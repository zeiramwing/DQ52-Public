;The dialog window and the game's text.
;
;The window's rows (screen rows 18 on) show character set B, which holds
;every text tile: the display list interrupt before them switches to it
;while the window is up, and the VBI switches back to set A. The map's
;characters are not in set B, so the window takes the whole width of its
;rows (the NES leaves 4 columns of map each side).
;
;The text is the game's (Bank02's TextBlock1-19, in TEXT_BANK): text tiles,
;and control bytes from $F0 on. A message is 16 * (block - 1) + entry, as
;the game's DoDialogLoBlock and DoDialogHiBlock (+256) number them. Words
;wrap at the window's edge, as the game's do, and when the window is full
;its lines move up.

.alias MSG_BANK         8       ;Where each message starts (convert.py's table),
.alias MSG_BASE         $8000   ;
.alias DLG_ROW          18      ;The window: rows 18-27, columns 4-27;
.alias DLG_COL          4       ;
.alias DLG_LAST         28      ;rows 18-28 are cleared (28 shows a line).
.alias TEXT_ROW         19      ;The text: 8 lines of 22, from (5, 19).
.alias TEXT_COL         5       ;
.alias TEXT_WIDTH       22      ;
.alias TEXT_LINES       8       ;

.alias MSG_EN_CHANT     $FD     ;The enemy's chant (goes on after $FC).
.alias TX_POINTS        $F0     ;Control bytes: a number of points,
.alias TX_ENEMY2        $F1     ;an enemy's name,
.alias TX_AMOUNT_P      $F3     ;
.alias TX_ENEMY         $F4     ;
.alias TX_AMOUNT        $F5     ;an amount,
.alias TX_SPELL         $F6     ;a spell,
.alias TX_ITEM          $F7     ;an item,
.alias TX_NAME          $F8     ;the hero's name,
.alias TX_WAIT          $FB     ;wait for a button,
.alias TX_END           $FC     ;the end of the message,
.alias TX_LINE          $FD     ;a new line.

.alias YN_ROW           12      ;The YES/NO window: 6 by 5 at (21, 12).
.alias YN_COL           21      ;

;Put set B character A at text position (TCol, TRow).
PutTextChar:
        PHA                     ;
        LDA TRow                ;
        CLC                     ;
        ADC #TEXT_ROW           ;
        STA WinRow              ;
        LDA TCol                ;
        CLC                     ;
        ADC #TEXT_COL           ;
        STA WinCol              ;
        PLA                     ;
        JMP PutChar             ;

;Open the dialog window and show the messages at MsgList.
OpenDialog:
        LDA #DLG_ROW            ;Clear its rows.
        STA WinRow              ;
*       LDA #$00                ;
        STA WinCol              ;
*       JSR PutChar             ;
        INC WinCol              ;
        LDX WinCol              ;
        CPX #32                 ;
        BNE -                   ;
        INC WinRow              ;
        LDX WinRow              ;
        CPX #DLG_LAST+1         ;
        BNE --                  ;
        LDA #DLG_ROW            ;The frame, in set B.
        STA WinRow              ;
        LDX #TL_TOP_LEFT        ;
        LDY #TL_TOP             ;
        LDA #TL_TOP_RIGHT       ;
        JSR DialogEdge          ;
*       INC WinRow              ;
        LDX #TL_LEFT            ;
        LDY #TL_BLANK           ;
        LDA #TL_RIGHT           ;
        JSR DialogEdge          ;
        LDA WinRow              ;
        CMP #DLG_ROW+TEXT_LINES ;
        BNE -                   ;
        INC WinRow              ;
        LDX #TL_BOTTOM_LEFT     ;
        LDY #TL_BOTTOM          ;
        LDA #TL_BOTTOM_RIGHT    ;
        JSR DialogEdge          ;
        LDA #$01                ;
        STA DialogOn            ;
        LDA #$00                ;
        STA TCol                ;
        STA TRow                ;
        LDA #$FF                ;
        STA Insert              ;
        LDA #$02                ;
        STA Mode                ;
        JMP NextMessage         ;

;A row of the frame: tile X at the left, Y across, A at the right.
DialogEdge:
        STA Tmp3                ;
        STY Tmp2                ;
        LDA #DLG_COL            ;
        STA WinCol              ;
        LDA TextB,X             ;
        JSR PutChar             ;
        LDX Tmp2                ;
        LDA TextB,X             ;
*       INC WinCol              ;
        JSR PutChar             ;
        LDX WinCol              ;
        CPX #DLG_COL+TEXT_WIDTH ;
        BNE -                   ;
        INC WinCol              ;
        LDX Tmp3                ;
        LDA TextB,X             ;
        JMP PutChar             ;

;Start the next message of MsgList, or, past the last, wait for a button
;to close the window. (The people's lists are in MSG_BANK.)
NextMessage:
        LDA #MSG_BANK           ;
        JSR SelectBank          ;
        LDY #$00                ;
        LDA (MsgList),Y         ;
        STA MsgLo               ;
        INY                     ;
        LDA (MsgList),Y         ;
        STA MsgHi               ;
        CMP #$FF                ;Steps from $FFFD on.
        BNE ListMessage         ;
        LDA MsgLo               ;
        CMP #$FF                ;
        BNE +                   ;
        LDA #$02                ;$FFFF: done.
        STA DlgState            ;
        RTS                     ;
*       CMP #$FE                ;
        BNE +                   ;
        JMP AskYesNo            ;$FFFE: ask YES or NO.
*       CMP #$FC                ;
        BNE +                   ;
        LDA #$01                ;$FFFC: ask YES or NO, and end there.
        STA AskRet              ;
        JMP AskYesNo            ;
*       CMP #$FB                ;
        BNE +                   ;
        JSR NextStep            ;$FFFB: a shop, for the control byte next.
        LDY #$00                ;
        LDA (MsgList),Y         ;
        JMP StartShop           ;
*       JSR NextStep            ;$FFFD: the experience for the next level.
        JSR ExpToLevel          ;
        JMP NextMessage         ;
ListMessage:
        JSR NextStep            ;
        LDA MsgHi               ;A message starts on a line of its own
        BNE MsgOwnLine          ;(but the enemy's chant, after its name).
        LDA MsgLo               ;
        CMP #MSG_EN_CHANT       ;
        BNE MsgOwnLine          ;
        LDA #$5F                ;(A space after the name, as an insert.)
        STA InsertBuf           ;
        LDA #$01                ;
        STA InsertLen           ;
        LDA #$00                ;
        STA Insert              ;
        BEQ MsgLineDone         ;
MsgOwnLine:
        LDA TCol                ;
        BEQ MsgLineDone         ;
        JSR NewLine             ;
MsgLineDone:
        LDA #$00                ;
        STA DlgState            ;
        LDA #MSG_BANK           ;Find it: where it starts (MSG_BANK's
        JSR SelectBank          ;table, 2 bytes a message).
        LDA MsgLo               ;
        ASL                     ;
        STA TextPtr             ;
        LDA MsgHi               ;
        ROL                     ;
        ADC #>MSG_BASE          ;(C is clear: messages are below 512.)
        STA TextPtr+1           ;
        LDY #$00                ;
        LDA (TextPtr),Y         ;
        TAX                     ;
        INY                     ;
        LDA (TextPtr),Y         ;
        STA TextPtr+1           ;
        STX TextPtr             ;
        LDA #TEXT_BANK          ;
        JMP SelectBank          ;

;MsgList on to its next step.
NextStep:
        LDA MsgList             ;
        CLC                     ;
        ADC #$02                ;
        STA MsgList             ;
        BCC +                   ;
        INC MsgList+1           ;
*       RTS                     ;

;Amount = the experience the hero needs for the next level (LevelExp for
;the next level, less the experience).
ExpToLevel:
        LDX Level               ;
        LDA LevelExpLo,X        ;
        SEC                     ;
        SBC Experience          ;
        STA Amount              ;
        LDA LevelExpHi,X        ;
        SBC Experience+1        ;
        STA Amount+1            ;
        RTS                     ;

;Step TextPtr on a byte (A kept).
TextNext:
        INC TextPtr             ;
        BNE +                   ;
        INC TextPtr+1           ;
*       RTS                     ;

;A frame with the dialog window up: print a character, or wait for a
;button (either fire button) at a wait or past the last message.
DialogFrame:
        LDA DlgState            ;
        BEQ PrintStep           ;
        CMP #$03                ;
        BNE +                   ;
        JMP YesNoFrame          ;
*
        LDA Pressed             ;
        AND #BTN_A+BTN_B        ;
        BEQ +                   ;
        LDA DlgState            ;
        CMP #$02                ;
        BEQ CloseDialog         ;
        LDA #$00                ;A wait: go on.
        STA DlgState            ;
*       RTS                     ;

CloseDialog:
        LDA #$00                ;
        STA DialogOn            ;
        STA Mode                ;
        LDA #6                  ;Block rows 9-14, every column.
        STA Rows                ;
        LDX #0                  ;
        LDY #9                  ;
        LDA #16                 ;
        JMP RedrawBlocks        ;

;Print the next character: one a frame, as the game prints at its normal
;speed. Control bytes and spaces at a line's start take no frame.
PrintStep:
        LDA Insert              ;Printing the name, or a number.
        BMI PrintByte           ;
        TAX                     ;
        CPX InsertLen           ;
        BCS NameDone            ;
        INC Insert              ;
        LDA InsertBuf,X         ;
        JMP PrintTile           ;
NameDone:
        LDA #$FF                ;
        STA Insert              ;
PrintByte:
        LDA #TEXT_BANK          ;
        JSR SelectBank          ;
        LDY #$00                ;
        LDA (TextPtr),Y         ;
        JSR TextNext            ;
        CMP #TX_POINTS          ;
        BCC PrintTile           ;
        CMP #TX_END             ;
        BNE +                   ;
        JMP NextMessage         ;
*       CMP #TX_LINE            ;
        BNE +                   ;
        JSR NewLine             ;
        JMP PrintStep           ;
*       CMP #TX_WAIT            ;
        BNE +                   ;
        LDA #$01                ;
        STA DlgState            ;
        RTS                     ;
*       CMP #TX_NAME            ;
        BNE NotName             ;
        LDX #$00                ;The name: its letters to InsertBuf.
NameCopy:
        LDA HeroName,X          ;
        STA InsertBuf,X         ;
        INX                     ;
        CPX NameLen             ;
        BNE NameCopy            ;
        JMP StartInsert         ;
NotName:
        CMP #TX_AMOUNT          ;
        BNE NotAmount           ;
        JSR AmountDigits        ;
        JMP StartInsert         ;
NotAmount:
        CMP #TX_AMOUNT_P        ;The amount, then " Point", and "s" unless
        BNE NotPoints           ;it is 1.
        JSR AmountDigits        ;
        LDY #$00                ;
*       LDA PointsText,Y        ;
        STA InsertBuf,X         ;
        INX                     ;
        INY                     ;
        CPY #$06                ;
        BNE -                   ;
        LDA Amount+1            ;
        BNE +                   ;
        LDA Amount              ;
        CMP #$01                ;
        BEQ StartInsert         ;
*       LDA #$1C                ;s
        STA InsertBuf,X         ;
        INX                     ;
        JMP StartInsert         ;
NotPoints:
        CMP #TX_ENEMY           ;The enemy's name.
        BNE NotEnemy            ;
        LDX #$00                ;
*       CPX EnemyNameLen        ;
        BEQ +                   ;
        LDA EnemyName,X         ;
        STA InsertBuf,X         ;
        INX                     ;
        BNE -                   ;
*       JMP StartInsert         ;
NotEnemy:
        CMP #TX_ENEMY2          ;After "A": "n" before a vowel, a space,
        BNE NotEnemy2           ;the name.
        LDX #$00                ;
        LDA EnemyName           ;
        LDY #$04                ;
*       CMP Vowels,Y            ;
        BEQ +                   ;
        DEY                     ;
        BPL -                   ;
        BMI ++                  ;
*       LDA #$17                ;n
        STA InsertBuf,X         ;
        INX                     ;
*       LDA #$5F                ;
        STA InsertBuf,X         ;
        INX                     ;
        LDY #$00                ;
*       CPY EnemyNameLen        ;
        BEQ +                   ;
        LDA EnemyName,Y         ;
        STA InsertBuf,X         ;
        INX                     ;
        INY                     ;
        BNE -                   ;
*       JMP StartInsert         ;
NotEnemy2:
        CMP #TX_POINTS          ;" Points".
        BNE NotPointsWord       ;
        LDX #$00                ;
*       LDA PointsText,X        ;
        STA InsertBuf,X         ;
        INX                     ;
        CPX #$06                ;
        BNE -                   ;
        LDA #$1C                ;s
        STA InsertBuf,X         ;
        INX                     ;
        JMP StartInsert         ;
NotPointsWord:
        CMP #TX_ITEM            ;An item's name (ItemName's), or a spell's
        BEQ ItemInsert          ;(an item's, SPELL_ITEM on).
        CMP #TX_SPELL           ;
        BNE NotItem             ;
ItemInsert:
        LDX ItemName            ;
        JSR NameOf              ;
        STA ShopTmpN            ;
        LDY #$00                ;
*       LDA (NamePtr),Y         ;
        STA InsertBuf,Y         ;
        INY                     ;
        CPY ShopTmpN            ;
        BNE -                   ;
        TYA                     ;
        TAX                     ;
        JMP StartInsert         ;
NotItem:
        JMP PrintStep           ;

;NamePtr = name X's start (NAME_LO/HI, in MSG_BANK: an item's, a spell's,
;or EN_NAMES on an enemy's), A its length; the text bank in, where it is.
NameOf:
        TXA                     ;
        TAY                     ;(SelectBank loses X.)
        LDA #MSG_BANK           ;
        JSR SelectBank          ;
        LDA NAME_LO,Y           ;
        STA NamePtr             ;
        LDA NAME_HI,Y           ;
        STA NamePtr+1           ;
        LDA NAME_LEN,Y          ;
        PHA                     ;
        LDA #TEXT_BANK          ;
        JSR SelectBank          ;
        PLA                     ;
        RTS                     ;

Vowels:         .byte $24, $28, $2C, $32, $38   ;A E I O U
StartInsert:
        STX InsertLen           ;
        JSR WrapWord            ;A word of its own length.
        LDA #$00                ;
        STA Insert              ;
        JMP PrintStep           ;

;InsertBuf = Amount in decimal digit tiles, without leading zeros; X = how
;many.
AmountDigits:
        LDA Amount              ;
        STA NumLo               ;
        LDA Amount+1            ;
        STA NumHi               ;
        LDX #$00                ;
        STX Lead                ;
        LDY #$00                ;Each power of ten, 10000 down.
AmtPower:
        LDA #$00                ;
        STA Digit               ;
*       LDA NumLo               ;
        SEC                     ;
        SBC PowerLo,Y           ;
        STA Tmp                 ;
        LDA NumHi               ;
        SBC PowerHi,Y           ;
        BCC +                   ;
        STA NumHi               ;
        LDA Tmp                 ;
        STA NumLo               ;
        INC Digit               ;
        BNE -                   ;
*       LDA Digit               ;
        ORA Lead                ;
        BNE +                   ;
        CPY #$04                ;The last digit, even 0.
        BNE ++                  ;
*       LDA Digit               ;
        STA InsertBuf,X         ;Digit tiles are $00-$09.
        INX                     ;
        STA Lead                ;
        INC Lead                ;
*       INY                     ;
        CPY #$05                ;
        BNE AmtPower            ;
        RTS                     ;

;A text tile: a space at a line's start is left out; a word that does not
;fit on the line goes to the next.
PrintTile:
        CMP #TL_BLANK           ;
        BCC PrintLetter         ;
        LDX TCol                ;
        BNE +                   ;
        JMP PrintStep           ;
*       LDA #$00                ;
        JMP PrintChar           ;
PrintLetter:
        PHA                     ;
        LDX Insert              ;Inside the name: no wrapping there.
        BPL ++                  ;
        LDX TCol                ;The first letter of a word (at the line's
        BEQ +                   ;start, or after a space)?
        LDY #$00                ;
        STX Tmp                 ;
        LDA TCol                ;
        CLC                     ;
        ADC #TEXT_COL-1         ;
        STA WinCol              ;
        LDA TRow                ;
        CLC                     ;
        ADC #TEXT_ROW           ;
        STA WinRow              ;
        JSR CharAt              ;
        BNE ++                  ;Not after a space.
*       JSR WrapLetters         ;
*       LDA TCol                ;Every other letter, the text sound.
        LSR                     ;
        BCC +                   ;
        LDA #SFX_TEXT           ;
        JSR PlaySFX             ;
*       PLA                     ;
        TAX                     ;
        LDA TextB,X             ;
PrintChar:
        JSR PutTextChar         ;
        INC TCol                ;
        LDA TCol                ;
        CMP #TEXT_WIDTH         ;
        BNE +                   ;
        JMP NewLine             ;
*       RTS                     ;

;The word starting here (the letter just read and those after it): to the
;next line if it does not fit on this one.
WrapLetters:
        LDA #$01                ;The letter just read.
        STA Count               ;
        LDY #$00                ;
*       LDA (TextPtr),Y         ;
        CMP #TL_BLANK           ;
        BCS +                   ;
        INC Count               ;
        INY                     ;
        BNE -                   ;
*       CMP #TX_NAME            ;A name inside a word.
        BNE WrapCheck           ;
        LDA Count               ;
        CLC                     ;
        ADC NameLen             ;
        STA Count               ;
        JMP WrapCheck           ;
WrapWord:
        LDA InsertLen           ;The name or number, as a word.
        STA Count               ;
WrapCheck:
        LDA TCol                ;
        CLC                     ;
        ADC Count               ;
        CMP #TEXT_WIDTH+1       ;
        BCC +                   ;
        LDA TCol                ;
        BEQ +                   ;Longer than a line: as it comes.
        JSR NewLine             ;
*       RTS                     ;

;A = the character in the ring at (WinRow, WinCol) (Z set if blank).
CharAt:
        LDA TopBlock            ;
        ASL                     ;
        CLC                     ;
        ADC WinRow              ;
        AND #$1F                ;
        LSR                     ;
        TAY                     ;
        LDA #$00                ;
        ROR                     ;
        STA Ptr                 ;
        TYA                     ;
        CLC                     ;
        ADC #>Screen            ;
        STA Ptr+1               ;
        LDA LeftBlock           ;
        ASL                     ;
        CLC                     ;
        ADC WinCol              ;
        AND #$3F                ;
        TAY                     ;
        LDA (Ptr),Y             ;
        RTS                     ;

;To the next line; past the last, the lines move up.
NewLine:
        LDA #$00                ;
        STA TCol                ;
        INC TRow                ;
        LDA TRow                ;
        CMP #TEXT_LINES         ;
        BCC +                   ;
        DEC TRow                ;
        JSR ScrollText          ;
*       RTS                     ;

;Move the text lines up one, and clear the last.
ScrollText:
        LDA #TEXT_ROW           ;
        STA Tmp3                ;Row written.
ScrollLine:
        LDA #TEXT_COL           ;
        STA WinCol              ;
*       LDA Tmp3                ;
        CLC                     ;
        ADC #$01                ;
        STA WinRow              ;
        CMP #TEXT_ROW+TEXT_LINES ;
        LDA #$00                ;The line below, or blank under the last.
        BCS +                   ;
        JSR CharAt              ;
*       LDX Tmp3                ;
        STX WinRow              ;
        JSR PutChar             ;
        INC WinCol              ;
        LDA WinCol              ;
        CMP #TEXT_COL+TEXT_WIDTH ;
        BNE --                  ;
        INC Tmp3                ;
        LDA Tmp3                ;
        CMP #TEXT_ROW+TEXT_LINES ;
        BNE ScrollLine          ;
        RTS                     ;

;--------------------------------------[YES or NO]---------------------------------------------------

;$FFFE in MsgList: open the YES/NO window, the cursor on YES; the yes and no
;lists follow.
AskYesNo:
        LDA #YN_ROW             ;
        STA WinRow              ;
        LDY #$00                ;
YesNoRow:
        LDA #YN_COL             ;
        STA WinCol              ;
*       LDA YesNoTemplate,Y     ;
        STY Tmp3                ;
        JSR PutTileA            ;
        LDY Tmp3                ;
        INY                     ;
        LDA WinCol              ;
        CMP #YN_COL+6           ;
        BNE -                   ;
        INC WinRow              ;
        CPY #6*5                ;
        BNE YesNoRow            ;
        LDA #$00                ;
        STA Answer              ;
        LDA #$01                ;
        STA YesNoOn             ;
        LDA #$03                ;
        STA DlgState            ;
        LDA #TL_ARROW           ;
        JMP PutAnswer           ;

;Put text tile A at the answer's place: YES or NO.
PutAnswer:
        PHA                     ;
        LDA Answer              ;
        ASL                     ;
        CLC                     ;
        ADC #YN_ROW+1           ;
        STA WinRow              ;
        LDA #YN_COL+1           ;
        STA WinCol              ;
        PLA                     ;
        JMP PutTileA            ;

;A frame with the YES/NO window up: the stick moves the cursor, the lower
;fire button answers, the upper one answers NO.
YesNoFrame:
        LDA StickNew            ;
        AND #$05                ;Up or down: the other answer.
        BEQ +                   ;
        LDA #TL_BLANK           ;
        JSR PutAnswer           ;
        LDA Answer              ;
        EOR #$01                ;
        STA Answer              ;
        LDA #TL_ARROW           ;
        JSR PutAnswer           ;
*       LDA Pressed             ;
        AND #BTN_B              ;
        BEQ +                   ;
        LDA #$01                ;
        STA Answer              ;
        BNE YesNoDone           ;
*       LDA Pressed             ;
        AND #BTN_A              ;
        BNE YesNoDone           ;
        RTS                     ;
YesNoDone:
        LDA #$00                ;
        STA YesNoOn             ;
        LDA #3                  ;The map back: block rows 6-8, columns 10-13.
        STA Rows                ;
        LDX #10                 ;
        LDY #6                  ;
        LDA #4                  ;
        JSR RedrawBlocks        ;
        LDA AskRet              ;Asked at $FFFC: the answer ends the list.
        BEQ +                   ;
        LDA #$00                ;
        STA AskRet              ;
        LDA #$02                ;
        STA DlgState            ;
        RTS                     ;
*
        LDA #MSG_BANK           ;(The lists' bank.)
        JSR SelectBank          ;
        LDA Answer              ;Then the yes list or the no list.
        ASL                     ;
        CLC                     ;
        ADC #$02                ;
        TAY                     ;
        LDA (MsgList),Y         ;
        TAX                     ;
        INY                     ;
        LDA (MsgList),Y         ;
        STA MsgList+1           ;
        STX MsgList             ;
        LDA #$00                ;
        STA DlgState            ;
        JMP NextMessage         ;

;" Point", in text tiles.
PointsText:     .byte $5F, $33, $18, $12, $17, $1D

YesNoTemplate:
        .byte $64, $62, $62, $62, $62, $67
        .byte $61, $5F, $3C, $28, $36, $66      ;YES
        .byte $61, $5F, $5F, $5F, $5F, $66
        .byte $61, $5F, $31, $32, $5F, $66      ;NO
        .byte $65, $68, $68, $68, $68, $69
