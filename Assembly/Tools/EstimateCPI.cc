#include <iostream>
#include <cassert>
using namespace std;

// Given some assembled CESC16 code, this small program attempts to estimate the true average CPI of
// the architecture by computing the mean of the provided code. This approach is flawed, since
// it ignores the effects of loops, but at least it's better than just blindly guessing.

const uint8_t MEMORY_CPI[8] = {
    3,  // lw
    3,  // lb
    4,  // sw
    5,  // swap
    3,  // peek (W=0)
    3,  // peek (W=1)
    3,  // push
    3   // pop
};
const uint8_t STACK_CPI[4] = {
    4,  // call
    3,  // ret
    3,  // pushf
    3   // popf
};

uint8_t get_clocks(uint8_t opcode) {
    if (opcode < 0b0010000) return 3;   // ALU operation (register or immediate modes)
    if (opcode < 0b0110000) return 4;   // ALU operation (direct or indirect modes)
    if (opcode < 0b1100000) return (opcode & 0b1111) + 1;       // Bit shift
    if (opcode < 0b1101000) return MEMORY_CPI[opcode-0b1100000];    // Memory operation
    if (opcode < 0b1111000) return 2;   // Jump
    if (opcode < 0b1111100) return STACK_CPI[opcode-0b1111000];     // Stack operation
    cout << "INVALID OPCODE! 0x" << hex << int(opcode) << endl;
    exit(EXIT_FAILURE);
}

int main() {
    uint16_t opcode, argument;
    unsigned long long int instructions = 0;
    unsigned long long int cycles = 0;
    while (cin >> hex >> opcode) {
        assert(cin >> hex >> argument); // Make sure the instruction was followed by an argument
        instructions++;
        cycles += get_clocks(opcode >> 8);
    }
    if (instructions == 0) cout << "No instructions provided!" << endl;
    else cout << "Average CPI: " << double(cycles)/double(instructions) << " (" << instructions << " instructions)" << endl;
}
