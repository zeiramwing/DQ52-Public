;Test script: in Hauksness at (18,12), where Erdrick's armor lies: SEARCH:
;the armor found and worn (the equipment byte's armor bits 7: 28).
;Entries: frames, directions (1 up, 2 right, 4 down, 8 left), buttons
;(1 lower fire, 2 upper).
;START: 28,18,12
;FIGHT: 254
;EXPECT-BYTE: Equipped 28
;EXPECT-BYTE: Mode 0

Script:
        .byte 40, 0, 0
        .byte 5, 0, 1
        .byte 10, 0, 0
        .byte 6, 4, 0
        .byte 6, 0, 0
        .byte 6, 4, 0
        .byte 6, 0, 0
        .byte 6, 4, 0
        .byte 6, 0, 0
        .byte 5, 0, 1
        .byte 120, 0, 0
        .byte 5, 0, 1
        .byte 120, 0, 0
        .byte 5, 0, 1
        .byte 60, 0, 0
        .byte 0
