;Test script: a level 10 hero in the rock mountain cave, B1 (dark): SPELL,
;RADIANT (the fourth): the light 7 blocks wide, for 80 steps, 3 MP paid.
;Entries: frames, directions (1 up, 2 right, 4 down, 8 left), buttons
;(1 lower fire, 2 upper).
;START: 12,6,11
;LEVEL: 10
;FIGHT: 254
;EXPECT-BYTE: LightW 7
;EXPECT-BYTE: RadiantTime 80
;EXPECT-BYTE: MagicPoints 37
;EXPECT-BYTE: Mode 0

Script:
        .byte 20, 0, 0
        .byte 5, 0, 1
        .byte 10, 0, 0
        .byte 5, 2, 0
        .byte 5, 0, 0
        .byte 5, 0, 1
        .byte 20, 0, 0
        .byte 6, 4, 0
        .byte 6, 0, 0
        .byte 6, 4, 0
        .byte 6, 0, 0
        .byte 6, 4, 0
        .byte 6, 0, 0
        .byte 5, 0, 1
        .byte 120, 0, 0
        .byte 0
