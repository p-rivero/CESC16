; ========================
;  Keyboard Input library
; ========================

#bank program

INPUT:

; Constants:
.ACK = 0x06
.RDY = 0x07

.BACKSPACE = 0x08
.TAB = 0x09
.ENTER = 0x0A
.PAGEUP = 0x0B
.PAGEDOWN = 0x0C
.HOME = 0x0D
.INSERT = 0x0E
; F1-F12 mapped to 0x0F-0x1A
.ESC = 0x1B
.LEFT = 0x1C
.RIGHT = 0x1D
.DOWN = 0x1E
.UP = 0x1F
.DEL = 0x7F


; Attach an interrupt handler (jump address) to a keypress
; WARNING: Those syscalls make use of the stack, and so they should be called in the correct order
; as if they were push/pop instructions.
.AttachInterrupt:
    swap a0, [HANDLERS.KEYPRESS] ; Attach new interrupt and retrieve old one
    swap a0, [sp] ; Simultaneously pop return address and push old interrupt handler
    jmp a0  ; Jump to return address

.DetachInterrupt:
    pop a0  ; Pop return address
    pop a1  ; Pop old interrupt handler
    mov [HANDLERS.KEYPRESS], a1  ; Attach old interrupt handler
    jmp a0  ; Jump to return address


; INTERRUPT HANDLER: it gets called when a key is pressed
.Key_Handler:
    cmp a0, INPUT.ESC
    je ..keyboard_int    ; Keyboard interrupt
    movf t0, [HANDLERS.KEYPRESS] ; Load the address of the user interrupt handler
    jnz t0  ; If it's not zero, jump to the user handler
    ret     ; If it's zero, don't do anything

..keyboard_int:
    mov a0, "!"
    syscall OUTPUT.char
    mov [TMR_ACTIVE], zero  ; Disable timer
    jmp STARTUP.Reset   ; Reset computer (placeholder)
