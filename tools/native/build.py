#!/usr/bin/env python3
"""Build the native 5200 engine's cartridge: a 512KB SuperCart (atari800
cartridge type 74).

Usage: build.py ROM OUTDIR [--autopilot | --script NAME] [--start MAP,X,Y] [--fight N] [--gold N] [--keys N] [--item N[,N...]] [--level N] [--exp N] [--equip N] [--flags N] [--hurt N] [--name-entry] [--profile]

Converts the game's data (convert.py), then assembles native/main.asm with
it into the first half of every bank, and puts the data banks' second
halves after: the overworld in bank 0, the text in bank 1, the cartridge
header in bank 15. --autopilot builds the measurement version (the hero
walks a fixed route, then the program parks for run5200.py); --script
NAME takes its controller input from native/scripts/NAME.asm. --start puts
the hero on map MAP (0 the overworld, then maps.TOWNS) at block X, Y;
--fight N makes every step on the overworld start a fight with enemy N;
--gold N gives the new hero N gold, --keys N magic keys, --item N[,N...] items (their ITM_ codes); --level N a hero of that level (HP and MP full), --exp N with N experience, --equip N wearing equipment byte N, --flags N with ModFlags N, --hurt N with N HP fewer than the most; --name-entry asks for the name at power-on (as the stick build does); --profile times the sound in the VBI
(ProfMax, ProfSum, ProfFrames: line pairs, 228 cycles each).
"""
import os
import shutil
import subprocess
import sys

import convert

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))
START = (43, 44)                # The hero's block: just south of Tantegel.
NAME = "Loto"                   # The name in builds without the name window.
BANKS, HALF = 16, 0x4000
MAP_BANK, TEXT_BANK, TOWN_BANK, IMAGES_BANK, MONSTER_BANK, BOOT_BANK = 0, 1, 2, 3, 4, 15
SOUND_BANK = 6                  # The music and effects (sound.py's format).
GFX_BANK = 7                    # The hero's and the townspeople's graphics.
OVERLAY_AT = 0xA000              # The power-on code, in MSG_BANK,
CREDITS_AT = 0xB400              # and the end credits.
TITLE_AT = 0x9000                # The title screen, in PEOPLE_BANK.
MSG_BANK = 8                    # Where each message starts in the text bank.
IMAGES2_BANK = 9                # The map images past the 7 IMAGES_BANK holds.
PEOPLE_BANK = 10                # The townspeople's tables (LoadPeople).
IMAGES3_BANK = 11               # The map images past 14,
IMAGES4_BANK = 14               # past 21,
TOWN2_BANK = 12                 # and the map pages past 15.
MONSTER_DARK_BANK = 13          # The monsters on black.
HEADER = 0xBFE8                 # The 5200 cartridge header, in BOOT_BANK.
DATA_END = 0xBFC0               # Reads from here up switch banks.

COMMANDS = [("TALK", "SPELL"), ("STATUS", "ITEM"), ("STAIRS", "DOOR"), ("SEARCH", "TAKE")]


PROFILE_START = """        LDA VCOUNT              ;(Profile: the line pair it starts on.)
        STA ProfStart           ;
"""
PROFILE_END = """        LDA VCOUNT              ;(Profile: line pairs it took, the most and
        SEC                     ;their sum over the frames.)
        SBC ProfStart           ;
        BCS +                   ;
        ADC #131                ;
*       CMP ProfMax             ;
        BCC +                   ;
        STA ProfMax             ;
*       CLC                     ;
        ADC ProfSum             ;
        STA ProfSum             ;
        BCC +                   ;
        INC ProfSum+1           ;
*       INC ProfFrames          ;
        BNE +                   ;
        INC ProfFrames+1        ;
*
"""


# The main loop's phases, timed in profile builds (prof_begin N / prof_end N
# around each; the macros are empty in other builds): the line pair each
# starts on, then the most it took and the sum (ProfPhase on, see main.asm).
PROFILE_MACROS = """.macro prof_begin
        PHA                     ;
        LDA VCOUNT              ;
        STA ProfT+_1            ;
        PLA                     ;
.macend
.macro prof_end
        PHA                     ;
        TXA                     ;
        PHA                     ;
        LDX #_1                 ;
        JSR ProfEnd             ;
        PLA                     ;
        TAX                     ;
        PLA                     ;
.macend
"""
PROFILE_CODE = """ProfEnd:
        LDA VCOUNT              ;
        SEC                     ;
        SBC ProfT,X             ;
        BCS +                   ;
        ADC #131                ;
*       CMP ProfPMax,X          ;
        BCC +                   ;
        STA ProfPMax,X          ;
*       CLC                     ;
        ADC ProfPSumLo,X        ;
        STA ProfPSumLo,X        ;
        BCC +                   ;
        INC ProfPSumHi,X        ;
*       INC ProfPCntLo,X        ;
        BNE +                   ;
        INC ProfPCntHi,X        ;
*       RTS                     ;
"""
PROFILE_EMPTY = """.macro prof_begin
.macend
.macro prof_end
.macend
"""


def tiles(text):
    """Text in the game's tiles: digits $00-$09, a-z $0A-$23, A-Z $24-$3D."""
    out = []
    for c in text:
        if c.isdigit():
            out.append(int(c))
        elif c.islower():
            out.append(0x0A + ord(c) - ord("a"))
        elif c.isupper():
            out.append(0x24 + ord(c) - ord("A"))
        else:
            out.append(0x5F)
    return out


def command_template():
    """The command window's tiles, 16 by 10, as the NES draws it."""
    rows = [[0x64, 0x62, 0x62, 0x63] + tiles("COMMAND") + [0x62] * 4 + [0x67]]
    blank = [0x61] + [0x5F] * 14 + [0x66]
    for left, right in COMMANDS:
        rows.append(list(blank))
        rows.append([0x61, 0x5F] + tiles(left.ljust(8)) + tiles(right.ljust(5)) + [0x66])
    rows.append([0x65] + [0x68] * 14 + [0x69])
    assert all(len(r) == 16 for r in rows) and len(rows) == 10, rows
    return [b for r in rows for b in r]


def battle_template():
    """The battle's command window, 16 by 6: FIGHT, SPELL, RUN, ITEM."""
    blank = [0x61] + [0x5F] * 14 + [0x66]
    rows = [[0x64, 0x62, 0x62, 0x63] + tiles("COMMAND") + [0x62] * 4 + [0x67]]
    for left, right in (("FIGHT", "SPELL"), ("RUN", "ITEM")):
        rows.append(list(blank))
        rows.append([0x61, 0x5F] + tiles(left.ljust(8)) + tiles(right.ljust(5)) + [0x66])
    rows.append([0x65] + [0x68] * 14 + [0x69])
    rows = rows[:5] + [rows[-1]]                # Top, blank, FIGHT, blank, RUN, bottom.
    assert all(len(r) == 16 for r in rows) and len(rows) == 6, rows
    return [b for r in rows for b in r]


CREDIT_UNIT = 8                         # Credits' waits: in 8 frames.
CREDIT_EVENT = 64                       # A music timing event, in frames (about).


def credits_bytes(rom_path):
    """The end credits (DoEndCredits' EndCreditDat, read from the ROM): its
    18 screens, each a wait (CREDIT_UNIT frames; the game's music timing
    events, CREDIT_EVENT frames each), then its rows of text, each row,
    column, length and text tiles; $FF ends a screen, $FE them all. The
    attribute writes are left out, as is the credits' own blank ($60) and
    mark ($61), which become the text blank."""
    rom = convert.romdata.Rom(rom_path)
    data = rom.table("EndCreditDat", 1400)
    at, out, screen = 0, bytearray(), 0
    events = [8, 2, 3, 3, 3] + [2] * 9 + [3] * 4      # (DoEndCredits' waits.)
    out.append(events[0] * CREDIT_EVENT // CREDIT_UNIT)
    while screen < 18:
        addr = data[at] | data[at + 1] << 8
        at += 2
        tiles = []
        while True:
            b = data[at]
            at += 1
            if b == 0xF7:
                tiles += [data[at + 1]] * data[at]
                at += 2
            elif b in (0xFC, 0xFD):
                break
            else:
                tiles.append(b)
        if addr < 0x23C0:
            row, col = divmod(addr - 0x2000, 32)
            tiles = [0x5F if t in (0x60, 0x61) else t for t in tiles]
            out += bytes([row, col, len(tiles)] + tiles)
        if b == 0xFD:
            out.append(0xFF)
            screen += 1
            if screen < 18:
                out.append(events[screen] * CREDIT_EVENT // CREDIT_UNIT)
    out.append(0xFE)
    return bytes(out)


TITLE_ROWS = 28                         # The view's rows (the nametable's 1-28).


def title_bytes(rom_path):
    """The title screen's background (DoIntroGFX: its nametable, from the
    ROM, in CHR bank 0, palette IntroPalTbl2; the dragon sprites are left
    out): its 2x2 tile groups as blocks with their attribute palettes,
    turned into mode 4 characters as the maps' are. 1KB of characters (set
    A), 1KB of its text rows' characters (set B), then the view's 28 rows
    of 32 codes, then COLPF0-3 and COLBK; and its first text row and their
    luminance."""
    rom = convert.romdata.Rom(rom_path)
    data = rom.table("IntroGFXTbl", 1200)
    at, nt = 0, []
    while len(nt) < 0x400:
        b = data[at]
        at += 1
        if b == 0xFC:
            continue
        if b == 0xF7:
            nt += [data[at + 1]] * data[at]
            at += 2
        else:
            nt.append(b)
    blocks = []
    for r in range(15):
        for c in range(16):
            t = r * 64 + c * 2
            attr = nt[0x3C0 + (r // 2) * 8 + c // 2] >> (((r & 1) * 2 + (c & 1)) * 2)
            blocks.append(([nt[t], nt[t + 1], nt[t + 32], nt[t + 33]], attr & 3))
    pal = rom.table("IntroPalTbl2", 12)
    chr_rom = rom.chr
    plan = convert.colordata.map_plan(chr_rom, blocks, pal, bank=0)
    pal, src, slot, inv = plan
    chars, codes = convert.block_chars(chr_rom, blocks, range(len(blocks)), slot, inv, bank=0)
    if len(chars) > 128:
        sys.exit(f"build: the title has {len(chars)} characters, more than 128")
    # Its text rows (those below the banner: the last rows reaching its
    # left edge) are mode 2 rows, their tiles at full width in one color,
    # from set B (TitleDLI switches to it, and to their colors).
    def colors_of(tile):
        return {v for row in convert.colordata.tile_pixels(chr_rom, 0, tile) for v in row if v}
    blank = max(set(nt[:0x3C0]), key=nt[:0x3C0].count)
    last = max(r for r in range(TITLE_ROWS) if nt[(r + 1) * 32] != blank)
    text_chars, lums = [bytes(8)], []
    grid = bytearray()
    for row in range(1, 1 + TITLE_ROWS):
        for col in range(32):
            if row - 1 > last:
                tile = nt[row * 32 + col]
                px = convert.colordata.tile_pixels(chr_rom, 0, tile)
                data = bytes(sum(0x80 >> x for x in range(8) if px[y][x]) for y in range(8))
                if data not in text_chars:
                    text_chars.append(data)
                grid.append(text_chars.index(data))
                p = blocks[(row // 2) * 16 + col // 2][1]
                lums += [convert.colordata.NES_TO_ATARI[pal[p * 3 + v - 1]] & 0x0F for v in colors_of(tile)]
                continue
            four = codes[(row // 2) * 16 + col // 2]
            grid.append(four[(row & 1) * 2 + (col & 1)])
    if len(text_chars) > 128:
        sys.exit(f"build: the title's text has {len(text_chars)} characters, more than 128")
    pf = [convert.colordata.NES_TO_ATARI[pal[(i // 4) * 3 + i % 4 - 1]] for i in src]
    lum = max(set(lums), key=lums.count) if lums else 0x0E
    return (b"".join(chars).ljust(0x400, b"\0") + b"".join(text_chars).ljust(0x400, b"\0")
            + bytes(grid) + bytes(pf + [0x00])), last + 1, max(lum, 0x08)


def script_bytes(path):
    """A test script's entries (its .byte lines after Script:), as bytes:
    put in MSG_BANK after the messages (input_script.asm reads them there)."""
    text = open(path).read()
    out = bytearray()
    for line in text[text.index("Script:"):].split("\n")[1:]:
        line = line.split(";")[0].strip()
        if line.startswith(".byte"):
            out += bytes(int(v.strip().replace("$", "0x"), 0) for v in line[5:].split(","))
    return bytes(out)


def status_template():
    """The status window's tiles, 8 by 12: its top border, then a line of
    the name, level, HP, MP, gold and experience with a blank row under each."""
    blank = [0x61] + [0x5F] * 6 + [0x66]
    rows = [[0x64, 0x63] + [0x5F] * 4 + [0x62, 0x67], blank]
    for label in ("LV", "HP", "MP", "G", "E"):
        rows += [[0x61] + tiles(label.ljust(6)) + [0x66], blank]
    rows[-1] = [0x65] + [0x68] * 6 + [0x69]
    assert all(len(r) == 8 for r in rows) and len(rows) == 12, rows
    return [b for r in rows for b in r]


def main():
    args = sys.argv[1:]
    script = None
    if "--script" in args:
        i = args.index("--script")
        script = args[i + 1]
        del args[i:i + 2]
    # The game starts in the throne room before the King (SetStartPos),
    # facing him; test builds on the overworld, but where a script says.
    start_map, start, facing = 0, START, 2
    if not script and "--autopilot" not in args:
        start_map, start, facing = 3, (3, 4), 0
    if "--start" in args:
        i = args.index("--start")
        start_map, *start = (int(v) for v in args[i + 1].split(","))
        del args[i:i + 2]
    profile = "--profile" in args
    items = []
    if "--item" in args:
        i = args.index("--item")
        items = [int(v) for v in args[i + 1].split(",")]
        del args[i:i + 2]
    keys = 0
    if "--keys" in args:
        i = args.index("--keys")
        keys = int(args[i + 1])
        del args[i:i + 2]
    gold = 0
    if "--gold" in args:
        i = args.index("--gold")
        gold = int(args[i + 1])
        del args[i:i + 2]
    hurt = 0
    if "--hurt" in args:
        i = args.index("--hurt")
        hurt = int(args[i + 1])
        del args[i:i + 2]
    flags = 0
    if "--flags" in args:
        i = args.index("--flags")
        flags = int(args[i + 1])
        del args[i:i + 2]
    equip = 0
    if "--equip" in args:
        i = args.index("--equip")
        equip = int(args[i + 1])
        del args[i:i + 2]
    exp = 0
    if "--exp" in args:
        i = args.index("--exp")
        exp = int(args[i + 1])
        del args[i:i + 2]
    level = 1
    if "--level" in args:
        i = args.index("--level")
        level = int(args[i + 1])
        del args[i:i + 2]
    fight = 0xFF
    if "--fight" in args:
        i = args.index("--fight")
        fight = int(args[i + 1])
        del args[i:i + 2]
    autopilot = "--autopilot" in args
    # The name window at power-on: in the stick build, and in a test that
    # asks for it (--name-entry); other tests start with NAME.
    name_entry = "--name-entry" in args or not (autopilot or script)
    if autopilot:
        fight = 0xFE                    # The measurement walks: no fights.
    args = [a for a in args if not a.startswith("--")]
    if len(args) != 2:
        sys.exit(__doc__)
    rom_path, out = args
    out = os.path.abspath(out)
    map_chars, set_b, text_size = convert.write_all(rom_path, out)
    if convert.WORLD_SIZE != 120:           # (main.asm's WorldRow: Y * 128 - Y * 8.)
        sys.exit("build: WorldRow works out rows 120 bytes apart")
    # --profile: the VBI times the sound (profile_start.asm, profile_end.asm;
    # empty in other builds, so they cost nothing there).
    with open(os.path.join(out, "profile_start.asm"), "w") as f:
        f.write(PROFILE_START if profile else "")
    with open(os.path.join(out, "profile_end.asm"), "w") as f:
        f.write(PROFILE_END if profile else "")
    with open(os.path.join(out, "profile.asm"), "w") as f:
        f.write(PROFILE_MACROS if profile else PROFILE_EMPTY)
    with open(os.path.join(out, "profile_code.asm"), "w") as f:
        f.write(PROFILE_CODE if profile else "")
    title, title_text, title_lum = title_bytes(rom_path)
    # A test script goes in MSG_BANK after the messages (SCRIPT_AT).
    script_data = script_bytes(os.path.join(ROOT, "native", "scripts", script + ".asm")) if script else b""
    script_at = 0x8000 + os.path.getsize(os.path.join(out, "messages.bin"))
    if script_at + len(script_data) > OVERLAY_AT:
        sys.exit("build: the script does not fit in MSG_BANK")
    with open(os.path.join(out, "config.asm"), "w") as f:
        f.write(f".alias SCRIPT_AT        ${script_at:04X}\n")
        f.write(f".alias OVERLAY_AT       ${OVERLAY_AT:04X}\n")
        f.write(f".alias CREDITS_AT       ${CREDITS_AT:04X}\n")
        f.write(f".alias TITLE_AT         ${TITLE_AT:04X}\n")
        f.write(f".alias TITLE_TEXT       {title_text}\n")
        f.write(f".alias TITLE_LUM        ${title_lum:02X}\n")
        f.write(f".alias START_MAP        {start_map}\n")
        f.write(f".alias FIGHT_ENEMY      ${fight:02X}\n")
        f.write(f".alias START_GOLD       {gold}\n")
        f.write(f".alias START_KEYS       {keys}\n")
        f.write(f".alias NAME_ENTRY       {int(name_entry)}\n")
        inv = bytearray(4)                      # Two items a byte (the low nibble first).
        for k, v in enumerate(items):
            inv[k // 2] |= v << (4 * (k & 1))
        for k in range(4):
            f.write(f".alias START_INV{k}       {inv[k]}\n")
        stats = convert.battle.base_stats(convert.romdata.Rom(rom_path))[level - 1]
        f.write(f".alias START_LEVEL      {level}\n")
        f.write(f".alias START_EXP        {exp}\n")
        f.write(f".alias START_EQUIP      {equip}\n")
        f.write(f".alias START_FLAGS      {flags}\n")
        f.write(f".alias START_HURT       {hurt}\n")
        for label, v in zip(("START_STR", "START_AGI", "START_HP", "START_MP"), stats):
            f.write(f".alias {label:16s} {v}\n")
        f.write(f".alias START_X          {start[0]}\n")
        f.write(f".alias START_FACING     {facing}\n")
        f.write(f".alias START_Y          {start[1]}\n")
        f.write(f".alias WORLD_SIZE       {convert.WORLD_SIZE}\n")
        f.write(f".alias BLK_WATER        ${convert.WATER_BLOCKS[0]:02X}\n")
    with open(os.path.join(out, "name.asm"), "w") as f:
        f.write(convert.asm_bytes(None, tiles(NAME.ljust(8))))
    with open(os.path.join(out, "strings.asm"), "w") as f:
        f.write(";Generated by tools/native/build.py.\n")

    for name in ("main.asm", "people.asm", "windows.asm", "text.asm", "battle.asm", "sound.asm", "shop.asm", "treasure.asm", "spell.asm", "castle.asm", "status.asm", "password.asm", "poweron.asm"):
        shutil.copy(os.path.join(ROOT, "native", name), out)
    shutil.copy(os.path.join(ROOT, "native", "hw5200.asm"), out)
    if script:
        shutil.copy(os.path.join(ROOT, "native", "input_script.asm"), os.path.join(out, "input.asm"))
    else:
        shutil.copy(os.path.join(ROOT, "native", "input_route.asm" if autopilot else "input_stick.asm"),
                    os.path.join(out, "input.asm"))

    program = os.path.join(out, "program.bin")
    run = subprocess.run(["ophis", "-q", "-o", program, "-m", os.path.join(out, "dwnative.bin.map"),
                          "main.asm"], cwd=out, capture_output=True, text=True)
    if run.returncode:
        sys.exit(f"build: ophis failed\n{run.stdout}{run.stderr}")
    code = open(program, "rb").read()
    if len(code) < HALF:
        sys.exit(f"build: the program is {len(code):#x} bytes, not {HALF:#x}")
    # What follows the program's half is the power-on code (poweron.asm),
    # assembled to run at OVERLAY_AT in MSG_BANK.
    code, overlay = code[:HALF], code[HALF:]
    if OVERLAY_AT + len(overlay) > DATA_END:
        sys.exit("build: the power-on code does not fit in MSG_BANK")
    labels = {}
    for line in open(os.path.join(out, "dwnative.bin.map")):
        parts = [p.strip() for p in line.split("|")]
        if len(parts) == 3:
            labels[parts[1]] = int(parts[0].lstrip("$"), 16)

    halves = [bytearray(b"\xff" * HALF) for _ in range(BANKS)]
    for bank, name in ((MAP_BANK, "world.bin"), (TEXT_BANK, "text.bin"), (TOWN_BANK, "towns.bin"),
                       (IMAGES_BANK, "images.bin"), (MONSTER_BANK, "monsters.bin"),
                       (MONSTER_BANK + 1, "monsters2.bin"), (SOUND_BANK, "sound.bin"),
                       (MSG_BANK, "messages.bin"),
                       (IMAGES2_BANK, "images2.bin"), (PEOPLE_BANK, "peopledata.bin"),
                       (IMAGES3_BANK, "images3.bin"), (TOWN2_BANK, "towns2.bin"),
                       (MONSTER_DARK_BANK, "monstersdark.bin"), (IMAGES4_BANK, "images4.bin")):
        data = open(os.path.join(out, name), "rb").read()
        if 0x8000 + len(data) > DATA_END:
            sys.exit(f"build: {name} is {len(data)} bytes, more than a bank holds")
        halves[bank][:len(data)] = data
    at = script_at - 0x8000
    halves[MSG_BANK][at:at + len(script_data)] = script_data
    at = OVERLAY_AT - 0x8000
    halves[MSG_BANK][at:at + len(overlay)] = overlay
    if OVERLAY_AT + len(overlay) > CREDITS_AT:
        sys.exit("build: the power-on code runs into the credits")
    at = TITLE_AT - 0x8000
    if TITLE_AT + len(title) > DATA_END or os.path.getsize(os.path.join(out, "peopledata.bin")) > at:
        sys.exit("build: the title does not fit in PEOPLE_BANK")
    halves[PEOPLE_BANK][at:at + len(title)] = title
    credits = credits_bytes(rom_path)
    if CREDITS_AT + len(credits) > DATA_END:
        sys.exit("build: the credits do not fit in MSG_BANK")
    at = CREDITS_AT - 0x8000
    halves[MSG_BANK][at:at + len(credits)] = credits
    gfx = open(os.path.join(out, "hero.bin"), "rb").read() + open(os.path.join(out, "people.bin"), "rb").read()
    if len(gfx) != 0x500:
        sys.exit(f"build: the hero and people graphics are {len(gfx)} bytes, not 1280")
    # Then the tables copied to RAM at $0800 at power on: TextA, TextB, the
    # windows' templates (main.asm's RAM_TABLES).
    tables = open(os.path.join(out, "textab.bin"), "rb").read()
    tables += bytes(command_template() + battle_template() + status_template())
    tables += bytes(0x3E0 - len(tables))                # (BridgeRow's RAM.)
    tables += open(os.path.join(out, "colors.bin"), "rb").read()    # PersonColors, at $0BE0.
    gfx += tables + bytes(0x400 - len(tables))
    gfx += open(os.path.join(out, "lord.bin"), "rb").read()        # The Dragonlord's frames.
    halves[GFX_BANK][:len(gfx)] = gfx                   # Copied to RAM at power on.
    header = bytes([0x64, 0x72, 0x61, 0x67, 0x6F, 0x6E, 0x00, 0x77, 0x61, 0x72, 0x72, 0x69, 0x6F, 0x72]
                   + [0] * 6 + [0x00, 0xFF, labels["start"] & 0xFF, labels["start"] >> 8])
    at = HEADER - 0x8000                # "dragon warrior", $FF: no BIOS title screen.
    halves[BOOT_BANK][at:at + len(header)] = header
    cart = os.path.join(out, "dwnative.bin")
    with open(cart, "wb") as f:
        for half in halves:
            f.write(code + half)
    print(f"build: wrote {cart} (map characters {map_chars}, {set_b} in set B, "
          f"{text_size} bytes of text, program to ${labels.get('programend', 0):04X}, "
          f"{0x8000 - labels.get('programend', 0)} bytes free)")


if __name__ == "__main__":
    main()
