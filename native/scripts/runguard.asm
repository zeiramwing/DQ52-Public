;Test script: a level 30 hero steps onto the axe knight's block in
;Hauksness (18,12), where Erdrick's armor lies, and RUNs: away, he is put
;a block back to the left (as the game does: else he could search the
;block with the knight never beaten), the town loaded again around him.
;Entries: frames, directions (1 up, 2 right, 4 down, 8 left), buttons
;(1 lower fire, 2 upper).
;START: 28,17,12
;FIGHT: 254
;LEVEL: 30
;SEED: 1
;EXPECT-BYTE: BattleOn 0
;EXPECT-BYTE: HeroX 17
;EXPECT-BYTE: HeroY 12
;EXPECT-BYTE: MapId 28

Script:
        .byte 20, 0, 0
        .byte 4, 2, 0
        .byte 150, 0, 0
        .byte 6, 4, 0
        .byte 10, 0, 0
        .byte 5, 0, 1
        .byte 200, 0, 0
        .byte 0
