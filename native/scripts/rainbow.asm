;Test script: on the overworld at (65,49), east of the water before the
;Dragonlord's island, with the rainbow drop: ITEM (down, right), the drop
;held up (a button after its message): the rainbow bridge built at (64,49), with its tune; then two
;steps left, over the bridge.
;Entries: frames, directions (1 up, 2 right, 4 down, 8 left), buttons
;(1 lower fire, 2 upper).
;START: 0,65,49
;FIGHT: 254
;ITEM: 14
;EXPECT-BYTE: ModFlags 8
;EXPECT-BYTE: BridgeY 49
;EXPECT-BYTE: HeroX 63
;EXPECT-BYTE: Mode 0

Script:
        .byte 20, 0, 0
        .byte 5, 0, 1
        .byte 10, 0, 0
        .byte 4, 4, 0
        .byte 5, 0, 0
        .byte 4, 2, 0
        .byte 5, 0, 0
        .byte 5, 0, 1
        .byte 20, 0, 0
        .byte 5, 0, 1
        .byte 100, 0, 0
        .byte 5, 0, 1
        .byte 250, 0, 0
        .byte 4, 8, 0
        .byte 30, 0, 0
        .byte 4, 8, 0
        .byte 40, 0, 0
        .byte 0
