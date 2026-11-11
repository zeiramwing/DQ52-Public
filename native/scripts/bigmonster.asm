;Test script: from (43,44) a step left on the overworld, a fight with enemy
;36, a level 30 hero in Erdrick's gear (255) so that the first round does
;not end it; stop on its command window. Its picture needs more than one
;set's 63 glyphs: its rows from 13 are in a second set (Lower2Set), so
;its shapes are its own, none merged.
;Entries: frames, directions (1 up, 2 right, 4 down, 8 left), buttons
;(1 lower fire, 2 upper).
;FIGHT: 36
;LEVEL: 30
;EQUIP: 255
;EXPECT-BYTE: BattleOn 1
;EXPECT-BYTE: MonSplit 13

Script:
        .byte 4, 8, 0
        .byte 160, 0, 0
        .byte 0
