#!/usr/bin/env python3
"""Run a 5200 cartridge in atari800 until it parks, then capture its state.

Usage: run5200.py CART --until ADDR [--frames N] [--type N] [--png FILE] [--dump ADDR:LEN]...
                  [--anywhere]

Runs atari800 with its built-in Altirra 5200 BIOS under a private Xvfb
display. ADDR must be a `JMP ADDR` loop the program parks in when done.
After waiting for --frames worth of time, the script screenshots the
emulator window, interrupts into the monitor and checks the PC. If it is at
ADDR (or anywhere, with --anywhere, to see where a run got stuck) it saves
the screenshot, prints each requested memory range as hex, and quits; otherwise it restarts the emulator with a longer wait. Exits
non-zero if the program does not park in time.

The screenshot comes before the interrupt because the emulator closes its
window in the monitor.

Needs atari800, Xvfb and xdotool (apt) and Pillow.
"""
import argparse
import os
import re
import select
import signal
import subprocess
import sys
import time

# A display per run: reusing one can catch the previous X server still exiting.
DISPLAY = f":{100 + os.getpid() % 400}"


def main():
    ap = argparse.ArgumentParser(usage=__doc__)
    ap.add_argument("cart")
    ap.add_argument("--until", required=True, help="address of the final JMP loop (hex)")
    ap.add_argument("--type", default="74", help="atari800 cartridge type (74 = 512KB SuperCart)")
    ap.add_argument("--png")
    ap.add_argument("--dump", action="append", default=[], help="ADDR:LEN in hex")
    ap.add_argument("--frames", type=int, default=0, help="frames the program runs before parking")
    ap.add_argument("--timeout", type=float, default=60)
    ap.add_argument("--anywhere", action="store_true",
                    help="capture after one wait of --frames even if not parked (for debugging)")
    args = ap.parse_args()
    until = int(args.until, 16)

    # One interrupt per emulator run: if the program has not parked by the
    # first check, start again and wait longer.
    wait = 2.0 + args.frames / 60
    deadline = time.time() + args.timeout
    while True:
        result = attempt(args, until, wait)
        if result:
            break
        if time.time() + wait * 1.5 > deadline:
            sys.exit(f"run5200: PC never reached ${until:04X}")
        wait *= 1.5
        print(f"run5200: not parked yet, retrying with {wait:.0f}s")


def attempt(args, until, wait):
    """One emulator run: wait, screenshot, interrupt. False if not parked."""
    xvfb = subprocess.Popen(["Xvfb", DISPLAY, "-screen", "0", "800x600x24", "-nolisten", "tcp", "-noreset"],
                            stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    env = dict(os.environ, DISPLAY=DISPLAY, SDL_AUDIODRIVER="dummy")
    emu = None
    try:
        wait_for_display(env)
        emu = subprocess.Popen(
            ["atari800", "-5200", "-5200-rev", "altirra", "-ntsc",
             "-cart", args.cart, "-cart-type", args.type, "-nosound"],
            stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, env=env)
        time.sleep(wait)
        shot = grab_window() if args.png else None
        emu.send_signal(signal.SIGINT)
        out = read_until(emu, "PC=", 5) or ""
        pcs = re.findall(r"PC=([0-9A-F]{4})", out)
        if not pcs:
            return False
        if int(pcs[-1], 16) != until:
            if not args.anywhere:
                return False
            print(f"run5200: not parked, stopped at ${pcs[-1]}")
        else:
            print(f"run5200: parked at ${until:04X}")
        print("run5200: " + [l for l in out.splitlines() if "PC=" in l][-1].strip())

        if args.png:
            if shot is None:
                sys.exit("run5200: emulator window not found")
            shot.save(args.png)
            print(f"run5200: screen saved to {args.png}")

        for spec in args.dump:
            addr, length = (int(x, 16) for x in spec.split(":"))
            print(f"${addr:04X}: {dump(emu, addr, length).hex(' ')}")
        send(emu, "QUIT")
        return True
    finally:
        if emu:
            emu.kill()
            emu.wait()
        xvfb.terminate()
        xvfb.wait()


def wait_for_display(env):
    """Wait until the X server accepts connections."""
    for _ in range(50):
        if subprocess.run(["xdotool", "getdisplaygeometry"], env=env,
                          capture_output=True).returncode == 0:
            return
        time.sleep(0.1)
    sys.exit(f"run5200: X server {DISPLAY} did not start")


def send(emu, line):
    emu.stdin.write((line + "\n").encode())
    emu.stdin.flush()


def read_until(emu, marker, timeout):
    """Read emulator output until MARKER appears; None on timeout."""
    buf = b""
    end = time.time() + timeout
    while time.time() < end:
        ready, _, _ = select.select([emu.stdout], [], [], 0.2)
        if ready:
            chunk = os.read(emu.stdout.fileno(), 65536)
            if not chunk:
                return None
            buf += chunk
            if marker.encode() in buf:
                return buf.decode("latin-1")
    return None


def dump(emu, addr, length):
    """Read LENGTH bytes at ADDR through the monitor's memory command."""
    data = bytearray()
    while len(data) < length:
        here = (addr + len(data)) & 0xFFFF
        send(emu, f"m {here:04X}")
        out = read_until(emu, f"{(here + 0xF0) & 0xFFFF:04X}:", 5) or ""
        for line in out.splitlines():
            m = re.match(r"^([0-9A-F]{4}): ((?:[0-9A-F]{2} ){16})", line)
            if m and int(m.group(1), 16) == (addr + len(data)) & 0xFFFF:
                data += bytes.fromhex(m.group(2))
    return bytes(data[:length])


def grab_window():
    """Screenshot the emulator window, or None if it is not open."""
    from PIL import ImageGrab
    env = dict(os.environ, DISPLAY=DISPLAY)
    wins = subprocess.run(["xdotool", "search", "--name", "Atari 800"], env=env,
                          capture_output=True, text=True).stdout.split()
    if not wins:
        return None
    geo = subprocess.run(["xdotool", "getwindowgeometry", "--shell", wins[0]], env=env,
                         capture_output=True, text=True).stdout
    g = dict(line.split("=") for line in geo.split())
    x, y, w, h = (int(g[k]) for k in ("X", "Y", "WIDTH", "HEIGHT"))
    return ImageGrab.grab(bbox=(x, y, x + w, y + h), xdisplay=DISPLAY)


if __name__ == "__main__":
    main()
