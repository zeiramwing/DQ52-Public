;Test script: the title at power-on, the keypad's Start past it: the start
;menu; Start again (NEW GAME): the name window (NameMode 1, the cursor on
;A, nothing typed).
;Entries: frames, directions (1 up, 2 right, 4 down, 8 left), buttons
;(1 lower fire, 2 upper; the high half a keypad key: $C0 Start).
;NAME-ENTRY
;FIGHT: 254
;EXPECT-BYTE: TitleOn 3
;EXPECT-BYTE: NameMode 1
;EXPECT-BYTE: Song 4
;EXPECT-BYTE: PwLen 128
;EXPECT-BYTE: Mode 6

Script:
        .byte 30, 0, 0
        .byte 5, 0, $C0
        .byte 90, 0, 0
        .byte 5, 0, $C0
        .byte 30, 0, 0
        .byte 0
