;Test script: stand, open the command window, move the cursor right (to
;SPELL) and down (to ITEM), and stop with the window up.
;Entries: frames, directions (1 up, 2 right, 4 down, 8 left), buttons
;(1 lower fire, 2 upper).
;EXPECT: >ITEM
;EXPECT: COMMAND
;EXPECT: TALK    SPELL
;EXPECT: HP  15

Script:
        .byte 40, 0, 0
        .byte 5, 0, 1
        .byte 10, 0, 0
        .byte 5, 2, 0
        .byte 5, 0, 0
        .byte 5, 4, 0
        .byte 20, 0, 0
        .byte 0
