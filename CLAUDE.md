# DQ52: working notes for Claude

The native Atari 5200 engine for NES Dragon Warrior. It's in the bug-hunt
phase: the features are done, and the owner tests on a SuperStation One
(FPGA 5200) on a CRT. Read README.md and docs/ARCHITECTURE.md (the RAM
map, the banks, the character sets) before touching code.

## Hard rules

- Never commit ROMs, game data, built cartridges or screenshots of game
  art. `build/` and `vendor/` are gitignored; keep it so.
- Never reproduce the game's text or music in chat, code, comments,
  commits or docs. Paraphrase.
- Built cartridges contain data taken from the ROM: send them only to the
  owner, never anywhere public.
- Overlay and other artwork must be original: no Atari, game or other
  imagery or logos.
- No model names or IDs in code, comments or commits.
- Commit and push straight to `main` in zeiramwing/DQ52. Make no PRs
  unless asked. End commit messages with the session's Co-Authored-By /
  Claude-Session lines here; the public repo's sync commits carry the
  Co-Authored-By line only, no Claude-Session link (the owner's choice).
- Don't tag a 1.0 until the owner has finished real-hardware testing.
- Don't reorganise the banks unless a fix needs it.

## Setup in a fresh container

- `pip install ophis-asm` (the assembler) and `apt-get install atari800`
  (the emulator used by the tests).
- The reference disassembly goes in
  `vendor/dragon-warrior-disassembly` (github.com/nmikstas/dragon-warrior-disassembly).
  It's only the reference for how the game works; the build reads the
  ROM itself.
- The ROM is not in the repo. Ask the owner for it (USA release, rev0 or
  rev1) and keep it at `build/dragon_warrior.nes`.

## Build and test

    ./build.sh build/dragon_warrior.nes          # -> build/dwnative.bin (SuperCart, cart type 74)
    python3 tools/native/test.py build/dragon_warrior.nes build/tests [NAME...]
    python3 tools/native/measure.py build/dragon_warrior.nes build/measure

- `test.py` runs the controller scripts in `native/scripts` (95 of them)
  and checks each script's `;EXPECT` lines against the screen and memory.
  The whole suite must pass before you push a code change. Walking must
  stay at the NES's 16 frames a step (`measure.py`).
- For a new bug, write a script that reproduces it first, then fix it.
- The full suite takes a while. Run it in a git worktree, so edits made
  while it runs don't change the code under it.
- `PROFILE=1` times the VBI's sound work; `tools/native/profile_sound.py`
  counts the sound engine's cycles exactly.

## Pitfalls that have bitten before

- RAM clashes: check docs/ARCHITECTURE.md's map before taking any byte,
  and grep for every user of an address.
- Ophis anonymous labels (`*`, `-`, `+`) are easy to mis-target. Use
  named labels in anything non-trivial.
- The program at $4000-$7FFF repeats in every bank. Code at $8000+ is
  per bank; call across banks with FarOut.
- The VBI writes what ANTIC reads from the frame's first line first
  (scroll, VDSLST, colors, SetAddresses), before line 16. Probe VCOUNT
  if you add work there: late writes glitch on real hardware only.
- Free program space is tight (about 25 bytes). Check the build's report.
- Edit `tools/native/convert.py` with care: confirm a whole edit applied,
  because half-applied edits have broken it before.

## Docs and the public repo

- When behaviour changes, update README.md (what the port does, kept
  current: no log there), docs/HISTORY.md (the log, oldest first; mark
  replaced entries with *Now:*) and docs/ARCHITECTURE.md.
- The browser builder (`web/`, published by `.github/workflows/pages.yml`
  from the public repo only) runs build.py under Pyodide. Keep build.py
  free of anything Pyodide lacks (no subprocess but the ophis fallback in
  `assemble`, no native modules), and check it after build changes:
  `web/make_site.py` a site, serve it, build in Chromium, and compare the
  cartridge with `build.sh`'s (pass `?pyodide=` a local Pyodide when the
  CDN is out of reach).
- The public copy is zeiramwing/DQ52-Public. It holds no history: sync it
  only when the owner asks. First check every change since the last sync
  for game text, then copy `git archive HEAD` over its tree and commit
  once.
