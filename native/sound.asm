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
;the triangle on channel 4 (8 bits at 64kHz), all pure tones but the
;noise. The square waves' duty cycles are not kept.
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
.alias TRI_VOLUME       10      ;The triangle's loudness (it has no volume).

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
.alias SFX_STAIRS       $82     ;
.alias SFX_RUN          $83     ;
.alias SFX_MENU         $85     ;
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
        JMP ++                  ;
*       LDA ChCtl,X             ;
        AND #$20                ;
        BEQ +                   ;
        LDA #15                 ;
        STA ChDecay,X           ;
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
        LDX ChNote              ;SQ1: channels 1+2.
        LDA Sq1DivLo,X          ;
        STA AUDF1               ;
        LDA Sq1DivHi,X          ;
        STA AUDF2               ;
        LDA #$00                ;
        STA AUDC1               ;
        LDA ChVol               ;
        ORA #$A0                ;
        STA AUDC2               ;
        LDA ChVol+3             ;Channel 3: the noise while it sounds, else
        BEQ +                   ;SQ2.
        ORA #$80                ;
        STA AUDC3               ;
        LDX ChNote+3            ;
        LDA NoiseDiv,X          ;
        STA AUDF3               ;
        JMP ++                  ;
*       LDX ChNote+1            ;
        LDA Sq2Div,X            ;
        STA AUDF3               ;
        LDA ChVol+1             ;
        ORA #$A0                ;
        STA AUDC3               ;
*       LDX ChNote+2            ;Channel 4: the triangle.
        LDA TriDiv,X            ;
        STA AUDF4               ;
        LDA ChVol+2             ;
        ORA #$A0                ;
        STA AUDC4               ;
        RTS                     ;
