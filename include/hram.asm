
; Tracks which quarter of the working grid we're copying to the vram on the next VBlank
WorkingGridPartNumber EQU $ff80

; When this is 1, fast Update should not run. This protects it from interrupting itself,
; as well as allowing it to be turned off during special circumstances.
TimerUpdateLock EQU $ff81

; This counter increments every time TimerCounter overflows
; We set timer to 2^14 Hz, so this counter counts at 64Hz.
TimerCounterSlow EQU $ff82

; The currently loaded level index
LevelNumber EQU $ff83

; How many ticks in a row the level end condition has been met (to add delay before ending level)
LevelEndTickCount EQU $ff84

; Tracks current state of the RunStep method, which fast update uses to avoid some race cdns
; when interacting with temperature changes. State is one of:
; 0: Not running
; 1: Computing new temperatures. Temperature changes should be added to ActionsToDo
RunStepStateFlag EQU $ff85

; This tracks the value of the "tick number" (top 5 bits of TimerCounterSlow) at the time
; of the last slow tick. This is used to trigger a new slow tick at 8Hz.
; Note the initial value of 0, which says that game init "counts as" the first slow tick
; and the actual first slow tick happens 1/8th of a second later.
LastSlowTickNumber EQU $ff86

; Flag to indicate to main loop that you should end the title screen
EndTitleScreenFlag EQU $ff87

; Player actions to perform at the end of current update step.
; An array of 4 lots of following struct:
;   16-bit: block index. $ffff indicates not used.
;   8-bit signed: delta temperature
ActionsToDo EQU $ff88 ; first available after = ff89 + 4*3 = ff94

; Last frame of input, to diff with this frame to detect presses
LastInput EQU $ff94
