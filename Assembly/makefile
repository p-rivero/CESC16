output = out.hex
temporary = temp.preprocessed
target = ROM.asm

preprocess = cpp -x assembler-with-cpp -nostdinc -CC -undef -P $(1) > $(temporary)
remove = rm -f $(temporary)

assemble: customasm.exe
	$(call preprocess, $(target))
	./customasm.exe $(temporary) -p
	$(call remove)

sim: customasm.exe
	$(call preprocess, $(target))
	./customasm.exe $(temporary) -f logisim16 -p
	$(call remove)

file: customasm.exe
	$(call preprocess, $(target))
	./customasm.exe $(temporary) -f logisim16 -o $(temporary)
	# start at line 2 (remove first line with text "v2.0 raw"). This workaround may need to be removed in the future
	tail -n +2 $(temporary) > $(output)
	$(call remove)

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