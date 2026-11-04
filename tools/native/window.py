"""Build-time window data for the native engine (used by convert.py).

The STATUS window (StatusDat in Bank01, WndwDataPtrTbl's entry 1) is read
from the ROM as the game's window code reads it: a few header bytes, then
text tiles and control bytes (1CCCCPPP: C the function, P its parameter):
blanks ($80-$87, P of them, 0 to the row's end), border tiles ($88-$8F),
the name ($B0-$B7), an item's name ($B8-$BF: P 0 weapon, 1 armor, 2
shield; the first time its first half, the second time its second), a
stat ($D8-$DF: P 0 strength, 1 agility, 2 attack, 3 defense, 4 max HP, 5
max MP). The engine gets the window's tiles with the fields left blank,
and where each field goes; the labels stay the ROM's.
"""

import rom as romdata

BLANK = 0x5F
TOP_LEFT, TOP, TOP_RIGHT = 0x64, 0x62, 0x67
LEFT, RIGHT = 0x61, 0x66
BOTTOM_LEFT, BOTTOM, BOTTOM_RIGHT = 0x65, 0x68, 0x69

# Field kinds (the engine's StatusField): the name, a stat (its P), an
# item's half (weapon, armor, shield: first halves, then second halves).
F_NAME, F_STAT, F_ITEM = 0x00, 0x10, 0x20
NAME_WIDTH, STAT_WIDTH = 8, 3


def status_window(rom):
    """(width, rows: lists of tiles, fields: (row, col, kind, width))."""
    data = rom.table("StatusDat", romdata.AT_LEN["StatusDat"])
    width = data[2]                     # Tiles across, its borders too.
    inner = width - 2
    rows, fields, row, halves = [], [], [], {}

    def end_row():
        nonlocal row
        rows.append(row + [BLANK] * (inner - len(row)))
        row = []

    i = 4                               # (Past the header.)
    top = True
    while i < len(data):
        b = data[i]
        i += 1
        if b < 0x80:                    # A tile.
            row.append(b)
        else:
            func, p = b >> 3 & 0x0F, b & 7
            if func == 0:               # Blanks.
                if p == 0:
                    end_row()
                else:
                    row += [BLANK] * p
            elif func == 1:             # The top border (the first row).
                assert top and not row, "status: a border past the top"
                top = False
            elif func == 6:             # The name.
                fields.append((len(rows), len(row), F_NAME, NAME_WIDTH))
                row += [BLANK] * NAME_WIDTH
            elif func == 7:             # An item's half: what is left of the row.
                half = halves.get(p, 0)
                halves[p] = half + 1
                w = inner - len(row) if half == 0 else inner - len(row)
                fields.append((len(rows), len(row), F_ITEM + 3 * half + p, w))
                row += [BLANK] * w
                end_row()
            elif func == 11:            # A stat.
                fields.append((len(rows), len(row), F_STAT + p, STAT_WIDTH))
                row += [BLANK] * STAT_WIDTH
            else:
                raise ValueError(f"status: control ${b:02X} not handled")
            if len(row) > inner:
                raise ValueError("status: a row past the window's width")
            if len(row) == inner and b >= 0x80 and func in (6, 11):
                end_row()
    if row:
        end_row()
    out = [[TOP_LEFT] + [TOP] * inner + [TOP_RIGHT]]
    out += [[LEFT] + r + [RIGHT] for r in rows]
    out.append([BOTTOM_LEFT] + [BOTTOM] * inner + [BOTTOM_RIGHT])
    assert len(out) == 2 * data[1], (len(out), data[1])     # Its height, in blocks.
    assert all(len(r) == width for r in out)
    return width, out, [(r + 1, c + 1, k, w) for r, c, k, w in fields]


def status_place(rom):
    """The window's top row and left column on the screen (its position
    byte: Y and X in blocks, 2 tiles each)."""
    pos = rom.table("StatusDat", 4)[3]
    return 2 * (pos >> 4), 2 * (pos & 0x0F)
