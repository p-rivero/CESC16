; =======================
;  Advanced Math Library
; =======================

; This library provides subroutines for performing the math
; operations that are not included in the basic builtin library
; (anything other than 16 bit MUL/DIV/MOD).

#bank program

MATH:

; Signed or Unsigned 32 bit * 16 bit Multiply
; Arguments: a1_a0 = N, a2 = M   (a0 = lower bits)
; Returns: a1_a0 = n*m   (a0 = lower bits)
; Worst case run time: ~330 clock cycles (170 if M is 8 bit)
.umul32:
.mul32:
    mov t0, zero    ; Set the result to 0 (lower bits)
    mov t1, zero    ; Set the result to 0 (upper bits)

..while: 
    mask a2, 0x0001 ; Test last bit
    jz ..endif
    add t0, t0, a0
    addc t1, t1, a1 ; Add A to the result (16 bit add)
..endif:
    
    sll a0, a0, 1   ; Shift lower A to the left and store carry
    sllc a1, a1     ; Shift upper A to the left with carry
    srl a2, a2, 1   ; Shift B to the right
    jnz ..while     ; Keep looping until B == 0
    
..endwhile:
    mov a0, t0      ; Copy the result to the return registers
    mov a1, t1
    ret
    
    
    
; Unsigned 32 bit / 16 bit Divide
; Arguments: a1_a0 = N, a2 = M   (a0 = lower bits)
; Returns: a1_a0 = n/m   (a0 = lower bits)
; Worst case run time:
.udiv32:
    
    ret
    
    
    
; Signed 32 bit / 16 bit Divide
; Arguments: a1_a0 = N, a2 = M   (a0 = lower bits)
; Returns: a1_a0 = n/m   (a0 = lower bits)
; Worst case run time:
.div32:

    ret
    
    
    
.pow:
    ; a^b
    ; int pow (int a, int b) {
    ; if (b==0) return 1;
    ; if (b==1) return a;
    ; s0 = a
    ; s1 = b
    ; v = pow(a, b<<2)
    ; v = v*v
    ; if (b&1) v = v*a
    ; return v }

    ret
    
    
    
.pow32:

    ret
    
    
    
.sqrt:
    ; ??
    ret
    
; Lookup tables for trigonometric functions?
    