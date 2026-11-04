;Test script: as lordfight, but his offer taken (the lower button: YES,
;twice): the hero's gold, items and equipment gone, and the game over
;there (its last step kept).
;Entries: frames, directions (1 up, 2 right, 4 down, 8 left), buttons
;(1 lower fire, 2 upper).
;START: 21,17,24
;LEVEL: 20
;FIGHT: 254
;GOLD: 100
;ITEM: 1
;EXPECT-BYTE: Gold 0
;EXPECT-BYTE: Inventory 0
;EXPECT-BYTE: ShopState 39
;EXPECT-BYTE: BattleOn 0

Script:
        .byte 20, 0, 0
        .byte 4, 8, 0
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
        .byte 120, 0, 0
        .byte 5, 0, 1
        .byte 120, 0, 0
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
