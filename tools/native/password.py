#!/usr/bin/env python3
"""The native engine's passwords (native/password.asm, poweron.asm), for
tests and to check one by hand.

All that the NES's battery-backed log keeps: 14 bytes (gold, experience,
the 4 inventory bytes, keys | herbs << 4, the equipment byte, ModFlags,
Flags2, HP, MP), then the name's 8 characters at 5 bits each (40 bits, 5
bytes: their index in the name window's grid, NAME_CHARS), then their
CRC-8 (polynomial $07, from $5A) as the twentieth; the 19 XORed with a
sequence started from it (each next = the last * 5 + $3B). The 160 bits,
the top first, are 32 characters of 5 bits: A-Z, then 2-7.

Usage: password.py encode GOLD EXP INV0 INV1 INV2 INV3 KEYS HERBS EQUIP FLAGS FLAGS2 HP MP NAME
       password.py decode PASSWORD
       password.py moves PASSWORD   (a test script's entries to type it on the grid)
"""
import sys

ALPHABET = "ABCDEFGHIJKLMNOPQRSTUVWXYZ234567"
NAME_CHARS = "ABCDEFGHIJKLMNOPQRSTUVWXYZ-'.!? "    # The name window's grid (NameTiles).
LENGTH = 32
BODY = 19                       # Bytes before the check.


def crc8(data):
    crc = 0x5A
    for b in data:
        crc ^= b
        for _ in range(8):
            crc = ((crc << 1) ^ 0x07) & 0xFF if crc & 0x80 else (crc << 1) & 0xFF
    return crc


def scramble(data, key):
    out = bytearray()
    for b in data:
        out.append(b ^ key)
        key = (key * 5 + 0x3B) & 0xFF
    return bytes(out)


def encode(gold, exp, inv, keys, herbs, equip, flags, flags2, hp, mp, name):
    """The password's character values (0-31). NAME: up to 8 characters of
    NAME_CHARS (padded with blanks)."""
    name = (name.upper() + " " * 8)[:8]
    packed = 0
    for c in name:
        packed = packed << 5 | NAME_CHARS.index(c)
    body = bytes([gold & 0xFF, gold >> 8, exp & 0xFF, exp >> 8, *inv, keys | herbs << 4,
                  equip, flags, flags2, hp, mp]) + packed.to_bytes(5, "big")
    check = crc8(body)
    bits = int.from_bytes(scramble(body, check) + bytes([check]), "big")
    return [(bits >> (160 - 5 * (i + 1))) & 31 for i in range(LENGTH)]


def decode(values):
    bits = 0
    for v in values:
        bits = bits << 5 | v
    data = bits.to_bytes(20, "big")
    check = data[BODY]
    body = scramble(data[:BODY], check)
    if crc8(body) != check:
        return None
    packed = int.from_bytes(body[14:19], "big")
    name = "".join(NAME_CHARS[packed >> (35 - 5 * i) & 31] for i in range(8)).rstrip()
    return dict(gold=body[0] | body[1] << 8, exp=body[2] | body[3] << 8, inv=list(body[4:8]),
                keys=body[8] & 7, herbs=body[8] >> 4 & 7, equip=body[9], flags=body[10],
                flags2=body[11], hp=body[12], mp=body[13], name=name)


def moves(values):
    """A test script's entries typing VALUES on the entry window's grid (8
    a row; the cursor from 0; up, down: a row; right, left: one along)."""
    out, at = [], 0
    for v in values:
        while at // 8 != v // 8:
            d = 4 if v // 8 > at // 8 else 1
            at += 8 if d == 4 else -8
            out += [(3, d, 0), (3, 0, 0)]
        while at != v:
            d = 2 if v > at else 8
            at += 1 if d == 2 else -1
            out += [(3, d, 0), (3, 0, 0)]
        out += [(3, 0, 1), (3, 0, 0)]
    return out


def text(values):
    return " ".join("".join(ALPHABET[c] for c in values[i:i + 4]) for i in range(0, LENGTH, 4))


if __name__ == "__main__":
    if len(sys.argv) >= 2 and sys.argv[1] == "encode" and len(sys.argv) >= 16:
        n = [int(x, 0) for x in sys.argv[2:15]]
        print(text(encode(n[0], n[1], n[2:6], n[6], n[7], n[8], n[9], n[10], n[11], n[12], " ".join(sys.argv[15:]))))
    elif len(sys.argv) >= 3 and sys.argv[1] in ("decode", "moves"):
        values = [ALPHABET.index(c) for c in "".join(sys.argv[2:]).upper().replace(" ", "")]
        if sys.argv[1] == "decode":
            print(decode(values))
        else:
            for e in moves(values):
                print("        .byte %d, %d, %d" % e)
    else:
        sys.exit(__doc__)
