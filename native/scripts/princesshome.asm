;Test script: the throne room with the princess home (ModFlags 4): she is
;among its people (5; 4 before she is home, as king's), in the figure the
;game gives her there.
;Entries: frames, directions (1 up, 2 right, 4 down, 8 left), buttons
;(1 lower fire, 2 upper).
;START: 3,3,6
;FIGHT: 254
;FLAGS: 4
;EXPECT-BYTE: PeopleOn 5
;EXPECT-BYTE: Mode 0

Script:
        .byte 30, 0, 0
        .byte 0
