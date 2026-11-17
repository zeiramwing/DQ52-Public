# Keypad overlay

A printable overlay for the 5200 controller's keypad, naming the keys the
port gives commands to (1 TALK, 2 STAIRS, 3 ITEM, 4 SPELL, 5 DOOR, 6 TAKE,
7 STATUS, 8 SEARCH), with Start and Pause noted above them. Its artwork is
the project's own: original pixel art made for it with PixelLab (a knight
on a crag, sword raised against a green dragon's fire, a castle under a
full moon at dusk, in a frame; `art.png`, 208 by 88 pixels), rainbow
stripes and pixel lettering, and no logos or art of Atari's or the
game's. `overlay.py` embeds the picture scaled up by whole pixels, so it
prints sharp.

`overlay.svg` is at true size, in millimetres. Print it at 100% (no "fit to
page") on card stock, check that the scale bar at its foot measures 50 mm,
cut round the card, and cut out the twelve dashed windows over the keys.

The sizes are estimates. Measure one of your own overlays (the card, a
key window, the distance between key centres, and how far the first row
is from the top), set them at the top of `overlay.py`, and run
`python3 overlay.py` to write a new `overlay.svg`.
