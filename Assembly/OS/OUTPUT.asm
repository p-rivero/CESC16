; =============================
;  VGA Terminal Output Library
; =============================

#bank data
Print_Buffer: #res 5    ; Decimal for 0xFFFF has 5 digits

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
    
    
; Print to screen the contents of Print_Buffer
.Output_PrintBuffer:
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
    
    jmp .Output_PrintBuffer
    
    
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


; Prints the HEX representation of the contents of a0.
.hex:
    mov [Print_Buffer], zero    ; Buffer has 5 digits. First one will always be 0
    ; Last digit
    and t0, a0, 0x000F
    peek t0, [t0 + ..hexTable], LOW
    mov [Print_Buffer+4], t0
    ; 3rd digit
    srl a0, a0, 4
    and t0, a0, 0x000F
    peek t0, [t0 + ..hexTable], LOW
    mov [Print_Buffer+3], t0
    ; 2nd digit
    srl a0, a0, 4
    and t0, a0, 0x000F
    peek t0, [t0 + ..hexTable], LOW
    mov [Print_Buffer+2], t0
    ; First digit
    srl a0, a0, 4
    peek t0, [t0 + ..hexTable], LOW
    mov [Print_Buffer+1], t0
    
    jmp .Output_PrintBuffer
    
..hexTable:
#d32 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, "A"-"0", "B"-"0", "C"-"0", "D"-"0", "E"-"0", "F"-"0"
#align 32

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
    mov a0, 0x81    ; Terminal CMD: Reset
    call .char
    jmp .CursorON
    

; Disable cursor blink
.CursorOFF:
    mov a0, 0x82    ; Terminal CMD: Disable blink
    jmp .char
    
; Enable cursor blink
.CursorON:
    mov a0, 0x83    ; Terminal CMD: Enable blink
    jmp .char
    
; Save cursor position
.CursorSave:
    mov a0, 0x84    ; Terminal CMD: Save cursor
    jmp .char
    
; Restore cursor position
.CursorRestore:
    mov a0, 0x85    ; Terminal CMD: Restore cursor
    jmp .char
    

; Moves the cursor to the row/line stored in a0. The column is not affected.
.MoveRow:
    and a0, a0, 0x1F ; 000rrrrr
    or a0, a0, 0xA0  ; 101rrrrr
    jmp .char
    
; Moves the cursor to the column stored in a0. The row/line is not affected.
.MoveColumn:
    or a0, a0, 0xC0  ; 11cccccc
    jmp .char
    

; Erases all characters in the current line
.Clear:
    mov a0, 0x87    ; Terminal CMD: Clear line
    jmp .char

; Erases all characters in the entire screen
.ClearScreen:
    mov a0, 0x86    ; Terminal CMD: Clear screen
    jmp .char


; Sets the current line color (and the color of future lines, using '\n')
; to the color stored in a0.
; Color format: 0b00RRGGBB (2 bits per channel)
.SetColor:
    mov a1, a0      ; Store color for later
    mov a0, 0x89    ; Terminal CMD: Set color for line
    call .char
    and a0, a1, 0x3F ; Restore color (only the 6 LSB)
    jmp .char

; Same as SetColor, but it changes the color of all the lines at the same time
.SetColorScreen:
    mov a1, a0      ; Store color for later
    mov a0, 0x88    ; Terminal CMD: Set color for screen
    call .char
    and a0, a1, 0x3F ; Restore color (only the 6 LSB)
    jmp .char

; Color definitions
COLOR:
.RED           = 0b110000
.LIGHTRED      = 0b110101
.LLIGHTRED     = 0b111010
.DARKRED       = 0b100000
.DDARKRED      = 0b010000

.GREEN         = 0b001100
.LIGHTGREEN    = 0b011101
.LLIGHTGREEN   = 0b101110
.DARKGREEN     = 0b001000
.DDARKGREEN    = 0b000100

.BLUE          = 0b000011
.LIGHTBLUE     = 0b010111
.LLIGHTBLUE    = 0b101011
.DARKBLUE      = 0b000010
.DDARKBLUE     = 0b000001

.CYAN          = 0b001111
.LIGHTCYAN     = 0b011111
.LLIGHTCYAN    = 0b101111
.DARKCYAN      = 0b001010
.DDARKCYAN     = 0b000101

.YELLOW        = 0b111100
.LIGHTYELLOW   = 0b111101
.LLIGHTYELLOW  = 0b111110
.DARKYELLOW    = 0b101000
.DDARKYELLOW   = 0b010100

.MAGENTA       = 0b110011
.LIGHTMAGENTA  = 0b110111
.LLIGHTMAGENTA = 0b111011
.DARKMAGENTA   = 0b100010
.DDARKMAGENTA  = 0b010001

.ORANGE        = 0b110100
.LIGHTORANGE   = 0b111001
.DARKORANGE    = 0b100100

.LIME          = 0b101100
.LIGHTLIME     = 0b101101
.DARKLIME      = 0b011000

.MINT          = 0b001110
.LIGHTMINT     = 0b011110
.DARKMINT      = 0b001001

.SKY           = 0b000111
.LIGHTSKY      = 0b011011
.DARKSKY       = 0b000110

.PURPLE        = 0b100011
.LIGHTPURPLE   = 0b100111
.DARKPURPLE    = 0b010010

.PINK          = 0b110001
.LIGHTPINK     = 0b110110
.DARKPINK      = 0b100001

.BLACK         = 0b000000
.GREY          = 0b010101
.LIGHTGREY     = 0b101010
.WHITE         = 0b111111
