;Test script: in Tantegel's hall below its gate row (11,28), cursed by the
;belt (as cursebelt): a step up onto the row: turned out of the castle,
;onto the overworld.
;(Flags2 bit 1: the throne room left, as on any map but it.)
;Entries: frames, directions (1 up, 2 right, 4 down, 8 left), buttons
;(1 lower fire, 2 upper).
;START: 1,11,28
;ITEM: 9
;FIGHT: 254
;EXPECT-BYTE: MapId 0
;EXPECT-BYTE: Flags2 66

Script:
        .byte 20, 0, 0
        .byte 5, 0, 1
        .byte 10, 0, 0
        .byte 4, 4, 0
        .byte 5, 0, 0
        .byte 4, 2, 0
        .byte 5, 0, 0
        .byte 5, 0, 1
        .byte 20, 0, 0
        .byte 5, 0, 1
        .byte 120, 0, 0
        .byte 5, 0, 1
        .byte 250, 0, 0
        .byte 4, 1, 0
        .byte 60, 0, 0
        .byte 5, 0, 1
        .byte 120, 0, 0
        .byte 0
