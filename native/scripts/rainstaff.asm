;Test script: in the staff of rain's cave right of its old man at (4,4),
;with the silver harp: a step left (the hero turns to him), TALK: the harp
;taken, and he goes; two steps left to the chest he kept, TAKE (down three
;and right in the command window): the staff of rain.
;Entries: frames, directions (1 up, 2 right, 4 down, 8 left), buttons
;(1 lower fire, 2 upper).
;START: 9,5,4
;FIGHT: 254
;ITEM: 10
;EXPECT-BYTE: PeopleOn 0
;EXPECT-BYTE: Inventory 13
;EXPECT-BYTE: HeroX 3

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
        .byte 60, 0, 0
        .byte 4, 8, 0
        .byte 30, 0, 0
        .byte 4, 8, 0
        .byte 40, 0, 0
        .byte 5, 0, 1
        .byte 10, 0, 0
        .byte 6, 4, 0
        .byte 6, 0, 0
        .byte 6, 4, 0
        .byte 6, 0, 0
        .byte 6, 4, 0
        .byte 6, 0, 0
        .byte 6, 2, 0
        .byte 6, 0, 0
        .byte 5, 0, 1
        .byte 150, 0, 0
        .byte 0
