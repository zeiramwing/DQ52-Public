# Project history

The project's log, oldest first: where a later entry changes something, it
replaces what an earlier one says (marked *Now:* where it matters). For
how things stand now, see [README.md](../README.md) and
[ARCHITECTURE.md](ARCHITECTURE.md).

The project began as a port that ran the game's own code, patched and
relocated from the disassembly, on a software NES in the 5200. It worked,
but at about 70% of the NES's speed, and was retired once the native
engine passed it. Commit c51bc31 is the last that has it.

## The native engine

A second codebase, written for the 5200 from the ground up rather than run
on a software NES. You present your own Dragon Warrior ROM; the build reads
the data it needs from it, converts it into the engine's own formats, and
assembles the 5200 cartridge. The engine is all native 5200 code, and the
disassembly is only the reference for how the game works, its stats and
where its data sits:

- `tools/native/rom.py`: the ROM reader. It loads an iNES file (or a
  directory of its split banks) and holds a table of where each piece of
  game data is: the PRG bank and CPU address of each table the converters
  use, found once in the disassembly and checked against the ROM. No game
  data is written in the repository, only those addresses.
  `tools/native/find_addresses.py` is a reference tool for finding a new
  table's address in the disassembly; the build never runs it. Switching
  the converters from the disassembly's source text to the ROM changed
  nothing in the cartridge: it is byte-identical, and it builds with the
  disassembly gone.

- `tools/native/convert.py`: the overworld as finished block numbers (water
  shores worked out as the game's `GetBlockID` does, row 10's short data
  read on into row 11's as `FindRowBlock` does), every overworld block as
  mode 4 characters with its colors chosen (52 characters for the whole
  overworld), the color registers, which blocks are walls, and the hero's 8
  frames as two players. Where the players overlap GTIA's multicolor mode
  shows their colors ORed, and the converter picks the pair of Atari colors
  that best gives the sprite's three. *Now:* three players, his own three
  colors exact, and 8 more frames carrying the princess.
- `native/main.asm`: the screen is a ring of 32 rows of 128 bytes, each
  block column written twice so ANTIC's 40-byte fetch for a scrolled row
  never runs off its end. Each display list row points into the ring, and
  HSCROL and VSCROL do the fine scroll. A step draws the one row or column
  of blocks coming into view, then scrolls 16 frames: a line a frame up or
  down, a color clock every other frame sideways.
- `native/windows.asm`, `native/text.asm`: the status window (after half a
  second standing: the name's first 4 letters in its top border, level,
  HP, MP, gold, experience), the command window (the lower fire button;
  the stick moves the cursor, the upper button closes it) and the dialog
  window, which prints the game's own messages a letter a frame: words
  wrap at its edge as the game's do, the hero's name goes in, a wait
  control waits for a button, and full, its lines move up. TALK, SPELL,
  ITEM, STAIRS, DOOR, SEARCH and TAKE say what the game says with nothing
  there. Windows are drawn into the ring where the view is (they only open
  while the hero stands); closing one draws the map blocks beneath again.
- Text needs more characters than the map's set has room for (the
  overworld's 52 and 92 text tiles), so the map's set holds what the status
  and command windows show (digits, capitals, the frame, the cursor) and 4
  slots that get the name's letters, and is in RAM for them. The dialog
  window's rows show a second set with every text tile, switched in by a
  display list interrupt at its top; it takes the whole width of its rows
  (the NES leaves 4 columns of map at each side). *Now:* those rows are
  high-resolution (ANTIC mode 2) while the window is up, the game's letters
  at full width, and the second set is one for every map.
- `tools/native/build.py ROM OUTDIR [--autopilot | --script NAME]` (ROM:
  your `.nes` file, or a directory of its split banks)
  builds a 512KB SuperCart (atari800 type 74): the program in the first half
  of every bank, the overworld in bank 0's second half, the text (15.5KB)
  in bank 1's, the header in bank 15. Played with the stick, walking a
  fixed route, or from a controller script (`native/scripts`).
- `tools/native/measure.py ROM OUTDIR` runs the route and counts
  the frames; `tools/native/test.py ROM OUTDIR` runs the scripts
  and reads the screen back as text against their `;EXPECT:` lines.

First result: 46 steps in 736 frames, exactly the NES's 16 frames a step,
with no frame missed (the software NES port takes about 35); still so with
the windows.

- Towns: Tantegel's ground floor and Brecconary (`tools/native/maps.py`),
  their blocks in their own color plan, entered from their block on the
  overworld by the game's map entrance table and left by walking off their
  edge. Each map has its own pair of character sets (its colors change the
  text's too) and block tables: a 2.25KB image in a data bank, copied to RAM
  when the hero enters, with the screen off meanwhile. *Now:* 1.25KB, its
  own set and tables; the dialog's set is shared.
- Townspeople (`native/people.asm`): from the game's tables of mobile and
  still people, each in one player in its graphic's color. Players 2 and 3
  are moved and recolored by a display list interrupt at the end of each
  row, so they show several people one under another, and two side by
  side; a third on the same rows is not drawn. Mobile people wander a block
  at a time, as the game's do, never into a wall, the hero or each other.
  TALK turns the one in front of the hero to face him, and they say what
  the game has them say for a hero at the start (their dialog control
  byte, as TALK's dispatch reads it; shops and the inn only greet so far).
  People are only drawn again when something about them changed, and the
  interrupts only run on maps with people. *Now:* no one wanders or turns;
  nearly all are drawn into the map, facing down and stepping in place, and
  the few left are in player 3.

- The throne room, up the stairs from Tantegel's ground floor (STAIRS, on
  the stairs block, follows the game's stairs link either way), its chests
  and door taken away as the game does once the hero has left it, and the
  princess out of sight until she is home. King Lorik's talk is the game's
  for a hero who has left: he is pleased, says the experience for the next
  level ("7 Points", the amount control filled in from the level table),
  asks YES or NO to record the deeds, then whether to continue the quest.
  Message lists now branch on a YES/NO window (as do the game's other
  yes/no questions), and TALK reaches across a counter to whoever is
  behind it, as the game's does. (Recording the deeds now shows a
  password: below.)
- `build.py --start MAP,X,Y` starts the hero elsewhere, for tests (a
  script's `;START:` line).

- Battles (`native/battle.asm`, `tools/native/battle.py`): random fights on
  the overworld as the game decides them (the chance by the ground, the
  enemy from the hero's zone, half called off near Tantegel), the game's
  enemy stats, names and pictures (put together from its sprites, at the
  game's place on screen). The fight is shown as the game shows it: its
  battle scene (CombatBckgndGFX) in a window at columns 10-23, rows 6-17,
  the map still around it. The window's rows are two bands, each with its
  own character set in RAM, switched by a chain of three display list
  interrupts: from row 6 the scene in the map's colors, and from the
  monster's top row the monster on the grass in colors chosen for it
  (COLPF1-3; COLPF0 stays white for the text). Each set holds its picture's
  glyphs (at most 63, the converter merging the least used into their
  nearest), the window text, and the map's characters beside the window
  copied into the codes left when the battle starts (in the monster's band
  their pixels turned to its colors), so the map shows on. Once the monster
  is beaten its cells show the grass without it. The monster's pictures
  take two banks (4 and 5). The display list interrupt for townspeople now
  works out which row it is at from VCOUNT and the scroll, as not every
  row has one. FIGHT, RUN, SPELL and ITEM; the game's
  sums for who goes first, excellent moves, hitting, the enemy dodging and
  running away, damage both ways; the game's messages throughout. Winning
  gives experience and gold and levels up (the game's stats per level);
  dying brings the hero back before the King with half the gold.
  `build.py --fight N` (a script's `;FIGHT:` line) makes every step a fight
  with enemy N, for tests, which check memory with `;EXPECT-BYTE:`.

Still exactly 16 frames a step, with no frame missed, on the overworld and
walking through Brecconary's streets among its people.

- Sound (`native/sound.asm`, `tools/native/sound.py`): the game's own music
  and sound effects, converted at build time into the engine's own format.
  The converter reads each music's and effect's channel parts from your ROM
  as the game's sound engine reads them, and writes each again as one
  straight stream:
  - subroutines are written out where they are used, and loops become a
    GOTO back to where the same state was met;
  - the space between notes becomes a wait after each note;
  - the sweep units' bytes and the no-ops are left out;
  - the note offset (the dungeon tunes step their key down as they play)
    stays a control byte, added to each note as the game does.

  The result (about 10KB) goes in bank 6, with tables of where each part
  starts; no game code goes in the cartridge, and none of it is in this
  repository. Every build then plays all 27 tunes for a minute and all 22
  effects both ways, with a model of the game's engine on the ROM's data and
  a model of the native engine on the converted data, and stops if any
  channel write differs on any frame. Altered notes are caught. The engine,
  run by the VBI each frame, keeps the game's timing (its tempo, the order
  of the channels, effects taking SQ2 and the noise) and its "hardware"
  writes in RAM, by channel. Each frame it then does in native form what
  the NES's sound hardware does with them: one pass over the channels, a
  silent one skipped; the length counter counted in frames; the envelope's
  divider spent against the frame's 4 quarter frames at once (checked
  against the NES's step by step, its period changing mid-note too); the
  triangle's linear counter. Then it sets POKEY:
  - SQ1 (the melody) on channels 1+2 joined, 16 bits at 1.79MHz: close to
    exact pitch.
  - SQ2, or the noise while it sounds, on channel 3; the triangle on
    channel 4. Each is 8 bits at 64kHz, within about a quarter of a
    semitone. A note too low for 8 bits goes up an octave.
  - Sound effects take SQ2 and the noise, as on the NES.
  - Trade-offs: every voice is a pure square wave, so the NES duty cycles
    are lost; the sweep units are not done; the triangle plays at one
    loudness; an effect that needs both a tone and the noise gets only
    the noise.

  What plays where: each map's music (the game's ResumeMusicTbl), the
  fight's music from the start of a battle, the victory, level-up and
  death tunes, and the game's effects for attacks, hits, misses,
  excellent moves, running away, the menu, stairs, bumping a wall, and
  every other letter of dialog. A `PlayMusic` or `PlaySFX` call only asks;
  the VBI starts the sound, so the engine is never caught halfway. Tests
  check the song playing (`Song`) and that the overworld music has set
  its tempo.

- Items, shops and inns (`native/shop.asm`, `tools/native/items.py`): the
  hero's goods are kept as the game keeps them. The equipment is one byte
  (weapon, armor, shield), herbs and magic keys are counted, and up to 8
  other items sit in 4 bytes. Attack is strength plus the weapon's bonus;
  defense is half the agility plus the armor's and shield's bonuses (and 2
  for the dragon's scale), from the game's tables, and the battle sums use
  them. Prices, item names and each shop's goods are the game's
  (ItemCostTbl, its item name tables, ShopItemsTbl, InnCostTbl,
  KeyCostTbl).
  - Shopkeepers, innkeepers and the key and fairy water sellers (dialog
    control bytes below $16) run chains of steps, as a battle does. Each
    step says one of the game's messages, or asks YES or NO after one, and
    the game's sums decide the next step.
  - Weapons and armor: the list window of the shop's goods and prices.
    The old piece of the same kind is bought back for half its price, and
    the new one is equipped.
  - Tools: BUY or SELL. Herbs top out at 6; other items go in the
    inventory unless it is full. Selling pays half the price.
  - Magic keys (6 at most) and fairy water.
  - Inns: the price for the town, then a night with the screen dark and
    the inn's tune, HP and MP restored, and the innkeeper's greeting.
  - ITEM lists the hero's goods. Herbs heal 23 to 30 HP; the wings fly
    back beside Tantegel; the dragon's scale is put on; the torch and
    fairy water give their messages (fairy water's monster-repelling is
    not done yet). In a battle, ITEM uses an herb if there is one (no item
    window there yet). *Now:* fairy water keeps the weaker monsters away
    for its steps, as the game's does, and a battle's ITEM opens a list of
    the goods.
  - Window text uses set A, which holds only digits, capitals and the
    frame. Any other letter is copied from set B into a character code the
    map leaves free, the first time a window needs it on that map.
    *Now:* window text is all capitals, from fixed codes; nothing is
    copied in.
  - Tests: `shopweapon` buys a Club, `shoptool` buys an herb and uses it,
    `inn` stays a night, `keys` buys a magic key. A script's `;GOLD: N`
    line (`build.py --gold N`) gives the hero gold to start with.
  - Program room: the 16KB program (the first half of every bank) had
    filled up. Measured from the assembler's label map, it was about
    4.0KB of data tables, 1.3KB of hero and townspeople graphics (kept
    only to be copied into player memory) and 0.7KB of item and enemy
    names, with the code spread evenly over the rest (no routine over
    about 200 bytes). Moved out:
    - the battle scene's glyphs and grid, the battle text and the
      white-text table, into the second monster bank (read when a fight
      starts);
    - the hero's and townspeople's graphics, into bank 7, copied at power
      on to RAM at $3B00-$3FFF;
    - the enemy and item names, into the text bank after the text (read
      while it is in, as the text is).

    `build.py` now reports what is left: about 2.3KB. The next tables to
    move if more room is needed are the dialog lists and their pointers
    (about 0.8KB), and TextA/TextB (512 bytes).

- Towns and how maps join (`tools/native/maps.py`): the engine's maps are a
  list of the game's map numbers (Tantegel, Brecconary, the throne room,
  Kol, Garinham, Cantlin, Rimuldar); each one's data, size and border come
  from the ROM's MapDatTbl, its people from NPCMobPtrTbl and
  NPCStatPtrTbl, its music from ResumeMusicTbl, its chests from
  TreasureTbl. How they join is the ROM's own map links (MapEntryTbl,
  MapTargetTbl, MapEntryDirTbl, those between these maps), used as the
  game uses them (`native/main.asm`'s CheckDoor, `windows.asm`'s
  TakeStairs): a step onto a link's start on the overworld goes to its end,
  facing as the link says; off a map's edge, back to where the first link
  into it starts, facing down; stairs down follow a link from the hero's
  block, facing right, stairs up go back along one to it, facing left. No
  door or stairs are written by hand any more. With 8 maps, their images
  take two banks (3 and 9). The `garinham` test walks into Garinham and
  out again.
- Caves: Tantegel's basement and the two shrine caves (lit, the game's
  dungeon blocks), and the dungeons (dark, the game's MAP_DUNGEON: maps 15
  on): the swamp cave, the rock mountain cave, Garinham's cave and
  Erdrick's cave, each joined by the ROM's links. Maps may now be wider
  than tall (the swamp cave is 6 by 30), up to 32 each way.
  - Dark: only the light round the hero shows, its own block at first; a
    block outside it is drawn black (an all-black block, past the game's
    39). Each step draws the light again, a block more each way. A torch
    makes it 3 wide (the game's LightDiameter); the wings will not work
    in a dungeon. Each cave plays its own music (ResumeMusicTbl).
  - Fights: on brick, 1 in 16, one of the cave's row of enemies (the
    game's CaveEnIndexTbl and EnemyGroupsTbl; none in Erdrick's cave).
    A cave's battle has no scene: the monster on black, from a second set
    of the monsters' pictures made on black (bank 13), and only the
    monster's band of rows. The scene band's RAM holds the cave's map copy
    meanwhile, and is not touched.
  - The maps' images take banks 3, 9 and 11, their pages banks 2 and 12.
  - Tests: `cave` (a torch in the dark), `cavefight` (a battle on black),
    `cavewin` (won: dark again, the map as it was). A script's `;ITEM: N`
    line (`build.py --item N`) gives the hero an item by its ITM_ code.
- Doors and treasure chests (`native/treasure.asm`): DOOR (and a magic key
  used from ITEM) opens a door beside the hero, looking above, below, left
  and right as the game does, the key used up. TAKE on a chest gives what
  the game's TreasureTbl (read from the ROM) has there, with the game's
  sums and messages. Gold is each kind's base and a random part; herbs
  and keys stop at 6 (the chest then empty); items go into the inventory;
  Erdrick's sword is wielded; the
  death necklace is a 1 in 32 chance against its gold. SEARCH on a chest
  reports a chest there. A town's map is copied into RAM while the
  hero is in it (the battle character sets' RAM, as towns have no
  battles), so an opened door or a taken chest is floor there, and back
  on the next visit, as in the game. A full inventory asks, as the game's
  DiscardItem does, whether to throw something away: NO gives the find
  up; YES lists the goods, refuses the herbs, keys and the quest's items
  (and a cursed belt or necklace that is worn), and swaps the chosen one
  for the find. Tests: `chestfull` (YES, a ring for the torch) and
  `tokenfull` (NO). Erdrick's tablet, in Erdrick's cave B2, is found
  (its name from the item name tables) and read, as the game's
  ChkTrsrErdTablet does. Test: `tablet`. The `treasury` test opens Tantegel's
  treasury and takes a chest's gold; a script's `;KEYS: N` line
  (`build.py --keys N`) gives the hero keys to start with.

In the monster's band the map beside the window takes the nearest of that
band's colors, so water there can show grey or brown.

- Spells (`native/spell.asm`): the hero knows each spell from the level the
  game teaches it on (read from the ROM's per-level spell bits; the game
  learns them in order, so a level is all the engine keeps), and a level
  up that teaches one says so. SPELL opens the list window with the spells
  known and their MP (they are listed as items past the last, their cost
  as their price, their names read from the ROM into the text bank, so
  the spell's name goes into the messages as an item's does). The MP is
  checked and paid as the game does it. On the map: HEAL and HEALMORE,
  RADIANT in the dark (the light 7 blocks wide, fading a block each way
  every 60 steps once its 80 are up), REPEL (weaker enemies kept off on
  the overworld by the ROM's repel values, as fairy water now does too;
  its end is said), OUTSIDE (each cave's own entrance, from the ROM's map
  links: Garinham's grave comes out in Garinham) and RETURN; HURT and
  SLEEP fizzle there. In a battle the list window covers the scene, and
  what it covers is kept and put back; HURT and HURTMORE (damage), SLEEP
  and STOPSPELL on the enemy, each failing by the game's checks, HEAL and
  HEALMORE; the map's spells cannot be used there. Enemies cast as the
  game's spell byte says (how often, and which: SLEEP, STOPSPELL, HEAL and
  HEALMORE when hurt, HURT, HURTMORE), and breathe fire; magic and
  Erdrick's armor take a third off. Sleep wakes as the game's sums say
  (the hero half the time, the enemy 1 time in 3), and stopped spells are
  blocked. Tests: `spellheal`, `spellradiant`, `spelloutside`,
  `spellreturn`, `battlelist`, `battlehurt`, `battlecaster` (an enemy that
  puts the hero to sleep and casts HURT, fought to the end), `newspell`.
  A script's `;LEVEL: N` and `;EXP: N` lines (`build.py --level N --exp
  N`) start the hero at that level, HP and MP full, with that experience.
- Room for it: the text tile tables and the windows' templates are copied
  at power on from the graphics bank to RAM the missiles would use (none
  are), and the townspeople's dialog table is in the messages bank: about
  1KB of program.

- The Dragonlord's castle (`native/castle.asm`): its eight floors are maps
  like the towns (the ground and bottom floors lit, with their own enemy
  rows; the six between dark, with the caves' rows), joined by the ROM's
  map links; their images take bank 14. The rainbow drop held up just
  east of the gap builds the rainbow bridge, once, with its tune; the
  overworld is in the cartridge, so its row there is then read from a RAM
  copy with the bridge in it. The stairs behind the throne show as a force
  field until SEARCH finds them (on the throne itself, the game's hint);
  the passage's name comes from the ROM's item names. Swamps take 2 HP a
  step and force fields 15, not through Erdrick's armor, and dying of it
  brings the hero back to the King. On the bottom floor the Dragonlord
  has his own figure (the ROM's, swapped into the wizard's slot there);
  talking to him gives his offer and its question twice: refused, the
  fight with him; taken, the hero's gold, experience, items and equipment
  are gone and the game stops there. Battles off the overworld are on
  black, as in caves: a lit map is drawn black round the window, the
  people hidden, and both come back after. The wings and RETURN fail on
  his floor, and OUTSIDE leaves the castle from its lower floors. Tests:
  `castlein`, `castlestairs`, `rainbow`, `castlepassage`, `lordfight`,
  `lordjoin`, `lordfloor`.
- The rainbow drop's guardian, the old man in its cave: with the drop
  already, he has nothing for the hero; without Erdrick's token he sends
  the hero out of the cave (by its map link, facing down); with the token,
  the stones of sunlight and the staff of rain become the rainbow drop,
  and without them he says what is wanted. As the drop is made the
  screen goes grey for half a second (GreyTime: the VBI keeps only the
  colors' luminance; the hero's sprite keeps its colors). A script's
  `;ITEM:` line now takes a list of ITM_ codes. Tests: `rainbowman`,
  `rainbowwant`, `rainbowout`. For room, every name's place in the text
  bank (items, spells, enemies) is now a table in the messages bank,
  looked up by one routine: about 250 bytes of program.
- The staff of rain's guardian, the old man in its cave: with the rainbow
  drop or the staff already, nothing for the hero; with the silver harp,
  he takes it and goes, leaving the chest he kept, where TAKE finds the
  staff; without it, his test. Tests: `rainstaff`, `raintest`. (And a
  fix: the three lit caves, Tantegel's basement and the staff's and the
  drop's caves, are town-type maps in the game, read through the town
  block table's first 8, not the dungeon one: they were drawn with the
  wrong blocks, the staff's chest as stairs.)
- The STATUS window (`native/status.asm`, `tools/native/window.py`):
  STATUS shows the hero's name, strength, agility, maximum HP and MP,
  attack and defense power, and the weapon, armor and shield worn, each
  name over two rows as the game splits it. Its layout and labels are the
  ROM's own window data (StatusDat), read at build time as the game's
  window code reads it (its control bytes: blanks, borders, the name,
  stats, item halves) into a template and a field list in the messages
  bank; the engine draws the template and fills the fields. It stays up
  until a button, with the hero and anyone under it out of sight, then
  the map is drawn back. Tests: `status`, `statusclose`; a script's
  `;EQUIP: N` line starts the hero wearing equipment byte N.
- Test scripts no longer take program room: build.py puts a script's
  entries in the messages bank after the messages, and the script reader
  reads them there through a pointer (any length; before, past 255 bytes
  a script started over).
- Hauksness, the ruined town: a lit map with its own enemy row (the
  game's ChkDungeonFights), its battles on black as the castle's lit
  floors'. Map images past the four images banks' 28 go in the second
  monster bank, after its data. SEARCH there finds Erdrick's armor (worn
  at once), and in Kol the fairy flute: the game's search finds are one
  table (map, block, what), the token's among them. Tests: `hauksness`,
  `hauksfight`, `erdarmor`, `flute`.
- The guardians, fought where the game sets them (CheckAxeKnight on): the
  axe knight in Hauksness on Erdrick's armor's block (every time), the
  green dragon in the swamp cave and the golem by Cantlin (each once:
  beaten, its flag in ModFlags keeps it so). Tests: `golem`, `axeknight`,
  `gdragon`.
- ITEM in a battle (PlyrItem): the hero's goods in the list window over
  the scene (what it covers kept, as SPELL's). The herb heals; the fairy
  flute plays its tune and puts the golem to sleep (else nothing); the
  silver harp plays and pleases the enemy; the dragon's scale is put on;
  anything else cannot be used there. Test: `flutegolem`.
- Princess Gwaelin: TALK to her in the swamp cave (her block now a wall,
  as in the game: talked to from beside it) gives her words and asks if
  she is to be taken home, again until YES; then she is carried (her
  block floor, and so on later visits). TALK to the King carrying her:
  his thanks, her keepsake given, her farewell; she is home. The flags
  are ModFlags bits 1 and 2. Her keepsake, used, tells the experience to
  the next level (or that the last is reached) and, on the overworld, how
  far Tantegel is north or south and east or west, then her words. Not
  yet: the hero's look while carrying her, her figure in the throne room
  after, an item taken for the keepsake with a full inventory, and her
  part in the ending. Tests: `rescue`, `kinggwaelin`, `keepsake`.
- Erdrick's armor gives back 1 HP each step, magic armor 1 every 4th
  (the game's MovementUpdates). Test: `armorheal` (a script's `;HURT: N`
  line starts the hero N HP short).
- Erdrick's token: SEARCH on the overworld where it lies finds it, once
  (the game's only find there). With a full inventory the game's ask
  what to throw away follows (as for a chest); given up, it can be found
  again. Test: `token`. With it,
  every item the castle's road needs can now be found in play: the
  silver harp and the stones of sunlight in chests, the staff of rain
  from its old man, the token on the ground, and the rainbow drop for
  them.

- The Dragonlord's two forms: beating the first (no excellent moves
  against either) brings, after the game's pause, his second: all of its
  HP, its own music and opening message. Beating it says his end, then (a button) he is dead
  (no more hurtful ground), HP and MP full, and the hero is outside his
  castle on the overworld, facing down. The enemies' records now hold
  40 (both forms). Test: `lordwin` (a level 30 hero in Erdrick's gear
  fights both forms to the end).

- The ending: with the Dragonlord dead, everyone in Tantegel's hall says
  the King awaits; stepping onto either of the two blocks before the
  throne room's stairs starts the ending (the game's ChkCstlEnd): the
  music stops, the King's last words (the game's messages, by number),
  the pauses, the hero turning right and then down, the end music, and
  the game stays there. Test: `ending` (a script's `;FLAGS: N` line starts
  the hero with ModFlags N).

- Saving, by password (`native/password.asm`, `tools/native/password.py`):
  the 5200 keeps nothing at power-off, so when the King records the
  hero's deeds (YES) he shows a password of 20 characters (A-Z and 2-7)
  in a window, until a button. Holding the upper fire button at power-on
  opens the entry window instead of starting a new adventure: the stick
  moves over its grid of the 32 characters, the lower button enters one,
  the upper takes the last back (with none, a new adventure after all).
  The 20th tries it: a wrong one is cleared with a bump; a right one
  brings the adventure back before the King. A password keeps the gold
  and experience, the items, keys and herbs, the equipment and the flags
  (bridge, passage, the Dragonlord, guardians, the princess), checked by a
  CRC-8 and scrambled; the level and its stats come back from the
  experience, HP and MP full. `password.py encode` and `decode` do the
  same in Python. The password keeps no name: after a right one, the name
  window asks for it (below). After recording the King no longer asks
  whether to go on. Tests: `kingsave`,
  `pwentry`, `king2` (NO to recording, then the question). *Now:* 32 characters, keeping the name, HP and MP too (below).
- More tables out of the program, for room: the map links, each map's
  record (copied to RAM at a map's load), the overworld's enemy zones and
  groups, the sound's dividers (with the sound bank in). The test harness
  now dumps memory up to $0BFF.

- Curses and the ring: the cursed belt and the death necklace, put on
  (ITEM), curse the hero (Flags2 bits 6 and 7), with the curse's tune;
  once on, they squeeze. Cursed, the hero is turned out of Tantegel's
  hall at its gate row, and comes back from death outside the castle with
  the King's words for the cursed. The curse lifter in Brecconary takes
  the cursed items and the curse; the ring man knows whether the
  fighter's ring is worn. The curses ride in the password's keys and
  herbs byte (its spare bits). Tests: `cursebelt`, `cursegate`,
  `curselift`. For room, the shops', chests' and item prices' tables are
  in the messages bank too (PriceOf reads the prices).

- The name: at power-on (without the upper button) the name window asks
  for it, on the password window's grid: A-Z, then - ' . ! ? and a blank,
  and END below; the lower button enters a character (8 at most), the
  upper takes the last back, END (one character at least) takes it. The
  name has its part in the stats, as the game's LoadStats gives it: its
  first 4 letters' sum cuts two of them to 9/10 (bit 0: the max MP, if
  any, else the strength; bit 1: the max HP, else the agility) and adds
  its bits 2-3 to each, at the start, at each new level and after a
  password. The name entry needs room, so the power-on code (both
  windows and the password's decoding) runs from the messages bank:
  build.py puts what main.asm assembles past the program's half at
  $A000 there, and FarOut brings that bank back after a call into the
  program that changes banks. Test builds start with the build's name
  (Loto) unless a script has `;NAME-ENTRY` (`build.py --name-entry`).
  Tests: `nameentry`, `pwname` (a password, then the name).

- The princess in the ending (the game's GwaelinJoin, logic and words
  only: her figure is not drawn): home or carried, after the King's first
  words she asks to go with the hero, asking again at NO; YES and she is
  carried (ModFlags bit 1); then the tale's end. Test: `endinggw`.

- The end credits (DoEndCredits): build.py reads the game's credits data
  (EndCreditDat) from the ROM and turns it into rows of text (row,
  column, length, tiles) for each of its 18 screens, with the game's
  waits between them, at $B400 in the messages bank. After the end
  music's first part the people and the hero go, and each screen blanks
  the view and draws its rows; the last stays. The player runs from the
  messages bank with the power-on code. Each screen fades in and out
  (FadeSub: the VBI takes it from every color's luminance, a step every
  other frame), the last only in. Colors are not the game's. Test:
  `credits`.
- The title screen: build.py reads the title's background from the ROM
  (DoIntroGFX's nametable, CHR bank 0, palette IntroPalTbl2) and turns its
  2x2 tile groups into mode 4 characters as the maps' are: a character
  set, the view's 28 rows of codes and the colors, at $9000 in the people
  bank. At power-on (where the name window is: the stick build, or a
  script's `;NAME-ENTRY`) TitleShow puts it over the view, no people, the
  hero out of sight; the lower button then goes on to the name window,
  the upper to the password's, the map back. Its text rows (below the
  banner) are mode 2 rows, their tiles at full width in one color from
  set B: TitleDLI, above them, switches the set and the colors, and
  TitleEnd builds the display list again. The title's dragon sprites
  are not drawn. Tests: `nameentry`, `pwname` (a button past it first).
- Princess Gwaelin in the throne room once she is home: her own entry in
  its people (the townsperson figure the game gives her there), loaded
  only with ModFlags' returned bit (LoadPeople). Carrying her, the hero
  is drawn in a second color pair (the VBI's HeroColors+2: his body
  rose), no new figure. *Now:* he has the game's frames carrying her. The King's password window and its encoding now
  run from the messages bank too, for room. Test: `princesshome`.
- The start menu: after the title, a blank screen with NEW GAME and
  CONTINUE (the port's own words; the stick, then the lower button or
  Start). NEW GAME opens the name window, CONTINUE the password window,
  both on the blank screen (the upper button with nothing typed goes
  back to the menu); then the map, the people and the hero come back
  (GameStart). Test: `menu`; `nameentry`, `opening`, `pwname`,
  `keystart` go through it.
- Fixed: the dialog window's top line showed the map's character set: the
  display list interrupt worked out its row before switching to set B,
  and the switch came a line late. It now switches first, on the line
  the VBI works out (DlgVCount). *Now:* the VBI chooses the interrupt
  (DLI while the window is up, DLINone else), and it sets only the set
  before the line's end: testing the line first made it miss, and the
  window's top line came in set A (a line across the screen).
- The game's start: the play build begins in the throne room before the
  King (SetStartPos: (3,4), facing him), who says his first words once the
  name is given (FirstKingDialog); after a password he is glad the hero
  has returned, says the experience for the next level and farewell. The
  throne room keeps its three chests and its door until the hero first
  goes to another map (Flags2 bit 1, the game's F_LEFT_THROOM; castle.asm's
  HideThrone makes them floor after; a password sets it too). Test
  builds start where their scripts say (the overworld by default). Tests:
  `opening`, `throneleft`; `pwentry` and `pwname` end on the King's words.
- Fixed: SetBridge's branches for no bridge landed on its copy loop's
  anonymous label, not its end: on every map load without the bridge it
  copied part of a row, marked the bridge as built (BridgeY), and could
  write a stray byte into the hero's player (a line of pixels above him).
  Test: `bridgeclosed`.
- Townspeople stand still, and most are drawn into the background: with
  no one wandering, each town's people are drawn into its map as composite
  blocks (the floor under them with their pixels from the ROM, each pixel
  in the nearest of the colors its character can show) wherever the
  town's 64 characters and its spare block numbers allow (78 of the
  game's 120). They are still in the town's people list (mobile $80), so
  TALK reaches them; they just are not drawn as sprites. Those with the
  most others a row or less away go first, so the sprites left crowd the
  two players' rows least. Guards, shopkeepers, innkeepers, the King and
  everyone else the game stands still keep their places; where three
  sprites would still share rows on a screen, one that wandered in the
  game is moved to the nearest free floor within 5 blocks that ends it
  (convert.py's spread_sprites: one Garinham townsperson, two blocks). The
  princess, the staff of rain's old man and the Dragonlord's floor keep
  sprites (they come and go). More color, no flicker for those drawn in
  the background, and in Brecconary the main loop takes 4,950 cycles a
  frame on average (it was 11,400). *Now:* all but five are, below.
- The password keeps all the game's own log does, so a continued hero is
  the one saved: 19 bytes (gold, experience, the items, keys and herbs,
  the equipment, ModFlags, Flags2: the fighter's ring now too, the HP and
  MP, and the name's 8 characters at 5 bits each, their places in the
  name window's grid) and a check byte, scrambled as before: 160 bits,
  32 characters, shown and typed in two rows of 16, four at a time.
  After a right one the name is the password's (no name window: before,
  a new name gave the stats a new pattern), the stats come from the level
  and the name, and the HP and MP are as kept (no more than the max;
  cursed, 1, as the game starts a cursed hero). PwBuf and PwChars moved
  to $3B00, free since the people's frames went. password.py's `moves`
  writes a test script's entries to type one. Tests: `kingsave`,
  `pwentry`, `pwname`.
- The townspeople's sprite code is gone, with no one to draw as a
  sprite: DrawPeople, PlacePeople, Redraw and their tables, the DLI's
  per-row player moves, ClearPlayers, the command window's hiding of the
  people under it, and the people's frames (people.bin, copied to RAM at
  power on; the build now stops if any townsperson is not in a map's
  background). The people are a list for TALK and for who comes and goes,
  and their stepping in place. The program has 1,272 bytes free (it had
  71), and in Brecconary the main loop takes 3,020 cycles a frame on
  average (it was 3,890).
- Every townsperson in the background: the two left as sprites (in
  Brecconary and Rimuldar, at their top edges, where neither town had a
  character to spare) fit now. When a town is full, convert.py's
  merged_people makes two of the townspeople's characters one where they
  differ by MERGE_LIMIT (4) of their 32 pixels at most, the closest
  first, until all fit; the map blocks' own characters are never
  changed. Brecconary's four merges change 1 to 3 pixels, Rimuldar's 3
  or 4. No townsperson is a sprite now (SpriteOne: none on every map).
- Those who come and go are in the background too: the princess in the
  throne room (once she is home), the staff of rain's old man, and the
  Dragonlord on his floor (in his own figure, LORD_GRAPHIC). convert.py's
  COMES_AND_GOES lists them with a ModFlags bit, and the build writes
  each one's place and the block under it (CondMap and so on);
  CondPeople, after a map's people load, puts back the block under each
  who is not there (her not home, him dead) and takes the person out of
  TALK's reach; the old man's block goes as he gives the staff
  (CondHere). Before, nothing took the Dragonlord away once dead. The
  sprite swap of his figure (SetLordGfx, lord.bin) is gone. Test:
  `lordgone`.
- Atari touches, things the NES does not do:
  - The overworld's sea sways: its open water's two characters swap with
    a copy whose waves sit a pixel to the right (convert.py's ripple),
    every 16 frames, through the townspeople's stepping (anim.bin's map
    0; AnimStep). Its blue is the towns', caves' and mountains' too, so a
    color cycle would have made them pulse; this moves the waves only.
  - The lead voice's long notes have a vibrato: after 20 frames, its
    16-bit divider moves up to twice its high byte up and down (about 14
    cents), a cycle each 16 frames (ToPokey, VibAge, VibMul).
  - Some effects' noise has POKEY's own textures (sound.py's NOISE_DIST,
    in the sound bank): the dragon's fire crackles (17-bit noise through
    the 5-bit), the hits and the force field buzz (the 4-bit); the rest
    keep the NES's white noise.
  - Monsters come and go: off the overworld, where the map round the
    battle window is black, the monster's colors fade in from black and
    out to it (MonFade, MonsterShade in the VBI: BattleDLI2 shows
    MonShow); on the overworld, whose scene shares the monster's
    colors, its rows show or go one by one, every other first, a row a
    frame (MonsterComes, EraseMonster, MonsterWipe).
- The music softer, and lower under the sound effects: tried on a
  SuperStation One, the music drowned the effects (POKEY's channels add
  up as they are; the NES's mix softens a loud one). ToPokey now plays
  the music's channels through MusicVol, a quarter softer, and at half
  while an effect sounds; the effect's tone or noise keeps its own
  loudness. *Now:* half, and a third (below). (The second voice's tuning was measured too: it plays above
  the first only 73 times in all the music, so giving the 16-bit pair to
  the higher voice would not help; its 8-bit notes stay.)
- The biggest monsters keep their shapes: seven need more than a set's
  63 glyphs on the scene (up to 87), and their least used ones took the
  nearest other's. Their rows from MonSplit now have a second set
  (Lower2Set, $3400), in the same colors: battle.py's monster picks the
  row that leaves the fuller of the two sets the fewest (46 at most),
  numbers each set's glyphs apart, and the record says the split and the
  second count; a fourth display list interrupt (BattleDLI2b) switches
  the set. For the room the map beside the window is recolored a byte at
  a time as each of its characters is copied (MapByte), not through two
  256-byte tables, and the remap table and the grid moved ($2A00,
  $3900). The caves' monsters on black all fit one set. Test:
  `bigmonster`.
- Less work for the people: no one wanders, so MovePeople and each
  person's step and offsets are gone; and a map has one person at most
  not drawn in its background (the build stops otherwise), found when
  its people load (SpriteOne): with none DrawPeople returns at once, else
  PlacePeople and Redraw work on that one, not the whole list. In
  Brecconary DrawPeople takes 990 cycles a frame on average, 2,740 at
  most (it was 2,480 and 8,210), and the program is 226 bytes shorter.
  The townspeople's step in place (AnimStep) is now last in the frame,
  and waits a frame when a step of the hero's began in it (the longest).
- The hero on three players, in his own colors: no map has more than
  one person left as a sprite, so the people use player 3 only (DrawOne;
  the DLI and VBI move only it) and player 2 is the hero's. His frames
  (convert.py's hero_frames: 16, the last 8 carrying the princess, 64
  bytes each, in bank 7 at GFX_HERO) are players 0-2's lines; each NES
  color shows as COLPM0, COLPM1, their overlap or COLPM2, chosen for the
  least error: white, blue and his skin's pink (it was light blue), and
  carrying her, her white, pink, his blue and her dark red hair. ShowHero
  reads the frame from the bank (and puts back the bank that was in);
  HeroAt places or hides all three players. The RAM copies of his frames
  (HeroGfx, CarryGfx) are gone.
- Room: one routine draws the four window templates (DrawTemplate), one
  gives a set A glyph's address (CharPtr), one selects the messages bank
  (SelectMsg). Set B, the same for every map since the dialog went to
  mode 2, is in bank 7 once (GFX_SETB; LoadSetB at power on and after
  the title): a map's image is $500 bytes, not $900, 27KB less in all
  and 1KB less to copy on each map load. The profile build fits again.
- The townspeople drawn in the background step in place, as the hero
  does (every 16 frames, in time with him): convert.py's map_image makes
  each background figure in both steps of its walk, and lists the
  characters of theirs that differ in the other (none a block's own; one
  two looks share with different steps stands still): anim.bin, in bank
  7 at GFX_ANIM, each map's codes and other-step glyphs. LoadAnim copies
  the map's to RAM (AnimCodes, AnimGlyphs at $2B00) and AnimStep swaps
  them with set A's when FrameCount's bit 4 changes (not at power-on). No
  extra character codes: 27 characters step in Brecconary, 25 in Kol
  and Rimuldar, 17 in Tantegel.
- The dialog window in high resolution: while it is up its rows
  (DLG_FIRST on) are ANTIC mode 2 (the VBI's DialogModes), and set B
  holds each text tile at the NES's full 8 pixels (convert.py's
  hires_char), white on black (COLPF1's brightness on COLPF2, set by the
  DLI at the window's top, or BattleDLI3 in a fight). The rows span the
  screen and the window clears them, so nothing else shows in mode 2.
  The name slots now take the name's capitals from set A (NameGlyphs),
  not set B's glyphs: the status window shows the name in capitals, like
  the rest of the windows' text.
- The Dragonlord's second form has his picture: the game's end boss
  (LoadEndBossGFX: 19 background tiles and 64 sprites from CHR bank 0,
  his two palettes), read from the ROM by battle.py's end_boss, moved
  (BOSS_SHIFT) to stand in the battle window (the loader's quirks kept:
  each background tile two to the left of its listed address, a lone
  $FF in the sprite list taking the next byte's value) and converted as the
  monsters on black are, his band from row 6. The whole view is black
  round him, as in the game (ComposeScene: no map beside the window or
  above it), so the 12 codes the map would take beside the window
  (TEXT_END on) hold his glyphs past 63: 75 (BOSS_GLYPHS; LoadMonster
  copies them after the text). An all-black character is code 0 now,
  for every monster, not a glyph of its own. Test: `lordtrue`.
- The hero carrying the princess has his own frames, the game's
  (CharSpriteTbl's carrying figure, his palette and hers): convert.py's
  carry_frames, in bank 7 (GFX_CARRY), copied to RAM at power on
  (CarryGfx, $2A00); ShowHero takes them while ModFlags' carry bit is
  set. His colors and hers are four, the two multicolor players show
  three, so her white and skin share their overlap: brown hair, violet
  armor, lavender white (the overlap kept a shade of one of the pair, not
  a hue of its own). Test: `rescue`. *Now:* three players (below): his
  blue kept, her white and pink, her hair dark red; no RAM copy.
- Nearly every townsperson in the background: everyone faces down,
  always (no one turns to the hero on TALK), so a figure needs one look,
  not four. Those who wandered in the game are set down on their town's
  main floor (the commonest block under them) at the nearest open spot
  within 6 blocks: never beside a wall, counter, door or sign, never next
  to someone else, never cutting a passage (convert.py's onto_floor), so
  their looks share characters. A town may also put map characters on
  set A's codes past the text, 116-127 (76 characters, not 64; no
  battle there reads those codes). One townsperson in Brecconary and one
  in Rimuldar still do not fit and stay sprites, alone on their rows,
  as do the princess, the staff of rain's old man and the Dragonlord.
- Window text in capitals, from fixed codes: set A holds the digits, the
  capitals, the frame and the arrow, then the name slots, the apostrophe
  and the STATUS window's mark (114-115), then the name window's - . ? !
  (116-119, which towns may take: that window opens only at power-on, on
  the start map). Lower case shows as its capital (TextA), so nothing is
  copied into set A as windows need it: TileA, its glyph cache and
  ResetTiles are gone (about 200 bytes of program). The dialog window
  still shows lower case (set B). A battle's map characters take codes
  from 116 (TEXT_END), not 114.
- No flicker as the view scrolls: a person who moved a line (every one of
  them, as the view scrolls) is drawn over where it was, then the one
  line it left is cleared; only one gone, in the other player or moved
  further is wiped first. So no one is ever missing from a frame being
  shown. (People in a player have a line between them at least, so the
  line cleared is no one else's.) The townspeople under the status or
  command window are now hidden before the window is drawn, not after
  (they showed over it for that frame). For room, the full bag's steps
  (DiscardItem) run from MSG_BANK too.
- Less flicker among the townspeople: they were all wiped and drawn
  again whenever any changed, and those near the top could be missing
  for the frame the screen was drawn in. Now (people.asm's Redraw) each
  one's last drawing is kept (its frame, player and top: OldKey,
  OldTop): only who moved or went is wiped, and only who changed is
  drawn; one that only turned or stepped in place is drawn over itself,
  and one that only moved sideways needs no drawing at all (its position
  is the player's register). For room, steps whose code is in MSG_BANK
  (the ending's, the credits, the King's password wait) are entered by
  the step runner itself, which selects that bank for an address of
  $8000 on.
- The keypad: Start goes past the title (as the lower button); Pause
  holds the game while walking until pressed again (the NES's Start);
  keys 1-8 do a command at once, the window not opened: 1 TALK, 2
  STAIRS, 3 ITEM, 4 SPELL, 5 DOOR, 6 TAKE, 7 STATUS, 8 SEARCH (the most
  used first; `KeyCommand` in windows.asm). A test script's buttons byte
  takes a key in its high half (KBCODE bits 1-4: key 1 $F0, Pause $80,
  Start $C0). Tests: `keytalk`, `keypause`, `keystart`.
- The princess's keepsake with a full bag (DoKingDialog): the King takes
  the first held of torch, dragon's scale, fighter's ring, fairy water,
  wings, cursed belt, staff of rain (InvListTbl) for it and says so; with
  none of them, no keepsake. Test: `keepfull`. The secret passage's name
  is now the item name table's right entry (it read past its end).
- `newspell`'s presses follow the name's part in the stats (the hero now
  wins in fewer rounds).
- A battle's start no longer shows garbage (seen on a SuperStation One:
  the whole screen in the wrong characters for about 13 frames). The
  battle's interrupts came on with BattleOn, before the monster's sets were
  loaded and the scene composed, at the walking display list's rows. Now
  ComposeScene writes the scene's rows into SceneBuf ($3C00) while the map
  shows on in set A, and SceneSwap puts them on the screen at once, once
  the beam is past row 17: BattleOn and the rows' interrupt bits, then the
  rows copied, done before the beam is back at the scene.
- The NES's hit and spell effects, timed as the game times them
  (`Effects` in the VBI, started by `StartFx`): the hero hit, the screen
  shaken 2 pixels over, then down, one frame in three, 8 times (HSCROL and
  VSCROL nudged; not against the Dragonlord's second form), with a red
  tint every other frame once the blow kills him; the enemy hit, the
  monster blinking, hidden 2 frames in 5, 5 times (its cells redrawn from
  the grid without it: one colour register can't be turned red for it
  alone, as the map beside it shares them); the enemy chanting, its band
  grey 2 frames in 5, 5 times; a spell cast (or the wings thrown), the
  screen grey 3 frames in 5, 8 times. A battle waits for its effect before
  the next message. `fight`, `battlehurt` and `cavewin`'s
  presses follow the longer rounds.
- The shake's sideways nudge (HSCROL 2 more) showed a sliver of column -1
  on the dialog's rows, never cleared: a dotted line beside the window.
  The dialog now clears columns -1 to 32. Brecconary's man beside the road
  stands on it again, where the game has him (`KEEP_PLACE` in
  convert.py): set down on the town's yellow floor, he was hard to see.
- A battle's end no longer shows garbage as its windows close: the
  battle's interrupts and the dialog's mode 2 rows went off at once while
  the map was redrawn over several frames, so the old screen showed
  through the map's set. Now EndBattle copies each display list row's 40
  bytes into FreezeBuf ($3B50) and shows the rows from there (`Frozen`,
  the VBI's SetAddresses) while the map is drawn under them; then the VBI
  ends the battle's display in one frame (`EndPending`): the rows back on
  the ring, BattleOn and DialogOn off, the interrupt bits, the hero shown.
- The full width: ANTIC's normal playfield (40 columns), not the narrow
  one (32), so the picture fills a television as most 5200 games' do. The
  windows, battle scene and menus keep their columns (0-31 in the middle:
  column -4 is the left edge, SetScroll's address 7 characters before the
  view's); the map is drawn two blocks more each side (DrawRow from
  LeftBlock - 2, 22 blocks; a step's new column at LeftBlock - 2 or + 19);
  the dialog clears, and gives back when it closes, columns -5 to 36; the
  battle composes columns -5 to 36 (SCENE_LEFT, SCENE_WIDE); the title and
  blank screens fill the columns beside theirs. ANTIC fetches 48 bytes a
  row with HSCROL now, so FreezeBuf takes 29 rows of 48: rows 0-4 in
  player 3's unused memory ($0F00, HPOSP3 kept 0), the rest at $3B00.
  `lordwin` starts a frame later: the new timing changed the fight's
  random numbers, and a level 30 hero can lose to him.
- A softer edge to the light in dark places, a touch of the port's own
  (the NES's edge is hard): the ring of blocks just past the torch's or
  RADIANT's light is drawn dimmed, every other pixel black, so the light
  fades into the dark over a block. convert.py's dim_copies puts each of a
  dark map's characters again DIM_ADD (32) codes on, checkerboarded (dark
  maps use at most 22); LightClass sorts each block into lit, ring or dark,
  and the block drawers add CharAdd (0 or DIM_ADD) to its codes. No ring
  without a light, so the hero's own block is still all there is then.
  RedrawLight now reaches two blocks past the light, to take the old ring
  back to black as the hero moves or RADIANT fades.
- Three things a 5200 cartridge does: the keypad's Reset starts the
  cartridge again, at the title (KEY_RESET, once it is let go; test builds
  keep their script going over it, ResetHook); attract mode, after about 9
  minutes with nothing pressed (IdleLo/IdleHi, counted by the VBI), the
  screen all one hue, a new one every 256 frames, and dimmed (AttractMask
  $F6 on every color written, the hero's and the dialog's too), until
  anything is pressed; and Pause dims the screen (FadeSub 4) while it
  holds the game. Tests: `keyreset`, `keypausedim`; `keypause` checks the
  dim is gone after.
- The NES's message speed and its fades between maps. The start menu has
  a third line, TEXT FAST, NORMAL or SLOW (the port's words; the lower
  button changes it): DialogFrame waits TextSpeed frames between letters,
  as the game waits MessageSpeed + 1 frames a letter (fast, the port's
  speed until now, is the default). Going to another map fades out, 4
  luminance a step every 4 frames, and the new map fades in from 3 steps
  dark (PalFadeOut, PalFadeIn), the hero too (FadeLum); not the boot's
  map, before the VBI runs (VbiOn). Test builds leave the fades out, so
  their timing stays (a `;FADE` line keeps them: build.py --fade). Tests:
  `menuspeed`, `fadedoor`.
- Hurtful ground flashes the screen red, as the game's RedFlashScreen
  does: once for a step on the swamp, three times on the barrier, a frame
  each (FX_GROUND, the red tint of the hero's death). Test: `swampflash`.
- Three more of the NES's touches, and a fix. The selection cursor blinks
  as the game's does, shown 16 frames and gone 16, shown at once when it
  is drawn: CursorBlink in the VBI changes the arrow's glyph (set A's,
  kept per map in ArrowA; in a battle the bands' copies too, the monster's
  white one in ArrowL), so every menu's cursor blinks without its own
  code. The inn fades out for the night and in for the morning (FadeOut,
  FadeIn: the map changes' fades, now shared). The rainbow drop's cave
  keeper flashes the screen grey and back before sending a hero without
  Erdrick's token out. And the wizard in Tantegel who gives MP back now
  does: before, he only spoke; now his words, the grey flash and all the
  hero's MP (MP_MAN, the game's $6A dialog). Test builds take `;DRAIN: N`
  (N MP short). Test: `mpwizard`.
- Found by sweeping transitions frame by frame (screenshots a frame or
  two apart): as a battle came up, the rows below the scene showed the
  map through set B for the frames before the dialog opened (BattleDLI3
  now keeps set A and the map's colors until DialogOn); a dialog's frame
  showed in set A for a frame (OpenDialog sets DialogOn before drawing
  it); and the inn's fade left the dialog's text bright (the VBI works
  out the ink, faded and dimmed, as DlgInk). Test builds take `;SEED: N`:
  each battle's random numbers from N, so `lordwin`, a fight the hero
  wins about half the time, no longer turns on timing elsewhere.
- From the owner's tests on real hardware. The title's dragon was the
  wrong tiles: its sprites are in CHR half 3 on the title (Bank3ToNT1),
  not 1, the text's (letters stood where the dragon is). The hero showed
  by the title's banner and then by the start menu's window: his lines
  are in players 0 and 1, which the title moves to the dragon's place.
  The title now blanks his lines (ShowHero waits while it is up) and
  TitleEnd puts him out of sight until the game starts. The start menu's
  order is now continue, begin a new quest, change the message speed, so
  the speed's word is under its choice (the game has the speed second).
- The credits' last screens. The game shows 19, not 18: the publisher's
  mark, then the closing banner, which stays; both pictures of tiles of
  the CHR bank the credits load, not text. The port stopped at the mark
  and drew its tiles as letters (a block of capitals). build.py now makes
  all 19 screens, and the two pictures' screens begin with their
  characters (squeezed in the text's color, as set A's text is), which
  CrLine copies over the capitals' (CR_GLYPHS_AT), the tiles made the
  capitals' (neither screen has text).
- From the sweeps of a chest, the princess's rescue and the credits: a
  line across the screen over every dialog window on a map (in set A, the
  window's top line). The dialog's interrupt tested DialogOn and its line
  before switching sets and missed the line's end; the VBI now chooses it
  (DLI or DLINone) and it switches at once. DlgVCount is gone.
- From the sweeps of the Dragonlord's second form, a level-up and an
  overworld fight. *Now:* the battle's row interrupts load only what fits
  before the line's end: BattleDLI2 only its set (loading the colors too
  missed the end, and the band's first line showed in the old set: a line
  over the monster), and the dialog's or the map's rows each have their own
  interrupt (Dli3Dialog, BattleDLI3), chosen by the one before, so neither
  tests DialogOn on the line. A number or name in a message is measured as
  the game measures a word, with the letters after it, to and with a
  period, comma or apostrophe (WrapWord, WrapLetters): "1" fit and its
  period went to a line of its own (wrapnumber).
- More from the frame by frame sweeps. The battle's row interrupts wrote
  their colors after the line had begun (dots at a band's left edge):
  they load before WSYNC and write the most seen first, from the colors
  the VBI set (ShownColors: tinted, faded, dimmed). The scene's copy could
  lose its race with the beam on the wider screen: a battle now starts as
  it ends, the screen held (FreezeView) while ComposeScene draws straight
  into the ring, then the VBI shows it with the battle's interrupts in
  one frame (StartPending); SceneBuf and its copy are gone. A dialog's
  rows now change mode and set a frame before anything is drawn on them,
  opening and closing (ClearDlgRows, WaitFrame): drawn sooner, its frame,
  or the map after it, showed in the other mode for a frame.
- The title and the start menu closer to the NES's, all of it from the
  ROM at build time. The title's bands each keep their own NES palette
  (borders, banner, each line of text: the attribute rows are uniform), so
  its pixels keep their NES color numbers and TitleDLI sets each band's
  colors at its first row (TitleBands, TITLE_BANDS): a white logo with its
  shadow on the banner's grey. Its sprites (DrgSprites, the sprites'
  pattern table) are players 0 and 1, black, in front of the banner,
  placed as the background is (TITLE_SPR_*), cleared when the title goes.
  The start menu shows the game's own words (build.py's menuwords.asm,
  from the window data FullMenuDat and MsgSpeedDat): continuing a quest,
  changing the message speed (each choice the next, the game's word for
  it shown below), beginning a new quest, the cursor on the last; the
  log's copy and erase are left out (there is no log). `menu` and
  `menuspeed` check its state, not its words.
- The title's columns beside its own (the full width's) now carry each
  row's 2-cell pattern on in step, from its first two cells and its last
  two (the background there in every row): repeating the edge cell alone
  broke the banner's stripes, and wrapping the row round brought pieces
  of the logo to the sides.
- Room in the program's half: the boot's setting up (BootInit: RAM
  cleared, the new hero, the controller, the tables, the display list,
  the sound, the vectors) and the new hero's table run from bank 8, as the
  power-on windows do; the tables' copy, which changes banks, goes through
  FarOut (BootTables). 153 bytes back (22 free to 175). The title's
  drawing stays: it reads its picture from another bank. Then the special
  characters' story steps (LordStep and what it dispatches to: the
  Dragonlord's offer, the two keepers, the MP wizard, the princess and
  the King's keepsake, the curse lifter, the ring man) moved to bank 8
  too; the step machine already enters steps there, StepStart selects the
  bank before LordStep, and their two calls that redraw the map
  (CloseDialog, SetBlock) go through FarOut. 521 more (696 free).
- The music softer again, about half the NES's loudness, a third while
  an effect sounds (MusicVol), nearer other 5200 games; the effects stay
  as loud.
- No glimpse of the King's chamber before the title or the start menu:
  the map loaded at power-on, and reloaded behind the menu, is loaded
  quietly (QuietLoad: no music, no fade in, the screen left off), and the
  title and the menu turn the screen on once they are drawn. (It showed,
  with its music, for a moment; the fades made the menu's longer.)
- The title and the start menu play the game's own music, as the NES
  does: the title its intro music (MSC_INTRO, as DoIntroRoutine starts
  it), the start menu, name and password windows the pre-game (village)
  music, started once. Tests: `titlemusic`; `menu` and `keystart` check
  the song too.

## Profiling: what is not native, and what a rewrite saved

The parts that still did things the NES's way were looked over, measured
and rewritten:

- The sound's NES hardware model (the four quarter-frame envelope steps a
  frame, the NES's register layout, loops over every channel): rewritten
  native, the same sound to the frame (every music and effect played by
  both engines on the simulator, every channel's note and volume each
  frame compared). 766 cycles a frame on average down to 408, the worst
  frame 2127 down to 1673; 76 bytes less.
- Messages were found as the game finds them: from the start of their
  block, reading through each message before them (up to 15). A table of
  where each starts (bank 8, made from the ROM's text) finds one at once:
  thousands of cycles less each time a message starts, and the block
  table and the search are gone from the program.
- What each townsperson says was a table of all 256 of the game's dialog
  control bytes (512 bytes, and a message list for each); it now holds
  only the ones the people have (48), each person's control byte turned
  into an index: 744 bytes less.

The main loop, timed phase by phase in a profile build (`PROFILE=1`), in
Brecconary's streets among its people (the tightest place): drawing the
townspeople took most of a frame, 14,000 cycles on average (wall time:
the display's DMA and the interrupts included) and up to 27,000. Done
about it:

- The display list interrupts were on every row while there were people
  (28 a frame, about 90 cycles each), most of them changing nothing; now
  only the rows where a player moves or changes color have one (and the
  dialog window's, the battle's), set after a redraw only when the rows
  with people in them change (a mask of them is kept).
- A person's 16 lines are drawn and cleared unrolled when all of them
  show (the usual case).
- Where each is on screen is worked out in 8 bits, its carries saying
  when it is off the screen; and a person's place under the windows is
  only looked at when a window is open (never while walking).

Drawing the people now takes 9,400 cycles a frame on average there, the
whole main loop 11,600 (from 14,200); the screens are the same to the
pixel.

Then the frame a step starts, the next most: it draws the row (18 blocks)
or column (16) of map blocks coming into view, and each block was found
alone (GetBlock: the map's edges, its bank, its row's address, all again
for each). Now a row's pointer, bank and ring row are found once and its
blocks drawn in one loop; a column's bank once, its rows a fixed stride
apart (120 on the overworld, 32 in a town) so going down one is an add,
its ring row counted on. Closing a window redraws through the same row
loop. On the simulator: a row 3,890 cycles down to 2,397 (a town's 4,466
to 2,434), a column 3,438 to 2,630 (a town's 3,949 to 2,630), every block
the same (96 draws compared, the map's edges and the view wrapping round
them included). In Brecconary the step's start now takes at most 6,840
cycles (it was 10,488).

The program then had about 2.6KB free. Features since filled it; for room,
the power-on screens, the password's making, the end credits and many
tables run from or sit in other banks, and about 300 bytes are free.

## The sound, closer to the NES

Measured with `tools/native/compare_sound.py`, which runs the sound engine
on a 6502 simulator and sets POKEY's pitch and loudness, channel by
channel, against the NES's from the same state:

- Channels 3 and 4 (SQ2, the triangle) switch to POKEY's 15kHz clock on a
  frame a note of theirs is too low for 64kHz, when neither's note is out
  of tune there (NoteFlags); else 64kHz, the low note an octave up as
  before. Over the music: SQ2 34 cents off on average to 20, the
  triangle 51 to 33; frames an octave off, SQ2's 97 to 44, the
  triangle's 587 to 346 (those left are clashes: one note too low for
  64kHz while the other is too high for 15kHz).
- A pulse's duty: POKEY plays every tone at 50%, so a narrower pulse is
  made as much quieter as it is on the NES (DutyVol: its wave's RMS, 12.5%
  0.66, 25% and 75% 0.87). The triangle up from 10 to 13 (TRI_VOLUME): the
  balance of SQ2 and the triangle against SQ1 is now the NES's (the
  triangle 1.56 times SQ1, as on the NES; it was 1.03).
- The sweep unit, the NES's, for the effects' SQ2: only the wings' flight
  uses it (SweepFrame each frame of an effect, SweepOut for channel 3's
  divider by the timer, TimerDiv), checked frame by frame against a model
  of the NES's: the same, all 84 frames.
- An effect's tone and noise both sounding: channel 3 plays the louder
  (the wings' noise is at volume 1 under its tone, near silent on the
  NES; it had hidden the tone).
- The port's own touches stay, at the owner's wish, for some Atari
  character: the lead voice's vibrato on long notes, and the effects'
  noise textures (crackling fire, buzzing hits).

The sound now takes 762 cycles a frame on average (647 before), at worst
2262 (1741), during the wings' sweep.

## The VBI's order (from the owner's tests: the shake)

On a SuperStation One, when the hero was hit the screen sometimes went
blank for a frame, or showed a brief glitch where a flash should be. A
probe of VCOUNT in the VBI found the fine scroll written at line 42, well
into the picture (it begins at line 16): it came after SetAddresses, the
VBI's longest part (until line 44), and the colors after much else. A
changed scroll (the shake) or color (a flash) then landed partway down a
frame; the emulator forgave it, the hardware did not (a scroll changed
mid-frame can change the frame's length, and the picture is lost). *Now:*
the VBI writes first what ANTIC reads from the frame's first line: the
fine scroll (by line 0), the interrupt vector, the colors (SetHardware,
by line 6), then the rows' addresses (SetAddresses, begun in the blank
and ahead of the rows); then DialogModes, and what readies the next
frame (Effects, CursorBlink, MonsterShade), the frame count and the
sound. The shake and flashes come a frame later, as Effects sets them
for the next frame.

## Turning before walking (from the owner's play on the NES)

On the NES, a direction pressed while standing turns the hero at once, but
the step waits for the game's 16-frame beat (DoJoyUp and the rest move
only when FrameCounter AND 15 is 0), so a tap only turns him; the port
stepped at once. *Now:* the same (Walk, SetFacing): from standing, the
turn at once and the step on the beat (FrameCount AND 15 = 0) while the
direction is held; walking on, the next step at once (the game's steps end
on the beat anyway, and a frame run long must not cost a whole beat).
Play builds only (WALK_BEAT): test builds step at once, as their scripts'
short presses expect, but with `;WALK-BEAT`. Test: `walkbeat`.

