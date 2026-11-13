#!/usr/bin/env python3
"""A printable keypad overlay for DQ52 on the Atari 5200 controller: an
SVG at true size (millimetres), its artwork the port's own (an original
painted scene in the manner of the era's box art, rainbow stripes and pixel
lettering; no logos or art of Atari's or the game's).

Every size below is a setting: they are estimates, so measure an overlay
of your own and change them before printing. The printed scale bar is 50
mm long when the printer keeps the true size (print at 100%, no "fit to
page").

Usage: overlay.py [OUT.svg]   (default: overlay.svg beside this file)
"""
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

# The picture: an original painting in the manner of the era's box art
# (airbrushed sky, glowing fire, figures rim-lit against the dusk): a knight
# on a crag, shield raised against a rearing dragon's fire, a castle on the
# heights behind. On a 208 by 88 canvas, scaled into the card (ART_* mm).
ART_X, ART_Y, ART_W = 5.0, 20.2, 52.0
RIM = 'stroke="#ffb347" stroke-width="0.7" stroke-linejoin="round"'


def limb(d, colour, width=4.0, rim="#ffb347"):
    """An arm, leg or neck as one thick stroke, a thin line of firelight on it."""
    return (f'<path d="{d}" fill="none" stroke="{colour}" stroke-width="{width}" stroke-linecap="round"/>'
            f'<path d="{d}" fill="none" stroke="{rim}" stroke-width="{width * 0.18:.2f}" stroke-linecap="round" '
            f'opacity="0.8" transform="translate(-{width * 0.3:.2f} -{width * 0.1:.2f})"/>')


def sparkle(x, y, s, colour="#ffffff"):
    """A four-pointed glint."""
    t = s * 0.13
    return (f'<path d="M{x - s} {y} L{x - t} {y - t} L{x} {y - s} L{x + t} {y - t} L{x + s} {y} L{x + t} {y + t} '
            f'L{x} {y + s} L{x - t} {y + t} Z" fill="{colour}"/>'
            f'<circle cx="{x}" cy="{y}" r="{s * 0.8}" fill="{colour}" opacity="0.4" filter="url(#glow)"/>')


DRAGON_ART = f"""
<defs>
  <clipPath id="frame"><rect x="0" y="0" width="208" height="88" rx="5"/></clipPath>
  <filter id="glow" x="-100%" y="-100%" width="300%" height="300%"><feGaussianBlur stdDeviation="2.2"/></filter>
  <filter id="soft" x="-50%" y="-50%" width="200%" height="200%"><feGaussianBlur stdDeviation="6"/></filter>
  <filter id="haze" x="-10%" y="-10%" width="120%" height="120%"><feGaussianBlur stdDeviation="0.8"/></filter>
  <filter id="grain" x="0" y="0" width="100%" height="100%">
    <feTurbulence type="fractalNoise" baseFrequency="1.0" numOctaves="2" seed="3"/>
    <feColorMatrix values="0 0 0 0 1  0 0 0 0 0.9  0 0 0 0 0.8  0 0 0 0.5 -0.2"/></filter>
  <linearGradient id="sky" x1="0" y1="0" x2="0" y2="1">
    <stop offset="0" stop-color="#140a2e"/><stop offset="0.35" stop-color="#4a1850"/>
    <stop offset="0.62" stop-color="#b8324a"/><stop offset="0.82" stop-color="#f2833a"/>
    <stop offset="1" stop-color="#ffd27a"/></linearGradient>
  <radialGradient id="moon" cx="0.4" cy="0.35" r="0.65">
    <stop offset="0" stop-color="#fffbe8"/><stop offset="0.75" stop-color="#ffe2a8"/>
    <stop offset="1" stop-color="#f2b07a"/></radialGradient>
  <linearGradient id="hills" x1="0" y1="0" x2="0" y2="1">
    <stop offset="0" stop-color="#5a1e48"/><stop offset="1" stop-color="#2a0f2e"/></linearGradient>
  <linearGradient id="crag" x1="0" y1="0" x2="1" y2="1">
    <stop offset="0" stop-color="#6a3a3a"/><stop offset="0.5" stop-color="#2a1420"/>
    <stop offset="1" stop-color="#0c0610"/></linearGradient>
  <linearGradient id="scales" x1="0" y1="0" x2="1" y2="0.6">
    <stop offset="0" stop-color="#7fd08a"/><stop offset="0.3" stop-color="#2a8a5a"/>
    <stop offset="0.75" stop-color="#0f4038"/><stop offset="1" stop-color="#071c1e"/></linearGradient>
  <linearGradient id="plates" x1="0" y1="0" x2="1" y2="0">
    <stop offset="0" stop-color="#ffe9a0"/><stop offset="1" stop-color="#b8782e"/></linearGradient>
  <linearGradient id="web" x1="0" y1="0" x2="1" y2="1">
    <stop offset="0" stop-color="#ff9a6a" stop-opacity="0.95"/><stop offset="0.5" stop-color="#a02a48"/>
    <stop offset="1" stop-color="#3a0c28"/></linearGradient>
  <linearGradient id="fire" x1="1" y1="0" x2="0" y2="1">
    <stop offset="0" stop-color="#fffbd8"/><stop offset="0.35" stop-color="#ffd23a"/>
    <stop offset="0.75" stop-color="#ff6a1a"/><stop offset="1" stop-color="#c81e14" stop-opacity="0.7"/></linearGradient>
  <linearGradient id="steel" x1="0" y1="0" x2="1" y2="1">
    <stop offset="0" stop-color="#ffffff"/><stop offset="0.45" stop-color="#9aa6b8"/>
    <stop offset="1" stop-color="#2a3040"/></linearGradient>
  <linearGradient id="armour" x1="1" y1="0" x2="0" y2="0">
    <stop offset="0" stop-color="#ffd8a0"/><stop offset="0.35" stop-color="#8a90a8"/>
    <stop offset="1" stop-color="#262a3c"/></linearGradient>
  <linearGradient id="cape" x1="1" y1="0" x2="0" y2="1">
    <stop offset="0" stop-color="#ff5a3a"/><stop offset="0.5" stop-color="#a0142a"/>
    <stop offset="1" stop-color="#3a0618"/></linearGradient>
  <radialGradient id="shield" cx="0.7" cy="0.3" r="0.9">
    <stop offset="0" stop-color="#7ab0ff"/><stop offset="0.6" stop-color="#2a4fa8"/>
    <stop offset="1" stop-color="#101c48"/></radialGradient>
</defs>
<g clip-path="url(#frame)">
  <rect x="0" y="0" width="208" height="88" fill="url(#sky)"/>
  <ellipse cx="70" cy="40" rx="60" ry="18" fill="#ff7a3a" opacity="0.35" filter="url(#soft)"/>
  <circle cx="118" cy="22" r="20" fill="#ffe2a8" opacity="0.35" filter="url(#soft)"/>
  <circle cx="118" cy="22" r="14" fill="url(#moon)"/>
  <g fill="#e89a6a" opacity="0.35"><ellipse cx="114" cy="18" rx="3" ry="2"/><ellipse cx="123" cy="26" rx="2.4" ry="1.6"/>
     <ellipse cx="111" cy="27" rx="1.6" ry="1.1"/></g>
  <g fill="#ffd8a8" opacity="0.5"><rect x="0" y="48" width="208" height="0.9"/><rect x="20" y="54" width="170" height="0.6"/></g>
  <g fill="#ffffff"><circle cx="16" cy="8" r="0.5"/><circle cx="42" cy="5" r="0.35"/><circle cx="66" cy="12" r="0.4"/>
     <circle cx="88" cy="4" r="0.5"/><circle cx="150" cy="6" r="0.35"/><circle cx="196" cy="12" r="0.45"/>
     <circle cx="8" cy="22" r="0.35"/><circle cx="58" cy="24" r="0.3"/></g>

  <path d="M-2 66 L18 52 L30 58 L46 48 L64 60 L84 54 L104 62 L130 52 L150 60 L170 50 L190 56 L210 50 L210 92 L-2 92 Z"
        fill="url(#hills)" filter="url(#haze)"/>
  <g fill="#1c0a22">
    <path d="M-2 60 L-2 40 L4 36 L8 42 L12 34 L16 40 L20 46 L22 60 Z"/>
    <rect x="5" y="25" width="5" height="14"/><path d="M4 25 L7.5 18 L11 25 Z"/>
    <rect x="13" y="31" width="4" height="10"/><path d="M12 31 L15 25 L18 31 Z"/>
    <path d="M7.5 18 L7.5 14 L11.5 15.4 L7.5 16.6" stroke="#1c0a22" stroke-width="0.4"/></g>
  <g fill="#ffcf6a"><rect x="6.8" y="28" width="1.2" height="1.8"/><rect x="14.4" y="34" width="1" height="1.6"/>
     <rect x="1.5" y="44" width="1.2" height="1.6"/></g>
  <path d="M-2 92 L-2 80 Q40 72 90 76 Q140 72 210 78 L210 92 Z" fill="#1a0a16"/>

  <path d="M164 80 C182 88 202 82 204 68 C205 58 196 54 192 60 C198 62 198 72 188 74 C180 76 172 72 164 70 Z"
        fill="url(#scales)"/>
  <path d="M192 60 L190 52 L197 56 Z" fill="#0f4038"/>
  {limb("M160 66 C164 72 162 78 158 82", "#134a3e", 8)}
  <path d="M150 83 L154 80 L160 80 L166 83 Z" fill="#0f2a28"/>
  <path d="M151 83 L149 85 M156 83 L155 86 M162 83 L163 86" stroke="#f4e6c0" stroke-width="0.8"/>
  <path d="M124 42 C122 32 132 28 140 32 C152 38 164 52 164 66 C164 76 156 81 148 80 C138 78 128 60 124 42 Z"
        fill="url(#scales)" {RIM}/>
  <path d="M128 44 C130 56 136 68 146 76 C140 76 132 66 128 54 Z" fill="url(#plates)" opacity="0.9"/>
  <path d="M128 48 L134 46 M129 54 L136 52 M131 60 L138 58 M134 66 L141 64 M139 72 L145 70" stroke="#8a5420"
        stroke-width="0.7"/>
  {limb("M146 66 C142 72 140 78 136 82", "#1a5a48", 7)}
  <path d="M128 83 L132 80 L139 80 L144 83 Z" fill="#0f2a28"/>
  <path d="M129 83 L127 85 M134 83 L133 86 M140 83 L141 86" stroke="#f4e6c0" stroke-width="0.8"/>

  <path d="M134 42 L148 16 L160 4 L188 0 Q182 9 194 12 L200 16 Q190 22 201 29 L204 36 Q190 34 186 44
           Q176 40 168 50 Q156 44 146 50 Z" fill="url(#web)"/>
  <path d="M160 4 L194 12 M160 4 L201 29 M160 4 L186 44 M154 12 L168 50" fill="none" stroke="#4a0e2a"
        stroke-width="1"/>
  <path d="M134 42 L148 16 L160 4 L188 0" fill="none" stroke="#2a8a5a" stroke-width="2.4"
        stroke-linejoin="round" stroke-linecap="round"/>
  <path d="M188 0 L192 -2 L190 2 Z M160 4 L158 0 L163 2 Z" fill="#f4e6c0"/>
  {limb("M132 38 C122 30 118 20 112 16 C106 13 100 16 98 22", "#2a8a5a", 7.5)}
  <path d="M106 16 C110 12 116 12 118 16" fill="none" stroke="#7fd08a" stroke-width="1" opacity="0.7"/>
  <path d="M120 22 L124 19 L123 24 Z M124 28 L129 26 L127 31 Z M116 15 L119 11 L120 16 Z" fill="#ff9a6a"/>
  <path d="M104 18 C100 14 92 16 86 22 L80 26 L86 27 L82 31 C88 32 96 30 100 28 C104 26 106 22 104 18 Z"
        fill="url(#scales)" {RIM}/>
  <path d="M82 31 L80 36 C86 36 94 32 98 28 Z" fill="#0f4038" {RIM}/>
  <path d="M81 27 L82 29 L84 27.4 Z M84 31 L85 33 L86.6 31 Z" fill="#fffbe8"/>
  <path d="M102 16 L110 8 L106 17 Z M100 15 L104 6 L103 15 Z" fill="#f4e6c0"/>
  <circle cx="94" cy="21" r="1.3" fill="#fff27a"/><circle cx="94" cy="21" r="3" fill="#fff27a" opacity="0.5"
        filter="url(#glow)"/>
  {limb("M130 48 C122 50 116 50 112 46", "#1a5a48", 4.5)}
  <path d="M112 46 L108 43 M112 46 L107 46.5 M112 46 L109 49" stroke="#f4e6c0" stroke-width="0.9"
        stroke-linecap="round"/>

  <path d="M82 30 C72 32 64 38 58 46 C56 50 58 54 62 54 C66 52 70 50 72 46 C76 40 80 36 84 33 Z"
        fill="#ff5a1a" opacity="0.65" filter="url(#glow)"/>
  <path d="M83 29 C70 31 62 38 56 44 C52 48 54 56 60 56 C64 55 66 50 70 46 C74 40 79 36 84 33 Z"
        fill="url(#fire)"/>
  <path d="M82 31 C74 33 68 38 64 44 C62 47 63 50 66 50 C69 47 72 41 83 32 Z" fill="#fffbd8"/>
  <circle cx="58" cy="50" r="12" fill="#ffb347" opacity="0.4" filter="url(#soft)"/>

  <path d="M-2 92 L-2 72 Q8 64 22 66 L40 62 Q54 64 62 72 L70 80 L74 92 Z" fill="url(#crag)"/>
  <path d="M22 66 L40 62 Q54 64 62 72" fill="none" stroke="#ff9a5a" stroke-width="0.8" opacity="0.8"/>
  <path d="M30 46 C22 50 12 56 6 62 C12 62 16 60 18 64 C22 60 26 60 30 58 Z" fill="url(#cape)"/>
  {limb("M34 56 C30 60 26 63 24 66", "#3a3e54", 4)}
  {limb("M38 56 C43 58 46 61 48 64", "#4a4e66", 4)}
  <path d="M20 67 L27 65 L28 67.5 L20 68.5 Z M45 65.5 L52 64 L52 66.6 L45 67 Z" fill="#14161e"/>
  <path d="M31 44 C34 42 40 42 42 45 L41 56 C38 58 33 58 31 56 Z" fill="url(#armour)" {RIM}/>
  <path d="M30 56 L43 56 L42 59 L31 59 Z" fill="#5a2a1a"/>
  {limb("M33 45 C30 40 28 36 27 32", "#4a4e66", 3.4)}
  <path d="M24.5 33 L30.5 32.6" stroke="#d8a03a" stroke-width="1.6" stroke-linecap="round"/>
  <path d="M27 32 L22 8 L24.4 7.6 L28.6 31.8 Z" fill="url(#steel)"/>
  <path d="M27 31 L23.4 9" stroke="#ffffff" stroke-width="0.4" opacity="0.9"/>
  {sparkle(23.2, 8, 3.6, "#fffbe8")}
  <path d="M34 38 C34 34 40 33 41 37 L41 42 C39 44 35 44 34 42 Z" fill="url(#armour)" {RIM}/>
  <path d="M37 39 L41.5 39" stroke="#0c0610" stroke-width="0.9"/>
  <path d="M35 34.5 C33 30 36 27 40 28 C37 29 37 32 38 34 Z" fill="#ff5a3a"/>
  {limb("M40 47 C44 48 46 47 48 46", "#4a4e66", 3.4)}
  <path d="M44 38 L56 37 C57 46 54 54 50 58 C46 54 43 46 44 38 Z" fill="url(#shield)" stroke="#ffb347" stroke-width="1"/>
  <path d="M50 39 L50 55 M45.5 44 L55 43.4" stroke="#f2d43a" stroke-width="1.6"/>
  <path d="M44 38 L56 37" stroke="#fff4c0" stroke-width="0.8"/>
  {sparkle(55, 40, 2.6, "#fff4c0")}
  <rect x="0" y="0" width="208" height="88" filter="url(#grain)" opacity="0.18"/>
</g>
<rect x="0" y="0" width="208" height="88" rx="5" fill="none" stroke="#f4ecd8" stroke-width="2.4"/>
<rect x="-2.6" y="-2.6" width="213.2" height="93.2" rx="7" fill="none" stroke="#e8572a" stroke-width="1.6"/>
"""


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
    out.append(f'<g transform="translate({ART_X} {ART_Y}) scale({ART_W / 208})">{DRAGON_ART}</g>')
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
