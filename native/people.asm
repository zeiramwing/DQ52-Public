;Townspeople: each a single player (2 or 3) in one color, its graphic's.
;
;A player is a column the screen's height, so players 2 and 3 can each show
;several people, one under another: the display list interrupt at the end
;of every row sets their position and color for the next (RowHP2 and so on,
;row 0's from the VBI). A person is put in the first of the two players
;free from the start of the row its top is in: two can stand side by side,
;a third on the same rows is not drawn. People under an open window are
;not drawn either (players show in front of the playfield).
;
;Mobile people wander a block at a time, as the game's do: now and then
;one picks a direction and walks there over 16 frames, unless a wall, the
;hero or another person is in the way.

.alias PersonX          $0400   ;Each person's block (where it is going,
.alias PersonY          $0420   ;while it walks),
.alias PersonFace       $0440   ;facing,
.alias SpriteOne        $04C0   ;The one person not in the map's background ($FF: none).
.alias PersonGfx        $0460   ;graphic,
.alias PEOPLE_BANK      10      ;The people's tables (convert.py).
.alias PersonCtl        $0480   ;dialog (DialogLo/Hi's index),
.alias PersonMob        $04A0   ;whether it wanders (bit 0) or is drawn in the
                                ;map's background (bit 7),
.alias RowHP3           $0540   ;player 3's,
.alias RowC3            $0580   ;
.alias OldKey           $2900   ;Each person as last drawn (Redraw): its
.alias OldTop           $2918   ;frame + 1 and player (0: not drawn), its
.alias NewKey           $2930   ;top; and as wanted now (in the RAM past
.alias MAX_PEOPLE       24      ;the map's image).
.alias Order            $05D0   ;People shown, in order of their top line.
.alias PTop             $05E8   ;Each person's top line (16
                                ;is the first shown),
.alias RowMask          $0600   ;4: the rows the drawn people's tops are in,
.alias OldMask          $0604   ;4: and those when the interrupts were set.
.alias PHpos            $0618   ;horizontal position,
.alias PRow             $0630   ;and the display row its top is in.

.alias End3             $D3     ;to (0: free from the top).
.alias NShown           $D4     ;
.alias PI               $D5     ;Person being worked on.
.alias RowTop           $D7     ;Window test: the person's rows and columns.
.alias RowBot           $D8     ;
.alias ColL             $D9     ;
.alias ColR             $DA     ;
.alias GfxPtr           $DB     ;2.
.alias LineLo           $DD     ;A line being drawn, 16 bits.
.alias LineHi           $DE     ;
.alias RowStart         $DF     ;
.alias Snap             $E0     ;8: what the people were last drawn with:
.alias SnapNow          $E8     ;the view, the step of their walk, the
.alias SNAP_SIZE        8       ;windows; and what shows now.
.alias PeopleDirty      $F0     ;Non-zero: a person moved or turned.

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
        LDX #$FF                ;
        STX SpriteOne           ;
        INX                     ;
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
        BMI +                   ;(Bit 7: in the map's background. The one
        STX SpriteOne           ;who is not, if any: the one drawn.)
*       INY                     ;
        INX                     ;
        JMP LoadPerson          ;
LoadedPeople:
        STX PeopleOn            ;
        LDA #$01                ;
        STA PeopleDirty         ;
        JSR ClearPlayers        ;Players 2 and 3 cleared, nothing drawn.
        LDA #$00                ;
        LDX #DL_ROWS            ;
*       STA RowHP3,X            ;
        DEX                     ;
        BPL -                   ;
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

;--------------------------------------[Drawing]-----------------------------------------------------

;Draw the people for this frame, if anything that shows changed: where each
;is on screen, then each, top first, into a free player, with its row's
;position and color (only at its first row: the DLI leaves a player as it
;is at rows whose position is 0).
DrawPeople:
        LDA PeopleOn            ;
        BEQ DrawNone            ;
        LDA SpriteOne           ;(All in the background: nothing to draw.)
        BPL +                   ;
DrawNone:
        RTS                     ;
*       JSR PeopleChanged       ;
        BCS +                   ;
        RTS                     ;
*       `prof_begin 6
        LDA #$00                ;Nothing wanted yet (NewKey), no row in use.
        LDX SpriteOne           ;
        STA NewKey,X            ;
        STA End3                ;
        LDX #DL_ROWS            ;No changes at any row yet.
*       STA RowHP3,X            ;
        DEX                     ;
        BPL -                   ;
        STA RowMask             ;
        STA RowMask+1           ;
        STA RowMask+2           ;
        STA RowMask+3           ;

        `prof_end 6
        `prof_begin 7
        JSR PlacePeople         ;Where each is, and their order.
        `prof_end 7
        LDA #$00                ;
        STA PI                  ;
DrawNext:
        LDA PI                  ;
        CMP NShown              ;
        BNE DrawOne             ;
        JSR Redraw              ;Only who changed: wiped and drawn.
        LDX #$03                ;Interrupts at the rows that need them, if
*       LDA RowMask,X           ;those have changed.
        CMP OldMask,X           ;
        BNE DrawRows            ;
        DEX                     ;
        BPL -                   ;
        RTS                     ;
DrawRows:
        LDX #$03                ;
*       LDA RowMask,X           ;
        STA OldMask,X           ;
        DEX                     ;
        BPL -                   ;
        JMP DLIBitRows          ;
DrawOne:
        TAY                     ;
        LDX Order,Y             ;
        LDA #FIRST_LINE         ;The first line of its top's row: 16 for
        LDY PRow,X              ;row 0, else 16 + row * 8 - VSCROL.
        BEQ +                   ;
        TYA                     ;
        ASL                     ;
        ASL                     ;
        ASL                     ;
        CLC                     ;
        ADC #FIRST_LINE-1       ;Less one: the player must be free on the
        SEC                     ;row before's last line, where the DLI
        SBC ShV                 ;moves it.
*       STA RowStart            ;
        LDA End3                ;Player 3 free by then? (Player 2 is the
        CMP RowStart            ;hero's now: a map has one person at most
        BCC InPlayer3           ;not drawn in its background.)
        JMP DrawSkip            ;No: not drawn.
InPlayer3:
        LDA PTop,X              ;
        CLC                     ;
        ADC #15                 ;
        STA End3                ;
        LDY PersonGfx,X         ;
        LDA PersonColors,Y      ;
        LDY PRow,X              ;
        STA RowC3,Y             ;
        LDA PHpos,X             ;
        STA RowHP3,Y            ;
        JSR MarkRow             ;
        JSR FrameOf             ;In player 3: bit 7 set.
        CLC                     ;
        ADC #$81                ;
        STA NewKey,X            ;
DrawSkip:
        INC PI                  ;
        JMP DrawNext            ;

;Row Y into RowMask (X kept).
MarkRow:
        STX Tmp                 ;
        LDX RowMaskByte,Y       ;
        LDA RowMaskBit,Y        ;
        ORA RowMask,X           ;
        STA RowMask,X           ;
        LDX Tmp                 ;
        RTS                     ;
RowMaskByte:    .byte 0,0,0,0,0,0,0,0, 1,1,1,1,1,1,1,1, 2,2,2,2,2,2,2,2, 3,3,3,3,3,3,3,3
RowMaskBit:     .byte 1,2,4,8,16,32,64,128, 1,2,4,8,16,32,64,128, 1,2,4,8,16,32,64,128, 1,2,4,8,16,32,64,128

;C set if what the people look like may have changed since they were last
;drawn: the view, the step of their walk, a window, or a person moving or
;turning (PeopleDirty).
PeopleChanged:
        LDA LeftBlock           ;What shows now.
        STA SnapNow             ;
        LDA TopBlock            ;
        STA SnapNow+1           ;
        LDA FineX               ;
        STA SnapNow+2           ;
        LDA FineY               ;
        STA SnapNow+3           ;
        LDA FrameCount          ;
        AND #$10                ;
        STA SnapNow+4           ;
        LDA StatusOn            ;
        STA SnapNow+5           ;
        LDA Mode                ;
        STA SnapNow+6           ;
        LDA DialogOn            ;
        ORA YesNoOn             ;
        STA SnapNow+7           ;
        LDA PeopleDirty         ;
        LDX #$00                ;
        STX PeopleDirty         ;
        TAY                     ;
        LDX #SNAP_SIZE-1        ;
*       LDA SnapNow,X           ;
        CMP Snap,X              ;
        BEQ +                   ;
        INY                     ;
*       STA Snap,X              ;
        DEX                     ;
        BPL --                  ;
        CPY #$01                ;C set if anything differed.
        RTS                     ;

;Person X's frame (graphic * 8 + facing * 2 + step, 16 bytes each). X
;kept.
FrameOf:
        LDA PersonGfx,X         ;
        ASL                     ;
        ASL                     ;
        ADC PersonFace,X        ;
        ASL                     ;
        STA Tmp                 ;
        LDA FrameCount          ;
        AND #$10                ;
        BEQ +                   ;
        INC Tmp                 ;
*       LDA Tmp                 ;
        RTS                     ;

;Once the people are placed (NewKey: each one's frame + 1 and player, 0
;not drawn), only who changed since they were drawn (OldKey, OldTop) is
;touched, and never by wiping first then drawing (between the two, the
;screen could show them missing): one that is gone, or in the other
;player, or moved more than a line, is wiped (all of that before any
;drawing: its old place may be another's now); then each that changed is
;drawn over where it was; then one that moved a line has the line it left
;cleared (people in a player have a line between them at least, as
;DrawPeople gives each its player, so that line is no one else's).
Redraw:
        LDX SpriteOne           ;(The one person drawn.) Gone, or moved
        JSR Moved               ;more than a line: wiped.
        BCC RedrawDraw          ;
        LDA OldKey,X            ;
        JSR PlayerOf            ;
        LDA OldTop,X            ;
        JSR ClearPerson         ;
RedrawDraw:
        LDA NewKey,X            ;
        BEQ RedrawKeep          ;
        CMP OldKey,X            ;
        BNE RedrawIt            ;
        LDA OldTop,X            ;
        CMP PTop,X              ;
        BEQ RedrawKeep          ;
RedrawIt:
        LDA NewKey,X            ;Drawn over itself,
        JSR PlayerOf            ;
        STX PI                  ;
        JSR DrawPerson          ;
        LDX PI                  ;
        LDA OldKey,X            ;and a line's move (in the same player):
        BEQ RedrawKeep          ;the line it left.
        EOR NewKey,X            ;
        BMI RedrawKeep          ;
        LDA PTop,X              ;
        SEC                     ;
        SBC OldTop,X            ;
        LDY OldTop,X            ;
        CMP #$01                ;(Down a line: its old top.)
        BEQ RedrawLine          ;
        CMP #$FF                ;(Up a line: its old bottom.)
        BNE RedrawKeep          ;
        TYA                     ;
        CLC                     ;
        ADC #15                 ;
        TAY                     ;
RedrawLine:
        LDA #$00                ;
        STA Ptr                 ;
        STA (Ptr),Y             ;
RedrawKeep:
        LDA NewKey,X            ;
        STA OldKey,X            ;
        LDA PTop,X              ;
        STA OldTop,X            ;
        RTS                     ;
;C set if person X was drawn and is now gone, in the other player, or
;more than a line from where it was. X kept.
Moved:
        LDA OldKey,X            ;
        BEQ MovedNo             ;
        LDA NewKey,X            ;
        BEQ MovedYes            ;
        EOR OldKey,X            ;
        BMI MovedYes            ;
        LDA PTop,X              ;
        SEC                     ;
        SBC OldTop,X            ;
        CLC                     ;
        ADC #$01                ;(-1, 0 or 1: 0 to 2.)
        CMP #$03                ;
        RTS                     ;
MovedYes:
        SEC                     ;
        RTS                     ;
MovedNo:
        CLC                     ;
        RTS                     ;
;Ptr+1 = the player of key A (bit 7: player 3). X kept.
PlayerOf:
        ASL                     ;
        LDA #>Player2           ;
        BCC +                   ;
        LDA #>Player3           ;
*       STA Ptr+1               ;
        RTS                     ;

;Clear player 3 (the people's), and what Redraw knows was drawn in it.
ClearPlayers:
        LDA #$00                ;
        TAX                     ;
*       STA Player3,X           ;
        INX                     ;
        BNE -                   ;
        LDX #MAX_PEOPLE-1       ;
*       STA OldKey,X            ;
        DEX                     ;
        BPL -                   ;
        RTS                     ;

;Draw person X (its key in NewKey) into the player at Ptr+1: its frame's
;16 lines from its top, those from line 16 to 239.
DrawPerson:
        LDA NewKey,X            ;Its frame, from its key.
        AND #$7F                ;
        SEC                     ;
        SBC #$01                ;
        STA Tmp                 ;
        LDA #$00                ;
        STA GfxPtr+1            ;
        LDA Tmp                 ;
        ASL                     ;
        ROL GfxPtr+1            ;
        ASL                     ;
        ROL GfxPtr+1            ;
        ASL                     ;
        ROL GfxPtr+1            ;
        ASL                     ;
        ROL GfxPtr+1            ;
        CLC                     ;
        ADC #<PeopleGfx         ;
        STA GfxPtr              ;
        LDA GfxPtr+1            ;
        ADC #>PeopleGfx         ;
        STA GfxPtr+1            ;
        LDA PTop,X              ;
        JSR LineRange           ;
        BCC DrawPartly          ;
        LDA (GfxPtr),Y          ;
        STA (Ptr),Y             ;
        INY                     ;
        LDA (GfxPtr),Y          ;
        STA (Ptr),Y             ;
        INY                     ;
        LDA (GfxPtr),Y          ;
        STA (Ptr),Y             ;
        INY                     ;
        LDA (GfxPtr),Y          ;
        STA (Ptr),Y             ;
        INY                     ;
        LDA (GfxPtr),Y          ;
        STA (Ptr),Y             ;
        INY                     ;
        LDA (GfxPtr),Y          ;
        STA (Ptr),Y             ;
        INY                     ;
        LDA (GfxPtr),Y          ;
        STA (Ptr),Y             ;
        INY                     ;
        LDA (GfxPtr),Y          ;
        STA (Ptr),Y             ;
        INY                     ;
        LDA (GfxPtr),Y          ;
        STA (Ptr),Y             ;
        INY                     ;
        LDA (GfxPtr),Y          ;
        STA (Ptr),Y             ;
        INY                     ;
        LDA (GfxPtr),Y          ;
        STA (Ptr),Y             ;
        INY                     ;
        LDA (GfxPtr),Y          ;
        STA (Ptr),Y             ;
        INY                     ;
        LDA (GfxPtr),Y          ;
        STA (Ptr),Y             ;
        INY                     ;
        LDA (GfxPtr),Y          ;
        STA (Ptr),Y             ;
        INY                     ;
        LDA (GfxPtr),Y          ;
        STA (Ptr),Y             ;
        INY                     ;
        LDA (GfxPtr),Y          ;
        STA (Ptr),Y             ;
        LDA Ptr                 ;All 16 lines shown: unrolled.
        RTS                     ;
DrawPartly:
*       LDA (GfxPtr),Y          ;
        STA (Ptr),Y             ;
        INY                     ;
        CPY LineHi              ;
        BNE -                   ;
        LDA Ptr                 ;
        RTS                     ;

;Clear the 16 lines from top A (as DrawPerson drew them) in the player at
;Ptr+1.
ClearPerson:
        JSR LineRange           ;(Only for a person gone, in the other
        LDA #$00                ;player or moved far: a loop is enough.)
*       STA (Ptr),Y             ;
        INY                     ;
        CPY LineHi              ;
        BNE -                   ;
        RTS                     ;

;For 16 lines from top A (1-239): Ptr = the player's page + A, and Y to
;LineHi the lines from there that are shown (16-239); C set if all 16
;are (Y 0). X is kept.
LineRange:
        STA Ptr                 ;
        LDY #$00                ;
        CMP #FIRST_LINE         ;
        BCC LineTop             ;
        CMP #FIRST_LINE+224-15  ;All of it shown: C set (Y 0, to 16).
        BCS LineBottom          ;
        LDA #16                 ;
        STA LineHi              ;
        SEC                     ;
        RTS                     ;
LineTop:
        LDA #FIRST_LINE         ;Above line 16: from 16 - top.
        SEC                     ;
        SBC Ptr                 ;
        TAY                     ;
        LDA #16                 ;
        STA LineHi              ;
        CLC                     ;
        RTS                     ;
LineBottom:
        LDA #FIRST_LINE+224     ;Below line 239: to 240 - top.
        SEC                     ;
        SBC Ptr                 ;
        STA LineHi              ;
        CLC                     ;
        RTS                     ;

;Where each person is on screen (its top line, horizontal position and
;top's row), which are shown (on screen, not under a window), and their
;order, top first.
PlacePeople:
        LDA #$00                ;
        STA NShown              ;
        LDX SpriteOne           ;The one not drawn in the map's background
        BPL PlaceOne            ;(convert.py's people_into_blocks), if any.
PlaceNext:
        RTS                     ;
PlaceOne:
        LDA PersonX,X           ;Blocks from the view's left, + 1: 0-17.
        SEC                     ;
        SBC LeftBlock           ;
        CLC                     ;
        ADC #$01                ;
        CMP #18                 ;
        BCS PlaceNext           ;
        ASL                     ;Position = 64 + (that - 1) * 8 - FineX
        ASL                     ;= 56 + that * 8 - FineX.
        ASL                     ;
        CLC                     ;
        ADC #56                 ;
        SEC                     ;
        SBC FineX               ;
        STA PHpos,X             ;
        CMP #64                 ;Only a whole figure in the playfield
        BCC PlaceNext           ;(64-191): the 5200 shows players in the
        CMP #185                ;border too, where the NES's view ends, so
        BCS PlaceNext           ;one off the view's edge showed there.
        LDA PersonY,X           ;Blocks from the view's top, + 1: 0-15.
        SEC                     ;
        SBC TopBlock            ;
        CLC                     ;
        ADC #$01                ;
        CMP #16                 ;
        BCS PlaceNext           ;
        ASL                     ;Top = 16 + (that - 1) * 16 - FineY = that
        ASL                     ;* 16 - FineY; a borrow: above the screen.
        ASL                     ;
        ASL                     ;
        SEC                     ;
        SBC FineY               ;
        BCC PlaceNext           ;
        STA PTop,X              ;
        BEQ PlaceNext           ;
        CMP #FIRST_LINE+224     ;
        BCS PlaceNext           ;
        SEC                     ;Its top's row: 0 above line 16, else
        SBC #FIRST_LINE         ;(top - 16 + VSCROL) / 8.
        BCS +                   ;
        LDA #$00                ;
        BEQ ++                  ;
*       CLC                     ;
        ADC ShV                 ;
        LSR                     ;
        LSR                     ;
        LSR                     ;
*       STA PRow,X              ;
        JSR UnderWindow         ;
        BCS PlaceNext           ;
        LDY NShown              ;Into the order, by top line: Y is where
InsertAt:                       ;it goes if the one before is above it.
        CPY #$00                ;
        BEQ Inserted            ;
        STX Tmp                 ;
        LDA Order-1,Y           ;
        TAX                     ;
        LDA PTop,X              ;
        LDX Tmp                 ;
        CMP PTop,X              ;
        BCC Inserted            ;At or above ours: we go after it.
        BEQ Inserted            ;
        LDA Order-1,Y           ;
        STA Order,Y             ;
        DEY                     ;
        JMP InsertAt            ;
Inserted:
        TXA                     ;
        STA Order,Y             ;
        INC NShown              ;
        JMP PlaceNext           ;

;C set if person X is under an open window. Its rows: (top - 16) / 8 to
;(top - 1) / 8; its columns: (position - 64) / 4 to (position - 57) / 4
;(clamped at the left edge).
UnderWindow:
        LDA StatusOn            ;No window open (as while walking): no.
        ORA DialogOn            ;
        ORA YesNoOn             ;
        ORA ListOn              ;
        BNE +                   ;
        LDA Mode                ;
        CMP #$01                ;
        BEQ +                   ;
        CMP #$05                ;
        BEQ +                   ;
        CLC                     ;
        RTS                     ;
*       LDA PTop,X              ;
        SEC                     ;
        SBC #FIRST_LINE         ;
        BCS +                   ;
        LDA #$00                ;
*       LSR                     ;
        LSR                     ;
        LSR                     ;
        STA RowTop              ;
        LDA PTop,X              ;
        SEC                     ;
        SBC #$01                ;
        LSR                     ;
        LSR                     ;
        LSR                     ;
        STA RowBot              ;
        LDA PHpos,X             ;
        SEC                     ;
        SBC #64                 ;
        BCS +                   ;
        LDA #$00                ;
*       LSR                     ;
        LSR                     ;
        STA ColL                ;
        LDA PHpos,X             ;
        SEC                     ;
        SBC #57                 ;
        BCS +                   ;
        LDA #$00                ;
*       LSR                     ;
        LSR                     ;
        STA ColR                ;
        LDA StatusOn            ;
        BEQ +                   ;
        LDY #$00                ;
        JSR InWindow            ;
        BCS UnderYes            ;
*       LDA Mode                ;
        CMP #$01                ;
        BNE +                   ;
        LDY #$01                ;
        JSR InWindow            ;
        BCS UnderYes            ;
*       LDA DialogOn            ;
        BEQ +                   ;
        LDY #$02                ;
        JSR InWindow            ;
        BCS UnderYes            ;
*       LDA ListOn              ;
        BEQ +                   ;
        LDY #$04                ;
        JSR InWindow            ;
        BCS UnderYes            ;
*       LDA YesNoOn             ;
        BEQ +                   ;
        LDY #$03                ;
        JSR InWindow            ;
        BCS UnderYes            ;
*       LDA Mode                ;
        CMP #$05                ;
        BNE +                   ;
        LDY #$05                ;
        JSR InWindow            ;
        BCS UnderYes            ;
*       CLC                     ;
UnderYes:
        RTS                     ;

;C set if the person's rows and columns meet window Y's.
InWindow:
        LDA RowBot              ;
        CMP WinTop,Y            ;
        BCC InWindowNo          ;
        LDA WinBottom,Y         ;
        CMP RowTop              ;
        BCC InWindowNo          ;
        LDA ColR                ;
        CMP WinLeft,Y           ;
        BCC InWindowNo          ;
        LDA WinRight,Y          ;
        CMP ColL                ;
        BCC InWindowNo          ;
        SEC                     ;
        RTS                     ;
InWindowNo:
        CLC                     ;
        RTS                     ;

;The windows' first and last rows and columns: status, command, dialog,
;YES/NO, the list window (at its largest), STATUS's.
WinTop:         .byte 4, 2, 18, 12, 2, STATUS_TOP
WinBottom:      .byte 15, 11, 28, 16, 13, STATUS_TOP+STATUS_HEIGHT-1
WinLeft:        .byte 2, 12, 0, 21, 10, STATUS_LEFT
WinRight:       .byte 9, 27, 31, 26, 31, STATUS_LEFT+STATUS_WIDTH-1

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
        PHA                     ;
        LDA #>LowerSet          ;
        STA WSYNC               ;
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
        LDA #<BattleDLI3        ;
        STA VDSLST              ;
        LDA #>BattleDLI3        ;
        STA VDSLST+1            ;
        PLA                     ;
        RTI                     ;
BattleDLI3:
        PHA                     ;
        LDA #>CharsetB          ;
        STA WSYNC               ;
        STA CHBASE              ;
        LDA #$00                ;(The dialog's mode 2 rows: white on black,
        STA COLPF2              ;the black first, for its top line.)
        LDA #DLG_INK            ;
        STA COLPF1              ;
        LDA MapColors           ;
        STA COLPF0              ;
        LDA MapColors+3         ;
        STA COLPF3              ;
        LDA MapColors+4         ;
        STA COLBK               ;
        PLA                     ;
        RTI                     ;

;Display list interrupt, at the end of each row: players 2 and 3 for the
;next (where they change: a position of 0 leaves one as it is), and from
;the dialog window's first row, while it is up, the text set.
DLI:
        PHA                     ;
        LDA DialogOn            ;First, before the line ends, the dialog
        BEQ DLIPeople           ;window's set from its first row: on the last
        LDA VCOUNT              ;line above it (DlgVCount, from the VBI: or
        SEC                     ;one more), set B at once. (Worked out after
        SBC DlgVCount           ;the row, as the people's are, it came a line
        CMP #$02                ;late: the window's top line was set A's.)
        BCS DLIPeople           ;
        LDA #>CharsetB          ;
        STA WSYNC               ;
        STA CHBASE              ;
        LDA #$00                ;(Mode 2 rows: the window's black first, in
        STA COLPF2              ;time for its top line; the text's
        LDA #DLG_INK            ;brightness.)
        STA COLPF1              ;
DLIPeople:
        TXA                     ;
        PHA                     ;
        LDA VCOUNT              ;The row this interrupt changes: it comes on
        ASL                     ;the last line L of the row before, VCOUNT
        CLC                     ;= L / 2; the next row is (L + 1 - 16 +
        ADC VScrolNow           ;VSCROL) / 8, and (VCOUNT * 2 + 2 - 16 +
        SEC                     ;VSCROL) / 8 is it too.
        SBC #FIRST_LINE-2       ;(Interrupts are not on every row.)
        LSR                     ;
        LSR                     ;
        LSR                     ;
        TAX                     ;
DLIRows:
        LDA RowHP3,X            ;No wait for the line's end: a person is
        BEQ +                   ;put in the player only from the line after
                                ;its last one (DrawPeople), so the line
                                ;this runs on shows nothing of it.
        STA HPOSP3              ;
        LDA RowC3,X             ;
        STA COLPM3              ;
*
DLIDone:
        PLA                     ;
        TAX                     ;
        PLA                     ;
        RTI                     ;
