;Test script: a level 1 hero fights a Slime (enemy 0), the battle's luck
;seeded so his first blow takes 2 HP off it: the message's number and the
;period after it go to the next line together, as the game measures a word
;(the number measured alone left the period on a line of its own).
;Entries: frames, directions (1 up, 2 right, 4 down, 8 left), buttons
;(1 lower fire, 2 upper).
;FIGHT: 0
;SEED: 777
;EXPECT: 2.

Script:
        .byte 250, 0, 0
        .byte 50, 0, 0
        .byte 4, 8, 0
        .byte 60, 0, 0
        .byte 5, 0, 1
        .byte 55, 0, 0
        .byte 5, 0, 1
        .byte 120, 0, 0
        .byte 0
