;Test script: on the overworld at (43,44), the keypad's Pause: the stick
;held right for 40 frames, and the hero stays at (43,44); Pause again and
;the stick right: one step, to (44,44).
;Entries: frames, directions (1 up, 2 right, 4 down, 8 left), buttons
;(1 lower fire, 2 upper; the high half a keypad key: $80 Pause).
;FIGHT: 254
;EXPECT-BYTE: HeroX 44
;EXPECT-BYTE: Paused 0
;EXPECT-BYTE: FadeSub 0
;EXPECT-BYTE: Mode 0

Script:
        .byte 20, 0, 0
        .byte 4, 0, $80
        .byte 4, 0, 0
        .byte 40, 2, 0
        .byte 10, 0, 0
        .byte 4, 0, $80
        .byte 4, 0, 0
        .byte 10, 2, 0
        .byte 40, 0, 0
        .byte 0
