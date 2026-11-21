;Test script: a level 20 hero meets a Slime: his strength is more than
;twice its attack, so as the fight starts it may run (1 in 4, the game's
;CheckEnRun, before who goes first is decided): with this seed it does,
;and the hero walks on with nothing gained.
;Entries: frames, directions (1 up, 2 right, 4 down, 8 left), buttons
;(1 lower fire, 2 upper).
;LEVEL: 20
;FIGHT: 0
;SEED: 2
;EXPECT-BYTE: BattleOn 0
;EXPECT-BYTE: Experience 0
;EXPECT-BYTE: Mode 0

Script:
        .byte 4, 8, 0
        .byte 250, 0, 0
        .byte 0
