;Test script: on the overworld east of Garinham's entrance at (2,2): a step
;left onto it, into Garinham (the ROM's map link: at (0,14), facing right),
;its music; then a step left, off its western edge, back out onto the
;overworld where the link starts.
;Entries: frames, directions (1 up, 2 right, 4 down, 8 left), buttons
;(1 lower fire, 2 upper).
;START: 0,3,2
;EXPECT-BYTE: MapId 0
;EXPECT-BYTE: HeroX 2
;EXPECT-BYTE: HeroY 2

Script:
        .byte 4, 8, 0
        .byte 60, 0, 0
        .byte 4, 8, 0
        .byte 60, 0, 0
        .byte 0
