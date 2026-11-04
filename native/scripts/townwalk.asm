;Test script: into Brecconary as brecconary.asm does, then along its
;streets: 12 steps right, 2 up, 10 left, 2 down (fewer where a townsperson
;is in the way). No frame may be missed while walking with the people
;moving and drawn.
;Entries: frames, directions (1 up, 2 right, 4 down, 8 left), buttons
;(1 lower fire, 2 upper).
;EXPECT-ZERO: Missed

Script:
        .byte 4, 2, 0
        .byte 20, 0, 0
        .byte 36, 1, 0
        .byte 20, 0, 0
        .byte 52, 2, 0
        .byte 40, 0, 0
        .byte 180, 2, 0
        .byte 20, 1, 0
        .byte 148, 8, 0
        .byte 20, 4, 0
        .byte 30, 0, 0
        .byte 0
