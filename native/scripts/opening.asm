;Test script: a new adventure in the throne room before the King (the play
;build's start), the name window: the title, a button past it, NEW GAME
;on the start menu, the name
;AB and END: the King's first words (FirstKingDialog: the dialog open),
;the throne room not yet left (Flags2 bit 1 clear: its chests and door
;there).
;Entries: frames, directions (1 up, 2 right, 4 down, 8 left), buttons
;(1 lower fire, 2 upper).
;NAME-ENTRY
;START: 3,3,4
;FIGHT: 254
;EXPECT-BYTE: DialogOn 1
;EXPECT-BYTE: Flags2 0
;EXPECT-BYTE: MapId 3

Script:
        .byte 30, 0, 0
        .byte 5, 0, 1
        .byte 90, 0, 0
        .byte 5, 0, 1
        .byte 30, 0, 0
        .byte 5, 0, 1
        .byte 5, 0, 0
        .byte 4, 2, 0
        .byte 5, 0, 0
        .byte 5, 0, 1
        .byte 5, 0, 0
        .byte 4, 4, 0
        .byte 5, 0, 0
        .byte 4, 4, 0
        .byte 5, 0, 0
        .byte 4, 4, 0
        .byte 5, 0, 0
        .byte 4, 4, 0
        .byte 5, 0, 0
        .byte 5, 0, 1
        .byte 30, 0, 0
        .byte 0
