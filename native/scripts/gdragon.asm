;Test script: a level 30 hero in Erdrick's gear in the swamp cave above
;the green dragon's block (4,14): a step down: his fight (enemy 30), FIGHT
;until he is beaten: his flag set (ModFlags bit 6), never again.
;Entries: frames, directions (1 up, 2 right, 4 down, 8 left), buttons
;(1 lower fire, 2 upper).
;START: 11,4,13
;FIGHT: 254
;LEVEL: 30
;EQUIP: 255
;EXPECT-BYTE: BattleOn 0
;EXPECT-BYTE: ModFlags 64

Script:
        .byte 20, 0, 0
        .byte 4, 4, 0
        .byte 80, 0, 0
        .byte 5, 0, 1
        .byte 60, 0, 0
        .byte 5, 0, 1
        .byte 60, 0, 0
        .byte 5, 0, 1
        .byte 60, 0, 0
        .byte 5, 0, 1
        .byte 60, 0, 0
        .byte 5, 0, 1
        .byte 60, 0, 0
        .byte 5, 0, 1
        .byte 60, 0, 0
        .byte 5, 0, 1
        .byte 60, 0, 0
        .byte 5, 0, 1
        .byte 60, 0, 0
        .byte 5, 0, 1
        .byte 60, 0, 0
        .byte 5, 0, 1
        .byte 60, 0, 0
        .byte 5, 0, 1
        .byte 60, 0, 0
        .byte 5, 0, 1
        .byte 60, 0, 0
        .byte 5, 0, 1
        .byte 60, 0, 0
        .byte 5, 0, 1
        .byte 60, 0, 0
        .byte 5, 0, 1
        .byte 60, 0, 0
        .byte 5, 0, 1
        .byte 60, 0, 0
        .byte 0
