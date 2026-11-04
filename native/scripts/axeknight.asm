;Test script: in Hauksness left of the axe knight's block (18,12), where
;Erdrick's armor lies: a step right: his fight (enemy 33).
;Entries: frames, directions (1 up, 2 right, 4 down, 8 left), buttons
;(1 lower fire, 2 upper).
;START: 28,17,12
;FIGHT: 254
;EXPECT-BYTE: BattleOn 1
;EXPECT-BYTE: Enemy 33

Script:
        .byte 20, 0, 0
        .byte 4, 2, 0
        .byte 80, 0, 0
        .byte 0
