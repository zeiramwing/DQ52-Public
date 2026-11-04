;Test script: in the Dragonlord's floor right of him at (17,24): a step
;left (he is there: the hero turns to him), TALK: his offer, refused (the
;upper button: NO, and on through his messages): the fight with him.
;Entries: frames, directions (1 up, 2 right, 4 down, 8 left), buttons
;(1 lower fire, 2 upper).
;START: 21,17,24
;LEVEL: 20
;FIGHT: 254
;EXPECT-BYTE: BattleOn 1
;EXPECT-BYTE: Enemy 38

Script:
        .byte 20, 0, 0
        .byte 4, 8, 0
        .byte 30, 0, 0
        .byte 5, 0, 1
        .byte 10, 0, 0
        .byte 5, 0, 1
        .byte 120, 0, 0
        .byte 5, 0, 2
        .byte 120, 0, 0
        .byte 5, 0, 2
        .byte 120, 0, 0
        .byte 5, 0, 2
        .byte 120, 0, 0
        .byte 5, 0, 2
        .byte 120, 0, 0
        .byte 5, 0, 2
        .byte 120, 0, 0
        .byte 5, 0, 2
        .byte 150, 0, 0
        .byte 0
