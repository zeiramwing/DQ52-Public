;Controller input for test builds (main.asm includes it as input.asm):
;Stick and Buttons from a script of entries of 3 bytes: frames, directions,
;buttons; 0 frames ends it, and the program parks, for run5200.py. The
;script is in MSG_BANK at SCRIPT_AT (build.py puts it there, out of the
;program's room), read through ScriptPtr, any length.
.alias ScriptPtr        $7C     ;2: the entry being played.

ReadInput:
        LDA CurBank             ;(The bank in, kept.)
        PHA                     ;
        LDA #MSG_BANK           ;
        JSR SelectBank          ;
        LDA ScriptPtr+1         ;The first: the script's start.
        BNE +                   ;
        LDA #<SCRIPT_AT         ;
        STA ScriptPtr           ;
        LDA #>SCRIPT_AT         ;
        STA ScriptPtr+1         ;
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
