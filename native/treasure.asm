;Doors and treasure chests: the DOOR and TAKE commands, a magic key used,
;SEARCH on a chest (the game's CheckDoor, DoTake and GetTreasure on).
;
;A town's map is a copy in RAM (TownMap) while the hero is in it, so an
;opened door or a taken chest becomes floor there; the next visit copies
;the map from the cartridge again, and they are back, as in the game.

.alias BLK_CHEST        $0C     ;The game's block numbers.
.alias BLK_DOOR         $11     ;
.alias BLK_FLOOR        $04     ;What an opened door or a taken chest is.
.alias SFX_CHEST        $93     ;
.alias SFX_DOOR         $94     ;
.alias ERDRICK_SWORD    $E0     ;The equipment byte's weapon bits for it.
.alias TRSR_HERB        $02     ;What a chest holds (TreasureTbl):
.alias TRSR_KEY         $03     ;
.alias TRSR_NCK         $0E     ;the death necklace, or gold,
.alias TRSR_ERSD        $11     ;Erdrick's sword,
.alias TRSR_GLD1        $12     ;gold ($12-$16),
.alias TRSR_TBLT        $17     ;Erdrick's tablet; below $11 an item
                                ;(its ITM_ code + 3).

;A = the block under or next to the hero at (BX, BY) is A: C set. X kept.
BlockIs:
        STA ShopTmpN            ;
        JSR GetBlock            ;
        CMP ShopTmpN            ;
        BEQ +                   ;
        CLC                     ;
        RTS                     ;
*       SEC                     ;
        RTS                     ;

;Block (BX, BY) of the town becomes A (in TownMap), and is drawn again.
SetBlock:
        PHA                     ;
        JSR GetBlock            ;(MapPtr: its row.)
        PLA                     ;
        LDY BX                  ;
        STA (MapPtr),Y          ;
        LDA #$01                ;
        STA Count               ;
        JMP DrawRowPart         ;

;--------------------------------------[DOOR]--------------------------------------------------------

;A door above, below, left or right of the hero (as the game looks): with
;a key, it opens (the key used up); without, or with none there, the
;game's message.
DoorCommand:
        LDX #$00                ;
DoorLook:
        LDA HeroX               ;
        CLC                     ;
        ADC DoorDX,X            ;
        STA BX                  ;
        LDA HeroY               ;
        CLC                     ;
        ADC DoorDY,X            ;
        STA BY                  ;
        LDA #BLK_DOOR           ;
        JSR BlockIs             ;
        BCS DoorFound           ;
        INX                     ;
        CPX #$04                ;
        BNE DoorLook            ;
        LDA #<MsgDoor           ;No door beside the hero.
        LDY #>MsgDoor           ;
        JMP SayList             ;
DoorFound:
        LDA Keys                ;
        BNE +                   ;
        LDA #<MsgNoKey          ;No key to use.
        LDY #>MsgNoKey          ;
        JMP SayList             ;
*       DEC Keys                ;
        LDA #BLK_FLOOR          ;
        JSR SetBlock            ;
        LDA #SFX_DOOR           ;
        JSR PlaySFX             ;
        LDA #$00                ;Back to walking.
        STA Mode                ;
        RTS                     ;

DoorDX:         .byte 0, 0, $FF, 1
DoorDY:         .byte $FF, 1, 0, 0
MsgNoKey:       .word $010C, $FFFF

;Open the dialog window with message list A (low), Y (high).
SayList:
        STA MsgList             ;
        STY MsgList+1           ;
        JMP OpenDialog          ;

;--------------------------------------[TAKE]--------------------------------------------------------

;A chest under the hero: what TreasureTbl has there, the chest gone.
TakeCommand:
        LDA HeroX               ;
        STA BX                  ;
        LDA HeroY               ;
        STA BY                  ;
        LDA #BLK_CHEST          ;
        JSR BlockIs             ;
        BCC TakeNothing         ;
        JSR SelectMsg           ;(The chests' tables' bank.)
        LDX #NUM_CHESTS-1       ;Which: the map's, at the hero's place.
TakeFind:
        LDA ChestMap,X          ;
        CMP MapId               ;
        BNE +                   ;
        LDA ChestX,X            ;
        CMP HeroX               ;
        BNE +                   ;
        LDA ChestY,X            ;
        CMP HeroY               ;
        BEQ TakeFound           ;
*       DEX                     ;
        BPL TakeFind            ;
TakeNothing:
        LDA #$D7                ;No chest under the hero.
        LDX #$00                ;
        JMP ShopOpen            ;
TakeFound:
        LDA ChestWhat,X         ;
        CMP #TRSR_KEY           ;
        BNE TakeHerb            ;
        LDA #KEY_ITEM           ;A key (6 at most).
        STA ItemName            ;
        LDA Keys                ;
        CMP #$06                ;
        BCS TakeEmpty           ;
        INC Keys                ;
        JMP TakeItemSaid        ;
TakeHerb:
        CMP #TRSR_HERB          ;
        BNE TakeNeck            ;
        LDA #HERB_ITEM          ;An herb (6 at most).
        STA ItemName            ;
        LDA Herbs               ;
        CMP #$06                ;
        BCS TakeEmpty           ;
        INC Herbs               ;
        JMP TakeItemSaid        ;
TakeNeck:
        CMP #TRSR_NCK           ;The death necklace: 1 in 32 (once found,
        BNE TakeSword           ;gold): else gold.
        JSR NextRandom          ;
        LDA Random+1            ;
        AND #$1F                ;
        BNE TakeGold            ;
        LDA #TRSR_NCK           ;
        BNE TakeItem            ;
TakeSword:
        CMP #TRSR_ERSD          ;Erdrick's sword: wielded.
        BNE TakeGoldTypes       ;
        LDA Equipped            ;
        AND #ERDRICK_SWORD      ;
        CMP #ERDRICK_SWORD      ;
        BEQ TakeEmpty           ;
        LDA Equipped            ;
        ORA #ERDRICK_SWORD      ;
        STA Equipped            ;
        LDA #6                  ;
        STA ItemName            ;
        JMP TakeItemSaid        ;
TakeGoldTypes:
        BCS TakeGold            ;From $12 on: gold (the tablet aside).
TakeItem:
        SEC                     ;An item: its ITM_ code is what less 3.
        SBC #$03                ;
        PHA                     ;
        CLC                     ;
        ADC #ITM_BASE           ;
        STA ItemName            ;
        PLA                     ;
        STA DsItem              ;
        JSR AddItem             ;
        BCC TakeItemSaid        ;
        JSR TakeChest           ;Full: found, and then something must go
        LDA #$D9                ;(DiscardItem).
        LDX #DS_ASK             ;
        JMP ShopOpen            ;
TakeItemSaid:
        JSR TakeChest           ;The find's message (its name inserted)
        LDA #$D9                ;found the Herb.
        LDX #$00                ;
        JMP ShopOpen            ;
TakeEmpty:
        JSR TakeChest           ;The empty chest's message.
        LDA #$DA                ;
        LDX #$00                ;
        JMP ShopOpen            ;

;Gold: the kind's base and a random part (GetTrsrGold): the necklace's
;100 + 0-31; $12 5 + 0-15, $13 6 + 0-7, $14 10 + 0-7, $15 500 + 0-255, $16
;120. Erdrick's tablet: found, and it reads as it does (ChkTrsrErdTablet).
TakeGold:
        LDA ChestWhat,X         ;
        CMP #TRSR_TBLT          ;
        BNE TakeGoldKind        ;
        JSR TakeChest           ;
        LDA #TABLET_ITEM        ;Found: the tablet,
        STA ItemName            ;
        LDA #$D9                ;
        LDX #TB_READ            ;
        JMP ShopOpen            ;
StepTbRead:
        LDA #$03                ;and it reads (high message 3).
        LDX #$00                ;
        JSR ShopHi              ;
        JMP NextMessage         ;
TakeGoldKind:
        LDY #$05                ;The necklace's entry.
        CMP #TRSR_NCK           ;
        BEQ +                   ;
        SEC                     ;
        SBC #TRSR_GLD1          ;
        TAY                     ;
*       JSR NextRandom          ;
        LDA Random+1            ;
        AND GoldBits,Y          ;
        CLC                     ;
        ADC GoldLo,Y            ;
        STA Amount              ;
        LDA GoldHi,Y            ;
        ADC #$00                ;
        STA Amount+1            ;
        LDA Gold                ;
        CLC                     ;
        ADC Amount              ;
        STA Gold                ;
        LDA Gold+1              ;
        ADC Amount+1            ;
        STA Gold+1              ;
        BCC +                   ;
        LDA #$FF                ;(At most 65535.)
        STA Gold                ;
        STA Gold+1              ;
*       JSR TakeChest           ;
        JSR RedrawStatus        ;
        LDA #$D8                ;The gold found (its amount inserted).
        LDX #$00                ;
        JMP ShopOpen            ;

GoldLo:         .byte 5, 6, 10, <500, 120, 100
GoldHi:         .byte 0, 0, 0, >500, 0, 0
GoldBits:       .byte $0F, $07, $07, $FF, $00, $1F

;The chest under the hero gone: floor, with the game's sound.
TakeChest:
        LDA HeroX               ;
        STA BX                  ;
        LDA HeroY               ;
        STA BY                  ;
        LDA #BLK_FLOOR          ;
        JSR SetBlock            ;
        LDA #SFX_CHEST          ;
        JMP PlaySFX             ;

;--------------------------------------[SEARCH]------------------------------------------------------

;SEARCH: on a chest, the chest-found message; else nothing found.
SearchCommand:
        JSR SearchCastle        ;The castle's throne (castle.asm).
        BCC +                   ;
        RTS                     ;
*       LDA HeroX               ;
        STA BX                  ;
        LDA HeroY               ;
        STA BY                  ;
        LDA #BLK_CHEST          ;
        JSR BlockIs             ;
        LDA #<MsgSearch         ;
        LDY #>MsgSearch         ;
        BCC +                   ;
        LDA #<MsgSearchChest    ;
        LDY #>MsgSearchChest    ;
*       JMP SayList             ;

MsgSearchChest: .word $00D2, $00D4, $FFFF ;The search, and a chest found there.

;DsItem: the ITM_ code found; DsDrop: the item to drop (the steps are in
;poweron.asm: the step runner enters MSG_BANK for them).
.alias DsItem           $07AD   ;
.alias DsDrop           $07AE   ;
