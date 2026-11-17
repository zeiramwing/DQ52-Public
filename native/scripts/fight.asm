;Test script: from (43,44) a step left on the overworld, where every step
;starts a fight with a Slime (enemy 0); then the lower fire button every
;second: FIGHT each round, through the win's messages, which a last press
;ends. The hero is left with the Slime's experience (1) and gold (2), and
;walking again.
;Entries: frames, directions (1 up, 2 right, 4 down, 8 left), buttons
;(1 lower fire, 2 upper).
;FIGHT: 0
;EXPECT-BYTE: Experience 1
;EXPECT-BYTE: Gold 2
;EXPECT-BYTE: Mode 0
;EXPECT-BYTE: BattleOn 0

Script:
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
        .byte 0
