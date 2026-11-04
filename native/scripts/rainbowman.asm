;Test script: in the rainbow drop's cave left of its old man at (4,5),
;with Erdrick's token, the stones of sunlight and the staff of rain: a step
;right (he is there: the hero turns to him), TALK: the stones and the staff
;become the rainbow drop (the token kept: the first byte $E7).
;Entries: frames, directions (1 up, 2 right, 4 down, 8 left), buttons
;(1 lower fire, 2 upper).
;START: 10,3,5
;FIGHT: 254
;ITEM: 7,12,13
;EXPECT-BYTE: Inventory 231
;EXPECT-BYTE: MapId 10

Script:
        .byte 20, 0, 0
        .byte 4, 2, 0
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
        .byte 100, 0, 0
        .byte 0
