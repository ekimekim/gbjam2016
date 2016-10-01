
; Tile map is a array 0 to 255 of 16-byte tile images from $8000-$8fff
; Alt tile map is a array -128 to 127 from $8800-$97ff (0 is at $9000)
; You can switch whether the background map uses TileMap or AltTileMap using LCDC register
; Here we define the base, the overlapping region, and the start of the non-overlapping alt part
BaseTileMap EQU $8000
OverlapTileMap EQU $8800
AltTileMap EQU $9000
; Background map is 32x32 grid of tile numbers from $9800-$9bff
; It can be scrolled using scroll registers.
Background EQU $9800
; Window map is 32x32 grid of tile numbers that may overlay the background
; starting from coordinates controlled by window registers
Window EQU $9c00
