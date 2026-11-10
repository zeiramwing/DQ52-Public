;Code that runs from a bank: the title, name and password windows, the
;password's making and decoding, and the end credits (code that rarely
;runs, kept out of the program's half for room). It is assembled for
;OVERLAY_AT ($A000) in MSG_BANK: build.py puts there what main.asm
;assembles past the program's half. Enter it with MSG_BANK selected (the
;program's stubs do); its calls into the program that change banks are
;tail calls, or go through FarOut. See docs/ARCHITECTURE.md.

        .org OVERLAY_AT

.alias NameMode         $07B1   ;The window: 0 the password's, 1 the name's.
.alias GridLast         $07B2   ;Its grid's last cell (the name's: END).
.alias NAME_MAX         8       ;
.alias PwOk             $07B4   ;A password was right (the name asked for).
.alias TitleOn          $07BB   ;The title: 1 shown, 2 gone.
.alias TITLE_ROWS       28      ;

;The first frame (Mode 6): the upper fire button held, the password
;window; else the name window (NAME_ENTRY: test builds start with the
;build's name). Then (PwLen $80 + : entering) each frame: the stick moves
;the cursor over the grid, the lower button enters its character (the
;password's 20th: tried; the name's END: done), the upper one takes the
;last back (none, in the password window: the name window after all).
PasswordFrame:
        LDA PwLen               ;
        BMI PwEntering          ;
        LDA #NAME_ENTRY         ;With the name window, the title first.
        BEQ PwNoTitle           ;
        LDA TitleOn             ;
        BNE TitleWait           ;
        LDX #<TitleShow         ;
        LDY #>TitleShow         ;
        JSR FarOut              ;
        LDX #2+3*TITLE_TEXT     ;Its text rows mode 2 (LMS, VSCROL,
TitleMode2:                     ;HSCROL), the row above with TitleDLI.
        LDA #$72                ;
        STA DList,X             ;
        INX                     ;
        INX                     ;
        INX                     ;
        CPX #2+3*TITLE_ROWS     ;
        BNE TitleMode2          ;
        LDA DList+2+3*TITLE_TEXT-3 ;
        ORA #$80                ;
        STA DList+2+3*TITLE_TEXT-3 ;
        INC TitleOn             ;
        RTS                     ;
TitleWait:
        CMP #$01                ;
        BEQ TitleUp             ;
        CMP #$02                ;
        BNE PwNoTitle           ;
        JMP MenuFrame           ;
TitleUp:
        LDA KeyNew              ;Until a button: the lower (or the keypad's
        CMP #KEY_START          ;Start), the name window; the upper, the
        BNE +                   ;password's.
        LDA #BTN_A              ;
        BNE ++                  ;
*       LDA Pressed             ;
        AND #BTN_A+BTN_B        ;
        BNE +                   ;
        RTS                     ;
*       LDX #<TitleEnd          ;Then the start menu, on a blank screen.
        LDY #>TitleEnd          ;
        JSR FarOut              ;
        LDA #$06                ;(LoadMap leaves Mode 0.)
        STA Mode                ;
        JSR BlankView           ;
        JMP MenuOpen            ;
PwNoTitle:
        LDA Buttons             ;
        AND #BTN_B              ;
        BNE PwOpen              ;
PwNoPassword:
        LDA #NAME_ENTRY         ;
        BNE NameOpen            ;
PwNewGame:
        LDA #$00                ;None asked for: the new adventure (nothing
        STA Mode                ;drawn over the map).
        STA Pressed             ;
        LDX PwLen               ;
        STA PwLen               ;
        TXA                     ;
        BEQ PwKingFirst         ;
        LDX #<DrawView          ;(From the window: the map back over it;
        LDY #>DrawView          ;from the start menu's, the people and the
        LDA #NAME_ENTRY         ;hero too.)
        BEQ PwBack              ;
        LDX #<GameStart         ;
        LDY #>GameStart         ;
PwBack:
        JSR FarOut              ;
PwKingFirst:
*       LDA #NAME_ENTRY         ;Before the King (the play build): his
        BEQ +                   ;first words (FirstKingDialog).
        LDA MapId               ;
        CMP #THRONE_MAP         ;
        BNE +                   ;
        LDA #<KingFirst         ;
        LDY #>KingFirst         ;
        JMP SayList             ;
*       RTS                     ;
KingFirst:      .word $0102, $FFFF
;After a password (the game's adventure log): glad the hero has returned,
;the experience for the next level, farewell.
KingBack:       .word $0117, $FFFD, $00C1, $0118, $00C4, $FFFF
PwOpen:
        LDA #$00                ;
        LDX #31                 ;
        LDY #6                  ;
        BNE PwWindow            ;
NameOpen:
        LDA #$00                ;
        STA Pressed             ;
        LDA #$01                ;
        LDX #32                 ;
        LDY #7                  ;
PwWindow:
        STA NameMode            ;The window: its frame, the grid.
        STX GridLast            ;
        STY Rows                ;
        LDA #EN_ROW             ;
        STA WinRow              ;
        LDA #EN_COL             ;
        STA WinCol              ;
        LDA #22                 ;
        STA PwW                 ;
        JSR PwFrame             ;
        LDX #$00                ;
*       STX PwCur               ;
        TXA                     ;
        JSR PwGridAt            ;
        LDA PwCur               ;
        JSR CellPut             ;
        LDX PwCur               ;
        CPX GridLast            ;
        INX                     ;
        BCC -                   ;
        LDA #$80                ;None entered, the cursor on A.
        STA PwLen               ;
        LDA #$00                ;
        STA PwCur               ;
        LDA #TL_ARROW           ;
        JMP PwCursor            ;
PwEntering:
        LDA StickNew            ;
        BEQ PwButtons           ;
        PHA                     ;
        LDA #TL_BLANK           ;
        JSR PwCursor            ;
        PLA                     ;
        LDX PwCur               ;
        LSR                     ;Up: a row up.
        BCC +                   ;
        CPX #8                  ;
        BCC +                   ;
        PHA                     ;
        TXA                     ;
        SBC #8                  ;
        TAX                     ;
        PLA                     ;
*       LSR                     ;Right.
        BCC +                   ;
        CPX GridLast            ;
        BCS +                   ;
        INX                     ;
*       LSR                     ;Down: a row down (from the name's last
        BCC ++                  ;row, END).
        PHA                     ;
        TXA                     ;
        CLC                     ;
        ADC #8                  ;
        CMP GridLast            ;
        BCC +                   ;
        BEQ +                   ;
        LDA GridLast            ;
        CMP #32                 ;
        BEQ +                   ;
        TXA                     ;
*       TAX                     ;
        PLA                     ;
*       LSR                     ;Left.
        BCC +                   ;
        CPX #$00                ;
        BEQ +                   ;
        DEX                     ;
*       STX PwCur               ;
        LDA #TL_ARROW           ;
        JSR PwCursor            ;
PwButtons:
        LDA Pressed             ;
        AND #BTN_B              ;
        BEQ PwEnter             ;
        LDA PwLen               ;Back a character, or (none) the name
        AND #$7F                ;window.
        BNE +                   ;
        LDA #NAME_ENTRY         ;(The play build: back to the start menu.)
        BNE PwToMenu            ;
        LDA NameMode            ;
        BEQ PwNoPassword        ;
        RTS                     ;
PwToMenu:
        JSR BlankView           ;
        JMP MenuOpen            ;
*       DEC PwLen               ;
        JSR PwTypedAt           ;
        LDA #TL_BLANK           ;
        JMP PutTileA            ;
PwEnter:
        LDA Pressed             ;
        AND #BTN_A              ;
        BNE +                   ;
        RTS                     ;
*       LDA NameMode            ;
        BEQ PwType              ;
        LDA PwCur               ;
        CMP #32                 ;
        BEQ NameEnd            ;
        LDA PwLen               ;
        CMP #$80+NAME_MAX       ;
        BCC PwType              ;
        RTS                     ;
PwType:
        JSR PwTypedAt           ;The cursor's character, entered.
        LDA PwCur               ;
        STA PwChars,X           ;
        JSR CellPut             ;
        INC PwLen               ;
        LDA NameMode            ;
        BNE PwTyped             ;
        LDA PwLen               ;
        CMP #$80+PW_LEN         ;
        BNE PwTyped             ;
        JSR PwDecode            ;All 20: tried.
        BCS PwPassed            ;
        LDA #SFX_WALL           ;Wrong: all of them gone.
        JSR PlaySFX             ;
PwWrong:
        DEC PwLen               ;
        JSR PwTypedAt           ;
        LDA #TL_BLANK           ;
        JSR PutTileA            ;
        LDA PwLen               ;
        CMP #$80                ;
        BNE PwWrong             ;
PwTyped:
        RTS                     ;
PwPassed:
        LDA #NAME_ENTRY         ;Right: the name asked for, then the King.
        BEQ +                   ;
        STA PwOk                ;
        JMP NameOpen            ;
*       JSR NameFull            ;
PwGood:
        LDA #$00                ;Before the King, facing him (the button
        STA Pressed             ;used up: walking goes on this frame).
        STA PwLen               ;
        STA Facing              ;
        LDA #THRONE_X           ;
        STA HeroX               ;
        LDA #THRONE_Y           ;
        STA HeroY               ;
        LDX #<RedrawStatus      ;
        LDY #>RedrawStatus      ;
        JSR FarOut              ;
        LDA Flags2              ;(The throne room left: its chests gone,
        ORA #F2_LEFT            ;as the game's log keeps it.)
        STA Flags2              ;
        LDA #THRONE_MAP         ;
        STA MapId               ;
        LDX #<GameStart         ;(The people, the hero, the map.)
        LDY #>GameStart         ;
        JSR FarOut              ;
        LDA #<KingBack          ;
        LDY #>KingBack          ;
        JMP SayList             ;

;END: the name (one character at least), padded with blanks, its part in
;the level's stats (the password's level, or the new hero's), HP and MP
;full; the King, after a password, else the new adventure.
NameEnd:
        LDA PwLen               ;
        AND #$7F                ;
        BEQ PwTyped             ;
        STA Tmp                 ;
        LDX #NAME_MAX-1         ;
*       LDA #TL_BLANK           ;
        CPX Tmp                 ;
        BCS +                   ;
        LDY PwChars,X           ;
        LDA NameTiles,Y         ;
*       STA HeroName,X          ;
        DEX                     ;
        BPL --                  ;
        LDX #NAME_MAX           ;Its length: up to the last that is not
*       DEX                     ;blank.
        BEQ +                   ;
        LDA HeroName,X          ;
        CMP #TL_BLANK           ;
        BEQ -                   ;
*       INX                     ;
        STX NameLen             ;
        LDA PwOk                ;
        BNE NameStatsIn         ;
        LDX #$03                ;The new hero's level's own stats.
*       LDA NewGame+15,X        ;
        STA MaxHP,X             ;
        DEX                     ;
        BPL -                   ;
NameStatsIn:
        JSR NameFull            ;
        LDX #<NameGlyphs        ;
        LDY #>NameGlyphs        ;
        JSR FarOut              ;
        LDX #<RedrawStatus      ;
        LDY #>RedrawStatus      ;
        JSR FarOut              ;
        LDA #$00                ;
        STA NameMode            ;
        LDA PwOk                ;
        BNE PwGood              ;
        JMP PwNewGame           ;(The new adventure, from the window.)

;The name's part in the stats, HP and MP full.
NameFull:
        JSR NameStats           ;
        LDA MaxHP               ;
        STA HitPoints           ;
        LDA MaxMP               ;
        STA MagicPoints         ;
        RTS                     ;

;Grid cell A at (WinRow, WinCol): the password's characters (PwPut), or
;the name's (NameTiles; END the last).
CellPut:
        LDX NameMode            ;
        BNE +                   ;
        JMP PwPut               ;
*       CMP #32                 ;
        BEQ +                   ;
        TAX                     ;
        LDA NameTiles,X         ;
        JMP PutTileA            ;
*       LDA #$28                ;E,
        JSR PutTileA            ;
        LDA #$31                ;N,
        JSR PutTileA            ;
        LDA #$27                ;D.
        JMP PutTileA            ;

;The name's characters: A-Z, then - ' . ! ? and a blank (the game's text
;tiles).
NameTiles:
        .byte $24, $25, $26, $27, $28, $29, $2A, $2B, $2C, $2D, $2E, $2F, $30
        .byte $31, $32, $33, $34, $35, $36, $37, $38, $39, $3A, $3B, $3C, $3D
        .byte $49, $40, $47, $4C, $4B, $5F

;WinRow, WinCol (X = PwLen's count) = where the next character entered
;goes, on row 7.
PwTypedAt:
        LDA #EN_ROW+1           ;
        STA WinRow              ;
        LDA PwLen               ;
        AND #$7F                ;
        TAX                     ;
        CLC                     ;
        ADC #EN_COL+2           ;
        STA WinCol              ;
        RTS                     ;

;WinRow, WinCol = grid character A's place (8 a row, 2 columns each).
PwGridAt:
        PHA                     ;
        LSR                     ;
        LSR                     ;
        LSR                     ;
        CLC                     ;
        ADC #EN_GRID            ;
        STA WinRow              ;
        PLA                     ;
        AND #$07                ;
        ASL                     ;
        CLC                     ;
        ADC #EN_COL+4           ;
        STA WinCol              ;
        RTS                     ;

;Tile A left of the cursor's character.
PwCursor:
        PHA                     ;
        LDA PwCur               ;
        JSR PwGridAt            ;
        DEC WinCol              ;
        PLA                     ;
        JMP PutTileA            ;

;The adventure from PwChars: C set if its check holds (and it is taken
;up), else C clear and nothing changed.
PwDecode:
        LDX #$00                ;
PwDecChar:
        LDA PwChars,X           ;Its 5 bits to the top.
        ASL                     ;
        ASL                     ;
        ASL                     ;
        STA Tmp                 ;
        LDY #$05                ;
*       ASL Tmp                 ;
        JSR PwShift             ;
        DEY                     ;
        BNE -                   ;
        INX                     ;
        CPX #PW_LEN             ;
        BNE PwDecChar           ;
        LDY #$04                ;(100 bits in: 4 more to the top.)
*       CLC                     ;
        JSR PwShift             ;
        DEY                     ;
        BNE -                   ;
        JSR PwScramble          ;
        JSR PwCheck             ;
        CMP PwBuf+11            ;
        BEQ +                   ;
        CLC                     ;
        RTS                     ;
*       LDX #$03                ;
*       LDA PwBuf,X             ;
        STA Gold,X              ;
        LDA PwBuf+4,X           ;
        STA Inventory,X         ;
        DEX                     ;
        BPL -                   ;
        LDA PwBuf+8             ;
        AND #$07                ;
        STA Keys                ;
        LDA PwBuf+8             ;
        LSR                     ;
        LSR                     ;
        LSR                     ;
        LSR                     ;
        AND #$07                ;
        STA Herbs               ;
        LDA PwBuf+8             ;The curses.
        AND #$08                ;
        ASL                     ;
        ASL                     ;
        ASL                     ;
        STA Flags2              ;
        LDA PwBuf+8             ;
        AND #F2_NECK            ;
        ORA Flags2              ;
        STA Flags2              ;
        LDA PwBuf+9             ;
        STA Equipped            ;
        LDA PwBuf+10            ;
        STA ModFlags            ;
        JSR SelectMsg           ;(The level tables' bank.)
        LDA #$01                ;The level the experience is, its stats,
        STA Level               ;HP and MP full.
*       LDX Level               ;
        CPX #30                 ;
        BCS ++                  ;
        LDA Experience+1        ;
        CMP LevelExpHi,X        ;
        BCC ++                  ;
        BNE +                   ;
        LDA Experience          ;
        CMP LevelExpLo,X        ;
        BCC ++                  ;
*       INC Level               ;
        BNE --                  ;
*       DEX                     ;
        LDA LevelStr,X          ;
        STA Strength            ;
        LDA LevelAgi,X          ;
        STA Agility             ;
        LDA LevelHP,X           ;
        STA MaxHP               ;
        LDA LevelMP,X           ;
        STA MaxMP               ;
        SEC                     ;
        RTS                     ;

;--------------------------------------[The end credits]---------------------------------------------

.alias CrPtr            $07B5   ;2: the credits' next byte (build.py's
.alias CrWait           $07B7   ;2: frames to the next screen,   credits),
.alias CrOn             $07B9   ;their screens begun (the map gone).
.alias CrRow            $07BA   ;

;Each frame of the credits (DoEndCredits): a screen's wait, then (but
;after the last, which stays) it fades out (FadeSub up, a step every
;other frame), the next screen is drawn, and it fades in.
.alias CrPhase          $07C0   ;0: its wait, 1: fading in, 2: fading out.
.alias FADE_DARK        15      ;
CreditsFrame:
        LDA CrPhase             ;
        BEQ CrHold              ;
        LDA FrameCount          ;
        LSR                     ;
        BCC CrFaded             ;
        LDA CrPhase             ;
        CMP #$01                ;
        BNE CrDarker            ;
        DEC FadeSub             ;In: to the colors as they are.
        BNE CrFaded             ;
        BEQ CrPhaseDone         ;
CrDarker:
        INC FadeSub             ;Out: to black, then the next.
        LDA FadeSub             ;
        CMP #FADE_DARK          ;
        BNE CrFaded             ;
        JSR CrNext              ;
        LDA #$01                ;
        STA CrPhase             ;
        RTS                     ;
CrPhaseDone:
        LDA #$00                ;
        STA CrPhase             ;
CrFaded:
        RTS                     ;
CrHold:
        LDA CrWait              ;
        ORA CrWait+1            ;
        BEQ CrWaited            ;
        LDA CrWait              ;
        BNE +                   ;
        DEC CrWait+1            ;
*       DEC CrWait              ;
        RTS                     ;
CrWaited:
        LDA CrOn                ;The first: from the map, at once.
        BNE +                   ;
        JSR CrNext              ;
        LDA #FADE_DARK          ;
        STA FadeSub             ;
        LDA #$01                ;
        STA CrPhase             ;
        RTS                     ;
*       JSR CrPeek              ;The last: kept.
        CMP #$FE                ;
        BEQ CrFaded             ;
        LDA #$02                ;
        STA CrPhase             ;
        RTS                     ;
;A = the credits' next byte, CrPtr left there.
CrPeek:
        JSR CrByte              ;
        LDA CrPtr               ;
        BNE +                   ;
        DEC CrPtr+1             ;
*       DEC CrPtr               ;
        LDY #$00                ;
        LDA (Ptr),Y             ;
        RTS                     ;
CrNext:
        JSR CrByte              ;
        CMP #$FE                ;
        BNE CrScreen            ;
        LDA CrPtr               ;The end: kept there.
        BNE +                   ;
        DEC CrPtr+1             ;
*       DEC CrPtr               ;
        RTS                     ;
CrScreen:
        LDX #$03                ;The wait: its units of 8 frames.
        STX Tmp                 ;
        LDX #$00                ;
        STX CrWait+1            ;
*       ASL                     ;
        ROL CrWait+1            ;
        DEC Tmp                 ;
        BNE -                   ;
        STA CrWait              ;
        LDA CrOn                ;The first: no people, the hero gone.
        BNE +                   ;
        INC CrOn                ;
        LDX #<TownBattle        ;
        LDY #>TownBattle        ;
        JSR FarOut              ;
        LDA #$00                ;
        JSR HeroAt              ;
*       JSR BlankView           ;The view blank.
CrLine:
        JSR CrByte              ;Its rows: row, column, length, tiles.
        CMP #$FF                ;
        BEQ ++                  ;
        STA WinRow              ;
        JSR CrByte              ;
        STA WinCol              ;
        JSR CrByte              ;
        STA Count               ;
*       JSR CrByte              ;
        JSR PutTileA            ;
        DEC Count               ;
        BNE -                   ;
        BEQ CrLine              ;
*       RTS                     ;

;A = the credits' next byte (through Ptr, which PutTileA also uses).
CrByte:
        LDA CrPtr               ;
        STA Ptr                 ;
        LDA CrPtr+1             ;
        STA Ptr+1               ;
        LDY #$00                ;
        LDA (Ptr),Y             ;
        INC CrPtr               ;
        BNE +                   ;
        INC CrPtr+1             ;
*       RTS                     ;

;--------------------------------------[The password's making]--------------------------------------

;PwBuf = the adventure, packed, its check, scrambled.
PackState:
        LDX #$03                ;Gold, experience.
*       LDA Gold,X              ;
        STA PwBuf,X             ;
        LDA Inventory,X         ;The items.
        STA PwBuf+4,X           ;
        DEX                     ;
        BPL -                   ;
        LDA Herbs               ;Keys and herbs, a nibble each, and in each
        ASL                     ;nibble's spare top bit a curse: the belt's
        ASL                     ;in bit 3, the necklace's in bit 7.
        ASL                     ;
        ASL                     ;
        ORA Keys                ;
        STA PwBuf+8             ;
        LDA Flags2              ;
        AND #F2_BELT            ;
        LSR                     ;
        LSR                     ;
        LSR                     ;
        ORA PwBuf+8             ;
        STA PwBuf+8             ;
        LDA Flags2              ;
        AND #F2_NECK            ;
        ORA PwBuf+8             ;
        STA PwBuf+8             ;
        LDA Equipped            ;
        STA PwBuf+9             ;
        LDA ModFlags            ;
        STA PwBuf+10            ;
        JSR PwCheck             ;
        STA PwBuf+11            ;
        LDA #$00                ;
        STA PwBuf+12            ;
;PwBuf's first 11 bytes XORed with the sequence from its check (its own
;inverse: the same unscrambles).
PwScramble:
        LDA PwBuf+11            ;
        STA PwKey               ;
        LDY #$00                ;
*       LDA PwKey               ;
        EOR PwBuf,Y             ;
        STA PwBuf,Y             ;
        LDA PwKey               ;
        ASL                     ;
        ASL                     ;
        CLC                     ;
        ADC PwKey               ;
        CLC                     ;
        ADC #$3B                ;
        STA PwKey               ;
        INY                     ;
        CPY #11                 ;
        BNE -                   ;
        RTS                     ;

;A = the CRC-8 of PwBuf's first 11 bytes.
PwCheck:
        LDA #$5A                ;
        LDY #$00                ;
PwCrcByte:
        EOR PwBuf,Y             ;
        LDX #$08                ;
*       ASL                     ;
        BCC +                   ;
        EOR #$07                ;
*       DEX                     ;
        BNE --                  ;
        INY                     ;
        CPY #11                 ;
        BNE PwCrcByte           ;
        RTS                     ;

;PwBuf shifted left a bit, C in at the bottom, its top bit out in C (X kept).
PwShift:
        STX Tmp2                ;
        LDX #12                 ;
*       ROL PwBuf,X             ;
        DEX                     ;
        BPL -                   ;
        LDX Tmp2                ;
        RTS                     ;

;PwChars = PwBuf, 5 bits each, the top first.
PwEncode:
        LDX #$00                ;
PwEncChar:
        LDA #$00                ;
        STA Tmp                 ;
        LDY #$05                ;
*       CLC                     ;
        JSR PwShift             ;
        ROL Tmp                 ;
        DEY                     ;
        BNE -                   ;
        LDA Tmp                 ;
        STA PwChars,X           ;
        INX                     ;
        CPX #PW_LEN             ;
        BNE PwEncChar           ;
        RTS                     ;

;Character A (0-31) at (WinRow, WinCol): A-Z, then 2-7.
PwPut:
        CMP #26                 ;
        BCC +                   ;
        SBC #26-2               ;(C set: 26 on are 2 on.)
        JMP PutTileA            ;
*       ADC #$24                ;(Capitals from $24.)
        JMP PutTileA            ;

;A frame of tiles X, Y across, A at the end, from WinCol, Count wide.
PwEdge:
        STA PwT1                ;
        STY PwT2                ;
        TXA                     ;
        JSR PutTileA            ;
*       LDA PwT2                ;
        JSR PutTileA            ;
        DEC Count               ;
        BNE -                   ;
        LDA PwT1                ;
        JMP PutTileA            ;

;A window's frame at (WinRow, WinCol): Rows rows inside, PwW  wide.
PwFrame:
        LDA WinCol              ;
        STA PwKey               ;(Its left column, kept.)
        LDA PwW                 ;
        STA Count               ;
        LDX #TL_TOP_LEFT        ;
        LDY #TL_TOP             ;
        LDA #TL_TOP_RIGHT       ;
        JSR PwEdge              ;
*       INC WinRow              ;
        LDA PwKey               ;
        STA WinCol              ;
        LDA PwW                 ;
        STA Count               ;
        LDX #TL_LEFT            ;
        LDY #TL_BLANK           ;
        LDA #TL_RIGHT           ;
        JSR PwEdge              ;
        DEC Rows                ;
        BNE -                   ;
        INC WinRow              ;
        LDA PwKey               ;
        STA WinCol              ;
        LDA PwW                 ;
        STA Count               ;
        LDX #TL_BOTTOM_LEFT     ;
        LDY #TL_BOTTOM          ;
        LDA #TL_BOTTOM_RIGHT    ;
        JMP PwEdge              ;

;--------------------------------------[The King's]--------------------------------------------------

;The deeds recorded: the password in a window over the map (its frame,
;then its 20 characters), until a button.
PwShowStep:
        JSR PackState           ;
        JSR PwEncode            ;
        LDA #PW_ROW             ;
        STA WinRow              ;
        LDA #PW_COL             ;
        STA WinCol              ;
        LDA #$01                ;
        STA Rows                ;
        LDA #PW_LEN             ;
        STA PwW                 ;
        JSR PwFrame             ;
        LDA #PW_ROW+1           ;
        STA WinRow              ;
        LDA #PW_COL+1           ;
        STA WinCol              ;
        LDX #$00                ;
*       STX PwLen               ;
        LDA PwChars,X           ;
        JSR PwPut               ;
        LDX PwLen               ;
        INX                     ;
        CPX #PW_LEN             ;
        BNE -                   ;
        LDA #PW_WAIT            ;
        STA ShopState           ;
        RTS                     ;
StepPwWait:
        LDA Pressed             ;
        AND #BTN_A+BTN_B        ;
        BNE +                   ;
        RTS                     ;
*       LDA #$00                ;The map back beneath it: block rows 0-1,
        STA ShopState           ;columns 2-13.
        LDA #2                  ;
        STA Rows                ;
        LDX #2                  ;
        LDY #0                  ;
        LDA #12                 ;
        JMP RedrawBlocks        ;

;--------------------------------------[The ending's steps]-----------------------------------------

;(castle.asm's EndTrigger starts them; the step runner enters this bank.)
StepEgAsk:
        LDA #$1E                ;
        LDX #EG_ASKED           ;
        JSR ShopHi              ;
        LDA #$FC                ;(Asked.)
        STA BattleList+2        ;
        JMP NextMessage         ;
StepEgAsked:
        LDA Answer              ;
        BEQ +                   ;
        LDA #$B6                ;NO: she asks again.
        LDX #EG_ASK             ;
        JMP ShopSay             ;
*       LDA ModFlags            ;YES: carried.
        ORA #F_CARRY            ;
        STA ModFlags            ;
        LDA #$B8                ;
        LDX #EG_TALE            ;
        JMP ShopSay             ;
StepEgTale:
        LDA #$22                ;The tale's end, then the pauses.
        LDX #EG_END             ;
        JSR ShopHi              ;
        JMP NextMessage         ;
;Its pauses (TaleEnd): 120 frames with the words up, then the window gone
;and the hero facing right; 30 more, facing down; 30 more, the end music,
;and the game stays there (as the game's does after its credits).
EndStep:
        LDA #120                ;
EndWait:
        STA SleepTime           ;
        LDA #END_WAIT           ;
        STA ShopState           ;
        RTS                     ;
StepEndWait:
        DEC SleepTime           ;
        BEQ +                   ;
        RTS                     ;
*       INC EndPhase            ;
        LDA EndPhase            ;
        CMP #$01                ;
        BNE ++                  ;
        LDX #<CloseDialog       ;(It redraws the map: a bank change.)
        LDY #>CloseDialog       ;
        JSR FarOut              ;
        LDA #$04                ;(Still the ending's steps.)
        STA Mode                ;
        LDA #$01                ;Facing right.
*       STA Facing              ;
        LDA #$FF                ;(Drawn again.)
        STA Shown               ;
        LDA #30                 ;
        BNE EndWait             ;
*       CMP #$02                ;
        BNE +                   ;
        LDA #$02                ;Facing down.
        BNE --                  ;
*       LDA #MSC_END            ;The end music, and after its first part,
        JSR PlayMusic           ;the credits (poweron.asm).
        LDA #<CREDITS_AT        ;
        STA CrPtr               ;
        LDA #>CREDITS_AT        ;
        STA CrPtr+1             ;
        LDA #CR_FANFARE         ;
        STA CrWait              ;
        LDA #$00                ;
        STA CrWait+1            ;
        LDA #CR_RUN             ;
        STA ShopState           ;
        RTS                     ;
.alias CR_FANFARE       240     ;Frames of the end music before them.

;--------------------------------------[The start menu]---------------------------------------------

;After the title (the play build), on a blank screen: NEW GAME (the name
;window) or CONTINUE (the password window); the stick up or down, the lower
;button or the keypad's Start to choose. (Its words are the port's own.)
.alias MenuSel          $07C6   ;0 NEW GAME, 1 CONTINUE.
.alias ME_ROW           10      ;
.alias ME_COL           10      ;
MenuOpen:
        LDA #$02                ;
        STA TitleOn             ;
        LDA #$00                ;
        STA PwLen               ;
        STA MenuSel             ;
        STA Pressed             ;
        LDA #ME_ROW             ;
        STA WinRow              ;
        LDA #ME_COL             ;
        STA WinCol              ;
        LDA #2                  ;
        STA Rows                ;
        LDA #10                 ;
        STA PwW                 ;
        JSR PwFrame             ;
        LDX #$00                ;
        LDA #ME_ROW+1           ;
        JSR MenuLine            ;
        LDA #ME_ROW+2           ;
        JSR MenuLine            ;
        JMP MenuArrow           ;
;Row A: MenuWords from X (8 letters), X past them.
MenuLine:
        STA WinRow              ;
        LDA #ME_COL+2           ;
        STA WinCol              ;
*       LDA MenuWords,X         ;
        STX PwT1                ;
        JSR PutTileA            ;
        LDX PwT1                ;
        INX                     ;
        TXA                     ;
        AND #$07                ;
        BNE -                   ;
        RTS                     ;
MenuWords:      .byte $31, $28, $3A, $5F, $2A, $24, $30, $28 ;NEW GAME
                .byte $26, $32, $31, $37, $2C, $31, $38, $28 ;CONTINUE
;The cursor at the choice, a blank at the other.
MenuArrow:
        LDA #ME_COL+1           ;
        STA WinCol              ;
        LDA #ME_ROW+1           ;
        STA WinRow              ;
        LDA MenuSel             ;(NEW GAME's row: the arrow at 0.)
        JSR MenuMark            ;
        LDA #ME_COL+1           ;
        STA WinCol              ;
        INC WinRow              ;
        LDA MenuSel             ;
        EOR #$01                ;
MenuMark:
        BEQ +                   ;(A 0: the arrow.)
        LDA #TL_BLANK           ;
        JMP PutTileA            ;
*       LDA #TL_ARROW           ;
        JMP PutTileA            ;
MenuFrame:
        LDA StickNew            ;Up or down: the other.
        AND #$05                ;
        BEQ +                   ;
        LDA MenuSel             ;
        EOR #$01                ;
        STA MenuSel             ;
        JSR MenuArrow           ;
*       LDA KeyNew              ;
        CMP #KEY_START          ;
        BEQ MenuPick            ;
        LDA Pressed             ;
        AND #BTN_A              ;
        BNE MenuPick            ;
        RTS                     ;
MenuPick:
        LDA #$03                ;
        STA TitleOn             ;
        LDA #$00                ;
        STA Pressed             ;
        LDA MenuSel             ;
        BEQ +                   ;
        JMP PwOpen              ;
*       JMP NameOpen            ;

;The view blank (a screen with nothing on it but windows).
BlankView:
        LDA #$00                ;
        STA CrRow               ;
*       LDA CrRow               ;
        STA WinRow              ;
        LDA #$00                ;
        STA WinCol              ;
        LDA #32                 ;
        STA Count               ;
*       LDA #TL_BLANK           ;
        JSR PutTileA            ;
        DEC Count               ;
        BNE -                   ;
        INC CrRow               ;
        LDA CrRow               ;
        CMP #28                 ;
        BNE --                  ;
        RTS                     ;

;------------------------------------[A full bag (DiscardItem)]--------------------------------------


StepDsAsk:
        LDA #$CC                ;To take it, something must be dropped:
        LDX #DS_ASKED           ;
        JMP ShopAsk             ;
StepDsAsked:
        LDA Answer              ;
        BNE DsKeep              ;
StepDsWhich:
        LDA #$CE                ;which one?
        LDX #DS_LIST            ;
        JMP ShopSay             ;
DsKeep:
        LDA DsItem              ;The find given up.
        CLC                     ;
        ADC #ITM_BASE           ;
        STA ItemName            ;
        LDA #$CD                ;
        JMP ShopEnd             ;
StepDsList:
        JSR GoodsList           ;
        LDA #$01                ;
        STA ListKind            ;
        LDX #DS_PICK            ;
        JMP OpenList            ;
StepDsPick:
        JSR ChosenItem          ;
        BCS DsKeep              ;
        STA DsDrop              ;
        LDY #$08                ;Not the important ones (NonDiscardTbl).
*       CMP NoDrop,Y            ;
        BEQ DsNo                ;
        DEY                     ;
        BPL -                   ;
        CMP #BELT_ITEM          ;Nor a curse that is worn.
        BNE +                   ;
        BIT Flags2              ;
        BVS DsCursed            ;
*       CMP #NECK_ITEM          ;
        BNE +                   ;
        BIT Flags2              ;
        BMI DsCursed            ;
*       STA ItemName            ;The one dropped,
        LDA #$CF                ;
        LDX #DS_GOT             ;
        JMP ShopSay             ;
DsNo:
        LDA #$D1                ;Refused: a quest item.
        LDX #DS_WHICH           ;
        JMP ShopSay             ;
DsCursed:
        LDA #$18                ;Cursed: it cannot be taken off.
        LDX #DS_WHICH           ;
        JMP ShopSay             ;
StepDsGot:
        LDA DsDrop              ;and the new one is his.
        SEC                     ;
        SBC #ITM_BASE           ;
        JSR RemoveItem          ;
        LDA DsItem              ;
        JSR AddItem             ;
        LDA DsItem              ;
        CLC                     ;
        ADC #ITM_BASE           ;
        STA ItemName            ;
        LDA #$D0                ;
        JMP ShopEnd             ;

NoDrop:
        .byte HERB_ITEM, KEY_ITEM, ITM_BASE+5, ITM_BASE+7, ITM_BASE+8
        .byte ITM_BASE+10, ITM_BASE+12, ITM_BASE+13, ITM_BASE+14
