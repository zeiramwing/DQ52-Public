;Test script: as rainbowman, without Erdrick's token: the old man sends
;the hero out of the cave, by its link, onto the overworld facing down.
;Entries: frames, directions (1 up, 2 right, 4 down, 8 left), buttons
;(1 lower fire, 2 upper).
;START: 10,3,5
;FIGHT: 254
;EXPECT-BYTE: MapId 0
;EXPECT-BYTE: HeroX 108
;EXPECT-BYTE: HeroY 109
;EXPECT-BYTE: Facing 2

Script:
        .byte 20, 0, 0
        .byte 4, 2, 0
        .byte 30, 0, 0
        .byte 5, 0, 1
        .byte 10, 0, 0
        .byte 5, 0, 1
        .byte 120, 0, 0
        .byte 5, 0, 1
        .byte 120, 0, 0
        .byte 5, 0, 1
        .byte 120, 0, 0
        .byte 5, 0, 1
        .byte 120, 0, 0
        .byte 5, 0, 1
        .byte 100, 0, 0
        .byte 0
