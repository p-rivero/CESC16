#include "CESC16.cpu"

#define DO_MANUAL_TEST ; Comment out (using ;) this line to skip the initial manual test

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

    ; Test basic ALU instructions and flags
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
    subb t2, t2, 0x8001 ; t2 = 0x71AA, flags: None
    subb t2, t2, 0x8001 ; t2 = 0xF1A9, flags: oVerflow, Sign, Carry
    subb t3, t2, zero   ; t3 = 0xF1A8, flags: Sign
    xor t3, t3, t3      ; t3 = 0x0000, flags: Zero
    sll t4, t2, 15      ; t4 = 0x8000, flags: Sign
    srl s4, t4, 15      ; s4 = 0x0001, flags: none
    sra s4, t4, 15      ; s4 = 0xFFFF, flags: Sign
    

    ; Test unconditional and conditional jumps
    ; TODO


    ; Test load/store + memory operations
    ; TODO


    ; Test basic I/O
    ; TODO


    ; Test stack (push(f)/pop(f) + call/ret)
    ; TODO

#endif


AUTOMATED_TEST:

    mov t0, 0x0100
    mov [FAILURE_CAUSE], t0
    ; Test conditional jumps
    ; TODO: Copy and delete test_jumps.asm


    mov t0, 0x0001
    mov [FAILURE_CAUSE], t0
    ; Repeat manual test

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
    jnc FAILURE
    jo FAILURE
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
    jo FAILURE
    jns FAILURE
    cmp sp, 0x8000
    jne FAILURE

    sra v0, sp, 9       ; v0 = 0xFFC0, flags: Sign
    jz FAILURE
    jc FAILURE
    jo FAILURE
    jns FAILURE
    cmp v0, 0xFFC0
    jne FAILURE

    srl v0, sp, 9       ; v0 = 0x0040, flags: none
    jz FAILURE
    jc FAILURE
    jo FAILURE
    js FAILURE
    cmp v0, 0x0040
    jne FAILURE

    sra v0, v0, 1       ; v0 = 0x0020, flags: none
    jz FAILURE
    jc FAILURE
    jo FAILURE
    js FAILURE
    cmp v0, 0x0020
    jne FAILURE

    sll sp, sp, 1       ; sp = 0x0000, flags: Zero, Carry
    jnz FAILURE
    jnc FAILURE
    jo FAILURE
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
    jnc FAILURE
    jo FAILURE
    js FAILURE
    cmp v0, zero
    jne FAILURE

    srl sp, sp, 1       ; sp = 0x0000, flags: Zero
    jnz FAILURE
    jc FAILURE
    jo FAILURE
    js FAILURE
    cmp sp, zero
    jne FAILURE

    mov sp, 0x1234      ; sp = 0x1234, flags unchanged
    jnz FAILURE
    jc FAILURE
    jo FAILURE
    js FAILURE
    cmp sp, 0x1234
    jne FAILURE

    mov v0, sp          ; v0 = 0x1234, flags unchanged
    jnz FAILURE
    jc FAILURE
    jo FAILURE
    js FAILURE
    cmp v0, sp
    jne FAILURE

    push 0b1111         ; sp = 0x1233, flags unchanged
    jnz FAILURE
    jc FAILURE
    jo FAILURE
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
    jnc FAILURE
    jno FAILURE
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
    jnc FAILURE
    jno FAILURE
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

    subb t2, t2, 0x8001 ; t2 = 0x71AA, flags: None
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
    jc FAILURE
    jo FAILURE
    js FAILURE
    cmp t3, zero
    jne FAILURE

    sll t4, t2, 15      ; t4 = 0x8000, flags: Sign
    jz FAILURE
    jc FAILURE
    jo FAILURE
    jns FAILURE
    cmp t4, 0x8000
    jne FAILURE

    srl s4, t4, 15      ; s4 = 0x0001, flags: none
    jz FAILURE
    jc FAILURE
    jo FAILURE
    js FAILURE
    cmp s4, 0x0001
    jne FAILURE

    sra s4, t4, 15      ; s4 = 0xFFFF, flags: Sign
    jz FAILURE
    jc FAILURE
    jo FAILURE
    jns FAILURE
    cmp s4, 0xFFFF
    jne FAILURE


    mov t0, 0x0002
    mov [FAILURE_CAUSE], t0
    ; Test ALU addressing modes (direct)
    ; TODO


    mov t0, 0x0003
    mov [FAILURE_CAUSE], t0
    ; Test ALU addressing modes (indirect)
    ; TODO
    

    mov t0, 0x0004
    mov [FAILURE_CAUSE], t0
    ; Test ALU addressing modes (indexed)
    ; TODO


    mov t0, 0x0005
    mov [FAILURE_CAUSE], t0
    ; Test ALU addressing modes (direct destination)
    ; TODO


    mov t0, 0x0006
    mov [FAILURE_CAUSE], t0
    ; Test ALU addressing modes (indirect destination)
    ; TODO


    mov t0, 0x0007
    mov [FAILURE_CAUSE], t0
    ; Test ALU addressing modes (indexed destination)
    ; TODO


    mov t0, 0x0010
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
    mov sp, 0xFFFF

    mov a0, "F"
    call Output_char
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
    mov sp, 0xFFFF
    jmp pc

    ; TODO: Improve success message
    mov a0, "O"
    call Output_char
    mov a0, "K"
    call Output_char
    mov a0, 0xFFFF


Output_char:
    test [TERMINAL_ADDR]    ; Read flag
    jnz Output_char         ; Poll until it's 0 (terminal ready)
    
    mov [TERMINAL_ADDR], a0     ; Send char to terminal
    ret
