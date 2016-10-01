
; "P1" Joypad input/output. Bits 6 and 7 are unused (count low to high, so bit 7 is 128)
; Bits 4 and 5 are written to to "select" one of two lines.
; When bit 4 is set to 0, the bits 0-3 are: Right, Left, Up, Down
; When bit 5 is set to 0, the bits 0-3 are: A, B, Select, Start
; It takes "a few cycles" between setting the bits and getting results.
; Result bits are 0 if the button is pressed, else 1
JoyIO EQU $ff00
JoySelectDPad EQU $20
JoySelectButtons EQU $10

; "SB" Serial transfer data
SerialData EQU $ff01
; "SC" Serial control
SerialControl EQU $ff02

; "DIV" fixed timer register. Incremented every ~610us (2^14 Hz)
; Write any value to set it to 0
DivTimer EQU $ff04

; "TIMA" Timer counter register. Incremented at a variable frequency (see TAC)
; When it overflows (increments from $ff), a Timer interrupt fires.
; After overflowing, its value is set to the value at TimerModulo.
; Can be set manually.
TimerCounter EQU $ff05
; "TMA" Timer modulo register. When TimerCounter overflows, it sets set to this value.
; By setting this value, you can fine tune the timer counter overflow frequency.
TimerModulo EQU $ff06
; "TAC" Timer control register. Set this to control the timer.
; Bits 3-7 are unused. Bit 2 enables the timer when set, disables it when unset.
; Bits 0-1 are a 2-bit number where the values 0-3 mean timer frequencies
; 2^12 Hz, 2^18 Hz, 2^16 Hz and 2^14 Hz respectively.
TimerControl EQU $ff07

; "IF" Interrupt flag register. The hardware will set a bit in this register when an interrupt
; would be generated, even if interrupts are currently disabled. Bits respectively refer to
; VBlank, LCDC, Timer, Serial and Joystick interrupts.
InterruptFlags EQU $ff0f

; $ff10 - $ff3f are sound registers, which I'm not gonna touch.

; "LCDC" LCD control register. Defaults to $91. Write to these bits to control the display mode:
; 0: Background and Window display off/on
; 1: Sprite display off/on
; 2: Sprite size (width x height): 8x8 if unset, 8x16 if set
; 3: Background Tile grid region select: 0 for TileGrid, 1 for AltTileGrid
; 4: Background and Window tile map mode select: 0 for unsigned, 1 for signed.
;    Note Sprites always use unsigned.
; 5: Window display off/on
; 6: Window Tile grid region select: 0 for TileGrid, 1 for AltTileGrid
; 7: Global display enable/disable: 0 to turn off screen, 1 to turn on
; Default value $91 = %10010001 = enabled display, signed tile map, background only
LCDControl EQU $ff40
