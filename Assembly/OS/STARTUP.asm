; ============================
;  Startup/Interrupt Routines
; ============================


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
    syscall OUTPUT.Reset    ; Clear screen
    mov [KEYBOARD_ADDR], INPUT.RDY  ; OS is ready to receive new interrupts
    
    ; User code execution (main() method)
    call main
    
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
    push bp
    push a0
    push a1
    push a2
    push a3
    push t0
    push t1
    push t2
    push t3
    
    ; Check timer (max ~30 cycles + user interrupt)
.readTimer:
    test [TMR_ACTIVE]   ; Check if the timer had been activated
    jz ..continue       ; If it hasn't, skip the rest of checks
    
    mov a0, [TIMER_ADDR]    ; Read current timer value
    cmp a0, TIME.END_COUNT  ; The timer causes an interrupt when it reaches TIME.END_COUNT
    jne ..continue          ; If it has any other value, don't call handler
    
    mov [TMR_ACTIVE], zero  ; Disable the timer so the handler only gets called once
    call TIME.Timer_Handler
..continue:
    
    ; Check PS/2 keyboard input (max ~30 cycles + user interrupt)
.readKeyboard:
    mov a0, [KEYBOARD_ADDR]     ; Read from keyboard
    and a0, a0, 0x7F            ; Remove busy flag (MSB)
    jz ..continue               ; If there was no input, don't do anything
    ; Here we should poll the busy flag until it's 0, but we can save time by assuming
    ; that the INT latency is enough time for the controller to be ready.
    ; TODO: Remove this check
..temp:
    mov t0, [KEYBOARD_ADDR]
    mask t0, 0x80
    jnz ..temp
    ; todo
    mov [KEYBOARD_ADDR], INPUT.ACK  ; Acknowledge input, this clears the register to avoid double reads

    call INPUT.Key_Handler      ; Call the user handler

    ; TODO: Remove this check
..temp2:
    mov t0, [KEYBOARD_ADDR]
    mask t0, 0x80
    jnz ..temp2
    ; todo
    mov [KEYBOARD_ADDR], INPUT.RDY  ; It's safe to be interrupted again by keyboard
..continue:
    
    ; Restore context
    pop t3
    pop t2
    pop t1
    pop t0
    pop a3
    pop a2
    pop a1
    pop a0
    pop bp
    popf
    ret
