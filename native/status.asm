;The STATUS window: the hero's name, strength, agility, maximum HP and
;MP, attack and defense power, and the weapon, armor and shield worn.
;
;Its tiles and where each field goes are the ROM's own window data
;(window.py reads StatusDat at build time into MSG_BANK: STATUS_WIN, its
;rows; STATUS_FIELDS, row, column and kind for each field, $FF after).
;The window stays up until a button is pressed (Mode 5), as the game's
;WaitForBtnRelease, then the map is drawn again beneath it.

.alias F_STAT           $10     ;Field kinds: below, the name; then a stat
.alias F_ITEM           $20     ;(its number); then an item's half (weapon,
                                ;armor, shield; first halves, then second).
.alias StField          $02E2   ;The field being drawn (its table index),
.alias StKind           $02E3   ;its kind,
.alias StLen            $02E4   ;an item name's length.
.alias StHalf           $02E5   ;Non-zero: the name's second half.

;STATUS (Cursor 2 of the command window): the window drawn.
StatusCommand:
        JSR SelectMsg           ;
        LDA #<STATUS_WIN        ;
        STA SrcPtr              ;
        LDA #>STATUS_WIN        ;
        STA SrcPtr+1            ;
        LDA #STATUS_TOP         ;
        STA WinRow              ;
StWinRow:
        LDA #STATUS_LEFT        ;
        STA WinCol              ;
        LDY #$00                ;
*       LDA (SrcPtr),Y          ;
        JSR PutTileA            ;(Y kept.)
        INY                     ;
        CPY #STATUS_WIDTH       ;
        BNE -                   ;
        TYA                     ;
        CLC                     ;
        ADC SrcPtr              ;
        STA SrcPtr              ;
        BCC +                   ;
        INC SrcPtr+1            ;
*       INC WinRow              ;
        LDA WinRow              ;
        CMP #STATUS_TOP+STATUS_HEIGHT ;
        BNE StWinRow            ;
        LDA #$00                ;
        STA StField             ;
StNextField:
        JSR SelectMsg           ;The next field's place and kind.
        LDX StField             ;
        LDA STATUS_FIELDS,X     ;
        CMP #$FF                ;
        BNE +                   ;
        LDA #$05                ;All drawn: wait for a button, the hero out
        STA Mode                ;of sight (under it).
        LDA #$00                ;
        JSR HeroAt              ;
        RTS                     ;
*       CLC                     ;
        ADC #STATUS_TOP         ;
        STA WinRow              ;
        LDA STATUS_FIELDS+1,X   ;
        CLC                     ;
        ADC #STATUS_LEFT        ;
        STA WinCol              ;
        LDA STATUS_FIELDS+2,X   ;
        STA StKind              ;
        INX                     ;
        INX                     ;
        INX                     ;
        STX StField             ;
        CMP #F_STAT             ;
        BCS StNotName           ;
        LDY #$00                ;The name, 8 letters.
*       LDA HeroName,Y          ;
        JSR PutTileA            ;
        INY                     ;
        CPY #$08                ;
        BNE -                   ;
        BEQ StNextField         ;
StNotName:
        CMP #F_ITEM             ;
        BCS StItem              ;
        AND #$07                ;A stat, 3 digits, the last at the field's
        JSR StatValue           ;third column.
        STA NumLo               ;
        LDA #$00                ;
        STA NumHi               ;
        INC WinCol              ;
        INC WinCol              ;
        LDX #3                  ;
        JSR PrintNumber         ;
        JMP StNextField         ;

;An item's half: the first up to its space, the second after it (the
;game's two name tables, joined with a space in ours).
StItem:
        SEC                     ;
        SBC #F_ITEM             ;
        LDY #$00                ;
        CMP #$03                ;
        BCC +                   ;
        SBC #$03                ;
        INY                     ;
*       STY StHalf              ;
        TAX                     ;
        LDA Equipped            ;The worn item's number (0: none).
        CPX #$01                ;
        BEQ StArmor             ;
        BCS StShield            ;
        LSR                     ;Weapon: bits 5-7, items 0-6.
        LSR                     ;
        LSR                     ;
        LSR                     ;
        LSR                     ;
        LDY #$FF                ;
        BNE StWorn              ;
StArmor:
        LSR                     ;Armor: bits 2-4, items 7-13.
        LSR                     ;
        AND #$07                ;
        LDY #6                  ;
        BNE StWorn              ;
StShield:
        AND #$03                ;Shield: bits 0-1, items 14-16.
        LDY #13                 ;
StWorn:
        CMP #$00                ;
        BEQ StNone              ;
        STY Tmp                 ;
        CLC                     ;
        ADC Tmp                 ;
        TAX                     ;
        JSR NameOf              ;(The text bank in.)
        STA StLen               ;
        LDY #$00                ;
        LDA StHalf              ;
        BEQ StHalfOut           ;
*       CPY StLen               ;The second: past the space.
        BEQ StNone              ;
        LDA (NamePtr),Y         ;
        INY                     ;
        CMP #TL_BLANK           ;
        BNE -                   ;
StHalfOut:
        CPY StLen               ;
        BEQ StNone              ;
        LDA (NamePtr),Y         ;
        CMP #TL_BLANK           ;(The first ends at the space.)
        BNE +                   ;
        LDX StHalf              ;
        BEQ StNone              ;
*       JSR PutTileA            ;
        INY                     ;
        BNE StHalfOut           ;
StNone:
        JMP StNextField         ;

;A = stat A: strength, agility, attack, defense, maximum HP, maximum MP.
StatValue:
        TAX                     ;
        BNE +                   ;
        LDA Strength            ;
        RTS                     ;
*       DEX                     ;
        BNE +                   ;
        LDA Agility             ;
        RTS                     ;
*       DEX                     ;
        BNE +                   ;
        JMP GetAttack           ;
*       DEX                     ;
        BNE +                   ;
        JMP GetDefense          ;
*       DEX                     ;
        BNE +                   ;
        LDA MaxHP               ;
        RTS                     ;
*       LDA MaxMP               ;
        RTS                     ;

;A frame with it up (Mode 5): a button closes it, the map back beneath.
StatusFrame:
        LDA Pressed             ;
        AND #BTN_A+BTN_B        ;
        BNE +                   ;
        RTS                     ;
*       LDA #$00                ;
        STA Mode                ;
        LDA #HERO_HPOS          ;
        JSR HeroAt              ;
        LDA #STATUS_HEIGHT/2    ;
        STA Rows                ;
        LDX #STATUS_LEFT/2      ;
        LDY #STATUS_TOP/2       ;
        LDA #STATUS_WIDTH/2     ;
        JMP RedrawBlocks        ;
