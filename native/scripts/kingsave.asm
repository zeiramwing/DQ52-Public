;Test script: as king.asm, then YES to recording the deeds (and a press
;past their message): the password in its window, until a button (its
;first character as tools/native/password.py has it for a new hero).
;Entries: frames, directions (1 up, 2 right, 4 down, 8 left), buttons
;(1 lower fire, 2 upper).
;START: 1,7,8
;FIGHT: 254
;EXPECT-BYTE: PwChars 28
;EXPECT-BYTE: ShopState 47

Script:
        .byte 4, 1, 0
        .byte 24, 0, 0
        .byte 5, 0, 1
        .byte 10, 0, 0
        .byte 5, 4, 0
        .byte 5, 0, 0
        .byte 5, 4, 0
        .byte 10, 0, 0
        .byte 5, 0, 1
        .byte 30, 0, 0
        .byte 52, 8, 0
        .byte 20, 0, 0
        .byte 52, 1, 0
        .byte 20, 0, 0
        .byte 4, 8, 0
        .byte 20, 0, 0
        .byte 4, 1, 0
        .byte 10, 0, 0
        .byte 5, 0, 1
        .byte 10, 0, 0
        .byte 5, 0, 1
        .byte 90, 0, 0
        .byte 5, 0, 1
        .byte 110, 0, 0
        .byte 5, 0, 1
        .byte 110, 0, 0
        .byte 5, 0, 1
        .byte 200, 0, 0
        .byte 5, 0, 1
        .byte 120, 0, 0
        .byte 0
