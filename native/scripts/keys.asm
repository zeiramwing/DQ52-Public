;Test script: on Tantegel's ground floor below the key seller's counter at
;(24,2), with 100 gold: face up, TALK: the offer of a key for 85 gold, YES:
;a key, the ask for another, NO: the seller's farewell (message 18).
;Entries: frames, directions (1 up, 2 right, 4 down, 8 left), buttons
;(1 lower fire, 2 upper).
;START: 1,24,3
;GOLD: 100
;EXPECT-MSG: 18
;EXPECT-BYTE: Gold 15
;EXPECT-BYTE: Keys 1

Script:
        .byte 4, 1, 0
        .byte 30, 0, 0
        .byte 5, 0, 1
        .byte 10, 0, 0
        .byte 5, 0, 1
        .byte 120, 0, 0
        .byte 5, 0, 1
        .byte 80, 0, 0
        .byte 5, 0, 2
        .byte 60, 0, 0
        .byte 0
