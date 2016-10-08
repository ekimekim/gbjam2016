
INCLUDE "hram.asm"

; Warning: each of these sections can only be 8b long!
section "Restart handler 0", ROM0 [$00]
Restart0::
	jp HaltForever
section "Restart handler 1", ROM0 [$08]
Restart1::
	jp HaltForever
section "Restart handler 2", ROM0 [$10]
Restart2::
	jp HaltForever
section "Restart handler 3", ROM0 [$18]
Restart3::
	jp HaltForever
section "Restart handler 4", ROM0 [$20]
Restart4::
	jp HaltForever
section "Restart handler 5", ROM0 [$28]
Restart5::
	jp HaltForever
section "Restart handler 6", ROM0 [$30]
Restart6::
	jp HaltForever
section "Restart handler 7", ROM0 [$38]
Restart7::
	jp HaltForever

; Warning: each of these sections can only be 8b long!
section "VBlank Interrupt handler", ROM0 [$40]
; triggered upon VBLANK period starting
IntVBlank::
	jp Draw
section "LCDC Interrupt handler", ROM0 [$48]
; Also known as STAT handler
; LCD controller changed state
IntLCDC::
	reti
section "Timer Interrupt handler", ROM0 [$50]
; A configurable amount of time has passed
IntTimer::
	jp TimerHandler
section "Serial Interrupt handler", ROM0 [$58]
; Serial transfer is complete
IntSerial::
	reti
section "Joypad Interrupt handler", ROM0 [$60]
; Change in joystick state?
IntJoypad::
	reti

section "Header Unused Area", ROM0 [$68]
; I'm going to use this space for some very core util functions
HaltForever::
	halt
	; halt can be recovered from after an interrupt or reset, so halt again
	jp HaltForever

; Timer handler is long-running, so we allow other interrupts to interrupt us.
; We use a flag in HRAM to avoid running if we're already running.
TimerHandler::
	push AF
	push BC
	push DE
	push HL

	; increment slow counter
	ld A, [TimerCounterSlow]
	inc A
	ld [TimerCounterSlow], A

	; if we aren't already inside Update, call Update
	ld A, [TimerUpdateLock]
	and A
	jr nz, .alreadyRunning

	; set the flag so we can't call again
	; note there's no race between checking and setting TimerUpdateLock because we have interrupts disabled
	ld A, 1
	ld [TimerUpdateLock], A

	; It's now safe to enable interrupts for the duration of Update
	EI
	call Update
	DI

	; now that we've disabled interrupts again, we can safely unset the flag
	xor A
	ld [TimerUpdateLock], A

.alreadyRunning

	pop HL
	pop DE
	pop BC
	pop AF
	reti

section "Header", ROM0 [$100]
; This must be nop, then a jump, then blank up to 150
_Start:
	nop
	jp Start
_Header::
	ds 76 ; Linker will fill this in
