;Test script: a level 10 hero, a fight with a Slime: SPELL, HURT (the
;second): 2 MP paid, the Slime (3 HP, no magic defense) defeated; the
;win's messages, then walking again with the scene put back.
;(Seeded: the hero is strong enough that the Slime may run, the
;game's CheckEnRun; with this seed it stays.)
;Entries: frames, directions (1 up, 2 right, 4 down, 8 left), buttons
;(1 lower fire, 2 upper).
;LEVEL: 10
;FIGHT: 0
;SEED: 1
;EXPECT-BYTE: MagicPoints 38
;EXPECT-BYTE: Experience 1
;EXPECT-BYTE: BattleOn 0
;EXPECT-BYTE: Mode 0

Script:
        .byte 4, 8, 0
        .byte 120, 0, 0
        .byte 5, 2, 0
        .byte 5, 0, 0
        .byte 5, 0, 1
        .byte 30, 0, 0
        .byte 6, 4, 0
        .byte 6, 0, 0
        .byte 5, 0, 1
        .byte 120, 0, 0
        .byte 5, 0, 1
        .byte 80, 0, 0
        .byte 5, 0, 1
        .byte 80, 0, 0
        .byte 5, 0, 1
        .byte 80, 0, 0
        .byte 5, 0, 1
        .byte 80, 0, 0
        .byte 5, 0, 1
        .byte 80, 0, 0
        .byte 5, 0, 1
        .byte 80, 0, 0
        .byte 0
