; =============================
;  VGA Terminal Output Library
; =============================

#bank data
Print_Buffer: #res 8

#bank program

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
; TODO: calculate time of division method
.Word:
    cmp a0, 10
    jltu skip(1)
    j ..continue
    ; If the input is a number between 0 and 9, just print it and return
    add a0, a0, "0"
    j .Char
    
..continue:
    ; Implement 16 bit Double dabble algorithm (convert to BCD)
    ; Takes ~1000 cycles
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
    
    ; At this point, a0 = 0 and a2,a1 contain BCD. s0 and v0 are free to use
    ; Store numbers to print
    and s0, a1, 0x000F  ; Store lowest BCD digit
    mov (Print_Buffer+4), s0
    srl a1, a1, 4
    and s0, a1, 0x000F  ; Store 2nd BCD digit
    mov (Print_Buffer+3), s0
    srl a1, a1, 4
    and s0, a1, 0x000F  ; Store 3rd BCD digit
    mov (Print_Buffer+2), s0
    srl s0, a1, 4
    mov (Print_Buffer+1), s0  ; Store 4th BCD digit
    mov (Print_Buffer), a2    ; Store most significant BCD digit (5th)
    
; Remove leading zeroes
    mov s0, Print_Buffer-1
..rem_zeroes:           
    add s0, s0, 1
    movf a0, (s0)
    jz ..rem_zeroes

; Print number from first non-zero digit onward
..print:        
    add a0, a0, "0"
    call .Char
    add s0, s0, 1
    mov a0, (s0)
    cmp s0, Print_Buffer+4
    jleu ..print ; Loop while pointer is less or equal than address of last digit
    
    pop s0  ; Restore context and return
    ret
    
    
; Prints the contents of a0 as a SIGNED integer.
.Signed:
    cmp zero, a0
    jle ..continue
    
    ; If number is strictly negative, output '-' and print absolute value
    mov a2, a0
    mov a0, "-"
    syscall .Char
    sub a0, zero, a2
..continue:    
    j .Word  ; Print unsigned integer and return


; Prints the contents of a1,a0 as an UNSIGNED 32-bit integer (a1 contains upper bits).
.DWord:
    ; TODO: 32 bit Double dabble
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
    