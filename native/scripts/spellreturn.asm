;Test script: a level 13 hero in Garinham: SPELL, RETURN (the seventh):
;on the overworld beside Tantegel, 8 MP paid.
;Entries: frames, directions (1 up, 2 right, 4 down, 8 left), buttons
;(1 lower fire, 2 upper).
;START: 5,2,2
;LEVEL: 13
;FIGHT: 254
;EXPECT-BYTE: MapId 0
;EXPECT-BYTE: HeroX 42
;EXPECT-BYTE: HeroY 43
;EXPECT-BYTE: MagicPoints 56

Script:
        .byte 20, 0, 0
        .byte 5, 0, 1
        .byte 10, 0, 0
        .byte 5, 2, 0
        .byte 5, 0, 0
        .byte 5, 0, 1
        .byte 20, 0, 0
        .byte 6, 4, 0
        .byte 6, 0, 0
        .byte 6, 4, 0
        .byte 6, 0, 0
        .byte 6, 4, 0
        .byte 6, 0, 0
        .byte 6, 4, 0
        .byte 6, 0, 0
        .byte 6, 4, 0
        .byte 6, 0, 0
        .byte 6, 4, 0
        .byte 6, 0, 0
        .byte 5, 0, 1
        .byte 160, 0, 0
        .byte 0
