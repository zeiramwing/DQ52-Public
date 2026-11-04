;Test script: as ending, the princess home (ModFlags 32 + 4): after the
;King's first words, her part (her figure not drawn): she asks to go with
;the hero, YES (buttons through it all): carried (ModFlags bit 1); then the
;tale's end, the pauses, the end music.
;Entries: frames, directions (1 up, 2 right, 4 down, 8 left), buttons
;(1 lower fire, 2 upper).
;START: 1,10,9
;FLAGS: 36
;FIGHT: 254
;EXPECT-BYTE: ModFlags 38
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
