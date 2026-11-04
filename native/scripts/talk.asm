;Test script: stand (the status window opens), the lower fire button (the
;command window), again (TALK), and wait while the message prints.
;Entries: frames, directions (1 up, 2 right, 4 down, 8 left), buttons
;(1 lower fire, 2 upper).
;EXPECT-MSG: 15
;EXPECT: HP  15

Script:
        .byte 40, 0, 0
        .byte 5, 0, 1
        .byte 20, 0, 0
        .byte 5, 0, 1
        .byte 80, 0, 0
        .byte 0
