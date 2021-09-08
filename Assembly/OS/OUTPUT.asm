; =============================
;  VGA Terminal Output Library
; =============================

#bank program

OUTPUT:

; ------------
; Basic output
; ------------

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
    

; ----------------
; Terminal Control
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
