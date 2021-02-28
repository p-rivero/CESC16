#include "CESC16.cpu"
#include "OS/OS.inc"

; Program for checking if all the conditional jumps work. At the end the result is sent to the output device:
; - All tests passed: 'K' (0x4B)
; - 1 or more tests failed: 'F' (0x46)

; WARNING: THE JMP AND JNZ (JNE) INTRUCTIONS NEED TO BE CHECKED MANUALLY, SINCE THIS TEST DEPENDS ON THEM

#bank program

; Data in program memory:
args: ; Arguments to be tested
#d16    0, 0,      300, 300,    -1, -1,     0, 100,     5, 0x7fff,   10, -10,    0, 0x8000,  -1, 0x8000, 0x8000, 0,  0x8000, 1,  2, 1,       -2, -1
.size = sizeof(args)

outputs: ; Expected outputs
#d16    0x1559,    0x1559,      0x1559,     0x0376,     0x0376,      0x1d16,     0x1a96,     0x3d0a,     0x236a,     0x24ea,     0x3d0a,      0x0376
.size = sizeof(outputs)

progmem_end:


; User program entry point
MAIN_PROGRAM:
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
    jne .error      ; If outputs don't match, display error
    
    add s0, s0, 2
    add s1, s1, 1
    
    cmp s0, s2      ; Check if all tests have been performed
    jne ..loop
    
    ; Previously, the success message was displayed here, but this could cause problems in the case that jumps
    ; don't work at all (the success message would be shown even though jumps would clearly not work).
    ; Moving .success under .error can solve this edge case
    je .success
    
..end:
    add sp, sp, args.size + outputs.size    ; Free space in stack
    pop s2
    pop s1
    pop s0
    ret
    
    
; Called if a test fails
.error:
    mov a0, "F"
    syscall OUTPUT.char
    syscall TIME.Halt

; Called if all tests succeed
.success:
    mov a0, "K"     ; All tests passed!
    syscall OUTPUT.char
    jmp .main.end

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
