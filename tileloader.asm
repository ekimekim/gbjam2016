
INCLUDE "macros.asm"

Section "Tile Assets", ROMX, BANK[1]

TileMapData:
INCLUDE "assets.asm"
EndTileMapData:

TileMapDataSize EQU EndTileMapData - TileMapData

Section "Tile Loading methods", ROMX, BANK[1]

; Copies tile data into vram. Make sure you can write to vram.
LoadTileData::
	ld HL, TileMapData
	ld DE, BaseTileMap
	ld BC, TileMapDataSize
	LongCopy ; copy BC bytes from [HL] to [DE]
	ret
