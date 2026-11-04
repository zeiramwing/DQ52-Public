;Test script: in Tantegel at its south gate (11,29): a step down, off its
;edge: out onto the overworld before the castle (its first link in, from
;the overworld; not the throne room's stairs, its second).
;Entries: frames, directions (1 up, 2 right, 4 down, 8 left), buttons
;(1 lower fire, 2 upper).
;START: 1,11,29
;FIGHT: 254
;EXPECT-BYTE: MapId 0

Script:
        .byte 20, 0, 0
        .byte 4, 4, 0
        .byte 80, 0, 0
        .byte 0
