;Test script: on Tantegel's ground floor below the stairs up at (7,7), a
;step up and STAIRS: into the throne room, at (8,8). Four steps left, four
;up (through where the door was, between the guards), one left, then up,
;where King Lorik sits at (3,3): the hero turns to him. TALK: he is pleased,
;tells the experience for the next level (7 Points), and asks whether to
;record the hero's deeds: the YES/NO window.
;Entries: frames, directions (1 up, 2 right, 4 down, 8 left), buttons
;(1 lower fire, 2 upper).
;START: 1,7,8
;EXPECT-MSG: 193
;EXPECT-MSG: 291
;EXPECT: >YES
;EXPECT: NO
;EXPECT-BYTE: Song 2

Script:
        .byte 4, 1, 0
        .byte 24, 0, 0
        .byte 5, 0, 1
        .byte 10, 0, 0
        .byte 5, 4, 0
        .byte 5, 0, 0
        .byte 5, 4, 0
        .byte 10, 0, 0
        .byte 5, 0, 1
        .byte 30, 0, 0
        .byte 52, 8, 0
        .byte 20, 0, 0
        .byte 52, 1, 0
        .byte 20, 0, 0
        .byte 4, 8, 0
        .byte 20, 0, 0
        .byte 4, 1, 0
        .byte 10, 0, 0
        .byte 5, 0, 1
        .byte 10, 0, 0
        .byte 5, 0, 1
        .byte 90, 0, 0
        .byte 5, 0, 1
        .byte 110, 0, 0
        .byte 5, 0, 1
        .byte 110, 0, 0
        .byte 0
