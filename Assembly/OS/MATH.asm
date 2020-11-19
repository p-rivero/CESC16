

#bank program
#bits 32

MATH:

; Signed or Unsigned 16 bit Multiply
; Arguments: a0 = N, a1 = M
; Returns: v0 = N*M
; Worst case run time: ~230 clock cycles (~120 cycles if M is 8 bit)
.UMult:
.Mult:
    mov v0, 0   ; Set result to 0
    test a0
    jz ..return  ; if n == 0, return 0
    
..while:
    mask a0, 1  ; Test last bit
    jz ..endif
    add v0, v0, a1  ; If Last bit is 1, add m to result
..endif:

    sll a1, a1, 1   ; Shift m to the left
    srl a0, a0, 1   ; Shift n to the right
    jnz ..while     ; Keep looping until n == 0
    
..return:
    ret



; Signed or Unsigned 32 bit * 16 bit Multiply
; Arguments: a1_a0 = N, a2 = M   (a0 = lower bits)
; Returns: t4_v0 = n*m   (v0 = lower bits)
; Worst case run time: ~330 clock cycles (170 if M is 8 bit)
.UMult32:
.Mult32:
    mov v0, zero    ; Set the result to 0 (lower bits)
    mov t4, zero    ; Set the result to 0 (upper bits)
    
    test a2
    jz ..endwhile   ; if B == 0, return 0

..while: 
    mask a2, 0x01       ; Test last bit
    jz ..endif
    add v0, v0, a0      
    addc t4, t4, a1     ; Add A to the result (16 bit add)
..endif:
    
    sll a0, a0, 1       ; Shift lower A to the left and store carry
    sllc a1, a1         ; Shift upper A to the left with carry
    srl a2, a2, 1       ; Shift B to the right
    jnz ..while         ; Keep looping until B == 0
    
..endwhile:
    ret
    
    
    
.UDiv:
    
    ret
    
.Div:

    ret
    
.UDiv32:
    
    ret
    
.Div32:

    ret
    
.Pow:
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

.Pow32:

    ret
    
.Sqrt:
    ; ??
    ret
    
; Lookup tables for trigonometric functions?
    