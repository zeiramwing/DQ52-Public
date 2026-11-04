;Test script: in Hauksness (the ruined town, lit, with its own enemies)
;at (1,10): two steps left, onto its entrance and off its edge: out onto
;the overworld where its link starts (25,89).
;Entries: frames, directions (1 up, 2 right, 4 down, 8 left), buttons
;(1 lower fire, 2 upper).
;START: 28,1,10
;FIGHT: 254
;EXPECT-BYTE: MapId 0
;EXPECT-BYTE: HeroX 25
;EXPECT-BYTE: HeroY 89

Script:
        .byte 20, 0, 0
        .byte 4, 8, 0
        .byte 30, 0, 0
        .byte 4, 8, 0
        .byte 80, 0, 0
        .byte 0
