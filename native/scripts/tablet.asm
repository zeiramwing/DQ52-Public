;Test script: in Erdrick's cave B2 on the tablet's chest at (9,3): TAKE
;(down three times, right): found (its name inserted: TABLET_ITEM 44),
;then the tablet's own words; the chest gone.
;Entries: frames, directions (1 up, 2 right, 4 down, 8 left), buttons
;(1 lower fire, 2 upper).
;START: 19,9,3
;FIGHT: 254
;EXPECT-BYTE: ItemName 44
;EXPECT-BYTE: ShopState 0
;EXPECT-BYTE: Mode 4

Script:
        .byte 20, 0, 0
        .byte 5, 0, 1
        .byte 10, 0, 0
        .byte 4, 4, 0
        .byte 5, 0, 0
        .byte 4, 4, 0
        .byte 5, 0, 0
        .byte 4, 4, 0
        .byte 5, 0, 0
        .byte 4, 2, 0
        .byte 5, 0, 0
        .byte 5, 0, 1
        .byte 120, 0, 0
        .byte 5, 0, 1
        .byte 150, 0, 0
        .byte 0
