;Test script: a level 10 hero (54 HP) in the Dragonlord's castle at (8,2),
;a force field: up, right, right, over three force fields to the stairs
;hidden behind the throne at (10,1), 15 HP each (9 left); SEARCH there
;(down three in the command window): the stairs found; then STAIRS (down
;two): down to the first dark floor at (9,0).
;Entries: frames, directions (1 up, 2 right, 4 down, 8 left), buttons
;(1 lower fire, 2 upper).
;START: 20,8,2
;LEVEL: 10
;FIGHT: 254
;EXPECT-BYTE: HitPoints 9
;EXPECT-BYTE: ModFlags 16
;EXPECT-BYTE: MapId 22
;EXPECT-BYTE: HeroX 9
;EXPECT-BYTE: HeroY 0

Script:
        .byte 20, 0, 0
        .byte 4, 1, 0
        .byte 30, 0, 0
        .byte 4, 2, 0
        .byte 30, 0, 0
        .byte 4, 2, 0
        .byte 40, 0, 0
        .byte 5, 0, 1
        .byte 10, 0, 0
        .byte 6, 4, 0
        .byte 6, 0, 0
        .byte 6, 4, 0
        .byte 6, 0, 0
        .byte 6, 4, 0
        .byte 6, 0, 0
        .byte 5, 0, 1
        .byte 120, 0, 0
        .byte 5, 0, 1
        .byte 30, 0, 0
        .byte 5, 0, 1
        .byte 10, 0, 0
        .byte 6, 4, 0
        .byte 6, 0, 0
        .byte 6, 4, 0
        .byte 6, 0, 0
        .byte 5, 0, 1
        .byte 80, 0, 0
        .byte 0
