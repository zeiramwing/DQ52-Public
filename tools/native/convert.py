"""Build-time conversion of Dragon Warrior's data for the native 5200 engine.

Everything the engine shows is finished here: map blocks become mode 4
characters with their colors chosen, the overworld becomes block numbers
with the water shores worked out, and so on. The engine only copies.
"""
import os
from collections import Counter
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
CARRY_OFFSET = 0xC0             # CharSpriteTbl: the hero carrying the princess.
ANIM_MAX = 32                   # A map's townspeople's characters that step (AnimCodes).
GFX_ANIM = 0x8B00               # Where anim.bin goes in GFX_BANK (castle.asm's alias).


def colour_pixels(chr_rom, table, palettes, direction, step, offset):
    """A 16x16 figure's NES colors (None: clear) facing DIRECTION in step 0
    or 1, from CharSpriteTbl's OFFSET, each sprite in its own palette of
    PALETTES (RegSPPal: 3 colors each)."""
    at = direction * 256 + offset + step * 8
    px = [[None] * 16 for _ in range(16)]
    for i in range(4):
        tile, attr = table[at + 2 * i], table[at + 2 * i + 1]
        t = colordata.tile_pixels(chr_rom, SPRITE_BANK, tile)
        if attr & 0x40:
            t = [row[::-1] for row in t]
        if attr & 0x80:
            t = t[::-1]
        for y in range(8):
            for x in range(8):
                if t[y][x]:
                    px[(i >> 1) * 8 + y][(i & 1) * 8 + x] = palettes[(attr & 3) * 3 + t[y][x] - 1]
    return px


def squeeze_colours(row):
    """A row of 16 colors (None: clear) to 8, keeping thin features (as
    squeeze_tile): of two that differ, a color over clear, else the one
    whose run is shorter, on a tie the rarer in the row."""
    count = Counter(row)
    out = []
    for x in range(0, 16, 2):
        a, b = row[x], row[x + 1]
        if a != b:
            if a is None or b is None:
                a = b if a is None else a
            else:
                run_a = 1 + (x > 0 and row[x - 1] == a)
                run_b = 1 + (x < 14 and row[x + 2] == b)
                a = a if (run_a < run_b if run_a != run_b else count[a] <= count[b]) else b
        out.append(a)
    return out


def hero_frames(chr_rom, table, palettes, offset):
    """The hero's 8 frames (direction * 2 + step) from CharSpriteTbl's OFFSET
    (HERO_OFFSET, or CARRY_OFFSET: carrying the princess), 64 bytes each:
    players 0, 1 and 2's 16 lines, 16 unused; and the three player colors.
    Each NES color shows as the nearest of COLPM0, COLPM1, where both
    overlap (the two ORed: multicolor players) and COLPM2, the three chosen
    for the least error: his own three colors come out exact, and with
    her four the overlap makes the fourth."""
    frames = [[squeeze_colours(r) for r in colour_pixels(chr_rom, table, palettes, d, s, offset)]
              for d in range(4) for s in range(2)]
    weights = Counter(c for f in frames for row in f for c in row if c is not None)
    want = {c: colordata.NES_RGB[c] for c in weights}
    dist = [{c: colordata.rgb_distance(want[c], colordata.ATARI_RGB[a]) for c in want} for a in range(128)]
    thirds = sorted({colordata.NES_TO_ATARI[c] // 2 for c in want})    # (COLPM2: one of theirs.)
    best = None
    for a in range(128):
        for b in range(a, 128):
            pair = {c: min(dist[a][c], dist[b][c], dist[a | b][c]) for c in want}
            for t in thirds:
                err = sum(n * min(pair[c], dist[t][c]) for c, n in weights.items())
                if best is None or err < best[0]:
                    best = (err, a, b, t)
    _, a, b, t = best
    shown = {}
    for c in want:
        e = [dist[a][c], dist[b][c], dist[a | b][c], dist[t][c]]
        k = e.index(min(e))
        shown[c] = (k in (0, 2), k in (1, 2), k == 3)   # (In player 0, 1, 2.)
    data = bytearray()
    for f in frames:
        for player in (0, 1, 2):
            for row in f:
                byte = 0
                for c in row:
                    byte = byte << 1 | (c is not None and shown[c][player])
                data.append(byte)
        data += bytes(16)
    return bytes(data), [2 * a, 2 * b, 2 * t]


def squeeze_wide(px):
    """16-pixel rows to 8, keeping thin features (as squeeze_tile)."""
    out = []
    for row in px:
        left = colordata.squeeze_tile([row[:8]] * 8)[0]
        right = colordata.squeeze_tile([row[8:]] * 8)[0]
        out.append([left >> (6 - 2 * i) & 3 for i in range(4)] + [right >> (6 - 2 * i) & 3 for i in range(4)])
    return out


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
LOWER = range(0x0A, 0x24)       # Shown in windows as capitals (UPPER, + $1A).
# Punctuation with codes of its own in set A, after the name slots: the
# apostrophe (item names) and the STATUS window's mark, in every map; then
# the name window's - . ? ! (it opens only at power-on, on the start map),
# whose codes a wide town gives its own characters (WIDE_CODE on).
PUNCT = (0x40, 0x44)
NAME_PUNCT = (0x49, 0x47, 0x4B, 0x4C)


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


def hires_char(chr_rom, tile):
    """A text tile as a mode 2 character (set B: the dialog window's rows,
    shown in ANTIC mode 2): the NES tile at its full 8 pixels, every lit
    pixel the text's (COLPF1's brightness on COLPF2)."""
    px = colordata.tile_pixels(chr_rom, BG_BANK, tile)
    return bytes(sum(1 << (7 - x) for x in range(8) if row[x]) for row in px)


def text_blocks(rom):
    """All 19 text blocks' bytes (one after another in bank 2), and where
    each starts."""
    first = romdata.TEXT_BLOCKS[0]
    return bytes(rom.read(2, first, romdata.TEXT_LENGTH)), [a - first for a in romdata.TEXT_BLOCKS]


TEXT_BASE_CODE = 64             # Set A: map characters below, text from here.
IMAGE_SIZE = 0x500              # Per map: set A, a page of tables. (Set B is every map's: setb.bin.)
IMAGES_PER_BANK = 7             # 7 * $900 in a bank's data half; more go in IMAGES2_BANK, 3.
TOWNS_PER_BANK = 15             # 1KB town pages in a bank's data half.


def composite_chars(chr_rom, blocks, plan, pf, base, person):
    """Block BASE with a townsperson drawn into it as background (people_looks), 4 mode 4 characters (upper left, upper right, lower left,
    lower right) and their bit 7. PERSON is 16 rows of 16 NES colors (None
    where the block shows): each such pixel becomes the nearest of the colors
    its character can show (COLBK, COLPF0, COLPF1, and COLPF2 or COLPF3 as
    the block's palette has bit 7)."""
    pal, src, slot, inv = plan
    tiles, bpal = blocks[base]
    regs = [0x00, pf[0], pf[1], pf[3] if inv[bpal] else pf[2]]
    rgb = [colordata.ATARI_RGB[a // 2] for a in regs]
    out = []
    for q, tile in enumerate(tiles):
        px = colordata.tile_pixels(chr_rom, BG_BANK, tile)
        vals = [[slot[bpal][c] for c in row] for row in px]
        for y in range(8):
            for x in range(8):
                c = person[(q >> 1) * 8 + y][(q & 1) * 8 + x]
                if c is not None:
                    want = colordata.NES_RGB[c]
                    vals[y][x] = min(range(4), key=lambda v: colordata.rgb_distance(want, rgb[v]))
        out.append((colordata.squeeze_tile(vals), inv[bpal]))
    return out


def sprite_table_of(rom):
    return rom.table("CharSpriteTbl", 1024)


# Maps whose people must stay sprites: the Dragonlord's floor (his figure is
# swapped in there) and the staff of rain's cave (its old man goes); and the
# princess anywhere (in the throne room only once she is home).
PEOPLE_SPRITE_MAPS = {6, 13}
PRINCESS_CONTROL = 0x6F


def people_looks(chr_rom, town, grid, border, people, table, sprite_pal):
    """The town's people standing still, drawn into its background where
    there is room: for each look (the block under them, their figure and
    facing), a composite block on a block number the town does not use
    (map_image takes the ones that fit), in both steps of the figure's
    walk. Returns those blocks (the block under, step 0, step 1) and each
    person's look's block number (None: a sprite)."""
    if town["number"] in PEOPLE_SPRITE_MAPS:
        return {}, [None] * len(people)
    used = {b for row in grid for b in row} | {border}
    spare = [b for b in range(40) if b not in used]
    extra, by_look, looks = {}, {}, [None] * len(people)
    # Those with the most others a row or less from them first: what stays a
    # sprite then crowds the players' rows least (two people a row apart or
    # less cannot share one; with two players, a third would not show).
    crowd = [sum(1 for q in people if q is not p and abs(q[2] - p[2]) <= 1) for p in people]
    for i in sorted(range(len(people)), key=lambda i: -crowd[i]):
        graphic, x, y, facing, control = people[i][:5]
        look = (grid[y][x], graphic, facing)
        if control == PRINCESS_CONTROL or (look not in by_look and not spare):
            continue
        if look not in by_look:
            steps = []
            for step in (0, 1):
                px, ppal = maps.person_pixels(chr_rom, table, graphic, facing, step)
                colors = sprite_pal[ppal * 3:ppal * 3 + 3]
                steps.append([[colors[c - 1] if c else None for c in row] for row in px])
            by_look[look] = spare.pop(0)
            extra[by_look[look]] = (look[0], *steps)
        looks[i] = by_look[look]
    return extra, looks


def people_into_blocks(grid, people, looks, accepted):
    """Each person whose look map_image took: its block in the town's map, and
    the person marked drawn in the background (mobile $80: still talked to,
    not drawn as a sprite). No one wanders (mobile 0)."""
    out = []
    for p, b in zip(people, looks):
        graphic, x, y, facing, control, _ = p
        if b in accepted:
            grid[y][x] = b
            out.append((graphic, x, y, facing, control, 0x80))
        else:
            out.append((graphic, x, y, facing, control, 0))
    return out


FLOOR_REACH = 6                 # How far a wanderer may be moved onto the floor.


def open_spot(grid, taken, x, y):
    """Whether someone standing still at X, Y blocks nothing: the block and
    its eight neighbors walkable (never beside a wall's gap, a counter, a
    door or a sign, so no passage or counter is plugged), no one else within
    a block, and every walkable neighbor still reachable from the others."""
    h, w = len(grid), len(grid[0])
    def walk(a, b):
        return 0 <= b < h and 0 <= a < w and grid[b][a] not in BLOCKED and (a, b) not in taken
    if not walk(x, y):
        return False
    for dy in (-1, 0, 1):
        for dx in (-1, 0, 1):
            if (dx or dy) and (not (0 <= y + dy < h and 0 <= x + dx < w)
                               or grid[y + dy][x + dx] in BLOCKED or (x + dx, y + dy) in taken):
                return False
    near = [(x + dx, y + dy) for dx, dy in ((0, -1), (1, 0), (0, 1), (-1, 0))]
    seen, todo = {near[0]}, [near[0]]
    while todo:
        a, b = todo.pop()
        for q in ((a, b - 1), (a + 1, b), (a, b + 1), (a - 1, b)):
            if q not in seen and q != (x, y) and walk(*q):
                seen.add(q)
                todo.append(q)
    return all(q in seen for q in near)


def onto_floor(grid, people):
    """Each townsperson who wandered in the game (mobile 1) set down on the
    town's main floor (the commonest block under the wanderers) at the
    nearest open spot (open_spot) within FLOOR_REACH blocks, facing down:
    one block under them all, so their looks share characters. Anyone with
    no such spot keeps the game's place. The others keep theirs."""
    under = [grid[p[2]][p[1]] for p in people if p[5] and grid[p[2]][p[1]] not in BLOCKED]
    if not under:
        return people
    floor = max(set(under), key=under.count)
    people = list(people)
    for i, (g, x, y, f, c, m) in enumerate(people):
        if not m:
            continue
        taken = {(p[1], p[2]) for j, p in enumerate(people) if j != i}
        if grid[y][x] == floor and open_spot(grid, taken, x, y):
            continue
        spots = sorted(((x + dx, y + dy) for dx in range(-FLOOR_REACH, FLOOR_REACH + 1)
                        for dy in range(-FLOOR_REACH, FLOOR_REACH + 1)
                        if abs(dx) + abs(dy) <= FLOOR_REACH),
                       key=lambda q: (abs(q[0] - x) + abs(q[1] - y), q[1], q[0]))
        for nx, ny in spots:
            if 0 <= ny < len(grid) and 0 <= nx < len(grid[0]) and grid[ny][nx] == floor \
                    and open_spot(grid, taken, nx, ny):
                people[i] = (g, nx, ny, f, c, m)
                break
    return people


SPREAD_REACH = 5                # How far a wanderer may be moved, in blocks.


def crowded(people):
    """The sprites (mobile 0) a row or less from two others also within a
    screen's width: the 5200's two sprite players cannot show all three."""
    sprites = [i for i, p in enumerate(people) if p[5] == 0]
    out = set()
    for i in sprites:
        near = [j for j in sprites if abs(people[j][2] - people[i][2]) <= 1
                and abs(people[j][1] - people[i][1]) <= 15]
        if len(near) > 2:
            out |= set(near)
    return out


def spread_sprites(grid, people, wanders):
    """Where three sprites would crowd the same rows, one that wandered in the
    game (WANDERS: never a guard, shopkeeper, the King or anyone the game
    stands still) is moved to the nearest free floor within SPREAD_REACH
    blocks that ends the crowding: not a wall, door or counter (BLOCKED), not
    where anyone stands. The game's own places are kept for everyone else."""
    people = list(people)
    for _ in range(len(people)):
        crowd = crowded(people)
        movable = [i for i in crowd if wanders[i]]
        if not movable:
            break
        taken = {(p[1], p[2]) for p in people}
        best = None
        for i in movable:
            g, x, y, f, c, m = people[i]
            for nx, ny in sorted(((x + dx, y + dy) for dx in range(-SPREAD_REACH, SPREAD_REACH + 1)
                                  for dy in range(-SPREAD_REACH, SPREAD_REACH + 1)),
                                 key=lambda q: abs(q[0] - x) + abs(q[1] - y)):
                if not (0 <= ny < len(grid) and 0 <= nx < len(grid[0])) or (nx, ny) in taken:
                    continue
                if grid[ny][nx] in BLOCKED or abs(nx - x) + abs(ny - y) > SPREAD_REACH:
                    continue
                trial = people[:i] + [(g, nx, ny, f, c, m)] + people[i + 1:]
                if len(crowded(trial)) < len(crowd):
                    d = abs(nx - x) + abs(ny - y)
                    if best is None or d < best[0]:
                        best = (d, i, nx, ny)
                    break
        if best is None:
            break
        _, i, nx, ny = best
        g, x, y, f, c, m = people[i]
        people[i] = (g, nx, ny, f, c, m)
    return people


TEXT_CODES = len(DIGITS) + len(UPPER) + len(FRAME) + 1 + NAME_SLOTS + len(PUNCT)
WIDE_CODE = TEXT_BASE_CODE + TEXT_CODES           # A wide map's 65th character's code.
assert WIDE_CODE == battle.TEXT_END


def char_code(i):
    """Map character I's code: the first 64 their own, a wide map's further
    ones after the text (WIDE_CODE on)."""
    return i if i < TEXT_BASE_CODE else WIDE_CODE + i - TEXT_BASE_CODE


OPEN_WATER = WATER_BLOCKS[0]    # The open sea's block (its characters A B / B A).


def ripple(a, b):
    """The open sea's two characters with their waves a pixel to the right
    (each row of A B, and of B A, as one row of 8 that wraps round)."""
    def px(g, y):
        return [g[y] >> (6 - 2 * x) & 3 for x in range(4)]

    def pack(row):
        return row[0] << 6 | row[1] << 4 | row[2] << 2 | row[3]
    out_a, out_b = bytearray(), bytearray()
    for y in range(8):
        pa, pb = px(a, y), px(b, y)
        out_a.append(pack([pb[3]] + pa[:3]))
        out_b.append(pack([pa[3]] + pb[:3]))
    return bytes(out_a), bytes(out_b)


def map_image(chr_rom, blocks, used, plan, tiles, extra=None, wide=False, sea=False):
    """A map's 2.25KB image, copied to RAM ($2000) when the hero enters:
    set A (its blocks' characters, then the window text at TEXT_BASE_CODE
    and the name slots), set B (every text tile), and a page of tables:
    each block's 4 characters (+0, +40, +80, +120), whether the hero can
    walk onto it (+160), and the colors (+200: COLPF0-3, COLBK). A WIDE map
    (a town: no battle there reads set A's codes past the text) may also
    take the codes from WIDE_CODE to 127, the name window's punctuation's,
    for more people in the background."""
    pal, src, slot, inv = plan
    room = TEXT_BASE_CODE + (128 - WIDE_CODE if wide else 0)
    chars, codes = block_chars(chr_rom, blocks, used, slot, inv)
    block_only = list(chars)                        # (The blocks' own characters.)
    pf = [colordata.NES_TO_ATARI[pal[(i // 4) * 3 + i % 4 - 1]] for i in src]
    accepted, second = set(), {}
    for b, (base, person, person1) in (extra or {}).items():     # (People in the background.)
        made = composite_chars(chr_rom, blocks, plan, pf, base, person)
        made1 = composite_chars(chr_rom, blocks, plan, pf, base, person1)
        new = {data for data, _ in made if data not in chars}
        if len(chars) + len(new) > room:                # (No room: a sprite then.)
            continue
        four = []
        for (data, bit7), (data1, _) in zip(made, made1):
            if data not in chars:
                chars.append(data)
            four.append(char_code(chars.index(data)) | bit7)
            second.setdefault(chars.index(data), set()).add(data1)
        codes[b] = four
        accepted.add(b)
    # Their other step: each character of theirs that differs in it, unless
    # it is also a block's own or two looks' share it with different steps
    # (then it stands still). The engine swaps them every 16 frames.
    steps = [(char_code(i), next(iter(d))) for i, d in sorted(second.items())
             if i >= len(block_only) and len(d) == 1 and next(iter(d)) != chars[i]]
    if sea and OPEN_WATER in codes:     # The overworld: its sea's waves sway.
        a, b = (codes[OPEN_WATER][k] & 0x7F for k in (0, 1))
        steps += list(zip((a, b), ripple(chars[a], chars[b])))
    if len(steps) > ANIM_MAX:
        sys.exit(f"convert: {len(steps)} characters of townspeople to animate, more than {ANIM_MAX}")
    free = char_code(len(chars))        # The first code no map character uses.
    over, chars = chars[TEXT_BASE_CODE:], chars[:TEXT_BASE_CODE]
    chars += [bytes(8)] * (TEXT_BASE_CODE - len(chars))
    for t in list(DIGITS) + list(UPPER) + list(FRAME) + [ARROW]:
        chars.append(text_char(chr_rom, t, slot))
    chars += [bytes(8)] * NAME_SLOTS
    chars += [text_char(chr_rom, t, slot) for t in PUNCT]
    chars += over or [text_char(chr_rom, t, slot) for t in NAME_PUNCT]  # (Wide: the rest.)
    image = bytearray(0x900)            # (As in RAM: set B's place skipped below.)
    image[0:len(chars) * 8] = b"".join(chars)
    for b in range(max(len(blocks), max(codes, default=0) + 1)):
        four = codes.get(b, [0, 0, 0, 0])
        for k in range(4):
            image[0x800 + 40 * k + b] = four[k]
        image[0x800 + 160 + b] = 1 if b in BLOCKED or b in accepted else 0
    pf = [colordata.NES_TO_ATARI[pal[(i // 4) * 3 + i % 4 - 1]] for i in src]
    image[0x800 + 200:0x800 + 205] = bytes(pf + [0x00])
    image = image[:0x400] + image[0x800:]
    return bytes(image), len([c for c in chars[:TEXT_BASE_CODE] if c != bytes(8)]) + 1, free, accepted, steps


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
    for t in LOWER:
        text_a[t] = text_a[t + 0x1A]
    name_slot = TEXT_BASE_CODE + len(list(DIGITS) + list(UPPER) + list(FRAME)) + 1
    for i, t in enumerate(PUNCT + NAME_PUNCT):
        text_a[t] = name_slot + NAME_SLOTS + i
    text_b = [0] * 256
    for i, t in enumerate(tiles):
        text_b[t] = i + 1

    world = world_blocks(world_types(rom))
    images, counts = [], []
    image, n, free, _, sea = map_image(chr_rom, blocks, {b for row in world for b in row},
                                       color_plan(rom, chr_rom, "OverworldPal"), tiles, sea=True)
    images.append(image)
    counts.append(n)
    free_codes = [free]
    anims = [sea]                                   # (The overworld: its sea's.)
    towns, everyone, starts = bytearray(), [], []
    town_plan = color_plan(rom, chr_rom, "TownPal")
    dungeon_plan = color_plan(rom, chr_rom, "DungeonPal")
    for town in maps.TOWNS:
        grid = maps.town_blocks(rom, town)
        _, size, border, _ = maps.map_info(rom, town["number"])
        town_people = maps.people(rom, town)
        if town["number"] not in PEOPLE_SPRITE_MAPS:
            town_people = onto_floor(grid, town_people)
        extra, looks = people_looks(chr_rom, town, grid, border, town_people,
                                    sprite_table_of(rom), rom.table("RegSPPal", 12))
        image, n, free, accepted, steps = map_image(chr_rom, blocks, {b for row in grid for b in row} | {border},
                                             dungeon_plan if town["number"] >= maps.DARK_FROM else town_plan,
                                             tiles, extra, wide=town["number"] < maps.DARK_FROM)
        wanders = [p[5] for p in town_people]
        town_people = people_into_blocks(grid, town_people, looks, accepted)
        town_people = spread_sprites(grid, town_people, wanders)
        if sum(1 for q in town_people if q[5] == 0) > 1:    # (The engine draws one: SpriteOne.)
            sys.exit(f"convert: {town['name']} has more than one person not in its background")
        images.append(image)
        counts.append(n)
        free_codes.append(free)
        anims.append(steps)
        page = bytearray([border] * 1024)
        for y, row in enumerate(grid):
            page[y * 32:y * 32 + len(row)] = bytes(row)
        towns += page
        starts.append(len(everyone))
        everyone += town_people
    starts.append(len(everyone))

    os.makedirs(out_dir, exist_ok=True)
    # The townspeople's other step (GFX_BANK at GFX_ANIM): each map's
    # address, then for each map its count, its characters' codes and their
    # glyphs in the other step (LoadAnim copies them to RAM; AnimStep swaps).
    anim = bytearray(2 * len(anims))
    for m, steps in enumerate(anims):
        at = GFX_ANIM + len(anim)
        anim[2 * m:2 * m + 2] = bytes([at & 0xFF, at >> 8])
        anim += bytes([len(steps)] + [code for code, _ in steps]) + b"".join(g for _, g in steps)
    with open(os.path.join(out_dir, "anim.bin"), "wb") as f:
        f.write(anim)
    with open(os.path.join(out_dir, "setb.bin"), "wb") as f:    # Set B: code 0 blank, then every text tile.
        f.write((bytes(8) + b"".join(hires_char(chr_rom, t) for t in tiles)).ljust(0x400, b"\0"))
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
    hero, hero_colors = hero_frames(chr_rom, sprite_table, sprite_pal, HERO_OFFSET)
    carry, carry_colors = hero_frames(chr_rom, sprite_table, sprite_pal, CARRY_OFFSET)
    with open(os.path.join(out_dir, "hero.bin"), "wb") as f:    # GFX_HERO: 16 frames.
        f.write(hero + carry)
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
    # Then each effect's noise texture (sound.py's NOISE_DIST: AUDC's
    # distortion bits; the port's own).
    noise_dist_at = div_at + len(dividers)
    with open(os.path.join(out_dir, "sound.bin"), "wb") as f:
        f.write(sound_data + sound_tables + dividers + bytes(sound.NOISE_DIST))
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
        f.write(f".alias TEXT_END         {WIDE_CODE}  ;The first code past set A's text.\n")
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
        f.write(";COLPM0-2 for the hero, COLPM3's color for each townsperson graphic.\n")
        f.write(asm_bytes("HeroColors", hero_colors + carry_colors))      # (Then carrying her.)
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
        f.write(f".alias NoiseDist        ${noise_dist_at:04X}\n")
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
