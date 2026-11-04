#!/usr/bin/env bash
# Build the Atari 5200 Dragon Warrior cartridge from your own ROM.
#
# Usage: ./build.sh path/to/Dragon_Warrior.nes
#
# Reads the game's data from the ROM (it must be the USA release, rev0 or
# rev1: tools/native/rom.py checks), converts it into the native engine's
# formats, and assembles the engine into build/dwnative.bin: a 512KB
# SuperCart (atari800 cartridge type 74).
#
# Needs python3 and the Ophis assembler on PATH (pip install ophis-asm).
set -euo pipefail

ROOT=$(cd "$(dirname "$0")" && pwd)
BUILD=$ROOT/build

if [ $# -ne 1 ]; then
    echo "usage: $0 ROM.nes" >&2
    exit 2
fi
command -v ophis >/dev/null || { echo "ophis not found (pip install ophis-asm)" >&2; exit 1; }

python3 "$ROOT/tools/native/build.py" "$1" "$BUILD/native"
cp "$BUILD/native/dwnative.bin" "$BUILD/dwnative.bin"
echo "== $BUILD/dwnative.bin (atari800 -cart-type 74 -cart $BUILD/dwnative.bin)"
