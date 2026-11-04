;Test script: the upper fire button held at power-on: the password entry
;window; the password of 1234 gold, 5000 experience, a torch and wings, 3
;keys, 2 herbs, equipment 73 and the bridge's flag (tools/native/password.py
;encode 1234 5000 0x75 0 0 0 3 2 0x49 0x08), entered on its grid with the
;stick and the lower button: the adventure back, before the King, its
;level and stats from the experience (level 12); the King glad the hero
;has returned (the dialog open), the throne room left (Flags2 bit 1).
;Entries: frames, directions (1 up, 2 right, 4 down, 8 left), buttons
;(1 lower fire, 2 upper).
;FIGHT: 254
;EXPECT-BYTE: Gold 210
;EXPECT-BYTE: Experience 136
;EXPECT-BYTE: Equipped 73
;EXPECT-BYTE: Keys 3
;EXPECT-BYTE: Herbs 2
;EXPECT-BYTE: ModFlags 8
;EXPECT-BYTE: MapId 3
;EXPECT-BYTE: Mode 2
;EXPECT-BYTE: DialogOn 1
;EXPECT-BYTE: Flags2 2
;EXPECT-BYTE: Level 12

Script:
        .byte 10, 0, 2
        .byte 20, 0, 0
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
        .byte 0
