#include <iostream>
#include <iomanip>
#include <fstream>
#include <vector>
#include <string>
#include <assert.h>
#include <ciso646> // Include this so vscode doesn't complain about alternative logical operators
using namespace std;


// CONTROL SIGNALS
#define AluM        0x000001    // Mode input for 74HC181 ALU
#define AddrOut0    0x000002    // Output select (address bus):
#define AddrOut1    0x000004    //     00 = No output,  01 = PC,  10 = ALU,  11 = SP
#define AluS0       0x000008    // Select input 0 for 74HC181 ALU
#define AluS1       0x000010    // Select input 1 for 74HC181 ALU
#define AluS2       0x000020    // Select input 2 for 74HC181 ALU
#define AluS3       0x000040    // Select input 3 for 74HC181 ALU
#define AluCIn      0x000080    // Carry In input for 74HC181 ALU

#define Dout2       0x000100    // Output select (data/main bus)
#define LdFlg       0x000200    // Load flags register [ACTIVE LOW]
#define TglRun      0x000400    // Toggle run mode (fetch from ROM or RAM) (also load flags from bus)
#define Dout1       0x000800    // Output select (data/main bus):
#define Dout0       0x001000    //    000=No output, 001=ALU, 010=ALU (Shifted), 011=Memory, 100=PC, 101=IR, 110=Flags, 111=Generate constant
#define LdX         0x002000    // Load temporary register X [ACTIVE LOW]
#define LdY         0x004000    // Load temporary register Y [ACTIVE LOW]
#define CLR         0x008000    // Clear microcode counter (start next instruction) [ACTIVE LOW]

#define LdImm       0x010000    // Load Immediate to temp register
#define SPpp        0x020000    // Increment Stack Pointer (SP-- if AluS0 = 1) [ACTIVE LOW]
#define PCpp        0x040000    // Increment Program Counter (and load Instruction Register)
#define PcIn        0x080000    // Program Counter in (Jump) [ACTIVE LOW]
#define MemIn       0x100000    // Memory (RAM) in
#define LdReg       0x200000    // Load Register (rD) [ACTIVE LOW]
#define Bank0       0x400000    // Memory bank select:
#define Bank1       0x800000    //    00 = Opcode,  01 = Argument,  10 = RAM (Data and Stack),  11 = RAM (Sign extended)

// Selective inverter for active low lines
const uint32_t ACTIVE_LOW_MASK = CLR | SPpp | LdReg | LdX | LdY | LdFlg | PcIn;



// COMMONLY USED SIGNAL COMBINATIONS
#define AluOutD     Dout0               // ALU -> Data Bus
#define AluShOut    Dout1               // ALU[>>] -> Data Bus

#define MemOut      Dout1|Dout0         // MEM -> Data Bus
#define PcOutD      Dout2               // PC -> Data Bus
#define IrOut       Dout2|Dout0         // IR -> Data Bus
#define FlagsOut    Dout2|Dout1         // Flags -> Data Bus
#define ConstOut    Dout2|Dout1|Dout0   // Generated constant -> Data Bus

#define PcOutAddr   AddrOut0            // PC -> MAR
#define AluOutAddr  AddrOut1            // ALU -> MAR

#define SPmm        SPpp|AluS0          // SP--
#define LdFlgALU    LdFlg               // Generate flags from ALU
#define LdFlgBUS    LdFlg|TglRun        // Load flags from the main bus

#define Fetch       PCpp|MemOut|LdX|LdY // First timestep for all instructions (LdX|LdY also loads Instruction Register)
#define ArgBk       Bank0               // Argument bank (where instruction arguments are fetched)

#define ToggleRun   TglRun|LdImm        // Toggle run mode (fetch from ROM or RAM)
#define Gen11       AluS1|AluS2         // Generate 0x0011 (must be compatible with ALU_Xminus1)
#define Gen13       AluS1|AluS2|AluM    // Generate 0x0013

// ALU OPERATIONS (from 74HC181 datasheet)
#define ALU_Y       AluM|AluS3|AluS1                // Output Y
#define ALU_X       AluM|AluS3|AluS2|AluS1|AluS0    // Output X
#define ALU_Xminus1 AluS3|AluS2|AluS1|AluS0|AluCIn  // Output X-1
#define ALU_and     AluM|AluS3|AluS1|AluS0
#define ALU_or      AluM|AluS3|AluS2|AluS1
#define ALU_xor     AluM|AluS2|AluS1
#define ALU_sll     AluS3|AluS2|AluCIn
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
    #define Fetch       PcOutAddr|MemOut|Bank1|LdX|LdY  // Fetch increments PC and is done from RAM (LdX|LdY also loads Instruction Register)
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

#define ALU_IDXA(OP) Fetch,  MemOut|ArgBk|LdImm|LdY|ALU_add|AluOutAddr,   IrOut|LdX,   MemOut|Bank1|LdImm|LdY,   OP|AluOutD|LdReg|LdFlgALU|PcOutAddr|CLR,       ZEROx11
#define ALU_IDXD(OP) Fetch,  MemOut|ArgBk|LdImm|LdY|ALU_add|AluOutAddr,   IrOut|LdY,   MemOut|Bank1|LdImm|LdX,   OP|AluOutD|MemIn|Bank1|LdFlgALU|PcOutAddr|CLR, ZEROx11

#define SLL_STEP    ALU_sll|AluOutD|LdImm|LdX
#define SLL_END     ALU_sll|AluOutD|LdReg|LdFlgALU|PcOutAddr|CLR
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

#define PUSH_R      Fetch,  SPmm|MemOut|ArgBk|LdY|ALU_Xminus1|AluOutAddr,       ALU_Y|AluOutD|MemIn|Bank1|PcOutAddr|CLR,    ZEROx13
#define PUSH_I      Fetch,  SPmm|MemOut|ArgBk|LdImm|LdY|ALU_Xminus1|AluOutAddr, ALU_Y|AluOutD|MemIn|Bank1|PcOutAddr|CLR,    ZEROx13
#define PUSHF       Fetch,  SPmm|ALU_Xminus1|AluOutAddr,                        FlagsOut|MemIn|Bank1|PcOutAddr|CLR,         ZEROx13

#define POP         Fetch,  ALU_X|AluOutAddr,                               SPpp|MemOut|Bank1|LdReg|PcOutAddr|CLR,      ZEROx13
#define POPF        Fetch,  ALU_X|AluOutAddr,                               SPpp|MemOut|Bank1|LdFlgBUS|PcOutAddr|CLR,   ZEROx13

#define CALL_R      Fetch,  MemOut|ArgBk|      LdY|ALU_Xminus1|AluOutAddr,      SPmm|PcOutD|MemIn|Bank1,    ALU_Y|AluOutD|PcIn|AluOutAddr|CLR,           ZEROx12
#define ENTER_R     Fetch,  MemOut|ArgBk|      LdY|ALU_Xminus1|AluOutAddr,      SPmm|PcOutD|MemIn|Bank1,    ALU_Y|AluOutD|PcIn|AluOutAddr|CLR|ToggleRun, ZEROx12
#define CALL_R_RAM  Fetch,  MemOut|ArgBk|      LdY|ALU_Xminus1|AluOutAddr|PCpp, SPmm|PcOutD|MemIn|Bank1,    ALU_Y|AluOutD|PcIn|AluOutAddr|CLR,           ZEROx12
#define SYSCALL_R   Fetch,  MemOut|ArgBk|      LdY|ALU_Xminus1|AluOutAddr|PCpp, SPmm|PcOutD|MemIn|Bank1,    ALU_Y|AluOutD|PcIn|AluOutAddr|CLR|ToggleRun, ZEROx12
#define CALL_I      Fetch,  MemOut|ArgBk|LdImm|LdY|ALU_Xminus1|AluOutAddr,      SPmm|PcOutD|MemIn|Bank1,    ALU_Y|AluOutD|PcIn|AluOutAddr|CLR,           ZEROx12
#define ENTER_I     Fetch,  MemOut|ArgBk|LdImm|LdY|ALU_Xminus1|AluOutAddr,      SPmm|PcOutD|MemIn|Bank1,    ALU_Y|AluOutD|PcIn|AluOutAddr|CLR|ToggleRun, ZEROx12
#define CALL_I_RAM  Fetch,  MemOut|ArgBk|LdImm|LdY|ALU_Xminus1|AluOutAddr|PCpp, SPmm|PcOutD|MemIn|Bank1,    ALU_Y|AluOutD|PcIn|AluOutAddr|CLR,           ZEROx12
#define SYSCALL_I   Fetch,  MemOut|ArgBk|LdImm|LdY|ALU_Xminus1|AluOutAddr|PCpp, SPmm|PcOutD|MemIn|Bank1,    ALU_Y|AluOutD|PcIn|AluOutAddr|CLR|ToggleRun, ZEROx12

#define RET         Fetch,  ALU_X|AluOutAddr,                               SPpp|MemOut|Bank1|PcIn|PcOutAddr|CLR,           ZEROx13
#define SYSRET      Fetch,  ALU_X|AluOutAddr,                               SPpp|MemOut|Bank1|PcIn|PcOutAddr|CLR|ToggleRun, ZEROx13
#define EXIT        Fetch,  ALU_X|AluOutAddr,                               SPpp|MemOut|Bank1|PcIn|PcOutAddr|CLR|ToggleRun, ZEROx13

#define JMP_REG     Fetch,  ALU_X|AluOutD/*|PcIn*/|PcOutAddr|CLR,   ZEROx14
#define JMP_IMM     Fetch,  MemOut|ArgBk /*|PcIn*/|PcOutAddr|CLR,   ZEROx14

#define NOP         Fetch,  PcOutAddr|CLR,   ZEROx14     // Only used for illegal instructions

// Jump to interrupt vector
const vector<uint32_t> JMP_INT_ROM = {Gen11|ConstOut|LdX|ALU_Xminus1|AluOutAddr,    SPmm|PcOutD|MemIn|Bank1,    Gen13|ConstOut|PcIn|PcOutAddr|CLR,           ZEROx13};
const vector<uint32_t> JMP_INT_RAM = {Gen11|ConstOut|LdX|ALU_Xminus1|AluOutAddr,    SPmm|PcOutD|MemIn|Bank1,    Gen11|ConstOut|PcIn|PcOutAddr|CLR|ToggleRun, ZEROx13};

#ifdef RUN_FROM_RAM
    // When executed from RAM, enter works like a regular call instruction
    #undef ENTER_R
    #define ENTER_R CALL_R
    #undef ENTER_I
    #define ENTER_I CALL_I
    // When executed from RAM, sysret works like a regular ret instruction
    #undef SYSRET
    #define SYSRET RET
    // Push 0x0000 when jumping to an interrupt
    #define JMP_INT JMP_INT_RAM
    // Add PC++ to 2nd timestep of CALL instructions (push PC+2 instead of PC+1)
    #undef CALL_R
    #define CALL_R CALL_R_RAM
    #undef CALL_I
    #define CALL_I CALL_I_RAM
#else
    // When executed from ROM, syscall works like a regular call instruction
    #undef SYSCALL_I
    #define SYSCALL_I CALL_I
    #undef SYSCALL_R
    #define SYSCALL_R CALL_R
    // When executed from ROM, exit works like a regular ret instruction
    #undef EXIT
    #define EXIT RET
    // Just push PC when jumping to an interrupt
    #define JMP_INT JMP_INT_ROM
#endif

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

    // 0101xFFF - ALU rD, [rA+Imm16]
    LOAD(Bank1)/* lw */, ALU_IDXA(ALU_and), ALU_IDXA(ALU_or), ALU_IDXA(ALU_xor), ALU_IDXA(ALU_add), ALU_IDXA(ALU_sub), ALU_IDXA(ALU_add), ALU_IDXA(ALU_sub),
    LOAD(Bank1)/* lw */, ALU_IDXA(ALU_and), ALU_IDXA(ALU_or), ALU_IDXA(ALU_xor), ALU_IDXA(ALU_add), ALU_IDXA(ALU_sub), ALU_IDXA(ALU_add), ALU_IDXA(ALU_sub),

    // 01100FFF - ALU [Addr16], rA
    MOV_DIRD, ALU_DIRD(ALU_and), ALU_DIRD(ALU_or), ALU_DIRD(ALU_xor), ALU_DIRD(ALU_add), ALU_DIRD(ALU_sub), ALU_DIRD(ALU_add), ALU_DIRD(ALU_sub),

    // 01101FFF - ALU [rA], rB
    MOV_INDD, ALU_INDD(ALU_and), ALU_INDD(ALU_or), ALU_INDD(ALU_xor), ALU_INDD(ALU_add), ALU_INDD(ALU_sub), ALU_INDD(ALU_add), ALU_INDD(ALU_sub),

    // 0111xFFF - ALU [rA+Imm16], rB
    STORE, ALU_IDXD(ALU_and), ALU_IDXD(ALU_or), ALU_IDXD(ALU_xor), ALU_IDXD(ALU_add), ALU_IDXD(ALU_sub), ALU_IDXD(ALU_add), ALU_IDXD(ALU_sub),
    STORE, ALU_IDXD(ALU_and), ALU_IDXD(ALU_or), ALU_IDXD(ALU_xor), ALU_IDXD(ALU_add), ALU_IDXD(ALU_sub), ALU_IDXD(ALU_add), ALU_IDXD(ALU_sub),


    LOAD(Bank1|Bank0),  // 10000000 - movb

    SWAP,       // 10000001 - swap

    LOAD(Bank0), LOAD(0),    // 1000001W - peek(W):  W=0 -> Lower bits (Bank 01),  W=1 -> Upper bits (Bank 00)
    
    PUSH_R, // 10000100 - push rB
    PUSH_I, // 10000101 - push Imm16
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

    // 1100FFFF - [JUMP] rA
    JMP_REG, JMP_REG, JMP_REG, JMP_REG, JMP_REG, JMP_REG, JMP_REG, JMP_REG, JMP_REG, JMP_REG, JMP_REG, JMP_REG, JMP_REG, JMP_REG, JMP_REG, JMP_REG,
    
    // 1101FFFF - [JUMP] Addr
    JMP_IMM, JMP_IMM, JMP_IMM, JMP_IMM, JMP_IMM, JMP_IMM, JMP_IMM, JMP_IMM, JMP_IMM, JMP_IMM, JMP_IMM, JMP_IMM, JMP_IMM, JMP_IMM, JMP_IMM, JMP_IMM,

    CALL_R,     // 11100000 - call rB
    CALL_I,     // 11100001 - call Addr16
    SYSCALL_R,  // 11100010 - syscall rB
    SYSCALL_I,  // 11100011 - syscall Addr16
    ENTER_R,    // 11100100 - enter rB
    ENTER_I,    // 11100101 - enter Addr16

    RET,        // 11100110 - ret
    SYSRET,     // 11100111 - sysret
    EXIT,       // 11101000 - exit
    
    // 11101001-11101111 - Unused
    NOP, NOP, NOP, NOP, NOP, NOP, NOP,
    // 1111xxxx - Unused
    NOP, NOP, NOP, NOP, NOP, NOP, NOP, NOP, NOP, NOP, NOP, NOP, NOP, NOP, NOP, NOP,
};


// Extract the opcode from an address (remove flags and timesteps)
inline int get_opcode(int address) {
    return (address & 0xFF0) >> 4;
}

void enable_jmp(int flags, int funct) {
    // Invert the PcIn signal from a given conditional jump ("enable" the jump)
    // The affected opcodes are 0b1100FFFF (reg) and 0b1101FFFF (imm) -> 0b11000000+funct and 0b11000000+16+funct
    const int OFFS = 16; // 4 funct bits

    int address = TEMPL_SIZE * flags + 16 * (0b11000000 + funct) + 1; // 16*(0xC0+funct) points to first microinstruction, +1 skips Fetch

    // Assert that we stay in the correct address range
    assert(get_opcode(address) >= 0b11000000); // 11000000 = JUMP_REG
    assert(get_opcode(address) <  0b11010000); // 11010000 = JUMP_IMM
    assert(get_opcode(address + OFFS*16) >= 0b11010000); // 0b11100000 = JUMP_IMM
    assert(get_opcode(address + OFFS*16) <  0b11100000); // 0b11100000 = CALL

    content[address] ^= PcIn;           // REG variant (base address)
    content[address + OFFS*16] ^= PcIn; // IMM variant: Add OFFS to opcode -> add OFFS*16 to address
}

void switchCarry(int flags, int funct) {
    // ALU_REG and ALU_IMM perform the ALU operation on the second time step (excluding the fetch cycle). Invert the carry bit on that microinstruction.
    // The affected opcodes are: 0b00000FFF (REG), 0b00001FFF (IMM), 0b010xxFFF (Arg), 0b011xxFFF (Dest)

    int address = TEMPL_SIZE * flags + 16 * funct + 2; // 16*funct points to fetch, +2 skips Fetch and MemOut|ArgBk|LdY
    const int OFFS = 8; // 3 funct bits

    // Assert that we stay in the correct address range
    assert(get_opcode(address) >= 0b00000000); // 0b00000000 = ALU_REG
    assert(get_opcode(address) <  0b00001000); // 0b00001000 = ALU_IMM
    assert(get_opcode(address + OFFS*16) >= 0b00001000); // 0b00001000 = ALU_IMM
    assert(get_opcode(address + OFFS*16) <  0b00010000); // 0b00010000 = SLL

    content[address] ^= AluCIn;             // REG variant (base address)
    content[address + OFFS*16] ^= AluCIn;   // Disable IMM variant (add OFFS to opcode -> add 8*16 to address)
    

    // Base address for memory variants (direct and indirect must skip must skip 1 extra timestep, indexed must skip 2!)
    address = TEMPL_SIZE * flags + 16 * (0b01000000 + funct) + 2;

    // Assert that we stay in the correct address range
    assert(get_opcode(address) >= 0b01000000); // 0b01000000 = ALU_DIR_arg
    assert(get_opcode(address) <  0b01001000); // 0b01001000 = ALU_IND_arg
    assert(get_opcode(address + 5*OFFS*16+1) >= 0b01101000); // 0b01101000 = ALU_IND_dest
    assert(get_opcode(address + 5*OFFS*16+1) <  0b01110000); // 0b01110000 = ALU_IDX_dest
    assert(get_opcode(address + 7*OFFS*16+2) <  0b10000000); // 0b10000000 = MOVB

    content[address + 0x00*16+1] ^= AluCIn; // Disable DIR_arg variant
    content[address + 0x08*16+1] ^= AluCIn; // Disable IND_arg variant (add 8 to opcode -> add 8*16 to address)
    content[address + 0x10*16+2] ^= AluCIn; // Disable IDX_arg variant (add 16 to opcode -> add 16*16 to address)
    content[address + 0x18*16+2] ^= AluCIn; // Disable IDX_arg variant
    content[address + 0x20*16+1] ^= AluCIn; // Disable DIR_dest variant (add 32 to opcode -> add 32*16 to address)
    content[address + 0x28*16+1] ^= AluCIn; // Disable IND_dest variant (add 40 to opcode -> add 40*16 to address)
    content[address + 0x30*16+2] ^= AluCIn; // Disable IDX_dest variant (add 48 to opcode -> add 48*16 to address)
    content[address + 0x38*16+2] ^= AluCIn; // Disable IDX_dest variant

    // TODO: Uncomment and make sure it's the same
    // content[address + 0*OFFS*16+1] ^= AluCIn; // Disable DIR_arg variant
    // content[address + 1*OFFS*16+1] ^= AluCIn; // Disable IND_arg variant (add 8 to opcode -> add 8*16 to address)
    // content[address + 2*OFFS*16+2] ^= AluCIn; // Disable IDX_arg variant (add 16 to opcode -> add 16*16 to address)
    // content[address + 3*OFFS*16+2] ^= AluCIn; // Disable IDX_arg variant
    // content[address + 4*OFFS*16+1] ^= AluCIn; // Disable DIR_dest variant (add 32 to opcode -> add 32*16 to address)
    // content[address + 5*OFFS*16+1] ^= AluCIn; // Disable IND_dest variant (add 40 to opcode -> add 40*16 to address)
    // content[address + 6*OFFS*16+2] ^= AluCIn; // Disable IDX_dest variant (add 48 to opcode -> add 48*16 to address)
    // content[address + 7*OFFS*16+2] ^= AluCIn; // Disable IDX_dest variant
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
        bool CF = flags & 0b0010;   // Carry flag
        bool VF = flags & 0b0100;   // Overflow flag
        bool SF = flags & 0b1000;   // Sign flag
        // Todo: LT = (VF != SF)
        bool LT = (VF and not SF) or (not VF and SF);   // Less Than = V xor S
        
        // Unconditional jump
        enable_jmp(flags, 0b0000); // JMP

        // Conditional jumps
        if (ZF) enable_jmp(flags, 0b0001);  // JZ
        else    enable_jmp(flags, 0b0010);  // JNZ
        
        if (CF) enable_jmp(flags, 0b0011);  // JC
        else    enable_jmp(flags, 0b0100);  // JNC

        if (VF) enable_jmp(flags, 0b0101);  // JO
        else    enable_jmp(flags, 0b0110);  // JNO

        if (SF) enable_jmp(flags, 0b0111);  // JS
        else    enable_jmp(flags, 0b1000);  // JNS
        
        if (ZF or CF) enable_jmp(flags, 0b1001); // JBE
        else    enable_jmp(flags, 0b1010);  // JA
        
        if (LT) enable_jmp(flags, 0b1011);  // JL
        else    enable_jmp(flags, 0b1110);  // JGE

        if (ZF or LT) enable_jmp(flags, 0b1100); // JLE
        else    enable_jmp(flags, 0b1101);  // JG
        
        
        // ALU operations with carry
        if (CF) {
            switchCarry(flags, 0b110);  // ADDC
            switchCarry(flags, 0b111);  // SUBB
        }
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
        outputFile << '\n';
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
