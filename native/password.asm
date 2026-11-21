;Passwords: the 5200 keeps nothing at power-off (the NES kept its logs in
;battery-backed RAM), so the King shows a password when he records the
;hero's deeds, and holding the upper fire button at power-on asks for one.
;
;A password holds all the game's own log keeps: the experience and gold,
;the items, keys and herbs, the equipment, the flags (ModFlags), what is
;worn and the curses (Flags2), the HP and MP, and the name (its 8
;characters, 5 bits each): 19 bytes, then a check byte (CRC-8, polynomial
;$07, from $5A), the 19 scrambled by a sequence started from the check
;(each next = the last * 5 + $3B) so that like adventures do not look
;alike. Its 160 bits are 32 characters of 5 bits: A-Z, then 2-7, shown
;and entered in two rows of 16, 4 at a time. The level and its stats
;come back from the experience and the name, as the game's do.

.alias PwBuf            $3B00   ;20: the bytes (in the RAM the people's frames had),
.alias PwChars          $3B20   ;32: the characters (0-31),
.alias PwLen            $07A4   ;how many are entered,
.alias PwCur            $07A5   ;the entry grid's cursor (0-31),
.alias PwKey            $07A6   ;the scrambling sequence (and a frame's column),
.alias PwT1             $07A7   ;temporaries.
.alias PwT2             $07A8   ;
.alias PwW              $07A9   ;A frame's width inside.
.alias PW_LEN           32      ;
.alias PW_BODY          19      ;The bytes before the check.
.alias PW_WIDTH         21      ;The King's window inside: 16 characters, 3 gaps, a column each side.
.alias PwHP             $3B40   ;The password's HP and MP, until the stats are.
.alias PwMP             $3B41   ;
.alias PW_SHOW          $F7     ;The King's step (maps.py), after the deeds are
.alias PW_WAIT          47      ;recorded; a button then closes it.
.alias PW_ROW           1       ;Where the King shows it: rows 1-4,
.alias PW_COL           5       ;columns 5-27.
.alias EN_ROW           6       ;The entry window: rows 6-13, columns 4-27:
.alias EN_COL           4       ;the characters entered on row 7, the grid
.alias EN_GRID          9       ;(8 a row, 2 columns each) on rows 9-12.

;The King's password window (poweron.asm, in MSG_BANK): its steps.
PwShowP:
        JSR SelectMsg           ;
        JMP PwShowStep          ;

;Call routine X/Y in MSG_BANK (poweron.asm) from the program, the bank in
;before put back after. (FarPtr: FarOut's, not in use meanwhile.)
MsgCall:
        STX FarPtr              ;
        STY FarPtr+1            ;
        LDA CurBank             ;
        PHA                     ;
        JSR SelectMsg           ;
        JSR MsgJump             ;
        PLA                     ;
        JMP SelectBank          ;
MsgJump:
        JMP (FarPtr)            ;

;--------------------------------------[At power-on]-------------------------------------------------

;The power-on code (poweron.asm) is in MSG_BANK: PowerOn runs its frame,
;and it calls a program routine that changes banks through FarOut (X, Y:
;the routine), which puts MSG_BANK back before it returns. A, X clobbered.
.alias FarPtr           $07AF   ;2: FarOut's routine.

PowerOn:
        JSR SelectMsg           ;
        JMP PasswordFrame       ;
FarOut:
        STX FarPtr              ;
        STY FarPtr+1            ;
        JSR +                   ;
        JMP SelectMsg           ;
*       JMP (FarPtr)            ;

;The title screen (build.py's title_bytes, in PEOPLE_BANK): its characters
;as set A, its colors, its 28 rows of codes over the view; no people, the
;hero out of sight. TitleEnd brings the map back.
TitleShow:
        LDX #<TownBattle        ;(No people; the map dark.)
        LDY #>TownBattle        ;
        JSR FarOut              ;
        LDA #$00                ;
        JSR HeroAt              ;
        LDA #PEOPLE_BANK        ;
        JSR SelectBank          ;
        LDX #$00                ;
TitleShowLoop:
*       LDA TITLE_AT,X          ;
        STA CharsetA,X          ;
        LDA TITLE_AT+$100,X     ;
        STA CharsetA+$100,X     ;
        LDA TITLE_AT+$200,X     ;
        STA CharsetA+$200,X     ;
        LDA TITLE_AT+$300,X     ;
        STA CharsetA+$300,X     ;
        LDA TITLE_AT+$400,X     ;Its text rows' set, as set B.
        STA CharsetB,X          ;
        LDA TITLE_AT+$500,X     ;
        STA CharsetB+$100,X     ;
        LDA TITLE_AT+$600,X     ;
        STA CharsetB+$200,X     ;
        LDA TITLE_AT+$700,X     ;
        STA CharsetB+$300,X     ;
        INX                     ;
        BNE TitleShowLoop       ;
        LDX #$04                ;
*       LDA TITLE_AT+$800+896,X ;
        STA MapColors,X         ;
        DEX                     ;
        BPL -                   ;
        LDX #TITLE_BANDS*5-1    ;Its bands' colors (TitleDLI's), to RAM.
TitleBandCopy:
        LDA TITLE_AT+$800+896+5,X ;
        STA TitleBands,X        ;
        DEX                     ;
        BPL TitleBandCopy       ;
        LDA #$FF                ;The hero's lines out of players 0 and 1
        STA Shown               ;(else he showed beside the dragon), and
        LDX #15                 ;drawn again when the title is gone.
        LDA #$00                ;
TitleHeroOff:
        STA Player0+HERO_LINE,X ;
        STA Player1+HERO_LINE,X ;
        DEX                     ;
        BPL TitleHeroOff        ;
        LDX #TITLE_SPR_H-1      ;Its sprites (build.py's, from the ROM's) as
TitleSprCopy:                   ;players 0 and 1, black (SetHardware), in
        LDA TITLE_SPR_AT,X      ;front of the banner.
        STA Player0+TITLE_SPR_TOP,X ;
        LDA TITLE_SPR_AT+TITLE_SPR_H,X ;
        STA Player1+TITLE_SPR_TOP,X ;
        DEX                     ;
        BPL TitleSprCopy        ;
        LDA #TITLE_SPR_X        ;
        STA HPOSP0              ;
        LDA #TITLE_SPR_X+8      ;
        STA HPOSP1              ;
        LDA #<[TITLE_AT+$800]   ;
        STA DstPtr              ;
        LDA #>[TITLE_AT+$800]   ;
        STA DstPtr+1            ;
        LDA #$00                ;
        STA WinRow              ;
TitleRow:
        LDY #$00                ;
*       STY WinCol              ;
        LDA (DstPtr),Y          ;
        JSR PutChar             ;
        INY                     ;
        CPY #32                 ;
        BNE -                   ;
        LDY #$00                ;The normal playfield's columns beside it
        LDX #$FB                ;(-5 to -1, 32 to 36): the row's 2-cell
        JSR TitleSide           ;pattern carried on, in step, from its first
        LDY #30                 ;two cells to the left and its last two to
        LDX #32                 ;the right (the background there in every
        JSR TitleSide           ;row, the logo's too).
        LDA DstPtr              ;
        CLC                     ;
        ADC #32                 ;
        STA DstPtr              ;
        BCC +                   ;
        INC DstPtr+1            ;
*       INC WinRow              ;
        LDA WinRow              ;
        CMP #28                 ;
        BNE TitleRow            ;
        JMP SelectMsg           ;
;5 cells of the title's row from column X, its cells Y and Y + 1 in turn.
TitleSide:
        STX WinCol              ;
        STY Tmp                 ;
        LDX #$05                ;
TitleSideCell:
        LDA WinCol              ;Cell Y or Y + 1, as the column is even or
        AND #$01                ;odd (the pattern's step).
        CLC                     ;
        ADC Tmp                 ;
        TAY                     ;
        LDA (DstPtr),Y          ;
        JSR PutChar             ;
        INC WinCol              ;
        DEX                     ;
        BNE TitleSideCell       ;
        RTS                     ;
TitleEnd:
        LDX #TITLE_SPR_H-1      ;Its sprites gone from the players (the
        LDA #$00                ;hero's lines are theirs again).
TitleSprClear:
        STA Player0+TITLE_SPR_TOP,X ;
        STA Player1+TITLE_SPR_TOP,X ;
        DEX                     ;
        BPL TitleSprClear       ;
        LDA #$00                ;The hero out of sight until the game
        JSR HeroAt              ;starts (his players were the dragon's,
        JSR BuildDList          ;by the menu's window). (Mode 4 rows again.)
        JSR LoadSetB            ;
        JSR TownBattleEnd       ;The map's sets and colors back, for the
        LDA #$01                ;(Quietly: no music, no fade in, the screen
        STA QuietLoad           ;left off until the menu is up.)
        LDA MapId               ;windows, but the people off, the hero still
        JSR LoadMap             ;out of sight (the screen is then made
        JMP TownBattle          ;blank: the start menu's).
;From the start menu's windows into the game: the people, the hero, the map.
GameStart:
        JSR TownBattleEnd       ;
        LDA #HERO_HPOS          ;
        JSR HeroAt              ;
        LDA MapId               ;
        JMP LoadMap             ;

;The title's interrupts, on the row before each of its bands (borders,
;banner, each line of text: each drawn in one NES palette): the band's
;set (A, or B for the mode 2 text rows) and colors, from TitleBands
;(build.py's title_bytes, from the ROM's attribute rows).
.alias TITLE_SPR_AT     TITLE_AT+$800+896+5+TITLE_BANDS*5 ;Its sprites, as players.
.alias TitleBands       $3C00   ;5 bytes a band: the row before it, set B (1) or A, COLPF0-2.
.alias TitleBand        $07F3   ;The next band's offset in them (the VBI's 0).
TitleDLI:
        PHA                     ;
        TXA                     ;
        PHA                     ;
        TYA                     ;
        PHA                     ;
        LDX TitleBand           ;
        LDY TitleBands+1,X      ;
        LDA TitleSets,Y         ;
        LDY TitleBands+4,X      ;(COLPF2 first: the text rows' background,
        STA WSYNC               ;from the line's left edge.)
        STA CHBASE              ;
        STY COLPF2              ;
        LDA TitleBands+3,X      ;
        STA COLPF1              ;
        LDA TitleBands+2,X      ;
        STA COLPF0              ;
        TXA                     ;
        CLC                     ;
        ADC #$05                ;
        STA TitleBand           ;
        PLA                     ;
        TAY                     ;
        PLA                     ;
        TAX                     ;
        PLA                     ;
        RTI                     ;
TitleSets:      .byte >CharsetA, >CharsetB
