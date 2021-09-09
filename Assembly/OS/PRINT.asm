; =============================
;  VGA Terminal Output Library
; =============================

#bank data
_Print_Buffer: #res 5    ; Decimal for 0xFFFF has 5 digits

#bank program

PRINT:

; Prints the contents of a0 as an UNSIGNED integer.
.uint16:
    ; If the input is a number between 0 and 9, just print it and return
    cmp a0, 10
    jnb ..skip_1_digit
    add a0, a0, "0"
    jmp OUTPUT.char
..skip_1_digit:
    
    ; If the input is a number between 10 and 99, separate the 2 digits with a div by 10
    ; (This method takes ~320 cycles instead of ~880)
    cmp a0, 100
    jnb ..skip_2_digits
..print_2_digits:
    mov a1, 10
    call div
    add a0, a0, "0"     ; a0 contains result (10s)
    syscall OUTPUT.char
    add a0, a1, "0"     ; a1 contains remainder (1s)
    jmp OUTPUT.char
..skip_2_digits:

    ; If the input is a number between 100 and 999, separate the first digits with a div by 100
    ; (This method takes ~630 cycles instead of ~915)
    cmp a0, 1000
    jnb ..skip_3_digits
    mov a1, 100
    call div
    add a0, a0, "0"     ; a0 contains result (100s)
    syscall OUTPUT.char
    mov a0, a1          ; a1 contains remainder (10s+1s)
    jmp ..print_2_digits
..skip_3_digits:

    ; For 4 and 5 digit numbers, implement 16 bit Double dabble algorithm (convert to BCD)
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
    mov [_Print_Buffer+4], t0
    srl a1, a1, 4
    and t0, a1, 0x000F  ; Store 2nd BCD digit
    mov [_Print_Buffer+3], t0
    srl a1, a1, 4
    and t0, a1, 0x000F  ; Store 3rd BCD digit
    mov [_Print_Buffer+2], t0
    srl t0, a1, 4
    mov [_Print_Buffer+1], t0  ; Store 4th BCD digit
    mov [_Print_Buffer], a2    ; Store most significant BCD digit (5th)
    
    jmp ._Output_PrintBuffer
    

; Prints the contents of a0 as a SIGNED integer.
.int16:
    cmp zero, a0
    jle .uint16   ; If 0 <= n, print n as an unsigned integer
    
    ; If number is strictly negative, output '-' and print absolute value
    mov t0, a0
    mov a0, "-"
    syscall OUTPUT.char
    sub a0, zero, t0
    jmp .uint16   ; Print unsigned integer and return
    

; Prints the HEX representation of the contents of a0.
.hex:
    mov [_Print_Buffer], zero    ; Buffer has 5 digits. First one will always be 0
    ; Last digit
    and t0, a0, 0x000F
    peek t0, [t0 + .hexTable], LOW
    mov [_Print_Buffer+4], t0
    ; 3rd digit
    srl a0, a0, 4
    and t0, a0, 0x000F
    peek t0, [t0 + .hexTable], LOW
    mov [_Print_Buffer+3], t0
    ; 2nd digit
    srl a0, a0, 4
    and t0, a0, 0x000F
    peek t0, [t0 + .hexTable], LOW
    mov [_Print_Buffer+2], t0
    ; First digit
    srl a0, a0, 4
    peek t0, [t0 + .hexTable], LOW
    mov [_Print_Buffer+1], t0
    
    jmp ._Output_PrintBuffer
    

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
    syscall OUTPUT.char
    sub a0, zero, t0    ; Negate a1,t0 and store in a1,a0
    subb a1, zero, a1
    jmp .uint32   ; Print unsigned integer and return
    


; Prints a null-terminated string (constructed in RAM). a0 points at the first char of the string
; WARNING: each 16-bit word contains A SINGLE 8-bit char (upper 8 bits must be 0x00)
.string_unpacked:
    mov a1, a0          ; Move pointer to a1 (use a0 as argument of OUTPUT.char)
..loop:
    movf a0, [a1]       ; Load next char
    jz ..return         ; If it's the null character, return
    syscall OUTPUT.char ; Else, print the char
    add a1, a1, 1       ; Increment pointer
    jmp ..loop
..return:
    ret
    

; Prints a null-terminated string (stored in RAM). a0 points at the first char of the string
; WARNING: each 16-bit word contains TWO 8-bit chars (no bits are ignored)
.string_packed:
    mov a1, a0      ; Move pointer to a1 (use a0 as argument of OUTPUT.char)
..loop:
    mov a2, [a1]        ; Load next pair of chars
    srl a0, a2, 8       ; Get upper bits (lower address in big endian)
    jz ..return         ; If it's the null character, return
    syscall OUTPUT.char ; Else, print the char

    and a0, a2, 0x00FF  ; Get lower bits (upper address in big endian)
    jz ..return         ; If it's the null character, return
    syscall OUTPUT.char ; Else, print the char

    add a1, a1, 1       ; Increment pointer
    jmp ..loop
..return:
    ret
    

; Prints a null-terminated string (stored in ROM). a0 points at the first char of the string
; WARNING: each 32-bit word contains FOUR 8-bit chars (no bits are ignored)
.string:
    mov a1, a0      ; Move pointer to a1 (use a0 as argument of OUTPUT.char)
..loop:
    peek a2, [a1], Up   ; Load next pair of chars (upper bits -> lower address in big endian)
    srl a0, a2, 8   ; Get upper bits (lower address in big endian)
    jz ..return     ; If it's the null character, return
    syscall OUTPUT.char      ; Else, print the char

    and a0, a2, 0x00FF  ; Get lower bits (upper address in big endian)
    jz ..return     ; If it's the null character, return
    syscall OUTPUT.char      ; Else, print the char

    peek a2, [a1], Low  ; Load next pair of chars (lower bits -> upper address in big endian)
    srl a0, a2, 8   ; Get upper bits (lower address in big endian)
    jz ..return     ; If it's the null character, return
    syscall OUTPUT.char      ; Else, print the char

    and a0, a2, 0x00FF  ; Get lower bits (upper address in big endian)
    jz ..return     ; If it's the null character, return
    syscall OUTPUT.char      ; Else, print the char

    add a1, a1, 1   ; Increment pointer
    jmp ..loop
..return:
    ret
    

; Print an error and halt the computer
.error:
    mov t0, a0
    ; Print newline
    mov a0, "\n"
    syscall OUTPUT.char
    ; Set color to red
    mov a0, COLOR.RED
    syscall OUTPUT.SetColor
    ; Print "[ERROR] "
    mov a0, ._STR.error_text
    call .string
    ; Print user text
    mov a0, t0
    call .string
    ; Halt computer
    syscall TIME.Halt
    


; Print to screen the contents of Print_Buffer
._Output_PrintBuffer:
; Remove leading zeroes
    mov t0, _Print_Buffer-1
..rem_zeroes:
    add t0, t0, 1
    movf a0, [t0]
    jz ..rem_zeroes

; Print number from first non-zero digit onward
..print:        
    add a0, a0, "0"
    syscall OUTPUT.char
    add t0, t0, 1
    mov a0, [t0]
    cmp t0, _Print_Buffer+4
    jbe ..print ; Loop while pointer is below or equal the address of last digit
    
    ret
    

; CONSTANTS
._STR:
..error_text: str("[ERROR] ")
#align 32

.hexTable:
#d32 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, "A"-"0", "B"-"0", "C"-"0", "D"-"0", "E"-"0", "F"-"0"
#align 32