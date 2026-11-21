;Test script: the new hero puts the cursed belt on (the item window, as
;cursegate), then steps left into a fight with a Wolf (enemy 20), far too
;strong, and dies: cursed, he is sent outside Tantegel, not to the King,
;and wakes with 1 HP (the game's StartAtThroneRoom), not full.
;Entries: frames, directions (1 up, 2 right, 4 down, 8 left), buttons
;(1 lower fire, 2 upper).
;ITEM: 9
;FIGHT: 20
;EXPECT-BYTE: MapId 0
;EXPECT-BYTE: HitPoints 1
;EXPECT-BYTE: BattleOn 0

Script:
        .byte 20, 0, 0
        .byte 5, 0, 1
        .byte 10, 0, 0
        .byte 4, 4, 0
        .byte 5, 0, 0
        .byte 4, 2, 0
        .byte 5, 0, 0
        .byte 5, 0, 1
        .byte 20, 0, 0
        .byte 5, 0, 1
        .byte 120, 0, 0
        .byte 5, 0, 1
        .byte 250, 0, 0
        .byte 4, 8, 0
        .byte 60, 0, 0
        .byte 5, 0, 1
        .byte 55, 0, 0
        .byte 5, 0, 1
        .byte 55, 0, 0
        .byte 5, 0, 1
        .byte 55, 0, 0
        .byte 5, 0, 1
        .byte 55, 0, 0
        .byte 5, 0, 1
        .byte 55, 0, 0
        .byte 5, 0, 1
        .byte 55, 0, 0
        .byte 5, 0, 1
        .byte 55, 0, 0
        .byte 5, 0, 1
        .byte 55, 0, 0
        .byte 5, 0, 1
        .byte 55, 0, 0
        .byte 5, 0, 1
        .byte 55, 0, 0
        .byte 5, 0, 1
        .byte 55, 0, 0
        .byte 5, 0, 1
        .byte 55, 0, 0
        .byte 5, 0, 1
        .byte 55, 0, 0
        .byte 5, 0, 1
        .byte 55, 0, 0
        .byte 5, 0, 1
        .byte 55, 0, 0
        .byte 5, 0, 1
        .byte 55, 0, 0
        .byte 5, 0, 1
        .byte 55, 0, 0
        .byte 5, 0, 1
        .byte 55, 0, 0
        .byte 5, 0, 1
        .byte 55, 0, 0
        .byte 5, 0, 1
        .byte 55, 0, 0
        .byte 5, 0, 1
        .byte 55, 0, 0
        .byte 5, 0, 1
        .byte 55, 0, 0
        .byte 5, 0, 1
        .byte 55, 0, 0
        .byte 5, 0, 1
        .byte 55, 0, 0
        .byte 5, 0, 1
        .byte 55, 0, 0
        .byte 5, 0, 1
        .byte 55, 0, 0
        .byte 5, 0, 1
        .byte 55, 0, 0
        .byte 5, 0, 1
        .byte 55, 0, 0
        .byte 5, 0, 1
        .byte 55, 0, 0
        .byte 5, 0, 1
        .byte 55, 0, 0
        .byte 5, 0, 1
        .byte 55, 0, 0
        .byte 5, 0, 1
        .byte 55, 0, 0
        .byte 5, 0, 1
        .byte 55, 0, 0
        .byte 5, 0, 1
        .byte 55, 0, 0
        .byte 5, 0, 1
        .byte 55, 0, 0
        .byte 5, 0, 1
        .byte 55, 0, 0
        .byte 5, 0, 1
        .byte 55, 0, 0
        .byte 5, 0, 1
        .byte 55, 0, 0
        .byte 5, 0, 1
        .byte 55, 0, 0
        .byte 5, 0, 1
        .byte 55, 0, 0
        .byte 0
