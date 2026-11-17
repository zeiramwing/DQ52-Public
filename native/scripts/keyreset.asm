;Test script: in the rock mountain cave, B1, a step left (to (5,11)); then
;the keypad's Reset: the cartridge starts again, the hero back where this
;build starts him (6,11), no steps taken. (Test builds keep the script
;going over the Reset: ResetHook.)
;Entries: frames, directions (1 up, 2 right, 4 down, 8 left), buttons
;(1 lower fire, 2 upper; the high half a keypad key: $40 Reset).
;START: 12,6,11
;FIGHT: 254
;EXPECT-BYTE: HeroX 6
;EXPECT-BYTE: HeroY 11
;EXPECT-BYTE: Mode 0

Script:
        .byte 20, 0, 0
        .byte 4, 8, 0
        .byte 40, 0, 0
        .byte 5, 0, $40
        .byte 90, 0, 0
        .byte 0
