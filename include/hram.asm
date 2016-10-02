
; Tracks which quarter of the working grid we're copying to the vram on the next VBlank
WorkingGridPartNumber EQU $ff80

; Set to 1 when timer fires, used by the main loop to wait until timer has fired
TimerFired EQU $ff81
