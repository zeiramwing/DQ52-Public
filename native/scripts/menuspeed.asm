;Test script: the title, a button past it: the start menu; down once
;(from the new quest to the message speed, the last), and
;the lower button: fast to normal (TextSpeed 1, a letter every other frame,
;the game's normal message speed), the menu still up.
;Entries: frames, directions (1 up, 2 right, 4 down, 8 left), buttons
;(1 lower fire, 2 upper).
;NAME-ENTRY
;FIGHT: 254
;EXPECT-BYTE: TextSpeed 1
;EXPECT-BYTE: MenuSel 2
;EXPECT-BYTE: TitleOn 2

Script:
        .byte 30, 0, 0
        .byte 5, 0, 1
        .byte 90, 0, 0
        .byte 4, 4, 0
        .byte 10, 0, 0
        .byte 4, 0, 0
        .byte 10, 0, 0
        .byte 5, 0, 1
        .byte 30, 0, 0
        .byte 0
