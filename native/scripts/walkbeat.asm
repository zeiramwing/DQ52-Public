;Test script: walking from standing as the game does (;WALK-BEAT, as the
;play build): on the overworld at (43,44), left held 16 frames: one step,
;taken on the game's 16-frame beat; then right tapped for a frame: the hero
;turns to face right, but does not step (a step from standing waits for the
;beat, the direction still held). Facing 1 is right.
;Entries: frames, directions (1 up, 2 right, 4 down, 8 left), buttons
;(1 lower fire, 2 upper).
;FIGHT: 254
;WALK-BEAT
;EXPECT-BYTE: HeroX 42
;EXPECT-BYTE: Facing 1
;EXPECT-BYTE: Moving 0

Script:
        .byte 60, 0, 0
        .byte 16, 8, 0
        .byte 40, 0, 0
        .byte 1, 2, 0
        .byte 40, 0, 0
        .byte 0
