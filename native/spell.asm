;Spells: the SPELL command on the map and in a battle, the enemies' spells.
;
;The hero knows a spell from the level the game teaches it on (SpellLevel,
;from BaseStatsTbl's spell bits: the game learns them in order). Spells are
;listed in the list window as items SPELL_ITEM on (convert.py: their MP
;cost as their price, their name in the text bank), so TX_SPELL inserts the
;spell's name as TX_ITEM inserts an item's. The sums and the messages are
;the game's (Bank03's DoSpell, CheckMP, and the fight's spells).

.alias SpellNum         $0283   ;The spell being cast (0-9).
.alias HeroSleep        $0284   ;Non-zero: the hero is asleep (a battle's),
.alias HeroStop         $0285   ;the hero's spells are stopped,
.alias EnSleep          $0286   ;the enemy is asleep,
.alias EnStop           $0287   ;the enemy's spells are stopped.
.alias RadiantTime      $0288   ;Steps left of RADIANT's light (the game's RadiantTimer).

.alias SPL_HEAL         0       ;The game's spell numbers.
.alias SPL_HURT         1       ;
.alias SPL_SLEEP        2       ;
.alias SPL_RADIANT      3       ;
.alias SPL_STOPSPELL    4       ;
.alias SPL_OUTSIDE      5       ;
.alias SPL_RETURN       6       ;
.alias SPL_REPEL        7       ;
.alias SPL_HEALMORE     8       ;
.alias SPL_HURTMORE     9       ;
.alias SFX_SPELL        $91     ;
.alias SFX_FIRE         $95     ;
.alias ARMOR_BITS       $1C     ;The equipment byte's armor,
.alias MAGIC_ARMOR      $18     ;
.alias ERDRICK_ARMOR    $1C     ;

;ListItems = the spells the hero knows, ListCount how many.
SpellList:
        LDX #$00                ;
        LDY #$00                ;
*       LDA Level               ;
        CMP SpellLevel,X        ;
        BCC +                   ;
        TXA                     ;
        CLC                     ;
        ADC #SPELL_ITEM         ;
        STA ListItems,Y         ;
        INY                     ;
*       INX                     ;
        CPX #10                 ;
        BNE --                  ;
        STY ListCount           ;
        RTS                     ;

;The SPELL command: the spells known in the list window, their MP beside
;them; C clear if there are none (the command's own message then).
SpellCommand:
        JSR SpellList           ;
        LDA ListCount           ;
        BNE +                   ;
        CLC                     ;
        RTS                     ;
*       LDA #$00                ;
        STA ListKind            ;
        LDA #$04                ;
        STA Mode                ;
        LDX #SP_PICK            ;
        JSR OpenList            ;
        SEC                     ;
        RTS                     ;

;The spell chosen: C set if none, else SpellNum and ItemName (its name)
;set, C clear.
ChosenSpell:
        JSR ChosenItem          ;
        BCS +                   ;
        STA ItemName            ;
        SEC                     ;
        SBC #SPELL_ITEM         ;
        STA SpellNum            ;
        CLC                     ;
*       RTS                     ;

;Its MP (CheckMP): A = $32 if the hero has too little; else paid, and A =
;$30, the chant (with its name).
PayMP:
        LDA ItemName            ;
        JSR PriceOf             ;
        STA Tmp                 ;
        LDA MagicPoints         ;
        CMP Tmp                 ;
        BCS +                   ;
        LDA #$32                ;
        RTS                     ;
*       SBC Tmp                 ;
        STA MagicPoints         ;
        JSR RedrawStatus        ;
        LDA #SFX_SPELL          ;
        JSR PlaySFX             ;
        LDA #$30                ;
        RTS                     ;

;--------------------------------------[On the map]--------------------------------------------------

;The spell chosen on the map: the chant (or too little MP), then its
;effect (SP_CAST).
StepSpPick:
        JSR ChosenSpell         ;
        BCC +                   ;
        LDA #$00                ;None: back to walking.
        STA ShopState           ;
        STA Mode                ;
        RTS                     ;
*       JSR PayMP               ;
        LDX #$00                ;
        CMP #$32                ;
        BEQ +                   ;
        LDX #SP_CAST            ;
*       JMP ShopOpen            ;

;The chant is out: what the spell does here (DoSpell).
StepSpCast:
        LDA #$00                ;
        STA ShopState           ;
        LDA SpellNum            ;
        CMP #SPL_HEAL           ;
        BNE +                   ;
        JMP DoHeal              ;
*       CMP #SPL_HEALMORE       ;
        BNE +                   ;
        JMP DoHealmore          ;
*       CMP #SPL_REPEL          ;
        BNE +                   ;
        LDA #$FF                ;(Odd: the spell's, not the fairy water's.)
        STA RepelTime           ;
        RTS                     ;
*       CMP #SPL_RADIANT        ;Only in the dark: the light 7 blocks wide.
        BNE +                   ;
        LDA Dark                ;
        BEQ SpellFizzle         ;
        LDA #$50                ;
        STA RadiantTime         ;
        LDA #$03                ;
        STA LightR              ;
        LDA #$07                ;
        STA LightW              ;
        LDA #SFX_RADIANT        ;
        JSR PlaySFX             ;
        JSR CloseDialog         ;
        JMP RedrawLight         ;
*       CMP #SPL_OUTSIDE        ;Out of a cave, by its own entrance
        BNE +                   ;(OutsideMap), facing down.
        LDX MapId               ;
        LDA OutsideMap          ;
        CMP #$FF                ;
        BEQ SpellFizzle         ;
        PHA                     ;
        LDA OutsideX            ;
        LDY OutsideY            ;
        TAX                     ;
        PLA                     ;
        JMP SpellGo             ;
*       CMP #SPL_RETURN         ;Not in the dark: beside Tantegel, as the
        BNE SpellFizzle         ;wings.
        LDA Dark                ;(Nor on the Dragonlord's floor.)
        BNE SpellFizzle         ;
        LDA MapId               ;
        CMP #CASTLE_BF          ;
        BEQ SpellFizzle         ;
        LDX #RETURN_X           ;
        LDY #RETURN_Y           ;
        LDA #$00                ;
SpellGo:
        STX HeroX               ;Map A, block (X, Y), facing down.
        STY HeroY               ;
        PHA                     ;
        LDA #$00                ;
        STA DialogOn            ;
        STA StatusOn            ;
        STA Mode                ;
        LDA #$02                ;
        STA Facing              ;
        PLA                     ;
        JMP LoadMap             ;

;HURT and SLEEP, or a spell where it cannot work.
SpellFizzle:
        LDA #$33                ;Nothing happened.
        JMP ShopEnd             ;

;HEAL: 10-17 HP back; HEALMORE 85-100; no more than the most.
DoHeal:
        LDX #$07                ;
        LDA #10                 ;
        BNE HealBy              ;
DoHealmore:
        LDX #$0F                ;
        LDA #85                 ;
HealBy:
        STA Tmp3                ;
        STX Tmp2                ;
        JSR NextRandom          ;
        LDA Random+1            ;
        AND Tmp2                ;
        CLC                     ;
        ADC Tmp3                ;
        JMP HealAdd             ;

;After each step: RADIANT's light, a block less each way every 60 steps
;once it runs out; the repel's steps (2 a step: its end said, the spell's
;or the fairy water's). C set if a message is up.
StepTimers:
        LDA RadiantTime         ;
        BEQ ++                  ;
        DEC RadiantTime         ;
        BNE ++                  ;
        LDA LightR              ;
        BEQ ++                  ;
        LDA #60                 ;
        STA RadiantTime         ;
        DEC LightR              ;
        DEC LightW              ;
        DEC LightW              ;
        JSR RedrawLight         ;
*       LDA RepelTime           ;
        BEQ +                   ;
        DEC RepelTime           ;
        DEC RepelTime           ;
        BEQ RepelEnd            ;
        LDA RepelTime           ;
        CMP #$01                ;
        BEQ RepelEnd            ;
*       CLC                     ;
        RTS                     ;
RepelEnd:
        LDA RepelTime           ;
        LDX #$00                ;
        STX RepelTime           ;
        CMP #$01                ;
        LDA #$37                ;The fairy water's end,
        BCC +                   ;
        LDA #$34                ;or the spell's.
*       JSR ShopOpen            ;
        SEC                     ;
        RTS                     ;

;C set if a fight with enemy A is kept off by the repel (ChkFightRepel):
;on the overworld, its repel value under the hero's defense / 2, or past
;it by no more than half its value. Else C clear, A kept.
Repelled:
        JSR LoadEnemy           ;(Its repel value.)
        STA ShopTmpI            ;
        LDX MapId               ;
        BNE NotRepelled         ;
        LDX RepelTime           ;
        BEQ NotRepelled         ;
        JSR GetDefense          ;
        LSR                     ;
        STA Tmp                 ;
        LDX ShopTmpI            ;
        LDA EnemyRepel             ;
        SEC                     ;
        SBC Tmp                 ;
        BCC IsRepelled          ;
        STA Tmp                 ;
        LDA EnemyRepel             ;
        LSR                     ;
        CMP Tmp                 ;
        BCC NotRepelled         ;
IsRepelled:
        SEC                     ;
        RTS                     ;
NotRepelled:
        LDA ShopTmpI            ;
        CLC                     ;
        RTS                     ;

;--------------------------------------[In a battle]-------------------------------------------------

;SPELL in a battle: the spells known in the list window (what it covers
;kept, the battle scene's band characters), or none known.
BattleSpell:
        JSR SpellList           ;
        LDA ListCount           ;
        BNE +                   ;
        LDA #$31                ;No spell learned yet.
        LDX #B_ROUND            ;
        JMP Say                 ;
*       JSR SaveUnder           ;
        LDA #$00                ;
        STA ListKind            ;
        LDX #SP_BATTLE          ;
        JMP OpenList            ;

;The spell chosen in a battle (PlyrSpellChosen): none, the command again;
;one of the map's, not here; then the MP, and the chant.
StepBSpell:
        LDA #$00                ;
        STA ShopState           ;
        JSR ChosenSpell         ;
        BCC +                   ;
        JMP StepCommand         ;
*       LDA SpellNum            ;
        CMP #SPL_RADIANT        ;
        BEQ BadSpell            ;
        CMP #SPL_REPEL          ;
        BEQ BadSpell            ;
        CMP #SPL_OUTSIDE        ;
        BEQ BadSpell            ;
        CMP #SPL_RETURN         ;
        BNE +                   ;
BadSpell:
        LDA #$E9                ;Not usable in battle.
        LDX #B_ROUND            ;
        JMP Say                 ;
*       JSR PayMP               ;
        LDX #B_ROUND            ;Too little MP: the hero's turn again.
        CMP #$32                ;
        BEQ +                   ;
        LDX #B_HSPELL           ;
*       JMP Say                 ;

;The chant is out: the spell's effect (blocked if the hero's spells are
;stopped). HURT, HURTMORE and SLEEP may fail by the enemy's magic defense
;or agility / 16, STOPSPELL by its agility's low 4 bits (ChkSpellFail).
StepHSpell:
        LDA HeroStop            ;
        BEQ +                   ;
        LDA #$EA                ;The spell has been blocked.
        LDX #B_ENEMY            ;
        JMP Say                 ;
*       LDX Enemy               ;
        LDA SpellNum            ;
        BNE +                   ;
        JSR DoHeal              ;HEAL, HEALMORE: then the enemy's turn.
        JMP StepEnemy           ;
*       CMP #SPL_HEALMORE       ;
        BNE +                   ;
        JSR DoHealmore          ;
        JMP StepEnemy           ;
*       CMP #SPL_SLEEP          ;
        BNE +                   ;
        LDA EnemyAgi               ;
        JSR Div16Fails          ;
        BCC SpellFailed         ;
        INC EnSleep             ;
        LDA #$EC                ;The enemy is put to sleep.
        LDX #B_ENASLEEP         ;
        JMP Say                 ;
*       CMP #SPL_STOPSPELL      ;
        BNE +                   ;
        LDA EnemyAgi               ;
        AND #$0F                ;
        JSR SpellFails          ;
        BCC SpellFailed         ;
        INC EnStop              ;
        LDA #$ED                ;The enemy's spells are blocked.
        LDX #B_ENEMY            ;
        JMP Say                 ;
*       LDY #5                  ;HURT: 5-12 damage; HURTMORE 58-65.
        CMP #SPL_HURT           ;
        BEQ +                   ;
        LDY #58                 ;
*       STY Tmp3                ;
        LDA EnemyMDef              ;
        JSR Div16Fails          ;
        BCC SpellFailed         ;
        JSR NextRandom          ;
        LDA Random+1            ;
        AND #$07                ;
        CLC                     ;
        ADC Tmp3                ;
        STA Damage              ;
        JMP StepDamage          ;
SpellFailed:
        LDA #$EB                ;The spell fails.
        LDX #B_ENEMY            ;
        JMP Say                 ;

;C clear if a spell fails: a random 0-15 under A / 16 (Div16Fails), or A.
Div16Fails:
        LSR                     ;
        LSR                     ;
        LSR                     ;
        LSR                     ;
SpellFails:
        STA Tmp                 ;
        JSR NextRandom          ;
        LDA Random+1            ;
        AND #$0F                ;
        CMP Tmp                 ;
        RTS                     ;

;The enemy's turn (StartEnemyTurn): asleep, it wakes 1 time in 3.
StepEnemy:
        LDA EnSleep             ;
        BEQ StepEnAct           ;
*       JSR NextRandom          ;
        LDA Random+1            ;
        AND #$03                ;
        BEQ -                   ;
        CMP #$01                ;
        BNE StepEnAsleep        ;
        LDA #$00                ;
        STA EnSleep             ;
        LDA #$00                ;The enemy wakes.
        LDX #B_ENACT            ;
        JMP Say                 ;
StepEnAsleep:
        LDA #$F8                ;The enemy is asleep.
        LDX #B_ROUND            ;
        JMP Say                 ;

;It may run from a strong hero (strength at least twice its attack: 1 in
;4); else its spells (EnSpells: bits 4-5 how often one of the upper ones,
;6-7 which: SLEEP, STOPSPELL, HEAL, HEALMORE, the last two only below a
;quarter of its HP; bits 0-1 how often a lower one, 2-3 which: HURT,
;HURTMORE, fire, the great fire); else it attacks.
StepEnAct:
        JSR GetAttack           ;
        LSR                     ;
        LDX Enemy               ;
        CMP EnemyAtt               ;
        BCC +                   ;
        JSR NextRandom          ;
        LDA Random+1            ;
        AND #$03                ;
        BNE +                   ;
        JSR EraseMonster        ;
        LDA #$E3                ;The enemy runs away.
        LDX #B_GONE             ;
        JMP Say                 ;
*       JSR NextRandom          ;
        LDX Enemy               ;
        LDA EnemySpells            ;
        AND #$30                ;
        STA Tmp                 ;
        LDA Random+1            ;
        AND #$30                ;
        CMP Tmp                 ;
        BCS EnLower             ;
        LDA EnemySpells            ;
        AND #$C0                ;
        BNE +                   ;
        LDA HeroSleep           ;SLEEP, unless the hero sleeps.
        BNE EnLower             ;
        LDA #SPL_SLEEP          ;
        BNE EnCast              ;
*       CMP #$40                ;STOPSPELL, unless already.
        BNE +                   ;
        LDA HeroStop            ;
        BNE EnLower             ;
        LDA #SPL_STOPSPELL      ;
        BNE EnCast              ;
*       TAY                     ;HEAL or HEALMORE, below a quarter.
        LDA EnemyMaxHP                ;
        LSR                     ;
        LSR                     ;
        CMP EnemyHP             ;
        BCC EnLower             ;
        LDA #SPL_HEAL           ;
        CPY #$80                ;
        BEQ EnCast              ;
        LDA #SPL_HEALMORE       ;
        BNE EnCast              ;
EnLower:
        JSR NextRandom          ;
        LDX Enemy               ;
        LDA EnemySpells            ;
        AND #$03                ;
        STA Tmp                 ;
        LDA Random+1            ;
        AND #$03                ;
        CMP Tmp                 ;
        BCS EnPhys              ;
        LDA EnemySpells            ;
        AND #$0C                ;
        BEQ EnHurt              ;
        CMP #$04                ;
        BEQ EnHurt              ;
        LDY #$10                ;Fire: 16-23; the great fire 65-72 (2/3
        CMP #$08                ;in Erdrick's armor).
        BEQ +                   ;
        LDY #65                 ;
*       STY Tmp3                ;
        JSR NextRandom          ;
        LDA Random+1            ;
        AND #$07                ;
        CLC                     ;
        ADC Tmp3                ;
        STA Damage              ;
        LDA Equipped            ;
        AND #ARMOR_BITS         ;
        CMP #ERDRICK_ARMOR      ;
        BNE +                   ;
        JSR TwoThirds           ;
*       LDA #SFX_FIRE           ;
        JSR PlaySFX             ;
        LDA #$FF                ;The enemy breathes fire.
        LDX #B_FIRE             ;
        JMP Say                 ;
EnHurt:
        LSR                     ;(4 for HURTMORE: 1.)
        LSR                     ;
        TAY                     ;
        LDA #SPL_HURT           ;
        CPY #$00                ;
        BEQ EnCast              ;
        LDA #SPL_HURTMORE       ;
EnCast:
        STA SpellNum            ;Its name, then the chant (EnCastSpell).
        CLC                     ;
        ADC #SPELL_ITEM         ;
        STA ItemName            ;
        LDA #$FC                ;
        LDX #B_ENCHANT          ;
        JMP Say                 ;
EnPhys:
        LDA #SFX_ATTACK_PREP    ;
        JSR PlaySFX             ;
        LDA #$F9                ;The enemy attacks.
        LDX #B_ENEMYHIT         ;
        JMP Say                 ;

StepEnChant:
        LDA #SFX_SPELL          ;
        JSR PlaySFX             ;
        LDA #$FD                ;Its spell's name.
        LDX #B_ENSPELL          ;
        JMP Say                 ;

;The enemy's spell is out: blocked if its spells are stopped; else HURT
;3-10 damage, HURTMORE 30-45 (2/3 in magic or Erdrick's armor); STOPSPELL
;on the hero half the time (never in Erdrick's armor); SLEEP; HEAL 20-27
;HP back, HEALMORE 85-100, no more than it started with.
StepEnSpell:
        LDA EnStop              ;
        BEQ +                   ;
        LDA #$EA                ;
        LDX #B_ROUND            ;
        JMP Say                 ;
*       LDA SpellNum            ;
        CMP #SPL_SLEEP          ;
        BNE +                   ;
        INC HeroSleep           ;
        LDA #$06                ;The hero is asleep.
        LDX #B_HASLEEP          ;
        JMP SayHi               ;
*       CMP #SPL_STOPSPELL      ;
        BNE ++                  ;
        LDA Equipped            ;
        AND #ARMOR_BITS         ;
        CMP #ERDRICK_ARMOR      ;
        BEQ +                   ;
        JSR NextRandom          ;
        LDA Random+1            ;
        LSR                     ;
        BCC +                   ;
        INC HeroStop            ;
        LDA #$FE                ;The hero's spells are blocked.
        LDX #B_ROUND            ;
        JMP Say                 ;
*       LDA #$EB                ;
        LDX #B_ROUND            ;
        JMP Say                 ;
*       LDY #3                  ;
        LDX #$07                ;
        CMP #SPL_HURT           ;
        BEQ EnSpellHurt         ;
        LDY #30                 ;
        LDX #$0F                ;
        CMP #SPL_HURTMORE       ;
        BEQ EnSpellHurt         ;
        LDY #20                 ;HEAL, HEALMORE.
        LDX #$07                ;
        CMP #SPL_HEAL           ;
        BEQ +                   ;
        LDY #85                 ;
        LDX #$0F                ;
*       JSR RandPlus            ;
        CLC                     ;
        ADC EnemyHP             ;
        BCS +                   ;
        LDX Enemy               ;
        CMP EnemyMaxHP                ;
        BCC ++                  ;
*       LDX Enemy               ;
        LDA EnemyMaxHP                ;
*       STA EnemyHP             ;
        LDA #$09                ;The enemy has recovered.
        LDX #B_ROUND            ;
        JMP SayHi               ;
EnSpellHurt:
        JSR RandPlus            ;
        STA Damage              ;
        LDA Equipped            ;
        AND #ARMOR_BITS         ;
        CMP #ERDRICK_ARMOR      ;
        BEQ +                   ;
        CMP #MAGIC_ARMOR        ;
        BNE StepFire            ;
*       JSR TwoThirds           ;
;The damage (Damage) to the hero.
StepFire:
        LDA Damage              ;
        JMP EnHit               ;

;A = Y + a random 0 to X.
RandPlus:
        STY Tmp3                ;
        STX Tmp                 ;
        JSR NextRandom          ;
        LDA Random+1            ;
        AND Tmp                 ;
        CLC                     ;
        ADC Tmp3                ;
        RTS                     ;

;Damage = Damage / 3 * 2.
TwoThirds:
        LDA Damage              ;
        LDX #$00                ;
*       CMP #$03                ;
        BCC +                   ;
        SBC #$03                ;
        INX                     ;
        BNE -                   ;
*       TXA                     ;
        ASL                     ;
        STA Damage              ;
        RTS                     ;

;--------------------------------------[What the list covers]----------------------------------------

;In a battle the list window covers the scene, its band characters: kept
;here (SaveUnder) and put back (RestoreUnder, by CloseList).
.alias UnderBuf         $0660   ;22 by up to 12.

SaveUnder:
        LDX #$00                ;
        BEQ UnderRows           ;
RestoreUnder:
        LDX #$80                ;
UnderRows:
        STX ShopTmpN            ;Bit 7: put back.
        LDA ListCount           ;Its rows: the list's and the frame's.
        CLC                     ;
        ADC #$02                ;
        STA Rows                ;
        LDA #LIST_ROW           ;
        STA WinRow              ;
        LDA #<UnderBuf          ;
        STA NamePtr             ;
        LDA #>UnderBuf          ;
        STA NamePtr+1           ;
UnderRow:
        LDA #LIST_COL           ;
        STA WinCol              ;
        LDY #$00                ;
*       BIT ShopTmpN            ;
        BMI +                   ;
        JSR GetChar             ;
        STA (NamePtr),Y         ;
        JMP ++                  ;
*       LDA (NamePtr),Y         ;
        JSR PutChar             ;
*       INC WinCol              ;
        INY                     ;
        CPY #LIST_RIGHT-LIST_COL+1 ;
        BNE ---                 ;
        TYA                     ;
        CLC                     ;
        ADC NamePtr             ;
        STA NamePtr             ;
        BCC +                   ;
        INC NamePtr+1           ;
*       INC WinRow              ;
        DEC Rows                ;
        BNE UnderRow            ;
        RTS                     ;

;--------------------------------------[ITEM in a battle]--------------------------------------------

.alias FLUTE_ITEM       ITM_BASE+$05 ;The items with a use in a battle (PlyrItem):
.alias HARP_ITEM        ITM_BASE+$0A ;the fairy flute, the silver harp.
.alias MSC_FLUTE        $12     ;
.alias MSC_HARP         $11     ;
.alias MSC_REG_FIGHT    $18     ;
.alias EN_GOLEM         $18     ;

;ITEM in a battle: the hero's goods in the list window (what it covers
;kept, as SPELL's), or nothing to use.
BattleItem:
        JSR GoodsList           ;
        LDA ListCount           ;
        BNE +                   ;
        LDA #$3D                ;Nothing of use.
        LDX #B_ROUND            ;
        JMP Say                 ;
*       JSR SaveUnder           ;
        LDA #$01                ;
        STA ListKind            ;
        LDX #IT_BATTLE          ;
        JMP OpenList            ;

;The item chosen: none, the command again; the herb heals; the flute
;plays (the golem falls asleep, else nothing); the harp plays (the enemy
;is pleased); the dragon's scale as on the map; anything else cannot be
;used here.
StepItBattle:
        LDA #$00                ;
        STA ShopState           ;
        JSR ChosenItem          ;
        BCC +                   ;
        JMP StepCommand         ;
*       STA ItemName            ;
        CMP #HERB_ITEM          ;
        BNE +                   ;
        DEC Herbs               ;
        JSR HerbHeal            ;
        LDA #$F7                ;The herb used.
        LDX #B_ENEMY            ;
        JMP Say                 ;
*       LDX #MSC_FLUTE          ;
        LDY #$3C                ;The flute blown,
        CMP #FLUTE_ITEM         ;
        BEQ +                   ;
        LDX #MSC_HARP           ;
        LDY #$41                ;or the harp played.
        CMP #HARP_ITEM          ;
        BNE ++                  ;
*       TXA                     ;
        JSR PlayMusic           ;
        TYA                     ;
        LDX #B_TUNE             ;
        JMP Say                 ;
*       CMP #SCALE_ITEM         ;
        BNE +                   ;
        JSR WearScale           ;
        LDX #B_ENEMY            ;
        JMP Say                 ;
*       LDA #$E9                ;Not usable here.
        LDX #B_ROUND            ;
        JMP Say                 ;

;The tune's message is out: the fight's music again; the flute puts the
;golem to sleep, else nothing; the harp pleases the enemy.
StepTune:
        LDA #MSC_REG_FIGHT      ;
        JSR PlayMusic           ;
        LDA ItemName            ;
        CMP #HARP_ITEM          ;
        BNE +                   ;
        LDA #$F4                ;The enemy looks happy.
        LDX #B_ENEMY            ;
        JMP Say                 ;
*       LDA Enemy               ;
        CMP #EN_GOLEM           ;
        BEQ +                   ;
        LDA #$33                ;Nothing happens.
        LDX #B_ENEMY            ;
        JMP Say                 ;
*       LDA #$01                ;
        STA EnSleep             ;
        LDA #$F3                ;The golem falls asleep.
        LDX #B_ENASLEEP         ;
        JMP Say                 ;
