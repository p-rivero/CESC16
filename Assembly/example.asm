; =====================
;   ASSEMBLER EXAMPLE
; =====================
; This example shows some important aspects of the CESC16 assembler, as well as customasm in general. The program itself doesn't do
; anything useful and some parts are even unreachable. It's meant to give an intuition of how would a real program look like.

#include "CESC16.cpu" ; Include cpudef
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
    
    nop                     ; This is the first instruction that will be executed (PC=0x0000)
    mov (vector+2), zero    ; Debug
    mov t3, constant        ; Loads 0x0FF1 into t3 (0x10 - (2 * 4 + 0x07) evaluates to 0x0FF1).
    mov s0, .local_const    ; Loads 2 into s0. s0 is a safe register
    sub t1, s0, t3          ; t1 = s0 - t3. Note that the contents of s0 and t3 are unchanged
    sw t1, num(zero)        ; Stores the contents of t1 to the absolute address "num" (global label)
    mov a0, t1              
    syscall PRINT.Char      ; Sends the contents of t1 to the connected output device
    jne .local_label        ; jne is a macro that gets expanded to jnz (jump if s0 - t3 != 0, therefore s0 != t3)
    j another_label
    
.local_label:
    lw s2, num(zero)        ; Loads the contents stored at absoulte address "num" into t2.
    mov t0, vector          ; Loads the address of vector[0]
    lw t1, 2(t0)            ; Loads the contents of vector[2] into R1
    call subroutine         ; Calls a subroutine. The arguments are in the temporary regsiters
    
    mov a0, v0              ; The returned value of the subroutine is in  v0. Outputs the result to the output terminal.
    syscall PRINT.Word
    mov (t0), s2            ; Stores the contents of s2 into the address in t0. The value of s2 has been preserved by the subroutine
    ret                     ; Program ends

loop:
    j loop                  ; Debug

another_label:              ; From this point, .local_const and .local_label aren't available anymore
    mov t0, t1              ; Copy contents of t1 to t0
    ; sw t2, result(zero)   ; Store contents of t2 to the reserved space in data memory
    
    lw a0, vector+4(zero)   ; Outputs contents of vector[4] to the output device
    syscall PRINT.Word
    j global_label
    

subroutine:
    push s0                 ; Store to the stack the contents of the safe registers it needs to use
    
    mov s0, 0xABCD
    
    ; ... rest of the subroutine
    
    call MATH.Mult32             ; Calls a subroutine from the MATH library.
    ; As long as the stack isn't full, there is no limit in the depth of subroutine calls.
    
    ; ... rest of the subroutine
    
    pop s0                  ; Restore protected registers
    ret                     ; Return to the point where the subroutine was called
    
