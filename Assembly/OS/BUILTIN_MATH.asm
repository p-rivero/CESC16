; ========================
;  Built-in Math Library
; ========================

; This library provides basic math subroutines that replace hardware instructions
; The implemented instuctions are: MUL, DIV/MOD, RSH, LSH

; Note that CESC16 already implements RSH and LSH, but only for a constant shamt.
; The provided subroutines allow shifting a variable number of bits.


BUILTIN:

; Signed/unsigned 16 bit Multiply
; a0 = a0*a1
; Worst case run time: ~235 clock cycles (~125 cycles if smallest value is 8 bit)
.mul:
    cmp a0, a1      ; If a0 > a1, swap them (run time depends on the value in a0)
    jna .end_swap
    mov t0, a0
    mov a0, a1
    mov a1, t0
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
; Worst case run time: 
.div:
    ; todo
    
    
; Unsigned 16 bit Divide
; a0 = a0/a1 (and a1 = a0%a1)
; Worst case run time: 
.divu:
    ; todo



; Signed 16 bit Modulo
; a0 = a0%a1
; Worst case run time: 7 clock cycles (+ run time of div)
.mod:
    call .div
    mov a0, a1
    
    
; Unsigned 16 bit Modulo
; a0 = a0%a1
; Worst case run time: 7 clock cycles (+ run time of divu)
.modu:
    call .divu
    mov a0, a1



; Signed/unsigned left shift
; a0 = a0<<a1
; Worst case run time: 39 cycles
.var_sll:
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


; Signed right shift
; a0 = a0>>a1
; Worst case run time: 39 cycles
.var_sra:
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


; Unsigned right shift
; a0 = a0>>a1
; Worst case run time: 39 cycles
.var_srl:
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
    
