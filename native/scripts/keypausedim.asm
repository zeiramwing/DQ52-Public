;Test script: on the overworld at (43,44), the keypad's Pause, and left
;paused: the screen dimmed (FadeSub 4, 4 less luminance) while it is held.
;Entries: frames, directions (1 up, 2 right, 4 down, 8 left), buttons
;(1 lower fire, 2 upper; the high half a keypad key: $80 Pause).
;FIGHT: 254
;EXPECT-BYTE: Paused 1
;EXPECT-BYTE: FadeSub 4
;EXPECT-BYTE: HeroX 43

Script:
        .byte 20, 0, 0
        .byte 4, 0, $80
        .byte 4, 0, 0
        .byte 20, 2, 0
        .byte 0
