#!/usr/bin/env python3
"""Run the native engine's scripted tests.

Usage: test.py ROM OUTDIR [NAME...]

Each native/scripts/NAME.asm is a controller script. When it ends, each
of its `;EXPECT: text` lines must appear on a line of the screen (only the
port's own words and short labels: the game's text is never in the
repository), each `;EXPECT-MSG: N` line's message N must be showing (a
run of its text, read from the ROM at test time, wherever the window
wraps it), and
each `;EXPECT-ZERO: label` names a 2-byte counter (main.asm's zero page)
that must be 0 then, such as Missed (frames the main loop missed), and
`;EXPECT-BYTE: label N` a byte that must be N. A
`;START: MAP,X,Y` line starts the hero there (build.py --start), and a
`;FIGHT: N` line makes every step on the overworld a fight with enemy N, and
a `;GOLD: N` line gives the hero N gold to start with (`;KEYS: N`, keys; `;ITEM: N[,N...]`, items by their ITM_ codes; `;LEVEL: N`, a hero of that level, HP and MP full; `;EXP: N`, experience; `;EQUIP: N`, the equipment byte; `;FLAGS: N`, ModFlags; `;HURT: N`, N HP short; `;NAME-ENTRY`, the name window at power-on). The
screen is read back from the ring as text: the window rows through set A's
characters, the dialog window's rows (18 on, while it is up) through set
B's. Runs every script with EXPECT lines, or those named. PROFILE=1 (or a
`;PROFILE` line) times the sound in the VBI and prints it.
"""
import glob
import os
import re
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
PROFILE = bool(os.environ.get("PROFILE"))
PHASES = ["main loop (a frame)", "MovePeople", "StepFrame", "DrawPeople", "ShowHero, SetScroll", "StartStep",
          "  DrawPeople's clear", "  PlacePeople"]  # PROFILE=1: every script a profile build.
ROOT = os.path.dirname(os.path.dirname(HERE))
ROWS, DIALOG_ROW = 28, 18
sys.path.insert(0, HERE)
import convert  # noqa: E402  (the ROM's text, for ;EXPECT-MSG)


def tile_text(t):
    if t < 10:
        return str(t)
    if 0x0A <= t < 0x24:
        return chr(ord("a") + t - 0x0A)
    if 0x24 <= t < 0x3E:
        return chr(ord("A") + t - 0x24)
    return {0x47: ".", 0x48: ",", 0x40: "'", 0x50: "'", 0x4C: "!", 0x4B: "?", 0x49: "-",
            0x42: ">", 0x5F: " ", 0x60: " "}.get(t, "#")


def squeeze(text):
    """Text with window frames and runs of spaces made one space (a line's
    wrap, or a frame between two lines, then matches)."""
    return " ".join(text.replace("#", " ").replace("|", " ").split())


_messages = {}


def message_runs(rom_path, n):
    """Message N's (16 * block + entry) runs of plain text of 8 characters or
    more (between the names, numbers and other control bytes the game puts
    in), read from the ROM, as the screen shows them: a test checks that one
    of them shows (a long message's start may have scrolled away), so the
    game's text is never in the repository."""
    if rom_path not in _messages:
        rom = convert.romdata.Rom(rom_path)
        text, starts = convert.text_blocks(rom)
        found = []
        for start in starts:
            at = start
            for _ in range(16):
                end = at
                while end < len(text) and text[end] != 0xFC:
                    end += 1
                found.append(text[at:end])
                at = end + 1
        _messages[rom_path] = found
    runs, run = [], ""
    for t in list(_messages[rom_path][n]) + [0xFF]:
        c = tile_text(t) if t < 0x61 else None
        if c is None or c == "#":
            if len(run.strip()) >= 8:
                runs.append(run.strip())
            run = ""
        else:
            run += c
    return runs


def tables(out):
    data = open(os.path.join(out, "textab.bin"), "rb").read()
    found = {}
    for k, label in enumerate(("TextA", "TextB")):
        values = data[k * 256:(k + 1) * 256]
        order = list(enumerate(values))         # (Set A: a capital, not its lower case.)
        found[label] = {code: tile for tile, code in (order if label == "TextA" else reversed(order)) if code}
    return found


def screen_text(out, mem, labels):
    zp = lambda name: mem[labels[name.lower()]]
    names = tables(out)
    name_slot = int(re.search(r"NAME_SLOT\s+(\d+)", open(os.path.join(out, "data.asm")).read()).group(1))
    hero = [mem[0x0240 + i] for i in range(4)]
    text_a = names["TextA"]
    lines = []
    for r in range(ROWS):
        row = (zp("TopBlock") * 2 + r) & 31
        line = ""
        for c in range(32):
            code = mem[0x1000 + row * 128 + ((zp("LeftBlock") * 2 + c) & 63)]
            if r >= DIALOG_ROW and zp("DialogOn"):
                line += tile_text(names["TextB"][code]) if code in names["TextB"] else " "
            elif code == 0:
                line += " "
            elif name_slot <= code < name_slot + 4:
                line += tile_text(hero[code - name_slot])
            else:
                line += tile_text(text_a[code]) if code in text_a else "."
        lines.append(line)
    return lines


def print_profile(name, mem, labels):
    at = labels["profmax"]
    frames = mem[at + 3] | mem[at + 4] << 8
    total = mem[at + 1] | mem[at + 2] << 8
    print(f"  profile {name}: the sound took at most {mem[at] * 228} cycles a frame, "
          f"{total * 228 // max(frames, 1)} on average, over {frames} frames")
    for k, phase in enumerate(PHASES):
        count = mem[0x3C0 + k] | mem[0x3C8 + k] << 8
        if count:
            total = mem[0x3B0 + k] | mem[0x3B8 + k] << 8
            print(f"  {phase:20s} at most {mem[0x3A8 + k] * 228:5d} cycles, "
                  f"{total * 228 // count:5d} on average ({count} times)")


def run(rom_path, out_root, name):
    out = os.path.join(out_root, name)
    script = os.path.join(ROOT, "native", "scripts", name + ".asm")
    expects = re.findall(r"^;EXPECT: (.+)$", open(script).read(), re.M)
    messages = [int(n) for n in re.findall(r"^;EXPECT-MSG: (\d+)$", open(script).read(), re.M)]
    zeros = re.findall(r"^;EXPECT-ZERO: (\w+)$", open(script).read(), re.M)
    bytes_ = re.findall(r"^;EXPECT-BYTE: (\w+) (\d+)$", open(script).read(), re.M)
    start = re.findall(r"^;START: (\S+)$", open(script).read(), re.M)
    fight = re.findall(r"^;FIGHT: (\d+)$", open(script).read(), re.M)
    gold = re.findall(r"^;GOLD: (\d+)$", open(script).read(), re.M)
    keys = re.findall(r"^;KEYS: (\d+)$", open(script).read(), re.M)
    item = re.findall(r"^;ITEM: ([\d,]+)$", open(script).read(), re.M)
    level = re.findall(r"^;LEVEL: (\d+)$", open(script).read(), re.M)
    exp = re.findall(r"^;EXP: (\d+)$", open(script).read(), re.M)
    equip = re.findall(r"^;EQUIP: (\d+)$", open(script).read(), re.M)
    flags = re.findall(r"^;FLAGS: (\d+)$", open(script).read(), re.M)
    hurt = re.findall(r"^;HURT: (\d+)$", open(script).read(), re.M)
    profile = PROFILE or ";PROFILE" in open(script).read()
    name_entry = ";NAME-ENTRY" in open(script).read()
    subprocess.run([sys.executable, os.path.join(HERE, "build.py"), rom_path, out,
                    "--script", name] + (["--start", start[0]] if start else [])
                   + (["--fight", fight[0]] if fight else [])
                   + (["--gold", gold[0]] if gold else [])
                   + (["--keys", keys[0]] if keys else [])
                   + (["--name-entry"] if name_entry else [])
                   + (["--item", item[0]] if item else [])
                   + (["--level", level[0]] if level else [])
                   + (["--exp", exp[0]] if exp else [])
                   + (["--equip", equip[0]] if equip else [])
                   + (["--flags", flags[0]] if flags else [])
                   + (["--hurt", hurt[0]] if hurt else [])
                   + (["--profile"] if profile else []), check=True, capture_output=True)
    labels = {}
    for line in open(os.path.join(out, "dwnative.bin.map")):
        parts = [p.strip() for p in line.split("|")]
        if len(parts) == 3:
            labels[parts[1]] = int(parts[0].lstrip("$"), 16)
    cart = os.path.join(out, "dwnative.bin")
    png = os.path.join(out, name + ".png")
    entries = re.findall(r"^\s+\.byte (\d+), \d+, \d+", open(script).read(), re.M)
    frames = 200 + sum(int(e) for e in entries)       # The script's frames, and loading.
    result = subprocess.run([sys.executable, os.path.join(HERE, "..", "run5200.py"), cart, "--type", "74",
                             "--until", f"{labels['parked'] + 4:04X}", "--frames", str(frames), "--timeout", str(60 + frames // 20),
                             "--png", png, "--dump", "0000:C00", "--dump", "1000:1000"],
                            capture_output=True, text=True)
    mem = bytearray(0x2000)
    for m in re.finditer(r"^\$([0-9A-F]{4}): ([0-9a-f ]+)$", result.stdout, re.M):
        data = bytes.fromhex(m.group(2))
        mem[int(m.group(1), 16):int(m.group(1), 16) + len(data)] = data
    if result.returncode:
        print(f"FAIL {name}: did not finish\n{result.stdout}{result.stderr}")
        return False
    lines = screen_text(out, mem, labels)
    missing = [e for e in expects if not any(e in line for line in lines)]
    shown = squeeze(" ".join(lines))
    missing += [f"message {n}" for n in messages
                if not any(squeeze(run) in shown for run in message_runs(rom_path, n))]
    for label, value in bytes_:
        at = labels[label.lower()]
        if mem[at] != int(value):
            missing.append(f"{label} = {value} (found {mem[at]})")
    for z in zeros:
        at = labels[z.lower()]
        if mem[at] | mem[at + 1] << 8:
            missing.append(f"{z} = 0 (found {mem[at] | mem[at + 1] << 8})")
    if profile:
        print_profile(name, mem, labels)
    if missing:
        print(f"FAIL {name}: missing {missing}. Screen:")
        print("\n".join(f"  |{line}|" for line in lines))
        return False
    print(f"PASS {name}: {', '.join(expects + [f'message {n}' for n in messages] + [z + ' = 0' for z in zeros] + [f'{l} = {v}' for l, v in bytes_])}"
          f" (screen: {png})")
    if os.environ.get("SHOW"):
        print("\n".join(f"  |{line}|" for line in lines))
    return True


def main():
    if len(sys.argv) < 3:
        sys.exit(__doc__)
    names = sys.argv[3:] or sorted(
        os.path.basename(p)[:-4] for p in glob.glob(os.path.join(ROOT, "native", "scripts", "*.asm"))
        if ";EXPECT" in open(p).read())
    ok = all([run(*sys.argv[1:3], n) for n in names])
    sys.exit(0 if ok else 1)


if __name__ == "__main__":
    main()
