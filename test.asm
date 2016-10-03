
Section "test level", ROM0

TestLevel:
	db $ff, $00, $00 ; high
	db $80, $00, $00 ; medium grass
	db $80, $00, $01 ; medium tree
	db $80, $00, $02 ; medium building
	db $40, $00, $00 ; low grass 1
	db $40, $00, $04 ; low grass 2
	db $40, $00, $01 ; low tree 1
	db $40, $00, $05 ; low tree 2
	db $40, $00, $09 ; low tree 3
	db $40, $00, $0d ; low tree 4
	db $40, $00, $02 ; low building
	db $00, $00, $00 ; burnt grass 1
	db $00, $00, $04 ; burnt grass 2
	db $00, $00, $01 ; burnt tree 1
	db $00, $00, $05 ; burnt tree 2
	db $00, $00, $09 ; burnt tree 3
	db $00, $00, $0d ; burnt tree 4
	db $00, $00, $02 ; burnt building
	db $00, $20, $00 ; normal grass 1
	db $00, $20, $04 ; normal grass 2
	db $00, $80, $01 ; normal tree 1
	db $00, $80, $05 ; normal tree 2
	db $00, $80, $09 ; normal tree 3
	db $00, $80, $0d ; normal tree 4
	db $00, $c0, $02 ; normal building
	db $00, $21, $00 ; lush grass 1
	db $00, $21, $04 ; lush grass 2
	db $00, $81, $01 ; lush tree 1
	db $00, $81, $05 ; lush tree 2
	db $00, $81, $09 ; lush tree 3
	db $00, $81, $0d ; lush tree 4
	db $00, $ff, $02 ; lush building
	db $60, $60, $01 ; normal tree on low fire
	db $60, $1f, $00 ; lush grass on low fire
	REPT (20*18-34)/2
	db $00, $10, $00 ; grass 1
	db $00, $10, $04 ; grass 2
	ENDR
EndTestLevel::
TestLevelSize EQU EndTestLevel - TestLevel

LoadTestLevel::
	ld BC, TestLevelSize
	ld HL, TestLevel
	ld DE, Level
.loop
	ld A, [HL+] ; also increments HL
	ld [DE], A
	inc DE
	dec BC
	xor A
	cp C
	jr nz, .loop
	cp B
	jr nz, .loop
	ret
