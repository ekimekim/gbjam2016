
section "Restart handler table", ROM0 [$00]
	Restart0::
		ds 8
	Restart1::
		ds 8
	Restart2::
		ds 8
	Restart3::
		ds 8
	Restart4::
		ds 8
	Restart5::
		ds 8
	Restart6::
		ds 8
	Restart7::
		ds 8

section "Interrupt handler table", ROM0 [$40]
	IntVBlank::
		; triggered upon VBLANK period starting
		ds 8
	IntLCDC::
		; LCD controller changed state
		ds 8
	IntTimer::
		; A configurable amount of time has passed
		ds 8
	IntSerial::
		; Serial transfer is complete
		ds 8
	IntJoypad::
		; Change in joystick state?
		ds 8

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
