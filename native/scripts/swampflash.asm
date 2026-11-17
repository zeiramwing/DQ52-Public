;Test script: on the overworld at (66,38), a step right onto the swamp at
;(67,38): 2 HP lost (15 to 13), the swamp's sound, and the screen red for
;a frame (FX_GROUND: the game's RedFlashScreen), over by the end.
;Entries: frames, directions (1 up, 2 right, 4 down, 8 left), buttons
;(1 lower fire, 2 upper).
;START: 0,66,38
;FIGHT: 254
;EXPECT-BYTE: HeroX 67
;EXPECT-BYTE: HitPoints 13
;EXPECT-BYTE: FxKind 5
;EXPECT-BYTE: FxTime 0

Script:
        .byte 20, 0, 0
        .byte 4, 2, 0
        .byte 40, 0, 0
        .byte 0
