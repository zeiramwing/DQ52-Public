;Test script: on the overworld at (50,40), the princess's keepsake (ITM_ 8)
;held: ITEM (down, right), it chosen: the experience to the next level,
;then how far Tantegel (43,43) is: 3 south of the hero, 7 west;
;then her words. (Amount is left at the last distance: 7.)
;Entries: frames, directions (1 up, 2 right, 4 down, 8 left), buttons
;(1 lower fire, 2 upper).
;START: 0,50,40
;ITEM: 8
;FIGHT: 254
;EXPECT-BYTE: Amount 7

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
        .byte 150, 0, 0
        .byte 5, 0, 1
        .byte 150, 0, 0
        .byte 5, 0, 1
        .byte 150, 0, 0
        .byte 5, 0, 1
        .byte 60, 0, 0
        .byte 0
