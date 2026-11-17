;Controller input for test builds (main.asm includes it as input.asm):
;Stick and Buttons from a script of entries of 3 bytes: frames, directions,
;buttons; 0 frames ends it, and the program parks, for run5200.py. The
;script is in MSG_BANK at SCRIPT_AT (build.py puts it there, out of the
;program's room), read through ScriptPtr, any length.
.alias ScriptPtr        $7C     ;2: the entry being played.
.alias ResetPtr         $3FF0   ;2: kept over the keypad's Reset (RAM not cleared
.alias ResetMark        $3FF2   ;at boot), and RESET_MAGIC there while it is.
.alias RESET_MAGIC      $A5     ;

ReadInput:
        LDA CurBank             ;(The bank in, kept.)
        PHA                     ;
        JSR SelectMsg           ;
        LDA ScriptPtr+1         ;The first: the script's start (or, after
        BNE ScriptStartNext     ;the keypad's Reset, the entry after it's).
        LDA ResetMark           ;
        CMP #RESET_MAGIC        ;
        BNE ScriptStart         ;
        LDA #$00                ;
        STA ResetMark           ;
        LDA ResetPtr            ;
        STA ScriptPtr           ;
        LDA ResetPtr+1          ;
        STA ScriptPtr+1         ;
        BNE +                   ;
ScriptStart:
        LDA #<SCRIPT_AT         ;
        STA ScriptPtr           ;
        LDA #>SCRIPT_AT         ;
        STA ScriptPtr+1         ;
ScriptStartNext:
*       LDY #$00                ;
        LDA RouteLeft           ;
        BNE +                   ;
        LDA (ScriptPtr),Y       ;Next entry.
        BEQ ScriptDone          ;
        STA RouteLeft           ;
*       INY                     ;
        LDA (ScriptPtr),Y       ;
        STA Stick               ;
        INY                     ;
        LDA (ScriptPtr),Y       ;(Its high half: a keypad key.)
        TAX                     ;
        AND #$03                ;
        STA Buttons             ;
        TXA                     ;
        LSR                     ;
        LSR                     ;
        LSR                     ;
        LSR                     ;
        STA Key                 ;
        DEC RouteLeft           ;
        BNE +                   ;
        LDA ScriptPtr           ;
        CLC                     ;
        ADC #$03                ;
        STA ScriptPtr           ;
        BCC +                   ;
        INC ScriptPtr+1         ;
*       PLA                     ;
        JMP SelectBank          ;
ScriptDone:
        PLA                     ;
        JMP Parked              ;

;The keypad's Reset (main.asm, before it starts the cartridge again): the
;script goes on from the entry after the Reset's.
ResetHook:
        LDA ScriptPtr           ;
        CLC                     ;
        ADC #$03                ;
        STA ResetPtr            ;
        LDA ScriptPtr+1         ;
        ADC #$00                ;
        STA ResetPtr+1          ;
        LDA #RESET_MAGIC        ;
        STA ResetMark           ;
        RTS                     ;
