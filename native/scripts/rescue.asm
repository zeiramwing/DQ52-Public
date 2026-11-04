;Test script: in the swamp cave left of the princess (5,18): a step right
;(she is there: the hero turns to her), TALK: her words, YES to taking her
;home: she is carried (ModFlags bit 1), her block floor.
;Entries: frames, directions (1 up, 2 right, 4 down, 8 left), buttons
;(1 lower fire, 2 upper).
;START: 11,4,18
;FIGHT: 254
;EXPECT-BYTE: ModFlags 2
;EXPECT-BYTE: Mode 0

Script:
        .byte 20, 0, 0
        .byte 4, 2, 0
        .byte 30, 0, 0
        .byte 5, 0, 1
        .byte 10, 0, 0
        .byte 5, 0, 1
        .byte 150, 0, 0
        .byte 5, 0, 1
        .byte 150, 0, 0
        .byte 5, 0, 1
        .byte 150, 0, 0
        .byte 5, 0, 1
        .byte 150, 0, 0
        .byte 5, 0, 1
        .byte 60, 0, 0
        .byte 0
