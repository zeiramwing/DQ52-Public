;Test script: in Hauksness at (1,10), where every step starts a fight
;with a Slime: a step right: the fight on black (the town drawn black
;round the window, as the castle's lit floors are), FIGHT until it is won:
;the town lit again.
;Entries: frames, directions (1 up, 2 right, 4 down, 8 left), buttons
;(1 lower fire, 2 upper).
;START: 28,1,10
;LEVEL: 20
;FIGHT: 0
;EXPECT-BYTE: BattleOn 0
;EXPECT-BYTE: Experience 1
;EXPECT-BYTE: Dark 0
;EXPECT-BYTE: MapId 28

Script:
        .byte 20, 0, 0
        .byte 4, 2, 0
        .byte 60, 0, 0
        .byte 5, 0, 1
        .byte 70, 0, 0
        .byte 5, 0, 1
        .byte 70, 0, 0
        .byte 5, 0, 1
        .byte 70, 0, 0
        .byte 5, 0, 1
        .byte 70, 0, 0
        .byte 5, 0, 1
        .byte 70, 0, 0
        .byte 5, 0, 1
        .byte 70, 0, 0
        .byte 5, 0, 1
        .byte 70, 0, 0
        .byte 0
