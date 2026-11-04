;Test script: the title at power-on, a button past it; the start menu, NEW
;GAME (the lower button); the name window: A (the cursor's first place),
;right and B, four down to END: the name is AB (in text tiles), 2 long. Its
;first 4 letters' sum (with the two blanks) is 7: the max HP cut to 9/10
;and 1 more (15: 14), the MP none to cut; HP full; the window closed.
;Entries: frames, directions (1 up, 2 right, 4 down, 8 left), buttons
;(1 lower fire, 2 upper).
;NAME-ENTRY
;FIGHT: 254
;EXPECT-BYTE: HeroName 36
;EXPECT-BYTE: NameLen 2
;EXPECT-BYTE: MaxHP 14
;EXPECT-BYTE: HitPoints 14
;EXPECT-BYTE: Strength 4
;EXPECT-BYTE: Mode 0

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
