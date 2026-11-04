;Test script: on Tantegel's ground floor right of the treasury's locked door
;at (4,13), with a magic key: DOOR (down twice and right in the command
;window) opens it, the key used up. Four steps left, onto the chest at
;(1,13): SEARCH (down three times) finds a treasure box; TAKE (down three
;times, right): its gold (6-13), the chest gone.
;Entries: frames, directions (1 up, 2 right, 4 down, 8 left), buttons
;(1 lower fire, 2 upper).
;START: 1,5,13
;KEYS: 1
;EXPECT-MSG: 216
;EXPECT-BYTE: Keys 0
;EXPECT-BYTE: Mode 4

Script:
        .byte 30, 0, 0
        .byte 5, 0, 1
        .byte 10, 0, 0
        .byte 4, 4, 0
        .byte 5, 0, 0
        .byte 4, 4, 0
        .byte 5, 0, 0
        .byte 4, 2, 0
        .byte 5, 0, 0
        .byte 5, 0, 1
        .byte 20, 0, 0
        .byte 68, 8, 0
        .byte 30, 0, 0
        .byte 5, 0, 1
        .byte 10, 0, 0
        .byte 4, 4, 0
        .byte 5, 0, 0
        .byte 4, 4, 0
        .byte 5, 0, 0
        .byte 4, 4, 0
        .byte 5, 0, 0
        .byte 5, 0, 1
        .byte 90, 0, 0
        .byte 5, 0, 1
        .byte 30, 0, 0
        .byte 5, 0, 1
        .byte 20, 0, 0
        .byte 5, 0, 1
        .byte 10, 0, 0
        .byte 4, 4, 0
        .byte 5, 0, 0
        .byte 4, 4, 0
        .byte 5, 0, 0
        .byte 4, 4, 0
        .byte 5, 0, 0
        .byte 4, 2, 0
        .byte 5, 0, 0
        .byte 5, 0, 1
        .byte 60, 0, 0
        .byte 0
