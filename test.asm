
Section "test level", ROM0

; example tile map
TileHighFire EQU 0
TileMediumFire EQU 1
TileLowFire EQU 4
TileBurnt EQU 20
TileNormal EQU 36
TileLush EQU 52
; 0: High fire
; 1: Grass medium fire
; 2: Tree medium fire
; 3: Building medium fire
; 4: low fire grass 1
; 5: low fire tree 1
; 6: low fire building
; 7: unused (t4v1)
; 8: low fire grass 2
; 9: low fire tree 2
; 10: unused (building v2)
; 11: unused (t4v2)
; 12: unused (grass v3)
; 13: low fire tree 3
; 14: unused (building v3)
; 15: unused (t4v3)
; 16: unused (grass v4)
; 17: low fire tree 4
; 18: unused (building v4)
; 19: unused (t4v4)
; 20: burnt grass 1
; 21: burnt tree 1
; 22: burnt building
; 23: unused (t4v1)
; 24: burnt grass 2
; 25: burnt tree 2
; 26: unused (building v2)
; 27: unused (t4v2)
; 28: unused (grass v3)
; 29: burnt tree 3
; 30: unused (building v3)
; 31: unused (t4v3)
; 32: unused (grass v4)
; 33: burnt tree 4
; 34: unused (building v4)
; 35: unused (t4v4)
; 36: normal grass 1
; 37: normal tree 1
; 38: normal building
; 39: unused (t4v1)
; 40: normal grass 2
; 41: normal tree 2
; 42: unused (building v2)
; 43: unused (t4v2)
; 44: unused (grass v3)
; 45: normal tree 3
; 46: unused (building v3)
; 47: unused (t4v3)
; 48: unused (grass v4)
; 49: normal tree 4
; 50: unused (building v4)
; 51: unused (t4v4)
; 52: lush grass 1
; 53: lush tree 1
; 54: lush building
; 55: unused (t4v1)
; 56: lush grass 2
; 57: lush tree 2
; 58: unused (building v2)
; 59: unused (t4v2)
; 60: unused (grass v3)
; 61: lush tree 3
; 62: unused (building v3)
; 63: unused (t4v3)
; 64: unused (grass v4)
; 65: lush tree 4
; 66: unused (building v4)
; 67: unused (t4v4)

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
EndTestLevel:

LoadTestLevel::
	ld HL, TestLevel
	ld DE, Level
.loop
	ld A, [HL]
	ld [DE], A
	sub HL, EndTestLevel
	ld BC, HL
	add HL, EndTestLevel
	xor A
	cp C
	jr nz .loop
	cp B
	jr nz .loop
	ret
