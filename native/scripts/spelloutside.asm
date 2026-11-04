;Test script: a level 13 hero in the rock mountain cave, B1: SPELL,
;OUTSIDE (the sixth): on the overworld at the cave's entrance, facing
;down, 6 MP paid.
;Entries: frames, directions (1 up, 2 right, 4 down, 8 left), buttons
;(1 lower fire, 2 upper).
;START: 12,6,11
;LEVEL: 13
;FIGHT: 254
;EXPECT-BYTE: MapId 0
;EXPECT-BYTE: HeroX 29
;EXPECT-BYTE: Facing 2
;EXPECT-BYTE: MagicPoints 58
;EXPECT-BYTE: Dark 0

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
        .byte 5, 0, 1
        .byte 160, 0, 0
        .byte 0
