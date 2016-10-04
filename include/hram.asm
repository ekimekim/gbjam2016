
; Tracks which quarter of the working grid we're copying to the vram on the next VBlank
WorkingGridPartNumber EQU $ff80

; Whether the update interrupt is currently running. This prevents it from interrupting itself.
TimerUpdateIsRunning EQU $ff81

TimerCounterSlow EQU $ff82
