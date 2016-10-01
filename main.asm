
section "Main", ROM0

Start::
	; Actual execution starts here
	ld HL, $8000
	ld  [HL], $f0
	
	jp HaltForever
