;Battles: random fights on the overworld, as the game has them.
;
;After each step on the overworld a fight may start: when the random
;number, masked by the ground (sand and hills $07, forest, brick and swamp
;$0F, elsewhere $1F or $0F as the hero's X and Y are both even or odd or
;not), is 0. The enemy is one of the 5 of the hero's zone (EnZones,
;EnGroups); in zone 0, by Tantegel, half the fights (three in four on
;hills) are called off.
;
;The battle scene (the game's, CombatBckgndGFX) is a window at columns
;10-23, rows 6-17, the map still around it, in two bands of rows, each with
;its own character set, switched by display list interrupts: the upper one
;(row 6 to the monster's top, UpperSet) in the map's colors, the lower one
;(the monster's rows to 17, LowerSet) in colors chosen for the monster
;(COLBK black, COLPF0 white for the text, COLPF1-3 its own). Each set holds
;its picture's glyphs from code 1, the window text from code 64 as set A
;has it (made all COLPF0 in the lower one), and the map's characters beside
;the window copied into the codes left (in the lower set with their pixels
;turned to its colors), so the map shows on as it was. The hero is hidden.
;The fight is a chain of messages in the dialog window, each step (BState)
;taken once a message is out, with the game's sums for who goes first,
;hitting, damage, running and leveling up.

.alias UpperSet         $2C00   ;The bands' character sets (RAM): the scene's,
.alias LowerSet         $3000   ;the monster's,
.alias Lower2Set        $3400   ;and its rows from MonSplit, if they need one.
.alias RemapTbl         $2A00   ;Each map character's code in the band ($FF: none yet).
.alias WithGrid         $3900   ;The lower band's codes, 14 a row: with the monster,
.alias WithoutGrid      $3800   ;and once it is gone.
.alias SceneGrid        $3A00   ;The upper band's codes, 14 by 12.
.alias SCENE_SHOWN      12      ;
.alias MONSTER_BASE     $8000   ;The monster pictures, in MonsterBank's banks.
.alias MONSTER_BANK     4       ;
.alias SCENE_COL        10      ;The scene window: columns 10-23,
.alias SCENE_ROW        6       ;rows 6-17.
.alias SCENE_END        18      ;
.alias WHITE            $0E     ;COLPF0 in the lower band.

.alias EnemyName        $0260   ;16: the enemy's name, in text tiles.
.alias BattleList       $0277   ;4: the message being shown, then $FFFF.
.alias MonHead          $02A0   ;The monster's record's first 15 bytes:
.alias MonTop           $02A0   ;the lower band's first row,
.alias MonColors        $02A1   ;3: its COLPF1-3,
.alias MonVals          $02A4   ;8: a map pixel's value in it (without bit 7, with),
.alias MonInv           $02AC   ;2: a map character's bit 7 in it (without, with),
.alias MonGlyphs        $02AE   ;its glyph count.
.alias LowerDLI         $02AF   ;The row before MonTop (its interrupt's).
.alias GridSize         $02B0   ;14 * the lower band's rows.
.alias NextFree         $02B1   ;The next code for a map character (0: none).
.alias InLower          $02B2   ;Non-zero: composing the lower band.
.alias MonGone          $02B3   ;Non-zero: the monster is gone.
.alias CmdBuf           $02B4   ;8: rows 6-7, columns 24-27 (under the command window).
.alias MonSplit         $02BC   ;The row its second set starts at (0: none),
.alias MonGlyphs2       $02BD   ;that set's glyph count,
.alias SplitDLI         $02BE   ;and the row before (its interrupt's).
.alias MapSrc           $02BF   ;MapByte's.
.alias MonFade          $07C8   ;The monster's colors less this luminance (16 on: black),
.alias MonFadeTo        $07C9   ;and where the VBI takes it, a step a frame;
.alias MonShow          $07CA   ;3: its COLPF1-3 as shown (BattleDLI2's).
.alias WipeLeft         $07CD   ;Rows left of the monster's coming or going,
.alias WipeShow         $07CE   ;and which: 0 coming (the grid with it), 1 going.
.alias SrcPtr           $DB     ;2: glyph copying (GfxPtr: no people on the overworld).

.alias BState           $F3     ;What to do once the message is out.
.alias Enemy            $F4     ;
.alias EnemyHP          $F5     ;
.alias Damage           $F6     ;
.alias Excellent        $F7     ;Non-zero: an excellent move.
.alias ProdLo           $F8     ;Mul8's product,
.alias ProdHi           $F9     ;
.alias MulB             $FA     ;and multiplier.
.alias EnemyNameLen     $FB     ;
.alias Prev             $FC     ;4: the hero's stats before a level up.
.alias DstPtr           $FC     ;2: glyph copying (Prev's, before any level up).
.alias BattleOn         $0280   ;Non-zero: in a battle.
.alias EnemyRec         $0648   ;16: the enemy's record (LoadEnemy, from ENEMY_RECS):
.alias EnemyAtt         $0648   ;attack,
.alias EnemyDef         $0649   ;defense,
.alias EnemyMaxHP       $064A   ;HP (what it starts with),
.alias EnemySpells      $064B   ;spells,
.alias EnemyAgi         $064C   ;agility,
.alias EnemyMDef        $064D   ;magic defense,
.alias EnemyExp         $064E   ;experience,
.alias EnemyGold        $064F   ;gold,
.alias EnemyRepel       $0650   ;repel value,
.alias EnemyPicLo       $0651   ;its picture's record and bank,
.alias EnemyPicHi       $0652   ;
.alias EnemyPicBank     $0653   ;
.alias EnemyDarkLo      $0654   ;and on black's.
.alias EnemyDarkHi      $0655   ;
.alias EnemyDarkBank    $0656   ;
.alias THRONE_MAP       3       ;Where a dead hero is brought back: before
.alias THRONE_X         3       ;the King.
.alias THRONE_Y         4       ;

;BState values.
.alias B_INTRO          0       ;The enemy's arrival message is out: who goes first.
.alias B_PROMPT         1       ;The command prompt is out: the command window.
.alias B_CMD            2       ;The command window is up.
.alias B_ATTACK         3       ;The hero's attack message is out.
.alias B_DAMAGE         4       ;The damage to the enemy.
.alias B_ENEMY          5       ;The enemy's turn.
.alias B_ENEMYHIT       6       ;The enemy's attack message is out.
.alias B_ROUND          7       ;A new round: the command prompt.
.alias B_WIN            8       ;The enemy is defeated.
.alias B_EXP            9       ;
.alias B_GOLD           10      ;
.alias B_LEVEL          11      ;
.alias B_STR            12      ;
.alias B_AGI            13      ;
.alias B_HP             14      ;
.alias B_MP             15      ;
.alias B_CLOSE          16      ;All said: a button ends the battle.
.alias B_RUN            17      ;The run message is out.
.alias B_GONE           18      ;The enemy ran away, or the hero did.
.alias B_DEAD           19      ;
.alias B_DEAD2          20      ;The death message is out: a button.
.alias B_HSPELL         21      ;The hero's chant is out (spell.asm on).
.alias B_ENACT          22      ;The enemy woke: its move.
.alias B_ENASLEEP       23      ;The enemy is asleep.
.alias B_ENCHANT        24      ;The enemy's chant,
.alias B_ENSPELL        25      ;its spell's name is out.
.alias B_HASLEEP        26      ;The hero fell asleep.
.alias B_FIRE           27      ;The fire's message is out.
.alias B_COMMAND        28      ;The command prompt (the hero awake).
.alias B_NEWSPELL       29      ;After a level's growth: a spell learned.
.alias B_LORD2          30      ;His first form beaten: a pause, his second.
.alias B_LORDEND        31      ;His end said: a button.
.alias B_TUNE           32      ;The flute's or the harp's message is out.

;--------------------------------------[Starting a fight]--------------------------------------------

;After a step: on the overworld, maybe a fight.
CheckEncounter:
        LDX MapId               ;
        BEQ +                   ;
        LDA MapEnemies          ;A cave: its own row of enemies, 1 in 16
        CMP #$FF                ;(as on brick).
        BNE CaveEncounter       ;
        RTS                     ;
*       LDA #FIGHT_ENEMY        ;(Test builds: always this enemy, or never,
        CMP #$FE                ;$FE.)
        BNE +                   ;
        RTS                     ;
*       CMP #$FF                ;
        BEQ +                   ;
        JMP StartBattle         ;
*       LDA HeroX               ;The ground under the hero.
        STA BX                  ;
        LDA HeroY               ;
        STA BY                  ;
        JSR GetBlock            ;
        STA Tmp3                ;
        LDX #$07                ;Sand and hills: 1 in 8.
        CMP #$01                ;
        BEQ ++                  ;
        CMP #$02                ;
        BEQ ++                  ;
        LDX #$0F                ;Forest, brick, swamp: 1 in 16.
        CMP #$0B                ;
        BEQ ++                  ;
        CMP #$04                ;
        BEQ ++                  ;
        CMP #$06                ;
        BEQ ++                  ;
        LDA HeroX               ;Elsewhere: 1 in 32 where X and Y are both
        EOR HeroY               ;even or both odd, else 1 in 16.
        LSR                     ;
        BCS ++                  ;
        LDX #$1F                ;
*       NOP                     ;
*       STX Tmp                 ;
        JSR NextRandom          ;
        LDA Random+1            ;
        AND Tmp                 ;
        BEQ +                   ;
        RTS                     ;
*       LDA #MSG_BANK           ;(The zones and groups are in MSG_BANK.)
        JSR SelectBank          ;
        LDA HeroY               ;The zone: X / 15, Y / 15.
        JSR Div15               ;
        ASL                     ;
        ASL                     ;
        STA Tmp                 ;
        LDA HeroX               ;
        JSR Div15               ;
        PHA                     ;
        LSR                     ;
        CLC                     ;
        ADC Tmp                 ;
        TAX                     ;
        LDA EnZones,X           ;
        STA Tmp                 ;
        PLA                     ;Even X: the upper nibble.
        LSR                     ;
        BCS +                   ;
        LSR Tmp                 ;
        LSR Tmp                 ;
        LSR Tmp                 ;
        LSR Tmp                 ;
*       LDA Tmp                 ;
        AND #$0F                ;
        STA Tmp                 ;
        BNE ++                  ;
        JSR NextRandom          ;Zone 0: maybe not.
        LDX #$01                ;
        LDA Tmp3                ;
        CMP #$02                ;
        BNE +                   ;
        LDX #$03                ;
*       TXA                     ;
        AND Random+1            ;
        BEQ +                   ;
        RTS                     ;
*       LDA Tmp                 ;One of the zone's 5.
        ASL                     ;
        ASL                     ;
        CLC                     ;
        ADC Tmp                 ;
        STA Tmp                 ;
*       JSR NextRandom          ;
        LDA Random+1            ;
        AND #$07                ;
        CMP #$05                ;
        BCS -                   ;
        CLC                     ;
        ADC Tmp                 ;
        TAX                     ;
        LDA EnGroups,X          ;
        JSR Repelled            ;
        BCC +                   ;
        RTS                     ;
*       JMP StartBattle         ;
CaveEncounter:
        STA Tmp                 ;Its row * 5.
        ASL                     ;
        ASL                     ;
        CLC                     ;
        ADC Tmp                 ;
        STA Tmp                 ;
        LDA #FIGHT_ENEMY        ;(Test builds: this enemy, or none.)
        CMP #$FE                ;
        BNE +                   ;
        RTS                     ;
*       CMP #$FF                ;
        BEQ +                   ;
        JMP StartBattle         ;
*       JSR NextRandom          ;
        LDA Random+1            ;
        AND #$0F                ;
        BEQ CaveEnemy           ;
        RTS                     ;
CaveEnemy:
        JSR SelectMsg           ;(EnGroups's bank.)
        JSR NextRandom          ;One of the row's 5.
        LDA Random+1            ;
        AND #$07                ;
        CMP #$05                ;
        BCS CaveEnemy           ;
        CLC                     ;
        ADC Tmp                 ;
        TAX                     ;
        LDA EnGroups,X          ;
        JSR Repelled            ;
        BCC +                   ;
        RTS                     ;
*       JMP StartBattle         ;

;The name's part in the stats (LoadStats): its first 4 letters' sum; its
;bit 0 cuts the max MP (if any) to 9/10, else the strength; bit 1 the max
;HP, else the agility; and bits 2-3 are added to each cut one.
NameStats:
        LDA HeroName            ;
        CLC                     ;
        ADC HeroName+1          ;
        CLC                     ;
        ADC HeroName+2          ;
        CLC                     ;
        ADC HeroName+3          ;
        STA Tmp2                ;
        LSR                     ;
        LSR                     ;
        AND #$03                ;
        STA NameBonus           ;
        LDX #Strength-MaxHP     ;
        LSR Tmp2                ;
        BCC +                   ;
        LDX #MaxMP-MaxHP        ;
        LDA MaxMP               ;
        BEQ ++                  ;
*       JSR NineTenths          ;
*       LDX #Agility-MaxHP      ;
        LSR Tmp2                ;
        BCC NineTenths          ;
        LDX #$00                ;
;MaxHP+X = its 9/10 (X less X/10, rounded up), and NameBonus more.
.alias NameBonus        $07B3   ;
NineTenths:
        LDA MaxHP,X             ;
        CLC                     ;
        ADC #9                  ;
        LDY #$00                ;
*       CMP #10                 ;
        BCC +                   ;
        SBC #10                 ;
        INY                     ;
        BNE -                   ;
*       STY Tmp                 ;
        LDA NameBonus           ;
        CLC                     ;
        ADC MaxHP,X             ;
        SEC                     ;
        SBC Tmp                 ;
        STA MaxHP,X             ;
        RTS                     ;

;A = A / 15.
Div15:
        LDX #$00                ;
*       CMP #15                 ;
        BCC +                   ;
        SBC #15                 ;
        INX                     ;
        BNE -                   ;
*       TXA                     ;
        RTS                     ;

;ProdHi:ProdLo = A * MulB.
Mul8:
        STA Tmp                 ;
        LDA #$00                ;
        STA ProdHi              ;
        LDX #$08                ;
*       LSR Tmp                 ;
        BCC +                   ;
        CLC                     ;
        ADC MulB                ;
*       ROR                     ;
        ROR ProdLo              ;
        DEX                     ;
        BNE --                  ;
        STA ProdHi              ;
        RTS                     ;

;A random byte times A, over 256: 0 to A - 1.
RandTimes:
        STA MulB                ;
        JSR NextRandom          ;
        LDA Random+1            ;
        JSR Mul8                ;
        LDA ProdHi              ;
        RTS                     ;

;A fight with enemy A: its stats, name and picture, the battle scene and the
;dialog window, the enemy's arrival message.
StartBattle:
        JSR LoadEnemy           ;
        STA Enemy               ;
        LDA #$01                ;
        STA BattleOn            ;
        LDA #$00                ;No one asleep or stopped.
        STA HeroSleep           ;
        STA HeroStop            ;
        STA EnSleep             ;
        STA EnStop              ;
        JSR TownBattle          ;(Off the overworld: no people, black.)
        LDA #$00                ;The hero out of sight.
        JSR HeroAt              ;
        LDX Enemy               ;HP: 3/4 to all of its base HP.
        LDA EnemyMaxHP          ;
        STA EnemyHP             ;
        LDX Enemy               ;(The Dragonlord's second form: all of it.)
        CPX #EN_DRAGONLORD2     ;
        BEQ +                   ;
        JSR RandTimes           ;
        LSR                     ;
        LSR                     ;
        STA Tmp                 ;
        LDA EnemyHP             ;
        SEC                     ;
        SBC Tmp                 ;
        STA EnemyHP             ;
*       LDA Enemy               ;Its name (in the text bank).
        CLC                     ;
        ADC #EN_NAMES           ;
        TAX                     ;
        JSR NameOf              ;
        STA EnemyNameLen        ;
        LDY #$00                ;
*       CPY EnemyNameLen        ;
        BEQ +                   ;
        LDA (NamePtr),Y         ;
        STA EnemyName,Y         ;
        INY                     ;
        BNE -                   ;
*       LDA #MSC_FIGHT          ;(His second form: his own music.)
        LDX Enemy               ;
        CPX #EN_DRAGONLORD2     ;
        BNE +                   ;
        LDA #MSC_END_BOSS       ;
*       JSR PlayMusic           ;
        JSR LoadMonster         ;
        JSR MonsterComes        ;
        JSR ComposeScene        ;
        JSR DLIBits             ;
        LDA #$00                ;
        STA StatusOn            ;
        JSR ShowStatus          ;
        LDA #B_INTRO            ;
        STA BState              ;
        LDA #$E2                ;The enemy appears: said. (His second form:
        LDX Enemy               ;high message $19, his own.)
        CPX #EN_DRAGONLORD2     ;
        BNE +                   ;
        LDA #$19                ;
        JSR SetSay              ;
        INC BattleList+1        ;
        BNE ++                  ;
*       JSR SetSay              ;
*       JSR OpenDialog          ;
        LDA #$03                ;
        STA Mode                ;
        RTS                     ;

;The monster's record (MonsterLo/Hi, in its MonsterBank): its first 15
;bytes into MonHead, its grids into WithGrid and WithoutGrid, its glyphs
;into LowerSet from code 1; the white text from code 64 and the name's
;letters (set A's name slots) made white. UpperSet: the scene's glyphs from
;code 1, set A's text from code 64. A monster too big for one set
;(more than 63 glyphs) has its rows from MonSplit in Lower2Set.
LoadMonster:
        LDA MapId               ;A cave's battle: the monster on black (no
        BEQ +                   ;scene there), MonsterDark's.
        LDX Enemy               ;
        LDA EnemyDarkBank     ;
        JSR SelectBank          ;
        LDX Enemy               ;
        LDA EnemyDarkLo       ;
        STA SrcPtr              ;
        LDA EnemyDarkHi       ;
        STA SrcPtr+1            ;
        JMP LoadHead            ;
*       LDX Enemy               ;
        LDA EnemyPicBank         ;
        JSR SelectBank          ;
        LDX Enemy               ;
        LDA EnemyPicLo           ;
        STA SrcPtr              ;
        LDA EnemyPicHi           ;
        STA SrcPtr+1            ;
LoadHead:
        LDY #14                 ;
*       LDA (SrcPtr),Y          ;
        STA MonHead,Y           ;
        DEY                     ;
        BPL -                   ;
        LDY #15                 ;
        LDA (SrcPtr),Y          ;
        STA MonSplit            ;
        TAX                     ;
        DEX                     ;
        STX SplitDLI            ;(At no row when there is no split: $FF.)
        INY                     ;
        LDA (SrcPtr),Y          ;
        STA MonGlyphs2          ;
        LDA #$00                ;
        STA MonGone             ;
        LDX MonTop              ;
        DEX                     ;
        STX LowerDLI            ;
        LDA #SCENE_END          ;The grids: 14 * (18 - top) codes each.
        SEC                     ;
        SBC MonTop              ;
        JSR Times14             ;
        STA GridSize            ;
        LDA #17                 ;
        JSR SrcAdd              ;
        LDY #$00                ;
*       LDA (SrcPtr),Y          ;
        STA WithGrid,Y          ;
        INY                     ;
        CPY GridSize            ;
        BNE -                   ;
        TYA                     ;
        JSR SrcAdd              ;
        LDY #$00                ;
*       LDA (SrcPtr),Y          ;
        STA WithoutGrid,Y       ;
        INY                     ;
        CPY GridSize            ;
        BNE -                   ;
        TYA                     ;
        JSR SrcAdd              ;
        LDA #<[LowerSet+8]      ;The glyphs, 8 bytes each.
        STA DstPtr              ;
        LDA #>[LowerSet+8]      ;
        STA DstPtr+1            ;
        LDX MonGlyphs           ;(His second form's past 63: below, to
        CPX #64                 ;TEXT_END on, after the text.)
        BCC +                   ;
        LDX #63                 ;
*       JSR CopyGlyphs          ;
        TYA                     ;
        JSR SrcAdd              ;
        LDX MonGlyphs2          ;Its second set's (rows from MonSplit).
        BEQ +                   ;
        LDA #<[Lower2Set+8]     ;
        STA DstPtr              ;
        LDA #>[Lower2Set+8]     ;
        STA DstPtr+1            ;
        JSR CopyGlyphs          ;
        TYA                     ;
        JSR SrcAdd              ;
*
        LDA #MONSTER_BANK+1     ;UpperSet's, from the second monster bank
        JSR SelectBank          ;(with the battle text); none in a cave,
        LDA MapId               ;whose map's copy is there (TownMap).
        BEQ +                   ;
        JMP LowerText           ;
*       LDA #<SCENE_DATA        ;
        STA SrcPtr              ;
        LDA #>SCENE_DATA        ;
        STA SrcPtr+1            ;
        LDA #<[UpperSet+8]      ;
        STA DstPtr              ;
        LDA #>[UpperSet+8]      ;
        STA DstPtr+1            ;
        LDX #SCENE_GLYPHS       ;
        JSR CopyGlyphs          ;
        LDX #SCENE_SHOWN*14-1   ;Its grid, to RAM.
*       LDA SCENE_DATA+SCENE_GLYPHS*8,X ;
        STA SceneGrid,X         ;
        DEX                     ;
        CPX #$FF                ;
        BNE -                   ;
        LDX #$07                ;Code 0 blank.
        LDA #$00                ;
*       STA UpperSet,X          ;
        DEX                     ;
        BPL -                   ;
        LDX #$00                ;The text from code 64: set A's in UpperSet,
*       LDA CharsetA+$200,X     ;
        STA UpperSet+$200,X     ;
        LDA CharsetA+$300,X     ;
        STA UpperSet+$300,X     ;
        INX                     ;
        BNE -                   ;
LowerText:
        LDX #$07                ;LowerSet's code 0 blank, its text from code
        LDA #$00                ;64 BattleText (400 bytes).
*       STA LowerSet,X          ;
        STA Lower2Set,X         ;(And the second set's, the same.)
        DEX                     ;
        BPL -                   ;
        LDX #$00                ;
*       LDA BATTLE_TEXT,X       ;
        STA LowerSet+$200,X     ;
        STA Lower2Set+$200,X    ;
        LDA BATTLE_TEXT+$100,X  ;
        STA LowerSet+$300,X     ;
        STA Lower2Set+$300,X    ;
        INX                     ;
        BNE -                   ;
        LDX #31                 ;The name slots: set A's, made white.
*       LDY CharsetA+NAME_SLOT*8,X ;
        LDA TO_WHITE,Y          ;(In the second monster bank.)
        STA LowerSet+NAME_SLOT*8,X ;
        STA Lower2Set+NAME_SLOT*8,X ;
        DEX                     ;
        BPL -                   ;
        LDA MonGlyphs           ;Glyphs past 63 (his second form's, only
        SEC                     ;in a dark battle: SrcPtr still at them).
        SBC #63                 ;
        BCC MonGlyphsIn         ;
        BEQ MonGlyphsIn         ;
        PHA                     ;
        LDX Enemy               ;
        LDA EnemyDarkBank       ;
        JSR SelectBank          ;
        LDA #<[LowerSet+TEXT_END*8] ;
        STA DstPtr              ;
        LDA #>[LowerSet+TEXT_END*8] ;
        STA DstPtr+1            ;
        PLA                     ;
        TAX                     ;
        JSR CopyGlyphs          ;
MonGlyphsIn:
        RTS                     ;

;A = glyph byte A's 4 pixels in the monster's colors (MonVals, + X: 0 for
;a map character without bit 7, 4 with it). Y kept.
MapByte:
        STA MapSrc              ;
        STX Tmp3                ;
        LDA #$04                ;
        STA Lead                ;
MapPixel:
        LDA #$00                ;The next pixel's value.
        ASL MapSrc              ;
        ROL                     ;
        ASL MapSrc              ;
        ROL                     ;
        CLC                     ;
        ADC Tmp3                ;
        TAX                     ;
        ASL Tmp2                ;
        ASL Tmp2                ;
        LDA Tmp2                ;
        ORA MonVals,X           ;
        STA Tmp2                ;
        DEC Lead                ;
        BNE MapPixel            ;
        RTS                     ;

;SrcPtr += A.
SrcAdd:
        CLC                     ;
        ADC SrcPtr              ;
        STA SrcPtr              ;
        BCC +                   ;
        INC SrcPtr+1            ;
*       RTS                     ;

;Copy X glyphs (X > 0) from SrcPtr to DstPtr.
CopyGlyphs:
        LDY #$00                ;
*       LDA (SrcPtr),Y          ;
        STA (DstPtr),Y          ;
        INY                     ;
        BNE +                   ;
        INC SrcPtr+1            ;
        INC DstPtr+1            ;
*       TYA                     ;
        AND #$07                ;
        BNE --                  ;
        DEX                     ;
        BNE --                  ;
        RTS                     ;

;A = A * 14 (A below 18).
Times14:
        STA Tmp                 ;
        ASL                     ;
        ASL                     ;
        ASL                     ;
        ASL                     ;
        SEC                     ;
        SBC Tmp                 ;
        SEC                     ;
        SBC Tmp                 ;
        RTS                     ;

;Draw the scene's rows: the window's cells from the grids, the map's
;beside it (columns -2 to 33, as many as can show) given codes in the band.
ComposeScene:
        LDA #$00                ;
        STA InLower             ;
        LDX #$07                ;(Under the command window: black, unless
*       STA CmdBuf,X            ;composed.)
        DEX                     ;
        BPL -                   ;
        LDA #SCENE_GLYPHS+1     ;
        JSR NewBand             ;
        LDA #SCENE_ROW          ;A cave's: from the monster's top (no scene;
        LDX MapId               ;the map round it is black). His second
        BEQ ComposeFrom         ;form's: the whole view, black but him.
        LDA MonTop              ;
        LDX Enemy               ;
        CPX #EN_DRAGONLORD2     ;
        BNE ComposeFrom         ;
        LDA #$00                ;
ComposeFrom:
        STA WinRow              ;
ComposeRow:
        LDA WinRow              ;
        CMP MonTop              ;
        BNE +                   ;
        INC InLower             ;The lower band from here.
        LDA MonGlyphs           ;
        CLC                     ;
        ADC #$01                ;
        JSR NewBand             ;
*       LDA MonSplit            ;Its second set's, from the split.
        BEQ +                   ;
        CMP WinRow              ;
        BNE +                   ;
        LDA #$02                ;
        STA InLower             ;
        LDA MonGlyphs2          ;
        CLC                     ;
        ADC #$01                ;
        JSR NewBand             ;
*       LDA #$FE                ;
        STA WinCol              ;
ComposeCol:
        LDA WinCol              ;
        SEC                     ;
        SBC #SCENE_COL          ;
        CMP #14                 ;
        BCS +                   ;
        JSR SceneCell           ;
        JMP ComposePut          ;
*       LDA #$00                ;(His second form: black round him.)
        LDX Enemy               ;
        CPX #EN_DRAGONLORD2     ;
        BEQ ComposePut          ;
        JSR GetChar             ;
        JSR RemapChar           ;
ComposePut:
        JSR PutChar             ;
        LDA WinCol              ;Under the command window: kept.
        SEC                     ;
        SBC #24                 ;
        CMP #$04                ;
        BCS +                   ;
        TAX                     ;
        LDA WinRow              ;
        CMP #SCENE_ROW          ;
        BEQ ComposeKeep         ;
        CMP #SCENE_ROW+1        ;
        BNE +                   ;
        INX                     ;
        INX                     ;
        INX                     ;
        INX                     ;
ComposeKeep:
        LDA PcChar              ;
        STA CmdBuf,X            ;
*       INC WinCol              ;
        LDA WinCol              ;
        CMP #34                 ;
        BNE ComposeCol          ;
        INC WinRow              ;
        LDA WinRow              ;
        CMP #SCENE_END          ;
        BNE ComposeRow          ;
        RTS                     ;

;A new band: no map characters given codes yet, the first free code A.
NewBand:
        CMP #64                 ;(After 63, TEXT_END.)
        BNE +                   ;
        LDA #TEXT_END           ;
*       STA NextFree            ;
        LDA #$FF                ;
        LDX #$00                ;
NewBandClear:
        STA RemapTbl,X          ;
        INX                     ;
        BNE NewBandClear        ;
        RTS                     ;

;A = the window's code at (WinRow, WinCol) (WinCol 10-23): the upper
;grid's in the upper band, the lower's (with the monster or without) in
;the lower.
SceneCell:
        LDA WinCol              ;
        SEC                     ;
        SBC #SCENE_COL          ;
        STA Lead                ;
        LDA WinRow              ;
        CMP MonTop              ;
        BCS +                   ;
        LDX MapId               ;(No scene in a cave: black.)
        BEQ SceneUpper          ;
        LDA #$00                ;
        RTS                     ;
SceneUpper:
        SEC                     ;
        SBC #SCENE_ROW          ;
        JSR Times14             ;
        CLC                     ;
        ADC Lead                ;
        TAX                     ;
        LDA SceneGrid,X         ;
        RTS                     ;
*       SEC                     ;
        SBC MonTop              ;
        JSR Times14             ;
        CLC                     ;
        ADC Lead                ;
        TAX                     ;
        LDA MonGone             ;
        BNE +                   ;
        LDA WithGrid,X          ;
        RTS                     ;
*       LDA WithoutGrid,X       ;
        RTS                     ;

;Each band's set's page: the scene's, the monster's, its second.
BandSet:        .byte >UpperSet, >LowerSet, >Lower2Set

;A = the band's code for the screen's character A: text as it is; a map
;character the code given it, or the next free one, its glyph copied from
;set A (in the lower band, through ByteMap0-1); 0 (blank) once none are
;left.
RemapChar:
        TAX                     ;
        AND #$7F                ;
        CMP #64                 ;
        BCC +                   ;
        TXA                     ;
        RTS                     ;
*       LDA RemapTbl,X          ;
        CMP #$FF                ;
        BNE RemapHave           ;
        LDA NextFree            ;
        BNE +                   ;
        RTS                     ;
*       STX Tmp                 ;Tmp: the character, Count: its code.
        STA Count               ;
        TXA                     ;Its glyph: CharsetA + (char AND $7F) * 8.
        AND #$7F                ;
        LDY #$00                ;
        STY SrcPtr+1            ;
        ASL                     ;
        ASL                     ;
        ROL SrcPtr+1            ;
        ASL                     ;
        ROL SrcPtr+1            ;
        STA SrcPtr              ;
        LDA SrcPtr+1            ;
        ADC #>CharsetA          ;(C is clear.)
        STA SrcPtr+1            ;
        LDA Count               ;Where it goes: the band's set + code * 8.
        LDY #$00                ;
        STY DstPtr+1            ;
        ASL                     ;
        ASL                     ;
        ROL DstPtr+1            ;
        ASL                     ;
        ROL DstPtr+1            ;
        STA DstPtr              ;
        LDX InLower             ;
        LDA BandSet,X           ;
RemapUpper:
        CLC                     ;
        ADC DstPtr+1            ;
        STA DstPtr+1            ;
        LDY #$07                ;
        LDA InLower             ;
        BNE RemapLower          ;
*       LDA (SrcPtr),Y          ;The upper band: as it is.
        STA (DstPtr),Y          ;
        DEY                     ;
        BPL -                   ;
        LDA Tmp                 ;
        AND #$80                ;
        JMP RemapDone           ;
RemapLower:
        LDX #$00                ;Through the monster's colors: without bit
        LDA Tmp                 ;7, or with it.
        BPL +                   ;
        LDX #$04                ;
*       STX Tmp3                ;(MapByte keeps it.)
RemapLowerByte:
        LDA (SrcPtr),Y          ;
        LDX Tmp3                ;
        JSR MapByte             ;
        STA (DstPtr),Y          ;
        DEY                     ;
        BPL RemapLowerByte      ;
        LDA MonInv              ;
        LDX Tmp3                ;
        BEQ RemapDone           ;
        LDA MonInv+1            ;
RemapDone:
        ORA Count               ;
        LDX Tmp                 ;
        STA RemapTbl,X          ;
        PHA                     ;
        LDX Count               ;The next free code: after 63, TEXT_END;
        INX                     ;none after 127.
        CPX #64                 ;
        BNE +                   ;
        LDX #TEXT_END           ;
*       CPX #128                ;
        BNE +                   ;
        LDX #$00                ;
*       STX NextFree            ;
        PLA                     ;
RemapHave:
        RTS                     ;

;The monster comes, and goes (the 5200's own touch: the NES's just shows
;or hides it). Off the overworld, where the map round the window is
;black, its colors fade in or out (MonFade, the VBI's); on the overworld,
;whose scene shares its colors, its rows show or go one by one, every
;other first (WipeOrder), a row a frame (MonsterWipe, each battle frame).
MonsterComes:
        LDX MapId               ;
        BEQ MonsterComesRows    ;
        LDA #16                 ;Black, then to its colors.
        STA MonFade             ;
        LDA #$00                ;
        STA MonFadeTo           ;
        RTS                     ;
MonsterComesRows:
        STX MonFade             ;
        STX MonFadeTo           ;
        STX WipeShow            ;
        INX                     ;The scene without it first.
        STX MonGone             ;
        LDA #12                 ;
        STA WipeLeft            ;
        RTS                     ;

;The monster is gone.
EraseMonster:
        LDA #$01                ;
        STA MonGone             ;(The grid without it from now: SceneCell.)
        LDX MapId               ;
        BEQ EraseRows           ;
        LDA #16                 ;
        STA MonFadeTo           ;
        RTS                     ;
EraseRows:
        STA WipeShow            ;
        LDA #12                 ;
        STA WipeLeft            ;
        RTS                     ;

;A battle frame: the next row of the monster's coming or going, if any.
MonsterWipe:
        LDX WipeLeft            ;
        BNE +                   ;
        RTS                     ;
*       DEX                     ;
        STX WipeLeft            ;
        LDA WipeOrder,X         ;
        CLC                     ;
        ADC MonTop              ;
        CMP #SCENE_END          ;
        BCS WipeState           ;(A row past the scene's: none.)
        STA WinRow              ;
        LDA WipeShow            ;Its row from the grid wanted.
        STA MonGone             ;
        LDA #SCENE_COL          ;
        STA WinCol              ;
WipeCell:
        JSR SceneCell           ;
        JSR PutChar             ;
        INC WinCol              ;
        LDA WinCol              ;
        CMP #SCENE_COL+14       ;
        BNE WipeCell            ;
WipeState:
        LDA WipeShow            ;Going: the grid without it. Coming: without
        BNE WipeSet             ;it until all its rows are shown, then with.
        LDA WipeLeft            ;
        BEQ WipeSet             ;
        LDA #$01                ;
WipeSet:
        STA MonGone             ;
        RTS                     ;
;The rows from the monster's top in the order they come or go (read from
;the last): every other one first.
WipeOrder:      .byte 11, 9, 7, 5, 3, 1, 10, 8, 6, 4, 2, 0

;EnemyRec = enemy A's record (ENEMY_RECS, in MSG_BANK). A kept.
LoadEnemy:
        PHA                     ;
        STA Tmp                 ;Its place: A * 16.
        LDA #$00                ;
        STA SrcPtr+1            ;
        LDA Tmp                 ;
        ASL                     ;
        ROL SrcPtr+1            ;
        ASL                     ;
        ROL SrcPtr+1            ;
        ASL                     ;
        ROL SrcPtr+1            ;
        ASL                     ;
        ROL SrcPtr+1            ;
        CLC                     ;
        ADC #<ENEMY_RECS        ;
        STA SrcPtr              ;
        LDA SrcPtr+1            ;
        ADC #>ENEMY_RECS        ;
        STA SrcPtr+1            ;
        JSR SelectMsg           ;
        LDY #15                 ;
*       LDA (SrcPtr),Y          ;
        STA EnemyRec,Y          ;
        DEY                     ;
        BPL -                   ;
        PLA                     ;
        RTS                     ;

;Show message A (in the low blocks) next: BattleList and MsgList set.
SetSay:
        STA BattleList          ;
        LDA #$00                ;
        STA BattleList+1        ;
        LDA #$FF                ;
        STA BattleList+2        ;
        STA BattleList+3        ;
        LDA #<BattleList        ;
        STA MsgList             ;
        LDA #>BattleList        ;
        STA MsgList+1           ;
        RTS                     ;

;Show message A now, and take step X once it is out.
Say:
        STX BState              ;
        JSR SetSay              ;
        JMP NextMessage         ;

;Message $1xx (a high block).
SayHi:
        STX BState              ;
        JSR SetSay              ;
        INC BattleList+1        ;
        JMP NextMessage         ;

;--------------------------------------[The fight]---------------------------------------------------

;A frame of a battle: the command window, or the dialog, and once its
;message is out, the next step.
BattleFrame:
        JSR MonsterWipe         ;
        LDA ListOn              ;The spells' list window.
        BEQ +                   ;
        JMP ListFrame           ;
*       LDA BState              ;
        CMP #B_CMD              ;
        BNE +                   ;
        JMP BattleCmdFrame      ;
*       LDA DlgState            ;
        CMP #$02                ;
        BEQ +                   ;
        JMP DialogFrame         ;
*       LDX BState              ;
        LDA StepLo,X            ;
        STA Ptr                 ;
        LDA StepHi,X            ;
        STA Ptr+1               ;
        JMP (Ptr)               ;

StepLo: .byte <StepIntro, <StepPrompt, <StepNone, <StepAttack, <StepDamage, <StepEnemy, <StepEnemyHit
        .byte <StepRound, <StepWin, <StepExp, <StepGold, <StepLevel, <StepStr, <StepAgi, <StepHP
        .byte <StepMP, <StepClose, <StepRun, <StepGone, <StepDead, <StepDead2, <StepHSpell
        .byte <StepEnAct, <StepEnAsleep, <StepEnChant, <StepEnSpell, <StepHAsleep, <StepFire
        .byte <StepCommand, <StepNewSpell, <StepLord2, <StepLordEnd2, <StepTune
StepHi: .byte >StepIntro, >StepPrompt, >StepNone, >StepAttack, >StepDamage, >StepEnemy, >StepEnemyHit
        .byte >StepRound, >StepWin, >StepExp, >StepGold, >StepLevel, >StepStr, >StepAgi, >StepHP
        .byte >StepMP, >StepClose, >StepRun, >StepGone, >StepDead, >StepDead2, >StepHSpell
        .byte >StepEnAct, >StepEnAsleep, >StepEnChant, >StepEnSpell, >StepHAsleep, >StepFire
        .byte >StepCommand, >StepNewSpell, >StepLord2, >StepLordEnd2, >StepTune

StepNone:
        RTS                     ;

;Who goes first (CalcWhoIsNext): the hero's agility times a random byte
;against the enemy's defense times a random 0-63; C set if the hero wins.
HeroFirst:
        JSR NextRandom          ;
        LDA Random+1            ;
        AND #$3F                ;
        LDX Enemy               ;
        LDY EnemyDef               ;
        STY MulB                ;
        JSR Mul8                ;
        LDA ProdLo              ;
        STA Prev                ;
        LDA ProdHi              ;
        STA Prev+1              ;
        JSR NextRandom          ;
        LDA Agility             ;
        STA MulB                ;
        LDA Random+1            ;
        JSR Mul8                ;
        LDA ProdLo              ;
        SEC                     ;
        SBC Prev                ;
        LDA ProdHi              ;
        SBC Prev+1              ;
        RTS                     ;

StepIntro:
        JSR HeroFirst           ;
        BCS StepRound           ;
        LDA #$E4                ;The enemy goes first: said.
        LDX #B_ENEMY            ;
        JMP Say                 ;
StepRound:
        LDA HeroSleep           ;Asleep: half the time the hero wakes.
        BEQ StepCommand         ;
        JSR NextRandom          ;
        LDA Random+1            ;
        LSR                     ;
        BCS +                   ;
StepHAsleep:
        LDA #$07                ;The hero is still asleep.
        LDX #B_ENEMY            ;
        JMP SayHi               ;
*       LDA #$00                ;
        STA HeroSleep           ;
        LDA #$08                ;The hero wakes.
        LDX #B_COMMAND          ;
        JMP SayHi               ;
StepCommand:
        LDA #$E8                ;Command?
        LDX #B_PROMPT           ;
        JMP Say                 ;
StepPrompt:
        JSR OpenBattleCmd       ;
        LDA #B_CMD              ;
        STA BState              ;
        RTS                     ;

;FIGHT: the hero's attack message, and the damage worked out (PlyrFight): 1 in 32 an
;excellent move (the attack less up to half of it), else
;PlyrCalcHitDmg.
DoFight:
        LDA #$00                ;
        STA Excellent           ;
        JSR NextRandom          ;
        LDA Enemy               ;(None against the Dragonlord.)
        CMP #EN_DRAGONLORD      ;
        BCS +                   ;
        LDA Random+1            ;
        AND #$1F                ;
        BNE +                   ;
        INC Excellent           ;
        JSR GetAttack           ;
        LSR                     ;
        JSR RandTimes           ;
        STA Tmp                 ;
        JSR GetAttack           ;
        SEC                     ;
        SBC Tmp                 ;
        STA Damage              ;
        JMP ++                  ;
*       JSR GetAttack           ;
        LDX Enemy               ;
        LDY EnemyDef               ;
        JSR HitDamage           ;
        STA Damage              ;
*       LDA #SFX_ATTACK         ;
        JSR PlaySFX             ;
        LDA #$E5                ;Loto attacks!
        LDX #B_ATTACK           ;
        JMP Say                 ;

;A = the damage of attack A on defense Y, as PlyrCalcHitDmg works it out:
;A - Y / 2 under 2: 1 or 0 at random; else ((that + 1) * random / 256 +
;that) / 4.
HitDamage:
        STA Tmp2                ;
        TYA                     ;
        LSR                     ;
        STA Tmp                 ;
        LDA Tmp2                ;
        SEC                     ;
        SBC Tmp                 ;
        BCC HitWeak             ;
        CMP #$02                ;
        BCC HitWeak             ;
NormalHit:
        STA Tmp2                ;(Tmp2 = attack - defense / 2.)
        CLC                     ;
        ADC #$01                ;
        JSR RandTimes           ;
        CLC                     ;
        ADC Tmp2                ;
        ROR                     ;
        LSR                     ;
        RTS                     ;
HitWeak:
        JSR NextRandom          ;
        LDA Random+1            ;
        AND #$01                ;
        RTS                     ;

;The hero's attack message is out: an excellent move, a miss, the enemy dodging (by
;its magic defense: 1 in 64 per point past the first), or the damage.
StepAttack:
        LDA Excellent           ;
        BEQ +                   ;
        LDA #$00                ;
        STA Excellent           ;
        LDA #SFX_EXCELLENT      ;
        JSR PlaySFX             ;
        LDA #$04                ;An excellent move: said.
        LDX #B_ATTACK           ;
        JMP SayHi               ;
*       LDA Damage              ;
        BNE +                   ;
        LDA #SFX_MISSED1        ;
        JSR PlaySFX             ;
        LDA #$E7                ;The hero misses: said.
        LDX #B_ENEMY            ;
        JMP Say                 ;
*       JSR NextRandom          ;
        LDA Random+1            ;
        AND #$3F                ;
        STA Tmp                 ;
        LDX Enemy               ;
        LDA EnemyMDef              ;
        AND #$0F                ;
        BEQ StepDamage          ;
        SEC                     ;
        SBC #$01                ;
        CMP Tmp                 ;
        BCC StepDamage          ;
        LDA #SFX_MISSED1        ;
        JSR PlaySFX             ;
        LDA #$0A                ;The enemy dodges: said.
        LDX #B_ENEMY            ;
        JMP SayHi               ;
StepDamage:
        LDA #SFX_ENEMY_HIT      ;
        JSR PlaySFX             ;
        LDA Damage              ;The damage to the enemy: said, with its
        STA Amount              ;amount.
        LDA #$00                ;
        STA Amount+1            ;
        LDA EnemyHP             ;
        SEC                     ;
        SBC Damage              ;
        BCS +                   ;
        LDA #$00                ;
*       STA EnemyHP             ;
        LDX #B_ENEMY            ;
        CMP #$00                ;
        BNE +                   ;
        LDX #B_WIN              ;
*       LDA #$E6                ;
        JMP Say                 ;

;The enemy's attack message is out: its damage (EnCalcHitDmg): attack less the
;hero's defense / 2, below attack / 2 + 1 a weak hit, ((attack / 2 + 1) *
;random / 256 + 2) / 3; else as the hero's.
StepEnemyHit:
        JSR GetDefense          ;The hero's defense (agility / 2 and the
        LSR                     ;armor's), / 2.
        STA Tmp                 ;
        LDX Enemy               ;
        LDA EnemyAtt               ;
        LSR                     ;
        CLC                     ;
        ADC #$01                ;
        STA Tmp3                ;
        LDA EnemyAtt               ;
        SEC                     ;
        SBC Tmp                 ;
        BCC EnWeak              ;
        CMP Tmp3                ;
        BCC EnWeak              ;
        JSR NormalHit           ;
        JMP EnHit               ;
EnWeak:
        LDA Tmp3                ;
        JSR RandTimes           ;
        CLC                     ;
        ADC #$02                ;
        LDX #$00                ;/ 3.
*       CMP #$03                ;
        BCC +                   ;
        SBC #$03                ;
        INX                     ;
        BNE -                   ;
*       TXA                     ;
EnHit:
        STA Damage              ;
        BNE +                   ;
        LDA #SFX_MISSED2        ;
        JSR PlaySFX             ;
        LDA #$FB                ;The miss message.
        LDX #B_ROUND            ;
        JMP Say                 ;
*       STA Amount              ;(The HP lost, for the hurt message.)
        LDA #SFX_HERO_HIT       ;
        JSR PlaySFX             ;
        LDA #$00                ;
        STA Amount+1            ;
        LDA HitPoints           ;
        SEC                     ;
        SBC Damage              ;
        BCS +                   ;
        LDA #$00                ;
*       STA HitPoints           ;
        JSR RedrawStatus        ;
        LDX #B_ROUND            ;
        LDA HitPoints           ;
        BNE +                   ;
        LDX #B_DEAD             ;
*       LDA #$FA                ;
        JMP Say                 ;

StepDead:
        LDA #MSC_DEATH          ;
        JSR PlayMusic           ;
        LDA #$01                ;The death message.
        LDX #B_DEAD2            ;
        JMP Say                 ;
StepDead2:
        LDA Pressed             ;A button: back to the King.
        AND #BTN_A+BTN_B        ;
        BNE +                   ;
        RTS                     ;
*       JMP HeroDies            ;

;The enemy is defeated: it goes; experience, gold, levels.
StepWin:
        LDA #MSC_VICTORY        ;
        JSR PlayMusic           ;
        JSR EraseMonster        ;
        JSR GuardianWon         ;
        LDA Enemy               ;The Dragonlord: his second form, or his end
        CMP #EN_DRAGONLORD      ;(castle.asm).
        BCC +                   ;
        JMP LordBeaten          ;
*
        LDA #$EE                ;The victory message.
        LDX #B_EXP              ;
        JMP Say                 ;
StepExp:
        LDX Enemy               ;
        LDA EnemyExp               ;
        STA Amount              ;
        LDA #$00                ;
        STA Amount+1            ;
        LDA EnemyExp               ;
        CLC                     ;
        ADC Experience          ;
        STA Experience          ;
        BCC +                   ;
        INC Experience+1        ;
*       JSR RedrawStatus        ;
        LDA #$EF                ;The experience gained.
        LDX #B_GOLD             ;
        JMP Say                 ;
StepGold:
        LDX Enemy               ;
        LDA EnemyGold              ;
        STA Amount              ;
        LDA #$00                ;
        STA Amount+1            ;
        LDA EnemyGold              ;
        CLC                     ;
        ADC Gold                ;
        STA Gold                ;
        BCC +                   ;
        INC Gold+1              ;
*       JSR RedrawStatus        ;
        LDA #$F0                ;The gold gained.
        LDX #B_LEVEL            ;
        JMP Say                 ;

;A new level, if the experience reaches the next (LevelExp): the stats of
;it (LevelStr and so on), and what grew.
StepLevel:
        JSR SelectMsg           ;(The level tables' bank.)
        LDX Level               ;
        CPX #30                 ;
        BCS LevelNone           ;
        LDA Experience+1        ;
        CMP LevelExpHi,X        ;
        BCC LevelNone           ;
        BNE +                   ;
        LDA Experience          ;
        CMP LevelExpLo,X        ;
        BCC LevelNone           ;
*       LDA Strength            ;
        STA Prev                ;
        LDA Agility             ;
        STA Prev+1              ;
        LDA MaxHP               ;
        STA Prev+2              ;
        LDA MaxMP               ;
        STA Prev+3              ;
        INC Level               ;
        LDA LevelStr,X          ;(X = the new level - 1.)
        STA Strength            ;
        LDA LevelAgi,X          ;
        STA Agility             ;
        LDA LevelHP,X           ;
        STA MaxHP               ;
        LDA LevelMP,X           ;
        STA MaxMP               ;
        JSR NameStats           ;
        JSR RedrawStatus        ;
        LDA #MSC_LEVEL_UP       ;
        JSR PlayMusic           ;
        LDA #$F1                ;The new level's message.
        LDX #B_STR              ;
        JMP Say                 ;
LevelNone:
        LDA #B_CLOSE            ;
        STA BState              ;
        RTS                     ;
StepStr:
        LDA Strength            ;
        LDX #$00                ;
        LDY #$0E                ;Strength grew (message $0E, high).
        LDA #B_AGI              ;
        PHA                     ;
        LDA Strength            ;
        JMP SayGrowth           ;
StepAgi:
        LDA #B_HP               ;
        PHA                     ;
        LDA Agility             ;
        LDX #$01                ;
        LDY #$0F                ;Agility grew ($0F).
        JMP SayGrowth           ;
StepHP:
        LDA #B_MP               ;
        PHA                     ;
        LDA MaxHP               ;
        LDX #$02                ;
        LDY #$10                ;Max HP grew ($10).
        JMP SayGrowth           ;
StepMP:
        LDA #B_NEWSPELL         ;Then a new spell, maybe another level.
        PHA                     ;
        LDA MaxMP               ;
        LDX #$03                ;
        LDY #$11                ;Max MP grew ($11).
;Stat A grew from Prev+X: say how much with high message Y (if at all),
;then the step on the stack.
SayGrowth:
        SEC                     ;
        SBC Prev,X              ;
        STA Amount              ;
        LDA #$00                ;
        STA Amount+1            ;
        PLA                     ;
        TAX                     ;
        LDA Amount              ;
        BNE +                   ;
        STX BState              ;Nothing: straight on.
        RTS                     ;
*       TYA                     ;
        JMP SayHi               ;

;A spell learned on the new level (ChkNewSpell): said; then maybe another
;level.
StepNewSpell:
        LDX #9                  ;
*       LDA SpellLevel,X        ;
        CMP Level               ;
        BEQ +                   ;
        DEX                     ;
        BPL -                   ;
        JMP StepLevel           ;
*       LDA #$F2                ;A new spell has been learned.
        LDX #B_LEVEL            ;
        JMP Say                 ;

;All said: a button ends the battle.
StepClose:
        LDA Pressed             ;
        AND #BTN_A+BTN_B        ;
        BNE StepGone            ;
        RTS                     ;
StepGone:
        JMP EndBattle           ;

;RUN: the run message; then as who goes first decides (weaker
;enemies: TryRun).
DoRun:
        LDA #SFX_RUN            ;
        JSR PlaySFX             ;
        LDA #$F5                ;
        LDX #B_RUN              ;
        JMP Say                 ;
StepRun:
        JSR HeroFirst           ;
        BCC +                   ;
        JMP EndBattle           ;
*       LDA #$F6                ;The escape failed.
        LDX #B_ENEMY            ;
        JMP Say                 ;

;The status window drawn again (its numbers changed).
RedrawStatus:
        LDA #$00                ;
        STA StatusOn            ;
        JMP ShowStatus          ;

;The end of a battle: the map back, the hero back.
EndBattle:
        LDA #$00                ;
        STA BattleOn            ;
        STA DialogOn            ;
        STA StatusOn            ;
        STA Mode                ;
        STA StandTime           ;
        LDA #HERO_HPOS          ;
        JSR HeroAt              ;
        JSR TownBattleEnd       ;
        JSR DLIBits             ;
        JSR PlayMapMusic        ;
        JMP DrawView            ;

;Dead: back to the King with half the gold, HP and MP full (as the game's
;InitDeathSequence), and what he says to a hero he brings back.
HeroDies:
        JSR EndBattle           ;
        LSR Gold+1              ;
        ROR Gold                ;
        LDA MaxHP               ;
        STA HitPoints           ;
        LDA MaxMP               ;
        STA MagicPoints         ;
        LDA #THRONE_X           ;
        STA HeroX               ;
        LDA #THRONE_Y           ;
        STA HeroY               ;
        LDA #$00                ;Facing up, to the King.
        STA Facing              ;
        LDA Flags2              ;Cursed: outside Tantegel instead.
        AND #F2_CURSED          ;
        BEQ +                   ;
        JMP CursedDeath         ;
*       LDA #THRONE_MAP         ;
        JSR LoadMap             ;
        LDA #<DeathTalk         ;
        STA MsgList             ;
        LDA #>DeathTalk         ;
        STA MsgList+1           ;
        JMP OpenDialog          ;

;The King's words after a death: brought back, the experience to the next level, sent off.
DeathTalk:
        .word $010D, $FFFD, $0112, $0113, $FFFF

;--------------------------------------[The command window]------------------------------------------

;The battle's command window: FIGHT, SPELL, RUN, ITEM, the cursor on FIGHT.
OpenBattleCmd:
        LDX #TPL_BATTLE         ;
        JSR DrawTemplate        ;
        LDA #$00                ;
        STA Cursor              ;
        LDA #$02                ;Two rows: down from the first only.
        STA CmdDownMax          ;
        LDA #TL_ARROW           ;
        JMP PutCursor           ;

;A frame with it up: the stick moves the cursor, the lower fire button
;chooses.
BattleCmdFrame:
        LDA Pressed             ;
        AND #BTN_A              ;
        BNE +                   ;
        JMP CmdMove             ;
*       JSR CloseBattleCmd      ;
        LDA Cursor              ;
        BNE +                   ;
        JMP DoFight             ;
*       CMP #$02                ;
        BNE +                   ;
        JMP DoRun               ;
*       CMP #$01                ;SPELL (spell.asm).
        BNE +                   ;
        JMP BattleSpell         ;
*       JMP BattleItem          ;ITEM (spell.asm).

;Close it: rows 2-5 the map again, rows 6-7 the scene (and the map beside
;it, as composed).
CloseBattleCmd:
        LDA #$06                ;
        STA CmdDownMax          ;
        LDA #2                  ;Block rows 1-2, columns 6-13.
        STA Rows                ;
        LDX #6                  ;
        LDY #1                  ;
        LDA #8                  ;
        JSR RedrawBlocks        ;
        LDA #SCENE_ROW          ;
        STA WinRow              ;
        LDY #$00                ;CmdBuf's index.
*       LDA #CMD_COL            ;
        STA WinCol              ;
*       LDA WinCol              ;
        CMP #SCENE_COL+14       ;
        BCS +                   ;
        JSR SceneCell           ;
        JMP CloseCell           ;
*       LDA CmdBuf,Y            ;
        INY                     ;
CloseCell:
        JSR PutChar             ;
        INC WinCol              ;
        LDA WinCol              ;
        CMP #CMD_COL+CMD_WIDTH  ;
        BNE --                  ;
        INC WinRow              ;
        LDA WinRow              ;
        CMP #CMD_ROW+6          ;
        BNE ---                 ;
        RTS                     ;
