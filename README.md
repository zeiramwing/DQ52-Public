# DQ52: Dragon Warrior for the Atari 5200

A port of NES Dragon Warrior to the Atari 5200. It is not an emulator and
does not run the NES's code: it is an engine written for the 5200 from the
ground up in 6502 assembly, plus build tools that read the game's data from
your own ROM and convert it into the engine's formats.

- The whole game, start to finish: every map, town, dungeon, monster,
  spell, item, shop and quest event, the Dragonlord and the ending with its
  credits. The rules and sums (damage, experience, luck, the name's effect
  on stats) follow the NES's.
- Walking keeps the NES's pace, 16 frames a step, with smooth fine
  scrolling.
- The NES's text, music and sound effects, read from the ROM.
- A 32-character password from the King in place of the battery save.
- Tested in the atari800 emulator, and on a SuperStation One (an FPGA
  5200) on a CRT television.

No game code or data lives in this repository. You supply your own ROM
(the USA release, rev0 or rev1). nmikstas's
[dragon-warrior-disassembly](https://github.com/nmikstas/dragon-warrior-disassembly)
was the reference for how the game works and where its data sits in the
ROM; you don't need it to build.

## License and disclaimer

The code, tools, tests and documentation here are released under the MIT
License (see [LICENSE](LICENSE)).

Dragon Warrior is a trademark of its respective owners, and the game is
their copyrighted work. This project is not affiliated with or endorsed by
them. It contains no game code, data, graphics, text or music: to build
the cartridge you need your own legally obtained ROM. A cartridge built
this way contains data converted from that ROM, so it is for the ROM's
owner only and must not be distributed. The MIT License covers only this
project's own code; it grants no rights to the game.

## Building and playing

    pip install ophis-asm
    ./build.sh path/to/Dragon_Warrior.nes
    atari800 -5200 -cart-type 74 -cart build/dwnative.bin

`build.sh` checks the ROM against the known releases' checksums, converts
its data and assembles the engine into `build/dwnative.bin`: a 512KB
SuperCart image (atari800 cartridge type 74). On real hardware, use a
flash cartridge or FPGA system that supports 512KB SuperCart
banking.

### Controls

| Control | Does |
|---|---|
| Stick | walk, move the cursor |
| Lower fire button | the NES's A: talk, choose, open the command window |
| Upper fire button | the NES's B: back, close |
| Keypad Start | past the title; choose on the start menu |
| Keypad Pause | hold the game while walking (the screen dims) |
| Keypad 1-8 | a command at once, without the command window |
| Keypad Reset | start the cartridge again, at the title |

A printable keypad overlay, in the project's own artwork, is in
[`extras/overlay/`](extras/overlay/).

### The start menu

Three choices, shown in the ROM's own words: continuing an adventure opens the
password window; starting a new one opens the name window; the third
steps the message speed through its three settings, with the current one
shown under it. The NES lists the speed second; it is last here so that
its setting sits under it.

## What differs from the NES, and how the port works around it

The rules, maps, text and music are the NES's. What changed comes from
the 5200's hardware, and each change is the least that made the game fit.

| The 5200's limit | What the port does |
|---|---|
| **160 colour pixels across**, not 256 | Map tiles, monsters and figures are squeezed to half width at build time. The squeeze keeps thin lines (outlines, mortar, window frames) over the fill around them. |
| **5 colours a screen row**, not 4 palettes of 3 | Each map gets a colour plan made from its NES palette. Some NES colours have to share one. |
| **4 one-colour sprites**, not 64 | The hero is three sprites layered for his three colours. Townspeople and monsters are drawn into the background (below). |
| **128 characters a set**, for map and window text together | Window text is in capitals. A town's graphics are capped to fit. A monster gets its own sets, two for the biggest. |
| **No battery save** | The King gives a password that keeps everything the NES's adventure log keeps: name, experience, gold, items, keys, herbs, equipment, curses, the quest's progress, HP and MP. |
| **4 sound channels, 8-bit pitch on most** | The lead voice has exact pitch (two channels joined). The second voice and the bass are 8-bit, so a few notes are slightly off. The square waves' duty settings and the wings' pitch sweep are not reproduced. Sound effects share the second voice's channel. |

### The townspeople stand still

The NES moves up to 20 people at once as sprites; the 5200 has one sprite
to spare after the hero. So the port draws the people into each town's
map:

- **No one wanders.** People who stand still on the NES are where the game
  has them. People who wander are placed on their town's main floor within
  6 blocks of where the game starts them, never in a doorway, a passage or
  in front of a counter.
- **They face down** and do not turn when spoken to (one picture each,
  not four).
- **They step in place**, in time with the hero, as on the NES. Two
  characters' pictures swap every 16 frames.
- **Comings and goings are kept.** The princess at home, the staff of
  rain's keeper and the Dragonlord appear and disappear as the story
  says.

### The map's colours change beside the battle window

On the NES the battle window is a box over the map, and the map around it
keeps its colours. The 5200 has 5 colours per screen row, and the
monster's rows need their own. So during a battle the screen is split into
bands with display list interrupts: the scene, the monster (two bands for
the biggest) and the dialog. In the monster's band, the map beside the
window shows in the monster's colours. In caves the monster stands on
black, with no scene, as on the NES. The Dragonlord's true form is drawn
on a black screen in four colours, so his oranges come out brown.

### Text

- **Windows are in capitals**: status, command, shop, item and spell
  windows, YES/NO and the credits. Lower case would need character codes
  the towns' graphics use. The hero's name shows in capitals there too.
- **The dialog window keeps the NES's own letters**, lower case included,
  at full width: while it is up, its rows switch to the 5200's
  high-resolution text mode (one colour, white on black), and the rest of
  the screen stays in colour.
- Words wrap as the game wraps them, a number and the period after it
  together.

### Figures

- The hero carrying the princess: her hair is dark red, not brown (four
  colours from three sprites).
- The end credits' two pictures, the publisher's mark and the closing
  banner, are at the map font's half horizontal resolution.

## What the 5200's own hardware adds

Where the 5200 can do something the NES can't, the port uses it, to fit
the game and as touches of its own:

| Hardware | Used for |
|---|---|
| **A display list: a mode per row** | The full-width screen (40 columns, as most 5200 games): the NES's view in the middle and two more map blocks each side. The dialog's high-resolution rows. |
| **Display list interrupts** | The battle's bands, each with its own character set and colours. The title screen's bands, each in its own NES palette. |
| **Colour registers changed on the fly** | Fades between maps, at the inn, and for the credits. Monsters fade in and out in dark places. Screen flashes: a hurtful step (red), the rainbow drop and the MP wizard (grey), the spells and hits as the NES times them. Pause dims the screen. |
| **Character sets in RAM** | Townspeople stepping in place, the overworld's swaying sea, the blinking cursor, a monster building up row by row on the overworld. |
| **Fine scrolling** | The view scrolls a line or a colour clock at a time; hits shake the screen as on the NES. |
| **Players** | The hero's three colours (two players overlapping make the third). The title's dragon, in front of its banner. |
| **POKEY's 16-bit channels and noise** | Exact pitch and a vibrato for the lead voice. Crackling dragon fire; buzzing hits and force fields. The music is mixed a little softer and dips under the effects. |
| **Attract mode** | After about 9 minutes untouched, the screen shifts hue and dims, as 5200 games do, until something is pressed. |
| **SuperCart banking** (512KB) | The program is in every bank and the data in the switched half. Code that rarely runs (title, passwords, credits, story events) runs from a data bank. |

Two touches are the port's own rather than the NES's: the light in dark
places fades into the dark over a block (the NES's edge is hard), and the
lead voice's long notes have a vibrato.

## Known rough edges

- When a dialog closes, its area is black for about three frames before
  the map is drawn back.
- When the status window appears after the hero has stood still, a frame
  runs long and that step takes 17 frames, not 16.
- On a composite connection, the dialog's thin white high-resolution
  strokes may show faint colour fringes.
- The 512KB SuperCart is larger than any cartridge sold for the 5200, so
  the game needs a flash cartridge or an FPGA system.
- Real-hardware testing so far is on a SuperStation One, not yet on an
  original 5200.

## Tests

    sudo apt-get install atari800
    python3 tools/native/test.py path/to/Dragon_Warrior.nes build/tests [NAME...]
    python3 tools/native/measure.py path/to/Dragon_Warrior.nes build/measure

`test.py` runs the controller scripts in `native/scripts` (90 of them) in
atari800, and checks each script's `;EXPECT` lines against the screen and
memory. `measure.py` walks a fixed route and checks every step takes the
NES's 16 frames.

## For developers

Start with [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md): the build
pipeline, the banks and the RAM map, the main loop and its modes, the step
machine, the display interrupts, the tests and the pitfalls. Every
`native/*.asm` and `tools/native/*.py` file opens with a header comment
saying what it holds. [docs/HISTORY.md](docs/HISTORY.md) is the project's
log, oldest first, including the profiling that brought walking to the
NES's pace.

### Tools

- `tools/native/build.py ROM OUTDIR [options]`: convert and assemble a
  cartridge. Test builds take `--script NAME`, `--start MAP,X,Y`,
  `--fight N`, `--level N`, `--seed N` and more (see its docstring).
- `tools/native/convert.py ROM OUTDIR`: only the conversion.
- `tools/native/rom.py`: the ROM reader, and where each table sits in the
  ROM.
- `tools/native/test.py`, `tools/native/measure.py`: the tests. With
  `PROFILE=1`, `test.py` also times the sound work in the VBI.
- `tools/native/profile_sound.py BUILDDIR [FRAMES]`: the sound engine's
  exact CPU cycles a frame, on a 6502 simulator (py65).
- `tools/native/password.py encode|decode`: the passwords in Python, for
  tests and for checking one by hand.
- `tools/run5200.py CART --until ADDR [...]`: run a cartridge headless and
  capture the screen and memory (used by the tests).
- `tools/native/find_addresses.py`: finds a table's address in the
  disassembly, for `rom.py`. The build never runs it.
- `tools/colordata.py`, `tools/monsters.py`, `tools/font4.py`: colour
  plans, monster pictures and the 4-pixel font, used by the converters.
