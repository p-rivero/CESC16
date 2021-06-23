// Simple utility program for converting from HEX format (readable by the simulator and emulator) to BIN format (readable by the FLASH programmer)

#include <iomanip>

#include <iostream>
#include <fstream>
#include <vector>
#include <cstdio>
#include <cstdlib>
#include <cstdint>
#include <cassert>
#include <cstdarg>
#include <ciso646> // Include this so vscode doesn't complain about alternative logical operators

using word = uint16_t;

word ROM[0x2000];

void fatal_error(const char* format, ...) {
    // Print error message
    va_list args;
    va_start(args, format);
    vfprintf(stderr, format, args);
    va_end (args);
    fprintf(stderr, "\n");
    exit(EXIT_FAILURE);
}

int main(int argc, char **argv) {
    if (argc == 1) fatal_error("No argument was provided. The first and only argument should be the HEX file");
    std::ifstream hex_file(argv[1], std::fstream::in);
    if (not hex_file) fatal_error("Error: ROM file [%s] could not be found/opened", argv[1]);

    uint32_t address = 0;
    word in;
    while (hex_file >> std::hex >> in) {
        ROM[address++] = in;

        // File too large for 16 bits of address space
        if (address > 0x1FFFF) fatal_error("Error: ROM file is too large");
    }

    // Make sure there is no leftover input
    if (not hex_file.eof()) fatal_error("Error: make sure the ROM file is a valid hex file");
    hex_file.close();
    

    for (uint32_t i = 0; i < address; i++)
        std::cout << char(ROM[i]);
    
    for (uint32_t i = address; i < 0x20000; i++)
        std::cout << char(-1);
    
    for (uint32_t i = 0; i < address; i++)
        std::cout << char(ROM[i]>>8);
}
