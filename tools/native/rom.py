"""The player's Dragon Warrior ROM, read by the native engine's converters.

Every piece of game data the engine uses is read from the ROM here. The
table below holds only where each piece is: its PRG bank and CPU address,
as found once in nmikstas's disassembly (its labels) and checked against
the ROM. The disassembly is not needed to build: it is the reference these
addresses (and the meaning of the data) came from.

A ROM is an iNES file (Dragon Warrior: 4 PRG banks of 16KB, banks 0-2 at
$8000, bank 3 fixed at $C000, then 16KB of CHR), or a directory of its
split banks (Bank00.bin..Bank03.bin and CHR_ROM.bin). It must be one of
the known releases (KNOWN, by checksum): the table is only right for them.
"""
import hashlib
import os
import sys

PRG_BANK = 0x4000

# The ROMs this table fits: the USA release (rev0) and its revision (rev1),
# by each bank's MD5 (rev0's are the disassembly's build script's; rev1
# differs from it in a few bytes of banks 0 and 2, no table moved).
KNOWN = {
    "rev0": ("4494467c3c7f3401a5ea25947814b8bd", "e34c39bfb3069bc6c563b0e614b22a49",
             "0135d12602c3efb5728a0f220ae916fd", "aae638b52ffc7a720a63d6ef1700a2b3"),
    "rev1": ("2a66872270f59d0d0a261ddf2381cb73", "e34c39bfb3069bc6c563b0e614b22a49",
             "5b06461471f1f21d59a970e8c3784b7c", "aae638b52ffc7a720a63d6ef1700a2b3"),
}
CHR_MD5 = "cacaed7278c49aff6a93b8298bdd3ce4"

# Where each table is: (PRG bank, CPU address). The disassembly's names.
AT_LEN = {"StatusDat": 0xB04B - 0xAFC7}   # Tables whose length is where the next starts.

AT = {
    "EndCreditDat": (1, 0x948D),      # The end credits (the same in both).
    "IntroGFXTbl": (0, 0xBDCC),       # The title screen's nametable (DoIntroGFX),
    "IntroPalTbl2": (2, 0xBDFF),      # and its palette, the text shown.
    # Bank 0: maps, people, shops, palettes, the overworld, the scene.
    "MapDatTbl": (0, 0x801A),           # Each map: data pointer, columns - 1, rows - 1, border.
    "NPCMobPtrTbl": (0, 0x9734),        # Each town's people (from map 4): pointers.
    "NPCStatPtrTbl": (0, 0x974C),       #
    "MapEntryDirTbl": (0, 0x9914),      # Each map link's facing.
    "TantGFDat": (0, 0x8240),           # Tantegel's ground floor (map types, 2 a byte).
    "ThrnRoomDat": (0, 0x8402),         # The throne room.
    "BrecconaryDat": (0, 0x8716),       # Brecconary.
    "CharSpriteTbl": (0, 0x9334),       # Character sprites: 4 facings of 256 bytes.
    "EndBossBGTiles": (0, 0xBBF8),      # The end boss (LoadEndBossGFX): background tiles,
    "EndBossSPTiles": (0, 0xBC3D),      # sprites,
    "EndBossPal1": (0, 0xBD41),         # and palettes: background,
    "EndBossPal2": (0, 0xBD4F),         # sprites.
    "TantMobTbl": (0, 0x9764),          # Townspeople: 3 bytes each, $FF ends.
    "TantStatTbl": (0, 0x9783),         #
    "ThRmMobTbl": (0, 0x97A2),          #
    "ThRmStatTbl": (0, 0x97A6),         #
    "BrecMobTbl": (0, 0x9875),          #
    "BrecStatTbl": (0, 0x9894),         #
    "ItemCostTbl": (0, 0x9947),         # Prices: a word each.
    "KeyCostTbl": (0, 0x9989),          #
    "InnCostTbl": (0, 0x998C),          #
    "ShopItemsTbl": (0, 0x9991),        # Each shop's items, $FD ends each.
    "WeaponsBonusTbl": (0, 0x99CF),     #
    "ArmorBonusTbl": (0, 0x99D7),       #
    "ShieldBonusTbl": (0, 0x99DF),      #
    "OverworldPal": (0, 0x9A46),        # Background palettes: 12 bytes.
    "TownPal": (0, 0x9A56),             #
    "DungeonPal": (0, 0x9A66),          #
    "PreGamePal": (0, 0x9A73),          #
    "RegSPPal": (0, 0x9A8B),            # Sprite palettes: 12 bytes.
    "EnSPPals": (0, 0x9AAF),            # The enemies' sprite palettes: 12 each.
    "CombatBckgndGFX": (0, 0x9C8F),     # The battle scene: 14 by 14 tiles.
    "SpellCostTbl": (0, 0x9D53),        # Each spell's MP.
    "WrldMapPtrTbl": (0, 0xA653),       # The overworld's 120 row pointers.
    "ResumeMusicTbl": (0, 0xB1AE),      # Each map's music.
    # Bank 1: sound, monsters, stats, names.
    "MusicalNotesTbl": (1, 0x8205),     # Notes: NES timer words.
    "MscStrtIndxTbl": (1, 0x8297),      # Each music's channel data pointers.
    "SFXStrtIndxTbl": (1, 0x8339),      # Each sound effect's.
    "EnSpritesPtrTbl": (1, 0x99E4),     # Each enemy's sprite list (word; < $8000 mirrored).
    "EnStatTbl": (1, 0x9E4B),           # Enemy stats: 16 bytes each.
    "BaseStatsTbl": (1, 0xA0CD),        # The hero's stats per level: 6 bytes each.
    "ItemNames11TbL": (1, 0xBAB7),      # Item names, $FF ends each.
    "ItemNames21TbL": (1, 0xBB8F),      #
    "ItemNames12TbL": (1, 0xBBB7),      #
    "ItemNames22TbL": (1, 0xBC4F),      #
    "StatusDat": (1, 0xAFC7),           # The STATUS window's data (to DialogDat).
    "SpellNameTbl": (1, 0xBE56),        # Spell names, $FF ends each.
    "EnNames1Tbl": (1, 0xBC70),         # Enemy names, $FF ends each.
    "EnNames2Tbl": (1, 0xBDA2),         #
    "TreasureTbl": (1, 0x9DCD),         # Chests: map, X, Y, what (4 bytes each).
    # Bank 2: the text.
    "TextBlock1": (2, 0x8028),          # 19 blocks, one after another.
    # Bank 3: levels, enemy zones, the map blocks.
    "CmbtBGPlcmntTbl": (3, 0xF397),     # The battle window's blocks in order: 49 bytes.
    "LevelUpTbl": (3, 0xF35B),          # The experience for each level: words.
    "OvrWrldEnGrid": (3, 0xF522),       # Enemy zones: 8 by 8 nibbles.
    "RepelTbl": (3, 0xF4FA),            # Each enemy's repel value.
    "EnemyGroupsTbl": (3, 0xF54F),      # Each zone's 5 enemies (14 overworld rows, then caves').
    "CaveEnIndexTbl": (3, 0xF542),      # Each cave's row in it (map 15 on).
    "GFXTilesTbl": (3, 0xF5B5),         # Each block's 4 tiles and palette.
    "MapEntryTbl": (3, 0xF3C8),         # Map links: from (map, X, Y),
    "MapTargetTbl": (3, 0xF461),        # to (map, X, Y).
}

# The text blocks' addresses (TextBlock1-19), and the text's length.
TEXT_BLOCKS = [0x8028, 0x8286, 0x8519, 0x8713, 0x894C, 0x8D12, 0x906E, 0x9442, 0x981E, 0x9C88,
               0x9F3F, 0xA28A, 0xA6DC, 0xAA2E, 0xAC61, 0xAE28, 0xAFEE, 0xB68B, 0xBA65]
TEXT_LENGTH = 15496


class Rom:
    def __init__(self, path):
        if os.path.isdir(path):
            self.prg = [open(os.path.join(path, f"Bank0{b}.bin"), "rb").read() for b in range(4)]
            self.chr = open(os.path.join(path, "CHR_ROM.bin"), "rb").read()
            self.revision = self.identify(path)
            return
        data = open(path, "rb").read()
        if data[:4] != b"NES\x1a" or data[4] != 4:
            sys.exit(f"rom: {path} is not a Dragon Warrior ROM (iNES, 4 PRG banks)")
        at = 16 + (512 if data[6] & 4 else 0)
        self.prg = [data[at + b * PRG_BANK:at + (b + 1) * PRG_BANK] for b in range(4)]
        self.chr = data[at + 4 * PRG_BANK:]
        self.revision = self.identify(path)

    def identify(self, path):
        """Which known ROM it is; exit if none."""
        banks = tuple(hashlib.md5(b).hexdigest() for b in self.prg)
        for name, known in KNOWN.items():
            if banks == known and hashlib.md5(self.chr).hexdigest() == CHR_MD5:
                return name
        sys.exit(f"rom: {path} is not a known Dragon Warrior ROM (USA, rev0 or rev1)")

    def read(self, bank, addr, count):
        """COUNT bytes of PRG bank BANK from CPU address ADDR."""
        base = 0xC000 if bank == 3 else 0x8000
        return self.prg[bank][addr - base:addr - base + count]

    def table(self, name, count, offset=0):
        bank, addr = AT[name]
        return list(self.read(bank, addr + offset, count))

    def words(self, name, count):
        data = self.table(name, count * 2)
        return [data[i] | data[i + 1] << 8 for i in range(0, count * 2, 2)]

    def word_at(self, bank, addr):
        data = self.read(bank, addr, 2)
        return data[0] | data[1] << 8

    def strings(self, name, count, end=0xFF):
        """COUNT runs of bytes, each ended by END (left out)."""
        bank, addr = AT[name]
        out, cur = [], []
        while len(out) < count:
            b = self.read(bank, addr, 1)[0]
            addr += 1
            if b == end:
                out.append(cur)
                cur = []
            else:
                cur.append(b)
        return out
