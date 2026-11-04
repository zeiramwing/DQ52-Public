;Passwords: the 5200 keeps nothing at power-off (the NES kept its logs in
;battery-backed RAM), so the King shows a password when he records the
;hero's deeds, and holding the upper fire button at power-on asks for one.
;
;A password holds the experience and gold, the items, keys and herbs, the
;equipment, the flags (ModFlags) and the curses (Flags2): 11 bytes, then a check byte (CRC-8,
;polynomial $07, from $5A), the 11 scrambled by a sequence started from
;the check (each next = the last * 5 + $3B) so that like adventures do
;not look alike. Its 96 bits, then 4 more of 0, are 20 characters of 5
;bits: A-Z, then 2-7. The level and its stats come back from the
;experience, HP and MP full, as the game's own logs bring them back. (The
;name is not kept: the name window asks for it after a password.)

.alias PwBuf            $0780   ;13: the bytes (the last a pad of 0),
.alias PwChars          $0790   ;20: the characters (0-31),
.alias PwLen            $07A4   ;how many are entered,
.alias PwCur            $07A5   ;the entry grid's cursor (0-31),
.alias PwKey            $07A6   ;the scrambling sequence (and a frame's column),
.alias PwT1             $07A7   ;temporaries.
.alias PwT2             $07A8   ;
.alias PwW              $07A9   ;A frame's width inside.
.alias PW_LEN           20      ;
.alias PW_SHOW          $F7     ;The King's step (maps.py), after the deeds are
.alias PW_WAIT          47      ;recorded; a button then closes it.
.alias PW_ROW           1       ;Where the King shows it: rows 1-3,
.alias PW_COL           5       ;columns 5-26.
.alias EN_ROW           6       ;The entry window: rows 6-13, columns 4-27:
.alias EN_COL           4       ;the characters entered on row 7, the grid
.alias EN_GRID          9       ;(8 a row, 2 columns each) on rows 9-12.

;The King's password window (poweron.asm, in MSG_BANK): its steps.
PwShowP:
        LDA #MSG_BANK           ;
        JSR SelectBank          ;
        JMP PwShowStep          ;

;--------------------------------------[At power-on]-------------------------------------------------

;The power-on code (poweron.asm) is in MSG_BANK: PowerOn runs its frame,
;and it calls a program routine that changes banks through FarOut (X, Y:
;the routine), which puts MSG_BANK back before it returns. A, X clobbered.
.alias FarPtr           $07AF   ;2: FarOut's routine.

PowerOn:
        LDA #MSG_BANK           ;
        JSR SelectBank          ;
        JMP PasswordFrame       ;
FarOut:
        STX FarPtr              ;
        STY FarPtr+1            ;
        JSR +                   ;
        LDA #MSG_BANK           ;
        JMP SelectBank          ;
*       JMP (FarPtr)            ;

;The title screen (build.py's title_bytes, in PEOPLE_BANK): its characters
;as set A, its colors, its 28 rows of codes over the view; no people, the
;hero out of sight. TitleEnd brings the map back.
TitleShow:
        LDX #<TownBattle        ;(No people; the map dark.)
        LDY #>TownBattle        ;
        JSR FarOut              ;
        LDA #$00                ;
        STA HPOSP0              ;
        STA HPOSP1              ;
        LDA #PEOPLE_BANK        ;
        JSR SelectBank          ;
        LDX #$00                ;
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
        BNE -                   ;
        LDX #$04                ;
*       LDA TITLE_AT+$800+896,X ;
        STA MapColors,X         ;
        DEX                     ;
        BPL -                   ;
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
        LDA #MSG_BANK           ;
        JMP SelectBank          ;
TitleEnd:
        JSR BuildDList          ;(Mode 4 rows again.)
        JSR TownBattleEnd       ;The map's sets and colors back, for the
        LDA MapId               ;windows, but the people off, the hero still
        JSR LoadMap             ;out of sight (the screen is then made
        JMP TownBattle          ;blank: the start menu's).
;From the start menu's windows into the game: the people, the hero, the map.
GameStart:
        JSR TownBattleEnd       ;
        LDA #HERO_HPOS          ;
        STA HPOSP0              ;
        STA HPOSP1              ;
        LDA MapId               ;
        JMP LoadMap             ;

;The title's interrupt, above its text rows (mode 2): set B, its colors.
TitleDLI:
        PHA                     ;
        LDA #>CharsetB          ;
        STA WSYNC               ;
        STA CHBASE              ;
        LDA #TITLE_LUM          ;
        STA COLPF1              ;
        LDA #$00                ;
        STA COLPF2              ;
        PLA                     ;
        RTI                     ;
