#!/usr/bin/env python3
"""Measure the native engine's walking speed.

Usage: measure.py ROM OUTDIR

Builds the measurement cartridge (build.py --autopilot: a fixed 46-step
route), runs it in atari800 until it parks, and reads its counters: steps
taken, frames spent walking, frames the main loop missed and steps a wall
refused. Passes if every step took the NES's 16 frames and no frame was
missed.
"""
import os
import re
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
STEPS = 44                      # input_route.asm's route.
NES_FRAMES = 16                 # Frames per step on the NES.


def main():
    if len(sys.argv) != 3:
        sys.exit(__doc__)
    out = sys.argv[2]
    subprocess.run([sys.executable, os.path.join(HERE, "build.py"), *sys.argv[1:], "--autopilot"],
                   check=True)
    cart = os.path.join(out, "dwnative.bin")
    labels = {}
    for line in open(cart + ".map"):
        parts = [p.strip() for p in line.split("|")]
        if len(parts) == 3:
            labels[parts[1]] = int(parts[0].lstrip("$"), 16)
    parked = labels["parked"] + 4          # Its JMP loop, after LDA/STA.
    run = subprocess.run([sys.executable, os.path.join(HERE, "..", "run5200.py"), cart, "--type", "74",
                          "--until", f"{parked:04X}", "--frames", "1000", "--timeout", "120",
                          "--png", os.path.join(out, "measure.png"), "--dump", "0080:24"],
                         capture_output=True, text=True)
    m = re.search(r"^\$0080: ([0-9a-f ]+)$", run.stdout, re.M)
    if run.returncode or not m:
        sys.exit(f"measure: the route did not finish\n{run.stdout}{run.stderr}")
    zp = bytes.fromhex(m.group(1))
    word = lambda a: zp[a - 0x80] | zp[a - 0x7F] << 8
    steps, frames, missed, blocked = word(labels["steps"]), word(labels["walkframes"]), \
        word(labels["missed"]), zp[labels["blocked"] - 0x80]
    print(f"measure: {steps} steps in {frames} frames ({frames / max(steps, 1):.2f} a step, "
          f"NES {NES_FRAMES}), {missed} frames missed, {blocked} steps refused")
    ok = steps == STEPS and frames == STEPS * NES_FRAMES and missed == 0
    print("PASS" if ok else "FAIL")
    sys.exit(0 if ok else 1)


if __name__ == "__main__":
    main()
