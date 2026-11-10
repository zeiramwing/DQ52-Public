;Test script: as lordwin, a level 30 hero in Erdrick's sword, armor and
;shield (255) right of the Dragonlord: TALK, his offer refused, FIGHT
;through his first form, and stopped in the fight with his second (enemy
;39): his picture on black, its 75 glyphs (63, then 12 from TEXT_END).
;Entries: frames, directions (1 up, 2 right, 4 down, 8 left), buttons
;(1 lower fire, 2 upper).
;START: 21,17,24
;LEVEL: 30
;EQUIP: 255
;FIGHT: 254
;EXPECT-BYTE: Enemy 39
;EXPECT-BYTE: MonGlyphs 75

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
        .byte 0
