#!/usr/bin/env python3
"""Profile the sound engine: run a built cartridge's UpdateSound on a 6502
simulator (py65: pip install py65), every music for a while and every
sound effect over the overworld's, and print the CPU cycles a frame it
takes (average and worst, each piece and in all), exactly, without the
display's DMA or the interrupts a real frame has.

Usage: profile_sound.py BUILDDIR [FRAMES]    (FRAMES of each music: 3600, a minute)

BUILDDIR: a build.py output directory (its dwnative.bin and .map).
"""
import statistics
import sys

from py65.devices.mpu6502 import MPU
from py65.memory import ObservableMemory

MUSIC, SFX, SFX_BASE, SFX_FRAMES = 27, 22, 0x80, 300
OVERWORLD = 5


class Machine:
    """The cartridge's program, its SuperCart banks switched as the 5200's
    are (a read of $BFC0-$BFDF), and RAM."""

    def __init__(self, build):
        self.cart = open(f"{build}/dwnative.bin", "rb").read()
        self.labels = {}
        for line in open(f"{build}/dwnative.bin.map"):
            parts = [p.strip() for p in line.split("|")]
            if len(parts) == 3:
                self.labels[parts[1]] = int(parts[0].lstrip("$"), 16)
        self.mem = ObservableMemory()
        self.ram = self.mem._subject
        self.ram[0x4000:0x8000] = self.cart[0:0x4000]      # The program: each bank's first half.
        self.bank = [0, 0]
        self.select()
        self.mem.subscribe_to_read(range(0xBFC0, 0xBFD0), self.upper)
        self.mem.subscribe_to_read(range(0xBFD0, 0xBFE0), self.lower)
        self.mpu = MPU(memory=self.mem)

    def upper(self, addr):
        self.bank[0] = addr & 0x0C
        self.select()
        return 0xFF

    def lower(self, addr):
        self.bank[1] = (addr & 0x0C) >> 2
        self.select()
        return 0xFF

    def select(self):
        b = (self.bank[0] | self.bank[1]) * 0x8000
        self.ram[0x8000:0xBFC0] = self.cart[b + 0x4000:b + 0x7FC0]

    def call(self, name, a=0):
        """Run routine NAME (A given): its cycles."""
        target = self.labels[name]
        self.ram[0x600:0x604] = [0x20, target & 0xFF, target >> 8, 0xEA]
        self.mpu.pc, self.mpu.a, self.mpu.sp = 0x600, a, 0xFF
        start = self.mpu.processorCycles
        while self.mpu.pc != 0x603:
            self.mpu.step()
        return self.mpu.processorCycles - start - 12      # Less the JSR here and the RTS.


def main():
    if len(sys.argv) not in (2, 3):
        sys.exit(__doc__)
    frames = int(sys.argv[2]) if len(sys.argv) == 3 else 3600
    m = Machine(sys.argv[1])
    pieces = [("music", n, n, None, frames) for n in range(MUSIC)]
    pieces += [("effect", n, OVERWORLD, SFX_BASE + n, SFX_FRAMES) for n in range(SFX)]
    every = []
    for kind, n, music, sfx, count in pieces:
        m.call("initsound")
        m.ram[m.labels["curbank"]] = 15
        m.call("playmusic", music)
        if sfx is not None:
            m.call("playsfx", sfx)
        cycles = [m.call("updatesound") for _ in range(count)]
        every += cycles
        print(f"{kind} {n:2d}: {statistics.mean(cycles):5.0f} cycles a frame on average, worst {max(cycles)}")
    print(f"all: {statistics.mean(every):.0f} cycles a frame on average, worst {max(every)}")


if __name__ == "__main__":
    main()
