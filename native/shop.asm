;Items, shops and inns.
;
;The hero's goods are kept as the game keeps them: the equipment in one
;byte (weapon in bits 5-7, armor 2-4, shield 0-1, each 0 for none), herbs
;and magic keys counted, and 8 more items in 4 bytes, one a nibble (the
;game's ITM_ codes). Items are numbered as the game's ItemCostTbl numbers
;them (items.py): its prices, names and shops' lists use those numbers.
;
;Shops, inns, the key and fairy water sellers (dialog control bytes below
;$16) and the ITEM command are chains of steps, as a battle is (Mode 4):
;each step says a message (ShopSay) or asks YES or NO after one (ShopAsk),
;and names the step to take once it is out; a step can also open the list
;window (a shop's goods and their prices, the hero's items, BUY or SELL),
;the step after it seeing the choice in ListSel ($FF: none). The messages
;and the sums are the game's (Bank03's WeaponsDialog on).
;
;Window text is drawn from set A, which holds only digits, capitals and
;the frame: any other text tile (an item's lower case letters) is copied
;from set B into a code the map's characters leave free (MapFreeCode on,
;then 114-127) the first time it is needed on a map (TileA).

.alias Equipped         $0253   ;Weapon, armor, shield (game state, saved
.alias Keys             $0254   ;with it: NewGame sets them),
.alias Herbs            $0255   ;
.alias Inventory        $0256   ;4: two items a byte,
.alias ModFlags         $025A   ;bit 0: wearing the dragon's scale.

.alias ShopState        $02C0   ;The step to take once the message is out (0: none).
.alias ShopCtl          $02C1   ;The dialog control byte.
.alias ShopIdx          $02C2   ;Its shop.
.alias ItemName         $02C3   ;The item TX_ITEM names.
.alias SelItem          $02C4   ;The item chosen.
.alias PriceLo          $02C5   ;Its price,
.alias PriceHi          $02C6   ;
.alias BuyLo            $02C7   ;and what the shop gives back.
.alias BuyHi            $02C8   ;
.alias ListOn           $02C9   ;Non-zero: the list window is up.
.alias ListCount        $02CA   ;Its rows,
.alias ListSel          $02CB   ;the cursor's (and the choice: $FF none),
.alias ListKind         $02CC   ;0 prices, 1 counts (herbs, keys), 2 words.
.alias AskRet           $02CD   ;Non-zero: the YES/NO answer ends the message list.
.alias DynNext          $02CE   ;The next free code for TileA (0: none).
.alias ListNext         $02CF   ;The step after the list.
.alias ListItems        $02D0   ;10: the rows' items.
.alias SleepTime        $02DA   ;The inn's night, in frames.
.alias RepelTime        $02DB   ;Fairy water's steps (the game's RepelTimer).
.alias ShopTmpX         $02DC   ;Temporaries.
.alias ShopTmpY         $02DD   ;
.alias ShopTmpI         $02DE   ;
.alias ShopTmpN         $02DF   ;
.alias TileX            $02E0   ;TileA's.
.alias TileY            $02E1   ;
.alias NamePtr          $6A     ;2: an item's name.
.alias TilePtr          $6C     ;2: TileA's glyph copying.
.alias TileDst          $6E     ;2:
.alias DynCodes         $3900   ;128: each text tile's code in set A (0: none yet).

.alias LIST_ROW         2       ;The list window: at (10, 2), 22 wide.
.alias LIST_COL         10      ;
.alias LIST_RIGHT       31      ;
.alias LIST_VALUE       30      ;Where a value ends.
.alias MSC_INN          $15     ;
.alias SLEEP_FRAMES     200     ;The night, with the inn's tune.
.alias HERB_ITEM        17      ;Items.
.alias KEY_ITEM         18      ;
.alias FAIRY_WATER      20      ;
.alias WINGS_ITEM       21      ;
.alias TORCH_ITEM       19      ;
.alias SCALE_ITEM       22      ;
.alias ITM_BASE         18      ;Item 18 + an ITM_ code.
.alias WORD_BUY         $FE     ;List rows that are words.
.alias WORD_SELL        $FD     ;
.alias RETURN_X         42      ;Where the wings bring the hero: beside
.alias RETURN_Y         43      ;Tantegel (the game's DoReturn).

;--------------------------------------[Window text]-------------------------------------------------

;A = set A's code for text tile A (X and Y kept): its own, or one given it
;now (its glyph copied from set B), or, none being left, a capital's.
TileA:
        STX TileX            ;
        TAX                     ;
        LDA TextA,X             ;
        BNE TileDone            ;
        CPX #TL_BLANK           ;(A blank: 0.)
        BEQ TileDone            ;
        LDA DynCodes,X          ;
        BNE TileDone            ;
        LDA DynNext             ;
        BEQ TileNone            ;
        STA DynCodes,X          ;
        STY TileY            ;
        LDA TextB,X             ;Set B's glyph: CharsetB + code * 8.
        LDY #$00                ;
        STY TilePtr+1            ;
        ASL                     ;
        ROL TilePtr+1            ;
        ASL                     ;
        ROL TilePtr+1            ;
        ASL                     ;
        ROL TilePtr+1            ;
        STA TilePtr              ;
        LDA TilePtr+1            ;
        CLC                     ;
        ADC #>CharsetB          ;
        STA TilePtr+1            ;
        LDA DynNext             ;To CharsetA + code * 8.
        STY TileDst+1            ;
        ASL                     ;
        ASL                     ;
        ROL TileDst+1            ;
        ASL                     ;
        ROL TileDst+1            ;
        STA TileDst              ;
        LDA TileDst+1            ;
        CLC                     ;
        ADC #>CharsetA          ;
        STA TileDst+1            ;
        LDY #$07                ;
*       LDA (TilePtr),Y          ;
        STA (TileDst),Y          ;
        DEY                     ;
        BPL -                   ;
        LDY TileY            ;
        LDA DynNext             ;The next: after 63, 114; none after 127.
        CLC                     ;
        ADC #$01                ;
        CMP #64                 ;
        BNE +                   ;
        LDA #114                ;
*       CMP #128                ;
        BNE +                   ;
        LDA #$00                ;
*       STA DynNext             ;
        LDA DynCodes,X          ;
TileDone:
        LDX TileX            ;
        RTS                     ;
TileNone:
        CPX #$24                ;Lower case: its capital.
        BCS +                   ;
        CPX #$0A                ;
        BCC +                   ;
        LDA TextA+$1A,X         ;
        BNE TileDone            ;
*       LDA TextA+TL_BLANK      ;
        JMP TileDone            ;

;A new map: no text tiles given codes.
ResetTiles:
        LDX MapId               ;
        LDA MapFreeCode         ;
        CMP #64                 ;
        BCC +                   ;
        LDA #114                ;
*       STA DynNext             ;
        LDA #$00                ;
        LDX #$7F                ;
*       STA DynCodes,X          ;
        DEX                     ;
        BPL -                   ;
        RTS                     ;

;--------------------------------------[Goods]-------------------------------------------------------

;A = the hero's attack: strength and the weapon's bonus.
GetAttack:
        LDA Equipped            ;
        LSR                     ;
        LSR                     ;
        LSR                     ;
        LSR                     ;
        LSR                     ;
        TAX                     ;
        LDA Strength            ;
        CLC                     ;
        ADC WeaponBonus,X       ;
        BCC +                   ;
        LDA #$FF                ;
*       RTS                     ;

;A = the hero's defense: agility / 2, the armor's and the shield's bonuses,
;and 2 with the dragon's scale on.
GetDefense:
        LDA Equipped            ;
        LSR                     ;
        LSR                     ;
        AND #$07                ;
        TAX                     ;
        LDA ArmorBonus,X        ;
        STA ShopTmpX            ;
        LDA Equipped            ;
        AND #$03                ;
        TAX                     ;
        LDA ShieldBonus,X       ;
        CLC                     ;
        ADC ShopTmpX            ;
        STA ShopTmpX            ;
        LDA ModFlags            ;
        AND #$01                ;
        ASL                     ;
        ADC ShopTmpX            ;
        STA ShopTmpX            ;
        LDA Agility             ;
        LSR                     ;
        CLC                     ;
        ADC ShopTmpX            ;
        BCC +                   ;
        LDA #$FF                ;
*       RTS                     ;

;Add ITM_ code A to the inventory (AddInvItem): C set if it is full.
AddItem:
        STA ShopTmpY            ;
        LDX #$00                ;
AddItemByte:
        LDA Inventory,X         ;
        AND #$0F                ;
        BNE +                   ;
        LDA Inventory,X         ;
        ORA ShopTmpY            ;
        STA Inventory,X         ;
        CLC                     ;
        RTS                     ;
*       LDA Inventory,X         ;
        AND #$F0                ;
        BNE +                   ;
        LDA ShopTmpY            ;
        ASL                     ;
        ASL                     ;
        ASL                     ;
        ASL                     ;
        ORA Inventory,X         ;
        STA Inventory,X         ;
        CLC                     ;
        RTS                     ;
*       INX                     ;
        CPX #$04                ;
        BNE AddItemByte         ;
        SEC                     ;
        RTS                     ;

;Take one ITM_ code A out of the inventory.
RemoveItem:
        STA ShopTmpY            ;
        LDX #$00                ;
RemoveByte:
        LDA Inventory,X         ;
        AND #$0F                ;
        CMP ShopTmpY            ;
        BNE +                   ;
        LDA Inventory,X         ;
        AND #$F0                ;
        STA Inventory,X         ;
        RTS                     ;
*       LDA Inventory,X         ;
        LSR                     ;
        LSR                     ;
        LSR                     ;
        LSR                     ;
        CMP ShopTmpY            ;
        BNE +                   ;
        LDA Inventory,X         ;
        AND #$0F                ;
        STA Inventory,X         ;
        RTS                     ;
*       INX                     ;
        CPX #$04                ;
        BNE RemoveByte          ;
        RTS                     ;

;ListItems = the hero's goods (CreateInvList): herbs, keys, then the
;items; ListCount how many.
GoodsList:
        LDY #$00                ;
        LDA Herbs               ;
        BEQ +                   ;
        LDA #HERB_ITEM          ;
        STA ListItems,Y         ;
        INY                     ;
*       LDA Keys                ;
        BEQ +                   ;
        LDA #KEY_ITEM           ;
        STA ListItems,Y         ;
        INY                     ;
*       LDX #$00                ;
GoodsByte:
        LDA Inventory,X         ;
        AND #$0F                ;
        BEQ +                   ;
        CLC                     ;
        ADC #ITM_BASE           ;
        STA ListItems,Y         ;
        INY                     ;
*       LDA Inventory,X         ;
        LSR                     ;
        LSR                     ;
        LSR                     ;
        LSR                     ;
        BEQ +                   ;
        CLC                     ;
        ADC #ITM_BASE           ;
        STA ListItems,Y         ;
        INY                     ;
*       INX                     ;
        CPX #$04                ;
        BNE GoodsByte           ;
        STY ListCount           ;
        RTS                     ;

;PriceLo/Hi = item A's price.
ItemPrice:
        JSR PriceOf             ;
        STA PriceLo             ;
        STX PriceHi             ;
        RTS                     ;

;A = item A's price's low byte, X its high (in MSG_BANK; Y lost).
PriceOf:
        TAY                     ;
        LDA #MSG_BANK           ;
        JSR SelectBank          ;
        LDX ItemPriceHi,Y       ;
        LDA ItemPriceLo,Y       ;
        RTS                     ;

;C clear if the hero cannot pay PriceLo/Hi.
CanPay:
        LDA Gold                ;
        CMP PriceLo             ;
        LDA Gold+1              ;
        SBC PriceHi             ;
        RTS                     ;

;Gold less the price, plus what the shop gives back (at most 65535); the
;status window shows it.
PayPrice:
        LDA Gold                ;
        SEC                     ;
        SBC PriceLo             ;
        STA Gold                ;
        LDA Gold+1              ;
        SBC PriceHi             ;
        STA Gold+1              ;
GetBack:
        LDA Gold                ;
        CLC                     ;
        ADC BuyLo               ;
        STA Gold                ;
        LDA Gold+1              ;
        ADC BuyHi               ;
        STA Gold+1              ;
        BCC +                   ;
        LDA #$FF                ;
        STA Gold                ;
        STA Gold+1              ;
*       JMP RedrawStatus        ;

;BuyLo/Hi = half item A's price; Amount too.
HalfPrice:
        JSR ItemPrice           ;
        LDA PriceHi             ;
        LSR                     ;
        STA BuyHi               ;
        STA Amount+1            ;
        LDA PriceLo             ;
        ROR                     ;
        STA BuyLo               ;
        STA Amount              ;
        RTS                     ;

;--------------------------------------[The list window]---------------------------------------------

;Open it with ListCount rows of ListItems (ListKind says what each shows),
;the cursor on the first; step X follows the choice.
OpenList:
        STX ListNext            ;
        LDA #$00                ;
        STA ListSel             ;
        LDA #$01                ;
        STA ListOn              ;
        LDA #LIST_ROW           ;
        STA WinRow              ;
        LDX #TL_TOP_LEFT        ;
        LDY #TL_TOP             ;
        LDA #TL_TOP_RIGHT       ;
        JSR ListEdge            ;
        LDA #$00                ;
        STA ShopTmpI            ;
*       INC WinRow              ;
        JSR ListRow             ;
        INC ShopTmpI            ;
        LDA ShopTmpI            ;
        CMP ListCount           ;
        BNE -                   ;
        INC WinRow              ;
        LDX #TL_BOTTOM_LEFT     ;
        LDY #TL_BOTTOM          ;
        LDA #TL_BOTTOM_RIGHT    ;
        JSR ListEdge            ;
        LDA #TL_ARROW           ;
        JMP PutListCursor       ;

;A row of the frame: tile X, then Y across, then A.
ListEdge:
        STA ShopTmpY            ;
        STY ShopTmpX            ;
        LDA #LIST_COL           ;
        STA WinCol              ;
        TXA                     ;
        JSR PutTileA            ;
*       LDA ShopTmpX            ;
        JSR PutTileA            ;
        LDA WinCol              ;
        CMP #LIST_RIGHT         ;
        BNE -                   ;
        LDA ShopTmpY            ;
        JMP PutTileA            ;

;Row ShopTmpI at WinRow: the frame, blanks, the name, the value.
ListRow:
        LDA #LIST_COL           ;
        STA WinCol              ;
        LDA #TL_LEFT            ;
        JSR PutTileA            ;
*       LDA #TL_BLANK           ;
        JSR PutTileA            ;
        LDA WinCol              ;
        CMP #LIST_RIGHT         ;
        BNE -                   ;
        LDA #TL_RIGHT           ;
        JSR PutTileA            ;
        LDA #LIST_COL+2         ;
        STA WinCol              ;
        LDX ShopTmpI            ;
        LDA ListItems,X         ;
        CMP #WORD_SELL          ;
        BCC ListName            ;
        LDY #$00                ;BUY or SELL.
        CMP #WORD_BUY           ;
        BEQ +                   ;
        LDY #$04                ;
*       LDA BuySellText,Y       ;
        BEQ ListRowDone         ;
        JSR PutTileA            ;
        INY                     ;
        BNE -                   ;
ListName:
        TAX                     ;(The names are in the text bank.)
        JSR NameOf              ;
        STA ShopTmpN            ;
        LDY #$00                ;
*       LDA (NamePtr),Y          ;
        JSR PutTileA            ;
        INY                     ;
        CPY ShopTmpN            ;
        BNE -                   ;
        LDX ShopTmpI            ;The value: the price, or a count.
        LDA ListKind            ;
        BEQ ListPrice           ;
        LDA ListItems,X         ;
        LDY Herbs               ;
        CMP #HERB_ITEM          ;
        BEQ ListCountOf         ;
        LDY Keys                ;
        CMP #KEY_ITEM           ;
        BNE ListRowDone         ;
ListCountOf:
        STY Amount              ;
        LDA #$00                ;
        STA Amount+1            ;
        JMP ListValue           ;
ListPrice:
        LDA ListItems,X         ;
        JSR PriceOf             ;
        STA Amount              ;
        STX Amount+1            ;
ListValue:
        JSR AmountDigits        ;InsertBuf, X digits: right aligned.
        STX ShopTmpN            ;
        LDA #LIST_VALUE+1       ;
        SEC                     ;
        SBC ShopTmpN            ;
        STA WinCol              ;
        LDY #$00                ;
*       LDA InsertBuf,Y         ;
        JSR PutTileA            ;
        INY                     ;
        CPY ShopTmpN            ;
        BNE -                   ;
ListRowDone:
        RTS                     ;

;BUY, SELL in text tiles.
BuySellText:    .byte $25, $38, $3C, 0, $36, $28, $2F, $2F, 0

;Put text tile A at the cursor's place.
PutListCursor:
        PHA                     ;
        LDA ListSel             ;
        CLC                     ;
        ADC #LIST_ROW+1         ;
        STA WinRow              ;
        LDA #LIST_COL+1         ;
        STA WinCol              ;
        PLA                     ;
        JMP PutTileA            ;

;A frame with it up: the stick moves the cursor, the lower fire button
;chooses, the upper one chooses nothing ($FF); either closes it and takes
;the step after.
ListFrame:
        LDA StickNew            ;
        AND #$05                ;
        BEQ ListButtons         ;
        STA ShopTmpN            ;
        LDA #TL_BLANK           ;
        JSR PutListCursor       ;
        LDX ListSel             ;
        LDA ShopTmpN            ;
        LSR                     ;Up.
        BCC +                   ;
        CPX #$00                ;
        BEQ +                   ;
        DEX                     ;
*       LDA ShopTmpN            ;
        AND #$04                ;Down.
        BEQ +                   ;
        INX                     ;
        CPX ListCount           ;
        BCC +                   ;
        DEX                     ;
*       STX ListSel             ;
        LDA #TL_ARROW           ;
        JSR PutListCursor       ;
ListButtons:
        LDA Pressed             ;
        AND #BTN_B              ;
        BEQ +                   ;
        LDA #$FF                ;
        STA ListSel             ;
        BNE ListChosen          ;
*       LDA Pressed             ;
        AND #BTN_A              ;
        BNE ListChosen          ;
        RTS                     ;
ListChosen:
        JSR CloseList           ;
        LDA ListNext            ;
        STA ShopState           ;
        JMP RunShopStep         ;

;Close it: the map's blocks back (block rows 1 on, columns 5-15).
CloseList:
        LDA #$00                ;
        STA ListOn              ;
        LDA BattleOn            ;(In a battle: what it covered back.)
        BEQ +                   ;
        JMP RestoreUnder        ;
*
        LDA ListCount           ;
        CLC                     ;
        ADC #$03                ;
        LSR                     ;
        STA Rows                ;
        LDX #5                  ;
        LDY #1                  ;
        LDA #11                 ;
        JMP RedrawBlocks        ;

;The chosen row's item (A), or C set for none.
ChosenItem:
        LDX ListSel             ;
        CPX #$FF                ;
        BEQ +                   ;
        LDA ListItems,X         ;
        CLC                     ;
        RTS                     ;
*       SEC                     ;
        RTS                     ;

;--------------------------------------[Steps]-------------------------------------------------------

;Say message A, then take step X.
ShopSay:
        STX ShopState           ;
        JSR SetSay              ;
        JMP NextMessage         ;

;Say message A and ask YES or NO (Answer: 0 yes), then take step X.
ShopAsk:
        STX ShopState           ;
        JSR SetSay              ;
        LDA #$FC                ;$FFFC: ask, and end there.
        STA BattleList+2        ;
        JMP NextMessage         ;

;Say message A, the last.
ShopEnd:
        LDX #$00                ;
        BEQ ShopSay             ;

;Message A in a new dialog window, then step X (0: none).
ShopOpen:
        STX ShopTmpN            ;
        JSR SetSay              ;
ShopOpenSaid:
        JSR OpenDialog          ;
        LDA ShopTmpN            ;
        STA ShopState           ;
        LDA #$04                ;
        STA Mode                ;
        RTS                     ;

;A frame of a shop: the list window, the dialog, and once its message is
;out, the next step (none: the dialog's end, which closes it).
ShopFrame:
        LDA ListOn              ;
        BEQ +                   ;
        JMP ListFrame           ;
*       LDA DlgState            ;
        CMP #$02                ;
        BNE +                   ;
        LDA ShopState           ;
        BNE RunShopStep         ;
*       LDA DialogOn            ;
        BNE +                   ;
        LDA #$00                ;(No window: the ITEM list closed.)
        STA Mode                ;
        RTS                     ;
*       JMP DialogFrame         ;
RunShopStep:
        LDX ShopState           ;
        LDA ShopStepLo,X        ;
        STA Ptr                 ;
        LDA ShopStepHi,X        ;
        STA Ptr+1               ;
        BPL +                   ;A step in MSG_BANK ($8000 on: poweron.asm),
        LDA #MSG_BANK           ;that bank in.
        JSR SelectBank          ;
*       JMP (Ptr)               ;

;$FFFB in a message list: the shop for control byte A.
StartShop:
        STA ShopCtl             ;
        LDA #S_START            ;
        STA ShopState           ;
        LDA #$02                ;
        STA DlgState            ;
        LDA #$04                ;
        STA Mode                ;
        RTS                     ;

.alias S_START          1
.alias W_ASKED          2
.alias W_LIST           3
.alias W_PICKED         4
.alias W_PRICE          5
.alias W_OKASK          6
.alias W_OK             7
.alias W_MORE           8
.alias T_MENU           9
.alias T_CHOSE          10
.alias T_BUY            11
.alias T_LIST           12
.alias T_PICKED         13
.alias T_MORE           14
.alias T_AGAIN          15
.alias T_EXIT           16
.alias T_SELL           17
.alias T_SLIST          18
.alias T_SPICK          19
.alias T_SOLD           20
.alias T_SMORE          21
.alias T_SAGAIN         22
.alias K_ASKED          23
.alias K_END            24
.alias F_ASKED          25
.alias F_END            26
.alias I_ASKED          27
.alias I_SLEEP          28
.alias I_WAIT           29
.alias I_BYE            30
.alias IT_PICK          31
.alias IT_WINGS         32
.alias SP_PICK          33      ;(spell.asm.)
.alias SP_CAST          34      ;
.alias SP_BATTLE        35      ;
.alias IT_RAINBOW       36      ;(castle.asm.)
.alias IT_RBWAIT        37      ;
.alias FD_DEAD          38      ;
.alias LORD_END         39      ;
.alias RM_EXIT          40      ;
.alias RM_MORE          41      ;
.alias END_WAIT         42      ;
.alias GW_ASKED         43      ;
.alias GW_AGAIN         44      ;
.alias GW_BYE           45      ;
.alias IT_BATTLE        46      ;
.alias LV_MAP           48      ;(castle.asm.)
.alias LV_DD            49      ;
.alias LV_Y             50      ;
.alias LV_X             51      ;
.alias LV_END           52      ;
.alias CF_DONE          53      ;
.alias DS_ASK           54      ;(treasure.asm.)
.alias DS_ASKED         55      ;
.alias DS_WHICH         56      ;
.alias DS_LIST          57      ;
.alias DS_PICK          58      ;
.alias DS_GOT           59      ;
.alias EG_ASK           60      ;(castle.asm.)
.alias EG_ASKED         61      ;
.alias EG_TALE          62      ;
.alias EG_END           63      ;
.alias CR_RUN           64      ;(castle.asm.)
.alias TB_READ          65      ;(treasure.asm.)
.alias GW_KEEP          66      ;(castle.asm.)

ShopStepLo:
        .byte 0, <StepStart, <StepWAsked, <StepWList, <StepWPicked, <StepWPrice, <StepWOkAsk
        .byte <StepWOk, <StepWMore, <StepTMenu, <StepTChose, <StepTBuy, <StepTList, <StepTPicked
        .byte <StepTMore, <StepTAgain, <StepTExit, <StepTSell, <StepTSList, <StepTSPick
        .byte <StepTSold, <StepTSMore, <StepTSAgain, <StepKAsked, <StepKEnd, <StepFAsked
        .byte <StepFEnd, <StepIAsked, <StepISleep, <StepIWait, <StepIBye, <StepItPick
        .byte <StepItWings, <StepSpPick, <StepSpCast, <StepBSpell, <StepItRainbow, <StepItRbWait, <StepFieldDead, <StepLordEnd, <StepRmExit, <StepRmMore, <StepEndWait, <StepGwAsked, <GwaelinAsk, <StepGwBye, <StepItBattle, <StepPwWait, <StepLvMap, <StepLvDD, <StepLvY, <StepLvX, <StepLvEnd, <StepCfDone
        .byte <StepDsAsk, <StepDsAsked, <StepDsWhich, <StepDsList, <StepDsPick, <StepDsGot
        .byte <StepEgAsk, <StepEgAsked, <StepEgTale, <EndStep, <CreditsFrame, <StepTbRead, <StepGwKeep
ShopStepHi:
        .byte 0, >StepStart, >StepWAsked, >StepWList, >StepWPicked, >StepWPrice, >StepWOkAsk
        .byte >StepWOk, >StepWMore, >StepTMenu, >StepTChose, >StepTBuy, >StepTList, >StepTPicked
        .byte >StepTMore, >StepTAgain, >StepTExit, >StepTSell, >StepTSList, >StepTSPick
        .byte >StepTSold, >StepTSMore, >StepTSAgain, >StepKAsked, >StepKEnd, >StepFAsked
        .byte >StepFEnd, >StepIAsked, >StepISleep, >StepIWait, >StepIBye, >StepItPick
        .byte >StepItWings, >StepSpPick, >StepSpCast, >StepBSpell, >StepItRainbow, >StepItRbWait, >StepFieldDead, >StepLordEnd, >StepRmExit, >StepRmMore, >StepEndWait, >StepGwAsked, >GwaelinAsk, >StepGwBye, >StepItBattle, >StepPwWait, >StepLvMap, >StepLvDD, >StepLvY, >StepLvX, >StepLvEnd, >StepCfDone
        .byte >StepDsAsk, >StepDsAsked, >StepDsWhich, >StepDsList, >StepDsPick, >StepDsGot
        .byte >StepEgAsk, >StepEgAsked, >StepEgTale, >EndStep, >CreditsFrame, >StepTbRead, >StepGwKeep

;Who it is: weapons and armor (0-6), tools (7-11), keys (12-14), fairy
;water (15-16), an inn (17-21).
StepStart:
        LDA #$00                ;
        STA BuyLo               ;
        STA BuyHi               ;
        LDA ShopCtl             ;
        CMP #LORD_FIGHT         ;The Dragonlord's (castle.asm).
        BCC +                   ;
        JMP LordStep            ;
*       STA ShopIdx             ;
        CMP #$07                ;
        BCS +                   ;
        LDA #$28                ;The weapon shop's greeting and its offer
        LDX #W_ASKED            ;(YES or NO).
        JMP ShopAsk             ;
*       CMP #$0C                ;
        BCS +                   ;
        LDA #$25                ;The tool shop's greeting, then BUY or
        LDX #T_MENU             ;(YES or NO).
        JMP ShopSay             ;
*       CMP #$0F                ;
        BCS +                   ;
        SEC                     ;
        SBC #$0C                ;
        TAX                     ;
        LDA KeyCost,X           ;
        JSR SetPrice8           ;
        LDA #$16                ;Magic keys! ... purchase one for 85 GOLD?
        LDX #K_ASKED            ;
        JMP ShopAsk             ;
*       CMP #$11                ;
        BCS +                   ;
        LDA #FAIRY_WATER        ;
        JSR ItemPrice           ;
        LDA #$11                ;The fairy water offer (YES or NO).
        LDX #F_ASKED            ;
        JMP ShopAsk             ;
*       SEC                     ;
        SBC #$11                ;
        TAX                     ;
        LDA InnCost,X           ;
        JSR SetPrice8           ;
        LDA #$0B                ;The inn's greeting and its price, then
        LDX #I_ASKED            ;board is 6 GOLD per night.
        JMP ShopAsk             ;

;Price (and Amount) = A.
SetPrice8:
        STA PriceLo             ;
        STA Amount              ;
        LDA #$00                ;
        STA PriceHi             ;
        STA Amount+1            ;
        RTS                     ;

;Weapons and armor (WeaponsDialog).
StepWAsked:
        LDA Answer              ;
        BEQ +                   ;
        LDA #$2F                ;Please, come again.
        JMP ShopEnd             ;
*       LDA #$2D                ;Which to buy?
        LDX #W_LIST             ;
        JMP ShopSay             ;
StepWList:
        LDX #W_PICKED           ;
        JMP OpenShopList        ;
StepWPicked:
        JSR ChosenItem          ;
        BCC +                   ;
        LDA #$2F                ;Please, come again.
        JMP ShopEnd             ;
*       STA SelItem             ;
        STA ItemName            ;
        LDA #$29                ;The Club?
        LDX #W_PRICE            ;
        JMP ShopSay             ;
StepWPrice:
        LDA SelItem             ;
        JSR ItemPrice           ;
        JSR CanPay              ;
        BCS +                   ;
        LDA #$2B                ;Not enough gold.
        LDX #W_MORE             ;
        JMP ShopSay             ;
*       LDA #$00                ;What it has of the kind: weapons 0-6,
        STA BuyLo               ;armor 7-13, shields 14-16.
        STA BuyHi               ;
        LDA SelItem             ;
        CMP #$07                ;
        BCS +                   ;
        LDA Equipped            ;
        LSR                     ;
        LSR                     ;
        LSR                     ;
        LSR                     ;
        LSR                     ;
        BEQ StepWOkAsk          ;
        SEC                     ;
        SBC #$01                ;
        JMP WOld                ;
*       CMP #14                 ;
        BCS +                   ;
        LDA Equipped            ;
        LSR                     ;
        LSR                     ;
        AND #$07                ;
        BEQ StepWOkAsk          ;
        CLC                     ;
        ADC #$06                ;
        JMP WOld                ;
*       LDA Equipped            ;
        AND #$03                ;
        BEQ StepWOkAsk          ;
        CLC                     ;
        ADC #13                 ;
WOld:
        STA ItemName            ;The trade-in offer for what is worn.
        PHA                     ;
        LDA PriceLo             ;(HalfPrice changes the price.)
        PHA                     ;
        LDA PriceHi             ;
        PHA                     ;
        LDA ItemName            ;
        JSR HalfPrice           ;
        PLA                     ;
        STA PriceHi             ;
        PLA                     ;
        STA PriceLo             ;
        PLA                     ;
        LDA #$2A                ;
        LDX #W_OKASK            ;
        JMP ShopSay             ;
StepWOkAsk:
        LDA #$27                ;Is that Okay?
        LDX #W_OK               ;
        JMP ShopAsk             ;
StepWOk:
        LDA Answer              ;
        BEQ +                   ;
        LDA #$26                ;The shopkeeper's reply to NO.
        LDX #W_MORE             ;
        JMP ShopSay             ;
*       LDA SelItem             ;Equip it.
        CMP #$07                ;
        BCS +                   ;
        CLC                     ;
        ADC #$01                ;
        ASL                     ;
        ASL                     ;
        ASL                     ;
        ASL                     ;
        ASL                     ;
        STA ShopTmpN            ;
        LDA Equipped            ;
        AND #$1F                ;
        JMP WEquip              ;
*       CMP #14                 ;
        BCS +                   ;
        SEC                     ;
        SBC #$06                ;
        ASL                     ;
        ASL                     ;
        STA ShopTmpN            ;
        LDA Equipped            ;
        AND #$E3                ;
        JMP WEquip              ;
*       SEC                     ;
        SBC #13                 ;
        STA ShopTmpN            ;
        LDA Equipped            ;
        AND #$FC                ;
WEquip:
        ORA ShopTmpN            ;
        STA Equipped            ;
        JSR PayPrice            ;
        LDA #$2E                ;The shopkeeper's thanks.
        LDX #W_MORE             ;
        JMP ShopSay             ;
StepWMore:
        LDA #$2C                ;Anything more (YES or NO)?
        LDX #W_ASKED            ;
        JMP ShopAsk             ;

;The shop's goods in the list window, with their prices; step X after.
OpenShopList:
        TXA                     ;
        PHA                     ;
        LDA #MSG_BANK           ;(The shops' tables' bank.)
        JSR SelectBank          ;
        LDX ShopIdx             ;
        LDA ShopStart,X         ;
        TAX                     ;
        LDY #$00                ;
*       LDA ShopData,X          ;
        CMP #$FD                ;
        BEQ +                   ;
        STA ListItems,Y         ;
        INX                     ;
        INY                     ;
        BNE -                   ;
*       STY ListCount           ;
        LDA #$00                ;
        STA ListKind            ;
        PLA                     ;
        TAX                     ;
        JMP OpenList            ;

;Tools (ToolsDialog): BUY or SELL.
StepTMenu:
        LDA #WORD_BUY           ;
        STA ListItems           ;
        LDA #WORD_SELL          ;
        STA ListItems+1         ;
        LDA #$02                ;
        STA ListCount           ;
        STA ListKind            ;
        LDX #T_CHOSE            ;
        JMP OpenList            ;
StepTChose:
        LDA ListSel             ;
        BEQ StepTBuy            ;
        CMP #$01                ;
        BEQ StepTSell           ;
StepTExit:
        LDA #$1E                ;The shop's farewell.
        JMP ShopEnd             ;
StepTBuy:
        LDA #$24                ;Which to buy?
        LDX #T_LIST             ;
        JMP ShopSay             ;
StepTList:
        LDX #T_PICKED           ;
        JMP OpenShopList        ;
StepTPicked:
        JSR ChosenItem          ;
        BCS StepTExit           ;
        STA SelItem             ;
        STA ItemName            ;
        JSR ItemPrice           ;
        JSR CanPay              ;
        BCS +                   ;
        LDA #$22                ;Not enough gold.
        LDX #T_MORE             ;
        JMP ShopSay             ;
*       LDA SelItem             ;
        CMP #HERB_ITEM          ;
        BNE +                   ;
        LDA Herbs               ;
        CMP #$06                ;
        BCC TAddHerb            ;
        LDA #$20                ;Herbs at the most already.
        LDX #T_MORE             ;
        JMP ShopSay             ;
TAddHerb:
        INC Herbs               ;
        JMP TBought             ;
*       SEC                     ;
        SBC #ITM_BASE           ;
        JSR AddItem             ;
        BCC TBought             ;
        LDA #$21                ;The bag is full.
        LDX #T_MORE             ;
        JMP ShopSay             ;
TBought:
        JSR PayPrice            ;
        LDA #$23                ;The thanks for the purchase.
        LDX #T_MORE             ;
        JMP ShopSay             ;
StepTMore:
        LDA #$1F                ;Anything else (YES or NO)?
        LDX #T_AGAIN            ;
        JMP ShopAsk             ;
StepTAgain:
        LDA Answer              ;
        BEQ StepTBuy            ;
        JMP StepTExit           ;
StepTSell:
        JSR GoodsList           ;
        LDA ListCount           ;
        BNE +                   ;
        LDA #$19                ;Nothing to sell.
        LDX #T_EXIT             ;
        JMP ShopSay             ;
*       LDA #$1D                ;Which to sell?
        LDX #T_SLIST            ;
        JMP ShopSay             ;
StepTSList:
        LDA #$01                ;
        STA ListKind            ;
        LDX #T_SPICK            ;
        JMP OpenList            ;
StepTSPick:
        JSR ChosenItem          ;
        BCC +                   ;
        JMP StepTExit           ;
*       STA SelItem             ;
        STA ItemName            ;
        JSR HalfPrice           ;
        LDA PriceLo             ;
        ORA PriceHi             ;
        BNE +                   ;
        LDA #$1B                ;I cannot buy it.
        LDX #T_SMORE            ;
        JMP ShopSay             ;
*       LDA #$1C                ;The price offered for it, and the ask
        LDX #T_SOLD             ;(YES or NO).
        JMP ShopAsk             ;
StepTSold:
        LDA Answer              ;
        BNE StepTSMore          ;
        LDA SelItem             ;
        CMP #HERB_ITEM          ;
        BNE +                   ;
        DEC Herbs               ;
        JMP TSoldGold           ;
*       CMP #KEY_ITEM           ;
        BNE +                   ;
        DEC Keys                ;
        JMP TSoldGold           ;
*       SEC                     ;
        SBC #ITM_BASE           ;
        JSR RemoveItem          ;
TSoldGold:
        JSR GetBack             ;
StepTSMore:
        LDA #$1A                ;Anything else to sell (YES or NO)?
        LDX #T_SAGAIN           ;
        JMP ShopAsk             ;
StepTSAgain:
        LDA Answer              ;
        BNE +                   ;
        JMP StepTSell           ;
*       JMP StepTExit           ;

;Keys (KeysDialog).
StepKAsked:
        LDA Answer              ;
        BNE StepKEnd            ;
        LDA Keys                ;
        CMP #$06                ;
        BCC +                   ;
        LDA #$14                ;Keys at the most already.
        LDX #K_END              ;
        JMP ShopSay             ;
*       JSR CanPay              ;
        BCS +                   ;
        LDA #$13                ;Not enough gold.
        LDX #K_END              ;
        JMP ShopSay             ;
*       INC Keys                ;
        JSR PayPrice            ;
        LDA #$15                ;A key sold, and the ask for more
        LDX #K_ASKED            ;purchase more?
        JMP ShopAsk             ;
StepKEnd:
        LDA #$12                ;The key seller's farewell.
        JMP ShopEnd             ;

;Fairy water (FairyDialog).
StepFAsked:
        LDA Answer              ;
        BNE StepFEnd            ;
        JSR CanPay              ;
        BCS +                   ;
        LDA #$22                ;Not enough gold.
        LDX #F_END              ;
        JMP ShopSay             ;
*       LDA #FAIRY_WATER-ITM_BASE ;
        JSR AddItem             ;
        BCC +                   ;
        LDA #$21                ;The bag is full.
        LDX #F_END              ;
        JMP ShopSay             ;
*       JSR PayPrice            ;
        LDA #$10                ;Thanks, and the ask for another.
        LDX #F_ASKED            ;
        JMP ShopAsk             ;
StepFEnd:
        LDA #$0C                ;The fairy water seller's farewell.
        JMP ShopEnd             ;

;An inn (InnDialog): the night is dark, with the inn's tune.
StepIAsked:
        LDA Answer              ;
        BEQ +                   ;
        LDA #$0A                ;The fairy water seller's goodbye.
        JMP ShopEnd             ;
*       JSR CanPay              ;
        BCS +                   ;
        LDA #$22                ;Not enough gold.
        JMP ShopEnd             ;
*       JSR PayPrice            ;
        LDA #$09                ;Good night.
        LDX #I_SLEEP            ;
        JMP ShopSay             ;
StepISleep:
        LDA #$01                ;The screen off (the VBI's DMACTL).
        STA Loading             ;
        LDA #MSC_INN            ;
        JSR PlayMusic           ;
        LDA MaxHP               ;
        STA HitPoints           ;
        LDA MaxMP               ;
        STA MagicPoints         ;
        LDA #SLEEP_FRAMES       ;
        STA SleepTime           ;
        LDA #I_WAIT             ;
        STA ShopState           ;
        RTS                     ;
StepIWait:
        DEC SleepTime           ;
        BEQ +                   ;
        RTS                     ;
*       LDA #$00                ;Morning.
        STA Loading             ;
        JSR PlayMapMusic        ;
        JSR RedrawStatus        ;
        LDA #$06                ;The morning after a night at the inn
        LDX #I_BYE              ;sleep I hope.
        JMP ShopSay             ;
StepIBye:
        LDA #$07                ;The innkeeper's farewell.
        JMP ShopEnd             ;

;--------------------------------------[ITEM]--------------------------------------------------------

;The ITEM command: the hero's goods in the list window; C clear if there
;are none (the command's own message then).
ItemCommand:
        JSR GoodsList           ;
        LDA ListCount           ;
        BNE +                   ;
        CLC                     ;
        RTS                     ;
*       LDA #$01                ;
        STA ListKind            ;
        LDA #$04                ;
        STA Mode                ;
        LDX #IT_PICK            ;
        JSR OpenList            ;
        SEC                     ;
        RTS                     ;

;The item chosen, used (ChkHerb on).
StepItPick:
        JSR ChosenItem          ;
        BCC +                   ;
        LDA #$00                ;None: back to walking.
        STA ShopState           ;
        STA Mode                ;
        RTS                     ;
*       STA ItemName            ;
        CMP #HERB_ITEM          ;
        BNE +                   ;
        DEC Herbs               ;
        JSR HerbHeal            ;
        LDA #$F7                ;Loto used the Herb.
        LDX #$00                ;
        JMP ShopOpen            ;
*       CMP #KEY_ITEM           ;A key: as DOOR.
        BNE +                   ;
        LDA #$00                ;
        STA ShopState           ;
        JMP DoorCommand         ;
*       CMP #TORCH_ITEM         ;A torch: in the dark, the light 3 blocks
        BNE +                   ;wide, the torch used up (UseTorch).
        LDA Dark                ;
        BNE UseTorch            ;
        LDA #$35                ;A torch: only of use in the dark.
        LDX #$00                ;
        JMP ShopOpen            ;
*       CMP #FAIRY_WATER        ;
        BNE +                   ;
        LDA #FAIRY_WATER-ITM_BASE ;
        JSR RemoveItem          ;
        LDA #$FE                ;The game's repel time (Repelled counts it).
        STA RepelTime           ;
        LDA #$36                ;The fairy water used.
        LDX #$00                ;
        JMP ShopOpen            ;
*       CMP #WINGS_ITEM         ;
        BNE +                   ;
        LDA Dark                ;Not in a dungeon, nor the Dragonlord's
        BNE WingsFail           ;floor (the game's WingsFail).
        LDA MapId               ;
        CMP #CASTLE_BF          ;
        BNE WingsUse            ;
WingsFail:
        LDA #$38                ;Wings: not of use here.
        LDX #$00                ;
        JMP ShopOpen            ;
WingsUse:
        LDA #WINGS_ITEM-ITM_BASE ;
        JSR RemoveItem          ;
        LDA #$39                ;The wings used.
        LDX #IT_WINGS           ;
        JMP ShopOpen            ;
*       CMP #LOVE_ITEM          ;The princess's keepsake (castle.asm).
        BNE +                   ;
        JMP LoveUse             ;
*       CMP #RAINBOW_ITEM       ;The rainbow drop held up (castle.asm).
        BNE +                   ;
        LDA #$04                ;
        LDX #IT_RAINBOW         ;
        JMP ShopOpen            ;
*       CMP #RING_ITEM          ;The fighter's ring, the cursed belt, the
        BNE +                   ;death necklace (castle.asm).
        JMP WearRing            ;
*       LDY #F2_BELT            ;
        CMP #BELT_ITEM          ;
        BEQ +                   ;
        LDY #F2_NECK            ;
        CMP #NECK_ITEM          ;
        BNE ++                  ;
*       JMP WearCursed          ;
*       CMP #SCALE_ITEM         ;
        BNE +                   ;
        JSR WearScale           ;
        LDX #$00                ;
        JMP ShopOpen            ;
*       LDA #$33                ;No effect.
        LDX #$00                ;
        JMP ShopOpen            ;

;The dragon's scale put on (ChkDragonScale): A = the message, that it is,
;or that it already was.
WearScale:
        LDA ModFlags            ;
        LSR                     ;
        LDA #$3B                ;Already worn.
        BCS +                   ;
        LDA ModFlags            ;
        ORA #$01                ;
        STA ModFlags            ;
        LDA #$3A                ;Put on.
*       RTS                     ;

;A torch lit: the light 3 blocks wide (the game's LightDiameter 3).
UseTorch:
        LDA #TORCH_ITEM-ITM_BASE ;
        JSR RemoveItem          ;
        LDA #$01                ;
        STA LightR              ;
        LDA #$03                ;
        STA LightW              ;
        LDA #SFX_RADIANT        ;
        JSR PlaySFX             ;
        LDA #$00                ;
        STA ShopState           ;
        STA Mode                ;
        JMP RedrawLight         ;

;The wings: back beside Tantegel.
StepItWings:
        LDA #$00                ;
        STA ShopState           ;
        STA DialogOn            ;
        STA StatusOn            ;
        LDA #RETURN_X           ;
        STA HeroX               ;
        LDA #RETURN_Y           ;
        STA HeroY               ;
        LDA #$02                ;Facing down.
        STA Facing              ;
        LDA #$00                ;
        JMP LoadMap             ;

;An herb: 23-30 HP back (HerbHeal), no more than the most.
HerbHeal:
        JSR NextRandom          ;
        LDA Random+1            ;
        AND #$07                ;
        CLC                     ;
        ADC #23                 ;
;A HP more, no more than the most.
HealAdd:
        CLC                     ;
        ADC HitPoints           ;
        BCS +                   ;
        CMP MaxHP               ;
        BCC ++                  ;
*       LDA MaxHP               ;
*       STA HitPoints           ;
        JMP RedrawStatus        ;
