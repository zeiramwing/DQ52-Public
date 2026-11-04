;Test script: a level 10 hero on the overworld: SPELL (right in the
;command window): the list window holds the spells known with their MP;
;HEAL chosen: the chant with its name, 4 MP paid (HP already full).
;Entries: frames, directions (1 up, 2 right, 4 down, 8 left), buttons
;(1 lower fire, 2 upper).
;LEVEL: 10
;FIGHT: 254
;EXPECT: HEAL
;EXPECT-BYTE: MagicPoints 36
;EXPECT-BYTE: HitPoints 54

Script:
        .byte 40, 0, 0
        .byte 5, 0, 1
        .byte 10, 0, 0
        .byte 5, 2, 0
        .byte 5, 0, 0
        .byte 5, 0, 1
        .byte 20, 0, 0
        .byte 5, 0, 1
        .byte 90, 0, 0
        .byte 0
