;Test script: on the overworld without the rainbow bridge (ModFlags 0): no
;bridge row (BridgeY $FF), and nothing written past the bridge row's RAM
;(SetBridge once fell into its copy loop and wrote a stray byte into the
;hero's player, $0C5F).
;Entries: frames, directions (1 up, 2 right, 4 down, 8 left), buttons
;(1 lower fire, 2 upper).
;FIGHT: 254
;EXPECT-BYTE: BridgeY 255
;EXPECT-BYTE: Mode 0

Script:
        .byte 30, 0, 0
        .byte 0
