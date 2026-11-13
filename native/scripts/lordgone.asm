;Test script: the Dragonlord dead (ModFlags 32), on his floor right of
;where he stood (17,24): he is not there (his block the floor under him:
;CondPeople), and TALK to his place starts no fight.
;Entries: frames, directions (1 up, 2 right, 4 down, 8 left), buttons
;(1 lower fire, 2 upper).
;START: 21,17,24
;FLAGS: 32
;FIGHT: 254
;EXPECT-BYTE: BattleOn 0
;EXPECT-BYTE: ShopState 0

Script:
        .byte 20, 0, 0
        .byte 4, 8, 0
        .byte 30, 0, 0
        .byte 5, 0, 1
        .byte 10, 0, 0
        .byte 5, 0, 1
        .byte 60, 0, 0
        .byte 0
