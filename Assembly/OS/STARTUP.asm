

#bank program
STARTUP:
    .Reset:
    ; Reset vector (hardware entry point): nop ensures that a reset is performed correctly, regardless of the clock state
    nop
    ; Disable timer
    mov [TMR_ACTIVE], zero
    ; Initialize stack
    mov sp, INIT_STACK
    ; Reset interrupt handlers
    mov [HANDLERS.KEY_PRESSED], zero
    mov [HANDLERS.KEY_RELEASED], zero
    mov [HANDLERS.TMR], zero
    
    ; Initialize I/O:
    mov [KEYBOARD_ADDR], zero   ; Acknowledge any leftover input
    syscall PRINT.Reset   ; Clear screen
    
    ; User code execution
    call MAIN_PROGRAM
    
    ; If user code terminates, halt the computer
    syscall TIME.Halt
    
    #res (INTERRUPT_VECTOR - pc) ; Fill space until interrupt vector (hardware entry point)
    
    
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
    mov [KEYBOARD_ADDR], zero   ; Else acknowledge input

    mask a0, INPUT.MASK_BREAK   ; Check if the key was pressed or released
    jnz ..key_released
    
    ; Key was pressed down
    call INPUT.Key_Pressed_Handler  ; Call the handler and continue
    jmp ..continue
    
    ..key_released:
    ; Key was released
    call INPUT.Key_Released_Handler ; Call the handler and continue
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
    ; If the interrupt was called from ROM: [sp] = flags, [sp+1] = return address
    ; If it was called from RAM: [sp] = flags, [sp+1] = 0x0000, [sp+2] = actual return address
    test [sp+1]
    jz ..return_RAM
    popf
    ret     ; Return to ROM

..return_RAM:
    popf
    pop zero    ; Remove the 0x0000
    sysret      ; Return to RAM


