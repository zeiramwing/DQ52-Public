;Test script: a level 30 hero in Erdrick's sword, armor and shield (255)
;right of the Dragonlord: TALK, his offer refused (the upper button), the
;fight: FIGHT each round (the lower button every second) through his
;first form and his second; his end, then outside his castle, on the
;overworld, the Dragonlord dead (ModFlags bit 5).
;Entries: frames, directions (1 up, 2 right, 4 down, 8 left), buttons
;(1 lower fire, 2 upper). Each battle's luck from a fixed seed (;SEED): a
;level 30 hero who only fights wins about half his fights with the
;Dragonlord, so the result would turn on any timing elsewhere.
;START: 21,17,24
;LEVEL: 30
;EQUIP: 255
;FIGHT: 254
;SEED: 48879
;EXPECT-BYTE: MapId 0
;EXPECT-BYTE: ModFlags 32
;EXPECT-BYTE: BattleOn 0

Script:
        .byte 21, 0, 0
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
        .byte 5, 0, 1
        .byte 60, 0, 0
        .byte 5, 0, 1
        .byte 60, 0, 0
        .byte 5, 0, 1
        .byte 60, 0, 0
        .byte 5, 0, 1
        .byte 60, 0, 0
        .byte 5, 0, 1
        .byte 60, 0, 0
        .byte 5, 0, 1
        .byte 60, 0, 0
        .byte 5, 0, 1
        .byte 60, 0, 0
        .byte 5, 0, 1
        .byte 60, 0, 0
        .byte 5, 0, 1
        .byte 60, 0, 0
        .byte 5, 0, 1
        .byte 60, 0, 0
        .byte 5, 0, 1
        .byte 60, 0, 0
        .byte 5, 0, 1
        .byte 60, 0, 0
        .byte 5, 0, 1
        .byte 60, 0, 0
        .byte 5, 0, 1
        .byte 60, 0, 0
        .byte 5, 0, 1
        .byte 60, 0, 0
        .byte 5, 0, 1
        .byte 60, 0, 0
        .byte 5, 0, 1
        .byte 60, 0, 0
        .byte 5, 0, 1
        .byte 60, 0, 0
        .byte 5, 0, 1
        .byte 60, 0, 0
        .byte 5, 0, 1
        .byte 60, 0, 0
        .byte 5, 0, 1
        .byte 60, 0, 0
        .byte 5, 0, 1
        .byte 60, 0, 0
        .byte 5, 0, 1
        .byte 60, 0, 0
        .byte 5, 0, 1
        .byte 60, 0, 0
        .byte 5, 0, 1
        .byte 60, 0, 0
        .byte 5, 0, 1
        .byte 60, 0, 0
        .byte 5, 0, 1
        .byte 60, 0, 0
        .byte 5, 0, 1
        .byte 60, 0, 0
        .byte 5, 0, 1
        .byte 60, 0, 0
        .byte 5, 0, 1
        .byte 60, 0, 0
        .byte 5, 0, 1
        .byte 60, 0, 0
        .byte 5, 0, 1
        .byte 60, 0, 0
        .byte 5, 0, 1
        .byte 60, 0, 0
        .byte 5, 0, 1
        .byte 60, 0, 0
        .byte 5, 0, 1
        .byte 60, 0, 0
        .byte 5, 0, 1
        .byte 60, 0, 0
        .byte 5, 0, 1
        .byte 60, 0, 0
        .byte 5, 0, 1
        .byte 60, 0, 0
        .byte 5, 0, 1
        .byte 60, 0, 0
        .byte 5, 0, 1
        .byte 60, 0, 0
        .byte 5, 0, 1
        .byte 60, 0, 0
        .byte 5, 0, 1
        .byte 60, 0, 0
        .byte 5, 0, 1
        .byte 60, 0, 0
        .byte 5, 0, 1
        .byte 60, 0, 0
        .byte 5, 0, 1
        .byte 60, 0, 0
        .byte 5, 0, 1
        .byte 60, 0, 0
        .byte 5, 0, 1
        .byte 60, 0, 0
        .byte 5, 0, 1
        .byte 60, 0, 0
        .byte 5, 0, 1
        .byte 60, 0, 0
        .byte 5, 0, 1
        .byte 60, 0, 0
        .byte 5, 0, 1
        .byte 60, 0, 0
        .byte 5, 0, 1
        .byte 60, 0, 0
        .byte 5, 0, 1
        .byte 60, 0, 0
        .byte 5, 0, 1
        .byte 60, 0, 0
        .byte 5, 0, 1
        .byte 60, 0, 0
        .byte 5, 0, 1
        .byte 60, 0, 0
        .byte 5, 0, 1
        .byte 60, 0, 0
        .byte 5, 0, 1
        .byte 60, 0, 0
        .byte 5, 0, 1
        .byte 60, 0, 0
        .byte 5, 0, 1
        .byte 60, 0, 0
        .byte 5, 0, 1
        .byte 60, 0, 0
        .byte 5, 0, 1
        .byte 60, 0, 0
        .byte 5, 0, 1
        .byte 60, 0, 0
        .byte 5, 0, 1
        .byte 60, 0, 0
        .byte 5, 0, 1
        .byte 60, 0, 0
        .byte 5, 0, 1
        .byte 60, 0, 0
        .byte 5, 0, 1
        .byte 60, 0, 0
        .byte 5, 0, 1
        .byte 60, 0, 0
        .byte 5, 0, 1
        .byte 60, 0, 0
        .byte 5, 0, 1
        .byte 60, 0, 0
        .byte 0
