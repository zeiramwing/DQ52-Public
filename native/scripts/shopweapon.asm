;Test script: in Brecconary below the weapon shop's counter at (5,5), with
;200 gold: face up, TALK across the counter to the shopkeeper. YES to buying,
;the list of the shop's goods and prices, down to the Club, chosen; the
;shopkeeper's check, YES: 60 gold paid, the Club equipped (bits 5-7 of
;Equipped: 2); NO to buying more: the shop's farewell (message 47).
;Entries: frames, directions (1 up, 2 right, 4 down, 8 left), buttons
;(1 lower fire, 2 upper).
;START: 2,5,6
;GOLD: 200
;EXPECT-MSG: 47
;EXPECT-BYTE: Equipped 64
;EXPECT-BYTE: Gold 140

Script:
        .byte 4, 1, 0
        .byte 30, 0, 0
        .byte 5, 0, 1
        .byte 10, 0, 0
        .byte 5, 0, 1
        .byte 120, 0, 0
        .byte 5, 0, 1
        .byte 60, 0, 0
        .byte 4, 4, 0
        .byte 10, 0, 0
        .byte 5, 0, 1
        .byte 40, 0, 0
        .byte 5, 0, 1
        .byte 40, 0, 0
        .byte 5, 0, 1
        .byte 80, 0, 0
        .byte 5, 0, 2
        .byte 60, 0, 0
        .byte 0
