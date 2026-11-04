;Test script: on Tantegel's ground floor: any map but the throne room, so
;the throne room is left (Flags2 bit 1, the game's F_LEFT_THROOM): its
;chests and door gone the next time it loads.
;Entries: frames, directions (1 up, 2 right, 4 down, 8 left), buttons
;(1 lower fire, 2 upper).
;START: 1,7,8
;FIGHT: 254
;EXPECT-BYTE: Flags2 2

Script:
        .byte 20, 0, 0
        .byte 0
