;Test script: the title at power-on, a button past it: the start menu on a
;blank screen (TitleOn 2), its cursor moved down to CONTINUE (MenuSel 1), no
;people and the hero out of sight meanwhile.
;Entries: frames, directions (1 up, 2 right, 4 down, 8 left), buttons
;(1 lower fire, 2 upper).
;NAME-ENTRY
;START: 3,3,4
;FIGHT: 254
;EXPECT: NEW GAME
;EXPECT: CONTINUE
;EXPECT-BYTE: TitleOn 2
;EXPECT-BYTE: MenuSel 1
;EXPECT-BYTE: PeopleOn 0
;EXPECT-BYTE: Mode 6

Script:
        .byte 30, 0, 0
        .byte 5, 0, 1
        .byte 90, 0, 0
        .byte 4, 4, 0
        .byte 30, 0, 0
        .byte 0
