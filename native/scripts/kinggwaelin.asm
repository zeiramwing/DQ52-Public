;Test script: carrying the princess (ModFlags 2), in the throne room below
;the King (3,3): a step up (he is there), TALK: his thanks, her keepsake
;given, her farewell: she is home (ModFlags bit 2).
;Entries: frames, directions (1 up, 2 right, 4 down, 8 left), buttons
;(1 lower fire, 2 upper).
;START: 3,3,4
;FIGHT: 254
;FLAGS: 2
;EXPECT-BYTE: ModFlags 4
;EXPECT-BYTE: Inventory 8
;EXPECT-BYTE: Mode 0

Script:
        .byte 20, 0, 0
        .byte 4, 1, 0
        .byte 30, 0, 0
        .byte 5, 0, 1
        .byte 10, 0, 0
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
