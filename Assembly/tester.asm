#include "CESC16.cpu"

#define DO_MANUAL_TEST ; Comment out (using ;) this line to skip the initial manual test
;#define STRICT_FLG    ; Remove this comment to force the correct flag values, even for undefined flags


; Error codes: if the test fails, check the table below to see where it failed
E_JUMPS = 0x0001    ; Automated jumps tester
E_MEM   = 0x0002    ; Automated jumps tester
E_ALU_1 = 0x0011    ; Basic ALU instructions and flags (section A)
E_ALU_2 = 0x0012    ; Basic ALU instructions and flags (section B)
E_O_DIR = 0x0021    ; ALU addressing modes (direct operand)
E_O_IND = 0x0022    ; ALU addressing modes (indirect operand)
E_O_IDX = 0x0023    ; ALU addressing modes (indexed operand)
E_D_DIR = 0x0024    ; ALU addressing modes (direct operand)
E_D_IND = 0x0025    ; ALU addressing modes (indirect operand)
E_D_IDX = 0x0026    ; ALU addressing modes (indexed operand)
E_IO    = 0x0031    ; Input and output



#ifdef STRICT_FLG
    #define FAILURE_UNDEFINED FAILURE   ; Mismatch on undefined flag jumps to FAILURE
#else
    #define FAILURE_UNDEFINED skip(0)   ; Mismatch on undefined flag continues execution
#endif

#bank data
FAILURE_CAUSE: #res 1


#bank program

BEGIN:
    ; Perform restart
    nop

#ifdef DO_MANUAL_TEST

MANUAL_TEST:

    ; Test basic instruction fetching and GPR connections
    mov t0, 0xFFFF
    mov t1, 0xFFFF
    mov t2, 0xFFFF
    mov t3, 0xFFFF
    mov t4, 0xFFFF
    mov s0, 0xFFFF
    mov s1, 0xFFFF
    mov s2, 0xFFFF
    mov s3, 0xFFFF
    mov s4, 0xFFFF
    mov a0, 0xFFFF
    mov a1, 0xFFFF
    mov a2, 0xFFFF
    mov v0, 0xFFFF
    mov sp, 0xFFFF

    mov t0, 0x0000
    mov t1, 0x0001
    mov t2, 0x0002
    mov t3, 0x0004
    mov t4, 0x0008
    mov s0, 0x0010
    mov s1, 0x0020
    mov s2, 0x0040
    mov s3, 0x0080
    mov s4, 0x0100
    mov a0, 0x0200
    mov a1, 0x0400
    mov a2, 0x0800
    mov v0, 0x1000
    mov sp, 0x8001
    mov zero, 0x2000    ; This shouldn't do anything

    ; Basic ALU instructions and flags
    or t0, t1, t2       ; t0 = 0x0003, flags: none (Carry)
    add t0, t0, t2      ; t0 = 0x0005, flags: none
    add sp, sp, 0xE123  ; sp = 0x6124, flags: Carry, oVerflow
    mov sp, v0          ; sp = 0x1000, flags unchanged
    sll sp, sp, 3       ; sp = 0x8000, flags: Sign
    sra v0, sp, 9       ; v0 = 0xFFC0, flags: Sign
    srl v0, sp, 9       ; v0 = 0x0040, flags: none
    sra v0, v0, 1       ; v0 = 0x0020, flags: none
    sll sp, sp, 1       ; sp = 0x0000, flags: Zero, Carry
    movf sp, 0x0001     ; sp = 0x0001, flags: none
    sra v0, sp, 1       ; v0 = 0x0000, flags: Zero (Carry)
    srl sp, sp, 1       ; sp = 0x0000, flags: Zero
    mov sp, 0x1234      ; sp = 0x1234, flags unchanged
    mov v0, sp          ; v0 = 0x1234, flags unchanged

    ; Basic memory instructions
    pushf               ; sp = 0x1233
    mov s0, 0x5050      ; s0 = 0x5050
    mov [25], s0
    mov s1, [25]        ; s1 = 0x5050
    mov s2, 0x100       ; s2 = 0x0100
    mov [s2], s0
    mov [s0], s2
    mov s3, [s2]        ; s3 = 0x5050
    mov s3, [s0]        ; s3 = 0x0100
    mov s3, [0x100]     ; s3 = 0x5050
    mov s3, [0x5050]    ; s3 = 0x0100
    mov s3, [25]        ; s3 = 0x5050
    sub s0, s0, 5       ; s0 = 0x504B, flags: none
    mov s3, [s0+5]      ; s3 = 0x0100
    mov [s3+500], s3
    mov s0, [0x2F4]     ; s0 = 0x0100
    push s0             ; sp = 0x1232
    push sp             ; sp = 0x1231
    push 0xABCD         ; sp = 0x1230
    pop s0              ; s0 = 0xABCD, sp = 0x1231
    pop s0              ; s0 = 0x1232, sp = 0x1232
    pop s0              ; s0 = 0x0100, sp = 0x1233
    swap s1, [sp+(-3)]  ; s1 = 0xABCD
    movb s1, [sp+(-3)]  ; s1 = 0x0050
    popf                ; sp = 0x1234, flags: Zero
    add [sp+(-4)], s1   ; flags: none
    movb s1, [sp+(-4)]  ; s1 = 0xFFA0
    mov s0, test_data-30    ; s0 = 0xXXXX
    peek s2, [test_data], 1 ; s2 = 0xBEEF
    peek s2, [s0+30], 0     ; s2 = 0xF00D
    

    ; Advanced ALU instructions and flags
    push 0b1111         ; sp = 0x1233, flags unchanged
    popf                ; sp = 0x1234, flags: Zero, Carry, oVerflow, Sign
    addc v0, v0, 0x20   ; v0 = 0x1255, flags: none
    addc v0, sp, 0x20   ; v0 = 0x1254, flags: none
    mov t0, 0xAAAA      ; t0 = 0xAAAA, flags unchanged
    xor t1, v0, 0xAAAA  ; t1 = 0xB8FE, flags: Sign (oVerflow, Carry)
    clrf                ; registers unchanged, flags: none
    xor t1, v0, t0      ; t1 unchanged, flags: Sign (oVerflow, Carry)
    add t2, t0, t1      ; t2 = 0x63A8, flags: oVerflow, Carry
    sub t2, t0, t1      ; t2 = 0xF1AC, flags: Sign, Carry
    subb t2, t2, 0x8001 ; t2 = 0x71AA, flags: none
    subb t2, t2, 0x8001 ; t2 = 0xF1A9, flags: oVerflow, Sign, Carry
    subb t3, t2, zero   ; t3 = 0xF1A8, flags: Sign
    xor t3, t3, t3      ; t3 = 0x0000, flags: Zero
    sll t4, t2, 15      ; t4 = 0x8000, flags: Sign
    srl s4, t4, 15      ; s4 = 0x0001, flags: none
    sra s4, t4, 15      ; s4 = 0xFFFF, flags: Sign
    sub t0, zero,0x8000 ; t0 = 0x8000, flags: Carry, oVerflow, Sign
    

    ; Unconditional and conditional jumps
    mov t0, 0x5555
    jmp skip(1)         ; Taken
    mov t0, 0xFFFF      ; Not executed

    add t0, t0, 0xAAAB  ; t0 = 0x0000, flags: Zero, Carry
    jnz skip(2)         ; Not taken
    mov a0, 0x1234      ; a0 = 0x1234
    jc skip(1)          ; Taken
    jmp FAILURE         ; Not executed
    ; Todo: test JMP and JZ more thoroughly
    

    ; Test load/store + memory operations
    ; TODO


    ; Test basic I/O
    ; TODO


    ; Test stack (push(f)/pop(f) + call/ret)
    ; TODO

#endif


AUTOMATED_TEST:

    mov t0, E_JUMPS
    mov [FAILURE_CAUSE], t0
; Test conditional jumps
    mov sp, 0x8000
    call TEST_JUMPS ; Call the jumps tester subroutine

    cmp sp, 0x8000  ; Make sure the subroutine has deallocated all its memory
    jne FAILURE


    mov t0, E_ALU_1
    mov [FAILURE_CAUSE], t0
    ; ALU operations, part 1

    mov t0, 0x0000
    mov t1, 0x0001
    mov t2, 0x0002
    mov t3, 0x0004
    mov t4, 0x0008
    mov s0, 0x0010
    mov s1, 0x0020
    mov s2, 0x0040
    mov s3, 0x0080
    mov s4, 0x0100
    mov a0, 0x0200
    mov a1, 0x0400
    mov a2, 0x0800
    mov v0, 0x1000
    mov sp, 0x8001

    or t0, t1, t2       ; t0 = 0x0003, flags: none (Carry)
    jz FAILURE
    jnc FAILURE_UNDEFINED
    jo FAILURE_UNDEFINED
    js FAILURE
    cmp t0, 0x0003
    jne FAILURE

    add t0, t0, t2      ; t0 = 0x0005, flags: none
    jz FAILURE
    jc FAILURE
    jo FAILURE
    js FAILURE
    cmp t0, 0x0005
    jne FAILURE

    add sp, sp, 0xE123  ; sp = 0x6124, flags: Carry, oVerflow
    jz FAILURE
    jnc FAILURE
    jno FAILURE
    js FAILURE
    pushf
    cmp sp, 0x6123  ; pushf decrements sp: 0x6124 -> 0x6123
    jne FAILURE
    popf

    mov sp, v0          ; sp = 0x1000, flags unchanged
    jz FAILURE
    jnc FAILURE
    jno FAILURE
    js FAILURE
    cmp sp, 0x1000
    jne FAILURE

    sll sp, sp, 3       ; sp = 0x8000, flags: Sign
    jz FAILURE
    jc FAILURE
    jo FAILURE_UNDEFINED
    jns FAILURE
    cmp sp, 0x8000
    jne FAILURE

    sra v0, sp, 9       ; v0 = 0xFFC0, flags: Sign
    jz FAILURE
    jc FAILURE_UNDEFINED
    jo FAILURE_UNDEFINED
    jns FAILURE
    cmp v0, 0xFFC0
    jne FAILURE

    srl v0, sp, 9       ; v0 = 0x0040, flags: none
    jz FAILURE
    jc FAILURE_UNDEFINED
    jo FAILURE_UNDEFINED
    js FAILURE
    cmp v0, 0x0040
    jne FAILURE

    sra v0, v0, 1       ; v0 = 0x0020, flags: none
    jz FAILURE
    jc FAILURE_UNDEFINED
    jo FAILURE_UNDEFINED
    js FAILURE
    cmp v0, 0x0020
    jne FAILURE

    sll sp, sp, 1       ; sp = 0x0000, flags: Zero, Carry
    jnz FAILURE
    jnc FAILURE
    jo FAILURE_UNDEFINED
    js FAILURE
    cmp sp, zero
    jne FAILURE

    movf sp, 0x0001     ; sp = 0x0001, flags: none
    jz FAILURE
    jc FAILURE
    jo FAILURE
    js FAILURE
    cmp sp, 0x0001
    jne FAILURE

    sra v0, sp, 1       ; v0 = 0x0000, flags: Zero (Carry)
    jnz FAILURE
    jnc FAILURE_UNDEFINED
    jo FAILURE_UNDEFINED
    js FAILURE
    cmp v0, zero
    jne FAILURE

    srl sp, sp, 1       ; sp = 0x0000, flags: Zero
    jnz FAILURE
    jc FAILURE_UNDEFINED
    jo FAILURE_UNDEFINED
    js FAILURE
    cmp sp, zero
    jne FAILURE

    mov sp, 0x1234      ; sp = 0x1234, flags unchanged
    jnz FAILURE
    jc FAILURE_UNDEFINED
    jo FAILURE_UNDEFINED
    js FAILURE
    cmp sp, 0x1234
    jne FAILURE

    mov v0, sp          ; v0 = 0x1234, flags unchanged
    jnz FAILURE
    jc FAILURE_UNDEFINED
    jo FAILURE_UNDEFINED
    js FAILURE
    pushf               ; sp = 0x1233
    cmp v0, 0x1234
    jne FAILURE
    cmp sp, 0x1233
    jne FAILURE



    mov t0, E_MEM
    mov [FAILURE_CAUSE], t0
    ; Basic memory instructions
    
    mov s0, 0x5050      ; s0 = 0x5050
    mov [25], s0
    mov s1, [25]        ; s1 = 0x5050
    cmp s1, 0x5050
    jne FAILURE

    mov s2, 0x100       ; s2 = 0x0100
    mov [s2], s0
    mov [s0], s2
    mov s3, [s2]        ; s3 = 0x5050
    cmp s3, 0x5050
    jne FAILURE

    mov s3, [s0]        ; s3 = 0x0100
    cmp s3, 0x0100
    jne FAILURE

    mov s3, [0x100]     ; s3 = 0x5050
    cmp s3, 0x5050
    jne FAILURE

    mov s3, [0x5050]    ; s3 = 0x0100
    cmp s3, 0x0100
    jne FAILURE

    mov s3, [25]        ; s3 = 0x5050, flags unchanged
    cmp s3, 0x5050
    jne FAILURE

    sub s0, s0, 5       ; s0 = 0x504B, flags: none
    mov s3, [s0+5]      ; s3 = 0x0100
    cmp s3, 0x0100
    jne FAILURE

    mov [s3+500], s3
    mov s0, [0x2F4]     ; s0 = 0x0100
    cmp s0, 0x0100
    jne FAILURE

    push s0             ; sp = 0x1232
    push sp             ; sp = 0x1231
    push 0xABCD         ; sp = 0x1230
    pop s0              ; s0 = 0xABCD, sp = 0x1231
    cmp s0, 0xABCD
    jne FAILURE
    cmp sp, 0x1231
    jne FAILURE

    pop s0              ; s0 = 0x1232, sp = 0x1232
    cmp s0, 0x1232
    jne FAILURE

    pop s0              ; s0 = 0x0100, sp = 0x1233
    cmp s0, 0x0100
    jne FAILURE
    cmp sp, 0x1233
    jne FAILURE

    swap s1, [sp+(-3)]  ; s1 = 0xABCD
    cmp s1, 0xABCD
    jne FAILURE

    movb s1, [sp+(-3)]  ; s1 = 0x0050
    cmp s1, 0x0050
    jne FAILURE

    popf                ; sp = 0x1234, flags: Zero
    jnz FAILURE
    jc FAILURE_UNDEFINED
    jo FAILURE_UNDEFINED
    js FAILURE
    cmp sp, 0x1234
    jne FAILURE

    add [sp+(-4)], s1   ; flags: none
    movb s1, [sp+(-4)]  ; s1 = 0xFFA0
    cmp s1, 0xFFA0
    jne FAILURE

    mov s0, test_data-30
    peek s2, [test_data], 1 ; s2 = 0xBEEF
    cmp s2, 0xBEEF
    jne FAILURE

    peek s2, [s0+30], 0     ; s2 = 0xF00D
    cmp s2, 0xF00D
    jne FAILURE



    mov t0, E_ALU_2
    mov [FAILURE_CAUSE], t0
    ; ALU operations, part 2

    push 0b1111         ; sp = 0x1233, flags unchanged
    jnz FAILURE
    jc FAILURE_UNDEFINED
    jo FAILURE_UNDEFINED
    js FAILURE
    cmp sp, 0x1233
    jne FAILURE
    
    popf                ; sp = 0x1234, flags: Zero, Carry, oVerflow, Sign
    jnz FAILURE
    jnc FAILURE
    jno FAILURE
    jns FAILURE

    addc v0, v0, 0x20   ; v0 = 0x1255, flags: none
    jz FAILURE
    jc FAILURE
    jo FAILURE
    js FAILURE
    pushf
    cmp v0, 0x1255
    jne FAILURE
    popf

    addc v0, sp, 0x20   ; v0 = 0x1254, flags: none
    jz FAILURE
    jc FAILURE
    jo FAILURE
    js FAILURE
    pushf
    cmp v0, 0x1254
    jne FAILURE
    popf

    mov t0, 0xAAAA      ; t0 = 0xAAAA, flags unchanged
    jz FAILURE
    jc FAILURE
    jo FAILURE
    js FAILURE
    cmp t0, 0xAAAA
    jne FAILURE

    xor t1, v0, 0xAAAA  ; t1 = 0xB8FE, flags: Sign (oVerflow, Carry)
    jz FAILURE
    jnc FAILURE_UNDEFINED
    jno FAILURE_UNDEFINED
    jns FAILURE
    cmp t1, 0xB8FE
    jne FAILURE

    clrf                ; registers unchanged, flags: none
    jz FAILURE
    jc FAILURE
    jo FAILURE
    js FAILURE

    xor t1, v0, t0      ; t1 unchanged, flags: Sign (oVerflow, Carry)
    jz FAILURE
    jnc FAILURE_UNDEFINED
    jno FAILURE_UNDEFINED
    jns FAILURE
    cmp t1, 0xB8FE
    jne FAILURE

    add t2, t0, t1      ; t2 = 0x63A8, flags: oVerflow, Carry
    jz FAILURE
    jnc FAILURE
    jno FAILURE
    js FAILURE
    cmp t2, 0x63A8
    jne FAILURE

    sub t2, t0, t1      ; t2 = 0xF1AC, flags: Sign, Carry
    jz FAILURE
    jnc FAILURE
    jo FAILURE
    jns FAILURE
    pushf
    cmp t2, 0xF1AC
    jne FAILURE
    popf

    subb t2, t2, 0x8001 ; t2 = 0x71AA, flags: none
    jz FAILURE
    jc FAILURE
    jo FAILURE
    js FAILURE
    pushf
    cmp t2, 0x71AA
    jne FAILURE
    popf

    subb t2, t2, 0x8001 ; t2 = 0xF1A9, flags: oVerflow, Sign, Carry
    jz FAILURE
    jnc FAILURE
    jno FAILURE
    jns FAILURE
    pushf
    cmp t2, 0xF1A9
    jne FAILURE
    popf

    subb t3, t2, zero   ; t3 = 0xF1A8, flags: Sign
    jz FAILURE
    jc FAILURE
    jo FAILURE
    jns FAILURE
    cmp t3, 0xF1A8
    jne FAILURE

    xor t3, t3, t3      ; t3 = 0x0000, flags: Zero
    jnz FAILURE
    jc FAILURE_UNDEFINED
    jo FAILURE_UNDEFINED
    js FAILURE
    cmp t3, zero
    jne FAILURE

    sll t4, t2, 15      ; t4 = 0x8000, flags: Sign
    jz FAILURE
    jc FAILURE
    jo FAILURE_UNDEFINED
    jns FAILURE
    cmp t4, 0x8000
    jne FAILURE

    srl s4, t4, 15      ; s4 = 0x0001, flags: none
    jz FAILURE
    jc FAILURE_UNDEFINED
    jo FAILURE_UNDEFINED
    js FAILURE
    cmp s4, 0x0001
    jne FAILURE

    sra s4, t4, 15      ; s4 = 0xFFFF, flags: Sign
    jz FAILURE
    jc FAILURE_UNDEFINED
    jo FAILURE_UNDEFINED
    jns FAILURE
    cmp s4, 0xFFFF
    jne FAILURE
    
    sub t0, zero,0x8000 ; t0 = 0x8000, flags: Carry, oVerflow, Sign
    jz FAILURE
    jnc FAILURE
    jno FAILURE
    jns FAILURE
    cmp t0, 0x8000
    jne FAILURE



    mov t0, E_O_DIR
    mov [FAILURE_CAUSE], t0
; Test ALU addressing modes (direct)
    ; TODO


    mov t0, E_O_IND
    mov [FAILURE_CAUSE], t0
; Test ALU addressing modes (indirect)
    ; TODO
    

    mov t0, E_O_IDX
    mov [FAILURE_CAUSE], t0
; Test ALU addressing modes (indexed)
    ; TODO


    mov t0, E_D_DIR
    mov [FAILURE_CAUSE], t0
; Test ALU addressing modes (direct destination)
    ; TODO


    mov t0, E_D_IND
    mov [FAILURE_CAUSE], t0
; Test ALU addressing modes (indirect destination)
    ; TODO


    mov t0, E_D_IDX
    mov [FAILURE_CAUSE], t0
; Test ALU addressing modes (indexed destination)
    ; TODO


    mov t0, E_IO
    mov [FAILURE_CAUSE], t0
; Test I/O
    ; TODO


; Copy to RAM and repeat
    ; TODO: Jump addresses need to be recalculated
    ; todo  Change error messages
    ; todo  syscall FAILURE instead of jumping


    ; Test finished!
    jmp SUCCESS


TERMINAL_ADDR = 0xFF40

FAILURE:
    mov t0, [FAILURE_CAUSE]
    mov t1, 0xFFFF
    mov t2, 0xFFFF
    mov t3, 0xFFFF
    mov t4, 0xFFFF
    mov s0, 0xFFFF
    mov s1, 0xFFFF
    mov s2, 0xFFFF
    mov s3, 0xFFFF
    mov s4, 0xFFFF
    mov a1, 0xFFFF
    mov a2, 0xFFFF
    mov v0, 0xFFFF
    mov sp, 0x8000

    mov a0, "F"
    call Output_char
    mov sp, 0xFFFF
    mov a0, 0xFFFF

    ; Infinite loop. The first jump should be enough, but it could fail in very high clock speeds
.loop:
    jmp .loop
    jmp .loop
    mov v0, .loop
    jmp v0

SUCCESS:
    ; Make checkerboard pattern to indicate success
    mov t0, 0x0000
    mov t1, 0xFFFF
    mov t2, 0x0000
    mov t3, 0xFFFF
    mov t4, 0xFFFF
    mov s0, 0xFFFF
    mov s1, 0xFFFF
    mov s2, 0x0000
    mov s3, 0x0000
    mov s4, 0xFFFF
    mov a1, 0x0000
    mov a2, 0x0000
    mov v0, 0x0000
    mov sp, 0x8000

    ; TODO: Improve success message
    mov a0, "O"
    call Output_char
    mov a0, "K"
    call Output_char
    
    mov sp, 0xFFFF
    mov a0, 0xFFFF

    jmp pc

    





; CODE FROM THE FORMER JUMPS TEST PROGRAM (TEST_JUMPS.ASM)

; Data in program memory:
args: ; Arguments to be tested
#d16    0, 0,      300, 300,    -1, -1,     0, 100,     5, 0x7fff,   10, -10,    0, 0x8000,  -1, 0x8000, 0x8000, 0,  0x8000, 1,  2, 1,       -2, -1
.size = sizeof(args)

outputs: ; Expected outputs
#d16    0x1559,    0x1559,      0x1559,     0x0376,     0x0376,      0x1d16,     0x1a96,     0x3d0a,     0x236a,     0x24ea,     0x3d0a,      0x0376
.size = sizeof(outputs)

progmem_end:


; User program entry point
TEST_JUMPS:
.main:
    push s0
    push s1
    push s2

    ; Copy progmem to data memory (stack)
    sub sp, sp, args.size+outputs.size  ; Reserve space in stack
    mov a0, args
    mov a1, progmem_end
    mov a2, sp              ; Destination is the stack
    syscall MEMORY.MemCopy
    
    mov s0, sp  ; Pointer to start of arguments
    add s2, sp, args.size   ; End of arguments
    mov s1, s2  ; Pointer to start of outputs

..loop:
    mov a0, [s0]    ; Load arguments
    mov a1, [s0+1]
    call .test_cond ; Call test
    
    mov t0, [s1]    ; Load output
    cmp v0, t0
    jne FAILURE     ; If outputs don't match, display error
    
    add s0, s0, 2
    add s1, s1, 1
    
    cmp s0, s2      ; Check if all tests have been performed
    jne ..loop
    

    ; This point is reached only if all the jump tests succeed
    add sp, sp, args.size + outputs.size    ; Free space in stack
    pop s2
    pop s1
    pop s0
    ret     ; Return to the main tester program


; Arguments: a0, a1 are tests
; Returns: v0 is the test result
.test_cond:     
    mov v0, 0
    
    cmp a0, a1
    jz skip(1)
    or v0, v0, 0x0001
    
    cmp a0, a1
    jnz skip(1)
    or v0, v0, 0x0002
    
    cmp a0, a1
    jc skip(1)
    or v0, v0, 0x0004
    
    cmp a0, a1
    jnc skip(1)
    or v0, v0, 0x0008
    
    cmp a0, a1
    jbe skip(1)
    or v0, v0, 0x0010
    
    cmp a0, a1
    jl skip(1)
    or v0, v0, 0x0020
    
    cmp a0, a1
    jle skip(1)
    or v0, v0, 0x0040

    cmp a0, a1
    jo skip(1)
    or v0, v0, 0x0080

    cmp a0, a1
    jno skip(1)
    or v0, v0, 0x0100

    cmp a0, a1
    js skip(1)
    or v0, v0, 0x0200

    cmp a0, a1
    jns skip(1)
    or v0, v0, 0x0400

    cmp a0, a1
    jg skip(1)
    or v0, v0, 0x0800

    cmp a0, a1
    jge skip(1)
    or v0, v0, 0x1000

    cmp a0, a1
    ja skip(1)
    or v0, v0, 0x2000
    
    xor v0, v0, 0x3FFF  ; Invert the results (convert to active high)
    
    ret


; CODE FROM THE OS LIBRARIES:

MEMORY:
.MemCopy:
    cmp a1, a0      ; If (address of last element) <= (address of first element),
    jbe ..return    ; then return (nothing to copy)
    
..loop:
    peek v0, [a0+0], Up     ; Read upper 16-bit word / opcode
    mov [a2], v0            ; Store to lower address (big endian)
    peek v0, [a0+0], Low    ; Read lower 16-bit word / argument
    mov [a2+1], v0          ; Store to upper address (big endian)
    add a0, a0, 1           ; Increment program memory pointer
    add a2, a2, 2           ; Increment data memory pointer
    
    cmp a0, a1              ; Keep looping until there are no more words
    jne ..loop
    
..return:
    ret

Output_char:
    test [TERMINAL_ADDR]    ; Read flag
    jnz Output_char         ; Poll until it's 0 (terminal ready)
    
    mov [TERMINAL_ADDR], a0     ; Send char to terminal
    ret



test_data:  #d32 0xBEEFF00D
