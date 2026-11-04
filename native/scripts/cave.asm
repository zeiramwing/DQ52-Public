;Test script: in the rock mountain cave, B1 (a dungeon: dark, the light at
;the hero's block only), with a torch: ITEM (down once, right), the torch:
;the light 3 blocks wide, the torch used up. Then a step left: the light
;goes with the hero.
;(The step is left: below is rock.)
;Entries: frames, directions (1 up, 2 right, 4 down, 8 left), buttons
;(1 lower fire, 2 upper).
;START: 12,6,11
;FIGHT: 254
;ITEM: 1
;EXPECT-BYTE: Dark 1
;EXPECT-BYTE: LightW 3
;EXPECT-BYTE: Inventory 0
;EXPECT-BYTE: Song 6
;EXPECT-BYTE: HeroX 5

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
        .byte 30, 0, 0
        .byte 4, 8, 0
        .byte 40, 0, 0
        .byte 0
