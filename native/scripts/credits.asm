;Test script: as ending, then the end credits (read from the ROM): the
;end music's first part, then the first screen: the people and the hero
;gone, the view blank but the credits' rows; on through the screens to the
;last, each faded in and out (the last only in), which stays (CrPtr at
;its end, $FE: the 1055 bytes build.py makes of the ROM's credits).
;Entries: frames, directions (1 up, 2 right, 4 down, 8 left), buttons
;(1 lower fire, 2 upper).
;START: 1,10,9
;FLAGS: 32
;FIGHT: 254
;EXPECT-BYTE: ShopState 64
;EXPECT-BYTE: CrOn 1
;EXPECT-BYTE: CrPhase 0
;EXPECT-BYTE: FadeSub 0
;EXPECT-BYTE: CrPtr 30
;EXPECT-BYTE: PeopleOn 0
;EXPECT-BYTE: Mode 4

Script:
        .byte 20, 0, 0
        .byte 4, 1, 0
        .byte 40, 0, 0
        .byte 200, 0, 0
        .byte 5, 0, 1
        .byte 200, 0, 0
        .byte 5, 0, 1
        .byte 200, 0, 0
        .byte 5, 0, 1
        .byte 200, 0, 0
        .byte 5, 0, 1
        .byte 200, 0, 0
        .byte 5, 0, 1
        .byte 200, 0, 0
        .byte 5, 0, 1
        .byte 200, 0, 0
        .byte 5, 0, 1
        .byte 200, 0, 0
        .byte 5, 0, 1
        .byte 200, 0, 0
        .byte 5, 0, 1
        .byte 200, 0, 0
        .byte 5, 0, 1
        .byte 200, 0, 0
        .byte 5, 0, 1
        .byte 200, 0, 0
        .byte 5, 0, 1
        .byte 200, 0, 0
        .byte 5, 0, 1
        .byte 200, 0, 0
        .byte 5, 0, 1
        .byte 255, 0, 0
        .byte 255, 0, 0
        .byte 255, 0, 0
        .byte 255, 0, 0
        .byte 255, 0, 0
        .byte 255, 0, 0
        .byte 255, 0, 0
        .byte 255, 0, 0
        .byte 255, 0, 0
        .byte 255, 0, 0
        .byte 255, 0, 0
        .byte 255, 0, 0
        .byte 255, 0, 0
        .byte 255, 0, 0
        .byte 255, 0, 0
        .byte 255, 0, 0
        .byte 255, 0, 0
        .byte 255, 0, 0
        .byte 255, 0, 0
        .byte 255, 0, 0
        .byte 255, 0, 0
        .byte 255, 0, 0
        .byte 255, 0, 0
        .byte 255, 0, 0
        .byte 0
