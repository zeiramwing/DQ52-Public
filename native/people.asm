;Townspeople: every one is drawn into its town's map (convert.py's
;people_into_blocks), so here they are only a list, for TALK and for who
;comes and goes (castle.asm's CondPeople), and their stepping in place.

.alias PersonX          $0400   ;Each person's block (where it is going,
.alias PersonY          $0420   ;while it walks),
.alias PersonFace       $0440   ;facing,
.alias PersonGfx        $0460   ;graphic,
.alias PEOPLE_BANK      10      ;The people's tables (convert.py).
.alias PersonCtl        $0480   ;dialog (DialogLo/Hi's index),
.alias PersonMob        $04A0   ;bit 7: drawn in the map's background (all are).


;Copy the map's people from the tables (its record's first and count; in
;PEOPLE_BANK), the princess only once she is home.
.alias PeopleEnd        $07BC   ;
.alias PRINCESS_CTL     $6F     ;Her dialog control byte (maps.py).
LoadPeople:
        LDA #PEOPLE_BANK        ;
        JSR SelectBank          ;
        LDA PeopleFirst         ;
        CLC                     ;
        ADC PeopleCount         ;
        STA PeopleEnd           ;
        LDY PeopleFirst         ;
        LDX #$00                ;
LoadPerson:
        CPY PeopleEnd           ;
        BEQ LoadedPeople        ;
        LDA INIT_CONTROL,Y       ;The princess (the throne room's): only
        CMP #PRINCESS_CTL       ;once she is home.
        BNE +                   ;
        LDA ModFlags            ;
        AND #F_RETURNED         ;
        BNE +                   ;
        INY                     ;
        BNE LoadPerson          ;
*       LDA INIT_GRAPHIC,Y       ;
        STA PersonGfx,X         ;
        LDA INIT_X,Y             ;
        STA PersonX,X           ;
        LDA INIT_Y,Y             ;
        STA PersonY,X           ;
        LDA INIT_FACING,Y        ;
        STA PersonFace,X        ;
        LDA INIT_CONTROL,Y       ;
        STA PersonCtl,X         ;
        LDA INIT_MOBILE,Y        ;
        STA PersonMob,X         ;
        INY                     ;
        INX                     ;
        JMP LoadPerson          ;
LoadedPeople:
        STX PeopleOn            ;
        RTS                     ;

;C set, X = the person, if one is at block (BX, BY) (or walking to it).
PersonAt:
        LDX PeopleOn            ;
PersonAtNext:
        DEX                     ;
        BMI PersonAtNone        ;
        LDA PersonX,X           ;
        CMP BX                  ;
        BNE PersonAtNext        ;
        LDA PersonY,X           ;
        CMP BY                  ;
        BNE PersonAtNext        ;
        SEC                     ;
        RTS                     ;
PersonAtNone:
        CLC                     ;
        RTS                     ;

;--------------------------------------[Stepping in place]-------------------------------------------

;The townspeople drawn in the background step in place as the hero does,
;every 16 frames: the characters of theirs that differ in the other step
;(convert.py's map_image) swap their glyphs in set A with AnimGlyphs.

.alias AnimHold         $294D   ;Non-zero: not this frame (a step of the hero's began in it).
.alias AnimPhase        $294E   ;FrameCount's bit 4 as the glyphs shown are (0: as loaded),
.alias AnimCount        $294F   ;how many characters step,
.alias AnimCodes        $2950   ;32: their codes,
.alias AnimGlyphs       $2B00   ;256: their glyphs in the step not shown.

;A new map: its townspeople's other step to RAM (GFX_ANIM's).
LoadAnim:
        LDA #GFX_BANK           ;
        JSR SelectBank          ;
        LDA MapId               ;
        ASL                     ;
        TAX                     ;
        LDA GFX_ANIM,X          ;
        STA Ptr                 ;
        LDA GFX_ANIM+1,X        ;
        STA Ptr+1               ;
        LDY #$00                ;
        STY AnimPhase           ;
        LDA (Ptr),Y             ;
        STA AnimCount           ;
        BEQ AnimLoaded          ;
        INY                     ;
AnimCode:
        LDA (Ptr),Y             ;Their codes (from byte 1),
        STA AnimCodes-1,Y       ;
        CPY AnimCount           ;
        INY                     ;
        BCC AnimCode            ;
        TYA                     ;then their glyphs.
        CLC                     ;
        ADC Ptr                 ;
        STA Ptr                 ;
        BCC +                   ;
        INC Ptr+1               ;
*       LDA AnimCount           ;
        ASL                     ;
        ASL                     ;
        ASL                     ;
        TAX                     ;(32 at most: 256 bytes, X 0 for all.)
        LDY #$00                ;
AnimGlyph:
        LDA (Ptr),Y             ;
        STA AnimGlyphs,Y        ;
        INY                     ;
        DEX                     ;
        BNE AnimGlyph           ;
AnimLoaded:
        RTS                     ;

;Each frame, last (but one in which a step of the hero's began, the
;longest: then the next): when FrameCount's bit 4 changes, the stepping characters'
;glyphs swapped with AnimGlyphs (not at power-on, whose windows and title
;have set A).
AnimStep:
        LDA AnimHold            ;
        BEQ +                   ;
        LDA #$00                ;
        STA AnimHold            ;
        RTS                     ;
*       LDA FrameCount          ;
        AND #$10                ;
        CMP AnimPhase           ;
        BEQ AnimDone            ;
        LDX Mode                ;
        CPX #$06                ;
        BEQ AnimDone            ;
        STA AnimPhase           ;
        LDA AnimCount           ;
        BEQ AnimDone            ;
        LDX #$00                ;
        STX Tmp2                ;
AnimChar:
        LDY Tmp2                ;Its code * 8 in set A.
        LDA AnimCodes,Y         ;
        JSR CharPtr             ;
        LDY #$00                ;
AnimByte:
        LDA (Ptr),Y             ;
        PHA                     ;
        LDA AnimGlyphs,X        ;
        STA (Ptr),Y             ;
        PLA                     ;
        STA AnimGlyphs,X        ;
        INX                     ;
        INY                     ;
        CPY #$08                ;
        BNE AnimByte            ;
        INC Tmp2                ;
        LDA Tmp2                ;
        CMP AnimCount           ;
        BNE AnimChar            ;
AnimDone:
        RTS                     ;

;In a battle, three interrupts in turn (the VBI points VDSLST at the
;first; each the next), each quick to its wait for the line's end, for
;the next row to show its set from its first line:
;the end of row 5, the scene's upper band's set; the row before the
;monster's top, the lower band's set and colors; the row before MonSplit,
;if the monster has a second set, that set; row 17, the map's colors
;again and the text set.
BattleDLI1:
        PHA                     ;
        LDA #>UpperSet          ;
        STA WSYNC               ;
        STA CHBASE              ;
        LDA #<BattleDLI2        ;
        STA VDSLST              ;
        LDA #>BattleDLI2        ;
        STA VDSLST+1            ;
        PLA                     ;
        RTI                     ;
BattleDLI2:
        PHA                     ;Only the set before the line's end: any
        LDA #>LowerSet          ;more work here misses it (the band's first
        STA WSYNC               ;line in the old set), on this row's line.
        STA CHBASE              ;
        LDA MonShow             ;(MonColors, faded: MonsterShade.)
        STA COLPF1              ;
        LDA MonShow+1           ;
        STA COLPF2              ;
        LDA MonShow+2           ;
        STA COLPF3              ;
        LDA #WHITE              ;
        STA COLPF0              ;
        LDA #$00                ;
        STA COLBK               ;
        LDA MonSplit            ;Next: the monster's second set, if it has
        BEQ BattleNext3         ;one, else the dialog's.
        LDA #<BattleDLI2b       ;
        STA VDSLST              ;
        LDA #>BattleDLI2b       ;
        STA VDSLST+1            ;
        PLA                     ;
        RTI                     ;
BattleDLI2b:
        PHA                     ;
        LDA #>Lower2Set         ;
        STA WSYNC               ;
        STA CHBASE              ;
BattleNext3:
        LDA DialogOn            ;The rows below: the dialog's, once it is
        BNE Next3Dialog         ;up, else the map's (the battle's first
        LDA #<BattleDLI3        ;frames). Chosen here, not on the line.
        STA VDSLST              ;
        LDA #>BattleDLI3        ;
        STA VDSLST+1            ;
        PLA                     ;
        RTI                     ;
Next3Dialog:
        LDA #<Dli3Dialog        ;
        STA VDSLST              ;
        LDA #>Dli3Dialog        ;
        STA VDSLST+1            ;
        PLA                     ;
        RTI                     ;
BattleDLI3:
        PHA                     ;The map's rows, in set A and the colors
        TXA                     ;the screen shows (ShownColors: an effect's
        PHA                     ;tint, a fade, attract mode's): the set and
        LDA #>CharsetA          ;the most seen color before the line's end.
        LDX ShownColors+3       ;
        STA WSYNC               ;
        STA CHBASE              ;
        STX COLPF3              ;
        LDA ShownColors         ;
        STA COLPF0              ;
        LDA ShownColors+1       ;
        STA COLPF1              ;
        LDA ShownColors+2       ;
        STA COLPF2              ;
        JMP Dli3Out             ;
Dli3Dialog:
        PHA                     ;The dialog's mode 2 rows: its ink on black,
        TXA                     ;the black first, for its top line.
        PHA                     ;
        LDA #>CharsetB          ;
        LDX #$00                ;
        STA WSYNC               ;
        STA CHBASE              ;
        STX COLPF2              ;
        LDA DlgInk              ;
        STA COLPF1              ;
        LDA ShownColors+3       ;
        STA COLPF3              ;
        LDA ShownColors         ;
        STA COLPF0              ;
Dli3Out:
        LDA ShownColors+4       ;
        STA COLBK               ;
        PLA                     ;
        TAX                     ;
        PLA                     ;
        RTI                     ;

;Display list interrupt, at the end of the row above the dialog window
;while it is up: the text set and its colors from the window's first row.
DLI:
        PHA                     ;Only the set before the line's end (any
        LDA #>CharsetB          ;more, and the window's top line came in
        STA WSYNC               ;set A: a line across the screen).
        STA CHBASE              ;
        LDA #$00                ;(Mode 2 rows: the window's black first, in
        STA COLPF2              ;time for its top line; the text's
        LDA DlgInk              ;brightness, faded or dimmed as the rest.)
        STA COLPF1              ;
        PLA                     ;
DLINone:
        RTI                     ;
