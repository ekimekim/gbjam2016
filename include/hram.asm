
; Tracks which quarter of the working grid we're copying to the vram on the next VBlank
WorkingGridPartNumber EQU $ff80

; Whether the update interrupt is currently running. This prevents it from interrupting itself.
TimerUpdateIsRunning EQU $ff81

; This counter increments every time TimerCounter overflows
; We set timer to 2^14 Hz, so this counter counts at 64Hz.
TimerCounterSlow EQU $ff82

; The currently loaded level index
LevelNumber EQU $ff83

; How many ticks in a row the level end condition has been met (to add delay before ending level)
LevelEndTickCount EQU $ff84
