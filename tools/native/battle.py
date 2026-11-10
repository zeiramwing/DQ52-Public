"""Build-time battle data for the native engine (used by convert.py).

* Enemies: each one's stats (EnStatTbl: attack, defense, HP, spells,
  agility, magic defense, experience, gold) and name (EnNames1Tbl and
  EnNames2Tbl, two halves).
* Where they are met: OvrWrldEnGrid (an 8 by 8 grid of 15-block zones, a
  nibble each) and EnemyGroupsTbl (5 enemies a zone).
* The hero's base stats per level (BaseStatsTbl).
* The battle scene: the game's overworld one (CombatBckgndGFX), in a window
  as the game puts it, and each monster on it, put together from its
  sprites at the game's screen place (monsters.py) and squeezed to 4 pixels
  per character row. Two bands of rows, each with its own character set:
  the upper one (from row 6 to the monster's top) in the map's colors, the
  lower one (the monster's rows) in colors chosen for the monster and the
  grass behind it. A character shows COLPF2 or COLPF3 (bit 7 of its code),
  not both: the less used one's pixels take their next nearest color.
* The text of the monster's band's character set: as the map's set has it from
  code 64 (TEXT_BASE_CODE), but every pixel of it COLPF0, so that the
  monster has the other three registers.
"""
import itertools
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))
import colordata  # noqa: E402
import monsters  # noqa: E402

ENEMIES = 40                    # The Dragonlord's two forms are 38 and 39.
EN_TRUE_FORM = 39               # The Dragonlord's second form: the end boss's picture (end_boss).
WHITE = 0x30                    # NES white: the text's color.


def enemy_stats(rom):
    """8 bytes an enemy (EnStatTbl, 16 each): attack, defense, HP, spells,
    agility, magic defense, experience, gold."""
    return [rom.table("EnStatTbl", 8, e * 16) for e in range(ENEMIES)]


def enemy_names(rom):
    """Each enemy's name in text tiles: the first half, a space and the
    second half (if any): EnNames1Tbl and EnNames2Tbl, $FF after each."""
    first, second = rom.strings("EnNames1Tbl", ENEMIES), rom.strings("EnNames2Tbl", ENEMIES)
    names = []
    for e in range(ENEMIES):
        a = [t for t in first[e] if t not in (0x5F, 0x60)]
        b = [t for t in second[e] if t not in (0x5F, 0x60)]
        names.append(a + ([0x5F] + b if b else []))
    return names


def zones(rom):
    return rom.table("OvrWrldEnGrid", 32)


GROUPS = 100                    # EnemyGroupsTbl: 14 overworld zones', 6 caves' rows of 5.


def enemy_groups(rom):
    """The 5 enemies of each group (EnemyGroupsTbl: the overworld zones')."""
    return rom.table("EnemyGroupsTbl", GROUPS)


def base_stats(rom):
    """Strength, agility, max HP, max MP for each level, from level 1
    (BaseStatsTbl: 6 bytes a level)."""
    return [rom.table("BaseStatsTbl", 4, i * 6) for i in range(30)]


def sprite_lists(rom):
    """Each enemy's sprites (EnSpritesPtrTbl: a pointer each, below $8000
    for a list drawn mirrored; 3 bytes a sprite, a 0 tile ends it), as
    monsters.sprite_list gives them."""
    out = []
    for w in rom.words("EnSpritesPtrTbl", ENEMIES - 1):
        mirrored = w >= 0x8000
        data = list(rom.read(1, w if mirrored else w + 0x8000, 3 * 64))
        out.append(monsters.sprite_list(data, mirrored))
    return out + [[]]                   # (His second form: end_boss.)


def enemy_palettes(rom):
    data = rom.table("EnSPPals", ENEMIES * 12)
    return [data[i * 12:i * 12 + 12] for i in range(ENEMIES)]


def nearest(rgb, choices):
    return min(range(len(choices)), key=lambda i: colordata.rgb_distance(rgb, colordata.ATARI_RGB[choices[i] // 2]))


# The overworld battle scene (CombatBckgndGFX): 14 by 14 tiles in a window
# at screen columns 10-23, rows 6-19 (the dialog window covers its last
# rows, so rows 6-17 are drawn). Each 2 by 2 block takes a palette by its
# first tile, as the game sets it: below $C1 0 (the sky), below $CA 1,
# below $DE 2, else 3.
SCENE_COL, SCENE_ROW, SCENE_SIZE, SCENE_SHOWN = 10, 6, 14, 12
MAX_GLYPHS = 63                 # Codes 1-63: the text is 64-115, and the
                                # engine puts the map beside the window in
                                # the codes left (and TEXT_END-127).
TEXT_END = 116                  # (convert.py's WIDE_CODE.) His second form's
BOSS_GLYPHS = MAX_GLYPHS + 128 - TEXT_END   # glyphs go on there too: no map
                                # shows round him.


def glyph_code(i):
    return i + 1 if i < MAX_GLYPHS else TEXT_END + i - MAX_GLYPHS


def scene_tiles(rom):
    data = rom.table("CombatBckgndGFX", SCENE_SIZE * SCENE_SIZE)
    return [data[r * SCENE_SIZE:(r + 1) * SCENE_SIZE] for r in range(SCENE_SIZE)]


def scene_palette(tiles, r, c):
    t = tiles[r & ~1][c & ~1]
    return 0 if t < 0xC1 else 1 if t < 0xCA else 2 if t < 0xDE else 3


def scene_colors(chr_rom, tiles, map_pal):
    """{(x4, y): NES color} of the scene's shown rows at 4 pixels a
    character, in screen coordinates (squeezed as the map's tiles are)."""
    out = {}
    for r in range(SCENE_SHOWN):
        for c in range(SCENE_SIZE):
            pal = scene_palette(tiles, r, c)
            px = colordata.tile_pixels(chr_rom, 1, tiles[r][c])
            sq = colordata.squeeze_tile(px)
            for y in range(8):
                for x in range(4):
                    v = sq[y] >> (6 - 2 * x) & 3
                    color = map_pal[pal * 3 + v - 1] if v else 0x0F
                    out[((SCENE_COL + c) * 4 + x, (SCENE_ROW + r) * 8 + y)] = color
    return out


def upper_band(chr_rom, tiles, slot, inv):
    """The scene in the map's colors (the upper band's): its glyphs from code
    1 and each shown cell's code (14 by 12)."""
    glyphs, grid = [], []
    for r in range(SCENE_SHOWN):
        for c in range(SCENE_SIZE):
            pal = scene_palette(tiles, r, c)
            px = [[slot[pal][v] for v in row] for row in colordata.tile_pixels(chr_rom, 1, tiles[r][c])]
            g = colordata.squeeze_tile(px)
            if g not in glyphs:
                glyphs.append(g)
            grid.append(glyph_code(glyphs.index(g)) | inv[pal])
    if len(glyphs) > 63:
        sys.exit(f"battle: the scene has {len(glyphs)} glyphs")
    return glyphs, grid


def glyph_distance(a, b):
    """How many pixels two glyphs differ in."""
    return sum(1 for x, y in zip(a, b) for i in range(0, 8, 2) if (x >> i & 3) != (y >> i & 3))


# The end boss (LoadEndBossGFX): on a black screen, 19 background tiles
# (EndBossBGTiles: a tile and its PPU address each, then 4 attribute
# bytes) and 64 sprites (EndBossSPTiles: as sprite RAM, $FF $FF ending),
# all from CHR bank 0, in his own palettes (EndBossPal1: background,
# EndBossPal2: sprites). Moved by BOSS_SHIFT to stand in the scene window.
BOSS_SHIFT = (16, -14)          # (NES pixels: from x 81-155, y 65-156.)


def end_boss(rom, chr_rom):
    """{(x, y): NES color} of the end boss's opaque pixels, at the scene
    window's place on the screen."""
    bg = rom.table("EndBossBGTiles", 0x45)
    sprites = rom.table("EndBossSPTiles", 0x104)
    pal_bg, pal_sp = rom.table("EndBossPal1", 12), rom.table("EndBossPal2", 12)
    tiles = [(bg[i], bg[i + 1] | bg[i + 2] << 8) for i in range(0, len(bg), 3)]
    # (The game puts each of the first 19 two to the left of its address:
    # LoadEndBossGFX takes 2 off all but the last 4, the attributes'.)
    tiles = [(t, at - 2 if i < len(tiles) - 4 else at) for i, (t, at) in enumerate(tiles)]
    attrs = {at: t for t, at in tiles if at >= 0x23C0}
    px = {}
    for tile, at in tiles:
        if at >= 0x23C0:
            continue
        row, col = divmod(at - 0x2000, 32)
        a = attrs.get(0x23C0 + row // 4 * 8 + col // 4, 0)
        pal = a >> ((row % 4) // 2 * 4 + (col % 4) // 2 * 2) & 3
        tp = colordata.tile_pixels(chr_rom, 0, tile)
        for y in range(8):
            for x in range(8):
                if tp[y][x]:
                    px[(col * 8 + x, row * 8 + y)] = pal_bg[pal * 3 + tp[y][x] - 1]
    ram, i = [], 0                      # (As the game copies them to sprite RAM:
    while len(ram) < 256:               # a lone $FF takes the next byte's value,
        b = sprites[i]                  # $FF $FF ends them.)
        if b == 0xFF:
            b = sprites[i + 1]
            if b == 0xFF:
                break
        ram.append(b)
        i += 1
    listed = [ram[i:i + 4] for i in range(0, len(ram) - 3, 4)]
    for y0, tile, attr, x0 in reversed(listed):     # (Earlier sprites in front.)
        tp = colordata.tile_pixels(chr_rom, 0, tile)
        for y in range(8):
            for x in range(8):
                v = tp[7 - y if attr & 0x80 else y][7 - x if attr & 0x40 else x]
                if v:
                    px[(x0 + x, y0 + 1 + y)] = pal_sp[(attr & 3) * 3 + v - 1]
    dx, dy = BOSS_SHIFT
    return {(x + dx, y + dy): c for (x, y), c in px.items()}


def monster(chr_rom, sprites, palette, scene, map_regs, picture=None):
    """A monster on the scene: its record (see below) and its glyph count.

    The lower band runs from the monster's top row to row 17. Its colors:
    COLBK black, COLPF0 white (the text's), and three chosen for the
    monster's pixels and (a quarter as much) the scene's on those rows.
    Record: the band's first row, COLPF1-3, how the map beside the window
    shows in the band (each pixel value's new one for a character without
    bit 7, then with it, then the new bit 7 for each), the glyph count, then 14 codes a row with the monster and 14 a row
    without it (once it is gone), then the glyphs (codes 1-63, 114-127)."""
    if picture is None:
        px = monsters.picture(chr_rom, sprites)
        colors = {k: (palette[(k >> 2) * 3 + (k & 3) - 1] if k & 3 else 0x0F) for k in range(16)}
    else:                                       # (NES colors already: the end boss.)
        px, colors = picture, {c: c for c in set(picture.values())}
    sq = {k: colors[v] for k, v in monsters.squeeze(px, colors).items() if v is not None}
    top = max(SCENE_ROW + (picture is None), min((y for x, y in sq), default=8 * (SCENE_ROW + SCENE_SHOWN - 1)) // 8)
    rows = range(top, SCENE_ROW + SCENE_SHOWN)
    counts = {}
    for color in sq.values():
        counts[color] = counts.get(color, 0) + 4
    for (x, y), color in scene.items():
        if y // 8 in rows and color != 0x0F:
            counts[color] = counts.get(color, 0) + 1
    white = colordata.NES_TO_ATARI[WHITE]
    pool = list(dict.fromkeys(colordata.NES_TO_ATARI[c] for c in sorted(counts, key=lambda c: -counts[c])))[:8]
    while len(pool) < 3:
        pool.append(white)
    best = None
    for three in itertools.permutations(pool, 3):
        regs = [0x00, white] + list(three)
        err = sum(n * min(colordata.rgb_distance(colordata.NES_RGB[c], colordata.ATARI_RGB[r // 2]) for r in regs)
                  for c, n in counts.items())
        if best is None or err < best[0]:
            best = (err, regs)
    regs = best[1]
    remap = [nearest(colordata.ATARI_RGB[r // 2], regs) for r in map_regs]

    def glyph(r, c, with_monster):
        cell = []
        for y in range(8):
            row = []
            for x in range(4):
                key = (c * 4 + x, r * 8 + y)
                color = sq.get(key) if with_monster else None
                row.append(scene.get(key, 0x0F) if color is None else color)
            cell.append(row)
        want = [[0 if v == 0x0F else nearest(colordata.NES_RGB[v], regs) for v in row] for row in cell]
        keep = 3 if sum(row.count(3) for row in want) >= sum(row.count(4) for row in want) else 4
        data = bytearray()
        for y in range(8):
            byte = 0
            for x in range(4):
                k = want[y][x]
                if k in (3, 4) and k != keep:
                    choices = [0, 1, 2, keep]
                    k = choices[nearest(colordata.NES_RGB[cell[y][x]], [regs[i] for i in choices])]
                byte = byte << 2 | (3 if k >= 3 else k)
            data.append(byte)
        return bytes(data), 0x80 if keep == 4 else 0

    cells = ([], [])
    uses = {}
    for which, with_monster in ((0, True), (1, False)):
        for r in rows:
            for c in range(SCENE_COL, SCENE_COL + SCENE_SIZE):
                g, flag = glyph(r, c, with_monster)
                cells[which].append((g, flag))
                uses[g] = uses.get(g, 0) + 1
    blank = bytes(8)                    # (All black: code 0, no glyph of its own.)
    glyphs = sorted((g for g in uses if g != blank), key=lambda g: -uses[g])
    room = MAX_GLYPHS if picture is None else BOSS_GLYPHS
    kept = glyphs[:room]
    # Too many: the least used take the nearest kept glyph's place.
    place = {g: i for i, g in enumerate(kept)}
    for g in glyphs[room:]:
        place[g] = min(range(len(kept)), key=lambda i: glyph_distance(g, kept[i]))
    glyphs = kept
    grids = tuple([0 if g == blank else glyph_code(place[g]) | flag for g, flag in cells[w]] for w in (0, 1))
    # How the map's pixels show in the band: for a character without and
    # with bit 7 (COLPF3 for value 3), each value's new one and the new bit 7.
    values, inverse = [], []
    for b in (0, 1):
        targets = [remap[0], remap[1], remap[2], remap[3 + b]]
        values += [min(t, 3) for t in targets]
        inverse.append(0x80 if targets[3] == 4 else 0)
    glyphs = glyphs or [blank]          # (One at least: CopyGlyphs. A dark one all black on black.)
    record = bytes([top] + regs[2:5] + values + inverse + [len(glyphs)]) + bytes(grids[0]) + bytes(grids[1])
    return record + b"".join(glyphs), len(glyphs)


def monster_records(rom, chr_rom, plan):
    """Each monster's record, and the upper band (glyphs, grid)."""
    pal, src, slot, inv = plan
    map_regs = [0x00] + [colordata.NES_TO_ATARI[pal[(i // 4) * 3 + i % 4 - 1]] for i in src]
    tiles = scene_tiles(rom)
    scene = scene_colors(chr_rom, tiles, pal)
    lists = sprite_lists(rom)
    palettes = enemy_palettes(rom)
    boss = end_boss(rom, chr_rom)
    pictures = [boss if e == EN_TRUE_FORM else None for e in range(ENEMIES)]
    records = [monster(chr_rom, lists[e], palettes[e], scene, map_regs, pictures[e]) for e in range(ENEMIES)]
    # And each on black, for the caves' battles (no scene there; his
    # second form's too, on his castle's floor).
    dark = [monster(chr_rom, lists[e], palettes[e], {}, map_regs, pictures[e]) for e in range(ENEMIES)]
    return records, upper_band(chr_rom, tiles, slot, inv), dark


def white_text(glyph):
    """A text glyph with every lit pixel COLPF0 (value 1)."""
    out = bytearray()
    for b in glyph:
        v = 0
        for i in range(4):
            v = v << 2 | (1 if b >> (6 - 2 * i) & 3 else 0)
        out.append(v)
    return bytes(out)
