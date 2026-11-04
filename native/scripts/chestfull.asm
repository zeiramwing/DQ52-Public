;Test script: in Garinham on the torch's chest at (9,5), the bag full
;of fighter's rings: TAKE (down three times, right): found, but something
;must go: YES, the list: the first ring dropped, the torch taken (ITM 1 in
;the first byte's low half), the window closed.
;Entries: frames, directions (1 up, 2 right, 4 down, 8 left), buttons
;(1 lower fire, 2 upper).
;START: 5,9,5
;FIGHT: 254
;ITEM: 6,6,6,6,6,6,6,6
;EXPECT-BYTE: Inventory 97
;EXPECT-BYTE: Mode 0

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
        .byte 90, 0, 0
        .byte 5, 0, 1
        .byte 90, 0, 0
        .byte 5, 0, 1
        .byte 60, 0, 0
        .byte 5, 0, 1
        .byte 60, 0, 0
        .byte 5, 0, 1
        .byte 90, 0, 0
        .byte 5, 0, 1
        .byte 60, 0, 0
        .byte 0
