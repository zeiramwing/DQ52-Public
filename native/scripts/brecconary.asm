;Test script: from (43,44) a step right, three up and four right, onto
;Brecconary's block on the overworld at (48,41) and into the town, at
;(0,15); two steps up, then right, where a villager stands at (1,13);
;TALK.
;Entries: frames, directions (1 up, 2 right, 4 down, 8 left), buttons
;(1 lower fire, 2 upper).
;FIGHT: 254
;EXPECT-MSG: 89
;EXPECT: HP  15
;EXPECT-BYTE: Song 4

Script:
        .byte 4, 2, 0
        .byte 20, 0, 0
        .byte 36, 1, 0
        .byte 20, 0, 0
        .byte 52, 2, 0
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
