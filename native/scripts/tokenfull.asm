;Test script: on the overworld at (83,113), where Erdrick's token lies, the
;bag full of fighter's rings: SEARCH (down three in the command window): the
;token found, but something must go: NO (down in the YES/NO window): the
;token given up, the rings kept, the window closed.
;Entries: frames, directions (1 up, 2 right, 4 down, 8 left), buttons
;(1 lower fire, 2 upper).
;START: 0,83,113
;FIGHT: 254
;ITEM: 6,6,6,6,6,6,6,6
;EXPECT-BYTE: Inventory 102
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
        .byte 120, 0, 0
        .byte 6, 4, 0
        .byte 6, 0, 0
        .byte 5, 0, 1
        .byte 90, 0, 0
        .byte 5, 0, 1
        .byte 60, 0, 0
        .byte 0
