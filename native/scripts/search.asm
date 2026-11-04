;Test script: stand, open the command window, move the cursor down three
;rows to SEARCH (and right and back left), choose it: the first message
;(the search message, the hero's name in it) waits for a button, the second
;(the nothing-found message) follows it.
;Entries: frames, directions (1 up, 2 right, 4 down, 8 left), buttons
;(1 lower fire, 2 upper).
;EXPECT-MSG: 210
;EXPECT-MSG: 211
;EXPECT: HP  15
;EXPECT-BYTE: Song 5
;EXPECT-BYTE: Tempo 150

Script:
        .byte 40, 0, 0
        .byte 5, 0, 1
        .byte 10, 0, 0
        .byte 5, 4, 0
        .byte 5, 0, 0
        .byte 5, 4, 0
        .byte 5, 0, 0
        .byte 5, 2, 0
        .byte 5, 0, 0
        .byte 5, 8, 0
        .byte 5, 0, 0
        .byte 5, 4, 0
        .byte 10, 0, 0
        .byte 5, 0, 1
        .byte 90, 0, 0
        .byte 5, 0, 1
        .byte 60, 0, 0
        .byte 0
