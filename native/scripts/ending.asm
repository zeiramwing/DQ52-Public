;Test script: the Dragonlord dead (ModFlags 32), in Tantegel's hall below
;the ending's block (10,8): a step up onto it: the music stops, the King's
;last words (buttons through them), the pauses, the hero facing down, the
;end music, then the credits' step (credits).
;Entries: frames, directions (1 up, 2 right, 4 down, 8 left), buttons
;(1 lower fire, 2 upper).
;START: 1,10,9
;FLAGS: 32
;FIGHT: 254
;EXPECT-BYTE: ShopState 64
;EXPECT-BYTE: Song 16
;EXPECT-BYTE: Facing 2
;EXPECT-BYTE: DialogOn 0

Script:
        .byte 20, 0, 0
        .byte 4, 1, 0
        .byte 40, 0, 0
        .byte 200, 0, 0
        .byte 5, 0, 1
        .byte 200, 0, 0
        .byte 5, 0, 1
        .byte 200, 0, 0
        .byte 5, 0, 1
        .byte 200, 0, 0
        .byte 5, 0, 1
        .byte 200, 0, 0
        .byte 5, 0, 1
        .byte 200, 0, 0
        .byte 5, 0, 1
        .byte 200, 0, 0
        .byte 5, 0, 1
        .byte 200, 0, 0
        .byte 5, 0, 1
        .byte 200, 0, 0
        .byte 5, 0, 1
        .byte 200, 0, 0
        .byte 5, 0, 1
        .byte 200, 0, 0
        .byte 5, 0, 1
        .byte 200, 0, 0
        .byte 5, 0, 1
        .byte 200, 0, 0
        .byte 5, 0, 1
        .byte 200, 0, 0
        .byte 5, 0, 1
        .byte 255, 0, 0
        .byte 0
