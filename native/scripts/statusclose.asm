;Test script: as status, then a button: the window closed, the map back,
;walking again.
;Entries: frames, directions (1 up, 2 right, 4 down, 8 left), buttons
;(1 lower fire, 2 upper).
;LEVEL: 10
;EQUIP: 73
;FIGHT: 254
;EXPECT-BYTE: Mode 0

Script:
        .byte 40, 0, 0
        .byte 5, 0, 1
        .byte 10, 0, 0
        .byte 6, 4, 0
        .byte 6, 0, 0
        .byte 5, 0, 1
        .byte 30, 0, 0
        .byte 5, 0, 1
        .byte 30, 0, 0
        .byte 0
