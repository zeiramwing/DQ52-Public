#!/usr/bin/env python3
"""Reference tool, not part of the build: where the disassembly puts each
named table (its PRG bank and CPU address), for rom.py's AT table.

Usage: find_addresses.py DISASM_SRC_DIR LABEL...

A label's address is that of the first line after it that has one (the
disassembly marks every line of data with its address). The build reads
the data itself from the player's ROM at these addresses; this only finds
them, from nmikstas's disassembly, when a converter needs a new table.
"""
import re
import sys


def find(src_dir, names):
    out = {}
    for bank in range(4):
        lines = open(f"{src_dir}/Bank0{bank}.asm", encoding="latin-1").read().split("\n")
        for i, line in enumerate(lines):
            m = re.match(r"^(\w+):", line)
            if m and m.group(1) in names:
                for nxt in lines[i:]:
                    a = re.match(r"^L([0-9A-F]{4}):", nxt)
                    if a:
                        out[m.group(1)] = (bank, int(a.group(1), 16))
                        break
    return out


if __name__ == "__main__":
    if len(sys.argv) < 3:
        sys.exit(__doc__)
    found = find(sys.argv[1], set(sys.argv[2:]))
    for name in sys.argv[2:]:
        if name in found:
            bank, addr = found[name]
            print(f'    "{name}": ({bank}, 0x{addr:04X}),')
        else:
            print(f"    # {name}: not found")
