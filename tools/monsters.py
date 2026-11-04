"""Build-time battle monster graphics for the 5200 driver (used by build5200.py).

On the NES a monster is up to 40 sprites from CHR bank 3, far more than the
5200's players can show, so the driver draws it into the background
instead: each mode 4 character it covers gets a copy with the monster's
pixels laid over it (monster.asm). This module does the slow part ahead of
time, for each enemy and for each background color plan battles happen in
(the overworld's and the dungeons'). The final boss, the Dragonlord's true
form, is 64 sprites from CHR bank 0 in a fight with its own palette, and is
done the same way, as enemy 39, in that fight's plan:

* Colors. The rows the monster covers get their own COLPF0-3 (written by
  the display list interrupts), fed from the monster's sprite palette, so
  they follow its fades and flashes. A register may also keep the plan's
  color, when the monster can share it: the other cells on those rows (the
  scene, the map, the pop-up window) are drawn with these registers too.
  The register holding the windows' text color always keeps it.
* Pixels. The monster is put together from its sprites at full resolution
  (as LoadEnemyGFX places them), squeezed to 4 pixels per character row like
  the background, and each pixel given the register nearest its color.
  Per character: 8 bytes of pixel values and 8 of mask (3 where the monster
  is opaque); 3 means COLPF2, or COLPF3 in an inverse character, so a
  character uses one of the two (the less used one's pixels take their next
  nearest register). Then 8 bytes of pixels for the other one, used where
  the character beneath shows its pixels of value 3 in that one.

Each plan's data fills two SuperCart banks (MON_BANKS), at $8000, the
first starting with:

    40 headers of 32 bytes, by enemy number:
      +0  address of the first character record
      +2  first column and row on the screen (NES tiles)
      +4  width and height in characters (0: no monster)
      +6  the bank of the character records
      +7  sources for COLPF0-3 on the monster's rows (PalRAM index, or $FF
          to keep the plan's)
      +11 per row, the number of characters with monster pixels (16)
    then character records, row by row, left to right: a flag byte (0: no
    monster pixels; else bit 7 inverse wanted, bit 6 not inverse wanted,
    bit 0 set) and, unless 0, 8 pixel bytes, 8 mask bytes and 8 alternate
    pixel bytes.
"""
import itertools
import re
from collections import Counter

import colordata
from colordata import BLACK, shown_error

SCENE_COL, SCENE_ROW = 10, 8    # Screen tile of the overworld battle scene (LoadCombatBckgrnd).


def sprite_list(data, mirrored):
    """An enemy's sprites from its sprite list's bytes (3 a sprite, a 0 tile
    ends it), as sprite_lists gives them."""
    if True:
        sprites = []
        for i in range(0, len(data), 3):
            if data[i] == 0:
                break
            tile, b2, b3 = data[i:i + 3]
            x = (b3 >> 2) - 0x1C
            flips = b2 & 0xC0
            if mirrored:
                x = -x
                flips ^= 0x40
            sprites.append((tile, (b2 & 0x3F) + 0x44 + 1, (x + 0x84) & 0xFF, b3 & 3, flips))
        return sprites


def picture(chr_rom, sprites, bank=3, background=()):
    """{(x, y): palette entry} of the opaque pixels: sprite entries 1-15
    (palette * 4 + color), earlier sprites in front, over any BACKGROUND
    tiles (end_boss_background), opaque even in color 0: background entries
    16-31 (16 + palette * 4 + color)."""
    px = {}
    for tile, col, row, pal in background:
        tp = colordata.tile_pixels(chr_rom, bank, tile)
        for r in range(8):
            for c in range(8):
                px[(col * 8 + c, row * 8 + r)] = 16 + pal * 4 + tp[r][c]
    for tile, y0, x0, pal, flips in reversed(sprites):
        tp = colordata.tile_pixels(chr_rom, bank, tile)
        for r in range(8):
            for c in range(8):
                v = tp[7 - r if flips & 0x80 else r][7 - c if flips & 0x40 else c]
                if v:
                    px[(x0 + c, y0 + r)] = pal * 4 + v
    return px


def squeeze(px, colors):
    """{(x4, y): entry} at 4 pixels per character: of each pair of pixels, an
    opaque one over a clear one, else the thinner feature (as squeeze_tile)."""
    out = {}
    for (x, y) in px:
        out.setdefault((x // 2, y), None)
    for (x2, y) in list(out):
        a, b = px.get((2 * x2, y)), px.get((2 * x2 + 1, y))
        if a is None or b is None or a == b:
            out[(x2, y)] = a if a is not None else b
            continue
        run_a = 1 + (px.get((2 * x2 - 1, y)) == a)
        run_b = 1 + (px.get((2 * x2 + 2, y)) == b)
        out[(x2, y)] = a if run_a < run_b or (run_a == run_b and colors[a] != BLACK) else b
    return out

