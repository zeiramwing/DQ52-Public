;Test script: a level 20 hero in the Dragonlord's floor at (17,24), where
;every step starts a fight with a Slime: a step right, the fight (on black,
;the Dragonlord out of sight), FIGHT until it is won: the floor lit again,
;the Dragonlord back.
;Entries: frames, directions (1 up, 2 right, 4 down, 8 left), buttons
;(1 lower fire, 2 upper).
;START: 21,17,24
;LEVEL: 20
;FIGHT: 0
;EXPECT-BYTE: BattleOn 0
;EXPECT-BYTE: Dark 0
;EXPECT-BYTE: LightW 1
;EXPECT-BYTE: PeopleOn 1
;EXPECT-BYTE: Experience 1

Script:
        .byte 20, 0, 0
        .byte 4, 2, 0
        .byte 60, 0, 0
        .byte 5, 0, 1
        .byte 70, 0, 0
        .byte 5, 0, 1
        .byte 70, 0, 0
        .byte 5, 0, 1
        .byte 70, 0, 0
        .byte 5, 0, 1
        .byte 70, 0, 0
        .byte 5, 0, 1
        .byte 70, 0, 0
        .byte 5, 0, 1
        .byte 70, 0, 0
        .byte 5, 0, 1
        .byte 70, 0, 0
        .byte 5, 0, 1
        .byte 70, 0, 0
        .byte 5, 0, 1
        .byte 70, 0, 0
        .byte 0
