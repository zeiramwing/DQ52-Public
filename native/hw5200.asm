;Atari 5200 hardware registers and BIOS RAM vectors.

;--------------------------------------[GTIA, $C000]-------------------------------------------------

.alias HPOSP0           $C000   ;Player 0-3 horizontal positions.
.alias HPOSP1           $C001   ;
.alias HPOSP2           $C002   ;
.alias HPOSP3           $C003   ;
.alias TRIG0            $C010   ;Controller 1 lower fire button (read).
.alias COLPM0           $C012   ;Player 0-3 colors.
.alias COLPM1           $C013   ;
.alias COLPM2           $C014   ;
.alias COLPM3           $C015   ;
.alias COLPF0           $C016   ;Playfield 0-3 colors.
.alias COLPF1           $C017   ;
.alias COLPF2           $C018   ;
.alias COLPF3           $C019   ;
.alias COLBK            $C01A   ;Background color.
.alias PRIOR            $C01B   ;Priority and GTIA modes.
.alias GRACTL           $C01D   ;Graphics control.
.alias CONSOL           $C01F   ;Console speaker / controller select.

;--------------------------------------[ANTIC, $D400]------------------------------------------------

.alias DMACTL           $D400   ;DMA control.
.alias CHACTL           $D401   ;Character control.
.alias DLISTL           $D402   ;Display list pointer, lower byte.
.alias DLISTH           $D403   ;Display list pointer, upper byte.
.alias HSCROL           $D404   ;Horizontal fine scroll.
.alias VSCROL           $D405   ;Vertical fine scroll.
.alias PMBASE           $D407   ;Player/missile base page.
.alias CHBASE           $D409   ;Character set base page.
.alias WSYNC            $D40A   ;Wait for horizontal sync.
.alias VCOUNT           $D40B   ;Vertical line counter / 2.
.alias NMIEN            $D40E   ;NMI enable.
.alias NMIRES           $D40F   ;NMI reset (write) / NMIST status (read).

;--------------------------------------[POKEY, $E800]------------------------------------------------

.alias POT0             $E800   ;Controller 1 horizontal pot (read).
.alias POT1             $E801   ;Controller 1 vertical pot (read).
.alias AUDF1            $E800   ;Audio channel 1-4 frequency and control (write).
.alias AUDC1            $E801   ;
.alias AUDF2            $E802   ;
.alias AUDC2            $E803   ;
.alias AUDF3            $E804   ;
.alias AUDC3            $E805   ;
.alias AUDF4            $E806   ;
.alias AUDC4            $E807   ;
.alias AUDCTL           $E808   ;Audio control (write) / ALLPOT (read).
.alias KBCODE           $E809   ;Keypad code (read).
.alias POTGO            $E80B   ;Start a pot scan (write).
.alias IRQEN            $E80E   ;IRQ enable (write) / IRQST (read).
.alias SKCTL            $E80F   ;Serial port and keypad control (write).
.alias SKSTAT           $E80F   ;Bit 3 = 0: top fire button. Bit 2 = 0: keypad key down (read).

;--------------------------------------[BIOS RAM vectors]--------------------------------------------

.alias VIMIRQ           $0200   ;Immediate IRQ. BRK arrives here with the stack untouched.
.alias VVBLKI           $0202   ;Immediate vertical blank NMI.
.alias VVBLKD           $0204   ;Deferred vertical blank NMI.
.alias VDSLST           $0206   ;Display list interrupt.
.alias VKEYBD           $0208   ;Keypad IRQ.
.alias VKEYPD           $020A   ;Keypad continuation.
.alias BRKKY            $020C   ;Break key IRQ.
.alias VBREAK           $020E   ;BRK instruction (unused: BRK goes through VIMIRQ).
.alias VSERIN           $0210   ;Serial input ready.
.alias VSEROR           $0212   ;Serial output ready.
.alias VSEROC           $0214   ;Serial output complete.
.alias VTIMR1           $0216   ;POKEY timer 1-4.
.alias VTIMR2           $0218   ;
.alias VTIMR4           $021A   ;

;--------------------------------------[SuperCart bank switching]------------------------------------

.alias SuperCartHi      $BFC0   ;512KB SuperCart, 16 banks of 32KB at $4000-$BFFF:
.alias SuperCartLo      $BFD0   ;reading $BFC0 + (bank AND $0C) selects the bank
                                ;number's upper 2 bits, $BFD0 + (bank AND 3) * 4
                                ;its lower 2; reading $BFE0-$BFFF (the BIOS
                                ;reads the header there) selects bank 15.
