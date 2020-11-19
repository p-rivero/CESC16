output = out.hex
temporary = temp.preprocessed
assemble: customasm.exe ROM.asm
	cpp -x assembler-with-cpp -nostdinc -CC -undef -P ROM.asm > $(temporary)
	./customasm.exe $(temporary) -p
	rm -f $(temporary)

sim: customasm.exe ROM.asm
	cpp -x assembler-with-cpp -nostdinc -CC -undef -P ROM.asm > $(temporary)
	./customasm.exe $(temporary) -f logisim16 -p
	rm -f $(temporary)

file: customasm.exe ROM.asm
	cpp -x assembler-with-cpp -nostdinc -CC -undef -P ROM.asm > $(temporary)
	./customasm.exe $(temporary) -f logisim16 -o $(output)
	rm -f $(temporary)

rom: customasm.exe ROM.asm
	cpp -x assembler-with-cpp -nostdinc -CC -undef -P ROM.asm > $(temporary)
	./customasm.exe $(temporary) -o $(output)
	rm -f $(temporary)
