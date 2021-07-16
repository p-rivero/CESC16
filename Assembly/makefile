target = ROM.asm

filename = out
output = $(filename).hex
output_bin = $(filename).bin

temporary = temp.preprocessed

preprocess = cpp -x assembler-with-cpp -include CESC16.cpu -nostdinc -CC -undef -P $(1) > $(temporary)
remove = rm -f $(temporary)

assemble: customasm.exe
	$(call preprocess, $(target))
	./customasm.exe $(temporary) -p
	$(call remove)

sim: customasm.exe
	$(call preprocess, $(target))
	./customasm.exe $(temporary) -f logisim16 -o $(temporary)
	# start at line 2 (remove first line with text "v2.0 raw"). This workaround may need to be removed in the future
	tail -n +2 $(temporary) > $(output)
	$(call remove)

file: Tools/hex2bin sim
	./Tools/hex2bin $(output) > $(output_bin)

rom: customasm.exe
	$(call preprocess, $(target))
	./customasm.exe $(temporary) -o $(output)
	$(call remove)

symbols: Tools/GenerateSymbols
	$(call preprocess, OS/UTILS.asm)
	./customasm.exe $(temporary) -s $(temporary)
	./Tools/GenerateSymbols < $(temporary) > OS/symbols.inc
	$(call remove)

Tools/GenerateSymbols: Tools/GenerateSymbols.cc
	g++ -O -o Tools/GenerateSymbols Tools/GenerateSymbols.cc

Tools/hex2bin: Tools/hex2bin.cc
	g++ -O -o Tools/hex2bin Tools/hex2bin.cc
