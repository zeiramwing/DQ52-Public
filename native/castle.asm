;The Dragonlord's castle: the rainbow bridge to its island, the stairs
;hidden behind his throne, and the Dragonlord himself.
;
;Its maps are towns (maps.TOWNS): the ground floor and the bottom one lit,
;the six between them dark, each with the game's enemies. Battles off the
;overworld have no scene (the monster on black), so a lit map's copy in
;TownMap is kept through one.

.alias F_BRIDGE         $08     ;ModFlags: the rainbow bridge is built,
.alias F_PASSAGE        $10     ;the stairs behind the throne are found,
.alias F_DL_DEAD        $20     ;the Dragonlord is dead,
.alias F_GDRAGON        $40     ;the green dragon of the swamp cave is,
.alias F_CARRY          $02     ;the princess is being carried home,
.alias F_RETURNED       $04     ;she is home.
.alias F_GOLEM          $80     ;and the golem by Cantlin.
.alias BRIDGE_X         64      ;Where the bridge is (GetBlockID's check),
.alias BRIDGE_Y         49      ;
.alias DROP_X           65      ;and where the hero holds up the drop (DoRainbow).
.alias BLK_BRIDGE       $0A     ;The bridge's block.
.alias MSC_RAINBOW      $13     ;
.alias RAINBOW_ITEM     32      ;The rainbow drop (ITM_ $0E).
.alias RAINBOW_FRAMES   200     ;Its tune's length, before the map's music.

;At a map's load: on the overworld with the bridge built, its row in RAM
;(BridgeRow, the bridge put in) and BridgeY its number; else BridgeY $FF.
SetBridge:
        LDA #$FF                ;
        STA BridgeY             ;
        LDA MapId               ;
        BNE NoBridge            ;
        LDA ModFlags            ;
        AND #F_BRIDGE           ;
        BEQ NoBridge            ;
        LDA #MAP_BANK           ;
        JSR SelectBank          ;
        LDY #BRIDGE_Y           ;(The cartridge's row: BridgeY is $FF.)
        JSR WorldRow            ;
        LDY #WORLD_SIZE-1       ;
*       LDA (MapPtr),Y          ;
        STA BridgeRow,Y         ;
        DEY                     ;
        BPL -                   ;
        LDA #BLK_BRIDGE         ;
        STA BridgeRow+BRIDGE_X  ;
        LDA #BRIDGE_Y           ;
        STA BridgeY             ;
NoBridge:                       ;(Not '+': the copy loop's label is the
        RTS                     ;next one, and it once wrote a stray byte.)

;The rainbow drop held up (ChkDrop): east of the bridge's place on the
;overworld, the bridge built (once), with its tune; else nothing.
StepItRainbow:
        LDA MapId               ;
        BNE RainbowFail         ;
        LDA HeroX               ;
        CMP #DROP_X             ;
        BNE RainbowFail         ;
        LDA HeroY               ;
        CMP #BRIDGE_Y           ;
        BNE RainbowFail         ;
        LDA ModFlags            ;
        AND #F_BRIDGE           ;
        BNE RainbowFail         ;
        LDA ModFlags            ;
        ORA #F_BRIDGE           ;
        STA ModFlags            ;
        JSR SetBridge           ;
        LDA #BRIDGE_X           ;The bridge's block drawn.
        STA BX                  ;
        LDA #BRIDGE_Y           ;
        STA BY                  ;
        LDA #$01                ;
        STA Count               ;
        JSR DrawRowPart         ;
        LDA #MSC_RAINBOW        ;
        JSR PlayMusic           ;
        LDA #RAINBOW_FRAMES     ;
        STA SleepTime           ;
        LDA #IT_RBWAIT          ;
        STA ShopState           ;
        RTS                     ;
RainbowFail:
        LDA #$05                ;Nothing comes of it: said.
        JMP ShopEnd             ;

;Its tune out: the map's music, and walking again.
StepItRbWait:
        DEC SleepTime           ;
        BEQ +                   ;
        RTS                     ;
*       LDA #$00                ;
        STA ShopState           ;
        JSR PlayMapMusic        ;
        JMP CloseDialog         ;

;--------------------------------------[The throne's stairs]-----------------------------------------

.alias PASSAGE_X        10      ;The stairs behind the throne (GetBlockID's
.alias PASSAGE_Y        1       ;check), and the throne before them (the
.alias THRONE_SEAT_Y    3       ;wind there: SrchPassage).
.alias BLK_FFIELD       $0D     ;What the stairs show until they are found.
.alias BLK_STAIRS_DN    $05     ;
.alias BLK_SWAMP        $06     ;
.alias SFX_FFIELD       $80     ;
.alias SFX_SWAMP        $84     ;

;After the castle's ground floor is copied to TownMap: its stairs behind
;the throne a force field until they are found.
HidePassage:
        LDA MapId               ;
        CMP #CASTLE_GF          ;
        BNE +                   ;
        LDA ModFlags            ;
        AND #F_PASSAGE          ;
        BNE +                   ;
        LDA #BLK_FFIELD         ;
        STA TownMap+PASSAGE_Y*32+PASSAGE_X ;
*       JMP HideThrone          ;

;At a map's load: any map but the throne room, and the hero has left it
;(F2_LEFT, the game's F_LEFT_THROOM); the throne room once he has, its three
;chests and its door gone (floor), as the game takes them (ChkLeftThRoom).
HideThrone:
        LDA MapId               ;
        CMP #THRONE_MAP         ;
        BEQ +                   ;
        LDA Flags2              ;
        ORA #F2_LEFT            ;
        STA Flags2              ;
        RTS                     ;
*       LDA Flags2              ;
        AND #F2_LEFT            ;
        BEQ +                   ;
        LDA #BLK_BRICK          ;
        STA TownMap+1*32+6      ;
        STA TownMap+4*32+4      ;
        STA TownMap+4*32+5      ;
        STA TownMap+7*32+4      ;
*       RTS                     ;

;SEARCH where the game hides something (its search finds): Erdrick's
;token on the overworld and the fairy flute in Kol, found once (unless the
;hero has it; with a full inventory the game asks what to throw away,
;treasure.asm's DiscardItem), and Erdrick's armor in Hauksness, put on. In the
;castle: on the throne, the wind behind it; behind it, the stairs found
;(once). C set if it said so.
SearchCastle:
        LDX #$00                ;
SearchFind:
        LDA SearchFinds,X       ;
        CMP MapId               ;
        BNE SearchFindNext      ;
        LDA SearchFinds+1,X     ;
        CMP HeroX               ;
        BNE SearchFindNext      ;
        LDA SearchFinds+2,X     ;
        CMP HeroY               ;
        BNE SearchFindNext      ;
        LDA SearchFinds+3,X     ;
        BMI SearchArmor         ;
        STA ShopTmpX            ;An item.
        JSR HasItem             ;
        BCS SearchNone          ;
        LDA ShopTmpX            ;Its name, for the find.
        CLC                     ;
        ADC #ITM_BASE           ;
        STA ItemName            ;
        LDA ShopTmpX            ;
        STA DsItem              ;(Full: DiscardItem, treasure.asm.)
        JSR AddItem             ;
        LDA #<TokenFound        ;
        LDY #>TokenFound        ;
        BCC +                   ;
        LDA #<TokenFull         ;
        LDY #>TokenFull         ;
*       JSR SayList             ;
        SEC                     ;
        RTS                     ;
SearchArmor:
        LDA Equipped            ;Erdrick's armor: worn, unless it is.
        AND #ARMOR_BITS         ;
        CMP #ERDRICK_ARMOR      ;
        BEQ SearchNone          ;
        LDA Equipped            ;
        ORA #ERDRICK_ARMOR      ;
        STA Equipped            ;
        LDA #ERDRICK_ARMOR_ITEM ;
        STA ItemName            ;
        LDA #<TokenFound        ;
        LDY #>TokenFound        ;
        JSR SayList             ;
        SEC                     ;
        RTS                     ;
SearchFindNext:
        INX                     ;
        INX                     ;
        INX                     ;
        INX                     ;
        CPX #4*3                ;
        BNE SearchFind          ;
        LDA MapId               ;
SearchInCastle:
        CMP #CASTLE_GF          ;
        BNE SearchNone          ;
        LDA HeroX               ;
        CMP #PASSAGE_X          ;
        BNE SearchNone          ;
        LDA HeroY               ;
        CMP #THRONE_SEAT_Y      ;
        BNE +                   ;
        LDA #$D6                ;The draft behind the throne (a hint).
        LDX #$00                ;
        JSR ShopOpen            ;
        SEC                     ;
        RTS                     ;
*       CMP #PASSAGE_Y          ;
        BNE SearchNone          ;
        LDA ModFlags            ;
        AND #F_PASSAGE          ;
        BNE SearchNone          ;
        ORA ModFlags            ;(A = 0.)
        ORA #F_PASSAGE          ;
        STA ModFlags            ;
        LDA HeroX               ;
        STA BX                  ;
        LDA HeroY               ;
        STA BY                  ;
        LDA #BLK_STAIRS_DN      ;
        JSR SetBlock            ;
        LDA #PASSAGE_ITEM       ;The passage found (its name inserted).
        STA ItemName            ;
        LDA #$D5                ;
        LDX #$00                ;
        JSR ShopOpen            ;
        SEC                     ;
        RTS                     ;
SearchNone:
        CLC                     ;
        RTS                     ;

.alias ITM_FLUTE        $05     ;
.alias ERDRICK_ARMOR_ITEM 13    ;(Its item number: armor 7 on.)
;The finds: map, X, Y, and the ITM_ code ($FF: Erdrick's armor).
SearchFinds:    .byte 0, 83, 113, ITM_TOKEN
                .byte KOL_MAP, 9, 6, ITM_FLUTE
                .byte HAUKSNESS_MAP, 18, 12, $FF
;The ground searched, the token found (and, the inventory full, no room).
TokenFound:     .word $00D2, $00D5, $FFFF
TokenFull:      .word $00D2, $00D5, $FFFB, DS_FULL

;--------------------------------------[Hurtful ground]----------------------------------------------

;After a step (ChkOtherBlocks): a swamp takes 2 HP, a force field 15, but
;not through Erdrick's armor (nor once the Dragonlord is dead). Dying of
;it: C set, the death's message up.
GroundHurt:
        LDA HeroX               ;
        STA BX                  ;
        LDA HeroY               ;
        STA BY                  ;
        JSR GetBlock            ;
        LDX #2                  ;
        LDY #SFX_SWAMP          ;
        CMP #BLK_SWAMP          ;
        BEQ +                   ;
        LDX #15                 ;
        LDY #SFX_FFIELD         ;
        CMP #BLK_FFIELD         ;
        BNE NoHurt              ;
*       LDA ModFlags            ;
        AND #F_DL_DEAD          ;
        BNE NoHurt              ;
        LDA Equipped            ;
        AND #ARMOR_BITS         ;
        CMP #ERDRICK_ARMOR      ;
        BEQ NoHurt              ;
        STX Tmp                 ;
        TYA                     ;
        JSR PlaySFX             ;
        LDX #2                  ;The screen red: once (a swamp), or 3 times
        LDA Tmp                 ;(the barrier), a frame each.
        CMP #2                  ;
        BEQ +                   ;
        LDX #6                  ;
*       LDA #FX_GROUND          ;
        JSR StartFx             ;
        LDA HitPoints           ;
        SEC                     ;
        SBC Tmp                 ;
        BCS +                   ;
        LDA #$00                ;
*       STA HitPoints           ;
        JSR RedrawStatus        ;
        LDA HitPoints           ;
        BNE NoHurt              ;
        LDA #MSC_DEATH          ;Dead (InitDeathSequence): its message,
        JSR PlayMusic           ;a button, back to the King.
        LDA #$01                ;
        LDX #FD_DEAD            ;
        JSR ShopOpen            ;
        SEC                     ;
        RTS                     ;
NoHurt:
        CLC                     ;
        RTS                     ;

;The death's message is out: a button.
StepFieldDead:
        LDA Pressed             ;
        AND #BTN_A+BTN_B        ;
        BNE +                   ;
        RTS                     ;
*       LDA #$00                ;
        STA ShopState           ;
        JMP HeroDies            ;

;--------------------------------------[The Dragonlord]----------------------------------------------

.alias GFX_HERO         $9C00   ;the hero's frames (ShowHero),
.alias GFX_ANIM         $8B00   ;the townspeople's other step (LoadAnim),
.alias GFX_SETB         $9800   ;set B (LoadSetB).

.alias LORD_FIGHT       $F0     ;His dialog's steps (maps.py: as a shop's
.alias LORD_JOIN        $F1     ;control byte).
.alias EN_DRAGONLORD    38      ;His first form,
.alias EN_DRAGONLORD2   39      ;and his second (no picture: on black).
.alias MSC_END_BOSS     $0F     ;
.alias LORD_PAUSE       80      ;Frames between them (the game's wait).


;--------------------------------------[Battles in a castle]-----------------------------------------

.alias SavedPeople      $0289   ;PeopleOn through a battle.
.alias CondI            $07D1   ;CondPeople's.

;A battle off the overworld: the people out of sight (none drawn, their
;players cleared), and a lit map drawn black round the window, as a cave's
;is (Dark $80: lit, made dark; nothing in the light).
TownBattle:
        LDA MapId               ;
        BEQ TownBattleNext      ;
        LDA PeopleOn            ;
        STA SavedPeople         ;
        LDA #$00                ;
        STA PeopleOn            ;
        LDA Dark                ;
        BNE +                   ;
        LDA #$80                ;
        STA Dark                ;
        LDA #$00                ;
        STA LightR              ;
        STA LightW              ;
        JSR DrawView            ;
TownBattleNext:
*       RTS                     ;

;Its end: the people back, a lit map lit again (EndBattle then draws it).
TownBattleEnd:
        LDA MapId               ;
        BEQ +                   ;
        LDA SavedPeople         ;
        STA PeopleOn            ;
        LDA Dark                ;
        BPL +                   ;
        LDA #$00                ;
        STA Dark                ;
        STA LightR              ;
        LDA #$01                ;
        STA LightW              ;
*       RTS                     ;

;--------------------------------------[The rainbow drop's guardian]---------------------------------

.alias RAINBOW_MAN      $F2     ;His dialog's step (maps.py).
.alias ITM_TOKEN        $07     ;The items he asks about (ITM_ codes).
.alias ITM_STONES       $0C     ;
.alias ITM_STAFF        $0D     ;
.alias ITM_DROP         $0E     ;
.alias ITM_HARP         $0A     ;
.alias RAIN_MAN         $F3     ;The staff of rain's guardian (maps.py).

;C set if the inventory holds ITM_ code A (CheckForInvItem). X, Y lost.
HasItem:
        LDX #$03                ;
HasItemLoop:
*       LDY Inventory,X         ;
        PHA                     ;
        TYA                     ;
        AND #$0F                ;
        STA Tmp                 ;
        TYA                     ;
        LSR                     ;
        LSR                     ;
        LSR                     ;
        LSR                     ;
        TAY                     ;
        PLA                     ;
        CMP Tmp                 ;
        BEQ +                   ;
        STY Tmp                 ;
        CMP Tmp                 ;
        BEQ +                   ;
        DEX                     ;
        BPL HasItemLoop         ;
        CLC                     ;
        RTS                     ;
*       SEC                     ;
        RTS                     ;

;--------------------------------------[His end]-----------------------------------------------------

;The Dragonlord beaten: his first form, after a pause, becomes his second
;(the people's count back first, for TownBattle to keep again); his
;second's end said (ball of light), then a button.
LordBeaten:
        CMP #EN_DRAGONLORD2     ;
        BEQ +                   ;
        LDA #LORD_PAUSE         ;
        STA SleepTime           ;
        LDA #B_LORD2            ;
        STA BState              ;
        RTS                     ;
*       LDA #$1A                ;
        LDX #B_LORDEND          ;
        JMP SayHi               ;
StepLord2:
        DEC SleepTime           ;
        BEQ +                   ;
        RTS                     ;
*       LDA SavedPeople         ;
        STA PeopleOn            ;
        LDA #EN_DRAGONLORD2     ;
        JMP StartBattle         ;

;Then (the game's end of the fight): he is dead (no more hurtful ground),
;HP and MP full, and the hero outside his castle, facing down.
StepLordEnd2:
        LDA Pressed             ;
        AND #BTN_A+BTN_B        ;
        BNE +                   ;
        RTS                     ;
*       LDA ModFlags            ;
        ORA #F_DL_DEAD          ;
        STA ModFlags            ;
        LDA MaxHP               ;
        STA HitPoints           ;
        LDA MaxMP               ;
        STA MagicPoints         ;
        JSR EndBattle           ;
        LDX #CASTLE_BF          ;
        LDA OutsideX            ;
        PHA                     ;
        LDY OutsideY            ;
        LDA OutsideMap          ;
        TAX                     ;
        PLA                     ;
        STX Tmp                 ;(SpellGo: map A, block X, Y.)
        TAX                     ;
        LDA Tmp                 ;
        JMP SpellGo             ;

;--------------------------------------[The ending]--------------------------------------------------

.alias ENDING           $F4     ;The ending's step (EndTalk's $FFFB).
.alias MSC_NOSOUND      $00     ;
.alias MSC_END          $10     ;
.alias END_Y            8       ;Where the ending starts in Tantegel's hall:
.alias END_X1           10      ;two blocks before the throne room's stairs
.alias END_X2           11      ;(the game's ChkCstlEnd).
.alias EndPhase         $02E2   ;Its pauses so far (StField's, STATUS being shut).

;After a step, once the Dragonlord is dead: on those blocks in Tantegel,
;the ending (EndGameTriggered): the music stops, the King's last words
;(the princess not being there: TaleEnd's), then EndStep. C set if begun.
EndTrigger:
        LDA ModFlags            ;
        AND #F_DL_DEAD          ;
        BEQ NoEnd               ;
        LDA MapId               ;
        CMP #TANTEGEL_GF        ;
        BNE NoEnd               ;
        LDA HeroY               ;
        CMP #END_Y              ;
        BNE NoEnd               ;
        LDA HeroX               ;
        CMP #END_X1             ;
        BEQ +                   ;
        CMP #END_X2             ;
        BNE NoEnd               ;
*       LDA #MSC_NOSOUND        ;
        JSR PlayMusic           ;
        LDA #$00                ;
        STA EndPhase            ;
        LDA ModFlags            ;The princess home, or carried: her part.
        AND #F_CARRY+F_RETURNED ;
        BEQ +                   ;
        LDA ModFlags            ;(Set down, then asking to be carried.)
        AND #$FF-F_CARRY        ;
        STA ModFlags            ;
        LDA #<EndGwTalk         ;
        LDY #>EndGwTalk         ;
        BNE EndTriggerNext      ;
*       LDA #<EndTalk           ;
        LDY #>EndTalk           ;
EndTriggerNext:
*       JSR SayList             ;
        SEC                     ;
        RTS                     ;
NoEnd:
        CLC                     ;
        RTS                     ;

EndTalk:        .word $011B, $0122, $FFFB, ENDING
EndGwTalk:      .word $011B, $011C, $011D, $FFFB, END_GW

;Her part (the game's GwaelinJoin: her figure is not drawn): she asks to
;go with the hero until YES, and is carried; then the tale's end.
.alias END_GW           $FB     ;(EndGwTalk's $FFFB.)
;Message $0100 + A next, then step X.
ShopHi:
        STX ShopState           ;
        JSR SetSay              ;
        INC BattleList+1        ;
        RTS                     ;


;--------------------------------------[The guardians]-----------------------------------------------

;Fights where the game sets them (CheckAxeKnight on): map, block, enemy,
;and the flag that ends it once won (0: none, every time).
Guardians:      .byte HAUKSNESS_MAP, 18, 12, $21, 0
                .byte SWAMP_MAP, 4, 14, $1E, F_GDRAGON
                .byte 0, 73, 100, $18, F_GOLEM

;After a step: on a guardian's block (and it not beaten), its fight. C
;set if it began.
GuardianFight:
        LDX #$00                ;
GuardNext:
        LDA Guardians,X         ;
        CMP MapId               ;
        BNE GuardSkip           ;
        LDA Guardians+1,X       ;
        CMP HeroX               ;
        BNE GuardSkip           ;
        LDA Guardians+2,X       ;
        CMP HeroY               ;
        BNE GuardSkip           ;
        LDA Guardians+4,X       ;
        AND ModFlags            ;
        BNE GuardSkip           ;
        LDA Guardians+3,X       ;
        JSR StartBattle         ;
        SEC                     ;
        RTS                     ;
GuardSkip:
        TXA                     ;
        CLC                     ;
        ADC #$05                ;
        TAX                     ;
        CPX #3*5                ;
        BNE GuardNext           ;
        CLC                     ;
        RTS                     ;

;A fight won: a guardian's flag set, if this was one where it waits
;(EnemyDefeated: the green dragon in the swamp cave, the golem on the
;overworld). X lost.
GuardianWon:
        LDX #$00                ;
GuardianWonLoop:
*       LDA Guardians+3,X       ;
        CMP Enemy               ;
        BNE +                   ;
        LDA Guardians,X         ;
        CMP MapId               ;
        BNE +                   ;
        LDA Guardians+4,X       ;
        ORA ModFlags            ;
        STA ModFlags            ;
*       TXA                     ;
        CLC                     ;
        ADC #$05                ;
        TAX                     ;
        CPX #3*5                ;
        BNE GuardianWonLoop     ;
        RTS                     ;

;--------------------------------------[The princess]------------------------------------------------

.alias BLK_PRINCESS     $17     ;Her block in the swamp cave,
.alias PRINCESS_X       5       ;where she waits.
.alias PRINCESS_Y       18      ;
.alias BLK_BRICK        $04     ;(It once she is gone.)
.alias GWAELIN          $F5     ;Her steps, and the King's for her
.alias KING_GW          $F6     ;(dialogs' $FFFB).
.alias KING_GFX         4       ;The King's figure (the throne room's only one).
.alias ITM_LOVE         $08     ;Her keepsake, the King's gift.

;At a map's load, after its people: each of those who come and go
;(convert.py's COMES_AND_GOES, drawn in the background) who is not there
;now (its ModFlags bit as CondWhen says) has its block put back to what
;was under it, and is out of TALK's reach.
CondPeople:
        LDX #NUM_CONDS-1        ;
CondNext:
        LDA CondMap,X           ;
        CMP MapId               ;
        BNE CondSkip            ;
        LDA CondFlag,X          ;(No bit: there at every load.)
        BEQ CondSkip            ;
        AND ModFlags            ;
        BEQ +                   ;
        LDA #$FF                ;
*       EOR CondWhen,X          ;
        BNE CondSkip            ;
        STX CondI               ;
        JSR CondGone            ;
        LDX CondI               ;
CondSkip:
        DEX                     ;
        BPL CondNext            ;
        RTS                     ;
;Entry X's person gone: its block what was under it, and the person (if
;loaded) off the map.
CondGone:
        LDA CondX,X             ;
        STA BX                  ;
        LDA CondY,X             ;
        STA BY                  ;
        LDA CondUnder,X         ;
        PHA                     ;
        JSR PersonAt            ;(First: SetBlock's drawing moves BX, BY.)
        BCC +                   ;
        LDA #$FF                ;
        STA PersonX,X           ;
*       PLA                     ;
        JMP SetBlock            ;
;The staff of rain's old man going: his entry, by the map.
CondHere:
        LDX #NUM_CONDS-1        ;
*       LDA CondMap,X           ;
        CMP MapId               ;
        BEQ CondGone            ;
        DEX                     ;
        BPL -                   ;
        RTS                     ;

;At a map's load: in the swamp cave, once she is carried or home, her
;block is floor (GetBlockID).
HidePrincess:
        LDA MapId               ;
        CMP #SWAMP_MAP          ;
        BNE +                   ;
        LDA ModFlags            ;
        AND #F_CARRY+F_RETURNED ;
        BEQ +                   ;
        LDA #BLK_BRICK          ;
        STA TownMap+PRINCESS_Y*32+PRINCESS_X ;
*       RTS                     ;

;TALK to her: her words, then whether she is taken to the castle, asked
;until it is YES (DoGwaelinRescue).
TalkPrincess:
        LDA #<GwaelinTalk       ;
        STA MsgList             ;
        LDA #>GwaelinTalk       ;
        STA MsgList+1           ;
        SEC                     ;
        RTS                     ;
GwaelinTalk:    .word $00B5, $FFFB, GWAELIN
;TALK to the King, carrying her (DoKingDialog): his thanks, her keepsake
;given (the bag full: an item of KeepTake's taken for it),
;her farewell; she is home.
KingGwaelin:
        LDA ModFlags            ;
        AND #F_CARRY            ;
        BEQ KingGwaelinNext     ;
        LDA MapId               ;The King: in the throne room, his figure.
        CMP #THRONE_MAP         ;
        BNE +                   ;
        LDX ShopTmpI            ;
        LDA PersonGfx,X         ;
        CMP #KING_GFX           ;
        BNE +                   ;
        LDA #<KingGwTalk        ;
        STA MsgList             ;
        LDA #>KingGwTalk        ;
        STA MsgList+1           ;
KingGwaelinNext:
*       RTS                     ;
KingGwTalk:     .word $00B9, $FFFB, KING_GW

;--------------------------------------[Healing armor]-----------------------------------------------

.alias ArmorSteps       $07AA   ;Steps in magic armor (MjArmrHP).

;After a step (MovementUpdates): Erdrick's armor gives back 1 HP each step,
;magic armor 1 every 4th; never past the most.
ArmorHeal:
        LDA Equipped            ;
        AND #ARMOR_BITS         ;
        CMP #ERDRICK_ARMOR      ;
        BEQ +                   ;
        CMP #MAGIC_ARMOR        ;
        BNE ArmorHealNext       ;
        INC ArmorSteps          ;
        LDA ArmorSteps          ;
        AND #$03                ;
        BNE ArmorHealNext       ;
*       LDA HitPoints           ;
        CMP MaxHP               ;
        BCS +                   ;
        INC HitPoints           ;
        JMP RedrawStatus        ;
ArmorHealNext:
*       RTS                     ;

;--------------------------------------[Her keepsake]------------------------------------------------

.alias LOVE_ITEM        ITM_BASE+ITM_LOVE ;
.alias HOME_X           43      ;Tantegel, where the distances are from.
.alias HOME_Y           43      ;

;Used (ChkLove): the experience to the next level (or that the last is
;reached); on the overworld, how far the castle is north or south, east or
;west; then her words.
LoveUse:
        LDA Level               ;
        CMP #30                 ;
        BCC +                   ;
        LDX #LV_MAP             ;The last level (high message $05).
        STX ShopTmpN            ;
        LDA #$05                ;
        JSR SetSay              ;
        INC BattleList+1        ;
        JMP ShopOpenSaid        ;
*       LDA #MSG_BANK           ;(ExpToLevel's tables.)
        JSR SelectBank          ;
        JSR ExpToLevel          ;
        LDA #$DB                ;
        LDX #LV_MAP             ;
        JMP ShopOpen            ;
StepLvMap:
        LDA MapId               ;
        BNE StepLvEnd           ;
        LDA #$DC                ;
        LDX #LV_DD              ;
        JMP ShopSay             ;
StepLvDD:
        LDA #$DD                ;
        LDX #LV_Y               ;
        JMP ShopSay             ;
StepLvY:
        LDA HeroY               ;North (below it) or south.
        LDX #$DE                ;
        LDY #HOME_Y             ;
        JSR LoveDistance        ;
        LDX #LV_X               ;
        JMP ShopSay             ;
StepLvX:
        LDA HeroX               ;West or east.
        LDX #$E1                ;
        LDY #HOME_X             ;
        JSR LoveDistance        ;
        LDX #LV_END             ;
        JMP ShopSay             ;
StepLvEnd:
        LDA #$BD                ;
        JMP ShopEnd             ;

;Amount = |A - Y|; A = message X when A is past Y, else X + 1.
LoveDistance:
        STY Tmp                 ;
        SEC                     ;
        SBC Tmp                 ;
        BCS +                   ;
        EOR #$FF                ;
        ADC #$01                ;(C clear: + 1.)
        INX                     ;
*       STA Amount              ;
        LDA #$00                ;
        STA Amount+1            ;
        TXA                     ;
        RTS                     ;

;--------------------------------------[Curses and the ring]-----------------------------------------

.alias Flags2           $025B   ;Worn: bit 0 the fighter's ring, 6 the cursed
.alias F2_RING          $01     ;belt, 7 the death necklace (ModsnSpells').
.alias F2_LEFT          $02     ;(And bit 1: the throne room left, HideThrone.)
.alias F2_BELT          $40     ;
.alias F2_NECK          $80     ;
.alias F2_CURSED        $C0     ;
.alias RING_ITEM        ITM_BASE+$06 ;
.alias BELT_ITEM        ITM_BASE+$09 ;
.alias NECK_ITEM        ITM_BASE+$0B ;
.alias MSC_CURSED       $17     ;
.alias CURSE_MAN        $F8     ;The curse lifter's dialog step, the ring
.alias RING_MAN         $F9     ;man's (maps.py).
.alias DS_FULL          $FA     ;A search's find, the bag full (TokenFull).
.alias MP_MAN           $FC     ;The wizard who gives MP back (maps.py).
.alias CURSED_Y         27      ;Tantegel's hall row that turns the cursed out.

;The fighter's ring put on, or put right (ChkRing).
WearRing:
        LDA Flags2              ;
        LSR                     ;
        LDA #$3F                ;
        BCS +                   ;
        LDA Flags2              ;
        ORA #F2_RING            ;
        STA Flags2              ;
        LDA #$3E                ;
*       LDX #$00                ;
        JMP ShopOpen            ;

;A cursed item (Y its bit) put on: cursed, with the curse's tune (then the
;map's music again); already on, it squeezes (WearCursedItem).
WearCursed:
        TYA                     ;
        AND Flags2              ;
        BEQ +                   ;
        LDA #$43                ;
        LDX #$00                ;
        JMP ShopOpen            ;
*       TYA                     ;
        ORA Flags2              ;
        STA Flags2              ;
        LDA #MSC_CURSED         ;
        JSR PlayMusic           ;
        LDA #RAINBOW_FRAMES     ;
        STA SleepTime           ;
        LDA #$42                ;
        LDX #IT_RBWAIT          ;
        JMP ShopOpen            ;

;After a step: cursed in Tantegel's hall on its gate row, turned out
;(CheckTantCursed). C set if so.
CursedGate:
        LDA Flags2              ;
        AND #F2_CURSED          ;
        BEQ CursedGateNext      ;
        LDA MapId               ;
        CMP #TANTEGEL_GF        ;
        BNE +                   ;
        LDA HeroY               ;
        CMP #CURSED_Y           ;
        BNE +                   ;
        LDA #$44                ;
        LDX #RM_EXIT            ;
        JSR ShopOpen            ;
        SEC                     ;
        RTS                     ;
CursedGateNext:
*       CLC                     ;
        RTS                     ;

;Dead and cursed: outside Tantegel (its first link in), the King's words
;for the cursed (high $14).
CursedDeath:
        LDA #TANTEGEL_GF        ;
        STA MapId               ;
        JSR LeaveMap            ;
        LDA #<CursedTalk        ;
        LDY #>CursedTalk        ;
        JMP SayList             ;
CursedTalk:     .word $0114, $FFFF
