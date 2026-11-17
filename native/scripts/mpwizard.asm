;Test script: in Tantegel at (18,26), across the counter from the wizard
;who gives MP back, a level 5 hero 6 MP short (14 of 20): the stick right (the
;counter: he only turns to it), TALK (the keypad's 1): his words, the
;screen grey and back (FX_SPELL, as the game's BWScreenFlash), and all
;the hero's MP back.
;Entries: frames, directions (1 up, 2 right, 4 down, 8 left), buttons
;(1 lower fire, 2 upper; the high half a keypad key: $F0 key 1).
;START: 1,18,26
;LEVEL: 5
;DRAIN: 6
;FIGHT: 254
;EXPECT-BYTE: MagicPoints 20
;EXPECT-BYTE: MaxMP 20
;EXPECT-BYTE: FxKind 4

Script:
        .byte 20, 0, 0
        .byte 4, 2, 0
        .byte 10, 0, 0
        .byte 4, 0, $F0
        .byte 150, 0, 0
        .byte 0
