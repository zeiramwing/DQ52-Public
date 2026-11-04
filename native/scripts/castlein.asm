;Test script: on the Dragonlord's island south of his castle at (48,48): a
;step up onto it, into the castle's ground floor (the ROM's map link), lit.
;Entries: frames, directions (1 up, 2 right, 4 down, 8 left), buttons
;(1 lower fire, 2 upper).
;START: 0,48,49
;FIGHT: 254
;EXPECT-BYTE: MapId 20
;EXPECT-BYTE: HeroX 10
;EXPECT-BYTE: HeroY 19
;EXPECT-BYTE: Dark 0
;EXPECT-ZERO: Missed

Script:
        .byte 4, 1, 0
        .byte 80, 0, 0
        .byte 0
