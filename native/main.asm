;Dragon Warrior, native Atari 5200 engine.
;
;Everything shown is finished at build time (tools/native/convert.py): map
;blocks are mode 4 characters with their colors chosen, the overworld and
;the towns are block numbers (the overworld's water shores worked out), the
;hero and the townspeople are player data, the text is the game's own. The
;engine only copies and scrolls.
;
;The cartridge is a 512KB SuperCart (atari800 type 74): 16 banks of 32KB at
;$4000-$BFFF. Each bank's first half ($4000-$7FFF) is this program, the
;same in all of them; the second half holds data: the overworld in bank 0,
;the text in bank 1, the towns in bank 2, each map's character sets and
;tables in bank 3, the cartridge header in bank 15, which the cartridge
;starts in.
;
;The screen is a ring of 32 character rows of 128 bytes ($1000-$1FFF): 16
;block rows of 2 character rows, 32 block columns of 2 characters, each
;column written twice (at c and c+64) so that the 40 bytes ANTIC fetches
;for a horizontally scrolled row never run off the end. The display list
;points each of its rows at the ring with the coarse scroll; HSCROL and
;VSCROL do the rest. Walking a block draws the one row or column of blocks
;coming into view, then scrolls the view 16 frames: a line a frame up or
;down, a color clock every other frame sideways (a block is 8 color clocks
;wide, as an NES block is 16 pixels).
;
;Windows (windows.asm, text.asm) are drawn into the ring where the view
;is: they only open while the hero stands, and closing one draws the map
;blocks beneath again. Townspeople (people.asm) are players 2 and 3, moved
;and colored by display list interrupts row by row.

.include "hw5200.asm"
.include "profile.asm"
.include "config.asm"

;--------------------------------------[Memory]------------------------------------------------------

.alias Screen           $1000   ;The ring: 32 rows of 128 bytes.
.alias DList            $0300   ;Display list.
.alias PMMemory         $0800   ;Player/missile memory (single-line):
.alias Player0          $0C00   ;players 0-3 at $0C00-$0FFF.
.alias Player1          $0D00   ;
.alias Player2          $0E00   ;
.alias Player3          $0F00   ;
.alias ProfStart        $02E8   ;Profile builds: the sound's time (line pairs):
.alias ProfMax          $02E9   ;the most in a frame,
.alias ProfSum          $02EA   ;2: the sum,
.alias ProfFrames       $02EC   ;2: over these frames.
.alias RowIsOff         $03D0   ;DrawRowPart: bit 7, its row is off the map.
.alias ColValid         $03D1   ;DrawColumn: MapPtr holds the row above's,
.alias ColStride        $03D3   ;and the rows' stride.
.alias PotX             $02E6   ;The stick's pots, as the VBI finds them.
.alias PotY             $02E7   ;
.alias RowBase          $03D2   ;A town's map: its page's high byte (MapBankIn).
.alias MapRec           $0770   ;16: the map's record (LoadMapRec, from MAP_RECS):
.alias MapImageBank     $0770   ;its image's bank and page,
.alias MapImageHi       $0771   ;
.alias MapSize          $0772   ;width, height,
.alias MapHeight        $0773   ;
.alias MapDark          $0774   ;dark,
.alias MapBorder        $0775   ;the block off its edges,
.alias MapEnemies       $0776   ;its enemies' row ($FF: none),
.alias MapTownBank      $0777   ;its page in the town banks,
.alias MapTownHi        $0778   ;
.alias MapMusic         $0779   ;its music,
.alias PeopleFirst      $077A   ;its people (the first, how many),
.alias PeopleCount      $077B   ;
.alias OutsideMap       $077C   ;where OUTSIDE takes the hero,
.alias OutsideX         $077D   ;
.alias OutsideY         $077E   ;
.alias MapFreeCode      $077F   ;its first free character code.
.alias RowSub           $07AB   ;2: WorldRow's Y * 8.
.alias Key              $07C1   ;The keypad key held (0: none),
.alias LastKey          $07C2   ;last frame's,
.alias KeyNew           $07C3   ;and the one just pressed (0: none).
.alias Paused           $07C4   ;Non-zero: the keypad's Pause holds the game.
.alias DlgVCount        $07C5   ;VCOUNT on the line above the dialog window.
.alias KEY_PAUSE        $08     ;Keypad codes (KBCODE bits 1-4).
.alias KEY_START        $0C     ;
.alias GreyTime         $07BD   ;Frames the screen is grey (the drop made),
.alias FadeSub          $07BE   ;and luminance taken from the colors (a fade).
.alias BridgeY          $03D4   ;The rainbow bridge's row while it is shown ($FF: not).
.alias BridgeRow        $0B60   ;120: that row with the bridge (after the templates).
.alias TownMap          $2C00   ;A town's map while the hero is in it (1KB:
                                ;the battle sets' RAM, as towns have no
                                ;battles).
.alias ProfT            $03A0   ;Profile builds: each main loop phase's start,
.alias ProfPMax         $03A8   ;the most it took,
.alias ProfPSumLo       $03B0   ;its sum,
.alias ProfPSumHi       $03B8   ;
.alias ProfPCntLo       $03C0   ;over this many times (8 phases: build.py).
.alias ProfPCntHi       $03C8   ;
.alias HeroGfx          $3B00   ;The hero's frames and the townspeople's
.alias PeopleGfx        $3C00   ;(1KB), copied from GFX_BANK at power on.
.alias GFX_BANK         7       ;
.alias TextA            $0800   ;Then (build.py) each text tile's character in
.alias TextB            $0900   ;set A (0: not there) and in set B, and the
.alias CommandTemplate  $0A00   ;windows' tiles (missile memory, unused):
.alias BattleCmdTemplate $0AA0  ;16 by 10, 16 by 6
.alias StatusTemplate   $0B00   ;and 8 by 12,
.alias PersonColors     $0BE0   ;8: each townsperson graphic's color.
.alias MapImage         $2000   ;The map's image (convert.py's map_image):
.alias CharsetA         $2000   ;its blocks' characters and the window text,
.alias CharsetB         $2400   ;every text tile (the dialog window's rows),
.alias BlockUL          $2800   ;each block's characters,
.alias BlockUR          $2828   ;
.alias BlockLL          $2850   ;
.alias BlockLR          $2878   ;
.alias BlockWall        $28A0   ;whether it can be walked onto,
.alias MapColors        $28C8   ;and COLPF0-3, COLBK.
.alias World            $8000   ;The overworld, in MAP_BANK,
.alias TEXT_BASE        $8000   ;the text, in TEXT_BANK,
.alias TOWN_BASE        $8000   ;the towns (1KB each, rows 32 apart), in TOWN_BANK,
.alias IMAGES_BASE      $8000   ;and each map's image, in IMAGES_BANK.
.alias MAP_BANK         0       ;
.alias TEXT_BANK        1       ;
.alias TOWN_BANK        2       ;
.alias IMAGES_BANK      3       ;
.alias IMAGES2_BANK     9       ;(The maps' images past the 7 IMAGES_BANK holds,
.alias IMAGES3_BANK     11      ;and past 14, past 21;
.alias IMAGES4_BANK     14      ;
.alias TOWN2_BANK       12      ;the map pages past the 15 TOWN_BANK holds.)
.alias MONSTER_DARK_BANK 13     ;The monsters on black (the caves' battles).

.alias DL_ROWS          29      ;Display list rows: 28 shown, one more for VSCROL.
.alias DLG_FIRST        18      ;The dialog window's first row.
.alias HERO_LINE        128     ;The hero's top line in player memory,
.alias HERO_HPOS        128     ;and its horizontal position: block 8 of the view.
.alias FIRST_LINE       16      ;The first scan line shown.

.alias BTN_A            $01     ;Buttons: the lower fire button,
.alias BTN_B            $02     ;the upper.

;Zero page.
.alias Ptr              $80     ;2: drawing pointer.
.alias MapPtr           $82     ;2: map row pointer.
.alias FrameCount       $84     ;Counted by the VBI.
.alias LastFrame        $85     ;The main loop's last frame.
.alias HeroX            $86     ;The hero's block.
.alias HeroY            $87     ;
.alias LeftBlock        $88     ;The view's top left block (mod 256: may be
.alias TopBlock         $89     ;off the map, which shows its border).
.alias FineX            $8A     ;0-8 color clocks into LeftBlock,
.alias FineY            $8B     ;0-16 lines into TopBlock.
.alias Facing           $8C     ;0 up, 1 right, 2 down, 3 left.
.alias Moving           $8D     ;Frames left in a step, 0 standing.
.alias Shown            $8E     ;Hero frame shown, $FF none.
.alias BX               $8F     ;Block being drawn.
.alias BY               $90     ;
.alias Count            $91     ;
.alias Tmp              $92     ;
.alias Stick            $93     ;Directions held: bit 0 up, 1 right, 2 down, 3 left.
.alias ShRow            $94     ;For the VBI: first ring row shown,
.alias ShCol            $95     ;first ring column,
.alias ShH              $96     ;HSCROL,
.alias ShV              $97     ;VSCROL.
.alias RouteAt          $98     ;Scripted input: entry,
.alias RouteLeft        $99     ;and steps or frames left in it.
.alias Steps            $9A     ;2: steps taken.
.alias WalkFrames       $9C     ;2: frames spent walking.
.alias Missed           $9E     ;2: frames the main loop missed.
.alias Blocked          $A0     ;Steps refused by a wall or a townsperson.
.alias Rows             $A1     ;
.alias FrameHi          $A2     ;FrameCount's upper byte.
.alias IsParked         $A3     ;Non-zero: parked (scripted builds).
.alias CurBank          $A4     ;SuperCart bank in place.
.alias Buttons          $A5     ;Buttons held,
.alias Pressed          $A6     ;and pressed this frame.
.alias LastButtons      $A7     ;
.alias StickNew         $A8     ;Directions newly held this frame.
.alias LastStick        $A9     ;
.alias Mode             $AA     ;0 walking, 1 command window, 2 dialog, 3 battle,
                                ;4 a shop, an inn or ITEM (shop.asm), 5 STATUS, 6 a password.
.alias StandTime        $AB     ;Frames standing, to $FF.
.alias StatusOn         $AC     ;Non-zero: the status window is shown.
.alias DialogOn         $AD     ;Non-zero: the dialog window is shown.
.alias WinRow           $AE     ;Screen row and column for PutChar.
.alias WinCol           $AF     ;
.alias Cursor           $B0     ;Command window choice, 0-7.
.alias NumLo            $B1     ;Number for PrintNumber.
.alias NumHi            $B2     ;
.alias Digit            $B3     ;
.alias Lead             $B4     ;
.alias TextPtr          $B5     ;2: next text byte, in TEXT_BANK.
.alias TCol             $B7     ;Dialog: next column and line,
.alias TRow             $B8     ;
.alias DlgState         $B9     ;0 printing, 1 waiting for a press, 2 done.
.alias MsgList          $BA     ;2: the messages still to show.
.alias Insert           $BC     ;Name letters printed so far, $FF none.
.alias Tmp2             $BD     ;
.alias Tmp3             $BE     ;
.alias PcChar           $BF     ;PutChar's character,
.alias PcY              $C0     ;and Y.
.alias NameLen          $C1     ;Letters in the name, before its blanks.
.alias MapId            $C2     ;0 the overworld, then the towns (maps.TOWNS).
.alias MapSz            $C3     ;Its width in blocks,
.alias MapHt            $74     ;and its height.
.alias Dark             $75     ;Non-zero: a dark map (a dungeon),
.alias LightR           $76     ;its light's reach round the hero (0: its block),
.alias LightW           $77     ;and width (2 * LightR + 1).
.alias RowLit           $78     ;DrawRowPart: bit 7, the row is in the light.
.alias DARK_BLOCK       39      ;A block all black (the game has 39).
.alias Loading          $C4     ;Non-zero: a map is loading (the screen off).
.alias StepDone         $C5     ;Non-zero: a step has just ended.
.alias Random           $C6     ;2: random number.
.alias DliRow           $C8     ;The display row the next DLI changes.
.alias PeopleOn         $C9     ;Townspeople on this map.
.alias VbiTmp           $CA     ;The VBI's own temporary.
.alias Amount           $CB     ;2: the amount a message shows.
.alias InsertLen        $CD     ;Letters to insert (name or number).
.alias Answer           $CE     ;YES/NO: 0 yes, 1 no.
.alias YesNoOn          $CF     ;Non-zero: the YES/NO window is shown.
.alias MsgLo            $F1     ;The message being started (NextMessage).
.alias MsgHi            $F2     ;
.alias InsertBuf        $0290   ;16: the letters being inserted.
.alias CmdDownMax       $0281   ;The command cursor goes down below this.
.alias VScrolNow        $0282   ;VSCROL as the VBI set it, this frame.

;Game state.
.alias HeroName         $0240   ;8: the name, in text tiles.
.alias Level            $0248   ;
.alias HitPoints        $0249   ;
.alias MagicPoints      $024A   ;
.alias Gold             $024B   ;2
.alias Experience       $024D   ;2
.alias MaxHP            $024F   ;
.alias MaxMP            $0250   ;
.alias Strength         $0251   ;
.alias Agility          $0252   ;

;--------------------------------------[Program]-----------------------------------------------------

.org $4000

Start:
        SEI                     ;
        CLD                     ;
        LDX #$FF                ;
        TXS                     ;
        LDA #$00                ;Display off while setting up.
        STA NMIEN               ;
        STA DMACTL              ;
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
        STA HPOSP0              ;
        STA HPOSP1              ;
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
        LDA #GFX_BANK           ;The hero's and the people's graphics to
        JSR SelectBank          ;RAM: 5 pages, then the tables: 4 at TextA.
        LDY #$00                ;
        LDX #$05                ;
        STY Ptr                 ;
        STY MapPtr              ;
        LDA #>HeroGfx           ;
        STA Ptr+1               ;
        LDA #$80                ;
        STA MapPtr+1            ;
BootCopy:
        LDA (MapPtr),Y          ;
        STA (Ptr),Y             ;
        INY                     ;
        BNE BootCopy            ;
        INC MapPtr+1            ;
        INC Ptr+1               ;
        DEX                     ;
        BNE BootCopy            ;
        LDA Ptr+1               ;
        CMP #>[TextA+$400]      ;
        BEQ BootCopied          ;
        LDA #>TextA             ;
        STA Ptr+1               ;
        LDX #$04                ;
        BNE BootCopy            ;
BootCopied:
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

        LDA #START_X            ;
        STA HeroX               ;
        LDA #START_Y            ;
        STA HeroY               ;
        LDA #START_MAP          ;The overworld (but in some test builds).
        JSR LoadMap             ;
        LDA #$06                ;The first frame: a password asked for?
        STA Mode                ;(password.asm.)

        LDA #$C0                ;Vertical blank and display list interrupts.
        STA NMIEN               ;
        CLI                     ;
        LDA FrameCount          ;
        STA LastFrame           ;

;--------------------------------------[Main loop]---------------------------------------------------

MainLoop:
*       LDA FrameCount          ;A frame at a time.
        CMP LastFrame           ;
        BEQ -                   ;
        SEC                     ;
        SBC LastFrame           ;More than one: the loop was late.
        CMP #$02                ;
        BCC +                   ;
        SBC #$01                ;
        CLC                     ;
        ADC Missed              ;
        STA Missed              ;
        BCC +                   ;
        INC Missed+1            ;
*       LDA FrameCount          ;
        STA LastFrame           ;
        `prof_begin 0
        JSR NextRandom          ;

        JSR ReadInput           ;
        LDA Buttons             ;Presses and new directions.
        TAX                     ;
        EOR LastButtons         ;
        AND Buttons             ;
        STA Pressed             ;
        STX LastButtons         ;
        LDA Stick               ;
        TAX                     ;
        EOR LastStick           ;
        AND Stick               ;
        STA StickNew            ;
        STX LastStick           ;
        LDX Key                 ;A keypad key just pressed (KeyNew; 0:
        CPX LastKey             ;none).
        BNE +                   ;
        LDX #$00                ;
*       STX KeyNew              ;
        LDA Key                 ;
        STA LastKey             ;

        LDA Mode                ;
        BEQ Walk                ;
        CMP #$01                ;
        BNE +                   ;
        JSR CommandFrame        ;
        JMP Frame               ;
*       CMP #$03                ;
        BNE +                   ;
        JSR BattleFrame         ;
        JMP Frame               ;
*       CMP #$04                ;
        BNE +                   ;
        JSR ShopFrame           ;
        JMP Frame               ;
*       CMP #$05                ;
        BNE +                   ;
        JSR StatusFrame         ;
        JMP Frame               ;
*       CMP #$06                ;
        BNE +                   ;
        JSR PowerOn             ;
        LDA Mode                ;(None asked for: walking, this frame.)
        BEQ Walk                ;
        JMP Frame               ;
*       JSR DialogFrame         ;
        JMP Frame               ;

Walk:
        LDA KeyNew              ;The keypad's Pause: everything held until
        CMP #KEY_PAUSE          ;it is pressed again (the NES's Start).
        BNE +                   ;
        LDA Paused              ;
        EOR #$01                ;
        STA Paused              ;
*       LDA Paused              ;
        BEQ +                   ;
        JMP Frame               ;
*       `prof_begin 1
        JSR MovePeople          ;
        `prof_end 1
        LDA Moving              ;Standing: a new step starts, and moves, in
        BNE Step                ;this frame, so steps follow each other
        LDX KeyNew              ;without a pause. Keys 1-8 do a command at
        LDA KeyCommand,X        ;once (KeyCommand); the lower fire button
        BMI +                   ;opens the command window.
        STA Cursor              ;
        LDA #$01                ;
        STA Mode                ;
        JSR DoCommand           ;
        JMP Frame               ;
*       LDA Pressed             ;
        AND #BTN_A              ;
        BEQ +                   ;
        JSR HideForCommand      ;
        JSR OpenCommand         ;
        JMP Frame               ;
*       LDA Stick               ;
        BEQ Stand               ;
        JSR HideStatus          ;
        `prof_begin 5
        JSR StartStep           ;
        `prof_end 5
        LDA Moving              ;
        BEQ Frame               ;
Step:
        `prof_begin 2
        JSR StepFrame           ;
        `prof_end 2
        LDA #$00                ;
        STA StandTime           ;
        INC WalkFrames          ;
        BNE +                   ;
        INC WalkFrames+1        ;
*       LDA StepDone            ;At the step's end: into a town, or out.
        BEQ Frame               ;
        LDA #$00                ;
        STA StepDone            ;
        JSR StepTimers          ;(A message up: no more this step.)
        BCS +                   ;
        JSR CheckDoor           ;
        JSR EndTrigger          ;(The ending: nothing more.)
        BCS +                   ;
        JSR CursedGate          ;(Turned out: nothing more.)
        BCS +                   ;
        JSR ArmorHeal           ;
        JSR GroundHurt          ;(Dead of it: no fight.)
        BCS +                   ;
        JSR GuardianFight       ;(A guardian's: no other.)
        BCS +                   ;
        JSR CheckEncounter      ;
*       JMP Frame               ;
Stand:
        LDA StandTime           ;The status window, once the hero has
        CMP #$FF                ;stood half a second.
        BEQ Frame               ;
        INC StandTime           ;
        CMP #STATUS_DELAY       ;
        BNE Frame               ;
        LDA #$01                ;The people under it gone first (StatusOn
        STA StatusOn            ;set for DrawPeople's look), then the window
        JSR DrawPeople          ;drawn: else for that frame they could show
        LDA #$00                ;over it. (ShowStatus draws only if it is
        STA StatusOn            ;not up yet.)
        JSR ShowStatus          ;
Frame:
        `prof_begin 4
        JSR ShowHero            ;
        JSR SetScroll           ;
        `prof_end 4
        `prof_begin 3
        JSR DrawPeople          ;
        `prof_end 3
        `prof_end 0
        JMP MainLoop            ;

;The command window (and the status window with it) about to open: the
;people under them gone first (DrawPeople, as if both were up), StatusOn
;as it was after, so that ShowStatus still draws it if it was not up.
HideForCommand:
        LDA StatusOn            ;
        PHA                     ;
        LDA #$01                ;
        STA StatusOn            ;
        STA Mode                ;
        JSR DrawPeople          ;
        PLA                     ;
        STA StatusOn            ;
        RTS                     ;

;A new random number (a 16-bit Galois LFSR).
NextRandom:
        LSR Random+1            ;
        ROR Random              ;
        BCC +                   ;
        LDA Random+1            ;
        EOR #$B4                ;
        STA Random+1            ;
*       RTS                     ;

;--------------------------------------[Maps]--------------------------------------------------------

;Load map A with the hero at (HeroX, HeroY): its image to RAM (the screen
;off meanwhile), its people, and the view around the hero.
LoadMap:
        STA MapId               ;
        JSR LoadMapRec          ;
        JSR SetBridge           ;
        JSR SetLordGfx          ;
        JSR PlayMapMusic        ;
        JSR ResetTiles          ;
        LDA #$01                ;
        STA Loading             ;
        LDA #$00                ;
        STA DMACTL              ;
        STA Moving              ;
        STA StatusOn            ;No windows on the new map.
        STA DialogOn            ;
        STA YesNoOn             ;
        STA StandTime           ;
        STA Mode                ;
        STA FineX               ;
        STA FineY               ;
        LDX MapId               ;Its image's bank.
        LDA MapImageBank        ;
        JSR SelectBank          ;
        LDX MapId               ;
        LDA MapImageHi          ;
        STA MapPtr+1            ;
        LDA MapSize             ;
        STA MapSz               ;
        LDA MapHeight           ;
        STA MapHt               ;
        LDA MapDark             ;Dark, the light at the hero's block only.
        STA Dark                ;
        LDA #$00                ;
        STA LightR              ;
        LDA #$01                ;
        STA LightW              ;
        LDA #$00                ;
        STA MapPtr              ;
        STA Ptr                 ;
        LDA #>MapImage          ;
        STA Ptr+1               ;
        LDX #IMAGE_PAGES        ;
        LDY #$00                ;
*       LDA (MapPtr),Y          ;
        STA (Ptr),Y             ;
        INY                     ;
        BNE -                   ;
        INC MapPtr+1            ;
        INC Ptr+1               ;
        DEX                     ;
        BNE -                   ;
        JSR NameGlyphs          ;
        LDA HeroX               ;
        SEC                     ;
        SBC #$08                ;
        STA LeftBlock           ;
        LDA HeroY               ;
        SEC                     ;
        SBC #$07                ;
        STA TopBlock            ;
        JSR CopyTown            ;A town: its map to RAM (doors open there).
        JSR HidePassage         ;
        JSR HidePrincess        ;
        JSR LoadPeople          ;
        JSR DLIBits             ;
        JSR DrawView            ;
        JSR SetScroll           ;
        LDA #$00                ;
        STA Loading             ;
        LDA FrameCount          ;The frames loading took are not missed.
        STA LastFrame           ;
        RTS                     ;

;At a step's end: on the overworld, onto a town's door block, into it; in
;a town, off its edges, out to its door on the overworld.
CheckDoor:
        LDA MapId               ;
        BNE OutOfTown           ;
        JSR FindLinkFrom        ;The overworld: a link from here (a town's,
        BCS +                   ;a castle's door).
        RTS                     ;
*       LDA LinkFacing,X        ;
        JMP GoLinkTo            ;
OutOfTown:
        LDA HeroX               ;Off a map's edge: back where the first link
        CMP MapSz               ;into it starts, facing down (the game's
        BCS LeaveMap            ;CheckMapExit).
        LDA HeroY               ;
        CMP MapHt               ;
        BCS LeaveMap            ;
        RTS                     ;
LeaveMap:
        JSR LinksIn             ;
        LDX #$00                ;(Out by the first link into the map, as
        LDA MapId               ;CheckMapExit searches: Tantegel has two,
*       CMP LinkToMap,X         ;the overworld's first, then the throne
        BEQ +                   ;room's stairs.)
        INX                     ;
        CPX #NUM_LINKS          ;
        BNE -                   ;
        JMP MapBankIn           ;
*       LDA #$02                ;
        JMP GoLinkFrom          ;

;MapRec = map MapId's record (MAP_RECS, in MSG_BANK).
LoadMapRec:
        LDA #$00                ;Its place: MapId * 16.
        STA SrcPtr+1            ;
        LDA MapId               ;
        ASL                     ;
        ASL                     ;
        ASL                     ;
        ASL                     ;
        ROL SrcPtr+1            ;
        CLC                     ;
        ADC #<MAP_RECS          ;
        STA SrcPtr              ;
        LDA SrcPtr+1            ;
        ADC #>MAP_RECS          ;
        STA SrcPtr+1            ;
        LDA #MSG_BANK           ;
        JSR SelectBank          ;
        LDY #15                 ;
*       LDA (SrcPtr),Y          ;
        STA MapRec,Y            ;
        DEY                     ;
        BPL -                   ;
        RTS                     ;

;The links' bank in (MSG_BANK; X lost). Found, GoLinkTo or GoLinkFrom
;reads them so; not found, the map's bank back (LinksOut).
LinksIn:
        LDA #MSG_BANK           ;
        JMP SelectBank          ;
LinksOut:
        JSR MapBankIn           ;
        CLC                     ;
        RTS                     ;

;X = the map link from the hero's block (C set), or C clear.
FindLinkFrom:
        JSR LinksIn             ;
        LDX #NUM_LINKS-1        ;
*       LDA LinkFromMap,X       ;
        CMP MapId               ;
        BNE +                   ;
        LDA LinkFromX,X         ;
        CMP HeroX               ;
        BNE +                   ;
        LDA LinkFromY,X         ;
        CMP HeroY               ;
        BNE +                   ;
        SEC                     ;
        RTS                     ;
*       DEX                     ;
        BPL --                  ;
        JMP LinksOut            ;

;X = the map link to the hero's block (C set), or C clear.
FindLinkTo:
        JSR LinksIn             ;
        LDX #NUM_LINKS-1        ;
*       LDA LinkToMap,X         ;
        CMP MapId               ;
        BNE +                   ;
        LDA LinkToX,X           ;
        CMP HeroX               ;
        BNE +                   ;
        LDA LinkToY,X           ;
        CMP HeroY               ;
        BNE +                   ;
        SEC                     ;
        RTS                     ;
*       DEX                     ;
        BPL --                  ;
        JMP LinksOut            ;

;Follow link X to its end (GoLinkTo) or back to its start (GoLinkFrom),
;facing A.
GoLinkTo:
        STA Facing              ;
        LDA LinkToX,X           ;
        STA HeroX               ;
        LDA LinkToY,X           ;
        STA HeroY               ;
        LDA LinkToMap,X         ;
        JMP LoadMap             ;
GoLinkFrom:
        STA Facing              ;
        LDA LinkFromX,X         ;
        STA HeroX               ;
        LDA LinkFromY,X         ;
        STA HeroY               ;
        LDA LinkFromMap,X       ;
        JMP LoadMap             ;

;--------------------------------------[Walking]-----------------------------------------------------

;Start a step in the first direction held (up, right, down, left), unless a
;wall or a townsperson is there: then just face it.
StartStep:
        LDX #$00                ;
        LDA Stick               ;
*       LSR                     ;
        BCS +                   ;
        INX                     ;
        BNE -                   ;
*       STX Facing              ;
        LDA HeroX               ;The block ahead.
        CLC                     ;
        ADC DirX,X              ;
        STA BX                  ;
        LDA HeroY               ;
        CLC                     ;
        ADC DirY,X              ;
        STA BY                  ;
        JSR GetBlock            ;
        TAY                     ;
        LDA BlockWall,Y         ;
        BNE +                   ;
        JSR PersonAt            ;
        BCC ++                  ;
*       INC Blocked             ;
        LDA #SFX_WALL           ;
        JMP PlaySFX             ;
*       LDA BX                  ;
        STA HeroX               ;
        LDA BY                  ;
        STA HeroY               ;
        LDA #16                 ;
        STA Moving              ;
        LDX Facing              ;
        BEQ StepUp              ;
        DEX                     ;
        BEQ StepRight           ;
        DEX                     ;
        BEQ StepDown            ;
StepLeft:
        DEC LeftBlock           ;The new left column comes into view; the
        LDA #$08                ;view starts a block right of it.
        STA FineX               ;
        LDA LeftBlock           ;
        JSR DrawColumn          ;
        JMP RedrawLight         ;
StepRight:
        LDA LeftBlock           ;The column after the view's right edge.
        CLC                     ;
        ADC #17                 ;
        JSR DrawColumn          ;
        JMP RedrawLight         ;
StepUp:
        DEC TopBlock            ;
        LDA #16                 ;
        STA FineY               ;
        LDA TopBlock            ;
        JSR DrawRow             ;
        JMP RedrawLight         ;
StepDown:
        LDA TopBlock            ;The row after the view's bottom edge.
        CLC                     ;
        ADC #15                 ;
        JSR DrawRow             ;
        JMP RedrawLight         ;

;One frame of a step: a line up or down, or every other frame a color
;clock sideways.
StepFrame:
        LDX Facing              ;
        BEQ FrameUp             ;
        DEX                     ;
        BEQ FrameRight          ;
        DEX                     ;
        BEQ FrameDown           ;
FrameLeft:
        LDA Moving              ;
        LSR                     ;
        BCC +                   ;
        DEC FineX               ;
        JMP StepCount           ;
FrameRight:
        LDA Moving              ;
        LSR                     ;
        BCC +                   ;
        INC FineX               ;
        LDA FineX               ;
        CMP #$08                ;
        BNE +                   ;
        LDA #$00                ;
        STA FineX               ;
        INC LeftBlock           ;
*       JMP StepCount           ;
FrameUp:
        DEC FineY               ;
        JMP StepCount           ;
FrameDown:
        INC FineY               ;
        LDA FineY               ;
        CMP #16                 ;
        BNE StepCount           ;
        LDA #$00                ;
        STA FineY               ;
        INC TopBlock            ;
StepCount:
        DEC Moving              ;
        BNE +                   ;
        INC StepDone            ;
        INC Steps               ;
        BNE +                   ;
        INC Steps+1             ;
*       RTS                     ;

DirX:   .byte $00, $01, $00, $FF
DirY:   .byte $FF, $00, $01, $00

;--------------------------------------[Hero]--------------------------------------------------------

;Show the hero's frame: its facing and, as the game does, a step of its
;walk every 16 frames.
ShowHero:
        LDA Facing              ;
        ASL                     ;
        STA Tmp                 ;
        LDA FrameCount          ;
        AND #$10                ;
        BEQ +                   ;
        INC Tmp                 ;
*       LDA Tmp                 ;
        CMP Shown               ;
        BEQ ShowDone            ;
        STA Shown               ;
        ASL                     ;Frame * 32: 16 bytes for each player.
        ASL                     ;
        ASL                     ;
        ASL                     ;
        ASL                     ;
        TAX                     ;
        LDY #$00                ;
*       LDA HeroGfx,X           ;
        STA Player0+HERO_LINE,Y ;
        LDA HeroGfx+16,X        ;
        STA Player1+HERO_LINE,Y ;
        INX                     ;
        INY                     ;
        CPY #16                 ;
        BNE -                   ;
ShowDone:
        RTS                     ;

;--------------------------------------[Controller]--------------------------------------------------

.include "input.asm"

;Scripted builds stop here, for run5200.py to find. The VBI then returns
;at once: the emulator stops just after a frame starts, and must find the
;program here, not in the VBI.
Parked:
        LDA #$01                ;
        STA IsParked            ;
*       JMP -                   ;

;--------------------------------------[Map blocks]--------------------------------------------------

;Put SuperCart bank A in place (the first half, this program, is the same
;in every bank): reading $BFC0 + (bank AND $0C) sets its upper 2 bits,
;$BFD0 + (bank AND 3) * 4 its lower 2.
SelectBank:
        CMP CurBank             ;
        BEQ +                   ;
        STA CurBank             ;
        AND #$0C                ;
        TAX                     ;
        LDA SuperCartHi,X       ;
        LDA CurBank             ;
        AND #$03                ;
        ASL                     ;
        ASL                     ;
        TAX                     ;
        LDA SuperCartLo,X       ;
*       RTS                     ;

;A = the block at (BX, BY): the map's border off its edges. X is kept.
GetBlock:
        STX Tmp3                ;
        LDA BX                  ;
        CMP MapSz               ;
        BCS GetBorder           ;
        LDA BY                  ;
        CMP MapHt               ;
        BCS GetBorder           ;
        LDA MapId               ;
        BNE GetTown             ;
        JSR SelectBank          ;The overworld (A = MAP_BANK, 0).
        LDY BY                  ;
        JSR WorldRow            ;
        JMP GetFromRow          ;
GetTown:
        LDA BY                  ;A town: its copy in RAM, TownMap + BY * 32.
        LSR                     ;
        LSR                     ;
        LSR                     ;
        CLC                     ;
        ADC #>TownMap           ;
        STA MapPtr+1            ;
        LDA BY                  ;
        ASL                     ;
        ASL                     ;
        ASL                     ;
        ASL                     ;
        ASL                     ;
        STA MapPtr              ;
GetFromRow:
        LDY BX                  ;
        LDA (MapPtr),Y          ;
        LDX Tmp3                ;
        RTS                     ;
GetBorder:
        LDX MapId               ;
        LDA MapBorder           ;
        LDX Tmp3                ;
        RTS                     ;

;MapPtr = map row BY's start (its bank in), as GetBlock finds it; C set if
;BY is off the map (its blocks the border).
RowPointer:
        JSR MapBankIn           ;
;The same, the map's bank already in (MapBankIn).
RowAddr:
        LDA BY                  ;
        CMP MapHt               ;
        BCS RowOff              ;
        LDA MapId               ;
        BNE RowTown             ;
        LDY BY                  ;The overworld: its row table.
        JSR WorldRow            ;
        CLC                     ;
RowOff:
        RTS                     ;

;MapPtr = overworld row Y: World + Y * 120 (Y * 128 - Y * 8: the rows
;are WORLD_SIZE apart), or the bridge's row in RAM (BridgeRow) once the
;rainbow bridge is built (BridgeY: its row). Y kept.
WorldRow:
        CPY BridgeY             ;
        BEQ +                   ;
        TYA                     ;Y * 128.
        LSR                     ;
        STA MapPtr+1            ;
        LDA #$00                ;
        ROR                     ;
        STA MapPtr              ;
        TYA                     ;Less Y * 8.
        ASL                     ;
        ASL                     ;
        ASL                     ;
        STA RowSub              ;
        TYA                     ;
        LSR                     ;
        LSR                     ;
        LSR                     ;
        LSR                     ;
        LSR                     ;
        STA RowSub+1            ;
        LDA MapPtr              ;
        SEC                     ;
        SBC RowSub              ;
        STA MapPtr              ;
        LDA MapPtr+1            ;
        SBC RowSub+1            ;
        CLC                     ;
        ADC #>World             ;
        STA MapPtr+1            ;
        RTS                     ;
*       LDA #<BridgeRow         ;
        STA MapPtr              ;
        LDA #>BridgeRow         ;
        STA MapPtr+1            ;
        RTS                     ;
RowTown:
        LDA BY                  ;A town: its base (RowBase) + BY * 32.
        LSR                     ;
        LSR                     ;
        LSR                     ;
        CLC                     ;
        ADC RowBase             ;
        STA MapPtr+1            ;
        LDA BY                  ;
        ASL                     ;
        ASL                     ;
        ASL                     ;
        ASL                     ;
        ASL                     ;
        STA MapPtr              ;
        CLC                     ;
        RTS                     ;

;The map's bank in (the overworld's), or for a town RowBase: its copy's
;page in RAM.
MapBankIn:
        LDA MapId               ;
        BNE +                   ;
        JMP SelectBank          ;The overworld (A = MAP_BANK, 0).
*       LDA #>TownMap           ;
        STA RowBase             ;
        RTS                     ;

;A town's map, 1KB from TOWN_BANK, to TownMap: there its doors open and
;its chests are taken (and on the next visit are back, as in the game).
;The overworld's is read from its bank.
CopyTown:
        LDA MapId               ;
        BNE +                   ;
        RTS                     ;
*       TAX                     ;Its page (MapTownBank, MapTownHi).
        LDA MapTownBank         ;
        JSR SelectBank          ;
        LDX MapId               ;
        LDA MapTownHi           ;
        STA MapPtr+1            ;
        LDA #>TownMap           ;
        STA Ptr+1               ;
        LDY #$00                ;
        STY MapPtr              ;
        STY Ptr                 ;
        LDX #$04                ;
*       LDA (MapPtr),Y          ;
        STA (Ptr),Y             ;
        INY                     ;
        BNE -                   ;
        INC MapPtr+1            ;
        INC Ptr+1               ;
        DEX                     ;
        BNE -                   ;
        RTS                     ;

;Draw blocks BX on, Count of them, of map row BY into the ring: ring rows
;(BY mod 16) * 2 and on, columns (BX mod 32) * 2, each written at that
;column and 64 on. The row's pointer and ring row are worked out once.
DrawRowPart:
        JSR RowPointer          ;
        ROR RowIsOff            ;(Bit 7: the row is off the map.)
        LDA BY                  ;In the light: its row (and its column, for
        SEC                     ;each block) within LightR of the hero's.
        SBC HeroY               ;
        CLC                     ;
        ADC LightR              ;
        CMP LightW              ;
        ROR RowLit              ;(Bit 7 clear: lit.)
        LDA BY                  ;Ring row * 128: (BY AND 15) * 256.
        AND #$0F                ;
        CLC                     ;
        ADC #>Screen            ;
        STA Ptr+1               ;
RowBlock:
        LDY BX                  ;
        LDA Dark                ;A dark map: black but in the light.
        BEQ RowLitBlock         ;
        BIT RowLit              ;
        BMI RowDark             ;
        TYA                     ;
        SEC                     ;
        SBC HeroX               ;
        CLC                     ;
        ADC LightR              ;
        CMP LightW              ;
        BCC RowLitBlock         ;
RowDark:
        LDX #DARK_BLOCK         ;
        JMP RowDraw             ;
RowLitBlock:
        BIT RowIsOff            ;The block: the map's, or off it the border.
        BMI +                   ;
        CPY MapSz               ;
        BCS +                   ;
        LDA (MapPtr),Y          ;
        TAX                     ;
        JMP ++                  ;
*       LDX MapId               ;
        LDA MapBorder           ;
        TAX                     ;
*
RowDraw:
        TYA                     ;Its ring column.
        AND #$1F                ;
        ASL                     ;
        STA Ptr                 ;
        LDY #$00                ;Its 4 characters, each at its column
        LDA BlockUL,X           ;and 64 on.
        STA (Ptr),Y             ;
        LDY #64                 ;
        STA (Ptr),Y             ;
        LDY #$01                ;
        LDA BlockUR,X           ;
        STA (Ptr),Y             ;
        LDY #65                 ;
        STA (Ptr),Y             ;
        LDY #128                ;
        LDA BlockLL,X           ;
        STA (Ptr),Y             ;
        LDY #192                ;
        STA (Ptr),Y             ;
        LDY #129                ;
        LDA BlockLR,X           ;
        STA (Ptr),Y             ;
        LDY #193                ;
        STA (Ptr),Y             ;
        INC BX                  ;
        DEC Count               ;
        BNE RowBlock            ;
        RTS                     ;

;Draw block column A, rows TopBlock to TopBlock + 15. The map's rows are
;a fixed length apart (the overworld's 120, a town's 32), so going down
;one is an add; the ring row counts on, round its 16.
DrawColumn:
        STA BX                  ;
        AND #$1F                ;Its ring column, the same all the way.
        ASL                     ;
        STA Ptr                 ;
        LDA TopBlock            ;
        STA BY                  ;
        AND #$0F                ;
        CLC                     ;
        ADC #>Screen            ;
        STA Ptr+1               ;
        LDA #16                 ;
        STA Count               ;
        LDA #$00                ;No row pointer yet.
        STA ColValid            ;
        LDA #32                 ;
        LDX MapId               ;
        BNE +                   ;
        LDA #120                ;
*       STA ColStride           ;
        JSR MapBankIn           ;Its bank, once.
ColBlock:
        LDA Dark                ;A dark map: black but in the light.
        BEQ ColLitBlock         ;
        LDA BX                  ;
        SEC                     ;
        SBC HeroX               ;
        CLC                     ;
        ADC LightR              ;
        CMP LightW              ;
        BCS ColDark             ;
        LDA BY                  ;
        SEC                     ;
        SBC HeroY               ;
        CLC                     ;
        ADC LightR              ;
        CMP LightW              ;
        BCC ColLitBlock         ;
ColDark:
        LDA #$00                ;
        STA ColValid            ;
        LDX #DARK_BLOCK         ;
        JMP ColDraw             ;
ColLitBlock:
        LDA BY                  ;Off the map (or the column is): the border.
        CMP MapHt               ;
        BCS ColBorder           ;
        LDY BX                  ;
        CPY MapSz               ;
        BCS ColBorder           ;
        LDA BY                  ;(The bridge's row is not a stride on: its
        CMP BridgeY             ;own, and the next found again.)
        BEQ ColBridge           ;
        LDA ColValid            ;The row: the one above's + the stride, or
        BEQ ColFirst            ;the first found.
        LDA MapPtr              ;
        CLC                     ;
        ADC ColStride           ;
        STA MapPtr              ;
        BCC +                   ;
        INC MapPtr+1            ;
        BCS +                   ;
ColBridge:
        JSR RowAddr             ;
        LDA #$00                ;
        STA ColValid            ;
        BEQ ColRead             ;
ColFirst:
        JSR RowAddr             ;
        INC ColValid            ;
ColRead:
        LDY BX                  ;
*       LDA (MapPtr),Y          ;
        TAX                     ;
        JMP ColDraw             ;
ColBorder:
        LDA #$00                ;
        STA ColValid            ;
        LDX MapId               ;
        LDA MapBorder           ;
        TAX                     ;
ColDraw:
        LDY #$00                ;Its 4 characters, each at its column
        LDA BlockUL,X           ;and 64 on.
        STA (Ptr),Y             ;
        LDY #64                 ;
        STA (Ptr),Y             ;
        LDY #$01                ;
        LDA BlockUR,X           ;
        STA (Ptr),Y             ;
        LDY #65                 ;
        STA (Ptr),Y             ;
        LDY #128                ;
        LDA BlockLL,X           ;
        STA (Ptr),Y             ;
        LDY #192                ;
        STA (Ptr),Y             ;
        LDY #129                ;
        LDA BlockLR,X           ;
        STA (Ptr),Y             ;
        LDY #193                ;
        STA (Ptr),Y             ;
        INC BY                  ;
        INC Ptr+1               ;The ring row on, round its 16.
        LDA Ptr+1               ;
        CMP #>Screen+16         ;
        BNE +                   ;
        LDA #>Screen            ;
        STA Ptr+1               ;
*       DEC Count               ;
        BNE ColBlock            ;
        RTS                     ;

;A dark map: the light round the hero drawn again, a block more each way
;(what has just left it black).
RedrawLight:
        LDA Dark                ;
        BEQ LightDone           ;
        LDA HeroY               ;
        SEC                     ;
        SBC LightR              ;
        SEC                     ;
        SBC #$01                ;
        STA BY                  ;
        LDA LightW              ;Rows: the width + 2.
        CLC                     ;
        ADC #$02                ;
        STA Rows                ;
LightRow:
        LDA HeroX               ;
        SEC                     ;
        SBC LightR              ;
        SEC                     ;
        SBC #$01                ;
        STA BX                  ;
        LDA LightW              ;
        CLC                     ;
        ADC #$02                ;
        STA Count               ;
        JSR DrawRowPart         ;
        INC BY                  ;
        DEC Rows                ;
        BNE LightRow            ;
LightDone:
        RTS                     ;

;Draw block row A, columns LeftBlock to LeftBlock + 17.
DrawRow:
        STA BY                  ;
        LDA LeftBlock           ;
        STA BX                  ;
        LDA #18                 ;
        STA Count               ;
        JMP DrawRowPart         ;

;The whole view, and a block more each way.
DrawView:
        LDA TopBlock            ;
        STA Tmp                 ;
        LDA #16                 ;
        STA Rows                ;
*       LDA Tmp                 ;
        JSR DrawRow             ;
        INC Tmp                 ;
        DEC Rows                ;
        BNE -                   ;
        RTS                     ;

;Draw the map blocks again where a window was: block columns LeftBlock + X
;on, A of them, rows TopBlock + Y on, Rows of them.
RedrawBlocks:
        STX Tmp2                ;
        STA Tmp                 ;
        TYA                     ;
        CLC                     ;
        ADC TopBlock            ;
        STA BY                  ;
RedrawRow:
        LDA LeftBlock           ;
        CLC                     ;
        ADC Tmp2                ;
        STA BX                  ;
        LDA Tmp                 ;
        STA Count               ;
        JSR DrawRowPart         ;
        INC BY                  ;
        DEC Rows                ;
        BNE RedrawRow           ;
        RTS                     ;

;--------------------------------------[Display]-----------------------------------------------------

;The coarse and fine scroll for the VBI, from the view position.
SetScroll:
        LDA FineY               ;Lines: TopBlock * 16 + FineY; ring row
        LSR                     ;= that / 8, VSCROL = that AND 7.
        LSR                     ;
        LSR                     ;
        STA Tmp                 ;
        LDA TopBlock            ;
        ASL                     ;
        CLC                     ;
        ADC Tmp                 ;
        AND #$1F                ;
        STA ShRow               ;
        LDA FineY               ;
        AND #$07                ;
        STA ShV                 ;
        LDA FineX               ;Color clocks: x = LeftBlock * 8 + FineX.
        LSR                     ;With HSCROL on, ANTIC fetches a normal
        LSR                     ;width line (40 bytes) from the row's
        STA Tmp                 ;address, starting 16 color clocks left of
        LDA LeftBlock           ;the narrow playfield, and shifts it right
        ASL                     ;by HSCROL. So the address is x / 4 - 3
        CLC                     ;characters (mod the ring's 64), and HSCROL
        ADC Tmp                 ;= 4 - x AND 3.
        SEC                     ;
        SBC #$03                ;
        AND #$3F                ;
        STA ShCol               ;
        LDA FineX               ;
        AND #$03                ;
        STA Tmp                 ;
        LDA #$04                ;
        SEC                     ;
        SBC Tmp                 ;
        STA ShH                 ;
        RTS                     ;

;The display list: 8 blank lines (7 and 1), then DL_ROWS mode 4 rows,
;each with its own address (LMS), all but the last with VSCROL, all with
;HSCROL. The 28 rows shown fill scan lines 16-239. DLIBits gives rows
;their display list interrupts.
BuildDList:
        LDA #$60                ;
        STA DList               ;
        LDA #$00                ;
        STA DList+1             ;
        LDX #$02                ;
        LDY #$00                ;
DListRow:
        LDA #$74                ;Mode 4, LMS, VSCROL, HSCROL.
        CPY #DL_ROWS-1          ;
        BNE +                   ;
        LDA #$54                ;The last: no VSCROL.
*       STA DList,X             ;
        INX                     ;
        INX                     ;
        INX                     ;
        INY                     ;
        CPY #DL_ROWS            ;
        BNE DListRow            ;
        LDA #$41                ;Jump and wait for vertical blank.
        STA DList,X             ;
        LDA #<DList             ;
        STA DList+1,X           ;
        LDA #>DList             ;
        STA DList+2,X           ;
        JMP SetAddresses        ;

;The display list interrupts (people.asm's DLI), each at the end of a row
;for the next: where a townsperson's player moves or changes color there
;(RowHP2/RowHP3: DrawPeople sets them, and calls this after), at the end
;of the row before the dialog window's (its character set), and in a
;battle the scene's bands'. Each interrupt costs time, so only those rows
;have one.
DLIBits:
        LDA #$FF                ;(DrawPeople's rows not the same, after.)
        STA OldMask             ;
DLIBitRows:
        LDA PeopleOn            ;(Townspeople: their rows count.)
        BEQ +                   ;
        LDA #$FF                ;
*       STA Tmp3                ;
        LDX #$02                ;
        LDY #$00                ;
DLIBitRow:
        LDA RowHP2+1,Y          ;
        ORA RowHP3+1,Y          ;
        AND Tmp3                ;
        BNE DLIOn               ;
        CPY #DLG_FIRST-1        ;
        BEQ DLIOn               ;
        LDA BattleOn            ;
        BEQ DLIOff              ;
        LDA MapId               ;(No scene band in a cave.)
        BNE +                   ;
        CPY #SCENE_ROW-1        ;
        BEQ DLIOn               ;
*
        CPY LowerDLI            ;
        BEQ DLIOn               ;
DLIOff:
        LDA DList,X             ;
        AND #$7F                ;
        JMP DLISet              ;
DLIOn:
        LDA DList,X             ;
        ORA #$80                ;
DLISet:
        STA DList,X             ;
        INX                     ;
        INX                     ;
        INX                     ;
        INY                     ;
        CPY #DL_ROWS-1          ;
        BNE DLIBitRow           ;
        LDA DList,X             ;The last row: none.
        AND #$7F                ;
        STA DList,X             ;
        RTS                     ;

;Each display list row's address: ring row (ShRow + i) mod 32, column
;ShCol. Called by the VBI too, so it has its own temporary.
SetAddresses:
        LDA ShRow               ;
        STA VbiTmp              ;
        LDX #$03                ;
        LDY #DL_ROWS            ;
*       LDA VbiTmp              ;Row * 128: high = row / 2, low = (row AND 1) * 128.
        LSR                     ;
        PHA                     ;
        LDA #$00                ;
        ROR                     ;
        ORA ShCol               ;
        STA DList,X             ;
        PLA                     ;
        CLC                     ;
        ADC #>Screen            ;
        STA DList+1,X           ;
        INC VbiTmp              ;
        LDA VbiTmp              ;
        AND #$1F                ;
        STA VbiTmp              ;
        INX                     ;
        INX                     ;
        INX                     ;
        DEY                     ;
        BNE -                   ;
        RTS                     ;

;The display and color registers: set at start and again every frame, as
;something in the BIOS changes them (the playfield goes black).
SetHardware:
        LDX #$04                ;The map's colors (grey while GreyTime
        LDA GreyTime            ;counts down; FadeSub less luminance):
        ORA FadeSub             ;neither, a plain copy.
        BNE SetColor            ;
*       LDA MapColors,X         ;
        STA COLPF0,X            ;
        DEX                     ;
        BPL -                   ;
        BMI SetColored          ;
SetColor:
        LDA MapColors,X         ;
        LDY GreyTime            ;
        BEQ +                   ;
        AND #$0F                ;
*       PHA                     ;
        AND #$0F                ;
        SEC                     ;
        SBC FadeSub             ;
        BCS +                   ;
        PLA                     ;(Gone: black.)
        LDA #$00                ;
        BEQ ++                  ;
*       STA VbiTmp              ;
        PLA                     ;
        AND #$F0                ;
        ORA VbiTmp              ;
*       STA COLPF0,X            ;
        DEX                     ;
        BPL SetColor            ;
        LDA GreyTime            ;
        BEQ SetColored          ;
        DEC GreyTime            ;
SetColored:
        LDX #$00                ;The hero's colors (carrying the princess:
        LDA ModFlags            ;the other pair).
        AND #F_CARRY            ;
        BEQ +                   ;
        LDX #$02                ;
*       LDA HeroColors,X        ;
        STA COLPM0              ;
        LDA HeroColors+1,X      ;
        STA COLPM1              ;
        LDA #>CharsetA          ;
        STA CHBASE              ;
        LDA #<DList             ;
        STA DLISTL              ;
        LDA #>DList             ;
        STA DLISTH              ;
        LDA #>PMMemory          ;
        STA PMBASE              ;
        LDA #$21                ;Multicolor players (where 0 and 1 overlap,
        STA PRIOR               ;their colors OR), in front of the playfield.
        LDA #$02                ;
        STA GRACTL              ;Players on.
        LDA #$39                ;Narrow playfield, players single-line,
        LDX Loading             ;or nothing while a map loads.
        BEQ +                   ;
        LDA #$00                ;
*       STA DMACTL              ;
        RTS                     ;

;Vertical blank: count the frame, show the scroll the main loop set, and
;players 2 and 3 as the first row has them.
VBI:
        PHA                     ;
        TXA                     ;
        PHA                     ;
        TYA                     ;
        PHA                     ;
        JSR SetHardware         ;
        LDA #$00                ;The first row's DLI is row 1's.
        STA DliRow              ;
        LDX #<DLI               ;The interrupts: a battle's own chain, or the
        LDY #>DLI               ;rows'.
        LDA BattleOn            ;
        BEQ +                   ;
        LDX #<BattleDLI1        ;
        LDY #>BattleDLI1        ;
        LDA MapId               ;(A cave's: no scene band, the monster's
        BEQ +                   ;first.)
        LDX #<BattleDLI2        ;
        LDY #>BattleDLI2        ;
*       LDA TitleOn             ;(The title's: TitleDLI.)
        CMP #$01                ;
        BNE +                   ;
        LDX #<TitleDLI          ;
        LDY #>TitleDLI          ;
*       STX VDSLST              ;
        STY VDSLST+1            ;
        LDA IsParked            ;
        BNE VBIDone             ;
        INC FrameCount          ;
        BNE +                   ;
        INC FrameHi             ;
*       JSR SetAddresses        ;
        LDA ShH                 ;
        STA HSCROL              ;
        LDA ShV                 ;
        STA VSCROL              ;
        STA VScrolNow           ;(For the DLI, which works out its row.)
        EOR #$FF                ;VCOUNT on the last line above the dialog
        SEC                     ;window (its rows' set): (16 + 18 * 8 - 1 -
        ADC #FIRST_LINE+DLG_FIRST*8-1 ;VSCROL) / 2.
        LSR                     ;
        STA DlgVCount           ;
        LDA POT0                ;The last scan's stick, finished (read in
        STA PotX                ;the main loop the pots are still counting).
        LDA POT1                ;
        STA PotY                ;
        STA POTGO               ;Start the next stick scan.
        LDA RowHP2              ;(0: as it is.)
        BEQ +                   ;
        STA HPOSP2              ;
        LDA RowC2               ;
        STA COLPM2              ;
*       LDA RowHP3              ;
        BEQ +                   ;
        STA HPOSP3              ;
        LDA RowC3               ;
        STA COLPM3              ;
*
.include "profile_start.asm"
        JSR UpdateSound         ;
.include "profile_end.asm"
VBIDone:
        PLA                     ;
        TAY                     ;
        PLA                     ;
        TAX                     ;
        PLA                     ;
        RTI                     ;

.include "sound.asm"
.include "shop.asm"
.include "treasure.asm"
.include "spell.asm"
.include "castle.asm"
.include "status.asm"
.include "password.asm"
.include "people.asm"
.include "windows.asm"
.include "text.asm"
.include "battle.asm"

;--------------------------------------[Data]--------------------------------------------------------

.include "data.asm"
.include "strings.asm"

;A new hero: the name (in text tiles, padded with blanks), level, HP, MP,
;gold and experience.
NewGame:
.include "name.asm"
        .byte START_LEVEL, START_HP-START_HURT, START_MP ;(Level 1, all HP, but in tests.)
        .word START_GOLD, START_EXP ;Gold, experience (0 but in tests).
        .byte START_HP, START_MP, START_STR, START_AGI ;Max HP, max MP, strength, agility.
        .byte START_EQUIP, START_KEYS, 0 ;Equipment, keys (none but in tests), herbs.
        .byte START_INV0, START_INV1, START_INV2, START_INV3 ;Items (none but in tests),
        .byte START_FLAGS       ;the flags (ModFlags: none but in tests).
.alias NEW_GAME_SIZE    27
.alias STATUS_DELAY     30      ;Frames standing before the status window.

.include "profile_code.asm"
ProgramEnd:
        .advance $8000, $FF     ;The program fills the first half of a bank.

.include "poweron.asm"
