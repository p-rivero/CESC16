#include <iostream>
#include <iomanip>
#include <fstream>
#include <vector>
#include <string>
#include <assert.h>
#include <ciso646> // Include this so vscode doesn't complain about alternative logical operators
using namespace std;


// CONTROL SIGNALS
#define CLR             0x000001    // Clear microcode counter (start next instruction) [ACTIVE LOW]
#define Dout0           0x000002    // Output select (data/main bus):
#define Dout1           0x000004    //     000 = No output,  001 = ALU,  010 = ALU (Shifted),  011 = Memory
#define Dout2           0x000008    //     100 = PC,  101 = IR,  110 = Flags,  111 = Constant 0x0011
#define AddrOut0        0x000010    // Output select (address bus):
#define AddrOut1        0x000020    //     00 = No output,  01 = PC,  10 = ALU,  11 = SP
#define Bank0           0x000040    // Memory bank select:
#define Bank1           0x000080    //     00 = Opcode,  01 = Argument,  10 = RAM (Data and Stack),  11 = RAM (Sign extended)

#define TglRun          0x000100    // TODO: Toggle run mode (fetch from ROM or RAM)
#define SPpp            0x000200    // Increment Stack Pointer (SP-- if AluS3 = 1) [ACTIVE LOW]
#define PCpp            0x000400    // Increment Program Counter (and load Instruction Register)
#define MemIn           0x000800    // Memory (RAM) in
#define PcIn            0x001000    // Program Counter in (Jump) [ACTIVE LOW]
#define LdReg           0x002000    // Load Register (rD) [ACTIVE LOW]
#define LdX             0x004000    // Load temporary register X [ACTIVE LOW]
#define LdY             0x008000    // Load temporary register Y [ACTIVE LOW]

#define LdImm           0x010000    // Load Immediate to temp register
#define LdFlg           0x020000    // Load flags register [ACTIVE LOW]
#define AluM            0x040000    // Mode input for 74HC181 ALU
#define AluS0           0x080000    // Select input 0 for 74HC181 ALU
#define AluS1           0x100000    // Select input 1 for 74HC181 ALU
#define AluS2           0x200000    // Select input 2 for 74HC181 ALU
#define AluS3           0x400000    // Select input 3 for 74HC181 ALU
#define AluCIn          0x800000    // Carry In input for 74HC181 ALU

// Selective inverter for active low lines
const uint32_t ACTIVE_LOW_MASK = CLR | SPpp | LdReg | LdX | LdY | LdFlg | PcIn;



// COMMONLY USED SIGNAL COMBINATIONS
#define AluOutD     Dout0               // ALU -> Data Bus
#define AluShOut    Dout1               // ALU[>>] -> Data Bus

#define MemOut      Dout1|Dout0         // MEM -> Data Bus
#define PcOutD      Dout2               // PC -> Data Bus
#define IrOut       Dout2|Dout0         // IR -> Data Bus
#define FlagsOut    Dout2|Dout1         // Flags -> Data Bus
#define ConstOut    Dout2|Dout1|Dout0   // Constant 0x0011 -> Data Bus

#define PcOutAddr   AddrOut0            // PC -> MAR
#define AluOutAddr  AddrOut1            // ALU -> MAR

#define IrIn        PCpp                // PCpp also loads Instruction Register
#define SPmm        SPpp|AluS0          // SP--
#define LdFlgALU    LdFlg               // Generate flags from ALU
#define LdFlgBUS    LdFlg|LdImm         // Load flags from the main bus

#define Fetch       PCpp|MemOut|IrIn|LdX|LdY    // First timestep for all instructions
#define ArgBk       Bank0                       // Argument bank (where instruction arguments are fetched)

// ALU OPERATIONS (from 74HC181 datasheet)
#define ALU_Y       AluM|AluS3|AluS1                // Output Y
#define ALU_X       AluM|AluS3|AluS2|AluS1|AluS0    // Output X
#define ALU_Xminus1 AluS3|AluS2|AluS1|AluS0|AluCIn  // Output X-1
#define ALU_and     AluM|AluS3|AluS1|AluS0
#define ALU_or      AluM|AluS3|AluS2|AluS1
#define ALU_xor     AluM|AluS2|AluS1
#define ALU_add     AluS3|AluS0|AluCIn  // Remove AluCIn for addc
#define ALU_sub     AluS2|AluS1         // Add AluCIn for subb

// Fill with 0s rest of timesteps
#define ZEROx8      0, 0, 0, 0, 0, 0, 0, 0
#define ZEROx11     0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
#define ZEROx12     0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
#define ZEROx13     0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
#define ZEROx14     0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0

// In case we are generating the microcode for instructions stored in RAM, there are some changes in instruction fetching
#ifdef RUN_FROM_RAM
    #undef ArgBk
    #define ArgBk       Bank1   // When fetching arguments, access RAM instead of lower bits of ROM
    #undef PcOutAddr
    #define PcOutAddr   AddrOut0|PCpp    // Loading the PC to MAR preincrements it (++PC -> MAR)
    #undef Fetch
    #define Fetch       PcOutAddr|MemOut|Bank1|IrIn|LdX|LdY    // Fetch is done from RAM and increments PC
#endif


// INSTRUCTIONS:
#define MOV_REG      Fetch,  ALU_X|AluOutD|LdReg|PcOutAddr|CLR,  ZEROx14
#define ALU_REG(OP)  Fetch,  MemOut|ArgBk|LdY,                   OP|AluOutD|LdReg|LdFlgALU|PcOutAddr|CLR,  ZEROx13

#define MOV_IMM      Fetch,  MemOut|ArgBk|LdReg|PcOutAddr|CLR,   ZEROx14
#define ALU_IMM(OP)  Fetch,  MemOut|ArgBk|LdImm|LdY,             OP|AluOutD|LdReg|LdFlgALU|PcOutAddr|CLR,  ZEROx13

#define MOV_DIRA     Fetch,  MemOut|ArgBk|LdImm|LdY|ALU_Y|AluOutAddr,    MemOut|Bank1|LdReg|PcOutAddr|CLR,  ZEROx13
#define ALU_DIRA(OP) Fetch,  MemOut|ArgBk|LdImm|LdY|ALU_Y|AluOutAddr,    MemOut|Bank1|LdImm|LdY,     OP|AluOutD|LdReg|LdFlgALU|PcOutAddr|CLR,     ZEROx12

#define MOV_INDA     Fetch,  MemOut|ArgBk|LdY|ALU_Y|AluOutAddr,    MemOut|Bank1|LdReg|PcOutAddr|CLR,  ZEROx13
#define ALU_INDA(OP) Fetch,  MemOut|ArgBk|LdY|ALU_Y|AluOutAddr,    MemOut|Bank1|LdImm|LdY,     OP|AluOutD|LdReg|LdFlgALU|PcOutAddr|CLR,     ZEROx12

#define MOV_DIRD     Fetch,  MemOut|ArgBk|LdImm|LdX|ALU_X|AluOutAddr,    ALU_Y|AluOutD|MemIn|Bank1|PcOutAddr|CLR,    ZEROx13
#define ALU_DIRD(OP) Fetch,  MemOut|ArgBk|LdImm|LdX|ALU_X|AluOutAddr,    MemOut|Bank1|LdImm|LdX,     OP|AluOutD|MemIn|Bank1|LdFlgALU|PcOutAddr|CLR,     ZEROx12

#define MOV_INDD     Fetch,  MemOut|ArgBk|LdY|ALU_X|AluOutAddr,  ALU_Y|AluOutD|MemIn|Bank1|PcOutAddr|CLR,    ZEROx13
#define ALU_INDD(OP) Fetch,  MemOut|ArgBk|LdY|ALU_X|AluOutAddr,  MemOut|Bank1|LdImm|LdX,     OP|AluOutD|MemIn|Bank1|LdFlgALU|PcOutAddr|CLR,     ZEROx12

#define SLL_STEP    ALU_add|AluOutD|LdImm|LdX|LdY
#define SLL_END     ALU_add|AluOutD|LdReg|LdFlgALU|PcOutAddr|CLR
#define SLL_STEP_4  SLL_STEP, SLL_STEP, SLL_STEP, SLL_STEP

#define SRL_STEP    ALU_X|AluShOut|LdImm|LdX
#define SRL_END     ALU_X|AluShOut|LdReg|LdImm|LdX|LdFlgALU|PcOutAddr|CLR
#define SRL_STEP_4  SRL_STEP, SRL_STEP, SRL_STEP, SRL_STEP

#define SRA_STEP    SRL_STEP|AluCIn     // AluCIn also changes from SRL to SRA
#define SRA_END     SRL_END|AluCIn
#define SRA_STEP_4  SRA_STEP, SRA_STEP, SRA_STEP, SRA_STEP


#define LOAD(Bank)  Fetch,  MemOut|ArgBk|LdImm|LdY|ALU_add|AluOutAddr,      MemOut|Bank|LdReg|PcOutAddr|CLR,    ZEROx13

#define STORE       Fetch,  MemOut|ArgBk|LdImm|LdY|ALU_add|AluOutAddr,      IrOut|LdY,      ALU_Y|AluOutD|MemIn|Bank1|PcOutAddr|CLR,    ZEROx12

#define SWAP        Fetch,  MemOut|ArgBk|LdImm|LdY|ALU_add|AluOutAddr,      IrOut|LdY,      MemOut|Bank1|LdReg,     ALU_Y|AluOutD|MemIn|Bank1|PcOutAddr|CLR,    ZEROx11

#define PUSH        Fetch,  SPmm|MemOut|ArgBk|LdY|ALU_Xminus1|AluOutAddr,   ALU_Y|AluOutD|MemIn|Bank1|PcOutAddr|CLR,    ZEROx13

#define POP         Fetch,  ALU_X|AluOutAddr,                               SPpp|MemOut|Bank1|LdReg|PcOutAddr|CLR,      ZEROx13

#define PUSHF       Fetch,  SPmm|ALU_Xminus1|AluOutAddr,                    FlagsOut|MemIn|Bank1|PcOutAddr|CLR,         ZEROx13

#define POPF        Fetch,  ALU_X|AluOutAddr,                               SPpp|MemOut|Bank1|LdFlgBUS|PcOutAddr|CLR,   ZEROx13

#define CALL        Fetch,  MemOut|ArgBk|LdImm|LdY|ALU_Xminus1|AluOutAddr,  SPmm|PcOutD|MemIn|Bank1,    ALU_Y|AluOutD|PcIn|AluOutAddr|CLR,  ZEROx12

#define RET         Fetch,  ALU_X|AluOutAddr,                               SPpp|MemOut|Bank1|PcIn|PcOutAddr|CLR,   ZEROx13

#define JMP_REG     Fetch,  ALU_X|AluOutD/*|PcIn*/|PcOutAddr|CLR,   ZEROx14

#define JMP_IMM     Fetch,  MemOut|ArgBk/*|PcIn*/|PcOutAddr|CLR,    ZEROx14

#define NOP         Fetch, PcOutAddr|CLR,   ZEROx14     // Only used for illegal instructions

// Jump to interrupt vector
const vector<uint32_t> JMP_INT = {ConstOut|LdX|ALU_Xminus1|AluOutAddr,  SPmm|PcOutD|MemIn|Bank1,    ConstOut|PcIn|PcOutAddr|CLR,    ZEROx13};


// 4 bit flags + 8 bit opcode + 4 bit timestep + 1 bit IRQ
const unsigned int SIZE = 16 * 256 * 16 * 2;
vector<uint32_t> content(SIZE);

// Size of template: 8 bit opcode + 4 bit timestep
const unsigned int TEMPL_SIZE = 256 * 16;
const vector<uint32_t> TEMPLATE = {
    // 00000FFF - ALU rD, rA, rB
    MOV_REG, ALU_REG(ALU_and), ALU_REG(ALU_or), ALU_REG(ALU_xor), ALU_REG(ALU_add), ALU_REG(ALU_sub), ALU_REG(ALU_add), ALU_REG(ALU_sub),

    // 00001FFF - ALU rD, rA, Imm16
    MOV_IMM, ALU_IMM(ALU_and), ALU_IMM(ALU_or), ALU_IMM(ALU_xor), ALU_IMM(ALU_add), ALU_IMM(ALU_sub), ALU_IMM(ALU_add), ALU_IMM(ALU_sub),

    // 0001iiii - sll rD, rA, Imm4
    NOP,    // Shift 0 positions
    Fetch,                                                          SLL_END, ZEROx14,   // Shift 1 position
    Fetch, SLL_STEP,                                                SLL_END, ZEROx13,   // Shift 2 positions
    Fetch, SLL_STEP, SLL_STEP,                                      SLL_END, ZEROx12,   // Shift 3 positions
    Fetch, SLL_STEP, SLL_STEP, SLL_STEP,                            SLL_END, ZEROx11,   // ...
    Fetch, SLL_STEP_4,                                              SLL_END, ZEROx8, 0, 0,
    Fetch, SLL_STEP_4, SLL_STEP,                                    SLL_END, ZEROx8, 0,
    Fetch, SLL_STEP_4, SLL_STEP, SLL_STEP,                          SLL_END, ZEROx8,
    Fetch, SLL_STEP_4, SLL_STEP, SLL_STEP, SLL_STEP,                SLL_END, 0, 0, 0, 0, 0, 0, 0,
    Fetch, SLL_STEP_4, SLL_STEP_4,                                  SLL_END, 0, 0, 0, 0, 0, 0,
    Fetch, SLL_STEP_4, SLL_STEP_4, SLL_STEP,                        SLL_END, 0, 0, 0, 0, 0,
    Fetch, SLL_STEP_4, SLL_STEP_4, SLL_STEP, SLL_STEP,              SLL_END, 0, 0, 0, 0,
    Fetch, SLL_STEP_4, SLL_STEP_4, SLL_STEP, SLL_STEP, SLL_STEP,    SLL_END, 0, 0, 0,
    Fetch, SLL_STEP_4, SLL_STEP_4, SLL_STEP_4,                      SLL_END, 0, 0,
    Fetch, SLL_STEP_4, SLL_STEP_4, SLL_STEP_4, SLL_STEP,            SLL_END, 0,
    Fetch, SLL_STEP_4, SLL_STEP_4, SLL_STEP_4, SLL_STEP, SLL_STEP,  SLL_END,            // Shift 15 positions

    // 0010iiii - srl rD, rA, Imm4
    NOP,    // Shift 0 positions
    Fetch,                                                          SRL_END, ZEROx14,   // Shift 1 position
    Fetch, SRL_STEP,                                                SRL_END, ZEROx13,   // Shift 2 positions
    Fetch, SRL_STEP, SRL_STEP,                                      SRL_END, ZEROx12,   // Shift 3 positions
    Fetch, SRL_STEP, SRL_STEP, SRL_STEP,                            SRL_END, ZEROx11,   // ...
    Fetch, SRL_STEP_4,                                              SRL_END, ZEROx8, 0, 0,
    Fetch, SRL_STEP_4, SRL_STEP,                                    SRL_END, ZEROx8, 0,
    Fetch, SRL_STEP_4, SRL_STEP, SRL_STEP,                          SRL_END, ZEROx8,
    Fetch, SRL_STEP_4, SRL_STEP, SRL_STEP, SRL_STEP,                SRL_END, 0, 0, 0, 0, 0, 0, 0,
    Fetch, SRL_STEP_4, SRL_STEP_4,                                  SRL_END, 0, 0, 0, 0, 0, 0,
    Fetch, SRL_STEP_4, SRL_STEP_4, SRL_STEP,                        SRL_END, 0, 0, 0, 0, 0,
    Fetch, SRL_STEP_4, SRL_STEP_4, SRL_STEP, SRL_STEP,              SRL_END, 0, 0, 0, 0,
    Fetch, SRL_STEP_4, SRL_STEP_4, SRL_STEP, SRL_STEP, SRL_STEP,    SRL_END, 0, 0, 0,
    Fetch, SRL_STEP_4, SRL_STEP_4, SRL_STEP_4,                      SRL_END, 0, 0,
    Fetch, SRL_STEP_4, SRL_STEP_4, SRL_STEP_4, SRL_STEP,            SRL_END, 0,
    Fetch, SRL_STEP_4, SRL_STEP_4, SRL_STEP_4, SRL_STEP, SRL_STEP,  SRL_END,            // Shift 15 positions

    // 0011iiii - srl rD, rA, Imm4
    NOP,    // Shift 0 positions
    Fetch,                                                          SRA_END, ZEROx14,   // Shift 1 position
    Fetch, SRA_STEP,                                                SRA_END, ZEROx13,   // Shift 2 positions
    Fetch, SRA_STEP, SRA_STEP,                                      SRA_END, ZEROx12,   // Shift 3 positions
    Fetch, SRA_STEP, SRA_STEP, SRA_STEP,                            SRA_END, ZEROx11,   // ...
    Fetch, SRA_STEP_4,                                              SRA_END, ZEROx8, 0, 0,
    Fetch, SRA_STEP_4, SRA_STEP,                                    SRA_END, ZEROx8, 0,
    Fetch, SRA_STEP_4, SRA_STEP, SRA_STEP,                          SRA_END, ZEROx8,
    Fetch, SRA_STEP_4, SRA_STEP, SRA_STEP, SRA_STEP,                SRA_END, 0, 0, 0, 0, 0, 0, 0,
    Fetch, SRA_STEP_4, SRA_STEP_4,                                  SRA_END, 0, 0, 0, 0, 0, 0,
    Fetch, SRA_STEP_4, SRA_STEP_4, SRA_STEP,                        SRA_END, 0, 0, 0, 0, 0,
    Fetch, SRA_STEP_4, SRA_STEP_4, SRA_STEP, SRA_STEP,              SRA_END, 0, 0, 0, 0,
    Fetch, SRA_STEP_4, SRA_STEP_4, SRA_STEP, SRA_STEP, SRA_STEP,    SRA_END, 0, 0, 0,
    Fetch, SRA_STEP_4, SRA_STEP_4, SRA_STEP_4,                      SRA_END, 0, 0,
    Fetch, SRA_STEP_4, SRA_STEP_4, SRA_STEP_4, SRA_STEP,            SRA_END, 0,
    Fetch, SRA_STEP_4, SRA_STEP_4, SRA_STEP_4, SRA_STEP, SRA_STEP,  SRA_END,            // Shift 15 positions

    // 01000FFF - ALU rD, rA, [Addr16]
    MOV_DIRA, ALU_DIRA(ALU_and), ALU_DIRA(ALU_or), ALU_DIRA(ALU_xor), ALU_DIRA(ALU_add), ALU_DIRA(ALU_sub), ALU_DIRA(ALU_add), ALU_DIRA(ALU_sub),

    // 01001FFF - ALU rD, rA, [rB]
    MOV_INDA, ALU_INDA(ALU_and), ALU_INDA(ALU_or), ALU_INDA(ALU_xor), ALU_INDA(ALU_add), ALU_INDA(ALU_sub), ALU_INDA(ALU_add), ALU_INDA(ALU_sub),

    // TODO: 0101xFFF - ALU rD, [rA+Imm16]
    LOAD(Bank1) /* lw */, NOP, NOP, NOP, NOP, NOP, NOP, NOP,
    LOAD(Bank1) /* lw */, NOP, NOP, NOP, NOP, NOP, NOP, NOP,

    // 01100FFF - ALU [Addr16], rA
    MOV_DIRD, ALU_DIRD(ALU_and), ALU_DIRD(ALU_or), ALU_DIRD(ALU_xor), ALU_DIRD(ALU_add), ALU_DIRD(ALU_sub), ALU_DIRD(ALU_add), ALU_DIRD(ALU_sub),

    // 01101FFF - ALU [rA], rB
    MOV_INDD, ALU_INDD(ALU_and), ALU_INDD(ALU_or), ALU_INDD(ALU_xor), ALU_INDD(ALU_add), ALU_INDD(ALU_sub), ALU_INDD(ALU_add), ALU_INDD(ALU_sub),

    // TODO: 0111xFFF - ALU [rA+Imm16], rB
    STORE, NOP, NOP, NOP, NOP, NOP, NOP, NOP,
    STORE, NOP, NOP, NOP, NOP, NOP, NOP, NOP,


    LOAD(Bank1|Bank0),  // 10000000 - lb

    SWAP,       // 10000001 - swap

    LOAD(Bank0), LOAD(0),    // 1000001W - peek(W):  W=0 -> Lower bits (Bank 01),  W=1 -> Upper bits (Bank 00)
    
    PUSH,   // 10000100 - push rB
    /*PUSH_I*/ NOP,       // TODO: 10000101 - push Imm16
    PUSHF,  // 10000110 - pushf

    POP,    // 10000111 - pop
    POPF,   // 10001000 - popf

    // 10001001-10001111 - Unused
    NOP, NOP, NOP, NOP, NOP, NOP, NOP,
    // 1001xxxx - Unused
    NOP, NOP, NOP, NOP, NOP, NOP, NOP, NOP, NOP, NOP, NOP, NOP, NOP, NOP, NOP, NOP,
    // 101xxxxx - Unused
    NOP, NOP, NOP, NOP, NOP, NOP, NOP, NOP, NOP, NOP, NOP, NOP, NOP, NOP, NOP, NOP,
    NOP, NOP, NOP, NOP, NOP, NOP, NOP, NOP, NOP, NOP, NOP, NOP, NOP, NOP, NOP, NOP,

    // 11000FFF - [JUMP] Addr
    JMP_IMM, JMP_IMM, JMP_IMM, JMP_IMM, JMP_IMM, JMP_IMM, JMP_IMM, JMP_IMM,

    // 11001FFF - [JUMP] rA
    JMP_REG, JMP_REG, JMP_REG, JMP_REG, JMP_REG, JMP_REG, JMP_REG, JMP_REG,

    CALL,   // 11010000 - call Addr16
    /*CALL_R*/ NOP,   // TODO: 11010001 - call rB
    /*SYSCALL*/ NOP,   // TODO: 11010010 - syscall Addr16

    /*RUN*/ NOP,    // TODO: 11010011 - run

    RET,    // 11010100 - ret
    
    // 11010101-11010111 - Unused
    NOP, NOP, NOP,
    // 11011xxx - Unused
    NOP, NOP, NOP, NOP, NOP, NOP, NOP, NOP,
    // 111xxxxx - Unused
    NOP, NOP, NOP, NOP, NOP, NOP, NOP, NOP, NOP, NOP, NOP, NOP, NOP, NOP, NOP, NOP,
    NOP, NOP, NOP, NOP, NOP, NOP, NOP, NOP, NOP, NOP, NOP, NOP, NOP, NOP, NOP, NOP,
};


void enable_jmp(int flags, int funct) {
    // Invert the PcIn signal from a given conditional jump ("enable" the jump)
    // The affected opcodes are 0b11000FFF (imm) and 0b11000000 (reg) -> 0b11000000+funct and 0b11000000+8+funct

    int address = TEMPL_SIZE * flags + 16 * (0b11000000 + funct) + 1; // 16*(0xC0+funct) points to first microinstruction, +1 skips Fetch

    content[address] ^= PcIn;        // IMM variant (base address)
    content[address + 8*16] ^= PcIn; // REG variant: Add 8 to opcode -> add 8*16 to address
}

void switchCarry(int flags, int funct) {
    // ALU_REG and ALU_IMM perform the ALU operation on the second time step (excluding the fetch cycle). Invert the carry bit on that microinstruction.
    // The affected opcodes are: 0b00000FFF (REG), 0b00001FFF (IMM), 0b010xxFFF (Arg), 0b011xxFFF (Dest)

    int address = TEMPL_SIZE * flags + 16 * funct + 2; // 16*funct points to fetch, +2 skips Fetch and MemOut|ArgBk|LdY
    content[address] ^= AluCIn;         // REG variant (base address)
    content[address + 8*16] ^= AluCIn;  // Disable IMM variant (add 8 to opcode -> add 8*16 to address)
    
    // Base address for memory variants (must skip an extra timestep!)
    address = TEMPL_SIZE * flags + 16 * (0b01000000 + funct) + 2;
    content[address + 0x00*16] ^= AluCIn; // Disable DIR_arg variant
    content[address + 0x08*16] ^= AluCIn; // Disable IND_arg variant (add 8 to opcode -> add 8*16 to address)
    content[address + 0x10*16] ^= AluCIn; // Disable IDX_arg variant (add 16 to opcode -> add 16*16 to address)
    content[address + 0x18*16] ^= AluCIn; // Disable IDX_arg variant
    content[address + 0x20*16] ^= AluCIn; // Disable DIR_dest variant (add 32 to opcode -> add 32*16 to address)
    content[address + 0x28*16] ^= AluCIn; // Disable IND_dest variant (add 40 to opcode -> add 40*16 to address)
    content[address + 0x30*16] ^= AluCIn; // Disable IDX_dest variant (add 48 to opcode -> add 48*16 to address)
    content[address + 0x38*16] ^= AluCIn; // Disable IDX_dest variant
}

void generate() {
    assert(TEMPLATE.size() == TEMPL_SIZE); // Make sure size is correct
    
    // Copy template 16 times while inverting active low signals:
    for (int i = 0; i < SIZE/2; i+=TEMPL_SIZE)
        for (int j = 0; j < TEMPL_SIZE; j++)
            content[i+j] = TEMPLATE[j] ^ ACTIVE_LOW_MASK;
    
    // FLAG MODIFICATIONS: Enable jump instructions and addc/subb
    for (int flags = 0; flags <= 0b1111; flags++) {
        bool ZF = flags & 0b0001;   // Zero flag
        bool BF = flags & 0b0010;   // Borrow flag
        bool VF = flags & 0b0100;   // Overflow flag
        bool SF = flags & 0b1000;   // Sign flag
        bool CF = not BF;           // Carry = not Borrow
        bool LT = (VF and not SF) or (not VF and SF);   // Less Than = V xor S
        
        // Unconditional jump
        enable_jmp(flags, 0b000); // JMP

        // Conditional jumps
        if (ZF) enable_jmp(flags, 0b001); // JZ
        else    enable_jmp(flags, 0b010); // JNZ
        
        if (CF) enable_jmp(flags, 0b011); // JC
        else    enable_jmp(flags, 0b100); // JNC
        
        if (ZF or BF) enable_jmp(flags, 0b101); // JLEU
        
        if (LT) enable_jmp(flags, 0b110);       // JLT
        if (ZF or LT) enable_jmp(flags, 0b111); // JLE
        
        
        // ALU operations with carry
        if (CF) switchCarry(flags, 0b110);  // ADDC
        else    switchCarry(flags, 0b111);  // SUBB
    }


    // Generate interrupt logic
    assert(JMP_INT.size() == 16);
    
    for (int i = SIZE/2; i < SIZE; i+=16)
        for (int j = 0; j < 16; j++)
            content[i+j] = JMP_INT[j] ^ ACTIVE_LOW_MASK;
}


void write_file(int filenum) {
    ofstream outputFile;
    
    cout << "Writing HEX file " << filenum << endl;
    #ifndef RUN_FROM_RAM
        outputFile.open("output" + to_string(filenum) + ".hex", fstream::out);
    #else
        // When generating instructions that run from RAM, append to the end of the file
        outputFile.open("output" + to_string(filenum) + ".hex", fstream::out|ifstream::app);
    #endif
    
    for (int i = 0; i < SIZE/32; i++) {
        for (int j = 0; j < 32; j++) {
            unsigned char output = content[32*i + j] >> (8*filenum);
            outputFile << setw(2) << setfill('0') << hex << int(output) << ' ';
        }
        outputFile << endl;
    }
    outputFile.close();
}


int main() {
    cout << "Generating file..." << endl;
    generate();
    
    for (int i = 0; i < 3; i++)
        write_file(i);
    
    cout << "Done." << endl;

    #ifdef RUN_FROM_RAM
        cout << "File 0 contains CLR, D_Out...\nFile 1 contains TglRun, SP++...\nFile 2 contains LdImm, LdFlg..." << endl;
    #endif
}
