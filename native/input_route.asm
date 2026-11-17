;Controller input for measurement builds (main.asm includes it as
;input.asm): Stick = the directions of a fixed route; at its end the
;program parks, for run5200.py.
ReadInput:
        LDA Moving              ;Read once a step, when it can start.
        BEQ RouteNext           ;
        RTS                     ;
RouteNext:
        LDA RouteLeft           ;
        BNE +                   ;
        LDX RouteAt             ;Next route entry.
        LDA Route+1,X           ;
        BEQ RouteDone           ;
        STA RouteLeft           ;
*       LDX RouteAt             ;
        LDA Route,X             ;
        STA Stick               ;
        DEC RouteLeft           ;
        BNE +                   ;
        INX                     ;
        INX                     ;
        STX RouteAt             ;
*       RTS                     ;
RouteDone:
        JMP Parked              ;

;The measurement route (on the overworld from (43,44), clear of Tantegel's
;block at (43,43)): directions held (1 up, 2 right, 4 down, 8 left)
;and steps, ending with 0 steps.
Route:
        .byte $08, 10, $01, 8, $02, 10, $04, 6, $08, 6, $01, 4, $00, 0

;The keypad's Reset: nothing to keep here.
ResetHook:
        RTS                     ;
