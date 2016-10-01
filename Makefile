
# avoid implicit rules for clarity
.SUFFIXES: .asm .o .gb

%.o: %.asm
	rgbasm -v -o $@ $^

game.gb: *.o
	rgblink -n game.sym -o $@ $^
	rgbfix $@
