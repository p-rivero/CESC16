

#bank program
STARTUP:
; Reset vector (hardware entry point):
.Reset:
    ; A nop ensures that a reset is performed correctly, regardless of the clock state
    nop
    ; Disable timer
    mov [TMR_ACTIVE], zero
    ; Initialize stack
    mov sp, INIT_STACK
    ; Reset interrupt handlers
    mov [HANDLERS.KEYPRESS], zero
    mov [HANDLERS.TMR], zero
    
    ; Initialize I/O:
    mov t0, INPUT.RDY
    mov [KEYBOARD_ADDR], t0 ; Acknowledge any leftover input
    syscall OUTPUT.Reset    ; Clear screen
    
    ; User code execution
    call MAIN_PROGRAM
    
    ; If user code terminates, halt the computer
    syscall TIME.Halt
    
    #addr INTERRUPT_VECTOR  ; Fill space until interrupt vector (hardware entry point)
    
RAM_INT_HANDLER:
    ; This handler gets called when an interrupt occurs while running a program from RAM.
    ; Its only job is to call the main interrupt handler below and then return to RAM.
    ; Warning: this code MUST be located at 0x0011 and be 2 instructions long (main handler must be at 0x0013)
    call MAIN_INTERRUPT_HANDLER
    sysret

MAIN_INTERRUPT_HANDLER:
    ; This handler gets called whenever any interrupt occurs. Its job is to call the correct specialized handlers
    ; Save+Restore context: ~60 clock cycles
    ; Timer: Max ~30 cycles + user interrupt
    ; PS/2 Keyboard: Max ~30 cycles + user interrupt
    
    ; Store context
    pushf
    push a0
    push a1
    push a2
    push v0
    push t0
    push t1
    push t2
    push t3
    push t4
    
    ; Check timer (max ~30 cycles + user interrupt)
.readTimer:
    test [TMR_ACTIVE]   ; Check if the timer had been activated
    jz ..continue       ; If it hasn't, skip the rest of checks
    
    mov a0, [TIMER_ADDR]    ; Read current timer value
    cmp a0, 0xFFFF      ; The timer causes an interrupt when it reaches 0xFFFF
    jne ..continue      ; If it has any other value, don't call handler
    
    mov [TMR_ACTIVE], zero  ; Disable the timer so the handler only gets called once
    call TIME.Timer_Handler
..continue:
    
    ; Check PS/2 keyboard input (max ~30 cycles + user interrupt)
.readKeyboard:
    movf a0, [KEYBOARD_ADDR]    ; Read from keyboard
    jz ..continue               ; If there was no input, don't do anything
    mask a0, 0x80               ; Test busy flag (MSB)
    jnz ..continue              ; If controller is busy, don't do anything
    mov t0, INPUT.ACK
    mov [KEYBOARD_ADDR], t0     ; Else acknowledge input

    call INPUT.Key_Handler      ; Call the user handler

    mov t0, INPUT.RDY
    mov [KEYBOARD_ADDR], t0     ; It's safe to be interrupted again by keyboard
..continue:
    
    ; Check other input sources (serial)
    ; TODO
    
    ; Restore context
    pop t4
    pop t3
    pop t2
    pop t1
    pop t0
    pop v0
    pop a2
    pop a1
    pop a0
    popf
    ret
