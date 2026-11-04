;Test script: in Erdrick's armor (equipment 28) and 5 HP short of the most
;(15, so 10): four steps on the overworld, 1 HP back each: 14.
;Entries: frames, directions (1 up, 2 right, 4 down, 8 left), buttons
;(1 lower fire, 2 upper).
;EQUIP: 28
;HURT: 5
;FIGHT: 254
;EXPECT-BYTE: HitPoints 14

Script:
        .byte 4, 8, 0
        .byte 20, 0, 0
        .byte 4, 2, 0
        .byte 20, 0, 0
        .byte 4, 8, 0
        .byte 20, 0, 0
        .byte 4, 2, 0
        .byte 20, 0, 0
        .byte 0
