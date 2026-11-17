;Code that runs from a bank: the title, name and password windows, the
;password's making and decoding, and the end credits (code that rarely
;runs, kept out of the program's half for room). It is assembled for
;OVERLAY_AT ($A000) in MSG_BANK: build.py puts there what main.asm
;assembles past the program's half. Enter it with MSG_BANK selected (the
;program's stubs do); its calls into the program that change banks are
;tail calls, or go through FarOut. See docs/ARCHITECTURE.md.

        .org OVERLAY_AT

;The boot's setting up (main.asm's Start, with MSG_BANK in): RAM cleared, a
;new hero, the controller and POKEY, the tables and set B, the display
;list, the sound, the interrupt vectors. (Here for the program's room: it
;runs once a power-on or Reset.)
BootInit:
        LDA #$00                ;
        TAX                     ;Clear zero page, the game state and the
*       STA $00,X               ;display list ($0240-$033F), the people
        STA $0240,X             ;($0400-$07FF), player memory, the screen
        INX                     ;and the map image.
        BNE -                   ;
        LDA #$04                ;
        STA Ptr+1               ;
        LDA #$00                ;
        STA Ptr                 ;
        LDY #$00                ;
*       STA (Ptr),Y             ;
        INY                     ;
        BNE -                   ;
        INC Ptr+1               ;
        LDX Ptr+1               ;
        CPX #$29                ;$0400-$28FF.
        BNE -                   ;
        LDX #NEW_GAME_SIZE-1    ;A new hero.
*       LDA NewGame,X           ;
        STA HeroName,X          ;
        DEX                     ;
        BPL -                   ;
        LDX #$00                ;The name's letters, before its blanks.
*       LDA HeroName,X          ;
        CMP #$5F                ;
        BCS +                   ;
        INX                     ;
        CPX #$08                ;
        BNE -                   ;
*       STX NameLen             ;
        JSR NameStats           ;The name's part in the stats.
        LDA #$06                ;
        STA CmdDownMax          ;
        LDA #$A5                ;
        STA Random              ;
        STA Random+1            ;

        LDA #HERO_HPOS          ;
        JSR HeroAt              ;
        LDA #$00                ;
        STA IRQEN               ;
        STA POTGO               ;
        LDA #$02                ;
        STA SKCTL               ;Scan the keypad (and the top fire button).
        LDA #$04                ;The pots on (the stick's), controller 1:
        STA CONSOL              ;without this they read 0, up and left.
        LDA #$FF                ;
        STA CurBank             ;
        STA Shown               ;
        LDX #<BootTables        ;The tables to RAM (in another bank: through
        LDY #>BootTables        ;FarOut).
        JSR FarOut              ;
        LDA #$FF                ;
        STA Shown               ;
        LDA #START_FACING       ;Facing down (or up, before the King).
        STA Facing              ;
        JSR BuildDList          ;
        JSR InitSound           ;
        LDA #<VBI               ;
        STA VVBLKI              ;
        LDA #>VBI               ;
        STA VVBLKI+1            ;
        LDA #<DLI               ;
        STA VDSLST              ;
        LDA #>DLI               ;
        STA VDSLST+1            ;
        RTS                     ;

;A new hero: the name (in text tiles, padded with blanks), level, HP, MP,
;gold and experience.
NewGame:
.include "name.asm"
        .byte START_LEVEL, START_HP-START_HURT, START_MP-START_DRAIN ;(Level 1, all HP, but in tests.)
        .word START_GOLD, START_EXP ;Gold, experience (0 but in tests).
        .byte START_HP, START_MP, START_STR, START_AGI ;Max HP, max MP, strength, agility.
        .byte START_EQUIP, START_KEYS, 0 ;Equipment, keys (none but in tests), herbs.
        .byte START_INV0, START_INV1, START_INV2, START_INV3 ;Items (none but in tests),
        .byte START_FLAGS       ;the flags (ModFlags: none but in tests).

.alias NameMode         $07B1   ;The window: 0 the password's, 1 the name's.
.alias GridLast         $07B2   ;Its grid's last cell (the name's: END).
.alias NAME_MAX         8       ;
.alias PwOk             $07B4   ;A password was right (the name asked for).
.alias MSC_INTRO        $01     ;The title's music (the game's DoIntroRoutine),
.alias MSC_VILLAGE      $04     ;and the start menu's (its pre-game windows').
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
        LDA #$00                ;The screen on, the title drawn (the map
        STA Loading             ;behind it was loaded quietly).
        LDA #MSC_INTRO          ;
        JSR PlayMusic           ;
        LDX #2+3*TITLE_TEXT     ;Its text rows mode 2 (LMS, VSCROL,
TitleMode2:                     ;HSCROL), the row above with TitleDLI.
        LDA #$72                ;
        STA DList,X             ;
        INX                     ;
        INX                     ;
        INX                     ;
        CPX #2+3*TITLE_ROWS     ;
        BNE TitleMode2          ;
        LDY #$00                ;An interrupt on the row before each band
TitleBandBits:                  ;(TitleDLI).
        CPY #TITLE_BANDS*5      ;
        BEQ TitleBandsSet       ;
        LDA TitleBands,Y        ;
        STA Tmp                 ;
        ASL                     ;
        CLC                     ;
        ADC Tmp                 ;
        CLC                     ;
        ADC #$02                ;
        TAX                     ;
        LDA DList,X             ;
        ORA #$80                ;
        STA DList,X             ;
        TYA                     ;
        CLC                     ;
        ADC #$05                ;
        TAY                     ;
        JMP TitleBandBits       ;
TitleBandsSet:
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
        BNE TitleUpNext         ;
*       LDA Pressed             ;
        AND #BTN_A+BTN_B        ;
        BNE +                   ;
        RTS                     ;
TitleUpNext:
*       LDX #<TitleEnd          ;Then the start menu, on a blank screen.
        LDY #>TitleEnd          ;
        JSR FarOut              ;
        LDA #$06                ;(LoadMap leaves Mode 0.)
        STA Mode                ;
        JSR BlankView           ;
        JSR MenuOpen            ;
        LDA #$00                ;The screen on, the menu drawn (the map
        STA Loading             ;behind it reloaded quietly).
        RTS                     ;
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
        BCC PwEnteringNext      ;row, END).
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
PwEnteringNext:
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
        BNE PwEnterBeep         ;
        RTS                     ;
PwEnterBeep:
        JSR Beep                ;(A choice: the menu button's sound.)
        LDA NameMode            ;
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
        JSR NameStats           ;Right: the name's part in the stats, and the
        LDA PwHP                ;HP and MP as kept (no more than the max;
        CMP MaxHP               ;cursed, or none, 1, as the game starts a
        BCC PwHPMax             ;cursed hero).
        LDA MaxHP               ;
PwHPMax:
        LDX Flags2              ;
        CPX #F2_BELT            ;(F2_BELT or F2_NECK: cursed.)
        BCS PwHPOne             ;
        TAX                     ;
        BNE PwHPSet             ;
PwHPOne:
        LDA #$01                ;
PwHPSet:
        STA HitPoints           ;
        LDA PwMP                ;
        CMP MaxMP               ;
        BCC PwMPSet             ;
        LDA MaxMP               ;
PwMPSet:
        STA MagicPoints         ;
        LDX #<NameGlyphs        ;
        LDY #>NameGlyphs        ;
        JSR FarOut              ;
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
NameEndLoop:
*       LDA #TL_BLANK           ;
        CPX Tmp                 ;
        BCS +                   ;
        LDY PwChars,X           ;
        LDA NameTiles,Y         ;
*       STA HeroName,X          ;
        DEX                     ;
        BPL NameEndLoop         ;
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
;goes: the name's along row 7, the password's as PwAt places them from
;there.
PwTypedAt:
        LDA #EN_ROW+1           ;
        STA WinRow              ;
        LDA #EN_COL+2           ;
        STA WinCol              ;
        LDA PwLen               ;
        AND #$7F                ;
        TAX                     ;
        LDY NameMode            ;
        BEQ PwAt                ;
        CLC                     ;
        ADC WinCol              ;
        STA WinCol              ;
        RTS                     ;
;WinRow, WinCol from a password's first place on = character X's (X kept):
;16 a row, a column between each 4.
PwAt:
        TXA                     ;
        AND #$10                ;(Its row.)
        BEQ +                   ;
        INC WinRow              ;
*       TXA                     ;
        AND #$0F                ;
        STA Tmp                 ;
        LSR                     ;
        LSR                     ;
        CLC                     ;
        ADC Tmp                 ;
        ADC WinCol              ;
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
        JSR PwScramble          ;
        JSR PwCheck             ;
        CMP PwBuf+PW_BODY       ;
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
        LDA PwBuf+9             ;
        STA Equipped            ;
        LDA PwBuf+10            ;
        STA ModFlags            ;
        LDA PwBuf+11            ;
        STA Flags2              ;
        LDA PwBuf+12            ;(HP and MP once the stats are: PwPassed.)
        STA PwHP                ;
        LDA PwBuf+13            ;
        STA PwMP                ;
        LDX #$00                ;The name: 5 bits a character, the first at
        STX NameLen             ;the top.
PwNameChar:
        LDA #$00                ;
        STA Tmp                 ;
        LDY #$05                ;
*       ASL PwBuf+18            ;
        ROL PwBuf+17            ;
        ROL PwBuf+16            ;
        ROL PwBuf+15            ;
        ROL PwBuf+14            ;
        ROL Tmp                 ;
        DEY                     ;
        BNE -                   ;
        LDY Tmp                 ;
        LDA NameTiles,Y         ;
        STA HeroName,X          ;
        CMP #TL_BLANK           ;(Its length: to the last not blank.)
        BEQ +                   ;
        STX NameLen             ;
        INC NameLen             ;
*       INX                     ;
        CPX #NAME_MAX           ;
        BNE PwNameChar          ;
        JSR SelectMsg           ;(The level tables' bank.)
        LDA #$01                ;The level the experience is, its stats,
        STA Level               ;HP and MP full.
PwNameCharLoop:
*       LDX Level               ;
        CPX #30                 ;
        BCS PwNameCharNext      ;
        LDA Experience+1        ;
        CMP LevelExpHi,X        ;
        BCC PwNameCharNext      ;
        BNE +                   ;
        LDA Experience          ;
        CMP LevelExpLo,X        ;
        BCC PwNameCharNext      ;
*       INC Level               ;
        BNE PwNameCharLoop      ;
PwNameCharNext:
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
        BEQ CrLinesDone         ;
        CMP #$FD                ;A picture's characters (the last two
        BNE CrRowAt             ;screens'): their count, then each's 8
        JSR CrByte              ;bytes, over the capitals' (build.py).
        ASL                     ;
        ASL                     ;
        ASL                     ;
        STA Count               ;
        LDX #$00                ;
CrGlyph:
        JSR CrByte              ;(Y lost, X kept.)
        STA CR_GLYPHS_AT,X      ;
        INX                     ;
        CPX Count               ;
        BNE CrGlyph             ;
        BEQ CrLine              ;
CrRowAt:
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
CrLinesDone:
        RTS                     ;

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
        LDA Herbs               ;Keys and herbs, a nibble each.
        ASL                     ;
        ASL                     ;
        ASL                     ;
        ASL                     ;
        ORA Keys                ;
        STA PwBuf+8             ;
        LDA Equipped            ;
        STA PwBuf+9             ;
        LDA ModFlags            ;
        STA PwBuf+10            ;
        LDA Flags2              ;What is worn, the curses.
        STA PwBuf+11            ;
        LDA HitPoints           ;
        STA PwBuf+12            ;
        LDA MagicPoints         ;
        STA PwBuf+13            ;
        LDX #$04                ;Then the name: 8 characters of 5 bits
        LDA #$00                ;(their places in NameTiles), the first at
*       STA PwBuf+14,X          ;the top.
        DEX                     ;
        BPL -                   ;
        LDX #$00                ;
PwPackName:
        LDA HeroName,X          ;
        LDY #31                 ;(Not in the grid: lower case, its capital;
*       CMP NameTiles,Y         ;else a blank.)
        BEQ PwNameAt            ;
        DEY                     ;
        BPL -                   ;
        LDY #31                 ;
        SEC                     ;
        SBC #$0A                ;
        CMP #26                 ;
        BCS PwNameAt            ;
        TAY                     ;
PwNameAt:
        TYA                     ;
        ASL                     ;
        ASL                     ;
        ASL                     ;
        STA Tmp                 ;
        LDY #$05                ;
*       ASL Tmp                 ;
        ROL PwBuf+18            ;
        ROL PwBuf+17            ;
        ROL PwBuf+16            ;
        ROL PwBuf+15            ;
        ROL PwBuf+14            ;
        DEY                     ;
        BNE -                   ;
        INX                     ;
        CPX #NAME_MAX           ;
        BNE PwPackName          ;
        JSR PwCheck             ;
        STA PwBuf+PW_BODY       ;
;PwBuf's first PW_BODY bytes XORed with the sequence from its check (its own
;inverse: the same unscrambles).
PwScramble:
        LDA PwBuf+PW_BODY       ;
        STA PwKey               ;
        LDY #$00                ;
PwScrambleLoop:
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
        CPY #PW_BODY            ;
        BNE PwScrambleLoop      ;
        RTS                     ;

;A = the CRC-8 of PwBuf's first PW_BODY bytes.
PwCheck:
        LDA #$5A                ;
        LDY #$00                ;
PwCrcByte:
        EOR PwBuf,Y             ;
        LDX #$08                ;
PwCrcByteLoop:
*       ASL                     ;
        BCC +                   ;
        EOR #$07                ;
*       DEX                     ;
        BNE PwCrcByteLoop       ;
        INY                     ;
        CPY #PW_BODY            ;
        BNE PwCrcByte           ;
        RTS                     ;

;PwBuf shifted left a bit, C in at the bottom, its top bit out in C (X kept).
PwShift:
        STX Tmp2                ;
        LDX #PW_BODY            ;
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
;then its 32 characters), until a button.
PwShowStep:
        JSR PackState           ;
        JSR PwEncode            ;
        LDA #PW_ROW             ;
        STA WinRow              ;
        LDA #PW_COL             ;
        STA WinCol              ;
        LDA #$02                ;
        STA Rows                ;
        LDA #PW_WIDTH           ;
        STA PwW                 ;
        JSR PwFrame             ;
        LDX #$00                ;
PwShowChar:
        STX PwLen               ;
        LDA #PW_ROW+1           ;
        STA WinRow              ;
        LDA #PW_COL+2           ;
        STA WinCol              ;
        JSR PwAt                ;
        LDA PwChars,X           ;
        JSR PwPut               ;
        LDX PwLen               ;
        INX                     ;
        CPX #PW_LEN             ;
        BNE PwShowChar          ;
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
        BNE StepEndWaitNext     ;
        LDX #<CloseDialog       ;(It redraws the map: a bank change.)
        LDY #>CloseDialog       ;
        JSR FarOut              ;
        LDA #$04                ;(Still the ending's steps.)
        STA Mode                ;
        LDA #$01                ;Facing right.
StepEndWaitLoop:
*       STA Facing              ;
        LDA #$FF                ;(Drawn again.)
        STA Shown               ;
        LDA #30                 ;
        BNE EndWait             ;
StepEndWaitNext:
*       CMP #$02                ;
        BNE +                   ;
        LDA #$02                ;Facing down.
        BNE StepEndWaitLoop     ;
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

;After the title (the play build), on a blank screen, the game's own start
;menu words (build.py's menuwords.asm, from the ROM's window data): continue
;a quest (the password window), begin a new quest (the name window), change
;the message speed (each choice the next; the speed shown below it, the
;game's word for it). (The game's order has the speed second: last here,
;so its word is under it.) The stick up or down, the lower button or the
;keypad's Start to choose; the cursor starts on the new quest.
.alias MenuSel          $07C6   ;0 continue, 1 a new quest, 2 the speed.
.alias ME_ROW           10      ;
MenuOpen:
        LDA Song                ;The pre-game music, unless it is on (back
        CMP #MSC_VILLAGE        ;from the name or password window).
        BEQ +                   ;
        LDA #MSC_VILLAGE        ;
        JSR PlayMusic           ;
*       LDA #$02                ;
        STA TitleOn             ;
        LDA #$01                ;
        STA MenuSel             ;
        LDA #$00                ;
        STA PwLen               ;
        STA Pressed             ;
        LDA #ME_ROW             ;
        STA WinRow              ;
        LDA #ME_COL             ;
        STA WinCol              ;
        LDA #4                  ;
        STA Rows                ;
        LDA #ME_LEN+3           ;
        STA PwW                 ;
        JSR PwFrame             ;
        LDX #$00                ;The game's lines: continue,
        LDA #ME_ROW+1           ;
        JSR MenuLine            ;
        LDX #2*ME_LEN           ;a new quest,
        LDA #ME_ROW+2           ;
        JSR MenuLine            ;
        LDX #ME_LEN             ;the speed.
        LDA #ME_ROW+3           ;
        JSR MenuLine            ;
        JSR MenuSpeed           ;
        JMP MenuArrow           ;
;Row A: MenuWords from X (ME_LEN tiles), X past them.
MenuLine:
        STA WinRow              ;
        LDA #ME_COL+2           ;
        STA WinCol              ;
        LDA #ME_LEN             ;
        STA PwT2                ;
MenuLetter:
        LDA MenuWords,X         ;
        STX PwT1                ;
        JSR PutTileA            ;
        LDX PwT1                ;
        INX                     ;
        DEC PwT2                ;
        BNE MenuLetter          ;
        RTS                     ;
;The speed's row, below the choices: its word for TextSpeed.
MenuSpeed:
        LDA #ME_ROW+4           ;
        STA WinRow              ;
        LDA #ME_COL+4           ;
        STA WinCol              ;
        LDX TextSpeed           ;
        LDA SpeedAt,X           ;
        TAX                     ;
        LDA #SPEED_LEN          ;
        STA PwT2                ;
SpeedLetter:
        LDA SpeedText,X         ;
        STX PwT1                ;
        JSR PutTileA            ;
        LDX PwT1                ;
        INX                     ;
        DEC PwT2                ;
        BNE SpeedLetter         ;
        RTS                     ;
SpeedAt:        .byte 0, SPEED_LEN, 2*SPEED_LEN
.include "menuwords.asm"
;The cursor at the choice, blanks at the others.
MenuArrow:
        LDY #$00                ;
MenuArrowRow:
        LDA #ME_COL+1           ;
        STA WinCol              ;
        TYA                     ;
        CLC                     ;
        ADC #ME_ROW+1           ;
        STA WinRow              ;
        LDA #TL_BLANK           ;
        CPY MenuSel             ;
        BNE MenuNoArrow         ;
        LDA #TL_ARROW           ;
MenuNoArrow:
        STY PwT1                ;
        JSR PutTileA            ;
        LDY PwT1                ;
        INY                     ;
        CPY #3                  ;
        BNE MenuArrowRow        ;
        RTS                     ;
MenuFrame:
        LDA StickNew            ;Up: the one above (round to the last).
        AND #$01                ;
        BEQ MenuNotUp           ;
        LDX MenuSel             ;
        DEX                     ;
        BPL MenuMove            ;
        LDX #2                  ;
        BNE MenuMove            ;
MenuNotUp:
        LDA StickNew            ;Down: the one below (round to the first).
        AND #$04                ;
        BEQ MenuNotDown         ;
        LDX MenuSel             ;
        INX                     ;
        CPX #3                  ;
        BNE MenuMove            ;
        LDX #0                  ;
MenuMove:
        STX MenuSel             ;
        JSR MenuArrow           ;
MenuNotDown:
        LDA KeyNew              ;
        CMP #KEY_START          ;
        BEQ MenuPick            ;
        LDA Pressed             ;
        AND #BTN_A              ;
        BNE MenuPick            ;
        RTS                     ;
MenuPick:
        JSR Beep                ;(A choice: the menu button's sound.)
        LDA #$00                ;
        STA Pressed             ;
        LDA MenuSel             ;The speed: the next one, shown.
        CMP #2                  ;
        BNE MenuGo              ;
        LDX TextSpeed           ;
        INX                     ;
        CPX #3                  ;
        BNE MenuSetSpeed        ;
        LDX #0                  ;
MenuSetSpeed:
        STX TextSpeed           ;
        JMP MenuSpeed           ;
MenuGo:
        LDA #$03                ;
        STA TitleOn             ;
        LDA MenuSel             ;
        BNE +                   ;
        JMP PwOpen              ;
*       JMP NameOpen            ;

;The view blank (a screen with nothing on it but windows).
BlankView:
        LDA #$00                ;
        STA CrRow               ;
BlankViewLoop:
*       LDA CrRow               ;
        STA WinRow              ;
        LDA #$FB                ;Columns -5 to 36: the normal playfield's
        STA WinCol              ;and a column more each side.
        LDA #42                 ;
        STA Count               ;
*       LDA #TL_BLANK           ;
        JSR PutTileA            ;
        DEC Count               ;
        BNE -                   ;
        INC CrRow               ;
        LDA CrRow               ;
        CMP #28                 ;
        BNE BlankViewLoop       ;
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

;--------------------------------------[Story steps (from castle.asm)]------------------------------

;The special characters' steps, run here for the program's room: the
;Dragonlord's offer and LordStep's dispatch (StepStart enters it with
;MSG_BANK selected), the rainbow drop's and the staff of rain's keepers,
;the MP wizard, the princess's question and the King's keepsake, the curse
;lifter and the ring man. Their calls that change banks go through FarOut.

;His offer refused: the fight. Taken: all the hero had is gone (ZeroStats)
;and the game ends there, the dialog's last message up.
LordStep:
        LDA #$00                ;
        STA ShopState           ;
        LDA ShopCtl             ;
        CMP #RAINBOW_MAN        ;
        BEQ RainbowMan          ;
        CMP #RAIN_MAN           ;
        BEQ RainMan             ;
        CMP #GWAELIN            ;
        BNE +                   ;
        JMP GwaelinAsk          ;
*       CMP #KING_GW            ;
        BNE +                   ;
        JMP KingGwStep          ;
*       CMP #PW_SHOW            ;
        BNE +                   ;
        JMP PwShowP             ;
*       CMP #CURSE_MAN          ;
        BNE +                   ;
        JMP CurseMan            ;
*       CMP #RING_MAN           ;
        BNE +                   ;
        JMP RingMan             ;
*       CMP #MP_MAN             ;
        BNE +                   ;
        JMP MpMan               ;
*       CMP #ENDING             ;(Steps in MSG_BANK: run next.)
        BNE +                   ;
        LDA #EG_END             ;
        STA ShopState           ;
        RTS                     ;
*       CMP #DS_FULL            ;(Steps in MSG_BANK: run next.)
        BNE +                   ;
        LDA #DS_ASK             ;
        STA ShopState           ;
        RTS                     ;
*       CMP #END_GW             ;
        BNE +                   ;
        LDA #EG_ASK             ;
        STA ShopState           ;
        RTS                     ;
*
        CMP #LORD_JOIN          ;
        BEQ LordJoin            ;
        LDX #<CloseDialog       ;(It redraws the map: through FarOut.)
        LDY #>CloseDialog       ;
        JSR FarOut              ;
        LDA #EN_DRAGONLORD      ;
        JMP StartBattle         ;
LordJoin:
        LDA #$00                ;Gold and experience,
        LDX #$03                ;
*       STA Gold,X              ;
        DEX                     ;
        BPL -                   ;
        LDX #ModFlags-Equipped  ;and the equipment, keys, herbs, items and
*       STA Equipped,X          ;flags.
        DEX                     ;
        BPL -                   ;
        JSR RedrawStatus        ;
        LDA #LORD_END           ;
        STA ShopState           ;
StepLordEnd:
        RTS                     ;

;The old man of the rainbow drop's cave (the game's $6D dialog): with the
;drop already, nothing for the hero; without Erdrick's token, the hero is
;sent out of the cave; with it, the stones of sunlight and the staff of
;rain become the rainbow drop, or he says what is wanted.
RainbowMan:
        LDA #ITM_DROP           ;
        JSR HasItem             ;
        BCC +                   ;
        LDA #$A5                ;He has nothing for the hero.
        JMP ShopEnd             ;
*       LDA #ITM_TOKEN          ;
        JSR HasItem             ;
        BCS +                   ;
        LDA #$B3                ;The task failed: out of the cave.
        LDX #RM_EXIT            ;
        JMP ShopSay             ;
*       LDA #ITM_STONES         ;
        JSR HasItem             ;
        BCC RainbowNot          ;
        LDA #ITM_STAFF          ;
        JSR HasItem             ;
        BCC RainbowNot          ;
        LDA #ITM_STONES         ;The sun and the rain meet: the drop.
        JSR RemoveItem          ;
        LDA #ITM_STAFF          ;
        JSR RemoveItem          ;
        LDA #ITM_DROP           ;
        JSR AddItem             ;
        LDA #30                 ;The screen grey for half a second.
        STA GreyTime            ;
        LDA #$B4                ;
        JMP ShopEnd             ;
RainbowNot:
        LDA #$49                ;What the bridge wants,
        LDX #RM_MORE            ;
        JMP ShopSay             ;
StepRmMore:
        LDA #$AE                ;and that he has waited.
        JMP ShopEnd             ;

;The old man of the staff of rain's cave (the game's $6C dialog): with the
;drop or the staff already, nothing for the hero; with the silver harp, it
;is taken and he goes, leaving the staff's chest free; else his test.
RainMan:
        LDA #ITM_DROP           ;
        JSR HasItem             ;
        BCS +                   ;
        LDA #ITM_STAFF          ;
        JSR HasItem             ;
        BCC RainManNext         ;
*       LDA #$A5                ;He has nothing for the hero.
        JMP ShopEnd             ;
RainManNext:
*       LDA #ITM_HARP           ;
        JSR HasItem             ;
        BCS +                   ;
        LDA #$B1                ;His test.
        JMP ShopEnd             ;
*       LDA #ITM_HARP           ;The harp taken, and he goes (the only one
        JSR RemoveItem          ;there: no one left on the map).
        JSR CondHere            ;(His block what was under him.)
        LDA #$00                ;
        STA PeopleOn            ;
        LDA #<RainTalk          ;What he says.
        LDY #>RainTalk          ;
        JMP SayList             ;

RainTalk:       .word $00B2, $00A4, $00C6, $FFFF

;Sent out: by the cave's link, facing down (CheckMapExit).
StepRmExit:
        LDA #FX_SPELL           ;The screen grey and back first, as the
        LDX #40                 ;game's BWScreenFlash, then out.
        JSR StartFx             ;
RmExitWait:
        LDA FxTime              ;
        BNE RmExitWait          ;
        LDA #$00                ;
        STA ShopState           ;
        JMP LeaveMap            ;

;The wizard who gives MP back (the game's $6A dialog): his words, the
;screen grey and back (BWScreenFlash), and all the hero's MP.
MpMan:
        LDA #FX_SPELL           ;
        LDX #40                 ;
        JSR StartFx             ;
        LDA MaxMP               ;
        STA MagicPoints         ;
        JSR RedrawStatus        ;
        LDA #$AD                ;
        JMP ShopEnd             ;

GwaelinAsk:
        LDA #$C5                ;
        LDX #GW_ASKED           ;
        JMP ShopAsk             ;
StepGwAsked:
        LDA Answer              ;
        BEQ +                   ;
        LDA #$B6                ;NO: she asks again.
        LDX #GW_AGAIN           ;
        JMP ShopSay             ;
*       LDA ModFlags            ;YES: she is carried, her block floor.
        ORA #F_CARRY            ;
        STA ModFlags            ;
        LDA #PRINCESS_X         ;
        STA BX                  ;
        LDA #PRINCESS_Y         ;
        STA BY                  ;
        LDA #BLK_BRICK          ;
        LDX #<SetBlock          ;(It reads and draws the map: through
        LDY #>SetBlock          ;FarOut.)
        JSR FarOut              ;
        LDA #$00                ;
        STA ShopState           ;
        RTS                     ;

KingGwStep:
        LDA ModFlags            ;
        AND #$FF-F_CARRY        ;
        ORA #F_RETURNED         ;
        STA ModFlags            ;
        LDA #ITM_LOVE           ;
        JSR AddItem             ;
        BCC StepGwKeep          ;
        LDA #$00                ;Full: the first of KeepTake held is taken
        STA ShopTmpI            ;for it (none: no keepsake).
*       LDX ShopTmpI            ;
        LDA KeepTake,X          ;
        JSR HasItem             ;
        BCS +                   ;
        INC ShopTmpI            ;
        LDA ShopTmpI            ;
        CMP #$07                ;
        BNE -                   ;
        BEQ StepGwKeep          ;
*       LDX ShopTmpI            ;
        LDA KeepTake,X          ;
        PHA                     ;
        JSR RemoveItem          ;
        PLA                     ;
        CLC                     ;
        ADC #ITM_BASE           ;
        STA ItemName            ;
        LDA #ITM_LOVE           ;
        JSR AddItem             ;
        LDA #$BA                ;And something of the hero's for the King.
        LDX #GW_KEEP            ;
        JMP ShopSay             ;
StepGwKeep:
        LDA #$BB                ;
        LDX #GW_BYE             ;
        JMP ShopSay             ;
;What the King may take for it (InvListTbl): torch, dragon's scale,
;fighter's ring, fairy water, wings, cursed belt, staff of rain.
KeepTake:       .byte 1, 4, 6, 2, 3, 9, 13
StepGwBye:
        LDA #$BC                ;
        JMP ShopEnd             ;

;The curse lifter (ChkCursedDialog): not cursed, come again; else the
;cursed items gone and the curse with them.
CurseMan:
        LDA Flags2              ;
        AND #F2_CURSED          ;
        BNE +                   ;
        LDA #$A6                ;
        JMP ShopEnd             ;
*       BPL +                   ;(Bit 7: the necklace.)
        LDA #$0B                ;
        JSR RemoveItem          ;
*       BIT Flags2              ;
        BVC +                   ;
        LDA #$09                ;
        JSR RemoveItem          ;
*       LDA Flags2              ;
        AND #$FF-F2_CURSED      ;
        STA Flags2              ;
        LDA #$A7                ;
        LDX #CF_DONE            ;
        JMP ShopSay             ;
StepCfDone:
        LDA #$A8                ;
        JMP ShopEnd             ;

;The ring man (ChkRingDialog): wearing it (it still had), his other words.
RingMan:
        LDA #$06                ;
        JSR HasItem             ;
        BCS +                   ;
        LDA Flags2              ;
        AND #$FF-F2_RING        ;
        STA Flags2              ;
*       LDA Flags2              ;
        LSR                     ;
        LDA #$AC                ;
        BCC +                   ;
        LDA #$AB                ;
*       JMP ShopEnd             ;

