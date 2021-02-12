#include "CESC16.cpu"

#bank program

    ; Perform restart
    nop
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
    or t0, t1, t2       ; t0 = 0x0003, flags: none
    add t0, t0, t2      ; t0 = 0x0005, flags: none
    add sp, sp, 0xE123  ; sp = 0x6124, flags: Carry, oVerflow
    mov sp, v0          ; sp = 0x1000, flags unchanged
    sll sp, sp, 3       ; sp = 0x8000, flags: Sign
    sra v0, sp, 9       ; v0 = 0xFFC0, flags: Sign (, Carry)
    srl v0, sp, 9       ; v0 = 0x0040, flags: none (Carry)
    sra v0, v0, 1       ; v0 = 0x0020, flags: none (Carry)
    sll sp, sp, 1       ; sp = 0x0000, flags: Zero, Carry
    movf sp, 0x0001     ; sp = 0x0001, flags: none
    sra v0, sp, 1       ; v0 = 0x0000, flags: Zero
    srl sp, sp, 1       ; sp = 0x0000, flags: Zero (Carry)
    mov sp, 0x1234      ; sp = 0x1234, flags unchanged
    mov v0, sp          ; v0 = 0x1234, flags unchanged
    addc v0, v0, 0x20   ; v0 = 0x1255, flags: none
    addc v0, sp, 0x20   ; v0 = 0x1254, flags: none
    mov t0, 0xAAAA      ; t0 = 0xAAAA, flags unchanged
    xor t1, v0, 0xAAAA  ; t1 = 0xB8FE, flags: Sign (oVerflow)
    clrf                ; registers unchanged, flags: none
    xor t1, v0, t0      ; t1 unchanged, flags: Sign (oVerflow)
    add t2, t0, t1      ; t2 = 0x63A8, flags: oVerflow, Carry
    sub t2, t0, t1      ; t2 = 0xF1AC, flags: Sign
    subb t2, t2, 0x8001 ; t2 = 0x71AA, flags: Carry
    subb t2, t2, 0x8001 ; t2 = 0xF1A9, flags: oVerflow, Sign
    subb t3, t2, zero   ; t3 = 0xF1A8, flags: Carry, Sign
    xor t3, t3, t3      ; t3 = 0x0000, flags: Zero (Carry)


    ; Test load/store


    ; Test I/O
    

    ; Test conditional jumps
    ; TODO: Test bàsic i després cridar test_jumps.asm


    ; Test ALU addressing modes


    ; Test call/ret
    

    ; Copy to RAM and repeat


    ; Test finished!
    jmp pc
