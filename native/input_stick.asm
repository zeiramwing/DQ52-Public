;Controller input for play builds (main.asm includes it as input.asm):
;Stick = the directions held on the analog stick, bit 0 up, 1 right,
;2 down, 3 left; Buttons = the fire buttons held, BTN_A the lower,
;BTN_B the upper; Key = the keypad key held (KBCODE bits 1-4: 0 none).
ReadInput:
        LDA #$00                ;
        STA Stick               ;
        STA Buttons             ;
        STA Key                 ;
        LDA SKSTAT              ;Bit 2 = 0: a keypad key down.
        AND #$04                ;
        BNE +                   ;
        LDA KBCODE              ;
        LSR                     ;
        AND #$0F                ;
        STA Key                 ;
*
        LDA TRIG0               ;0: the lower fire button pressed.
        BNE +                   ;
        LDA #BTN_A              ;
        STA Buttons             ;
*       LDA SKSTAT              ;Bit 3 = 0: the upper one.
        AND #$08                ;
        BNE +                   ;
        LDA #BTN_B              ;
        ORA Buttons             ;
        STA Buttons             ;
*       LDA PotY                ;Vertical: about 1 (up) to 228 (down); 0
        BEQ StickDone           ;before the first scan is done: none yet.
        CMP #$50                ;
        BCS +                   ;
        LDA #$01                ;
        STA Stick               ;
*       LDA PotY                ;
        CMP #$A0                ;
        BCC +                   ;
        LDA #$04                ;
        ORA Stick               ;
        STA Stick               ;
*       LDA PotX                ;Horizontal: about 1 (left) to 228 (right).
        BEQ StickDone           ;
        CMP #$50                ;
        BCS +                   ;
        LDA #$08                ;
        ORA Stick               ;
        STA Stick               ;
*       LDA PotX                ;
        CMP #$A0                ;
        BCC +                   ;
        LDA #$02                ;
        ORA Stick               ;
        STA Stick               ;
*
StickDone:
        RTS                     ;
