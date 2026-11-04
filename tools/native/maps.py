"""Build-time conversion of Dragon Warrior's towns and their people for the
native engine (used by convert.py).

Towns are 4-bit map types, two to a byte (the game's town block conversion
turns them into blocks); each becomes a grid of block numbers with rows 32
apart. Each townsperson is 3 bytes in the game's tables (NNNXXXXX _DDYYYYY
CCCCCCCC: graphic, X, facing, Y, dialog control byte), mobile ones in one
table and still ones in another. What a dialog control byte says depends
on the game's progress (TALK's dispatch, from DoTalkResults on); the table
here is for a hero at the start: the princess not yet saved, nothing
carried, the throne room left.
"""
import colordata

# The game's maps the engine has (its map numbers: MapDatTbl's), in the
# engine's order (0 is the overworld, then these). Their data, size, border
# and people are the ROM's (map_info, people); how they join, its map links
# (links).
TOWNS = [
    dict(name="Tantegel", number=4),
    dict(name="Brecconary", number=8),
    # Once the hero has left the throne room, the game takes its three chests
    # and its door away (Bank00's ChkLeftThRoom): castle.asm's HideThrone
    # makes them floor then.
    dict(name="Throne room", number=5),
    dict(name="Kol", number=7),
    dict(name="Garinham", number=9),
    dict(name="Cantlin", number=10),
    dict(name="Rimuldar", number=11),
    dict(name="Tantegel basement", number=12),  # Lit caves (the game's town
    dict(name="Staff of rain cave", number=13), # kind: the town blocks' first 8).
    dict(name="Rainbow drop cave", number=14),
    dict(name="Swamp cave", number=21),         # Dark (dungeons: map 15 on).
    dict(name="Rock mountain cave B1", number=22),
    dict(name="Rock mountain cave B2", number=23),
    dict(name="Garinham's cave B1", number=24),
    dict(name="Garinham's cave B2", number=25),
    dict(name="Garinham's cave B3", number=26),
    dict(name="Garinham's cave B4", number=27),
    dict(name="Erdrick's cave B1", number=28),
    dict(name="Erdrick's cave B2", number=29),
    dict(name="Dragonlord's castle", number=2),    # Its ground floor, lit,
    dict(name="Dragonlord's castle, bottom", number=6),  # and where he waits;
    dict(name="Dragonlord's castle SL1", number=15),  # the dark floors between.
    dict(name="Dragonlord's castle SL2", number=16),
    dict(name="Dragonlord's castle SL3", number=17),
    dict(name="Dragonlord's castle SL4", number=18),
    dict(name="Dragonlord's castle SL5", number=19),
    dict(name="Dragonlord's castle SL6", number=20),
    dict(name="Hauksness", number=3),           # The ruined town: lit, its enemies.
]
# The castle's lit floors have their own enemies (ChkDungeonFights: their
# rows in EnemyGroupsTbl); the dark maps' come from CaveEnIndexTbl.
LIT_ENEMIES = {2: 0x10, 6: 0x12, 3: 0x0D}
DUNGEON_BLOCKS_FROM = 12                # Maps with the 8 dungeon blocks (GetBlockID).
DARK_FROM = 15                          # Dungeons: dark (the game's MAP_DUNGEON).
NO_ENEMIES_FROM = 28                    # Erdrick's cave: no fights.
PEOPLE_UNTIL = 14                       # The last map with people tables.
OVERWORLD = 1                           # The game's map number for it.
LINKS = 51                              # MapEntryTbl's entries.


def map_info(rom, number):
    """Map NUMBER's data pointer, width, border block and height
    (MapDatTbl: 5 bytes each)."""
    d = rom.table("MapDatTbl", 5, 5 * number)
    if d[2] >= 32 or d[3] >= 32:
        raise SystemExit(f"maps: map {number} is more than 32 blocks across")
    return d[0] | d[1] << 8, d[2] + 1, d[4], d[3] + 1


def ours(towns=None):
    """The game's map numbers to the engine's."""
    out = {OVERWORLD: 0}
    out.update({t["number"]: i + 1 for i, t in enumerate(towns or TOWNS)})
    return out


def links(rom):
    """The map links (MapEntryTbl, MapTargetTbl, MapEntryDirTbl) between the
    engine's maps: (from map, X, Y, to map, X, Y, facing), its map numbers."""
    to_ours = ours()
    entry, target = rom.table("MapEntryTbl", LINKS * 3), rom.table("MapTargetTbl", LINKS * 3)
    facing = rom.table("MapEntryDirTbl", LINKS)
    out = []
    for i in range(LINKS):
        a, b = entry[i * 3:i * 3 + 3], target[i * 3:i * 3 + 3]
        if a[0] in to_ours and b[0] in to_ours:
            out.append((to_ours[a[0]], a[1], a[2], to_ours[b[0]], b[1], b[2], facing[i] & 3))
    return out


def outside(rom):
    """For each engine map (0 the overworld): the map and block OUTSIDE
    takes the hero to (our map numbers), or $FF where it fails (Bank03's
    ChkOutside: by the game's map number, an entry of MapEntryTbl, 3 bytes
    each: Garinham's grave's is in Garinham)."""
    entry = rom.table("MapEntryTbl", LINKS * 3)
    to_ours = ours()

    def target(number):
        for first, last, at in ((28, 29, 0x27), (24, 27, 0x39), (22, 23, 0x18), (21, 21, 0x0F),
                                (15, 20, 0x12), (6, 6, 0x12)):
            if first <= number <= last:
                return to_ours[entry[at]], entry[at + 1], entry[at + 2]
        return 0xFF, 0, 0
    return [(0xFF, 0, 0)] + [target(t["number"]) for t in TOWNS]


# People the game keeps out of sight: none. Princess Gwaelin, in the throne
# room (control $6F: the townsperson figure many share), shows only once
# she is home (people.asm's LoadPeople).
HIDDEN = set()

# Message list steps besides messages: AMOUNT puts the experience the hero
# needs for the next level into the next message's amount; Ask(yes, no)
# asks YES or NO and goes on with one list or the other.
AMOUNT = "amount"


class Shop:
    """A shop, an inn, a key or fairy water seller (control bytes below
    $16): the engine's own steps (native/shop.asm) for it."""
    def __init__(self, control):
        self.control = control


class Ask:
    def __init__(self, yes, no):
        self.yes, self.no = yes, no


CONTINUE = [0x125, Ask([0xC4], [0x126])]  # (whether to go on with the quest)
# (The deeds recorded: the password shown, the engine's step; on the
# 5200 nothing else keeps them.)
PASSWORD = 0xF7
KING = [AMOUNT, 0xC0, 0xC1, 0x123, Ask([0x124, Shop(PASSWORD)], CONTINUE)]

# Town map types to blocks (GenBlkConvTbl's town part).
TOWN_BLOCKS = [0x00, 0x01, 0x0F, 0x0C, 0x10, 0x03, 0x04, 0x05, 0x0B, 0x06, 0x0D, 0x11, 0x13, 0x14, 0x0A, 0x0E]
# And the dungeons' 8 (its dungeon part): stone, stairs up, brick, stairs
# down, a chest, a door, Gwaelin, blank.
DUNGEON_BLOCKS = [0x10, 0x03, 0x04, 0x05, 0x0C, 0x11, 0x17, 0x16]

# What each dialog control byte says (message numbers: 16 * (block - 1) +
# entry, + 256 for the high blocks): shops and inns are the engine's
# steps (Shop: native/shop.asm), most people say control + $2F, and the
# special ones as at the start of the game.
# The Dragonlord (DoDrgnLrdDialog): his offer, asked twice; refused, the
# fight; taken, the bad end. Both are the engine's steps (castle.asm),
# started as a shop is: Shop(LORD_FIGHT), Shop(LORD_JOIN).
LORD_FIGHT, LORD_JOIN = 0xF0, 0xF1
LORD = [0xC7, 0xA4, 0xC8]

SPECIAL = {
    0x1A: [0x1A + 0x2F, 0xB0],          # ... the legend of the rainbow bridge.
    0x62: [0x9B], 0x63: [0x9B],         # (one who wonders where the princess is)
    0x64: [0x9E],                       # Tell the king the search has failed.
    0x65: [0xA0, Ask([0xA2], [0xA1, 0xA2])],  # (whether the hero knows of the princess)
    0x66: [0xA4, 0xC6],                 # (the old man who has waited)
    0x67: [Shop(0xF8)],                 # (The curse lifter: the engine's step.)
    0x68: [0xA9],                       # (the warning about the hero's weapons)
    0x6A: [0xAD],                       # (The MP restoring wizard.)
    0x71: [0x03],                       # (the advice to rest with the King)
    0x72: [0x91],                       # (the advice to bring a torch)
    0x69: [Shop(0xF9)],                 # (The ring man: the engine's step.)
    0x6B: [0x4C, 0xAE, 0xAF],           # (Erdrick's token man.)
    0x6E: KING,                         # (the King's greeting on return)
}
# The rainbow drop's guardian (his cave's old man): the engine's steps too.
RAINBOW_MAN, RAIN_MAN = 0xF2, 0xF3     # (And the staff of rain's.)
SPECIAL[0x6D] = [Shop(RAINBOW_MAN)]
SPECIAL[0x6C] = [Shop(RAIN_MAN)]
_refused = [0xC9, Shop(LORD_FIGHT)]
SPECIAL[0x70] = LORD + [Ask([0x116, Ask([0xCA, 0xC2, 0xC3, 0xCB, Shop(LORD_JOIN)], _refused)], _refused)]
NO_ONE = [0x0F]                         # (no one in front of the hero)


def dialog(control):
    """The messages a dialog control byte says."""
    if control < 0x16:                  # Weapons and armor, tools, keys,
        return [Shop(control)]          # fairy water, inns.
    if control in SPECIAL:
        return SPECIAL[control]
    if control < 0x5E:
        return [control + 0x2F]
    if control < 0x62:                  # A yes/no question (CheckYesNoDialog).
        m = control + 0x2F
        return [m, Ask([m + 5], [m + 10])]
    return NO_ONE


def town_blocks(rom, town):
    """The town as block numbers, [y][x] (its map types, 2 a byte, rows of
    (size + 1) / 2 bytes)."""
    at, size, _, height = map_info(rom, town["number"])
    per_row = (size + 1) // 2
    data = rom.read(0, at, height * per_row)
    # The mask is by map number (8 blocks from Tantegel's basement on), the
    # table by map type (GetBaseBlockID: MapType's offset): the lit caves
    # (maps 12-14) are towns, so the town table's first 8; dungeons the
    # dungeon table.
    mask = 7 if town["number"] >= DUNGEON_BLOCKS_FROM else 15
    table = DUNGEON_BLOCKS if town["number"] >= DARK_FROM else TOWN_BLOCKS
    grid = [[table[data[y * per_row + x // 2] >> (0 if x & 1 else 4) & mask] for x in range(size)]
            for y in range(height)]
    for x, y in town.get("removed", []):
        grid[y][x] = 0x04               # Brick.
    return grid


def people(rom, town):
    """The town's people: (graphic, x, y, facing, control, mobile), 3 bytes
    each, an $FF ending each table."""
    out = []
    if not 4 <= town["number"] <= PEOPLE_UNTIL:  # (The tables start at map 4.)
        return out
    index = 2 * (town["number"] - 4)
    for name, mobile in (("NPCMobPtrTbl", 1), ("NPCStatPtrTbl", 0)):
        at = rom.words(name, 12)[index // 2]
        data = rom.read(0, at, 3 * 32)
        for i in range(0, len(data) - 2, 3):
            if data[i] == 0xFF:
                break
            a, b, c = data[i:i + 3]
            if c not in HIDDEN:
                out.append((a >> 5, a & 0x1F, b & 0x1F, b >> 5 & 3, c, mobile))
    return out


def person_pixels(chr_rom, table, graphic, direction, step):
    """A townsperson's 16x16 NES color indices (CharSpriteTbl: 16 bytes per
    graphic in each direction's 256, 8 for each step)."""
    at = direction * 256 + graphic * 16 + step * 8
    px = [[0] * 16 for _ in range(16)]
    for i in range(4):
        tile, attr = table[at + 2 * i], table[at + 2 * i + 1]
        t = colordata.tile_pixels(chr_rom, 2, tile)
        if attr & 0x40:
            t = [row[::-1] for row in t]
        if attr & 0x80:
            t = t[::-1]
        for y in range(8):
            for x in range(8):
                px[(i >> 1) * 8 + y][(i & 1) * 8 + x] = t[y][x]
    return px, table[at + 1] & 3


def flatten(steps, lists):
    """A message list as data.asm words, its branches as further lists
    appended to LISTS (label, words): messages, $FFFD for AMOUNT, $FFFE then
    the yes and no lists' labels for an Ask, $FFFB then its control byte for
a Shop, $FFFF at the end."""
    words = []
    for step in steps:
        if isinstance(step, Shop):
            return words + ["$FFFB", f"${step.control:04X}"]
        if step == AMOUNT:
            words.append("$FFFD")
        elif isinstance(step, Ask):
            yes, no = (add_list(branch, lists) for branch in (step.yes, step.no))
            words += ["$FFFE", yes, no]
            return words                # An Ask ends its list.
        else:
            words.append(f"${step:04X}")
    return words + ["$FFFF"]


def add_list(steps, lists):
    words = flatten(steps, lists)
    for label, w in lists:
        if w == words:
            return label
    label = f"Dialog{len(lists)}"
    lists.append((label, words))
    return label
