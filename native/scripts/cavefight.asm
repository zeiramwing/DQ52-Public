;Test script: in the rock mountain cave, B1 (dark), a step left: a fight
;(a Slime: FIGHT 0), on black, no scene (the cave's map copy kept where the
;scene's set would go). FIGHT, until it is won: back in the cave, its map
;and its darkness as they were.
;Entries: frames, directions (1 up, 2 right, 4 down, 8 left), buttons
;(1 lower fire, 2 upper).
;START: 12,6,11
;FIGHT: 0
;EXPECT-MSG: 226
;EXPECT-BYTE: BattleOn 1
;EXPECT-BYTE: Dark 1

Script:
        .byte 20, 0, 0
        .byte 4, 8, 0
        .byte 120, 0, 0
        .byte 0
