;Test script: as pwentry, with the title and the name window (NAME-ENTRY):
;the upper button past the title to the start menu, down to CONTINUE and
;the lower button: the password window; the password
;right, the name asked for: A, then four down to END. The password's level
;(12) and its stats with the name's part: A and three blanks sum to 65, so
;the max MP (58) and the agility (40) are cut to 9/10, none added; then the
;King.
;Entries: frames, directions (1 up, 2 right, 4 down, 8 left), buttons
;(1 lower fire, 2 upper).
;NAME-ENTRY
;FIGHT: 254
;EXPECT-BYTE: Level 12
;EXPECT-BYTE: MapId 3
;EXPECT-BYTE: HeroName 36
;EXPECT-BYTE: NameLen 1
;EXPECT-BYTE: Strength 48
;EXPECT-BYTE: Agility 36
;EXPECT-BYTE: MaxMP 52
;EXPECT-BYTE: MagicPoints 52
;EXPECT-BYTE: Mode 2
;EXPECT-BYTE: DialogOn 1
;EXPECT-BYTE: Flags2 2

Script:
        .byte 30, 0, 0
        .byte 10, 0, 2
        .byte 90, 0, 0
        .byte 4, 4, 0
        .byte 6, 0, 0
        .byte 5, 0, 1
        .byte 30, 0, 0
        .byte 3, 4, 0
        .byte 3, 0, 0
        .byte 3, 2, 0
        .byte 3, 0, 0
        .byte 3, 2, 0
        .byte 3, 0, 0
        .byte 3, 2, 0
        .byte 3, 0, 0
        .byte 3, 2, 0
        .byte 3, 0, 0
        .byte 3, 2, 0
        .byte 3, 0, 0
        .byte 3, 0, 1
        .byte 3, 0, 0
        .byte 3, 8, 0
        .byte 3, 0, 0
        .byte 3, 8, 0
        .byte 3, 0, 0
        .byte 3, 0, 1
        .byte 3, 0, 0
        .byte 3, 0, 1
        .byte 3, 0, 0
        .byte 3, 4, 0
        .byte 3, 0, 0
        .byte 3, 4, 0
        .byte 3, 0, 0
        .byte 3, 2, 0
        .byte 3, 0, 0
        .byte 3, 2, 0
        .byte 3, 0, 0
        .byte 3, 0, 1
        .byte 3, 0, 0
        .byte 3, 1, 0
        .byte 3, 0, 0
        .byte 3, 1, 0
        .byte 3, 0, 0
        .byte 3, 1, 0
        .byte 3, 0, 0
        .byte 3, 0, 1
        .byte 3, 0, 0
        .byte 3, 4, 0
        .byte 3, 0, 0
        .byte 3, 4, 0
        .byte 3, 0, 0
        .byte 3, 4, 0
        .byte 3, 0, 0
        .byte 3, 8, 0
        .byte 3, 0, 0
        .byte 3, 8, 0
        .byte 3, 0, 0
        .byte 3, 0, 1
        .byte 3, 0, 0
        .byte 3, 1, 0
        .byte 3, 0, 0
        .byte 3, 8, 0
        .byte 3, 0, 0
        .byte 3, 0, 1
        .byte 3, 0, 0
        .byte 3, 4, 0
        .byte 3, 0, 0
        .byte 3, 8, 0
        .byte 3, 0, 0
        .byte 3, 0, 1
        .byte 3, 0, 0
        .byte 3, 1, 0
        .byte 3, 0, 0
        .byte 3, 1, 0
        .byte 3, 0, 0
        .byte 3, 1, 0
        .byte 3, 0, 0
        .byte 3, 2, 0
        .byte 3, 0, 0
        .byte 3, 0, 1
        .byte 3, 0, 0
        .byte 3, 4, 0
        .byte 3, 0, 0
        .byte 3, 4, 0
        .byte 3, 0, 0
        .byte 3, 4, 0
        .byte 3, 0, 0
        .byte 3, 2, 0
        .byte 3, 0, 0
        .byte 3, 2, 0
        .byte 3, 0, 0
        .byte 3, 2, 0
        .byte 3, 0, 0
        .byte 3, 2, 0
        .byte 3, 0, 0
        .byte 3, 0, 1
        .byte 3, 0, 0
        .byte 3, 1, 0
        .byte 3, 0, 0
        .byte 3, 2, 0
        .byte 3, 0, 0
        .byte 3, 0, 1
        .byte 3, 0, 0
        .byte 3, 1, 0
        .byte 3, 0, 0
        .byte 3, 8, 0
        .byte 3, 0, 0
        .byte 3, 8, 0
        .byte 3, 0, 0
        .byte 3, 8, 0
        .byte 3, 0, 0
        .byte 3, 8, 0
        .byte 3, 0, 0
        .byte 3, 8, 0
        .byte 3, 0, 0
        .byte 3, 0, 1
        .byte 3, 0, 0
        .byte 3, 1, 0
        .byte 3, 0, 0
        .byte 3, 0, 1
        .byte 3, 0, 0
        .byte 3, 4, 0
        .byte 3, 0, 0
        .byte 3, 4, 0
        .byte 3, 0, 0
        .byte 3, 8, 0
        .byte 3, 0, 0
        .byte 3, 8, 0
        .byte 3, 0, 0
        .byte 3, 0, 1
        .byte 3, 0, 0
        .byte 3, 4, 0
        .byte 3, 0, 0
        .byte 3, 2, 0
        .byte 3, 0, 0
        .byte 3, 2, 0
        .byte 3, 0, 0
        .byte 3, 0, 1
        .byte 3, 0, 0
        .byte 3, 1, 0
        .byte 3, 0, 0
        .byte 3, 0, 1
        .byte 3, 0, 0
        .byte 3, 4, 0
        .byte 3, 0, 0
        .byte 3, 8, 0
        .byte 3, 0, 0
        .byte 3, 0, 1
        .byte 3, 0, 0
        .byte 3, 1, 0
        .byte 3, 0, 0
        .byte 3, 1, 0
        .byte 3, 0, 0
        .byte 3, 2, 0
        .byte 3, 0, 0
        .byte 3, 0, 1
        .byte 3, 0, 0
        .byte 3, 4, 0
        .byte 3, 0, 0
        .byte 3, 4, 0
        .byte 3, 0, 0
        .byte 3, 2, 0
        .byte 3, 0, 0
        .byte 3, 2, 0
        .byte 3, 0, 0
        .byte 3, 0, 1
        .byte 3, 0, 0
        .byte 3, 1, 0
        .byte 3, 0, 0
        .byte 3, 1, 0
        .byte 3, 0, 0
        .byte 3, 1, 0
        .byte 3, 0, 0
        .byte 3, 8, 0
        .byte 3, 0, 0
        .byte 3, 8, 0
        .byte 3, 0, 0
        .byte 3, 8, 0
        .byte 3, 0, 0
        .byte 3, 8, 0
        .byte 3, 0, 0
        .byte 3, 0, 1
        .byte 3, 0, 0
        .byte 120, 0, 0
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
        .byte 60, 0, 0
        .byte 0
