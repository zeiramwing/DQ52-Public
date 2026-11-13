# How the native engine fits together

A guide for anyone, person or AI, opening this code cold. `README.md`
says what the port does feature by feature; this says where things live
and how they connect. Read this first, then the header comment of the
file you need: every `native/*.asm` and `tools/native/*.py` file opens
with one.

## The idea in one paragraph

The player supplies their own NES ROM. `tools/native/build.py` reads the
game's data out of it (maps, text, monsters, sound, tables) and converts
it into formats made for the 5200. It then assembles a new program,
written from scratch in `native/*.asm`, that uses that data. The
disassembly in `vendor/` is only a reference for how the game behaves;
none of its code runs. No game data is ever committed: `build/`,
`vendor/` and `*.nes` are ignored.

## Build pipeline

```
ROM.nes ──► tools/native/rom.py        reads tables by bank and address (rom.AT)
        ──► tools/native/convert.py    maps, text, sprites, colors  ─┐
            maps.py battle.py sound.py items.py window.py            ├─► build/native/*.bin
            tools/colordata.py font4.py monsters.py                  ┘
        ──► tools/native/build.py      writes config.asm (build options), runs Ophis on
                                       native/main.asm (which .includes every other file),
                                       then lays the .bin files and the program into
                                       16 banks: build/dwnative.bin (512KB SuperCart, type 74)
```

`./build.sh ROM.nes` does all of it. Test builds add options
(`--script NAME`, `--start MAP,X,Y`, `--flags N`, ...); see build.py's
docstring.

## The cartridge

A SuperCart switches a 32KB window ($4000-$BFFF) between 16 banks.
**The program is copied into the first half ($4000-$7FFF) of every
bank**, so it is always present; only the second half ($8000-$BFBF)
changes. `SelectBank` switches, and remembers the bank in `CurBank` (the
VBI puts it back after reading sound data).

| Bank | Data half ($8000-$BFBF) |
|---|---|
| 0 | the overworld map |
| 1 | the text, then the enemy and item names |
| 2, 12 | town maps |
| 3, 9, 11, 14 | map images (charsets and colors), 7 a bank |
| 4, 5 | monster pictures (5 also holds extra map images) |
| 6 | music and effects, and the sound's divider tables |
| 7 | RAM tables copied at boot (from $8500); the townspeople's other step (`GFX_ANIM` $8B00), set B (`GFX_SETB` $9800), the hero's 16 frames (`GFX_HERO` $9C00) |
| 8 | `MSG_BANK`: message tables, game tables (enemies, maps, shops, levels...), test scripts; **code** at $A000 (`poweron.asm`); the credits at $B400 |
| 10 | the townspeople tables; the title screen at $9000 |
| 13 | monster pictures on black (caves) |
| 15 | the cartridge header |

Free room is roughly 9KB in bank 7 (past `GFX_HERO`'s 1KB at $9C00),
9.3KB in bank 10 and 5KB each in banks 5 and 6; the map images' banks
hold 7 of $500 bytes each, so each has about 7KB unused. Bank 1 (text)
is full. The program half has about 1,270 bytes free; the build prints
`program to $XXXX, N bytes free`.

### Code that runs from a bank (`poweron.asm`)

What Ophis assembles past $8000 (after `main.asm`'s
`.advance $8000`) is `poweron.asm`, assembled for $A000. build.py
splits it off and puts it in bank 8. It holds code that rarely runs:
the title, name and password windows, the password's encoding and
decoding, and the end credits. Rules for code there:

- Enter it only with bank 8 selected. A step machine step there needs
  nothing: `RunShopStep` selects bank 8 for any step address of $8000
  on. Other entries go through a stub (`PowerOn`, `PwShowP`).
- It may `JSR` program routines that never switch banks, and may
  `JMP` to any routine (the `RTS` then returns to the program).
- A `JSR` to a program routine that switches banks must go through
  `FarOut` (X/Y = the routine's address), which reselects bank 8
  before returning.

## RAM ($0000-$3FFF)

| Range | What |
|---|---|
| $00-$FF | zero page: pointers (`Ptr`, `MapPtr`, `DstPtr`...), the frame counter, `Mode` |
| $0200-$02FF | the hero (`HeroName` $0240 on: level, HP, gold, stats, items), shop and list state |
| $0300 | the display list |
| $0400-$07FF | townspeople arrays, enemy record, map record (`MapRec` $0770), password and power-on state; $07Bx-$07Cx: flash, fades, credits, title |
| $0800-$0BFF | tables copied from bank 7 at boot (text tile codes, window templates) |
| $0C00-$0FFF | player/missile graphics (players 0-2 the hero; player 3 unused) |
| $1000-$1FFF | the screen: a ring of 32 rows × 128 bytes, scrolled |
| $2000-$28FF | set A (the map's image), set B (every map's, `LoadSetB`), block tables, colors (`MapColors` $28C8) |
| $2900-$2BFF | the stepping characters (`AnimCodes` $2950, `AnimGlyphs` $2B00); a battle's `RemapTbl` $2A00 |
| $2C00-$2FFF | the current town's map (doors and chests change it) |
| $3000-$3AFF | a battle's: the monster's sets (`LowerSet` $3000, `Lower2Set` $3400), its grids (`WithoutGrid` $3800, `WithGrid` $3900), `SceneGrid` $3A00 |
| $3B00-$3FFF | the password's bytes and characters (`PwBuf` $3B00, `PwChars` $3B20); the rest free |

The whole of `$0400-$28FF` is cleared at boot.

## The main loop and modes

`MainLoop` in `main.asm` waits for the VBI's frame, reads input
(`Pressed` = buttons newly pressed, `StickNew` = directions newly held,
`KeyNew` = a keypad key just pressed, as KBCODE bits 1-4),
then runs one frame of the current `Mode`:

| Mode | What | Frame routine |
|---|---|---|
| 0 | walking | `Walk` (in `main.asm`) |
| 1 | the command window | `CommandFrame` (`windows.asm`) |
| 2 | a dialog | `DialogFrame` (`text.asm`) |
| 3 | a battle | `BattleFrame` (`battle.asm`) |
| 4 | a step machine (shops, inns, items, events) | `ShopFrame` (`shop.asm`) |
| 5 | the STATUS window | `StatusFrame` (`status.asm`) |
| 6 | power-on (title, name, password) | `PowerOn` → `PasswordFrame` |

Controls: the lower fire button is the NES's A, the upper B. On the
keypad, Start goes past the title, Pause holds the game while walking,
and keys 1-8 run a command at once through the command window's own
dispatch (`DoCommand`, with `KeyCommand` mapping keys to commands).

After a step ends, `main.asm` checks, in order: doors, the ending's
trigger, the cursed gate, healing armor, hurtful ground, guardian
fights, then random encounters.

### The step machine (Mode 4)

Most multi-message interactions are small state machines. `ShopState`
names the next step. `ShopFrame` runs it once the dialog's current
message is out, through the tables `ShopStepLo`/`ShopStepHi` in
`shop.asm` (each step's number is an `.alias` just above them, such as
`T_BUY` or `DS_ASK`). A step usually ends with one of:

- `ShopSay` (A = message, X = next step),
- `ShopAsk` (the same, plus a YES/NO window; the answer is in `Answer`, 0 = yes),
- `ShopEnd` (the last message).

A dialog list can start a step with the word `$FFFB` followed by a
control byte (`maps.py`'s `Shop(control)`). Bytes below $16 are shops
and inns; $F0 and up are engine events, dispatched in `castle.asm`'s
`LordStep`:

| Control | Event |
|---|---|
| $F0 / $F1 | the Dragonlord's fight / joining him |
| $F2 / $F3 | the rainbow drop's / staff of rain's old man |
| $F4 | the ending |
| $F5 / $F6 | the princess's rescue / the King's thanks |
| $F7 | the King's password window |
| $F8 / $F9 | the curse and ring men |
| $FA | a search find with a full bag |
| $FB | the princess's part in the ending |

To add an interaction: write its steps, add their numbers and the
`ShopStepLo`/`Hi` entries, and either start it from a message list
(`$FFFB` and a new control byte, plus a `LordStep` case) or call
`ShopOpen` (A = first message, X = the step after it).

## Messages and text

Messages are played by number from the ROM's own text: `NextMessage`
finds message N through tables in bank 8 and prints it from bank 1.
`ItemName` and `Amount` fill in the game's name and number slots. A
message list is a run of 16-bit words: message numbers, `$FFFC`
(ask YES/NO), `$FFFB` (start a step), `$FFFF` (end). The game's text is
never written into this repository.

## Tests

`native/scripts/NAME.asm` is a scripted run. Its header lines set the
build (`;START: map,x,y`, `;FLAGS:`, `;ITEM:`, `;NAME-ENTRY`...) and the
checks (`;EXPECT: text on screen`, `;EXPECT-BYTE: Label value`). The body
is entries of `frames, directions, buttons`. `tools/native/test.py ROM
OUTDIR [NAME...]` builds and runs each script in atari800 and compares.
`tools/native/measure.py` checks that walking takes the NES's 16 frames
a step. The whole suite takes about an hour; run it before pushing.

## Pitfalls (each has caused a bug)

- **`SelectBank` destroys X.** Load an index after switching, or keep it elsewhere.
- **Anonymous labels** (`*`, `+`, `-`) count across everything in between.
  Inserting a new `*` between a branch and its target silently moves the
  target. Prefer named labels in new code, and recheck nearby branches
  after an edit.
- **`LoadMap` sets `Mode` to 0.** Code that loads a map mid-sequence must
  set its mode again afterwards.
- **Test scripts count main-loop frames.** Heavy work (a map load,
  drawing a whole screen) can make a button press land while the game is
  busy and be missed. Give such moments generous waits.
- **Memory dumps come after the script ends**, so a short countdown
  (such as the 30-frame grey flash) has usually finished by then.
- **Zero-page pointers are shared.** `Ptr` is used by `PutChar`, and
  `TextPtr` by message printing. Use RAM, or reload the pointer before
  each use, if other routines can run in between.
- **Program space is tight.** Move rarely-run code into `poweron.asm`
  (with a stub), and tables into a bank (bank 8 has room).

## Where to look for what

| You want | Look in |
|---|---|
| boot, the main loop, scrolling, the VBI, the display list | `main.asm` |
| walking onto doors, chests, SEARCH, TAKE, the full-bag ask | `treasure.asm` |
| shops, inns, items, the step machine, the inventory | `shop.asm` |
| spells, in the field and in battle | `spell.asm` |
| battles, levels, death, the name's effect on stats | `battle.asm` |
| the castle, the Dragonlord, quest events, the ending, curses | `castle.asm` |
| townspeople: loading, stepping in place; the display interrupts | `people.asm` |
| windows (status, command, templates) | `windows.asm` |
| the dialog window and message printing | `text.asm` |
| the title, name and password windows; credits | `poweron.asm` |
| password encoding and the King's window stubs | `password.asm`, `poweron.asm`; `tools/native/password.py` the same in Python |
| what a map, a town or a person converts to | `tools/native/maps.py`, `convert.py` |
| where a ROM table is | `tools/native/rom.py` (`AT`) |
