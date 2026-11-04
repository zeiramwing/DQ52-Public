;Test script: in Brecconary left of the curse lifter (24,10), cursed by the
;belt: a step right (he is there), TALK: the belt taken and the curse
;lifted.
;(Flags2 bit 1: the throne room left, as on any map but it.)
;Entries: frames, directions (1 up, 2 right, 4 down, 8 left), buttons
;(1 lower fire, 2 upper).
;START: 2,23,10
;ITEM: 9
;FIGHT: 254
;EXPECT-BYTE: Flags2 2
;EXPECT-BYTE: Inventory 0

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
        .byte 4, 2, 0
        .byte 30, 0, 0
        .byte 5, 0, 1
        .byte 10, 0, 0
        .byte 5, 0, 1
        .byte 150, 0, 0
        .byte 5, 0, 1
        .byte 150, 0, 0
        .byte 5, 0, 1
        .byte 60, 0, 0
        .byte 0
