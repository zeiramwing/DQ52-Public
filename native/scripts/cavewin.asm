;Test script: in the rock mountain cave, B1 (dark), a step left: a fight
;with a Slime (FIGHT 0) on black, no scene; FIGHT each round, through the
;win's messages. Back in the cave: dark again (its map's copy where the
;scene's set would go, kept: no scene in a cave), the Slime's experience
;and gold.
;Entries: frames, directions (1 up, 2 right, 4 down, 8 left), buttons
;(1 lower fire, 2 upper).
;START: 12,6,11
;FIGHT: 0
;EXPECT-BYTE: Experience 1
;EXPECT-BYTE: BattleOn 0
;EXPECT-BYTE: Mode 0
;EXPECT-BYTE: Dark 1
;EXPECT-BYTE: MapId 12

Script:
        .byte 20, 0, 0
        .byte 4, 8, 0
        .byte 60, 0, 0
        .byte 5, 0, 1
        .byte 55, 0, 0
        .byte 5, 0, 1
        .byte 55, 0, 0
        .byte 5, 0, 1
        .byte 55, 0, 0
        .byte 5, 0, 1
        .byte 55, 0, 0
        .byte 5, 0, 1
        .byte 55, 0, 0
        .byte 5, 0, 1
        .byte 55, 0, 0
        .byte 5, 0, 1
        .byte 55, 0, 0
        .byte 5, 0, 1
        .byte 55, 0, 0
        .byte 5, 0, 1
        .byte 55, 0, 0
        .byte 5, 0, 1
        .byte 55, 0, 0
        .byte 5, 0, 1
        .byte 55, 0, 0
        .byte 5, 0, 1
        .byte 55, 0, 0
        .byte 5, 0, 1
        .byte 55, 0, 0
        .byte 5, 0, 1
        .byte 55, 0, 0
        .byte 5, 0, 1
        .byte 55, 0, 0
        .byte 5, 0, 1
        .byte 55, 0, 0
        .byte 5, 0, 1
        .byte 55, 0, 0
        .byte 5, 0, 1
        .byte 55, 0, 0
        .byte 5, 0, 1
        .byte 55, 0, 0
        .byte 5, 0, 1
        .byte 55, 0, 0
        .byte 5, 0, 1
        .byte 55, 0, 0
        .byte 5, 0, 1
        .byte 55, 0, 0
        .byte 5, 0, 1
        .byte 55, 0, 0
        .byte 5, 0, 1
        .byte 55, 0, 0
        .byte 5, 0, 1
        .byte 55, 0, 0
        .byte 5, 0, 1
        .byte 55, 0, 0
        .byte 5, 0, 1
        .byte 55, 0, 0
        .byte 5, 0, 1
        .byte 55, 0, 0
        .byte 5, 0, 1
        .byte 55, 0, 0
        .byte 5, 0, 1
        .byte 55, 0, 0
        .byte 5, 0, 1
        .byte 55, 0, 0
        .byte 5, 0, 1
        .byte 55, 0, 0
        .byte 5, 0, 1
        .byte 55, 0, 0
        .byte 5, 0, 1
        .byte 55, 0, 0
        .byte 5, 0, 1
        .byte 55, 0, 0
        .byte 5, 0, 1
        .byte 55, 0, 0
        .byte 5, 0, 1
        .byte 55, 0, 0
        .byte 5, 0, 1
        .byte 55, 0, 0
        .byte 5, 0, 1
        .byte 55, 0, 0
        .byte 5, 0, 1
        .byte 55, 0, 0
        .byte 0
