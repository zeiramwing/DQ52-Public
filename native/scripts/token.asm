;Test script: on the overworld at (83,113), where Erdrick's token lies:
;SEARCH (down three in the command window): the token found; SEARCH again:
;nothing more (one token, kept).
;Entries: frames, directions (1 up, 2 right, 4 down, 8 left), buttons
;(1 lower fire, 2 upper).
;START: 0,83,113
;FIGHT: 254
;EXPECT-BYTE: Inventory 7
;EXPECT-BYTE: Mode 0

Script:
        .byte 40, 0, 0
        .byte 5, 0, 1
        .byte 10, 0, 0
        .byte 6, 4, 0
        .byte 6, 0, 0
        .byte 6, 4, 0
        .byte 6, 0, 0
        .byte 6, 4, 0
        .byte 6, 0, 0
        .byte 5, 0, 1
        .byte 120, 0, 0
        .byte 5, 0, 1
        .byte 120, 0, 0
        .byte 5, 0, 1
        .byte 60, 0, 0
        .byte 5, 0, 1
        .byte 10, 0, 0
        .byte 6, 4, 0
        .byte 6, 0, 0
        .byte 6, 4, 0
        .byte 6, 0, 0
        .byte 6, 4, 0
        .byte 6, 0, 0
        .byte 5, 0, 1
        .byte 120, 0, 0
        .byte 5, 0, 1
        .byte 120, 0, 0
        .byte 5, 0, 1
        .byte 60, 0, 0
        .byte 0
