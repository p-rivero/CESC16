; ========================
;  Keyboard Input library
; ========================

#bank program

INPUT:

; Constants:
.MASK_BREAK = 0x4000  ; From Keyboard Interface
.MASK_ENTER = 0x2000  ; From Keyboard Interface

.INSERT = 22      ; From PS2Keyboard.h
.HOME = 23        ; From PS2Keyboard.h
.PAGEUP = 25      ; From PS2Keyboard.h
.PAGEDOWN = 26    ; From PS2Keyboard.h


; Attach an interrupt handler (jump address) to a keypress or a key being released
; WARNING: Those syscalls make use of the stack, and so they should be called in the correct order
; as if they were push/pop instructions.
; Example of correct use: [AttachInterrupt.Pressed], [5 push instructions], [AttachInterrupt.Released],
;          [...], [DetachInterrupt.Released], [5 pop instructions], [DetachInterrupt.Pressed]
.AttachInterrupt:
..Pressed:
    swap a0, [HANDLERS.KEY_PRESSED] ; Attach new interrupt and retrieve old one
    swap a0, [sp] ; Simultaneously pop return address and push old interrupt handler
    jmp a0  ; Jump to return address
    
..Released:
    swap a0, [HANDLERS.KEY_RELEASED] ; Attach new interrupt and retrieve old one
    swap a0, [sp] ; Simultaneously pop return address and push old interrupt handler
    jmp a0  ; Jump to return address

.DetachInterrupt:
..Pressed:
    pop a0  ; Pop return address
    pop a1  ; Pop old interrupt handler
    mov [HANDLERS.KEY_PRESSED], a1  ; Attach old interrupt handler
    jmp a0  ; Jump to return address
    
..Released:
    pop a0  ; Pop return address
    pop a1  ; Pop old interrupt handler
    mov [HANDLERS.KEY_RELEASED], a1 ; Attach old interrupt handler
    jmp a0  ; Jump to return address



; INTERRUPT HANDLERS: those get called when a key is pressed/released
; A key has been pressed down
.Key_Pressed_Handler:
    movf t0, [HANDLERS.KEY_PRESSED] ; Load the address of the user interrupt handler
    jnz t0  ; If it's not zero, jump to the user handler
    ret     ; If it's zero, don't do anything


; A key has been released
.Key_Released_Handler:
    xor a0, a0, INPUT.MASK_BREAK    ; Remove break bit
    cmp a0, INPUT.HOME              ; If "Home" key was released, reset computer
    jeq STARTUP.Reset
    ; More keys can be checked here
    
    movf t0, [HANDLERS.KEY_RELEASED] ; Load the address of the user interrupt handler
    jnz t0  ; If it's not zero, jump to the user handler
    ret     ; If it's zero, don't do anything
    
