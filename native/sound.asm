;Sound: the game's music and sound effects.
;
;Each music's and effect's parts were read from the ROM and converted at
;build time (tools/native/sound.py) into one straight stream per channel
;in SOUND_BANK: notes, waits, a few control bytes, loops as a GOTO. The
;build plays every one both ways, the game's engine on the ROM's data and
;this one on the converted data, and stops if any differs. The engine,
;run by the VBI each frame, keeps the game's timing (its tempo, the order
;of the channels, effects on SQ2 and the noise) and its "hardware" writes
;in RAM, by channel (0 SQ1, 1 SQ2, 2 the triangle, 3 the noise). Each
;frame then does what the NES's sound hardware does with them, in native
;form: one pass over the channels, a silent one skipped, the length
;counter counted in frames, the envelope's divider spent against the
;frame's 4 quarter frames at once (as the NES's steps them), the linear
;counter; and the result goes in POKEY: SQ1 on channels 1+2 joined
;(16 bits at 1.79MHz), SQ2 or the noise (the sound effects') on channel 3,
;the triangle on channel 4 (8 bits at 64kHz, both at 15kHz on a frame the
;triangle's note is too low for 64kHz and channel 3's would still be in
;tune there: NoteFlags), all pure tones but the noise. A pulse plays at
;50% whatever its duty, so a narrower one is made as much quieter as it is
;on the NES (DutyVol). The sweep unit is the NES's, for the effects' SQ2
;(the wings' flight). The port's own touches: SQ1's vibrato on long notes,
;and noise textures for some effects (NOISE_DIST). POKEY's channels add up as they are, without the
;NES's softening of a loud mix, so the music plays at about half the
;game's loudness and at a third while an effect sounds, the effect at its
;own loudness (MusicLoud).
;
;PlayMusic / PlaySFX (A: the game's music or effect number) only ask: the
;VBI starts it, so the engine is never caught halfway.

.alias SOUND_BANK       6       ;The converted music and effects (and MUSIC_LO/HI,
                                ;SFX_LO/HI: where each part starts).
.alias OP_TEMPO         $F0     ;The format's control bytes (sound.py).
.alias OP_CNTRL0        $F1     ;
.alias OP_NOISE_VOL     $F2     ;
.alias OP_WAIT          $F3     ;
.alias OP_GOTO          $F4     ;
.alias OP_SWEEP         $F6     ;
.alias VIB_DELAY        20      ;Frames an SQ1 note sounds before its vibrato.
.alias NoiseKind        $07CF   ;The effect's noise's texture (AUDC's top bits: NoiseDist).
.alias VibAge           $07D0   ;Frames SQ1's note has sounded (to 255).
.alias TRI_VOLUME       13      ;The triangle's loudness (it has no volume):
                                ;its balance with the pulses the NES's.
;The sweep unit (the NES's $4001, the effects' SQ2): its byte, its
;divider, its reload flag, and SQ2's timer as it sweeps.
.alias SweepCfg         $07FB   ;
.alias SweepDiv         $07FC   ;
.alias SweepReload      $07FD   ;
.alias SweepLo          $07FE   ;
.alias SweepHi          $07FF   ;
.alias SndSlow          $73     ;Channels 3 and 4 at 15kHz this frame (ToPokey).

;The game's software registers, X = 0 SQ1, 2 SQ2, 4 TRI, 6 noise.
.alias ChIndex          $40     ;8: data pointers (zero page, for (ChIndex,X)),
.alias ChLength         $50     ;8: counts to the next byte (0: off),
.alias Tempo            $60     ;
.alias TempoCntr        $61     ;
.alias NoteOffset       $62     ;
.alias SFXActive        $63     ;
.alias SndTemp          $64     ;
.alias SQ2Config        $65     ;
.alias MusicReq         $66     ;A music number + 1 to start (0: none),
.alias SFXReq           $67     ;and an effect's.
.alias Song             $68     ;The music playing.
.alias SndBanked        $70     ;Non-zero: the sound bank is in.
.alias SndTemp2         $71     ;
.alias ApuClocks        $72     ;Quarter frames left this frame.
;Each channel's state, by channel Y (0 SQ1, 1 SQ2, 2 TRI, 3 noise; 4 where
;the music's SQ2 goes while an effect plays, unheard).
.alias ChCtl            $0380   ;5: its control byte 0 (envelope, volume, halt),
.alias ChNote           $0385   ;5: its note (the noise: its period),
.alias ChDecay          $038A   ;5: the envelope's volume,
.alias ChAcc            $038F   ;5: the envelope's divider ($80: to start),
.alias ChLen            $0394   ;5: frames to silence (the length counter),
.alias ChVol            $0399   ;5: the volume it sounds at (0-15).
.alias LinCount         $039E   ;The triangle's linear counter,
.alias LinReload        $039F   ;and its reload flag.

;The game's music and effect numbers (Dragon_Warrior_Defines.asm).
.alias MSC_FIGHT        $0E     ;Entering a fight (it goes on to the fight's).
.alias MSC_DEATH        $14     ;
.alias MSC_VICTORY      $19     ;
.alias MSC_LEVEL_UP     $1A     ;
.alias SFX_WINGS        $81     ;The flight home (wings, RETURN: the game's DoReturn).
.alias SFX_STAIRS       $82     ;
.alias SFX_RUN          $83     ;
.alias SFX_MENU         $85     ;
.alias SFX_CONFIRM      $86     ;(The YES/NO window's.)
.alias SFX_ENEMY_HIT    $87     ;
.alias SFX_EXCELLENT    $88     ;
.alias SFX_ATTACK       $89     ;
.alias SFX_HERO_HIT     $8A     ;
.alias SFX_ATTACK_PREP  $8C     ;
.alias SFX_MISSED1      $8D     ;
.alias SFX_MISSED2      $8E     ;
.alias SFX_WALL         $8F     ;
.alias SFX_TEXT         $90     ;
.alias SFX_RADIANT      $92     ;


;--------------------------------------[Requests]----------------------------------------------------

;The menu button's sound: a choice made in a selection window, or the
;command window up (the game's SFX_MENU_BTN).
Beep:
        LDA #SFX_MENU           ;
        JMP PlaySFX             ;

PlayMusic:
        STA Song                ;
        CLC                     ;
        ADC #$01                ;
        STA MusicReq            ;
        RTS                     ;

;The map's music (MapMusic: the game's ResumeMusicTbl), unless playing.
PlayMapMusic:
        LDX MapId               ;
        LDA MapMusic            ;
        CMP Song                ;
        BNE PlayMusic           ;
        RTS                     ;

PlaySFX:
        AND #$7F                ;
        CLC                     ;
        ADC #$01                ;
        STA SFXReq              ;
        RTS                     ;

;Silence, at power on.
InitSound:
        LDA #$00                ;
        LDX #$3F                ;
*       STA ChIndex,X           ;
        DEX                     ;
        BPL -                   ;
        LDX #$1F                ;
*       STA ChCtl,X             ;
        DEX                     ;
        BPL -                   ;
        LDA #$FF                ;
        STA Tempo               ;
        LDA #$50                ;Channels 1+2 joined, 1 at 1.79MHz.
        STA AUDCTL              ;
        LDA #$FF                ;
        STA Song                ;
        RTS                     ;

;--------------------------------------[The VBI's part]----------------------------------------------

;A frame of sound: requests, the engine, the APU's work, POKEY. The bank
;is put back as CurBank says (SelectBank only changes it after CurBank,
;and both its reads may be done again).
UpdateSound:
        LDA MusicReq            ;
        BEQ +                   ;
        JSR SndBankIn           ;
        LDA MusicReq            ;
        SEC                     ;
        SBC #$01                ;
        JSR InitMusic           ;
        LDA #$00                ;
        STA MusicReq            ;
*       LDA SFXReq              ;
        BEQ +                   ;
        JSR SndBankIn           ;
        LDA SFXReq              ;
        SEC                     ;
        SBC #$01                ;
        JSR InitSFX             ;
        LDA #$00                ;
        STA SFXReq              ;
*       JSR SoundEngine         ;
        JSR RunAPU              ;
        JSR SndBankIn           ;(The dividers are in the sound bank.)
        JSR ToPokey             ;
        LDA #$00                ;The bank back.
        STA SndBanked           ;
        LDA CurBank             ;
        JMP HwBank              ;

;The sound bank in (X kept), until UpdateSound's end: only on the frames
;the data is read (most frames none is).
SndBankIn:
        LDA SndBanked           ;
        BNE +                   ;
        STX SndTemp2            ;
        LDA #SOUND_BANK         ;
        JSR HwBank              ;
        LDX SndTemp2            ;
        LDA #$01                ;
        STA SndBanked           ;
*       RTS                     ;

;The SuperCart's bank A, CurBank left as it is.
HwBank:
        PHA                     ;
        AND #$0C                ;
        TAX                     ;
        LDA SuperCartHi,X       ;
        PLA                     ;
        AND #$03                ;
        ASL                     ;
        ASL                     ;
        TAX                     ;
        LDA SuperCartLo,X       ;
        RTS                     ;

;Music A (InitMusicSFX's music part): each channel's pointer from the
;table, or the no-sound one's.
InitMusic:
        TAY                     ;Its 3 parts (SQ1, SQ2, TRI): MusicLo/Hi
        LDX #$00                ;from A * 3.
        ASL                     ;
        STA SndTemp             ;
        TYA                     ;
        CLC                     ;
        ADC SndTemp             ;
        TAY                     ;
InitChannel:
        LDA MUSIC_LO,Y           ;
        STA ChIndex,X           ;
        LDA MUSIC_HI,Y           ;
        STA ChIndex+1,X         ;
        LDA #$01                ;
        STA ChLength,X          ;
        INY                     ;
        INX                     ;
        INX                     ;
        CPX #$06                ;
        BNE InitChannel         ;
        LDA #$00                ;
        STA NoteOffset          ;
        RTS                     ;

;Sound effect A (0 on): on the noise channel's data, SQ2's hardware.
InitSFX:
        TAX                     ;
        LDA #$00                ;No sweep until it asks for one.
        STA SweepCfg            ;
        LDA NoiseDist,X         ;Its noise's texture (sound.py's NOISE_DIST,
        STA NoiseKind           ;in SOUND_BANK, in now: the port's own).
        LDA SFX_LO,X             ;
        STA ChIndex+6           ;
        LDA SFX_HI,X             ;
        STA ChIndex+7           ;
        LDA #$01                ;
        STA SFXActive           ;
        STA ChLength+6          ;
        LDA #$30                ;Constant volume 0, no length counter.
        STA ChCtl+1             ;
        STA ChCtl+3             ;
        RTS                     ;

;--------------------------------------[The engine]--------------------------------------------------

;The game's timing (UpdateSound): the effect first (without the note
;offset), then, at the tempo, the triangle, SQ2 (nowhere while an effect
;plays) and SQ1.
SoundEngine:
        LDA SFXActive           ;
        BEQ SndTempo            ;
        LDA NoteOffset          ;
        PHA                     ;
        LDA #$00                ;
        STA NoteOffset          ;
        LDX #$06                ;(On SQ2.)
        LDY #$01                ;
        JSR NextByte            ;
        TAX                     ;
        PLA                     ;
        STA NoteOffset          ;
        TXA                     ;
        BNE SndTempo            ;
        STA SFXActive           ;Done: SQ2 the music's again, the noise off.
        STA ChLen+1             ;
        STA ChLen+3             ;
        LDA SQ2Config           ;
        STA ChCtl+1             ;
        LDA #$30                ;
        STA ChCtl+3             ;
SndTempo:
        LDA TempoCntr           ;A step each time the count passes 256,
        CLC                     ;then less 150.
        ADC Tempo               ;
        STA TempoCntr           ;
        BCC SndDone             ;
        SBC #$96                ;
        STA TempoCntr           ;
        LDX #$04                ;
        LDY #$02                ;
        JSR NextByte            ;
        LDX #$02                ;
        LDY #$01                ;
        LDA SFXActive           ;
        BEQ +                   ;
        LDY #$04                ;
*       JSR NextByte            ;
        LDX #$00                ;
        LDY #$00                ;
        JSR NextByte            ;
SndDone:
        RTS                     ;

;Part X (channel Y): when its wait runs out, its next bytes, to the
;next wait (sound.py's format). A: the wait (0: the channel has ended).
NextByte:
        LDA ChLength,X          ;
        BEQ SndRet              ;
        DEC ChLength,X          ;
        BNE SndRet              ;
ProcessByte:
        JSR GetByte             ;
        CMP #OP_TEMPO           ;
        BCS SndOp               ;
        CMP #$E0                ;
        BCS SndNoise            ;
        CMP #$80                ;
        BCS SndNote             ;
        STA ChLength,X          ;A wait (0: the end).
SndRet:
        RTS                     ;

SndOp:
        BNE +                   ;$F0: the tempo.
        JSR GetByte             ;
        STA Tempo               ;
        JMP ProcessByte         ;
*       CMP #OP_CNTRL0          ;
        BNE +                   ;
        JSR GetByte             ;
        CPX #$02                ;(SQ2's kept, for after an effect.)
        BNE SndCntrl0           ;
        STA SQ2Config           ;
SndCntrl0:
        STA ChCtl,Y             ;
        JMP ProcessByte         ;
*       CMP #OP_NOISE_VOL       ;
        BNE +                   ;
        JSR GetByte             ;
        STA ChCtl+3             ;
        JMP ProcessByte         ;
*       CMP #OP_WAIT            ;
        BNE +                   ;
        JSR GetByte             ;
        STA ChLength,X          ;
        RTS                     ;
*       CMP #OP_GOTO            ;
        BNE +                   ;
        JSR GetByte             ;
        PHA                     ;
        JSR GetByte             ;
        STA ChIndex+1,X         ;
        PLA                     ;
        STA ChIndex,X           ;
        JMP ProcessByte         ;
*       CMP #OP_SWEEP           ;
        BNE +                   ;
        JSR GetByte             ;$F6: the sweep (written as $4001 is: its
        STA SweepCfg            ;divider reloaded at the next half frame).
        STA SweepReload         ;
        JMP ProcessByte         ;
*       JSR GetByte             ;$F5: the note offset.
        STA NoteOffset          ;
        JMP ProcessByte         ;

SndNoise:
        AND #$0F                ;
        STA ChNote+3            ;
        TYA                     ;
        PHA                     ;
        LDY #$03                ;
        JSR StartNote           ;
        PLA                     ;
        TAY                     ;
        JMP ProcessByte         ;

SndNote:
        CLC                     ;The note, the offset added (as the game's
        ADC NoteOffset          ;table index: mod 128).
        AND #$7F                ;
        CMP #NUM_NOTES          ;(Past the table: its last.)
        BCC +                   ;
        LDA #NUM_NOTES-1        ;
*       STA ChNote,Y            ;
        CPY #$00                ;(SQ1's: its vibrato waits again.)
        BNE NoteAged            ;
        STY VibAge              ;
NoteAged:
        CPY #$01                ;(SQ2's: its timer, for the sweep.)
        BNE NoteTimed           ;
        STX SndTemp             ;
        TAX                     ;
        LDA NesTimLo,X          ;
        STA SweepLo             ;
        LDA NesTimHi,X          ;
        STA SweepHi             ;
        LDX SndTemp             ;
NoteTimed:
        JSR StartNote           ;
        JMP ProcessByte         ;

;Channel Y's note starts (the game's write to its length register): the
;length counter full (its index 1: 254 half frames), the envelope to start
;(at 15), the triangle's linear counter to be reloaded.
StartNote:
        LDA #127                ;
        STA ChLen,Y             ;
        LDA #15                 ;
        STA ChDecay,Y           ;
        LDA #$80                ;(The envelope's start, its next quarter frame.)
        STA ChAcc,Y             ;
        CPY #$02                ;
        BNE +                   ;
        STA LinReload           ;
*       RTS                     ;

GetByte:
        LDA SndBanked           ;
        BNE +                   ;
        JSR SndBankIn           ;
*       LDA (ChIndex,X)         ;
        INC ChIndex,X           ;
        BNE +                   ;
        INC ChIndex+1,X         ;
*       RTS                     ;

;--------------------------------------[The APU]-----------------------------------------------------

;Notes written, then four quarter frames and two half frames.
RunAPU:
        LDX #$03                ;Channel X, down to SQ1.
APUChannel:
        LDA ChLen,X             ;Silent: nothing to do.
        BEQ APUSilent           ;
        CPX #$02                ;
        BEQ APUTriangle         ;
        LDA ChCtl,X             ;Two half frames: the length counter, a
        AND #$20                ;frame less unless halted (bit 5).
        BNE +                   ;
        DEC ChLen,X             ;
        BEQ APUSilent           ;
*       LDA ChCtl,X             ;A constant volume (bit 4),
        AND #$10                ;
        BEQ APUEnvelope         ;
        LDA ChCtl,X             ;
        AND #$0F                ;
        JMP APUVolume           ;
APUEnvelope:                    ;or the envelope: the NES's divider (ChAcc)
        LDA ChCtl,X             ;spent against the frame's 4 quarter frames,
        AND #$0F                ;a step each time it runs out, then reloaded
        STA SndTemp             ;with the period (bit 7: a note's first
        LDA #$04                ;frame, its first quarter frame the start).
        STA ApuClocks           ;
        LDA ChAcc,X             ;
        BPL APUEnvRun           ;
        DEC ApuClocks           ;
        LDA SndTemp             ;
APUEnvRun:
        CMP ApuClocks           ;The divider outlasts the clocks left: done.
        BCS APUEnvLast          ;
        EOR #$FF                ;Clocks less the divider less 1.
        ADC ApuClocks           ;(C is clear.)
        STA ApuClocks           ;
        LDA ChDecay,X           ;A step: the volume down, or at 0 again
        BEQ +                   ;from 15 if looping (bit 5).
        DEC ChDecay,X           ;
        JMP APUEnvRunNext       ;
*       LDA ChCtl,X             ;
        AND #$20                ;
        BEQ +                   ;
        LDA #15                 ;
        STA ChDecay,X           ;
APUEnvRunNext:
*       LDA SndTemp             ;
        JMP APUEnvRun           ;
APUEnvLast:
        SEC                     ;
        SBC ApuClocks           ;
        STA ChAcc,X             ;
        LDA ChDecay,X           ;
APUVolume:
        STA ChVol,X             ;
        DEX                     ;
        BPL APUChannel          ;
        RTS                     ;
APUSilent:
        LDA #$00                ;
        STA ChVol,X             ;
        DEX                     ;
        BPL APUChannel          ;
        RTS                     ;

;The triangle: its linear counter (reloaded after a note, and while halted,
;bit 7; else 4 quarter frames less a frame, 3 the frame it was reloaded),
;its length counter (halted by bit 7 too); it sounds while both run.
APUTriangle:
        LDA LinReload           ;
        BEQ APULinDown          ;
        LDA ChCtl+2             ;
        AND #$7F                ;
        STA LinCount            ;
        LDA ChCtl+2             ;
        BMI APUTriSound         ;
        LDA #$00                ;
        STA LinReload           ;
        LDA LinCount            ;
        SEC                     ;
        SBC #$03                ;
        JMP APULinSet           ;
APULinDown:
        LDA LinCount            ;
        SEC                     ;
        SBC #$04                ;
APULinSet:
        BCS +                   ;
        LDA #$00                ;
*       STA LinCount            ;
        LDA ChCtl+2             ;
        BMI APUTriSound         ;
        DEC ChLen+2             ;
        BEQ APUSilent           ;
APUTriSound:
        LDA LinCount            ;
        BEQ APUSilent           ;
        LDA #TRI_VOLUME         ;
        JMP APUVolume           ;

;--------------------------------------[POKEY]-------------------------------------------------------

ToPokey:
        LDY #$00                ;The music's loudness: MusicVol's first 16,
        LDA SFXActive           ;its second while an effect plays (the
        BEQ PokeyLoud           ;effect then heard over it).
        LDY #16                 ;
PokeyLoud:
        STY SndTemp             ;
        LDA SweepCfg            ;An effect's sweep runs every frame, heard
        BPL PokeyNoSweep        ;or not (the noise may have channel 3).
        LDA SFXActive           ;
        BEQ PokeyNoSweep        ;
        JSR SweepFrame          ;
PokeyNoSweep:
        LDA VibAge              ;
        CMP #$FF                ;
        BEQ VibAged             ;
        INC VibAge              ;
VibAged:
        LDX ChNote              ;SQ1: channels 1+2, 16 bits, with a vibrato
        LDA VibAge              ;(the port's own) once a note has sounded
        CMP #VIB_DELAY          ;VIB_DELAY frames: its divider and up to
        BCC VibNone             ;twice its high byte more or less (about 14
        LDA FrameCount          ;cents), a cycle each 16 frames (VibMul: by
        LSR                     ;the phase, the second half less).
        AND #$07                ;
        TAY                     ;
        LDA Sq1DivHi,X          ;
        STA SndTemp2            ;
        LDA VibMul,Y            ;
        BEQ VibNone             ;
        CMP #$02                ;
        BNE VibOnce             ;
        ASL SndTemp2            ;
VibOnce:
        LDA Sq1DivLo,X          ;
        CPY #$04                ;
        BCS VibDown             ;
        CLC                     ;
        ADC SndTemp2            ;
        STA AUDF1               ;
        LDA Sq1DivHi,X          ;
        ADC #$00                ;
        STA AUDF2               ;
        JMP VibDone             ;
VibDown:
        SEC                     ;
        SBC SndTemp2            ;
        STA AUDF1               ;
        LDA Sq1DivHi,X          ;
        SBC #$00                ;
        STA AUDF2               ;
        JMP VibDone             ;
VibNone:
        LDA Sq1DivLo,X          ;
        STA AUDF1               ;
        LDA Sq1DivHi,X          ;
        STA AUDF2               ;
VibDone:
        LDA #$00                ;
        STA AUDC1               ;
        LDY #$00                ;
        JSR DutyLoud            ;
        JSR MusicLoud           ;
        STA AUDC2               ;
        LDA #$00                ;Channels 3 and 4 at 15kHz (SndSlow 1) when
        STA SndSlow             ;a note of theirs is too low for 64kHz
        STA SndTemp2            ;(SndTemp2) and none is out of tune there
        STA ApuClocks           ;(ApuClocks), by NoteFlags: bit 7 the
        LDA ChVol+3             ;triangle's too low, 4 in tune; 5 SQ2's too
        ORA SFXActive           ;low, 6 in tune. Never under an effect.
        BNE PokeyClock          ;Else 64kHz, a low note an octave up.
        LDA ChVol+2             ;
        BEQ PokeyNoTri          ;
        LDX ChNote+2            ;
        LDA NoteFlags,X         ;
        AND #$80                ;
        STA SndTemp2            ;
        LDA NoteFlags,X         ;
        AND #$10                ;
        BNE PokeyNoTri          ;
        INC ApuClocks           ;
PokeyNoTri:
        LDA ChVol+1             ;
        BEQ PokeyDecide         ;
        LDX ChNote+1            ;
        LDA NoteFlags,X         ;
        AND #$20                ;
        ORA SndTemp2            ;
        STA SndTemp2            ;
        LDA NoteFlags,X         ;
        AND #$40                ;
        BNE PokeyDecide         ;
        INC ApuClocks           ;
PokeyDecide:
        LDA SndTemp2            ;
        BEQ PokeyClock          ;
        LDA ApuClocks           ;
        BNE PokeyClock          ;
        INC SndSlow             ;
PokeyClock:
        LDA SndSlow             ;
        ORA #$50                ;(Channels 1+2 joined, 1 at 1.79MHz.)
        STA AUDCTL              ;
        LDA ChVol+3             ;Channel 3: the noise while it sounds, else
        BEQ PokeySq2            ;SQ2; both (an effect's), the louder.
        CMP ChVol+1             ;
        BCC PokeySq2            ;
        ORA NoiseKind           ;(Its texture: NoiseDist.)
        STA AUDC3               ;
        LDX ChNote+3            ;
        LDA NoiseDiv,X          ;
        STA AUDF3               ;
        JMP PokeyTri            ;
PokeySq2:
        LDX ChNote+1            ;
        LDA Sq2Div,X            ;
        LDY SndSlow             ;
        BEQ PokeySq2Div         ;
        LDA Sq2Div15,X          ;
PokeySq2Div:
        STA AUDF3               ;
        LDY #$01                ;
        JSR DutyLoud            ;
        LDX SFXActive           ;(An effect's tone at its own loudness.)
        BNE PokeySfx            ;
        JSR MusicLoud           ;
        JMP PokeySq2Set         ;
PokeySfx:
        LDX SweepCfg            ;Sweeping (the wings): the swept timer's
        BPL PokeySfxVol         ;divider, or silent when the sweep mutes.
        PHA                     ;
        JSR SweepOut            ;
        PLA                     ;
        BCC PokeySfxVol         ;
        LDA #$00                ;
PokeySfxVol:
        ORA #$A0                ;
PokeySq2Set:
        STA AUDC3               ;
PokeyTri:
        LDX ChNote+2            ;Channel 4: the triangle.
        LDA TriDiv,X            ;
        LDY SndSlow             ;
        BEQ PokeyTriDiv         ;
        LDA TriDiv15,X          ;
PokeyTriDiv:
        STA AUDF4               ;
        LDA ChVol+2             ;
        JSR MusicLoud           ;
        STA AUDC4               ;
        RTS                     ;

;A = channel Y's volume as loud as the NES's pulse of its duty (DutyVol,
;in SOUND_BANK: by the duty, the top bits of its control byte).
DutyLoud:
        LDA ChCtl,Y             ;
        AND #$C0                ;
        LSR                     ;
        LSR                     ;
        ORA ChVol,Y             ;
        TAX                     ;
        LDA DutyVol,X           ;
        RTS                     ;

;A frame of the sweep unit (the NES's, for SQ2): its two half frames.
SweepFrame:
        LDY #$02                ;
SweepHalf:
        JSR SweepTarget         ;At the divider's end: the timer to the
        LDA SweepDiv            ;target, unless it mutes or shifts by 0.
        BNE SweepCount          ;
        BCS SweepCount          ;
        LDA SweepCfg            ;
        AND #$07                ;
        BEQ SweepCount          ;
        LDA SndTemp2            ;
        STA SweepLo             ;
        LDA ApuClocks           ;
        STA SweepHi             ;
SweepCount:
        LDA SweepDiv            ;Then the divider: reloaded with the
        BEQ SweepLoad           ;period at its end or when written, else
        LDA SweepReload         ;counted down.
        BNE SweepLoad           ;
        DEC SweepDiv            ;
        JMP SweepNext           ;
SweepLoad:
        LDA SweepCfg            ;
        LSR                     ;
        LSR                     ;
        LSR                     ;
        LSR                     ;
        AND #$07                ;
        STA SweepDiv            ;
        LDA #$00                ;
        STA SweepReload         ;
SweepNext:
        DEY                     ;
        BNE SweepHalf           ;
        RTS                     ;

;Channel 3's divider for the swept timer (TimerDiv); carry set if the sweep
;mutes it (the timer below 8, or the target past $7FF).
SweepOut:
        LDA SweepLo             ;The divider: TimerDiv + the timer.
        STA SndTemp2            ;
        LDA SweepHi             ;
        AND #$07                ;
        CLC                     ;
        ADC #>TimerDiv          ;
        STA ApuClocks           ;
        LDA SndTemp2            ;
        CLC                     ;
        ADC #<TimerDiv          ;
        STA SndTemp2            ;
        BCC SweepRead           ;
        INC ApuClocks           ;
SweepRead:
        LDY #$00                ;
        LDA (SndTemp2),Y        ;
        STA AUDF3               ;
        ;Fall through: the carry says whether it mutes.

;SndTemp2/ApuClocks = the sweep's target: the timer, and it shifted right
;by the shift, added (or, negated, taken away: SQ2's). Carry set: it mutes.
SweepTarget:
        LDA SweepLo             ;
        STA SndTemp2            ;
        LDA SweepHi             ;
        STA ApuClocks           ;
        LDA SweepCfg            ;
        AND #$07                ;
        TAX                     ;
        BEQ SweepShifted        ;
SweepShift:
        LSR ApuClocks           ;
        ROR SndTemp2            ;
        DEX                     ;
        BNE SweepShift          ;
SweepShifted:
        LDA SweepCfg            ;
        AND #$08                ;
        BNE SweepDown           ;
        CLC                     ;
        LDA SweepLo             ;
        ADC SndTemp2            ;
        STA SndTemp2            ;
        LDA SweepHi             ;
        ADC ApuClocks           ;
        STA ApuClocks           ;
        CMP #$08                ;
        BCS SweepMute           ;
        BCC SweepLow            ;
SweepDown:
        SEC                     ;
        LDA SweepLo             ;
        SBC SndTemp2            ;
        STA SndTemp2            ;
        LDA SweepHi             ;
        SBC ApuClocks           ;
        STA ApuClocks           ;
SweepLow:
        LDA SweepHi             ;
        BNE SweepOn             ;
        LDA SweepLo             ;
        CMP #$08                ;
        BCC SweepMute           ;
SweepOn:
        CLC                     ;
        RTS                     ;
SweepMute:
        SEC                     ;
        RTS                     ;

;A = a music channel's volume A (0-15) as POKEY plays it, pure tone:
;about half the game's, a third while an effect plays (SndTemp: 0
;or 16), so that the effects are heard over it. (Never 0 for a volume
;that is not, but AUDC's tone bits make it non-zero anyway.)
MusicLoud:
        CLC                     ;
        ADC SndTemp             ;
        TAX                     ;
        LDA MusicVol,X          ;
        ORA #$A0                ;
        RTS                     ;
VibMul:         .byte 0, 1, 2, 1, 0, 1, 2, 1
MusicVol:       .byte 0, 1, 1, 2, 2, 3, 3, 4, 4, 5, 5, 6, 6, 7, 7, 8
                .byte 0, 1, 1, 1, 1, 2, 2, 2, 3, 3, 3, 4, 4, 4, 5, 5
