;Windows: the status window and the command window, drawn into the screen
;ring in the map's character set (set A), which holds the digits, the
;capitals, the frame and the arrow, and 4 slots for the name's letters.
;They open only while the hero stands, so a screen position is a fixed
;place in the ring; closing one draws the map blocks beneath again.

.alias STATUS_ROW       4       ;The status window: 8 by 12 at (2, 4), as on
.alias STATUS_COL       2       ;the NES.
.alias CMD_ROW          2       ;The command window: 16 by 10 at (12, 2).
.alias CMD_COL          12      ;
.alias CMD_WIDTH        16      ;
.alias CMD_HEIGHT       10      ;

.alias TL_BLANK         $5F     ;Text tiles: blank,
.alias TL_LEFT          $61     ;the frame,
.alias TL_TOP           $62     ;
.alias TL_TOP_LEAD      $63     ;(the top border's tile leading into a title)
.alias TL_TOP_LEFT      $64     ;
.alias TL_BOTTOM_LEFT   $65     ;
.alias TL_RIGHT         $66     ;
.alias TL_TOP_RIGHT     $67     ;
.alias TL_BOTTOM        $68     ;
.alias TL_BOTTOM_RIGHT  $69     ;
.alias TL_ARROW         $42     ;and the cursor.
.alias ARROW_CODE       109     ;The arrow's code in set A (convert.py: text from 64,
                                ;10 digits, 26 capitals, 9 frame pieces, then it).

;Put character A at screen row WinRow, column WinCol: in the ring at row
;(TopBlock * 2 + WinRow) mod 32, column (LeftBlock * 2 + WinCol) mod 64,
;and 64 on. A, X and Y are kept.
PutChar:
        STA PcChar              ;
        STY PcY                 ;
        JSR CellAt              ;
        LDA PcChar              ;
        STA (Ptr),Y             ;
        TYA                     ;
        ORA #$40                ;
        TAY                     ;
        LDA PcChar              ;
        STA (Ptr),Y             ;
        LDY PcY                 ;
        RTS                     ;

;A = the character at (WinRow, WinCol).
GetChar:
        STY PcY                 ;
        JSR CellAt              ;
        LDA (Ptr),Y             ;
        LDY PcY                 ;
        RTS                     ;

;Ptr and Y: the ring's place for (WinRow, WinCol).
CellAt:
        LDA TopBlock            ;
        ASL                     ;
        CLC                     ;
        ADC WinRow              ;
        AND #$1F                ;
        LSR                     ;Row * 128: high = row / 2, low = (row AND 1) * 128.
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
        RTS                     ;

;Put text tile A in set A at (WinRow, WinCol), and step to the next column.
PutTileA:
        CMP #TL_ARROW           ;(The cursor drawn: shown at once, its blink
        BNE PutTileOn           ;from the start.)
        LDX #$00                ;
        STX CursorClock         ;
PutTileOn:
        TAX                     ;Its code in set A (TextA: lower case the
        LDA TextA,X             ;capitals'; blanks and tiles set A lacks 0).
        JSR PutChar             ;
        INC WinCol              ;
        RTS                     ;

;Ptr = set A's glyph for code A (CharsetA + A * 8; X and Y kept).
CharPtr:
        STA Ptr                 ;
        LDA #$00                ;
        ASL Ptr                 ;
        ROL                     ;
        ASL Ptr                 ;
        ROL                     ;
        ASL Ptr                 ;
        ROL                     ;
        ADC #>CharsetA          ;(C clear: A below 8.)
        STA Ptr+1               ;
        RTS                     ;

;Draw window template X (TPL_: its tiles, row by row, at its place).
.alias TPL_STATUS       0       ;
.alias TPL_COMMAND      6       ;
.alias TPL_BATTLE       12      ;
.alias TPL_YESNO        18      ;
.alias TplPtr           $6C     ;2: the template.
.alias TplX             $02E0   ;Which,
.alias TplN             $02E1   ;and the cells left in the row.
DrawTemplate:
        STX TplX                ;
        LDA Templates,X         ;
        STA TplPtr              ;
        LDA Templates+1,X       ;
        STA TplPtr+1            ;
        LDA Templates+2,X       ;
        STA WinRow              ;
        LDY #$00                ;
TemplateRow:
        LDX TplX                ;
        LDA Templates+3,X       ;
        STA WinCol              ;
        LDA Templates+4,X       ;
        STA TplN                ;
TemplateCell:
        LDA (TplPtr),Y          ;
        STY Tmp3                ;
        JSR PutTileA            ;
        LDY Tmp3                ;
        INY                     ;
        DEC TplN                ;
        BNE TemplateCell        ;
        INC WinRow              ;
        LDX TplX                ;
        TYA                     ;
        CMP Templates+5,X       ;
        BNE TemplateRow         ;
        RTS                     ;
;Each: its tiles, row, column, width, and size.
Templates:
        .word StatusTemplate
        .byte STATUS_ROW, STATUS_COL, 8, 8*12
        .word CommandTemplate
        .byte CMD_ROW, CMD_COL, CMD_WIDTH, CMD_WIDTH*CMD_HEIGHT
        .word BattleCmdTemplate
        .byte CMD_ROW, CMD_COL, CMD_WIDTH, CMD_WIDTH*6
        .word YesNoTemplate
        .byte YN_ROW, YN_COL, 6, 6*5

;Copy the glyphs of the name's first 4 letters into set A's name slots,
;from set A's own (capitals: set B's are mode 2's, the dialog's).
NameGlyphs:
        LDY #$00                ;
NameGlyph:
        LDX HeroName,Y          ;
        LDA TextA,X             ;Its set A character * 8 (lower case: the
        CMP #TEXT_END           ;capital's). The name window's punctuation
        BCC +                   ;past TEXT_END: blank in a wide town, whose
        LDX MapFreeCode         ;characters have those codes.
        CPX #TEXT_END+1         ;
        BCC +                   ;
        LDA #$00                ;
*       JSR CharPtr             ;
        TYA                     ;Slot NAME_SLOT + Y in set A, * 8.
        CLC                     ;
        ADC #NAME_SLOT          ;
        STA MapPtr              ;
        LDA #$00                ;
        ASL MapPtr              ;
        ROL                     ;
        ASL MapPtr              ;
        ROL                     ;
        ASL MapPtr              ;
        ROL                     ;
        CLC                     ;
        ADC #>CharsetA          ;
        STA MapPtr+1            ;
        STY Tmp                 ;
        LDY #$07                ;
*       LDA (Ptr),Y             ;
        STA (MapPtr),Y          ;
        DEY                     ;
        BPL -                   ;
        LDY Tmp                 ;
        INY                     ;
        CPY #$04                ;
        BNE NameGlyph           ;
        RTS                     ;

;Print the number NumLo/NumHi in decimal, X digits, the last at WinCol,
;without leading zeros (blanks instead).
PrintNumber:
        STX Count               ;
        LDA WinCol              ;
        SEC                     ;
        SBC Count               ;
        STA WinCol              ;
        INC WinCol              ;
        LDA #$00                ;
        STA Lead                ;Non-zero once a digit has been printed.
        LDX #$00                ;Each power of ten, 10000 down.
NumPower:
        LDA #$00                ;
        STA Digit               ;
*       LDA NumLo               ;
        SEC                     ;
        SBC PowerLo,X           ;
        TAY                     ;
        LDA NumHi               ;
        SBC PowerHi,X           ;
        BCC +                   ;
        STA NumHi               ;
        STY NumLo               ;
        INC Digit               ;
        BNE -                   ;
*       TXA                     ;Only the last Count digits are shown.
        CLC                     ;
        ADC Count               ;
        CMP #$05                ;
        BCC NumNext             ;
        LDA Digit               ;
        ORA Lead                ;
        BNE +                   ;
        CPX #$04                ;The last digit, even 0.
        BEQ +                   ;
        LDA #TL_BLANK           ;
        BNE NumPowerNext        ;
*       STA Lead                ;
        LDA Digit               ;Digit tiles are $00-$09.
NumPowerNext:
*       STX Tmp2                ;
        JSR PutTileA            ;
        LDX Tmp2                ;
NumNext:
        INX                     ;
        CPX #$05                ;
        BNE NumPower            ;
        RTS                     ;

PowerLo:        .byte <10000, <1000, <100, <10, <1
PowerHi:        .byte >10000, >1000, >100, >10, >1

;--------------------------------------[Status window]-----------------------------------------------

ShowStatus:
        LDA StatusOn            ;
        BEQ +                   ;
        RTS                     ;
*       LDA #$01                ;
        STA StatusOn            ;
        LDX #TPL_STATUS         ;The template, row by row.
        JSR DrawTemplate        ;

        LDA #STATUS_ROW         ;The name's first 4 letters in the top
        STA WinRow              ;border (set A's name slots; a blank shows
        LDA #STATUS_COL+2       ;blank).
        STA WinCol              ;
        LDX #$00                ;
ShowStatusLoop:
*       LDA #NAME_SLOT          ;
        STX Tmp                 ;
        CLC                     ;
        ADC Tmp                 ;
        LDY HeroName,X          ;
        CPY #TL_BLANK           ;
        BCC +                   ;
        LDA #$00                ;
*       JSR PutChar             ;
        INC WinCol              ;
        INX                     ;
        CPX #$04                ;
        BNE ShowStatusLoop      ;

        LDA #STATUS_ROW+2       ;The numbers, each ending in column 6.
        LDX #2                  ;
        LDY Level               ;
        JSR StatusByte          ;
        LDA #STATUS_ROW+4       ;
        LDX #3                  ;
        LDY HitPoints           ;
        JSR StatusByte          ;
        LDA #STATUS_ROW+6       ;
        LDX #3                  ;
        LDY MagicPoints         ;
        JSR StatusByte          ;
        LDA Gold                ;
        STA NumLo               ;
        LDA Gold+1              ;
        STA NumHi               ;
        LDA #STATUS_ROW+8       ;
        LDX #5                  ;
        JSR StatusNumber        ;
        LDA Experience          ;
        STA NumLo               ;
        LDA Experience+1        ;
        STA NumHi               ;
        LDA #STATUS_ROW+10      ;
        LDX #5                  ;
        JMP StatusNumber        ;

;Number Y, X digits, on status row A.
StatusByte:
        STY NumLo               ;
        LDY #$00                ;
        STY NumHi               ;
StatusNumber:
        STA WinRow              ;
        LDA #STATUS_COL+6       ;
        STA WinCol              ;
        JMP PrintNumber         ;

HideStatus:
        LDA StatusOn            ;
        BEQ +                   ;
        LDA #$00                ;
        STA StatusOn            ;
        LDA #6                  ;Block rows 2-7, columns 1-4.
        STA Rows                ;
        LDX #1                  ;
        LDY #2                  ;
        LDA #4                  ;
        JMP RedrawBlocks        ;
*       RTS                     ;

;--------------------------------------[Command window]----------------------------------------------

;Open the command window (and the status window with it), the cursor on
;TALK.
OpenCommand:
        LDA #SFX_MENU           ;
        JSR PlaySFX             ;
        JSR ShowStatus          ;
        LDX #TPL_COMMAND        ;
        JSR DrawTemplate        ;
        LDA #$00                ;
        STA Cursor              ;
        LDA #TL_ARROW           ;
        JSR PutCursor           ;
        LDA #$01                ;
        STA Mode                ;
        RTS                     ;

;Put text tile A where the cursor is: row 4 + (Cursor / 2) * 2, column 13
;or 21.
PutCursor:
        PHA                     ;
        LDA Cursor              ;
        AND #$FE                ;
        CLC                     ;
        ADC #CMD_ROW+2          ;
        STA WinRow              ;
        LDA Cursor              ;
        AND #$01                ;
        ASL                     ;
        ASL                     ;
        ASL                     ;
        CLC                     ;
        ADC #CMD_COL+1          ;
        STA WinCol              ;
        PLA                     ;
        JMP PutTileA            ;

;The keypad's keys as commands (KBCODE bits 1-4; $FF: none): 1 TALK, 2
;STAIRS, 3 ITEM, 4 SPELL, 5 DOOR, 6 TAKE, 7 STATUS, 8 SEARCH (the most used
;first).
KeyCommand:     .byte $FF, $FF, $FF, $FF, $FF, $FF, 6, 2
                .byte $FF, 7, 5, 1, $FF, 3, 4, 0

;A frame with the command window up: the stick moves the cursor, the upper
;fire button closes the window, the lower one chooses.
CommandFrame:
        LDA Pressed             ;
        AND #BTN_B              ;
        BEQ +                   ;
        JSR CloseCommand        ;
        LDA #$00                ;
        STA Mode                ;
        RTS                     ;
*       LDA Pressed             ;
        AND #BTN_A              ;
        BEQ CmdMove             ;
        JSR Beep                ;(A choice: the menu button's sound.)
        JSR CloseCommand        ;
;Command Cursor (0 TALK, 1 SPELL, 2 STATUS, 3 ITEM, 4 STAIRS, 5 DOOR, 6
;SEARCH, 7 TAKE): from the window, or a keypad key (main.asm's Walk).
DoCommand:
        LDA Cursor              ;STAIRS, on stairs: up or down them.
        CMP #$04                ;
        BNE +                   ;
        JSR TakeStairs          ;
        BCC +                   ;
        RTS                     ;
*       LDA Cursor              ;DOOR, SEARCH, TAKE (treasure.asm).
        CMP #$05                ;
        BNE +                   ;
        JMP DoorCommand         ;
*       CMP #$06                ;
        BNE +                   ;
        JMP SearchCommand       ;
*       CMP #$07                ;
        BNE +                   ;
        JMP TakeCommand         ;
*       LDA Cursor              ;STATUS (status.asm).
        CMP #$02                ;
        BNE +                   ;
        JMP StatusCommand       ;
*       LDA Cursor              ;ITEM: the hero's goods, if any.
        CMP #$03                ;
        BNE +                   ;
        JSR ItemCommand         ;
        BCC +                   ;
        RTS                     ;
*       LDA Cursor              ;SPELL: the spells known, if any.
        CMP #$01                ;
        BNE +                   ;
        JSR SpellCommand        ;
        BCC +                   ;
        RTS                     ;
*       LDA Cursor              ;TALK, to someone in front of the hero:
        BNE +                   ;what they say.
        JSR TalkTo              ;
        BCS CmdSay              ;
*       LDA Cursor              ;Else the command's messages.
        ASL                     ;
        TAX                     ;
        LDA CommandMsgs,X       ;
        STA MsgList             ;
        LDA CommandMsgs+1,X     ;
        STA MsgList+1           ;
CmdSay:
        ORA MsgList             ;None (STATUS): back to walking.
        BNE +                   ;
        STA Mode                ;
        RTS                     ;
*       JMP OpenDialog          ;
CmdMove:
        LDA StickNew            ;
        BEQ CmdDone             ;
        STA Tmp3                ;
        LDX Cursor              ;
        LSR Tmp3                ;Up: a row up.
        BCC +                   ;
        CPX #$02                ;
        BCC +                   ;
        DEX                     ;
        DEX                     ;
*       LSR Tmp3                ;Right: to the right column.
        BCC +                   ;
        TXA                     ;
        AND #$01                ;
        BNE +                   ;
        INX                     ;
*       LSR Tmp3                ;Down: a row down.
        BCC +                   ;
        CPX CmdDownMax                ;
        BCS +                   ;
        INX                     ;
        INX                     ;
*       LSR Tmp3                ;Left: to the left column.
        BCC +                   ;
        TXA                     ;
        AND #$01                ;
        BEQ +                   ;
        DEX                     ;
*       CPX Cursor              ;
        BEQ CmdDone             ;
        STX Tmp2                ;
        LDA #TL_BLANK           ;
        JSR PutCursor           ;
        LDA Tmp2                ;
        STA Cursor              ;
        LDA #TL_ARROW           ;
        JMP PutCursor           ;
CmdDone:
        RTS                     ;

CloseCommand:
        LDA #5                  ;Block rows 1-5, columns 6-13.
        STA Rows                ;
        LDX #6                  ;
        LDY #1                  ;
        LDA #8                  ;
        JMP RedrawBlocks        ;

;C set if someone is on the block in front of the hero: they turn to face
;the hero, and MsgList is what they say (their dialog control byte's).
TalkTo:
        LDX Facing              ;
        LDA HeroX               ;
        CLC                     ;
        ADC DirX,X              ;
        STA BX                  ;
        LDA HeroY               ;
        CLC                     ;
        ADC DirY,X              ;
        STA BY                  ;
        JSR PersonAt            ;
        BCS TalkFound           ;
        JSR GetBlock            ;A counter (the large tile) there: who is
        CMP #BLK_PRINCESS       ;(The princess in the swamp cave: her
        BNE +                   ;rescue, castle.asm.)
        JMP TalkPrincess        ;
*       CMP #$0E                ;behind it, as the game's TALK does.
        BNE TalkNone            ;
        LDX Facing              ;
        LDA BX                  ;
        CLC                     ;
        ADC DirX,X              ;
        STA BX                  ;
        LDA BY                  ;
        CLC                     ;
        ADC DirY,X              ;
        STA BY                  ;
        JSR PersonAt            ;
        BCC TalkNone            ;
TalkFound:
        STX ShopTmpI            ;(Who: KingGwaelin's.)
        LDY PersonCtl,X         ;Its dialog's list (MSG_BANK's tables).
        JSR SelectMsg           ;
                                ;(X lost.)
        LDA DIALOG_LO,Y         ;
        STA MsgList             ;
        LDA DIALOG_HI,Y         ;
        STA MsgList+1           ;
        JSR MapBankIn           ;
        JSR KingGwaelin         ;(The princess brought home: the King's.)
        LDA ModFlags            ;The Dragonlord dead: in Tantegel's hall,
        AND #F_DL_DEAD          ;everyone says the King awaits (the game's
        BEQ +                   ;high message $21).
        LDA MapId               ;
        CMP #TANTEGEL_GF        ;
        BNE +                   ;
        LDA #<KingAwaits        ;
        STA MsgList             ;
        LDA #>KingAwaits        ;
        STA MsgList+1           ;
*       SEC                     ;
        RTS                     ;

KingAwaits:     .word $0121, $FFFF
TalkNone:
        CLC                     ;
        RTS                     ;

;C set if the hero is on stairs that lead somewhere, and has gone there
;(the game's CheckStairs): down, along the map link from here, facing
;right; up, back along the link to here, facing left.
TakeStairs:
        LDA HeroX               ;
        STA BX                  ;
        LDA HeroY               ;
        STA BY                  ;
        JSR GetBlock            ;
        CMP #$05                ;Stairs down.
        BNE StairsUp            ;
        JSR FindLinkFrom        ;
        BCC NoStairs            ;
        JSR StairsSound         ;
        LDA #$01                ;
        JSR GoLinkTo            ;
        SEC                     ;
        RTS                     ;
StairsUp:
        CMP #$03                ;Stairs up.
        BNE NoStairs            ;
        JSR FindLinkTo          ;
        BCC NoStairs            ;
        JSR StairsSound         ;
        LDA #$03                ;
        JSR GoLinkFrom          ;
        SEC                     ;
        RTS                     ;
NoStairs:
        CLC                     ;
        RTS                     ;
StairsSound:
        LDA #SFX_STAIRS         ;
        JMP PlaySFX             ;(X kept.)

;What each command says (the game's messages: 16 * (text block - 1) +
;entry), ending with $FFFF; STATUS says nothing.
CommandMsgs:
        .word MsgTalk, MsgSpell, 0, MsgItem, MsgStairs, MsgDoor, MsgSearch, MsgTake
MsgTalk:        .word $000F, $FFFF      ;No one in front of the hero.
MsgSpell:       .word $0031, $FFFF      ;No spell learned yet.
MsgItem:        .word $003D, $FFFF      ;Nothing to use.
MsgStairs:      .word $000D, $FFFF      ;No stairs under the hero.
MsgDoor:        .word $010B, $FFFF      ;No door beside the hero.
MsgSearch:      .word $00D2, $00D3, $FFFF ;The search, and nothing found.
MsgTake:        .word $00D7, $FFFF      ;No chest under the hero.
