;Test script: a level 10 hero wearing a weapon, armor and a shield (73:
;weapon 2, armor 2, shield 1): the
;command window, STATUS (down one): the STATUS window (Mode 5), left up.
;Entries: frames, directions (1 up, 2 right, 4 down, 8 left), buttons
;(1 lower fire, 2 upper).
;LEVEL: 10
;EQUIP: 73
;FIGHT: 254
;EXPECT-BYTE: Mode 5
;EXPECT-BYTE: StField 39

Script:
        .byte 40, 0, 0
        .byte 5, 0, 1
        .byte 10, 0, 0
        .byte 6, 4, 0
        .byte 6, 0, 0
        .byte 5, 0, 1
        .byte 30, 0, 0
        .byte 0
