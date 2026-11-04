"""Build-time color data for the 5200 driver (used by build5200.py).

The driver shows map rows in ANTIC mode 4: 4 pixels per character, each
pixel 2 bits selecting COLBK, COLPF0, COLPF1, or COLPF2 (COLPF3 when the
character code has bit 7 set). This module produces:

* Mode 4 source graphics for each background CHR bank: every tile's pixels
  as NES color indices 0-3, squeezed to 4 pixels per row. The driver maps
  them through the current color plan when it caches a character.
* Text flags: which tiles are font or window frame (font tiles get font4's
  4-pixel glyphs) and which are empty.
* Color plans: for each of the game's background palette sets, which NES
  palette entries feed COLPF0-3 and which register each palette entry is
  drawn with. Chosen by trying every assignment and keeping the one with the
  least color error, weighted by how much each palette entry is used.
"""
import itertools
import re
from collections import Counter

import font4

# The background only ever uses CHR banks 0 (title) and 1 (everything else):
# the game always shows background pattern table 0, holding ActiveNT0.
BG_BANKS = (0, 1)

# Approximate NES colors as RGB (the common FCEUX palette).
NES_RGB = [
    0x7C7C7C, 0x0000FC, 0x0000BC, 0x4428BC, 0x940084, 0xA80020, 0xA81000, 0x881400,
    0x503000, 0x007800, 0x006800, 0x005800, 0x004058, 0x000000, 0x000000, 0x000000,
    0xBCBCBC, 0x0078F8, 0x0058F8, 0x6844FC, 0xD800CC, 0xE40058, 0xF83800, 0xE45C10,
    0xAC7C00, 0x00B800, 0x00A800, 0x00A844, 0x008888, 0x000000, 0x000000, 0x000000,
    0xF8F8F8, 0x3CBCFC, 0x6888FC, 0x9878F8, 0xF878F8, 0xF85898, 0xF87858, 0xFCA044,
    0xF8B800, 0xB8F818, 0x58D854, 0x58F898, 0x00E8D8, 0x787878, 0x000000, 0x000000,
    0xFCFCFC, 0xA4E4FC, 0xB8B8F8, 0xD8B8F8, 0xF8B8F8, 0xF8A4C0, 0xF0D0B0, 0xFCE0A8,
    0xF8D878, 0xD8F878, 0xB8F8B8, 0xB8F8D8, 0x00FCFC, 0xF8D8F8, 0x000000, 0x000000,
]
BLACK = 0x0F

# Atari colors $00, $02 ... $FE as RGB, measured from atari800's default NTSC
# palette by tools/palcart/palette.asm (see tools/palcart/README).
ATARI_RGB = [
    0x040404, 0x1B1B1B, 0x333333, 0x4F4F4F, 0x686868, 0x898989, 0xABABAB, 0xD3D3D3,
    0x041600, 0x1B2D00, 0x334600, 0x4F6200, 0x687B08, 0x899B29, 0xABBE4C, 0xD3E574,
    0x1C0800, 0x331F00, 0x4B3700, 0x675300, 0x806C12, 0xA18D34, 0xC3B057, 0xEBD77E,
    0x2F0000, 0x460F00, 0x5E2800, 0x7A4416, 0x935D2F, 0xB47E51, 0xD6A173, 0xFDC89B,
    0x390000, 0x50040A, 0x681B23, 0x84373F, 0x9D5058, 0xBD7179, 0xE0949C, 0xFFBBC3,
    0x380020, 0x4E0037, 0x66134F, 0x822F6B, 0x9B4884, 0xBC6AA5, 0xDE8CC7, 0xFFB4EF,
    0x2B0047, 0x42005E, 0x5A1276, 0x762E91, 0x8E47AA, 0xAF69CB, 0xD18BED, 0xF9B3FF,
    0x16005F, 0x2D0275, 0x45188D, 0x6135A9, 0x7A4EC1, 0x9B6FE2, 0xBD91FF, 0xE4B9FF,
    0x010063, 0x130B7A, 0x2C2492, 0x4840AD, 0x6159C6, 0x827AE7, 0xA49DFF, 0xCCC4FF,
    0x000453, 0x011B6A, 0x143382, 0x314F9E, 0x4A68B6, 0x6B89D7, 0x8DACF9, 0xB5D3FF,
    0x001332, 0x002A49, 0x044261, 0x205E7D, 0x397796, 0x5A98B7, 0x7DBAD9, 0xA4E2FF,
    0x001F07, 0x00361E, 0x014E36, 0x196A53, 0x32836B, 0x54A38C, 0x76C6AF, 0x9EEDD6,
    0x002500, 0x003C00, 0x03540A, 0x1E7027, 0x378840, 0x59A961, 0x7BCC84, 0xA3F3AB,
    0x002400, 0x003B00, 0x115300, 0x2E6F04, 0x47871D, 0x68A83E, 0x8ACA61, 0xB2F289,
    0x001C00, 0x103300, 0x284B00, 0x446700, 0x5D8009, 0x7EA12B, 0xA1C34E, 0xC8EA76,
    0x120E00, 0x292600, 0x413E00, 0x5D5A00, 0x76730B, 0x97942D, 0xB9B650, 0xE1DD78,
]

# Background palette sets to plan for: label in the source, and whether its
# weights come from the map blocks (True) or are uniform.
def tile_pixels(chr_rom, bank, tile):
    """8x8 NES color indices of a tile."""
    base = bank * 0x1000 + tile * 16
    return [[(chr_rom[base + y] >> (7 - x) & 1) | (chr_rom[base + 8 + y] >> (7 - x) & 1) << 1
             for x in range(8)] for y in range(8)]


def squeeze_tile(px, plane0_first=False):
    """An 8x8 tile's NES color indices -> 8 bytes of 4 pixels, 2 bits each.

    Each pair of NES pixels becomes one. Where the two differ, the one kept
    belongs to the thinner feature: the pixel whose run of its color, reaching
    out of the pair into its neighbor, is shorter (a 1-pixel line rather than
    the fill around it); on a tie, the color rarer in the tile. Outlines,
    mortar and window lines survive the halving this way. With PLANE0_FIRST,
    a pixel in the first bit plane (color 1 or 3) wins over one of color 2.
    """
    count = Counter(v for row in px for v in row)
    out = bytearray()
    for row in px:
        byte = 0
        for x in range(0, 8, 2):
            a, b = row[x], row[x + 1]
            if plane0_first and {a & 1, b & 1} == {0, 1} and 2 in (a, b):
                a = a if a & 1 else b
            elif a != b:
                run_a = 1 + (x > 0 and row[x - 1] == a)
                run_b = 1 + (x < 6 and row[x + 2] == b)
                if run_a != run_b:
                    keep_a = run_a < run_b
                else:
                    keep_a = count[a] <= count[b]
                a = a if keep_a else b
            byte = byte << 2 | a
        out.append(byte)
    return bytes(out)


def text_flags(chr_rom, map_tiles):
    """256 bytes per BG bank: bit 0 for font and window tiles, bit 1 for
    empty tiles (every pixel color 0), which need no mode 4 character.

    Bank 0 (title): tiles below $74 except the blank; the logo starts at $74.
    Bank 1: tiles below $80 that no map block uses (shore edges, stairs and
    walls are below $80 too), except the blanks $5F and $60.
    """
    out = bytearray()
    for bank in BG_BANKS:
        for tile in range(256):
            if bank == 0:
                text = tile < 0x74 and tile != 0x5F
            else:
                text = tile < 0x80 and tile not in map_tiles and tile not in (0x5F, 0x60)
            base = bank * 0x1000 + tile * 16
            empty = not any(chr_rom[base:base + 16])
            out.append((1 if text else 0) | (2 if empty else 0))
    return bytes(out)


def block_weights(chr_rom, blocks, bank=1):
    """How much each color of each palette is drawn by the map blocks.

    Pixel counts within a palette, scaled so every palette totals 1000: the
    palettes stand for terrain classes (water, rock, grass, sand), and the
    15 water-shore blocks would otherwise make water count most.
    """
    weights = [[0] * 4 for _ in range(4)]
    for tiles, pal in blocks:
        for tile in tiles:
            for row in tile_pixels(chr_rom, bank, tile):
                for c in row:
                    weights[pal][c] += 1
    for row in weights:
        total = sum(row[1:]) or 1
        row[1:] = [1000 * w // total for w in row[1:]]
    return weights


def rgb_distance(a, b):
    ra, ga, ba = a >> 16, a >> 8 & 0xFF, a & 0xFF
    rb, gb, bb = b >> 16, b >> 8 & 0xFF, b & 0xFF
    return 2 * (ra - rb) ** 2 + 4 * (ga - gb) ** 2 + 3 * (ba - bb) ** 2


def nes_to_atari():
    """For each NES color, the Atari color byte nearest to it."""
    return [2 * min(range(128), key=lambda i: rgb_distance(NES_RGB[c], ATARI_RGB[i]))
            for c in range(64)]


NES_TO_ATARI = nes_to_atari()


def shown_error(wanted, register):
    """Error drawing NES color WANTED with a register holding NES color REGISTER.

    The register shows REGISTER's nearest Atari color, so that is compared.
    """
    return rgb_distance(NES_RGB[wanted], ATARI_RGB[NES_TO_ATARI[register] // 2])


def plan(colors, weights):
    """Best register plan for 4 palettes of 3 colors (colors[p][c-1]).

    Returns (src, slot, inv): src[k] is the PalRAM index (p*4+c) feeding
    COLPF0-3; slot[p][c] is the pixel value (0 = COLBK, 1 = COLPF0, 2 =
    COLPF1, 3 = COLPF2/3) for palette p color c; inv[p] is $80 if palette p
    uses COLPF3.
    """
    entries = {}
    for p in range(4):
        for c in range(1, 4):
            entries.setdefault(colors[p][c - 1], p * 4 + c)
    candidates = [col for col in entries if NES_RGB[col] != 0] or [BLACK]
    while len(candidates) < 4:
        candidates.append(candidates[0])

    best = None
    for four in itertools.combinations(range(len(candidates)), 4):
        for shared in itertools.combinations(four, 2):
            alt = [i for i in four if i not in shared]
            regs = [candidates[i] for i in list(shared) + alt]     # PF0, PF1, PF2, PF3
            cost, choice = 0, []
            for p in range(4):
                options = []
                for a in (2, 3):
                    targets = [BLACK, regs[0], regs[1], regs[a]]
                    slots = [min(range(4), key=lambda s: shown_error(colors[p][c - 1], targets[s]))
                             for c in range(1, 4)]
                    err = sum(weights[p][c] * shown_error(colors[p][c - 1], targets[slots[c - 1]])
                              for c in range(1, 4))
                    options.append((err, a, slots))
                err, a, slots = min(options)
                cost += err
                choice.append((a, slots))
            if best is None or cost < best[0]:
                best = (cost, regs, choice)

    _, regs, choice = best
    src = [entries.get(col, 0) for col in regs]
    slot = [[0] + slots for _, slots in choice]
    inv = [0x80 if a == 3 else 0 for a, _ in choice]
    return src, slot, inv


def map_plan(chr_rom, blocks, pal, bank=1):
    """A map palette's plan (pal, src, slot, inv), weighted by how much the
    map BLOCKS draw each color (as all_plans does for its map palettes)."""
    colors = [pal[p * 3:p * 3 + 3] for p in range(4)]
    return (pal,) + plan(colors, block_weights(chr_rom, blocks, bank))

