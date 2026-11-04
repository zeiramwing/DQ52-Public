;Test script: a level 2 hero with 22 experience beats a Slime (FIGHT each
;round): 23, level 3, where HEAL is learned: said after the growth.
;Entries: frames, directions (1 up, 2 right, 4 down, 8 left), buttons
;(1 lower fire, 2 upper).
;LEVEL: 2
;EXP: 22
;FIGHT: 0
;EXPECT-MSG: 242
;EXPECT-BYTE: Level 3
;EXPECT-BYTE: BattleOn 1

Script:
        .byte 4, 8, 0
        .byte 60, 0, 0
        .byte 5, 0, 1
        .byte 90, 0, 0
        .byte 5, 0, 1
        .byte 90, 0, 0
        .byte 5, 0, 1
        .byte 90, 0, 0
        .byte 5, 0, 1
        .byte 90, 0, 0
        .byte 5, 0, 1
        .byte 90, 0, 0
        .byte 5, 0, 1
        .byte 90, 0, 0
        .byte 5, 0, 1
        .byte 90, 0, 0
        .byte 5, 0, 1
        .byte 90, 0, 0
        .byte 0
