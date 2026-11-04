#!/usr/bin/env python3
"""The native engine's passwords (native/password.asm), for tests and to
check one by hand.

11 bytes (gold, experience, the 4 inventory bytes, keys | belt << 3 | herbs
<< 4 | necklace << 7, the
equipment byte, ModFlags), their CRC-8 (polynomial $07, from $5A) as the
twelfth, the 11 XORed with a sequence started from it (each next = the
last * 5 + $3B), then a pad byte of 0; the first 100 bits, the top first,
are 20 characters of 5 bits: A-Z, then 2-7.

Usage: password.py encode GOLD EXP INV0 INV1 INV2 INV3 KEYS HERBS EQUIP FLAGS
       password.py decode PASSWORD
"""
import sys

ALPHABET = "ABCDEFGHIJKLMNOPQRSTUVWXYZ234567"
LENGTH = 20


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


def encode(gold, exp, inv, keys, herbs, equip, flags, belt=0, necklace=0):
    """The password's character values (0-31). The curses (belt, necklace)
    ride in the keys' and herbs' nibbles' spare top bits."""
    body = bytes([gold & 0xFF, gold >> 8, exp & 0xFF, exp >> 8, *inv,
                  keys | belt << 3 | herbs << 4 | necklace << 7, equip, flags])
    check = crc8(body)
    data = scramble(body, check) + bytes([check, 0])
    bits = int.from_bytes(data, "big")
    return [(bits >> (104 - 5 * (i + 1))) & 31 for i in range(LENGTH)]


def decode(values):
    bits = 0
    for v in values:
        bits = bits << 5 | v
    data = (bits << 4).to_bytes(13, "big")
    check = data[11]
    body = scramble(data[:11], check)
    if crc8(body) != check:
        return None
    return dict(gold=body[0] | body[1] << 8, exp=body[2] | body[3] << 8, inv=list(body[4:8]),
                keys=body[8] & 7, herbs=body[8] >> 4 & 7, belt=body[8] >> 3 & 1, necklace=body[8] >> 7,
                equip=body[9], flags=body[10])


if __name__ == "__main__":
    if len(sys.argv) == 12 and sys.argv[1] == "encode":
        v = [int(a, 0) for a in sys.argv[2:]]
        print("".join(ALPHABET[c] for c in encode(v[0], v[1], v[2:6], v[6], v[7], v[8], v[9])))
    elif len(sys.argv) == 3 and sys.argv[1] == "decode":
        print(decode([ALPHABET.index(c) for c in sys.argv[2].upper()]))
    else:
        sys.exit(__doc__)
