;Test script: from (43,44) a step up onto Tantegel's block on the overworld
;and into the castle, at (11,29); two steps up, then right, where a guard
;stands at (12,27) (the hero only turns to him); TALK.
;Entries: frames, directions (1 up, 2 right, 4 down, 8 left), buttons
;(1 lower fire, 2 upper).
;EXPECT-MSG: 80
;EXPECT: HP  15
;EXPECT-BYTE: Song 3

Script:
        .byte 4, 1, 0
        .byte 40, 0, 0
        .byte 20, 1, 0
        .byte 30, 0, 0
        .byte 4, 2, 0
        .byte 50, 0, 0
        .byte 5, 0, 1
        .byte 15, 0, 0
        .byte 5, 0, 1
        .byte 150, 0, 0
        .byte 0
