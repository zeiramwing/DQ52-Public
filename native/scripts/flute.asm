;Test script: in Kol at (9,6), where the fairy flute lies: SEARCH (down
;three in the command window): the flute found (ITM_ 5).
;Entries: frames, directions (1 up, 2 right, 4 down, 8 left), buttons
;(1 lower fire, 2 upper).
;START: 4,9,6
;FIGHT: 254
;EXPECT-BYTE: Inventory 5
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
        .byte 0
