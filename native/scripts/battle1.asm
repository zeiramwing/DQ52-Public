;Test script: from (43,44) a step left on the overworld, a fight with a
;Slime (enemy 0); stop on its command window: the battle rows show the
;Slime, the dialog window with its arrival message, the command prompt.
;Entries: frames, directions (1 up, 2 right, 4 down, 8 left), buttons
;(1 lower fire, 2 upper).
;FIGHT: 0
;EXPECT-MSG: 226
;EXPECT: FIGHT   SPELL
;EXPECT-BYTE: BattleOn 1
;EXPECT-BYTE: Song 14

Script:
        .byte 4, 8, 0
        .byte 160, 0, 0
        .byte 0
