

#bank program
STARTUP:
    .Reset:
    ; Reset vector (hardware entry point):
    nop             ; Ensure that a reset is performed correctly, regardless of the clock state
    mov sp, INIT_STACK  ; Initialize stack
    mov (KEY_PRESSED_HANDLER), zero ; Reset interrupt handlers
    mov (KEY_RELEASED_HANDLER), zero
    
    ; Initialize I/O:
    syscall PRINT.Reset   ; Clear screen
    
    ; User code execution
    call MAIN_PROGRAM
    
    ; If user code terminates, halt the computer
    syscall TIME.Halt
    
    #res (INTERRUPT_VECTOR - pc) ; Fill space until interrupt vector
    
    
; INTERRUPT HANDLER
    ; This handler gets called whenever any interrupt occurs. Its job is to call the correct specialized handlers
    ; Save+Restore context: ~60 clock cycles
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
    
    ; Check timer and call user interrupt handler
    ; TODO
    
    ; Check PS/2 keyboard input (max ~30 cycles + user interrupt)
.readKeyboard:
    movf a0, (KEYBOARD_ADDR)    ; Read from keyboard
    jz ..continue               ; If there was no input, don't do anything
    mov (KEYBOARD_ADDR), zero   ; Else acknowledge input

    mask a0, INPUT.MASK_BREAK   ; Check if the key was pressed or released
    jnz ..key_released
    
    ; Key was pressed down
    call INPUT.Key_Pressed_Handler  ; Call the handler and continue
    j ..continue
    
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
    popf
    ret
    

; Copy data from program memory to RAM
; Arguments: a0 = Address of first element in program memory (origin)
;            a1 = Address AFTER last element in program memory (will NOT be copied)
;            a2 = Address of first element in data memory (destination)
; Warning: The conversion from 32-bit program memory to 16-bit data memory is performed
;          using big endian format (upper bits get copied before lower bits).
;          This ensures that the #d16 get stored in the order that they were typed.
.MemCopy:
    cmp a1, a0      ; If (address of last element) <= (address of first element),
    jleu ..return   ; then return (nothing to copy)
    
..loop:
    peek v0, 0(a0), 1   ; Read upper 16-bit word / opcode
    mov (a2), v0        ; Store to lower address (big endian)
    peek v0, 0(a0), 0   ; Read lower 16-bit word / argument
    sw v0, 1(a2)        ; Store to upper address (big endian)
    add a0, a0, 1       ; Increment program memory pointer
    add a2, a2, 2       ; Increment data memory pointer
    
    cmp a0, a1          ; Keep looping until there are no more words
    jne ..loop
    
..return:
    ret
