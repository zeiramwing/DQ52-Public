;Test script: on the overworld below the golem's block (73,100), by
;Cantlin: a step up: his fight (enemy 24).
;Entries: frames, directions (1 up, 2 right, 4 down, 8 left), buttons
;(1 lower fire, 2 upper).
;START: 0,73,101
;FIGHT: 254
;EXPECT-BYTE: BattleOn 1
;EXPECT-BYTE: Enemy 24

Script:
        .byte 20, 0, 0
        .byte 4, 1, 0
        .byte 80, 0, 0
        .byte 0
