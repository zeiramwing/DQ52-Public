"""Build-time item and shop data for the native engine (used by convert.py).

Items are numbered as the game's ItemCostTbl numbers them (its shops'
tables and its buying use those numbers): 0-6 weapons, 7-13 armor, 14-16
shields, 17 the herb, 18 the magic key, then the inventory items, the
game's ITM_ codes (torch 1 on) each at 18 + its code. Each has its price
(ItemCostTbl) and its name (the game's item name tables, two halves each:
the first table's for most, the second's for a few; their order is the
window cost table's, not ItemCostTbl's).
"""

ITEMS = 33                      # Bamboo pole (0) to the rainbow drop (32).
SPELLS = 10                     # Then the spells, as items 33-42 (SPELL_ITEM on):
SPELL_ITEM = ITEMS              # their MP cost as their price, their name.
HERB, KEY = 17, 18
ITM_BASE = 18                   # Item 18 + an ITM_ code.

# Each item's name: (table, entry) in the game's name tables (1: the first,
# 2: the second).
NAME_AT = [(1, i) for i in range(17)] + [
    (1, 17),                    # Herb.
    (1, 21),                    # Magic key.
    (1, 18),                    # Torch.
    (1, 22),                    # Fairy water.
    (1, 20),                    # Wings.
    (1, 19),                    # Dragon's scale.
    (1, 25),                    # Fairy flute.
    (2, 2),                     # Fighter's ring.
    (2, 3),                     # Erdrick's token.
    (1, 29),                    # Gwaelin's love.
    (2, 0),                     # Cursed belt.
    (1, 26),                    # Silver harp.
    (2, 1),                     # Death necklace.
    (1, 28),                    # Stones of sunlight.
    (1, 27),                    # Staff of rain.
    (1, 30),                    # Rainbow drop.
]
SPACE = 0x5F


def names(rom, at=None):
    """Each item's name in text tiles (or those of AT's entries): its
    halves, a space between (the name tables: the first's 31 entries, the
    second's 6, $FF after each)."""
    tables = {1: (rom.strings("ItemNames11TbL", 31), rom.strings("ItemNames12TbL", 31)),
              2: (rom.strings("ItemNames21TbL", 6), rom.strings("ItemNames22TbL", 6))}
    out = []
    for t, e in at or NAME_AT:
        first, second = tables[t][0][e], tables[t][1][e]
        out.append(first + ([SPACE] + second if second else []))
    return out


PASSAGE_ITEM = SPELL_ITEM + SPELLS     # Then names only: the castle's secret
PASSAGE_AT = (2, 4)                     # passage (its description, $24),
TABLET_ITEM = PASSAGE_ITEM + 1          # and Erdrick's tablet (its chest's,
TABLET_AT = (1, 24)                     # ErdrkTabletTbl's $19).


def passage_name(rom):
    return names(rom, [PASSAGE_AT])[0]


def tablet_name(rom):
    return names(rom, [TABLET_AT])[0]


def prices(rom):
    """Each item's price, then each spell's MP."""
    return rom.words("ItemCostTbl", ITEMS) + rom.table("SpellCostTbl", SPELLS)


def spell_names(rom):
    return rom.strings("SpellNameTbl", SPELLS)


def spell_levels(rom, base):
    """The level each spell is learned on (BaseStatsTbl: byte 5 the first 8
    spells' bits, byte 4's bits 0-1 the last 2). BASE: each level's 6
    bytes. The game learns them in order, so knowing a spell is a level."""
    known = [base[i][5] | (base[i][4] & 3) << 8 for i in range(len(base))]
    out = []
    for n in range(SPELLS):
        lv = next(i + 1 for i, k in enumerate(known) if k >> n & 1)
        assert all(k >> n & 1 for k in known[lv - 1:]), n
        out.append(lv)
    return out


def small_table(rom, name, count):
    return rom.table(name, count)


SHOPS = 12                      # Weapon and armor shops 0-6, tool shops 7 on.


def shops(rom):
    """Each shop's items (ShopItemsTbl), each list ending with $FD."""
    return [s + [0xFD] for s in rom.strings("ShopItemsTbl", SHOPS, 0xFD)]
