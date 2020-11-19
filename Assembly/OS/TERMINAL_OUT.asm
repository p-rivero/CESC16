; =============================
;  VGA Terminal Output Library
; =============================

#bank program
#bits 32

PRINT:

; -------------------------------
; OUTPUTTING DIFFERENT DATA TYPES
; -------------------------------

; Waits until the terminal is available and prints
; a char stored in the lower bits of a0.
.Char:
    test (TERMINAL_ADDR)    ; Read flag
    jnz .Char               ; Poll until it's 0 (terminal ready)
    ; Arduino Terminal accepts 1 byte every 32 us.
    ; (shortest access loop: 18 cycles, when [syscall PRINT.Char; mov a0, x; syscall PRINT.Char] is performed)
    ; - 1 MHz: At most, the polling loops 4 times (with polling every 6 us)
    ; - 2 MHz: At most, the polling loops 9 times (with polling every 3 us)
    
    mov (TERMINAL_ADDR), a0     ; Send char to terminal
    ret
    
    
; Prints the contents of a0 as an UNSIGNED integer.
; TODO: do not print leading 0s (00012 -> 12)
; TODO: calculate time of division method
.Word:
    ; Implement 16 bit Double dabble algorithm (convert to BCD)
    ; Takes between 850 and 900 cycles
    push s0
    mov s0, 16      ; Iteration counter
    mov a1, zero    ; BCD output is stored in a1 and a2
    mov a2, zero
    
..loop:
    ; For each BCD digit (4 bits) that is >= 5, increment it by 3
    ; Test lowest BCD digit
    and v0, a1, 0x000F
    cmp v0, 0x0005
    jltu skip(1)
    add a1, a1, 0x0003
    
    ; Test 2nd BCD digit
    and v0, a1, 0x00F0
    cmp v0, 0x0050
    jltu skip(1)
    add a1, a1, 0x0030
    
    ; Test 3rd BCD digit
    and v0, a1, 0x0F00
    cmp v0, 0x0500
    jltu skip(1)
    add a1, a1, 0x0300
    
    ; Test 4th BCD digit
    and v0, a1, 0xF000
    cmp v0, 0x5000
    jltu skip(1)
    add a1, a1, 0x3000
    
    ; The 5th BCD digit (lower bits of a2) doesn't need to be tested, since it will never be more than 3

    sll a0, a0, 1   ; Shift all registers 1 position
    sllc a1, a1
    sllc a2, a2
    
    sub s0, s0, 1
    jnz ..loop      ; Iterate 16 times
    
    ; Now print the BCD in order
    
    ; Print most significant BCD digit (5th)
    add a0, a2, "0"
    call .Char
    
    and s0, a1, 0x000F ; Save lowest BCD digit
    srl a1, a1, 4
    and a2, a1, 0x000F ; Save 2nd BCD digit
    srl a1, a1, 4
    and v0, a1, 0x000F ; Save 3rd BCD digit
    
    srl a0, a1, 4       ; Print 4th BCD digit
    add a0, a0, "0"
    call .Char
    
    add a0, v0, "0"     ; Print 3rd BCD digit
    call .Char
    
    add a0, a2, "0"     ; Print 2nd BCD digit
    call .Char
    
    add a0, s0, "0"     ; Print least significat BCD digit
    call .Char
    
    pop s0  ; Restore context and return
    ret
    
    
; Prints the contents of a0 as a SIGNED integer.
.Signed:
    cmp a0, zero
    jle ..continue
    
    ; If number is strictly negative, output '-' and print absolute value
    mov a2, a0
    mov a0, "-"
    syscall .Char
    sub a0, zero, a2
..continue:    
    j .Word  ; Print unsigned integer and return


; Prints the contents of a1,a0 as aN UNSIGNED 32-bit integer (a1 contains upper bits).
.DWord:
    ; TODO
    ret
    
    
; Prints the contents of a1,a0 as a SIGNED 32-bit integer (a1 contains upper bits).
.DSigned:
    cmp a1, zero
    jle ..continue
    
    ; If number is strictly negative, output '-' and print absolute value
    mov a2, a0
    mov a0, "-"
    syscall .Char
    sub a0, zero, a2    ; Invert a1,a2 and store in a1,a0
    subb a1, zero, a1
..continue:    
    j .Word  ; Print unsigned integer and return
    ret

.String:
    ; TODO: Print chars and increment pointer until null char
    ret

; ----------------
; TERMINAL CONTROL
; ----------------

; Clears entire screen and moves the cursor to the top-left
; corner (row 1, column 1).
.Reset:
    ;call .SetColor.White
    ret
    

; Call with PRINT.SetColor.Red
.SetColor:
..Red:
..White:
; ...
    ret
    