; =====================
;   ASSEMBLER EXAMPLE
; =====================
; This example shows some important aspects of the CESC16 assembler, as well as customasm in general. The program itself doesn't do
; anything useful and some parts are even unreachable. It's meant to give an intuition of how would a real program look like.

; !WARNING: This example is now obsolete and needs to be updated

; Include definition and libraries
#include "CESC16.cpu"
#include "OS/OS.inc"

; constant that can be used as a number
constant = 0x1000 - (2 * 4 + 0x07)


; global variables (you can use #res [and #str]):
#bank data
num:        #res 1 ; reserves 1 16-bit word
result:     #res 1 
vector:     #res 5

    
; program memory
#bank program

; Entry point
MAIN_PROGRAM:

; A word followed by a colon (:) is a label. A label can't be called "zero", "sp" or any other name that conflicts with a register
global_label:
    .local_const = 2        ; Labels and constants that start with a dot (.) are local (only visible whithin 2 global labels)
    
    nop                     ; This is the first program instruction that will be executed
    mov [vector+2], zero    ; Initialize vector[2] to 0
    mov t3, constant        ; Loads 0x0FF1 into t3 (0x10 - (2 * 4 + 0x07) evaluates to 0x0FF1).
    mov s0, .local_const    ; Loads 2 into s0. s0 is a safe register
    
    sub t1, s0, t3          ; t1 = s0 - t3. Note that the contents of s0 and t3 are unchanged
    sub a0, t1, 15          ; a0 = t1 - 15
    mov a0, t1              ; a0 = t1 (move contents from register t1 to register a0)
    
    syscall OUTPUT.char     ; Sends the contents of a0 to the connected output device
    jne .local_label        ; jne is a macro that gets expanded to jnz (jump if s0 - t3 != 0, therefore s0 != t3)
    jmp another_label
    
.local_label:
    mov [num], t1           ; Stores the contents of t1 to the absolute address "num" (global label). Identical to "sw t1, num(zero)"

    mov s2, [num]           ; Loads the contents stored at absoulte address "num" into s2 (safe register). Identical to "lw s2, num(zero)"
    
    mov a0, vector          ; Loads the ADDRESS of vector[0] into a0 (argument register)
    mov a1, [a0+2]          ; Loads the CONTENTS of vector[2] into a1 (argument register). Identical to "lw a1, 2(a0)"

    add [a0+1], t0          ; vector[1] += t0. There is no equivalent instruction in MIPS/RISC-V syntax
    
    call subroutine         ; Calls a subroutine. The arguments are in a0-a2.
    
    mov a0, v0              ; The returned value of the subroutine is in v0. Output the result (as an integer) to the output terminal.
    syscall OUTPUT.uint16
    mov [t0], s2            ; Stores the contents of s2 into the address in t0. The value of s2 has been preserved by the subroutine
    ret                     ; Program ends
    

another_label:              ; From this point, .local_const and .local_label aren't available anymore
    jmp skip(2)             ; Skips the next 2 instructions
.loop:
    jmp .loop               ; Infinite loop
    
    mov t0, t1              ; Copy contents of t1 to t0
    mov [result], t2        ; Store contents of t2 in the reserved space in data memory. Identical to "sw t2, result(zero)"
    
    jmp global_label
    

subroutine:
    push s0                 ; Store to the stack the contents of the safe registers it needs to use
    
    mov s0, 0xABCD
    
    ; ... rest of the subroutine
    
    call MATH.Mult32        ; Calls a subroutine from the MATH library.
    ; As long as the stack isn't full, there is no limit in the depth of subroutine calls.
    
    ; ... rest of the subroutine
    
    pop s0                  ; Restore protected registers
    ret                     ; Return to the point where the subroutine was called
    
