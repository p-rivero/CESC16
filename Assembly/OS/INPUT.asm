; ========================
;  Keyboard Input library
; ========================

#bank program

INPUT:

; Constants:
.ACK = 0x1  ; TODO: Choose actual ACK command
.RDY = 0x2  ; TODO: Choose actual RDY command

.INSERT = 22      ; From PS2Keyboard.h
.HOME = 23        ; From PS2Keyboard.h
.PAGEUP = 25      ; From PS2Keyboard.h
.PAGEDOWN = 26    ; From PS2Keyboard.h


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
    movf t0, [HANDLERS.KEYPRESS] ; Load the address of the user interrupt handler
    jnz t0  ; If it's not zero, jump to the user handler
    ret     ; If it's zero, don't do anything

