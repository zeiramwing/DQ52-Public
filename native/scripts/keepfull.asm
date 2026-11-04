;Test script: as kinggwaelin, the bag full (seven fairy flutes and the
;dragon's scale): the King takes the first of InvListTbl's items held, the
;scale (ItemName 22), for her keepsake (ITM 8 in its place: the last
;byte $85), and says so; then her farewell.
;Entries: frames, directions (1 up, 2 right, 4 down, 8 left), buttons
;(1 lower fire, 2 upper).
;START: 3,3,4
;FIGHT: 254
;FLAGS: 2
;ITEM: 5,5,5,5,5,5,5,4
;EXPECT-BYTE: ModFlags 4
;EXPECT-BYTE: ItemName 22
;EXPECT-BYTE: Mode 0

Script:
        .byte 20, 0, 0
        .byte 4, 1, 0
        .byte 30, 0, 0
        .byte 5, 0, 1
        .byte 10, 0, 0
        .byte 5, 0, 1
        .byte 150, 0, 0
        .byte 5, 0, 1
        .byte 150, 0, 0
        .byte 5, 0, 1
        .byte 150, 0, 0
        .byte 5, 0, 1
        .byte 150, 0, 0
        .byte 5, 0, 1
        .byte 150, 0, 0
        .byte 5, 0, 1
        .byte 150, 0, 0
        .byte 5, 0, 1
        .byte 150, 0, 0
        .byte 5, 0, 1
        .byte 60, 0, 0
        .byte 5, 0, 1
        .byte 150, 0, 0
        .byte 0
