;Test script: on the stairs of the Dragonlord's castle at (4,14): STAIRS
;(down three in the command window): down to its first dark floor.
;Entries: frames, directions (1 up, 2 right, 4 down, 8 left), buttons
;(1 lower fire, 2 upper).
;START: 20,4,14
;FIGHT: 254
;EXPECT-BYTE: MapId 22
;EXPECT-BYTE: Dark 1
;EXPECT-BYTE: HeroX 8
;EXPECT-BYTE: HeroY 13

Script:
        .byte 20, 0, 0
        .byte 5, 0, 1
        .byte 10, 0, 0
        .byte 6, 4, 0
        .byte 6, 0, 0
        .byte 6, 4, 0
        .byte 6, 0, 0
        .byte 5, 0, 1
        .byte 80, 0, 0
        .byte 0
