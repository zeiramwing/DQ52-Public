#!/usr/bin/env python3
"""A printable keypad overlay for DQ52 on the Atari 5200 controller: an
SVG at true size (millimetres), its artwork the port's own (original pixel
art of a knight and a dragon, rainbow stripes and pixel lettering; no logos
or art of Atari's or the game's).

Every size below is a setting: they are estimates, so measure an overlay
of your own and change them before printing. The printed scale bar is 50
mm long when the printer keeps the true size (print at 100%, no "fit to
page").

Usage: overlay.py [OUT.svg]   (default: overlay.svg beside this file)
"""
import base64
import io
import os
import sys

# The card (mm), and the keypad's 12 windows on it: 3 across, 4 down, the
# first row's top TOP_KEYS from the card's top.
CARD_W, CARD_H = 62.0, 100.0
KEY_W, KEY_H = 11.0, 7.5        # Each key's window.
PITCH_X, PITCH_Y = 17.5, 13.5   # From one key's centre to the next.
TOP_KEYS = 50.0                 # The first row's centre, from the card's top.
CORNER = 3.0                    # The card's corner radius.

# What each key does (the port's KeyCommand): by keypad row.
KEYS = [["1", "TALK"], ["2", "STAIRS"], ["3", "ITEM"],
        ["4", "SPELL"], ["5", "DOOR"], ["6", "TAKE"],
        ["7", "STATUS"], ["8", "SEARCH"], ["9", ""],
        ["*", ""], ["0", ""], ["#", ""]]

# A 3 by 5 pixel font: each glyph 5 rows of 3 bits.
FONT = {
    "A": "010101111101101", "B": "110101110101110", "C": "011100100100011",
    "D": "110101101101110", "E": "111100110100111", "F": "111100110100100",
    "G": "011100101101011", "H": "101101111101101", "I": "111010010010111",
    "J": "001001001101010", "K": "101101110101101", "L": "100100100100111",
    "M": "101111111101101", "N": "110101101101101", "O": "010101101101010",
    "P": "110101110100100", "Q": "010101101110011", "R": "110101110101101",
    "S": "011100010001110", "T": "111010010010010", "U": "101101101101111",
    "V": "101101101101010", "W": "101101111111101", "X": "101101010101101",
    "Y": "101101010010010", "Z": "111001010100111", "0": "111101101101111",
    "1": "010110010010111", "2": "110001010100111", "3": "110001010001110",
    "4": "101101111001001", "5": "111100110001110", "6": "011100111101111",
    "7": "111001010010010", "8": "111101111101111", "9": "111101111001110",
    "*": "000101010101000", "#": "101111101111101", "-": "000000111000000",
    ":": "000010000010000", ".": "000000000000010", " ": "000000000000000",
}

# The picture: original pixel art of the project's own (a knight against a
# fire-breathing dragon, made for it with PixelLab), art.png beside this file,
# 208 by 88 pixels. It is embedded scaled up by whole pixels (ART_SCALE), so a
# printer cannot blur it, and placed ART_W mm wide at ART_X, ART_Y, in a frame.
ART_PNG = "art.png"
ART_X, ART_Y, ART_W = 5.0, 20.2, 52.0
ART_SCALE = 8


def art_image():
    """The picture as an SVG <image>, its pixels kept square and sharp."""
    path = os.path.join(os.path.dirname(os.path.abspath(__file__)), ART_PNG)
    try:
        from PIL import Image          # (To scale it up by whole pixels.)
        im = Image.open(path).convert("RGB")
        w, h = im.size
        buf = io.BytesIO()
        im.resize((w * ART_SCALE, h * ART_SCALE), Image.NEAREST).save(buf, "PNG")
        data = buf.getvalue()
    except ImportError:                # Without Pillow: as it is, kept sharp by
        data = open(path, "rb").read()  # image-rendering.
        w, h = 208, 88
    height = ART_W * h / w
    href = "data:image/png;base64," + base64.b64encode(data).decode()
    return (f'<image x="{ART_X}" y="{ART_Y}" width="{ART_W}" height="{height:.3f}" '
            f'preserveAspectRatio="none" style="image-rendering:pixelated" href="{href}"/>'
            f'<rect x="{ART_X}" y="{ART_Y}" width="{ART_W}" height="{height:.3f}" rx="1.2" fill="none" '
            f'stroke="#f4ecd8" stroke-width="0.6"/>'
            f'<rect x="{ART_X - 0.65}" y="{ART_Y - 0.65}" width="{ART_W + 1.3}" height="{height + 1.3:.3f}" '
            f'rx="1.7" fill="none" stroke="#e8572a" stroke-width="0.4"/>')


STRIPES = ["#f2d43a", "#f2a33a", "#e8572a", "#c8306b", "#7b3fa0"]


def pixels(text, x, y, size, colour):
    """SVG rectangles for TEXT in the pixel font, its top left at X, Y,
    SIZE mm a pixel."""
    out = []
    for i, ch in enumerate(text.upper()):
        bits = FONT.get(ch, FONT[" "])
        for k, b in enumerate(bits):
            if b == "1":
                out.append(f'<rect x="{x + (i * 4 + k % 3) * size:.3f}" y="{y + (k // 3) * size:.3f}" '
                           f'width="{size:.3f}" height="{size:.3f}" fill="{colour}"/>')
    return out


def centred(text, cx, y, size, colour):
    width = (len(text) * 4 - 1) * size
    return pixels(text, cx - width / 2, y, size, colour)


def overlay():
    out = [f'<svg xmlns="http://www.w3.org/2000/svg" width="{CARD_W}mm" height="{CARD_H}mm" '
           f'viewBox="0 0 {CARD_W} {CARD_H}">',
           '<title>DQ52 keypad overlay</title>',
           f'<rect x="0" y="0" width="{CARD_W}" height="{CARD_H}" rx="{CORNER}" fill="#101018"/>']
    # Rainbow stripes across the top, the title under them.
    for i, colour in enumerate(STRIPES):
        out.append(f'<rect x="0" y="{2.6 + i * 1.5:.2f}" width="{CARD_W}" height="1.1" fill="{colour}"/>')
    out += centred("DQ52", CARD_W / 2, 11.0, 0.95, "#ffffff")
    out += centred("ATARI 5200 EDITION", CARD_W / 2, 16.9, 0.38, "#f2d43a")
    # The picture, framed as the boxes' were.
    out.append(art_image())
    # The buttons the overlay does not cover.
    out += centred("START: TITLE  PAUSE: HOLD", CARD_W / 2, 43.6, 0.36, "#c8c8d8")
    # The keys: a window cut-out outline each, its number and command.
    for i, (key, word) in enumerate(KEYS):
        cx = CARD_W / 2 + (i % 3 - 1) * PITCH_X
        cy = TOP_KEYS + (i // 3) * PITCH_Y
        out.append(f'<rect x="{cx - KEY_W / 2:.2f}" y="{cy - KEY_H / 2:.2f}" width="{KEY_W}" height="{KEY_H}" '
                   f'rx="1" fill="#ffffff" stroke="#888" stroke-width="0.2" stroke-dasharray="0.8 0.6"/>')
        out += pixels(key, cx - KEY_W / 2 - 2.6, cy - KEY_H / 2, 0.5, "#f2a33a")
        if word:
            out += centred(word, cx, cy + KEY_H / 2 + 0.9, 0.42, "#ffffff")
    # The scale bar: 50 mm when printed at true size.
    out.append(f'<rect x="{(CARD_W - 50) / 2}" y="{CARD_H - 3.2}" width="50" height="0.5" fill="#7b3fa0"/>')
    out += pixels("50MM", (CARD_W - 50) / 2, CARD_H - 2.4, 0.25, "#7b3fa0")
    out.append('</svg>')
    return "\n".join(out) + "\n"


if __name__ == "__main__":
    path = sys.argv[1] if len(sys.argv) > 1 else os.path.join(os.path.dirname(os.path.abspath(__file__)), "overlay.svg")
    with open(path, "w") as f:
        f.write(overlay())
    print(f"overlay: wrote {path} ({CARD_W} x {CARD_H} mm)")
