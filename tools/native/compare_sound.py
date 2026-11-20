#!/usr/bin/env python3
"""Compare the port's sound with the NES's, channel by channel: run a built
cartridge's sound engine on a 6502 simulator (as profile_sound.py does),
read what it writes to POKEY each frame, and set it against what the NES's
sound hardware would play from the same state (the engine keeps the game's
channels as the NES has them: ChNote, ChVol, ChCtl).

For each channel, over the frames it sounds: how far POKEY's pitch is from
the NES's (cents: the mean, the worst, and how many frames are more than
an octave's quarter off, an octave raised), and its average loudness, the
NES's (its mixer's levels, by the pulse's duty) beside POKEY's (AUDC's
volume, a pure tone's), so the balance between the channels can be
compared.

Usage: compare_sound.py ROM BUILDDIR [FRAMES]   (FRAMES of each music: 3600)

BUILDDIR: a build.py output directory (its dwnative.bin and .map).
"""
import math
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
import convert                                  # noqa: E402
import sound                                    # noqa: E402
from profile_sound import Machine, MUSIC, SFX, SFX_BASE, SFX_FRAMES, OVERWORLD   # noqa: E402

NES_CPU = 1789773
POKEY = 0xE800
CLOCK_64K, CLOCK_15K, CLOCK_FAST = 63921, 15700, 1789790
# The NES's mixer: a pulse at volume v (its wave's RMS by duty), the triangle
# at full swing; the noise at volume v.
DUTY_RMS = [math.sqrt(d * (1 - d)) for d in (0.125, 0.25, 0.5, 0.75)]


def pulse_level(v, duty):
    return 0 if v == 0 else 95.88 / (8128 / v + 100) * DUTY_RMS[duty]


TRI_LEVEL = 159.79 / (8227 / 15 + 100) / (2 * math.sqrt(3))


def cents(a, b):
    return 1200 * math.log2(a / b)


class Stats:
    def __init__(self):
        self.err, self.worst, self.off, self.frames = 0.0, 0.0, 0, 0
        self.nes, self.pokey = 0.0, 0.0

    def add(self, f_pokey, f_nes, nes_level, pokey_vol):
        e = abs(cents(f_pokey, f_nes))
        self.frames += 1
        self.err += min(e, 1200)
        self.worst = max(self.worst, e)
        self.off += e > 300
        self.nes += nes_level
        self.pokey += pokey_vol / 2          # A pure tone's RMS, in AUDC's steps.

    def line(self, name):
        if not self.frames:
            return f"{name}: silent"
        return (f"{name}: {self.frames:6d} frames, pitch off {self.err / self.frames:5.1f}c on average, "
                f"worst {self.worst:6.1f}c, {self.off} frames an octave or more off; "
                f"loudness NES {1000 * self.nes / self.frames:5.1f}, POKEY {self.pokey / self.frames:4.2f}")


def main():
    if len(sys.argv) not in (3, 4):
        sys.exit(__doc__)
    rom = convert.romdata.Rom(sys.argv[1])
    frames = int(sys.argv[3]) if len(sys.argv) == 4 else 3600
    m = Machine(sys.argv[2])
    timers = sound.note_timers(rom)
    L = m.labels
    ram = m.ram
    stats = {k: Stats() for k in ("sq1", "sq2", "tri", "sfx")}
    pieces = [(n, None, frames) for n in range(MUSIC)]
    pieces += [(OVERWORLD, SFX_BASE + n, SFX_FRAMES) for n in range(SFX)]
    for music, sfx, count in pieces:
        m.call("initsound")
        ram[L["curbank"]] = 15
        m.call("playmusic", music)
        if sfx is not None:
            m.call("playsfx", sfx)
        for _ in range(count):
            m.call("updatesound")
            reg = ram[POKEY:POKEY + 9]
            note, vol, ctl = (ram[L["chnote"]:L["chnote"] + 4], ram[L["chvol"]:L["chvol"] + 4],
                              ram[L["chctl"]:L["chctl"] + 4])
            slow = reg[8] & 0x01
            clock = CLOCK_15K if slow else CLOCK_64K
            sfx_on = ram[L["sfxactive"]]
            if vol[0]:
                f = CLOCK_FAST / 2 / (reg[2] * 256 + reg[0] + 7)
                stats["sq1"].add(f, NES_CPU / 16 / (timers[note[0]] + 1), pulse_level(vol[0], ctl[0] >> 6), reg[3] & 15)
            if vol[1] and not vol[3]:
                f = clock / 2 / (reg[4] + 1)
                if sfx is None:
                    stats["sq2"].add(f, NES_CPU / 16 / (timers[note[1]] + 1), pulse_level(vol[1], ctl[1] >> 6), reg[5] & 15)
                elif sfx_on and not ram[L["sweepcfg"]] & 0x80 if "sweepcfg" in L else sfx_on:   # (A sweep's is checked apart.)
                    stats["sfx"].add(f, NES_CPU / 16 / (timers[note[1]] + 1), pulse_level(vol[1], ctl[1] >> 6), reg[5] & 15)
            if vol[2] and sfx is None:
                f = clock / 2 / (reg[6] + 1)
                stats["tri"].add(f, NES_CPU / 32 / (timers[note[2]] + 1), TRI_LEVEL, reg[7] & 15)
    for k in ("sq1", "sq2", "tri", "sfx"):
        print(stats[k].line(k))


if __name__ == "__main__":
    main()
