; =====================
; CESC16 CPU TEST SUITE
; =====================
;
; Automated tests for checking that a CESC16 CPU works properly
;
; How to use:
;
; 1. If DO_MANUAL_TEST is left uncommented, the tester will first perform the tests without
;    checking the results. A human must supervise the code execution and check that the
;    result of each instruction matches the comment written next to them.
;
; 2. Then, the automated tests will begin. If all tests pass, the LEDs on the registers will
;    display a chess pattern. If a test fails, all registers will be set to 0xFFFF except for
;    t0, which will contain the error code of the test that failed. Check the table below to
;    see which test didn't pass.
;
; 3. If STRICT_FLG is defined, a flag that doesn't match the hardware simulation will be
;    considered a failure, even if the flag is undefined after the executed instruction.
;    Uncomment it for testing real hardware, and leave it commented for emulators.
;
; 4. If TEST_RAM is defined, the test suite will be copied to RAM and executed in user mode
;    (from RAM). I recommend testing the ROM first; once it works you can uncomment that line
;    and test RAM. Keep in mind that RAM testing is ~10x slower than testing directly in ROM.



#define DO_MANUAL_TEST ; Comment out (using ;) this line to skip the initial manual test
; #define STRICT_FLG    ; Uncomment this to force the correct flag values, even for undefined flags
; #define TEST_RAM      ; Uncomment this to copy the tester program to RAM (test RAM execution)


; Error codes: if the test fails, check the table below to see where it failed
E_JUMPS = 0x0001    ; Automated jumps tester
E_MEM   = 0x0002    ; Memory instructions
E_ALU_1 = 0x0011    ; Basic ALU instructions and flags (section A)
E_ALU_2 = 0x0012    ; Basic ALU instructions and flags (section B)
E_ADDR  = 0x0013    ; ALU addressing modes
E_ZEROR = 0x0021    ; Speed of zero register

MASK_ROM = 0x0000
MASK_RAM = 0x8000



#ifdef STRICT_FLG
    #define FAILURE_UNDEFINED FAILURE   ; Mismatch on undefined flag jumps to FAILURE
#else
    #define FAILURE_UNDEFINED skip(0)   ; Mismatch on undefined flag continues execution
#endif

#ifdef TEST_RAM
    #undef skip
    #define skip(Off) (pc + 2*(Off + 1))
    #define ERR_MASK MASK_RAM
#else
    #define ERR_MASK MASK_ROM
#endif

; Returns the data size between Begin and the current spot (RAM)
#define sizeof_RAM(Begin) (pc - Begin)
; Returns the address in ROM where a RAM symbol is located
#define rom(Addr) (Addr/2)


#bank data
FAILURE_CAUSE: #res 1


#bank program

BEGIN:
    ; Perform restart
    nop

#ifdef TEST_RAM
    ; Testing RAM execution
    
    #ifdef DO_MANUAL_TEST
        ; Copy MANUAL_TEST to RAM
        mov sp, 0x8000
        mov a0, rom(MANUAL_TEST)
        mov a1, rom(MANUAL_TEST) + MANUAL_TEST.size
        mov a2, MANUAL_TEST ; RAM location
        call MEMORY.MemCopy
        
        ; Execute MANUAL_TEST
        enter MANUAL_TEST
        
        ; Manual test for enter/exit is stored in ROM
        call ENTER_EXIT_MANUAL_TEST
    #endif

    mov a0, rom(TEST_JUMPS)
    mov a1, rom(TEST_JUMPS) + TEST_JUMPS.size
    mov a2, TEST_JUMPS ; RAM location
    call MEMORY.MemCopy
    
    mov a0, rom(AUTOMATED_TEST)
    mov a1, rom(AUTOMATED_TEST) + AUTOMATED_TEST_SZ
    mov a2, AUTOMATED_TEST ; RAM location
    call MEMORY.MemCopy
    
    ; Execute AUTOMATED_TEST
    enter AUTOMATED_TEST
    
    ; Unreachable
    jmp pc

; ifdef TEST_RAM
#endif


#ifdef DO_MANUAL_TEST

#ifdef TEST_RAM
    ; First part of manual test will be copied to RAM
    #bits 16
#endif

MANUAL_TEST:

    ; Test basic instruction fetching and GPR connections
    mov t0, 0xFFFF
    mov t1, 0xFFFF
    mov t2, 0xFFFF
    mov t3, 0xFFFF
    mov bp, 0xFFFF
    mov s0, 0xFFFF
    mov s1, 0xFFFF
    mov s2, 0xFFFF
    mov s3, 0xFFFF
    mov s4, 0xFFFF
    mov a0, 0xFFFF
    mov a1, 0xFFFF
    mov a2, 0xFFFF
    mov a3, 0xFFFF
    mov sp, 0xFFFF

    mov t0, 0x0000
    mov t1, 0x0001
    mov t2, 0x0002
    mov t3, 0x0004
    mov bp, 0x0008
    mov s0, 0x0010
    mov s1, 0x0020
    mov s2, 0x0040
    mov s3, 0x0080
    mov s4, 0x0100
    mov a0, 0x0200
    mov a1, 0x0400
    mov a2, 0x0800
    mov a3, 0x1000
    mov sp, 0x8001
    mov zero, 0x2000    ; This shouldn't do anything

    ; Basic ALU instructions and flags
    or t0, t1, t2       ; t0 = 0x0003, flags: none (Carry)
    add t0, t0, t2      ; t0 = 0x0005, flags: none
    add sp, sp, 0xE123  ; sp = 0x6124, flags: Carry, oVerflow
    mov sp, a3          ; sp = 0x1000, flags unchanged
    sll sp, sp, 3       ; sp = 0x8000, flags: Sign
    sra a3, sp, 9       ; a3 = 0xFFC0, flags: Sign
    srl a3, sp, 9       ; a3 = 0x0040, flags: none
    sra a3, a3, 1       ; a3 = 0x0020, flags: none
    sll sp, sp, 1       ; sp = 0x0000, flags: Zero, Carry
    movf sp, 0x0001     ; sp = 0x0001, flags: none
    sra a3, sp, 1       ; a3 = 0x0000, flags: Zero (Carry)
    srl sp, sp, 1       ; sp = 0x0000, flags: Zero
    mov sp, 0x1234      ; sp = 0x1234, flags unchanged
    mov a3, sp          ; a3 = 0x1234, flags unchanged

    ; Basic memory instructions
    pushf               ; sp = 0x1233
    mov s4, [0x100]     ; Store overwritten instruction in RAM
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
    mov s1, [sp+(-3)]   ; s1 = 0x5050
    popf                ; sp = 0x1234, flags: Zero
    mov s0, test_data-30    ; s0 = 0xXXXX
    peek s2, [test_data], 1 ; s2 = 0xBEEF
    peek s2, [s0+30], 0     ; s2 = 0xF00D
    mov [0x100], s4     ; Restore overwritten instruction in RAM
    

    ; Advanced ALU instructions and flags
    push 0b1111         ; sp = 0x1233, flags unchanged
    popf                ; sp = 0x1234, flags: Zero, Carry, oVerflow, Sign
    addc a3, a3, 0x20   ; a3 = 0x1255, flags: none
    addc a3, sp, 0x20   ; a3 = 0x1254, flags: none
    mov t0, 0xAAAA      ; t0 = 0xAAAA, flags unchanged
    xor t1, a3, 0xAAAA  ; t1 = 0xB8FE, flags: Sign (oVerflow, Carry)
    clrf                ; registers unchanged, flags: none
    xor t1, a3, t0      ; t1 unchanged, flags: Sign (oVerflow, Carry)
    add t2, t0, t1      ; t2 = 0x63A8, flags: oVerflow, Carry
    sub t2, t0, t1      ; t2 = 0xF1AC, flags: Sign, Carry
    subb t2, t2, 0x8001 ; t2 = 0x71AA, flags: none
    subb t2, t2, 0x8001 ; t2 = 0xF1A9, flags: oVerflow, Sign, Carry
    subb t3, t2, zero   ; t3 = 0xF1A8, flags: Sign
    xor t3, t3, t3      ; t3 = 0x0000, flags: Zero
    sll bp, t2, 15      ; bp = 0x8000, flags: Sign
    srl s4, bp, 15      ; s4 = 0x0001, flags: none
    sra s4, bp, 15      ; s4 = 0xFFFF, flags: Sign
    sub t0, zero,0x8000 ; t0 = 0x8000, flags: Carry, oVerflow, Sign
    
    
    ; Addressing modes (Mem = Address 0x8002)
    mov [0x8002], s2        ; Mem: 0xF00D
    mov s0, [0x8002]        ; s0 = 0xF00D
    mov [t0+2], t1          ; Mem: 0xB8FE
    mov s1, [t0+2]          ; s1 = 0xB8FE
    mov t0, 0x8002          ; t0 = 0x8002
    mov [t0], s0            ; Mem: 0xF00D
    mov s1, [t0]            ; s1 = 0xF00D
    mov s3, 0x8FF5          ; s3 = 0x8FF5
    mov [s3+s1], t2         ; Mem: 0xF1A9
    mov s3, [s1+s3]         ; s3 = 0xF1A9
    mov s3, [0x8002]        ; s3 unchanged
    
    add s4, [t2+0x8E59]     ; s4 = 0xF1A8, flags: Sign, Carry
    sub [s4+0x8E5A], s4     ; Mem: 0x0001, flags: none
    mov t2, 0x8102          ; t2 = 0x8102
    or [t0], t2             ; Mem: 0x8103, flags: Sign (oVerflow, Carry)
    
    mov t1, 0xAAAA          ; t1 = 0xAAAA
    and t3, t1, [0x8002]    ; t3 = 0x8002, flags: Sign
    or t3, t1, [t0]         ; t3 = 0xABAB, flags: Sign
    xor t3, t1, [0x8002]    ; t3 = 0x2BA9, flags: none
    sub [0x8002], t1        ; Mem: 0xD659, flags: Sign, Carry
    mov t1, [t0]            ; t1 = 0xD659
    
    mov s1, 0xFF00          ; s1 = 0xFF00
    addc s2, [s1+t2]        ; s2 = 0xC667, flags: Sign, Carry
    subb [s1+t2], s2        ; Mem: 0x0FF1, flags: none
    subb s4, s4, [t0]       ; s4 = 0xE1B7, flags: Sign
    subb [t2+s1], s4        ; Mem: 0x2E3A, flags: Carry
    subb s4, s4, [t0]       ; s4 = 0xB37C, flags: Sign
    addc t1, [s4+0xCC86]    ; t1 = 0x0493, flags: Carry
    addc t1, [s4+0xCC86]    ; t1 = 0x32CE, flags: none
    addc [0x8002], s1       ; Mem: 0x2D3A, flags: Carry
    subb [t0], s1           ; Mem: 0x2E39, flags: Carry
    subb t2, t1, [0x8002]   ; t2 = 0x0494, flags: none
    subb t1, t1, [0x8002]   ; t1 = 0x0495, flags: none
    
    
    ; Unconditional and conditional jumps
    mov t0, 0x5555
    jmp skip(1)         ; Taken
    mov t0, 0xFFFF      ; Not executed

    add t0, t0, 0xAAAB  ; t0 = 0x0000, flags: Zero, Carry
    jnz skip(2)         ; Not taken
    mov a0, 0x1234      ; a0 = 0x1234
    jc skip(1)          ; Taken
    jmp FAILURE         ; Not executed
    jz skip(1)          ; Taken
    jmp FAILURE         ; Not executed
    add t0, t0, .test_jmp.label

.test_jmp:
    jnz t0              ; 1: Taken,     2: Not taken
    jmp ..skip          ; 1: Not taken, 2: Taken

..label:
    movf t1, zero       ; t1 = 0x0000, flags: Zero
    jmp .test_jmp

..skip:
    add t1, t1, 0x1111  ; t1 = 0x1111, flags: none


    ; call/ret instructions
    call .test_call     ; sp = 0x1233
    
    jmp .test_call.end

.test_call:
    mov s0, 0x1234      ; s0 = 0x1234
    ret                 ; sp = 0x1234

..end:
    add s0, s0, 0x1111  ; s0 = 0x2345
    call .test_recursive ; sp = 0x1233

    jmp .test_recursive.end

.test_recursive:
    srl s0, s0, 1
    jz skip(1)
    call .test_recursive ; sp--
    ret

..end:
    add s0, s0, 1       ; s0 = 0x0001

; End of manual test: return to caller
#ifdef TEST_RAM
    mov sp, 0x7FFF
    exit
#endif

.size = sizeof_RAM(MANUAL_TEST)


; enter/exit testing is always done in ROM
#bits 32

ENTER_EXIT_MANUAL_TEST:
    ; enter/exit and syscall/sysret instructions
    mov a0, .enter_test
    mov a1, .enter_test.end
    mov a2, 0x1234
    call MEMORY.MemCopy

    enter 0x1234

    add t0, t0, 1       ; t0 = 0x1236
    jmp .enter_test.end

.enter_test: ; Copy to RAM
    mov t0, 0xABCD
    add t0, t0, 0x1111  ; t0 = 0xBCDE
    syscall syscall_test
    
; syscall_test:         (defined below)
;     mov t0, 0x1234
;     sysret
    
    add t0, t0, 1       ; t0 = 0x1235
    exit
..end:

    sub t0, t0, 1       ; t0 = 0x1235
    
#ifdef TEST_RAM
    ; End of manual test: return to caller
    ret
#else
    ; End of manual test: continue with automated test
    jmp AUTOMATED_TEST
#endif


; ifdef DO_MANUAL_TEST
#endif


#ifdef TEST_RAM
    ; Automated test will be copied to RAM
    #bits 16
#endif

AUTOMATED_TEST:

    mov t0, E_JUMPS|ERR_MASK
    mov [FAILURE_CAUSE], t0
    ; Test conditional jumps
    mov sp, 0x8000
    call TEST_JUMPS ; Call the jumps tester subroutine

    cmp sp, 0x8000  ; Make sure the subroutine has deallocated all its memory
    jne FAILURE


    mov t0, E_ALU_1|ERR_MASK
    mov [FAILURE_CAUSE], t0
    ; ALU operations, part 1

    mov t0, 0x0000
    mov t1, 0x0001
    mov t2, 0x0002
    mov t3, 0x0004
    mov bp, 0x0008
    mov s0, 0x0010
    mov s1, 0x0020
    mov s2, 0x0040
    mov s3, 0x0080
    mov s4, 0x0100
    mov a0, 0x0200
    mov a1, 0x0400
    mov a2, 0x0800
    mov a3, 0x1000
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

    mov sp, a3          ; sp = 0x1000, flags unchanged
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

    sra a3, sp, 9       ; a3 = 0xFFC0, flags: Sign
    jz FAILURE
    jc FAILURE_UNDEFINED
    jo FAILURE_UNDEFINED
    jns FAILURE
    cmp a3, 0xFFC0
    jne FAILURE

    srl a3, sp, 9       ; a3 = 0x0040, flags: none
    jz FAILURE
    jc FAILURE_UNDEFINED
    jo FAILURE_UNDEFINED
    js FAILURE
    cmp a3, 0x0040
    jne FAILURE

    sra a3, a3, 1       ; a3 = 0x0020, flags: none
    jz FAILURE
    jc FAILURE_UNDEFINED
    jo FAILURE_UNDEFINED
    js FAILURE
    cmp a3, 0x0020
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

    sra a3, sp, 1       ; a3 = 0x0000, flags: Zero (Carry)
    jnz FAILURE
    jnc FAILURE_UNDEFINED
    jo FAILURE_UNDEFINED
    js FAILURE
    cmp a3, zero
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

    mov a3, sp          ; a3 = 0x1234, flags unchanged
    jnz FAILURE
    jc FAILURE_UNDEFINED
    jo FAILURE_UNDEFINED
    js FAILURE
    pushf               ; sp = 0x1233
    cmp a3, 0x1234
    jne FAILURE
    cmp sp, 0x1233
    jne FAILURE



    mov t0, E_MEM|ERR_MASK
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
    
    mov t0, [0x2F4]     ; Store overwritten instruction in RAM
    mov [s3+500], s3
    mov s0, [0x2F4]     ; s0 = 0x0100
    mov [0x2F4], t0     ; Restore overwritten instruction in RAM
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

    mov s1, [sp+(-3)]   ; s1 = 0x5050
    cmp s1, 0x5050
    jne FAILURE

    popf                ; sp = 0x1234, flags: Zero
    jnz FAILURE
    jc FAILURE_UNDEFINED
    jo FAILURE_UNDEFINED
    js FAILURE
    cmp sp, 0x1234
    jne FAILURE

    mov s0, test_data-30
    peek s2, [test_data], 1 ; s2 = 0xBEEF
    cmp s2, 0xBEEF
    jne FAILURE

    peek s2, [s0+30], 0     ; s2 = 0xF00D
    cmp s2, 0xF00D
    jne FAILURE



    mov t0, E_ALU_2|ERR_MASK
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

    addc a3, a3, 0x20   ; a3 = 0x1255, flags: none
    jz FAILURE
    jc FAILURE
    jo FAILURE
    js FAILURE
    pushf
    cmp a3, 0x1255
    jne FAILURE
    popf

    addc a3, sp, 0x20   ; a3 = 0x1254, flags: none
    jz FAILURE
    jc FAILURE
    jo FAILURE
    js FAILURE
    pushf
    cmp a3, 0x1254
    jne FAILURE
    popf

    mov t0, 0xAAAA      ; t0 = 0xAAAA, flags unchanged
    jz FAILURE
    jc FAILURE
    jo FAILURE
    js FAILURE
    cmp t0, 0xAAAA
    jne FAILURE

    xor t1, a3, 0xAAAA  ; t1 = 0xB8FE, flags: Sign (oVerflow, Carry)
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

    xor t1, a3, t0      ; t1 unchanged, flags: Sign (oVerflow, Carry)
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

    sll bp, t2, 15      ; bp = 0x8000, flags: Sign
    jz FAILURE
    jc FAILURE
    jo FAILURE_UNDEFINED
    jns FAILURE
    cmp bp, 0x8000
    jne FAILURE

    srl s4, bp, 15      ; s4 = 0x0001, flags: none
    jz FAILURE
    jc FAILURE_UNDEFINED
    jo FAILURE_UNDEFINED
    js FAILURE
    cmp s4, 0x0001
    jne FAILURE

    sra s4, bp, 15      ; s4 = 0xFFFF, flags: Sign
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



    mov t0, E_ADDR|ERR_MASK
    mov [FAILURE_CAUSE], t0
    ; Test ALU addressing modes
    mov t0, 0x8000
    mov [0x8002], s2        ; Mem: 0xF00D
    mov s0, [0x8002]        ; s0 = 0xF00D
    cmp s0, 0xF00D
    jne FAILURE
    
    mov [t0+2], t1          ; Mem: 0xB8FE
    mov s1, [t0+2]          ; s1 = 0xB8FE
    cmp s1, 0xB8FE
    jne FAILURE
    
    mov t0, 0x8002          ; t0 = 0x8002
    mov [t0], s0            ; Mem: 0xF00D
    mov s1, [t0]            ; s1 = 0xF00D
    cmp s1, 0xF00D
    jne FAILURE
    
    mov s3, 0x8FF5          ; s3 = 0x8FF5
    mov [s3+s1], t2         ; Mem: 0xF1A9
    mov s3, [s1+s3]         ; s3 = 0xF1A9
    cmp s3, 0xF1A9
    jne FAILURE
    
    mov s3, [0x8002]        ; s3 unchanged
    cmp s3, 0xF1A9
    jne FAILURE
    
    add s4, [t2+0x8E59]     ; s4 = 0xF1A8, flags: Sign, Carry
    jz FAILURE
    jnc FAILURE
    jo FAILURE
    jns FAILURE
    cmp s4, 0xF1A8
    jne FAILURE

    sub [s4+0x8E5A], s4     ; Mem: 0x0001, flags: none
    jz FAILURE
    jc FAILURE
    jo FAILURE
    js FAILURE

    mov t2, 0x8102          ; t2 = 0x8102
    or [t0], t2             ; Mem: 0x8103, flags: Sign (oVerflow, Carry)
    jz FAILURE
    jnc FAILURE_UNDEFINED
    jno FAILURE_UNDEFINED
    jns FAILURE
    
    mov t1, 0xAAAA          ; t1 = 0xAAAA
    and t3, t1, [0x8002]    ; t3 = 0x8002, flags: Sign
    jz FAILURE
    jc FAILURE_UNDEFINED
    jo FAILURE_UNDEFINED
    jns FAILURE
    cmp t3, 0x8002
    jne FAILURE

    or t3, t1, [t0]         ; t3 = 0xABAB, flags: Sign
    jz FAILURE
    jc FAILURE_UNDEFINED
    jo FAILURE_UNDEFINED
    jns FAILURE
    cmp t3, 0xABAB
    jne FAILURE

    xor t3, t1, [0x8002]    ; t3 = 0x2BA9, flags: none
    jz FAILURE
    jc FAILURE_UNDEFINED
    jo FAILURE_UNDEFINED
    js FAILURE
    cmp t3, 0x2BA9
    jne FAILURE

    sub [0x8002], t1        ; Mem: 0xD659, flags: Sign, Carry
    mov t1, [t0]            ; t1 = 0xD659
    jz FAILURE
    jnc FAILURE
    jo FAILURE
    jns FAILURE
    pushf
    cmp t1, 0xD659
    jne FAILURE
    popf
    
    mov s1, 0xFF00          ; s1 = 0xFF00
    addc s2, [s1+t2]        ; s2 = 0xC667, flags: Sign, Carry
    jz FAILURE
    jnc FAILURE
    jo FAILURE
    jns FAILURE
    pushf
    cmp s2, 0xC667
    jne FAILURE
    popf
    
    subb [s1+t2], s2        ; Mem: 0x0FF1, flags: none
    jz FAILURE
    jc FAILURE
    jo FAILURE
    js FAILURE
    
    subb s4, s4, [t0]       ; s4 = 0xE1B7, flags: Sign
    jz FAILURE
    jc FAILURE
    jo FAILURE
    jns FAILURE
    pushf
    cmp s4, 0xE1B7
    jne FAILURE
    popf
    
    subb [t2+s1], s4        ; Mem: 0x2E3A, flags: Carry
    jz FAILURE
    jnc FAILURE
    jo FAILURE
    js FAILURE
    
    subb s4, s4, [t0]       ; s4 = 0xB37C, flags: Sign
    jz FAILURE
    jc FAILURE
    jo FAILURE
    jns FAILURE
    pushf
    cmp s4, 0xB37C
    jne FAILURE
    popf
    
    addc t1, [s4+0xCC86]    ; t1 = 0x0493, flags: Carry
    jz FAILURE
    jnc FAILURE
    jo FAILURE
    js FAILURE
    pushf
    cmp t1, 0x0493
    jne FAILURE
    popf
    
    addc t1, [s4+0xCC86]    ; t1 = 0x32CE, flags: none
    jz FAILURE
    jc FAILURE
    jo FAILURE
    js FAILURE
    pushf
    cmp t1, 0x32CE
    jne FAILURE
    popf
    
    addc [0x8002], s1       ; Mem: 0x2D3A, flags: Carry
    jz FAILURE
    jnc FAILURE
    jo FAILURE
    js FAILURE
    
    subb [t0], s1           ; Mem: 0x2E39, flags: Carry
    jz FAILURE
    jnc FAILURE
    jo FAILURE
    js FAILURE
    
    subb t2, t1, [0x8002]   ; t2 = 0x0494, flags: none
    jz FAILURE
    jc FAILURE
    jo FAILURE
    js FAILURE
    pushf
    cmp t1, 0x32CE
    jne FAILURE
    popf
    
    subb t1, t1, [0x8002]   ; t1 = 0x0495, flags: none
    jz FAILURE
    jc FAILURE
    jo FAILURE
    js FAILURE
    cmp t1, 0x0495
    jne FAILURE
    
    
    
    mov t0, E_ZEROR|ERR_MASK
    mov [FAILURE_CAUSE], t0
    ; Test speed of zero register
    add t0, zero, zero
    jnz FAILURE
    cmp t0, zero
    jne FAILURE

    sub t0, t0, zero
    jnz FAILURE
    or zero, zero, 0
    jnz FAILURE

    not t0, zero
    cmp t0, 0xFFFF
    jne FAILURE


    ; Test finished!
    jmp SUCCESS


TERMINAL_ADDR = 0xFF40

FAILURE:
    mov t0, [FAILURE_CAUSE]
    mov t1, 0xFFFF
    mov t2, 0xFFFF
    mov t3, 0xFFFF
    mov bp, 0xFFFF
    mov s0, 0xFFFF
    mov s1, 0xFFFF
    mov s2, 0xFFFF
    mov s3, 0xFFFF
    mov s4, 0xFFFF
    mov a1, 0xFFFF
    mov a2, 0xFFFF
    mov a3, 0xFFFF
    mov sp, 0x8000

    mov a0, "F"
    mov [TERMINAL_ADDR], a0
    mov sp, 0xFFFF
    mov a0, 0xFFFF

    ; Infinite loop. The first jump should be enough, but it could fail in very high clock speeds
.loop:
    jmp .loop
    jmp .loop
    mov a3, .loop
    jmp a3

SUCCESS:
    ; Make checkerboard pattern to indicate success
    mov t0, 0x0000
    mov t1, 0xFFFF
    mov t2, 0x0000
    mov t3, 0xFFFF
    mov bp, 0xFFFF
    mov s0, 0xFFFF
    mov s1, 0xFFFF
    mov s2, 0x0000
    mov s3, 0x0000
    mov s4, 0xFFFF
    mov a1, 0x0000
    mov a2, 0x0000
    mov a3, 0x0000
    mov sp, 0x8000

    mov a0, "K"
    mov [TERMINAL_ADDR], a0 ; Send char to terminal
    
    mov sp, 0xFFFF
    mov a0, 0xFFFF

    jmp pc  ; Infinite loop

    





; CODE FROM THE FORMER JUMPS TEST PROGRAM (TEST_JUMPS.ASM)
AUTOMATED_TEST_SZ = sizeof_RAM(AUTOMATED_TEST)

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
#ifdef TEST_RAM
    mov a3, MEMORY.MemCopy
    syscall CALL_GATE
#else
    syscall MEMORY.MemCopy
#endif
    
    mov s0, sp  ; Pointer to start of arguments
    add s2, sp, args.size   ; End of arguments
    mov s1, s2  ; Pointer to start of outputs

..loop:
    mov a0, [s0]    ; Load arguments
    mov a1, [s0+1]
    call .test_cond ; Call test
    
    mov t0, [s1]    ; Load output
    cmp a3, t0
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
; Returns: a3 is the test result
.test_cond:     
    mov a3, 0
    
    cmp a0, a1
    jz skip(1)
    or a3, a3, 0x0001
    
    cmp a0, a1
    jnz skip(1)
    or a3, a3, 0x0002
    
    cmp a0, a1
    jc skip(1)
    or a3, a3, 0x0004
    
    cmp a0, a1
    jnc skip(1)
    or a3, a3, 0x0008
    
    cmp a0, a1
    jbe skip(1)
    or a3, a3, 0x0010
    
    cmp a0, a1
    jl skip(1)
    or a3, a3, 0x0020
    
    cmp a0, a1
    jle skip(1)
    or a3, a3, 0x0040

    cmp a0, a1
    jo skip(1)
    or a3, a3, 0x0080

    cmp a0, a1
    jno skip(1)
    or a3, a3, 0x0100

    cmp a0, a1
    js skip(1)
    or a3, a3, 0x0200

    cmp a0, a1
    jns skip(1)
    or a3, a3, 0x0400

    cmp a0, a1
    jg skip(1)
    or a3, a3, 0x0800

    cmp a0, a1
    jge skip(1)
    or a3, a3, 0x1000

    cmp a0, a1
    ja skip(1)
    or a3, a3, 0x2000
    
    xor a3, a3, 0x3FFF  ; Invert the results (convert to active high)
    
    ret

.size = sizeof_RAM(TEST_JUMPS)




; ALWAYS ON ROM
#bits 32

; Data in program memory:
args: ; Arguments to be tested
#d16    0, 0,      300, 300,    -1, -1,     0, 100,     5, 0x7fff,   10, -10,    0, 0x8000,  -1, 0x8000, 0x8000, 0,  0x8000, 1,  2, 1,       -2, -1
.size = sizeof(args)

outputs: ; Expected outputs
#d16    0x1559,    0x1559,      0x1559,     0x0376,     0x0376,      0x1d16,     0x1a96,     0x3d0a,     0x236a,     0x24ea,     0x3d0a,      0x0376
.size = sizeof(outputs)

progmem_end:

syscall_test:
    mov t0, 0x1234
    sysret
    

MEMORY:
.MemCopy:
    cmp a1, a0      ; If (address of last element) <= (address of first element),
    jbe ..return    ; then return (nothing to copy)
    
..loop:
    peek a3, [a0+0], Up     ; Read upper 16-bit word / opcode
    mov [a2], a3            ; Store to lower address (big endian)
    peek a3, [a0+0], Low    ; Read lower 16-bit word / argument
    mov [a2+1], a3          ; Store to upper address (big endian)
    add a0, a0, 1           ; Increment program memory pointer
    add a2, a2, 2           ; Increment data memory pointer
    
    cmp a0, a1              ; Keep looping until there are no more words
    jne ..loop
    
..return:
    ret



test_data:  #d32 0xBEEFF00D

CALL_GATE:
    call a3
    sysret

