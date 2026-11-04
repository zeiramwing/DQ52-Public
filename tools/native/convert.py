"""Build-time conversion of Dragon Warrior's data for the native 5200 engine.

Everything the engine shows is finished here: map blocks become mode 4
characters with their colors chosen, the overworld becomes block numbers
with the water shores worked out, and so on. The engine only copies.
"""
import os
import re
import sys

sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))
import colordata  # noqa: E402
import font4  # noqa: E402
import maps  # noqa: E402
import battle  # noqa: E402
import sound  # noqa: E402
import items  # noqa: E402
import window  # noqa: E402
import rom as romdata  # noqa: E402

BG_BANK = 1                     # CHR bank of the map tiles.
WORLD_SIZE = 120
MONSTER_BANK, MONSTER_DARK_BANK = 4, 13  # (build.py's banks.)
LORD_GRAPHIC = 14               # The Dragonlord's figure (CharSpriteTbl's $E0).

# Overworld map types (the upper nibble of a map byte) to block numbers
# (GFXTilesTbl), as WrldBlkConvTbl.
WORLD_BLOCKS = [0x00, 0x01, 0x02, 0x12, 0x0F, 0x10, 0x0B, 0x06, 0x07, 0x08, 0x09, 0x0A, 0x05]
WATER, BRIDGE = 0x04, 0x0B      # Map types.
NUM_GAME_BLOCKS = 39            # GFXTilesTbl's blocks.
TREASURES = 31                  # TreasureTbl's chests.
WATER_BLOCKS = [0x0F] + list(range(0x18, 0x27))  # By shore bits: top 1, left 2, right 4, bottom 8.


def world_types(rom):
    """The overworld as map types, [y][x]: each row's runs (a type in the
    upper nibble, the count - 1 in the lower) from its pointer in
    WrldMapPtrTbl on. A row whose runs come short of 120 blocks (row 10)
    goes on into the next row's, as FindRowBlock reads it.
    """
    grid = []
    for start in rom.words("WrldMapPtrTbl", WORLD_SIZE):
        data = rom.read(0, start, 2 * WORLD_SIZE)
        row, i = [], 0
        while len(row) < WORLD_SIZE:
            row += [data[i] >> 4] * ((data[i] & 15) + 1)
            i += 1
        grid.append(row[:WORLD_SIZE])
    return grid


def world_blocks(types):
    """The overworld as block numbers, with shores as GetBlockID works them out."""
    def wet(x, y):
        if not (0 <= x < WORLD_SIZE and 0 <= y < WORLD_SIZE):
            return True
        return types[y][x] in (WATER, BRIDGE)
    out = []
    for y, row in enumerate(types):
        line = []
        for x, t in enumerate(row):
            if t == WATER:
                shore = ((not wet(x, y - 1)) | (not wet(x - 1, y)) << 1
                         | (not wet(x + 1, y)) << 2 | (not wet(x, y + 1)) << 3)
                line.append(WATER_BLOCKS[shore])
            else:
                line.append(WORLD_BLOCKS[t])
        out.append(line)
    return out


def map_blocks(rom):
    """(tiles, palette) for each block (GFXTilesTbl: 5 bytes each)."""
    data = rom.table("GFXTilesTbl", NUM_GAME_BLOCKS * 5)
    return [(data[i:i + 4], data[i + 4]) for i in range(0, len(data), 5)]


def color_plan(rom, chr_rom, label):
    """The color plan for map palette LABEL (colordata.map_plan)."""
    return colordata.map_plan(chr_rom, map_blocks(rom), rom.table(label, 12))


def block_chars(chr_rom, blocks, used, slot, inv, bank=BG_BANK):
    """Mode 4 characters for the blocks USED: (charset bytes, codes per block).

    A block's 4 tiles (upper left, upper right, lower left, lower right) in
    its palette become 4 character codes, bit 7 set where the palette draws
    with COLPF3. Identical characters are shared; character 0 stays blank.
    """
    chars = [bytes(8)]
    codes = {}
    for b in sorted(used):
        tiles, pal = blocks[b]
        four = []
        for tile in tiles:
            px = colordata.tile_pixels(chr_rom, bank, tile)
            px = [[slot[pal][c] for c in row] for row in px]
            data = colordata.squeeze_tile(px)
            if data not in chars:
                chars.append(data)
            four.append(chars.index(data) | inv[pal])
        codes[b] = four
    return chars, codes


SPRITE_BANK = 2
HERO_OFFSET = 0x80              # CharSpriteTbl: no weapon, no shield; +8 the other step.
CARRY_COLOR = 0x48              # The hero's body color while he carries the princess.


def hero_pixels(chr_rom, table, direction, step):
    """The hero's 16x16 NES color indices facing DIRECTION (0 up, 1 right,
    2 down, 3 left), in step 0 or 1, as DoSprites puts its 4 sprites."""
    at = direction * 256 + HERO_OFFSET + step * 8
    px = [[0] * 16 for _ in range(16)]
    for i in range(4):
        tile, attr = table[at + 2 * i], table[at + 2 * i + 1]
        t = colordata.tile_pixels(chr_rom, SPRITE_BANK, tile)
        if attr & 0x40:
            t = [row[::-1] for row in t]
        if attr & 0x80:
            t = t[::-1]
        for y in range(8):
            for x in range(8):
                px[(i >> 1) * 8 + y][(i & 1) * 8 + x] = t[y][x]
    return px


def squeeze_wide(px):
    """16-pixel rows to 8, keeping thin features (as squeeze_tile)."""
    out = []
    for row in px:
        left = colordata.squeeze_tile([row[:8]] * 8)[0]
        right = colordata.squeeze_tile([row[8:]] * 8)[0]
        out.append([left >> (6 - 2 * i) & 3 for i in range(4)] + [right >> (6 - 2 * i) & 3 for i in range(4)])
    return out


def player_colors(colors, weights):
    """Two player colors for a sprite's 3 NES colors, with GTIA's multicolor
    players: where players 0 and 1 overlap the color is COLPM0 | COLPM1.

    Returns (masks, colpm0, colpm1): masks[c] = (in player 0, in player 1)
    for NES color c 1-3. Tries every way of giving each color player 0,
    player 1 or both, with every pair of Atari colors.
    """
    rgb = [colordata.NES_RGB[c] for c in colors]
    best = None
    for perm in ((1, 2, 3), (1, 3, 2), (2, 1, 3), (2, 3, 1), (3, 1, 2), (3, 2, 1)):
        for a in range(0, 256, 2):
            ea = [colordata.rgb_distance(rgb[i], colordata.ATARI_RGB[a // 2]) for i in range(3)]
            for b in range(0, 256, 2):
                eb = [colordata.rgb_distance(rgb[i], colordata.ATARI_RGB[b // 2]) for i in range(3)]
                ab = colordata.ATARI_RGB[(a | b) // 2]
                err = 0
                for i in range(3):
                    shown = perm[i]
                    e = ea[i] if shown == 1 else eb[i] if shown == 2 else \
                        colordata.rgb_distance(rgb[i], ab)
                    err += weights[i] * e
                if best is None or err < best[0]:
                    best = (err, perm, a, b)
    _, perm, a, b = best
    masks = {i + 1: (perm[i] in (1, 3), perm[i] in (2, 3)) for i in range(3)}
    return masks, a, b


def hero_frames(chr_rom, table, palette):
    """8 frames (direction * 2 + step) of 2 players * 16 bytes, and the two
    player colors."""
    frames = [squeeze_wide(hero_pixels(chr_rom, table, d, s)) for d in range(4) for s in range(2)]
    weights = [sum(row.count(c) for f in frames for row in f) for c in (1, 2, 3)]
    masks, a, b = player_colors(palette, weights)
    data = bytearray()
    for f in frames:
        for player in (0, 1):
            for row in f:
                byte = 0
                for c in row:
                    byte = byte << 1 | (c != 0 and masks[c][player])
                data.append(byte)
    return bytes(data), a, b


# Blocks the hero and the townspeople cannot walk onto: water, rock walls,
# doors, mountains, shop counters (the large tile), signs, black, and the
# princess in the swamp cave (talked to from beside her).
BLOCKED = {0x0E, 0x0F, 0x10, 0x11, 0x12, 0x13, 0x14, 0x16, 0x17} | set(range(0x18, 0x27))


def asm_bytes(label, data, per_line=16):
    lines = [f"{label}:"] if label else []
    for i in range(0, len(data), per_line):
        lines.append("        .byte " + ", ".join(f"${b:02X}" for b in data[i:i + per_line]))
    return "\n".join(lines) + "\n"


def asm_bytes_expr(label, exprs, per_line=8):
    lines = [f"{label}:"]
    for i in range(0, len(exprs), per_line):
        lines.append("        .byte " + ", ".join(exprs[i:i + per_line]))
    return "\n".join(lines) + "\n"


# Text tiles in CHR bank 1 (the game's text encoding): digits, lower and
# upper case, punctuation, the window frame. $5F and $60 are blanks.
DIGITS, UPPER = range(0x00, 0x0A), range(0x24, 0x3E)
FRAME = range(0x61, 0x6A)
ARROW = 0x42
BLANKS = (0x5F, 0x60)
NAME_SLOTS = 4                  # The status window shows the name's first 4 letters.


def text_tiles(chr_rom, blocks):
    """Bank 1's text and window tiles (colordata.text_flags), blanks left out."""
    flags = colordata.text_flags(chr_rom, {t for tiles, _ in blocks for t in tiles})
    return [t for t in range(256) if flags[256 + t] & 1 and not flags[256 + t] & 2]


def text_char(chr_rom, tile, slot):
    """A text tile as a mode 4 character in palette 0: font4's 4-pixel font
    for letters, digits and punctuation, the tile squeezed for the frame."""
    if tile in font4.GLYPHS:
        g = font4.glyph(tile, 1)
        px = [[slot[0][g[y][x]] for x in range(4)] for y in range(8)]
        return bytes(px[y][0] << 6 | px[y][1] << 4 | px[y][2] << 2 | px[y][3] for y in range(8))
    px = colordata.tile_pixels(chr_rom, BG_BANK, tile)
    return colordata.squeeze_tile([[slot[0][c] for c in row] for row in px])


def text_blocks(rom):
    """All 19 text blocks' bytes (one after another in bank 2), and where
    each starts."""
    first = romdata.TEXT_BLOCKS[0]
    return bytes(rom.read(2, first, romdata.TEXT_LENGTH)), [a - first for a in romdata.TEXT_BLOCKS]


TEXT_BASE_CODE = 64             # Set A: map characters below, text from here.
IMAGE_SIZE = 0x900              # Per map: set A, set B, a page of tables.
IMAGES_PER_BANK = 7             # 7 * $900 in a bank's data half; more go in IMAGES2_BANK, 3.
TOWNS_PER_BANK = 15             # 1KB town pages in a bank's data half.


def map_image(chr_rom, blocks, used, plan, tiles):
    """A map's 2.25KB image, copied to RAM ($2000) when the hero enters:
    set A (its blocks' characters, then the window text at TEXT_BASE_CODE
    and the name slots), set B (every text tile), and a page of tables:
    each block's 4 characters (+0, +40, +80, +120), whether the hero can
    walk onto it (+160), and the colors (+200: COLPF0-3, COLBK)."""
    pal, src, slot, inv = plan
    chars, codes = block_chars(chr_rom, blocks, used, slot, inv)
    free = len(chars)                   # The first code no map character uses.
    if len(chars) > TEXT_BASE_CODE:
        sys.exit(f"convert: {len(chars)} map characters, more than {TEXT_BASE_CODE}")
    chars += [bytes(8)] * (TEXT_BASE_CODE - len(chars))
    for t in list(DIGITS) + list(UPPER) + list(FRAME) + [ARROW]:
        chars.append(text_char(chr_rom, t, slot))
    chars += [bytes(8)] * NAME_SLOTS
    chars_b = [bytes(8)] + [text_char(chr_rom, t, slot) for t in tiles]
    image = bytearray(IMAGE_SIZE)
    image[0:len(chars) * 8] = b"".join(chars)
    image[0x400:0x400 + len(chars_b) * 8] = b"".join(chars_b)
    for b in range(len(blocks)):
        four = codes.get(b, [0, 0, 0, 0])
        for k in range(4):
            image[0x800 + 40 * k + b] = four[k]
        image[0x800 + 160 + b] = 1 if b in BLOCKED else 0
    pf = [colordata.NES_TO_ATARI[pal[(i // 4) * 3 + i % 4 - 1]] for i in src]
    image[0x800 + 200:0x800 + 205] = bytes(pf + [0x00])
    return bytes(image), len([c for c in chars[:TEXT_BASE_CODE] if c != bytes(8)]) + 1, free


def write_all(rom_path, out_dir):
    """Write the engine's data: images.bin (each map's characters and
    tables: bank data), world.bin (the overworld: bank data), towns.bin (the
    towns, 1KB each: bank data), text.bin (bank data), hero.bin, people.bin
    and data.asm (tables)."""
    rom = romdata.Rom(rom_path)
    chr_rom = rom.chr
    blocks = map_blocks(rom)
    tiles = text_tiles(chr_rom, blocks)
    if len(tiles) + 1 > 128:
        sys.exit(f"convert: {len(tiles)} text tiles, more than set B holds")
    text_a = [0] * 256
    for i, t in enumerate(list(DIGITS) + list(UPPER) + list(FRAME) + [ARROW]):
        text_a[t] = TEXT_BASE_CODE + i
    name_slot = TEXT_BASE_CODE + len(list(DIGITS) + list(UPPER) + list(FRAME)) + 1
    text_b = [0] * 256
    for i, t in enumerate(tiles):
        text_b[t] = i + 1

    world = world_blocks(world_types(rom))
    images, counts = [], []
    image, n, free = map_image(chr_rom, blocks, {b for row in world for b in row},
                               color_plan(rom, chr_rom, "OverworldPal"), tiles)
    images.append(image)
    counts.append(n)
    free_codes = [free]
    towns, everyone, starts = bytearray(), [], []
    town_plan = color_plan(rom, chr_rom, "TownPal")
    dungeon_plan = color_plan(rom, chr_rom, "DungeonPal")
    for town in maps.TOWNS:
        grid = maps.town_blocks(rom, town)
        _, size, border, _ = maps.map_info(rom, town["number"])
        image, n, free = map_image(chr_rom, blocks, {b for row in grid for b in row} | {border},
                                   dungeon_plan if town["number"] >= maps.DARK_FROM else town_plan,
                                   tiles)
        images.append(image)
        counts.append(n)
        free_codes.append(free)
        page = bytearray([border] * 1024)
        for y, row in enumerate(grid):
            page[y * 32:y * 32 + len(row)] = bytes(row)
        towns += page
        starts.append(len(everyone))
        everyone += maps.people(rom, town)
    starts.append(len(everyone))

    os.makedirs(out_dir, exist_ok=True)
    with open(os.path.join(out_dir, "textab.bin"), "wb") as f:  # TextA, TextB: copied to RAM.
        f.write(bytes(text_a + text_b))
    per_bank = IMAGES_PER_BANK
    for name, data in (("images.bin", b"".join(images[:per_bank])),
                       ("images2.bin", b"".join(images[per_bank:2 * per_bank])),
                       ("images3.bin", b"".join(images[2 * per_bank:3 * per_bank])),
                       ("images4.bin", b"".join(images[3 * per_bank:4 * per_bank])),
                       ("world.bin", bytes(b for row in world for b in row)),
                       ("towns.bin", bytes(towns[:TOWNS_PER_BANK * 1024])),
                       ("towns2.bin", bytes(towns[TOWNS_PER_BANK * 1024:]))):
        with open(os.path.join(out_dir, name), "wb") as f:
            f.write(data)
    text, text_starts = text_blocks(rom)
    # Where each message starts (16 * block + entry; past a block's last,
    # its end): MSG_BANK's table, so that one is found without reading
    # through the ones before it.
    message_at = []
    for b, start in enumerate(text_starts):
        at = start
        for e in range(16):
            message_at.append(min(at, len(text) - 1))
            while at < len(text) and text[at] != 0xFC:
                at += 1
            at += 1

    sprite_pal = rom.table("RegSPPal", 12)
    sprite_table = rom.table("CharSpriteTbl", 1024)
    hero, pm0, pm1 = hero_frames(chr_rom, sprite_table, sprite_pal[0:3])
    with open(os.path.join(out_dir, "hero.bin"), "wb") as f:
        f.write(hero)
    people_gfx, people_colors = people_frames(chr_rom, sprite_table, sprite_pal)
    with open(os.path.join(out_dir, "people.bin"), "wb") as f:
        f.write(people_gfx)
    # The Dragonlord's figure (CharSpriteTbl's graphic 14, the sprites the
    # game shows in his castle's bottom floor in the wizard's place,
    # ChkDrgnLordNPC): swapped into the wizard's slot there.
    lord_gfx, lord_color = people_frames(chr_rom, sprite_table, sprite_pal, [LORD_GRAPHIC])
    with open(os.path.join(out_dir, "lord.bin"), "wb") as f:
        f.write(lord_gfx)
    with open(os.path.join(out_dir, "colors.bin"), "wb") as f:    # PersonColors (RAM), then his.
        f.write(bytes(people_colors + lord_color))

    # The message lists of the dialog control bytes the people have, and
    # each person's control byte as an index among them.
    lists = []
    controls = sorted({p[4] for p in everyone})
    dialog_at = [maps.add_list(maps.dialog(c), lists) for c in controls]
    everyone = [p[:4] + (controls.index(p[4]),) + p[5:] for p in everyone]
    # MSG_BANK: where each message starts, then the people's message lists
    # (words; an Ask's branches as their addresses there).
    table = b"".join(bytes([(0x8000 + a) & 0xFF, (0x8000 + a) >> 8]) for a in message_at)
    list_at, at = {}, 0x8000 + len(table)
    for label, words in lists:
        list_at[label] = at
        at += 2 * len(words)
    data = bytearray(table)
    for label, words in lists:
        for w in words:
            v = list_at[w] if w in list_at else int(w[1:], 16)
            data += bytes([v & 0xFF, v >> 8])
    dialog_lo_at = 0x8000 + len(data)                   # Each dialog's list (DIALOG_LO/HI).
    data += bytes(list_at[label] & 0xFF for label in dialog_at)
    data += bytes(list_at[label] >> 8 for label in dialog_at)
    messages = data                                     # (Written once the names are placed.)

    records, (upper_glyphs, upper_grid), dark_records = battle.monster_records(
        rom, chr_rom, color_plan(rom, chr_rom, "OverworldPal"))
    plan = color_plan(rom, chr_rom, "OverworldPal")
    battle_text = b"".join(battle.white_text(text_char(chr_rom, t, plan[2]))
                           for t in list(DIGITS) + list(UPPER) + list(FRAME) + [ARROW])
    battle_text += bytes(512 - len(battle_text))       # (Copied as 2 pages.)
    scene = b"".join(upper_glyphs) + bytes(upper_grid)
    # The records in two banks (monsters.bin, monsters2.bin), none across;
    # the battle text and the scene after them in the second.
    monster_data, monster_at, monster_bank = [bytearray()], [], []
    for record, _ in records:
        if len(monster_data[-1]) + len(record) > MONSTER_ROOM:
            monster_data.append(bytearray())
        monster_bank.append(len(monster_data) - 1)
        monster_at.append(len(monster_data[-1]))
        monster_data[-1] += record
    if len(monster_data) == 1:
        monster_data.append(bytearray())
    if len(monster_data) > 2:
        sys.exit("convert: the monsters need more than two banks")
    battle_text_at = len(monster_data[1])
    scene_at = battle_text_at + len(battle_text)
    to_white = bytes(battle.white_text([b])[0] for b in range(256))
    to_white_at = scene_at + len(scene)
    monster_data[1] += battle_text + scene + to_white
    if len(monster_data[1]) > MONSTER_ROOM:
        sys.exit("convert: the second monster bank is full")
    # Map images past the four images banks' 28: in the second monster
    # bank after its data, each on a page of its own (MapImageHi).
    extra_at = []
    for image in images[4 * IMAGES_PER_BANK:]:
        monster_data[1] += bytes(-len(monster_data[1]) % 256)
        extra_at.append(0x8000 + len(monster_data[1]))
        monster_data[1] += image
    if len(monster_data[1]) > 0x3FC0:
        sys.exit("convert: the second monster bank is full")
    for name, data in zip(("monsters.bin", "monsters2.bin"), monster_data):
        with open(os.path.join(out_dir, name), "wb") as f:
            f.write(data)
    # The monsters on black (the battles off the overworld), in one more bank.
    dark_data, dark_at, dark_bank = [bytearray()], [], []
    for record, _ in dark_records:
        if len(dark_data[-1]) + len(record) > MONSTER_ROOM:
            dark_data.append(bytearray())
        dark_bank.append(len(dark_data) - 1)
        dark_at.append(len(dark_data[-1]))
        dark_data[-1] += record
    if len(dark_data) > 1:
        sys.exit("convert: the monsters on black need more than a bank")
    for name, data in (("monstersdark.bin", dark_data[0]),):
        with open(os.path.join(out_dir, name), "wb") as f:
            f.write(data)
    names = battle.enemy_names(rom)
    stats = battle.enemy_stats(rom)
    groups = battle.enemy_groups(rom)
    levels = battle.base_stats(rom)
    rom_levels = [rom.table("BaseStatsTbl", 6, i * 6) for i in range(30)]
    # The music and effects in the engine's format, checked against the
    # game's (sound.check exits if any plays differently).
    sound_data, music_at, sfx_at = sound.converted(rom)
    sound.check(rom, sound_data, music_at, sfx_at)
    # After the sound data, in its bank: where each music's parts and each
    # effect start (read while the bank is in).
    sound_tables = bytes([a & 0xFF for part in music_at for a in part] + [a >> 8 for part in music_at for a in part]
                         + [a & 0xFF for a in sfx_at] + [a >> 8 for a in sfx_at])
    sound_tables_at = 0x8000 + len(sound_data)
    # Then the POKEY dividers for each note (sound.py), read by ToPokey
    # with the bank in: SQ1 (16 bits), SQ2 and the triangle (8 bits), and
    # the noise channel's periods.
    sq1, sq2, tri, noise = sound.tables(rom)
    div_at = sound_tables_at + len(sound_tables)
    dividers = bytes([v & 0xFF for v in sq1] + [v >> 8 for v in sq1] + sq2 + tri + noise)
    with open(os.path.join(out_dir, "sound.bin"), "wb") as f:
        f.write(sound_data + sound_tables + dividers)
    with open(os.path.join(out_dir, "peopledata.bin"), "wb") as f:
        f.write(bytes(p[k] for k in range(6) for p in everyone) or bytes(6))
    # The text bank: the text, then the enemies' and the items' names (read
    # while it is in, as the text is).
    item_names = (items.names(rom) + items.spell_names(rom)     # (Spells: items SPELL_ITEM on;
                  + [items.passage_name(rom), items.tablet_name(rom)])  # then the passage's
                                                                # and the tablet's names.)
    en_names_at = len(text)
    en_names_data = [b for n in names for b in n]
    item_names_at = en_names_at + len(en_names_data)
    item_names_data = [b for n in item_names for b in n]
    # Where each name starts in the text bank, and its length: the items'
    # (and spells', and the passage's), then the enemies' (NAME_LO/HI/LEN,
    # in the messages bank after the dialog tables).
    name_list, name_at, at = item_names + names, [], item_names_at
    for n in item_names:
        name_at.append(at)
        at += len(n)
    at = en_names_at
    for n in names:
        name_at.append(at)
        at += len(n)
    name_lo_at = 0x8000 + len(messages)
    messages += bytes((0x8000 + v) & 0xFF for v in name_at)
    messages += bytes((0x8000 + v) >> 8 for v in name_at)
    messages += bytes(len(n) for n in name_list)
    # The STATUS window (window.py): its tiles, then its fields (row,
    # column, kind; $FF ends them), read while the messages bank is in.
    st_width, st_rows, st_fields = window.status_window(rom)
    status_at = 0x8000 + len(messages)
    messages += bytes(b for r in st_rows for b in r)
    status_fields_at = 0x8000 + len(messages)
    messages += bytes(b for r, c, k, _ in st_fields for b in (r, c, k)) + b"\xff"
    # Each enemy's record (ENEMY_RECS, 16 bytes; battle.asm's LoadEnemy
    # copies the one fought to RAM): EnStatTbl's attack, defense, HP,
    # spells, agility, magic defense, experience, gold; its repel value
    # (RepelTbl); its picture's place and bank, and on black.
    enemy_recs_at = 0x8000 + len(messages)
    repel = rom.table("RepelTbl", battle.ENEMIES)
    for e in range(battle.ENEMIES):
        at, dat = 0x8000 + monster_at[e], 0x8000 + dark_at[e]
        messages += bytes(stats[e][:8] + [repel[e], at & 0xFF, at >> 8, MONSTER_BANK + monster_bank[e],
                                          dat & 0xFF, dat >> 8, MONSTER_DARK_BANK + dark_bank[e], 0])
    # Each map's 16-byte record (MAP_RECS; LoadMap copies the one entered to
    # RAM): its image's bank and page, its width and height, dark, the
    # block off its edges, its enemies' row ($FF none), its page in the
    # town banks, its music (ResumeMusicTbl), its people (first, count),
    # where OUTSIDE goes ($FF: nowhere), and its first free character code.
    info = [maps.map_info(rom, t["number"]) for t in maps.TOWNS]
    cave_rows = rom.table("CaveEnIndexTbl", 13)
    resume = sound.resume_music(rom)
    outside = maps.outside(rom)
    n4 = 4 * IMAGES_PER_BANK
    map_recs_at = 0x8000 + len(messages)
    people_at = [0] + starts                            # (PeopleStart's: the overworld none.)
    for m in range(len(images)):
        if m < n4:
            img_bank = (3, 9, 11, 14)[m // IMAGES_PER_BANK]
            img_hi = (0x8000 + (m % IMAGES_PER_BANK) * IMAGE_SIZE) >> 8
        else:
            img_bank, img_hi = MONSTER_BANK + 1, extra_at[m - n4] >> 8
        if m == 0:
            size, height, border, dark, enemies, town_bank, town_hi = (
                WORLD_SIZE, WORLD_SIZE, WATER_BLOCKS[0], 0, 0xFF, 0, 0)
            music = resume[1]
        else:
            t, i = maps.TOWNS[m - 1], m - 1
            size, height, border = info[i][1], info[i][3], info[i][2]
            dark = 1 if t["number"] >= maps.DARK_FROM else 0
            enemies = (maps.LIT_ENEMIES[t["number"]] if t["number"] in maps.LIT_ENEMIES else
                       cave_rows[t["number"] - maps.DARK_FROM]
                       if maps.DARK_FROM <= t["number"] < maps.NO_ENEMIES_FROM else 0xFF)
            town_bank = (2, 12)[i // TOWNS_PER_BANK]
            town_hi = (0x8000 + (i % TOWNS_PER_BANK) * 1024) >> 8
            music = resume[t["number"]]
        messages += bytes([img_bank, img_hi, size, height, dark, border, enemies, town_bank, town_hi,
                           music, people_at[m], people_at[m + 1] - people_at[m], *outside[m], free_codes[m]])
    # The experience each level needs and each level's stats (StepLevel,
    # ExpToLevel and PwDecode read them with the bank in).
    level_exp = rom.words("LevelUpTbl", 30)
    level_at = 0x8000 + len(messages)
    messages += bytes([v & 0xFF for v in level_exp] + [v >> 8 for v in level_exp])
    for k in range(4):
        messages += bytes(lv[k] for lv in levels)
    # Each item's price, then each spell's MP (PriceOf reads them).
    cost = items.prices(rom)
    prices_at = 0x8000 + len(messages)
    messages += bytes([v & 0xFF for v in cost] + [v >> 8 for v in cost])
    # Each shop's items (ShopItemsTbl: from ShopStart, $FD after each), and
    # the chests on the engine's maps (TreasureTbl: map, X, Y, what, the
    # game's map numbers turned into ours): read with the bank in.
    shop_at, shop_data = [], []
    for shop in items.shops(rom):
        shop_at.append(len(shop_data))
        shop_data += shop
    shops_at = 0x8000 + len(messages)
    messages += bytes(shop_at + shop_data)
    ours = maps.ours()
    table = rom.table("TreasureTbl", TREASURES * 4)
    chests = [table[i:i + 4] for i in range(0, len(table), 4) if table[i] in ours]
    chests_at = 0x8000 + len(messages)
    for k in range(4):
        messages += bytes(ours[ch[0]] if k == 0 else ch[k] for ch in chests)
    # The overworld's enemy zones and their groups (battle.asm's
    # CheckEncounter reads them with the bank in).
    zones = battle.zones(rom)
    zones_at = 0x8000 + len(messages)
    messages += bytes(zones) + bytes(groups)
    # The map links (maps.links: MapEntryTbl, MapTargetTbl, MapEntryDirTbl),
    # seven tables of NUM_LINKS bytes, read with the bank in (main.asm's
    # FindLinkFrom and the rest).
    links = maps.links(rom)
    links_at = 0x8000 + len(messages)
    for k in range(7):
        messages += bytes(ln[k] for ln in links)
    if len(messages) > 0x3FC0:
        sys.exit("convert: the messages bank is full")
    with open(os.path.join(out_dir, "messages.bin"), "wb") as f:
        f.write(messages)
    with open(os.path.join(out_dir, "text.bin"), "wb") as f:
        f.write(text + bytes(en_names_data) + bytes(item_names_data))
    with open(os.path.join(out_dir, "data.asm"), "w") as f:
        f.write(";Generated by tools/native/convert.py.\n\n")
        f.write(f".alias NUM_BLOCKS       {len(blocks)}\n")
        f.write(f".alias NAME_SLOT        {name_slot}\n")
        f.write(f".alias NUM_MAPS         {len(images)}\n")
        f.write(f".alias NUM_PEOPLE       {len(everyone)}\n")
        f.write(f".alias IMAGE_PAGES      {IMAGE_SIZE // 256}\n")
        f.write(f".alias TEXT_SIZE        {len(text)}\n")
        f.write(f".alias SCENE_GLYPHS     {len(upper_glyphs)}\n")
        f.write(";In the second monster bank: the battle text (all COLPF0), the\n")
        f.write(";scene's glyphs and its 14 by 12 codes.\n")
        f.write(f".alias BATTLE_TEXT      ${0x8000 + battle_text_at:04X}\n")
        f.write(f".alias SCENE_DATA       ${0x8000 + scene_at:04X}\n")
        f.write(";And each byte of a glyph with every lit pixel COLPF0 (for the name's\n")
        f.write(";letters in the monster's band's set).\n")
        f.write(f".alias TO_WHITE         ${0x8000 + to_white_at:04X}\n\n")
        f.write(";COLPM0-1 for the hero, COLPM2-3's color for each townsperson graphic.\n")
        f.write(asm_bytes("HeroColors", [pm0, pm1, pm0, CARRY_COLOR]))    # (Then carrying her.)
        f.write(";Where each text block starts, in the text bank.\n")
        f.write(";Each map (0 the overworld, then maps.TOWNS): its image's place in the\n")
        f.write(";images bank, size, the block off its edges, the overworld block that\n")
        f.write(";leads in and where it leads, and its people (PeopleStart to the next).\n")
        n4 = 4 * IMAGES_PER_BANK
        f.write(";Each map but the overworld: its map's page in its bank (copied to RAM).\n")
        f.write(";Each map: dark (a dungeon), and its enemies' row in EnGroups ($FF: none).\n")
        cave_rows = rom.table("CaveEnIndexTbl", 13)
        info = [maps.map_info(rom, t["number"]) for t in maps.TOWNS]
        f.write(";Each townsperson: graphic, X, Y, facing, dialog (DialogLo/Hi's), mobile.\n")
        f.write(";(The people's tables are in PEOPLE_BANK: InitGraphic and so on, each\n")
        f.write(";NUM_PEOPLE bytes, one after another.)\n")
        for k, label in enumerate(("INIT_GRAPHIC", "INIT_X", "INIT_Y", "INIT_FACING", "INIT_CONTROL",
                                   "INIT_MOBILE")):
            f.write(f".alias {label:16s} ${0x8000 + k * max(len(everyone), 1):04X}\n")
        f.write(";What each dialog says (the game's control bytes the people have): a\n")
        f.write(";list of messages ending with $FFFF.\n")
        f.write(";(Steps: $FFFD the experience for the next level as the next message's\n")
        f.write(";amount; $FFFE then two lists: ask YES or NO, go on with one.)\n")
        f.write(";(In MSG_BANK, after where the messages start.)\n")
        f.write(f".alias DIALOG_LO        ${dialog_lo_at:04X}\n")
        f.write(f".alias DIALOG_HI        ${dialog_lo_at + len(dialog_at):04X}\n")
        f.write(";The map links between these maps (the game's MapEntryTbl, MapTargetTbl,\n")
        f.write(";MapEntryDirTbl): from a map's block to another's, and the facing there\n")
        f.write(";(in MSG_BANK: LinksIn first).\n")
        for k, label in enumerate(("LinkFromMap", "LinkFromX", "LinkFromY", "LinkToMap", "LinkToX",
                                   "LinkToY", "LinkFacing")):
            f.write(f".alias {label:16s} ${links_at + k * len(links):04X}\n")
        f.write(f".alias NUM_LINKS        {len(links)}\n")
        f.write(";The experience each level needs (LevelUpTbl), and each level's\n")
        f.write(";strength, agility, max HP and max MP (BaseStatsTbl): in MSG_BANK.\n")
        for k, label in enumerate(("LevelExpLo", "LevelExpHi", "LevelStr", "LevelAgi", "LevelHP", "LevelMP")):
            f.write(f".alias {label:16s} ${level_at + 30 * k:04X}\n")
        f.write(f".alias NUM_ENEMIES      {battle.ENEMIES}\n")
        f.write(";Each enemy's 16-byte record, in MSG_BANK (LoadEnemy).\n")
        f.write(f".alias ENEMY_RECS       ${enemy_recs_at:04X}\n")
        f.write(";Each enemy's name: where it starts (in the text bank), and its length.\n")
        f.write(";Each name (items, spells, the passage, then EN_NAMES on the enemies'):\n")
        f.write(";where it starts in the text bank and its length (in MSG_BANK).\n")
        f.write(f".alias NAME_LO          ${name_lo_at:04X}\n")
        f.write(f".alias NAME_HI          ${name_lo_at + len(name_list):04X}\n")
        f.write(f".alias NAME_LEN         ${name_lo_at + 2 * len(name_list):04X}\n")
        f.write(f".alias EN_NAMES         {len(item_names)}\n")
        st_top, st_left = window.status_place(rom)
        f.write(";The STATUS window (window.py): its tiles and fields in MSG_BANK.\n")
        f.write(f".alias STATUS_WIN       ${status_at:04X}\n")
        f.write(f".alias STATUS_FIELDS    ${status_fields_at:04X}\n")
        f.write(f".alias STATUS_WIDTH     {st_width}\n")
        f.write(f".alias STATUS_HEIGHT    {len(st_rows)}\n")
        f.write(f".alias STATUS_TOP       {st_top}\n")
        f.write(f".alias STATUS_LEFT      {st_left}\n")
        f.write(";The overworld's enemy zones (8 by 8, a nibble each) and the groups\n")
        f.write(";of 5 enemies they name (OvrWrldEnGrid, EnemyGroupsTbl).\n")
        f.write(f".alias EnZones          ${zones_at:04X}   ;(In MSG_BANK.)\n")
        f.write(f".alias EnGroups         ${zones_at + len(zones):04X}\n")
        f.write(";Each map's first character code below 64 its blocks leave free (for\n")
        f.write(";the window text set A lacks, put there as it is needed).\n")
        f.write(f".alias NUM_ITEMS        {items.ITEMS}\n")
        f.write(";Each item (items.py: ItemCostTbl's numbers): its price and name.\n")
        f.write(f".alias ItemPriceLo      ${prices_at:04X}   ;(In MSG_BANK: PriceOf.)\n")
        f.write(f".alias ItemPriceHi      ${prices_at + len(cost):04X}\n")
        f.write(f".alias SPELL_ITEM       {items.SPELL_ITEM}\n")
        f.write(f".alias PASSAGE_ITEM     {items.PASSAGE_ITEM}\n")
        f.write(f".alias TABLET_ITEM      {items.TABLET_ITEM}\n")
        f.write(f".alias CASTLE_GF        {maps.ours()[2]}\n")
        f.write(f".alias CASTLE_BF        {maps.ours()[6]}\n")
        f.write(f".alias TANTEGEL_GF      {maps.ours()[4]}\n")
        f.write(f".alias KOL_MAP          {maps.ours()[7]}\n")
        f.write(f".alias HAUKSNESS_MAP    {maps.ours()[3]}\n")
        f.write(f".alias SWAMP_MAP        {maps.ours()[21]}\n")
        f.write(";The spells (items SPELL_ITEM on): the level each is learned on\n")
        f.write(";(BaseStatsTbl's spell bits).\n")
        f.write(asm_bytes("SpellLevel", items.spell_levels(rom, rom_levels)))

        f.write(";Each map: the map and block OUTSIDE takes the hero to ($FF: it\n")
        f.write(";fails there; the game's ChkOutside, its MapEntryTbl entries).\n")
        outside = maps.outside(rom)
        f.write(";Each map's 16-byte record, in MSG_BANK (LoadMap copies it to MapRec).\n")
        f.write(f".alias MAP_RECS         ${map_recs_at:04X}\n")
        f.write(";Each shop's items (ShopItemsTbl), from ShopStart, ending with $FD,\n")
        f.write(";and the chests (TreasureTbl: map, X, Y, what): in MSG_BANK.\n")
        f.write(f".alias ShopStart        ${shops_at:04X}\n")
        f.write(f".alias ShopData         ${shops_at + len(shop_at):04X}\n")
        f.write(f".alias NUM_CHESTS       {len(chests)}\n")
        for k, label in enumerate(("ChestMap", "ChestX", "ChestY", "ChestWhat")):
            f.write(f".alias {label:16s} ${chests_at + k * len(chests):04X}\n")
        f.write(";Inn and key prices by town (InnCostTbl, KeyCostTbl), and the\n")
        f.write(";equipment's bonuses (WeaponsBonusTbl and so on).\n")
        f.write(asm_bytes("InnCost", items.small_table(rom, "InnCostTbl", 5)))
        f.write(asm_bytes("KeyCost", items.small_table(rom, "KeyCostTbl", 3)))
        f.write(asm_bytes("WeaponBonus", items.small_table(rom, "WeaponsBonusTbl", 8)))
        f.write(asm_bytes("ArmorBonus", items.small_table(rom, "ArmorBonusTbl", 8)))
        f.write(asm_bytes("ShieldBonus", items.small_table(rom, "ShieldBonusTbl", 4)))
        f.write(";Where each music's parts (SQ1, SQ2, TRI) and each sound effect's\n")
        f.write(";start in the sound bank (sound.py's format).\n")
        n_parts, n_sfx = len(music_at) * 3, len(sfx_at)
        f.write(f".alias MUSIC_LO         ${sound_tables_at:04X}   ;(In SOUND_BANK.)\n")
        f.write(f".alias MUSIC_HI         ${sound_tables_at + n_parts:04X}\n")
        f.write(f".alias SFX_LO           ${sound_tables_at + 2 * n_parts:04X}\n")
        f.write(f".alias SFX_HI           ${sound_tables_at + 2 * n_parts + n_sfx:04X}\n")
        f.write(f".alias NUM_NOTES        {len(sq1)}\n")
        f.write(";POKEY dividers for each note, in SOUND_BANK (sound.py).\n")
        n = len(sq1)
        for k, label in enumerate(("Sq1DivLo", "Sq1DivHi", "Sq2Div", "TriDiv")):
            f.write(f".alias {label:16s} ${div_at + k * n:04X}\n")
        f.write(f".alias NoiseDiv         ${div_at + 4 * n:04X}\n")
        resume = sound.resume_music(rom)
        f.write(";Each map's music (the game's ResumeMusicTbl, by its map number).\n")
    return counts, len(tiles) + 1, len(text)


MONSTER_ROOM = 0x3FC0                   # A bank's data half, below its switches.


def people_frames(chr_rom, table, sprite_pal, graphics=range(8)):
    """The townspeople's frames (graphic * 8 + facing * 2 + step), 16 bytes
    each, one player each: every pixel of the figure, in one color per
    graphic, the Atari color nearest its palette's three colors (weighted by
    how much each is drawn)."""
    data, colors = bytearray(), []
    for graphic in graphics:
        frames, palette = [], 0
        for d in range(4):
            for s in range(2):
                px, palette = maps.person_pixels(chr_rom, table, graphic, d, s)
                frames.append(squeeze_wide(px))
        weights = [sum(row.count(c) for f in frames for row in f) for c in (1, 2, 3)]
        three = sprite_pal[palette * 3:palette * 3 + 3]
        best = min(range(0, 256, 2), key=lambda a: sum(
            w * colordata.rgb_distance(colordata.NES_RGB[c], colordata.ATARI_RGB[a // 2])
            for w, c in zip(weights, three)))
        colors.append(best)
        for f in frames:
            for row in f:
                byte = 0
                for c in row:
                    byte = byte << 1 | (c != 0)
                data.append(byte)
    return bytes(data), colors


if __name__ == "__main__":
    if len(sys.argv) != 3:
        sys.exit("Usage: convert.py ROM OUTDIR")
    print("convert: map characters %s, %d in set B, %d bytes of text" % write_all(*sys.argv[1:]))
