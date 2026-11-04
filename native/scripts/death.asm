;Test script: as fight.asm, but against a Wolf (enemy 20), far too strong:
;the hero dies, and is back before the King in the throne room (map 3),
;HP full, gold halved (0).
;Entries: frames, directions (1 up, 2 right, 4 down, 8 left), buttons
;(1 lower fire, 2 upper).
;FIGHT: 20
;EXPECT-BYTE: MapId 3
;EXPECT-BYTE: HitPoints 15
;EXPECT-BYTE: BattleOn 0

Script:
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
