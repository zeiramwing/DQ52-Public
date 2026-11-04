;Test script: as rainstaff, without the silver harp: the old man's test,
;and he stays.
;Entries: frames, directions (1 up, 2 right, 4 down, 8 left), buttons
;(1 lower fire, 2 upper).
;START: 9,5,4
;FIGHT: 254
;EXPECT-BYTE: PeopleOn 1
;EXPECT-BYTE: Mode 0

Script:
        .byte 20, 0, 0
        .byte 4, 8, 0
        .byte 30, 0, 0
        .byte 5, 0, 1
        .byte 10, 0, 0
        .byte 5, 0, 1
        .byte 250, 0, 0
        .byte 5, 0, 1
        .byte 250, 0, 0
        .byte 5, 0, 1
        .byte 250, 0, 0
        .byte 5, 0, 1
        .byte 250, 0, 0
        .byte 5, 0, 1
        .byte 60, 0, 0
        .byte 0
