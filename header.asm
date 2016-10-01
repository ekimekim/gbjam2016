
; Warning: each of these sections can only be 8b long!
section "Restart handler 0", ROM0 [$00]
Restart0::
	jp Halt
section "Restart handler 0", ROM0 [$08]
Restart1::
	jp Halt
section "Restart handler 0", ROM0 [$10]
Restart2::
	jp Halt
section "Restart handler 0", ROM0 [$18]
Restart3::
	jp Halt
section "Restart handler 0", ROM0 [$20]
Restart4::
	jp Halt
section "Restart handler 0", ROM0 [$28]
Restart5::
	jp Halt
section "Restart handler 0", ROM0 [$30]
Restart6::
	jp Halt
section "Restart handler 0", ROM0 [$38]
Restart7::
	jp Halt

; Warning: each of these sections can only be 8b long!
section "VBlank Interrupt handler", ROM0 [$40]
; triggered upon VBLANK period starting
IntVBlank::
	reti
section "LCDC Interrupt handler", ROM0 [$48]
; Also known as STAT handler
; LCD controller changed state
IntLCDC::
	reti
section "Timer Interrupt handler", ROM0 [$50]
; A configurable amount of time has passed
IntTimer::
	reti
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
Halt::
	halt
	; halt can be recovered from after an interrupt or reset, so halt again
	jp Halt

section "Header", ROM0 [$100]
; This must be nop, then a jump, then blank up to 150
_Start:
	nop
	jp Start
_Header::
	; Linker will fill this in
	ds $150 - _Header

Start::
	; Actual execution starts here
	jp Halt
