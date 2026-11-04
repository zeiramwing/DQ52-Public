;Test script: in Brecconary left of the inn's counter at (9,21), with 10
;gold: face right, TALK across the counter: the price for the night, YES:
;the night (the screen dark, the inn's tune), the morning, a button, the
;innkeeper's farewell (message 7).
;Entries: frames, directions (1 up, 2 right, 4 down, 8 left), buttons
;(1 lower fire, 2 upper).
;START: 2,8,21
;GOLD: 10
;EXPECT-MSG: 7
;EXPECT-BYTE: Gold 4
;EXPECT-BYTE: Song 4
;EXPECT-BYTE: Loading 0

Script:
        .byte 4, 2, 0
        .byte 30, 0, 0
        .byte 5, 0, 1
        .byte 10, 0, 0
        .byte 5, 0, 1
        .byte 130, 0, 0
        .byte 5, 0, 1
        .byte 250, 0, 0
        .byte 100, 0, 0
        .byte 5, 0, 1
        .byte 60, 0, 0
        .byte 0
