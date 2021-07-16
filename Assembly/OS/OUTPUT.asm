; =============================
;  VGA Terminal Output Library
; =============================

#bank data
Print_Buffer: #res 8

#bank program

OUTPUT:

; -------------------------------
; OUTPUTTING DIFFERENT DATA TYPES
; -------------------------------

; Waits until the terminal is available and prints
; a char stored in the lower bits of a0.
.char:
    test [TERMINAL_ADDR]    ; Read flag
    jnz .char               ; Poll until it's 0 (terminal ready)
    ; Arduino Terminal accepts 1 byte every 32 us.
    ; (shortest access loop: 18 cycles, when [syscall OUTPUT.char; mov a0, x; syscall OUTPUT.char] is performed)
    ; - 1 MHz: At most, the polling loops 4 times (with polling every 6 us)
    ; - 2 MHz: At most, the polling loops 9 times (with polling every 3 us)
    
    mov [TERMINAL_ADDR], a0     ; Send char to terminal
    ret
    
    
; Prints the contents of a0 as an UNSIGNED integer.
; TODO: calculate time of division method
.uint16:
    cmp a0, 10
    jnb ..continue
    ; If the input is a number between 0 and 9, just print it and return
    add a0, a0, "0"
    jmp .char
    
..continue:
    ; Implement 16 bit Double dabble algorithm (convert to BCD)
    ; Takes ~1000 cycles
    mov t0, 16      ; Iteration counter
    mov a1, zero    ; BCD output is stored in a1 and a2
    mov a2, zero
    
..loop:
    ; For each BCD digit (4 bits) that is >= 5, increment it by 3
    ; Test lowest BCD digit
    and t1, a1, 0x000F
    cmp t1, 0x0005
    jb skip(1)
    add a1, a1, 0x0003
    
    ; Test 2nd BCD digit
    and t1, a1, 0x00F0
    cmp t1, 0x0050
    jb skip(1)
    add a1, a1, 0x0030
    
    ; Test 3rd BCD digit
    and t1, a1, 0x0F00
    cmp t1, 0x0500
    jb skip(1)
    add a1, a1, 0x0300
    
    ; Test 4th BCD digit
    and t1, a1, 0xF000
    cmp t1, 0x5000
    jb skip(1)
    add a1, a1, 0x3000
    
    ; The 5th BCD digit (lower bits of a2) doesn't need to be tested, since it will never be more than 3

    sll a0, a0, 1   ; Shift all registers 1 position
    sllc a1, a1
    sllc a2, a2
    
    sub t0, t0, 1
    jnz ..loop      ; Iterate 16 times
    
    ; At this point, a0 = 0 and a2,a1 contain BCD. t0 and t1 are free to use
    ; Store numbers to print
    and t0, a1, 0x000F  ; Store lowest BCD digit
    mov [Print_Buffer+4], t0
    srl a1, a1, 4
    and t0, a1, 0x000F  ; Store 2nd BCD digit
    mov [Print_Buffer+3], t0
    srl a1, a1, 4
    and t0, a1, 0x000F  ; Store 3rd BCD digit
    mov [Print_Buffer+2], t0
    srl t0, a1, 4
    mov [Print_Buffer+1], t0  ; Store 4th BCD digit
    mov [Print_Buffer], a2    ; Store most significant BCD digit (5th)
    
; Remove leading zeroes
    mov t0, Print_Buffer-1
..rem_zeroes:
    add t0, t0, 1
    movf a0, [t0]
    jz ..rem_zeroes

; Print number from first non-zero digit onward
..print:        
    add a0, a0, "0"
    call .char
    add t0, t0, 1
    mov a0, [t0]
    cmp t0, Print_Buffer+4
    jbe ..print ; Loop while pointer is below or equal the address of last digit
    
    ret
    
    
; Prints the contents of a0 as a SIGNED integer.
.int16:
    cmp zero, a0
    jle .uint16   ; If 0 <= n, print n as an unsigned integer
    
    ; If number is strictly negative, output '-' and print absolute value
    mov t0, a0
    mov a0, "-"
    syscall .char
    sub a0, zero, t0
    jmp .uint16   ; Print unsigned integer and return


; Prints the contents of a1,a0 as an UNSIGNED 32-bit integer (a1 contains upper bits).
.uint32:
    ; TODO: 32 bit Double dabble
    ret
    
    
; Prints the contents of a1,a0 as a SIGNED 32-bit integer (a1 contains upper bits).
.int32:
    cmp zero, a1
    jle .uint32   ; If 0 <= n, print n as an unsigned integer
    
    ; If number is strictly negative, output '-' and print absolute value
    mov t0, a0
    mov a0, "-"
    syscall .char
    sub a0, zero, t0    ; Negate a1,t0 and store in a1,a0
    subb a1, zero, a1
    jmp .uint32   ; Print unsigned integer and return



; Prints a null-terminated string (constructed in RAM). a0 points at the first char of the string
; WARNING: each 16-bit word contains A SINGLE 8-bit char (upper 8 bits must be 0x00)
.string:
    mov a1, a0      ; Move pointer to a1 (use a0 as argument of .char)
..loop:
    movf a0, [a1]   ; Load next char
    jz ..return     ; If it's the null character, return
    call .char      ; Else, print the char
    add a1, a1, 1   ; Increment pointer
    jmp ..loop
..return:
    ret

; Prints a null-terminated string (stored in RAM). a0 points at the first char of the string
; WARNING: each 16-bit word contains TWO 8-bit chars (no bits are ignored)
.string_RAM:
    mov a1, a0      ; Move pointer to a1 (use a0 as argument of .char)
..loop:
    mov a2, [a1]    ; Load next pair of chars
    srl a0, a2, 8   ; Get upper bits (lower address in big endian)
    jz ..return     ; If it's the null character, return
    call .char      ; Else, print the char

    and a0, a2, 0x00FF  ; Get lower bits (upper address in big endian)
    jz ..return     ; If it's the null character, return
    call .char      ; Else, print the char

    add a1, a1, 1   ; Increment pointer
    jmp ..loop
..return:
    ret

; Prints a null-terminated string (stored in ROM). a0 points at the first char of the string
; WARNING: each 32-bit word contains FOUR 8-bit chars (no bits are ignored)
.string_ROM:
    mov a1, a0      ; Move pointer to a1 (use a0 as argument of .char)
..loop:
    peek a2, [a1], Up   ; Load next pair of chars (upper bits -> lower address in big endian)
    srl a0, a2, 8   ; Get upper bits (lower address in big endian)
    jz ..return     ; If it's the null character, return
    call .char      ; Else, print the char

    and a0, a2, 0x00FF  ; Get lower bits (upper address in big endian)
    jz ..return     ; If it's the null character, return
    call .char      ; Else, print the char

    peek a2, [a1], Low  ; Load next pair of chars (lower bits -> upper address in big endian)
    srl a0, a2, 8   ; Get upper bits (lower address in big endian)
    jz ..return     ; If it's the null character, return
    call .char      ; Else, print the char

    and a0, a2, 0x00FF  ; Get lower bits (upper address in big endian)
    jz ..return     ; If it's the null character, return
    call .char      ; Else, print the char

    add a1, a1, 1   ; Increment pointer
    jmp ..loop
..return:
    ret

; ----------------
; TERMINAL CONTROL
; ----------------

; Clears entire screen and moves the cursor to the top-left
; corner (row 1, column 1).
.Reset:
    ; PLACEHOLDER
    ;call .SetColor.White
    ret
    

; Call with OUTPUT.SetColor.Red
.SetColor:
..Red:
..White:
    ; PLACEHOLDER
    ret
    