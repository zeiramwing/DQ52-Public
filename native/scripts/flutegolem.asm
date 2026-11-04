;Test script: a level 30 hero with the fairy flute, on the overworld where
;every step starts a fight with the golem (enemy 24): a step left, the
;fight; ITEM (down, right in the battle's command window): the list window
;over the scene, the flute: its tune, and the golem asleep.
;Entries: frames, directions (1 up, 2 right, 4 down, 8 left), buttons
;(1 lower fire, 2 upper).
;LEVEL: 30
;ITEM: 5
;FIGHT: 24
;EXPECT-BYTE: EnSleep 1
;EXPECT-BYTE: BattleOn 1

Script:
        .byte 4, 8, 0
        .byte 150, 0, 0
        .byte 6, 4, 0
        .byte 6, 0, 0
        .byte 6, 2, 0
        .byte 6, 0, 0
        .byte 5, 0, 1
        .byte 30, 0, 0
        .byte 5, 0, 1
        .byte 200, 0, 0
        .byte 0
