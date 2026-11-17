;Test script: as castlein, with the fades between maps the play build has
;(;FADE): a step up onto the Dragonlord's castle, the island faded out and
;the castle's ground floor faded in (PalFadeOut, PalFadeIn): there, lit,
;the fade done (FadeSub 0), no frames counted missed.
;Entries: frames, directions (1 up, 2 right, 4 down, 8 left), buttons
;(1 lower fire, 2 upper).
;START: 0,48,49
;FIGHT: 254
;FADE
;EXPECT-BYTE: MapId 20
;EXPECT-BYTE: HeroX 10
;EXPECT-BYTE: HeroY 19
;EXPECT-BYTE: FadeSub 0
;EXPECT-ZERO: Missed

Script:
        .byte 4, 1, 0
        .byte 120, 0, 0
        .byte 0
