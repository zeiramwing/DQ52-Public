;Test script: as rainbowman, with Erdrick's token only: the old man says
;what the bridge wants, and the hero keeps the token and stays.
;Entries: frames, directions (1 up, 2 right, 4 down, 8 left), buttons
;(1 lower fire, 2 upper).
;START: 10,3,5
;FIGHT: 254
;ITEM: 7
;EXPECT-BYTE: Inventory 7
;EXPECT-BYTE: Mode 0
;EXPECT-BYTE: MapId 10

Script:
        .byte 20, 0, 0
        .byte 4, 2, 0
        .byte 30, 0, 0
        .byte 5, 0, 1
        .byte 10, 0, 0
        .byte 5, 0, 1
        .byte 120, 0, 0
        .byte 5, 0, 1
        .byte 120, 0, 0
        .byte 5, 0, 1
        .byte 120, 0, 0
        .byte 5, 0, 1
        .byte 120, 0, 0
        .byte 5, 0, 1
        .byte 120, 0, 0
        .byte 5, 0, 1
        .byte 120, 0, 0
        .byte 5, 0, 1
        .byte 60, 0, 0
        .byte 0
