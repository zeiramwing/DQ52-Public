;Test script: in Brecconary left of the tool shop's counter at (24,25), with
;100 gold: face right, TALK: BUY (the BUY/SELL window), the Herb (24 gold),
;the thanks, NO to anything else, the farewell; the window closed. Then
;ITEM (down and right in the command window): the list window holds the
;Herb, chosen: the herb's message (247).
;Entries: frames, directions (1 up, 2 right, 4 down, 8 left), buttons
;(1 lower fire, 2 upper).
;START: 2,23,25
;GOLD: 100
;EXPECT-MSG: 247
;EXPECT-BYTE: Gold 76
;EXPECT-BYTE: Herbs 0

Script:
        .byte 4, 2, 0
        .byte 30, 0, 0
        .byte 5, 0, 1
        .byte 10, 0, 0
        .byte 5, 0, 1
        .byte 80, 0, 0
        .byte 5, 0, 1
        .byte 40, 0, 0
        .byte 5, 0, 1
        .byte 40, 0, 0
        .byte 5, 0, 1
        .byte 60, 0, 0
        .byte 5, 0, 2
        .byte 60, 0, 0
        .byte 5, 0, 1
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
        .byte 60, 0, 0
        .byte 0
