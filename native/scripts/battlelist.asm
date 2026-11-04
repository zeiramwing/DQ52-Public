;Test script: a level 10 hero, a fight with a Slime: SPELL (right in the
;battle's command window): the spells known in the list window over the
;scene, left up.
;Entries: frames, directions (1 up, 2 right, 4 down, 8 left), buttons
;(1 lower fire, 2 upper).
;LEVEL: 10
;FIGHT: 0
;EXPECT: HEAL
;EXPECT: STOPSPELL
;EXPECT-BYTE: ListOn 1
;EXPECT-BYTE: BattleOn 1

Script:
        .byte 4, 8, 0
        .byte 120, 0, 0
        .byte 5, 2, 0
        .byte 5, 0, 0
        .byte 5, 0, 1
        .byte 30, 0, 0
        .byte 0
