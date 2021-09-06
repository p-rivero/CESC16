; ========================
;  Built-in Math Library
; ========================

; This library provides basic math subroutines that replace hardware instructions
; The implemented instuctions are: MUL, DIV/MOD, RSH, LSH

; Note that CESC16 already implements RSH and LSH, but only for a constant shamt.
; The provided subroutines allow shifting a variable number of bits.


; Signed/unsigned 16 bit Multiply
; a0 = a0*a1
; Worst case run time: ~235 clock cycles (~125 cycles if smallest value is 8 bit)
mul:
    cmp a0, a1      ; If a0 > a1, swap them (run time depends on the value in a0)
    jna .end_swap
    mov a2, a0
    mov a0, a1
    mov a1, a2
.end_swap:
    mov a2, 0   ; Set result to 0
    
..while:
    mask a0, 1  ; Test last bit
    jz ..endif
    add a2, a2, a1  ; If Last bit is 1, add m to result
..endif:

    sll a1, a1, 1   ; Shift m to the left
    srl a0, a0, 1   ; Shift n to the right
    jnz ..while     ; Keep looping until n == 0
    
    mov a0, a2      ; Return the result on a0
    ret
    
    
; Signed 16 bit Divide
; a0 = a0/a1 (and a1 = a0%a1)
; Run time: 32 cycles (+ run time of divu)
div:
    movf t1, a0
    jns skip(1)
    sub a0, zero, a0
    
    movf t2, a1
    jns skip(1)
    sub a1, zero, a1
    
    call divu
    
    xor zero, t1, t2
    jns skip(1)
    sub a0, zero, a0
    
    test t1
    jns skip(1)
    sub a1, zero, a1
    
    ret
    
    
; Unsigned 16 bit Divide
; a0 = a0/a1 (and a1 = a0%a1)
; Worst case run time: ~320 clock cycles (average of 270 cycles)
divu:
    mov a2, 0   ; Initialize remainder
    
.dont_init_rem:
    mov t0, 16  ; Count 16 iterations
    mov a3, 0   ; Initialize quotient

.loop:
    sll a0, a0, 1   ; Shift top bit of n
    sllc a2, a2     ; Shift remainder and add shifted bit
    sll a3, a3, 1   ; Quotient * 2
    
    cmp a2, a1      ; If remainder > a1 (denominator), subtract it and increment quotient
    jb skip(2)
    sub a2, a2, a1  ; Subtract denominator from remainder
    add a3, a3, 1   ; Set bottom bit of quotient (we know it's zero)
    
    ; === LOOP UNROLL (same as first iteration) ===
    sll a0, a0, 1
    sllc a2, a2
    sll a3, a3, 1
    cmp a2, a1
    jb skip(2)
    sub a2, a2, a1
    add a3, a3, 1
    ; ---------------------------------------------
    
    ; === LOOP UNROLL (same as first iteration) ===
    sll a0, a0, 1
    sllc a2, a2
    sll a3, a3, 1
    cmp a2, a1
    jb skip(2)
    sub a2, a2, a1
    add a3, a3, 1
    ; ---------------------------------------------
    
    ; === LOOP UNROLL (same as first iteration) ===
    sll a0, a0, 1
    sllc a2, a2
    sll a3, a3, 1
    cmp a2, a1
    jb skip(2)
    sub a2, a2, a1
    add a3, a3, 1
    ; ---------------------------------------------
    
    sub t0, t0, 4   ; Decrement iteration counter (unrolled: 4 iterations)
    jnz .loop
    
    mov a0, a3  ; Quotient
    mov a1, a2  ; Remainder
    ret



; Signed 16 bit Modulo
; a0 = a0%a1
; Worst case run time: 7 clock cycles (+ run time of div)
mod:
    call div
    mov a0, a1
    ret
    
    
; Unsigned 16 bit Modulo
; a0 = a0%a1
; Worst case run time: 7 clock cycles (+ run time of divu)
modu:
    call divu
    mov a0, a1
    ret



; Signed/unsigned left shift
; a0 = a0<<a1
; Worst case run time: 39 cycles
var_sll:
    mask a1, 0b0001
    jz skip(1)
    sll a0, a0, 1
    
    mask a1, 0b0010
    jz skip(1)
    sll a0, a0, 2
    
    mask a1, 0b0100
    jz skip(1)
    sll a0, a0, 4
    
    mask a1, 0b1000
    jz skip(1)
    sll a0, a0, 8
    ret


; Signed right shift
; a0 = a0>>a1
; Worst case run time: 39 cycles
var_sra:
    mask a1, 0b0001
    jz skip(1)
    sra a0, a0, 1
    
    mask a1, 0b0010
    jz skip(1)
    sra a0, a0, 2
    
    mask a1, 0b0100
    jz skip(1)
    sra a0, a0, 4
    
    mask a1, 0b1000
    jz skip(1)
    sra a0, a0, 8
    ret


; Unsigned right shift
; a0 = a0>>a1
; Worst case run time: 39 cycles
var_srl:
    mask a1, 0b0001
    jz skip(1)
    srl a0, a0, 1
    
    mask a1, 0b0010
    jz skip(1)
    srl a0, a0, 2
    
    mask a1, 0b0100
    jz skip(1)
    srl a0, a0, 4
    
    mask a1, 0b1000
    jz skip(1)
    srl a0, a0, 8
    ret
    
