;Test script: the title at power-on, left alone a second: the game's title
;music playing (MSC_INTRO), as the NES's DoIntroRoutine starts it.
;Entries: frames, directions (1 up, 2 right, 4 down, 8 left), buttons
;(1 lower fire, 2 upper).
;NAME-ENTRY
;FIGHT: 254
;EXPECT-BYTE: TitleOn 1
;EXPECT-BYTE: Song 1

Script:
        .byte 60, 0, 0
        .byte 0
