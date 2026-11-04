;Test script: on the overworld with the cursed belt: ITEM (down, right),
;the belt: put on, and cursed (Flags2 bit 6), the curse's tune, then the
;map's music again.
;(Flags2 bit 1: the throne room left, as on any map but it.)
;Entries: frames, directions (1 up, 2 right, 4 down, 8 left), buttons
;(1 lower fire, 2 upper).
;START: 0,43,44
;ITEM: 9
;FIGHT: 254
;EXPECT-BYTE: Flags2 66
;EXPECT-BYTE: Mode 0
;EXPECT-BYTE: Song 5

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
        .byte 0
