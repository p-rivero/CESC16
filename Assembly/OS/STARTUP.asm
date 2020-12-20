

#bank program
#bits 32
STARTUP:
    .Reset:
    ; Reset vector (hardware entry point):
    nop             ; Ensure that a reset is performed correctly, regardless of the clock state
    mov sp, INIT_STACK  ; Initialize stack
    
    ; Initialize I/O: Make sure there is no leftover input and clear terminal
    syscall INPUT.GetFull ; Acknowledge input
    syscall PRINT.Reset   ; Clear screen
    
    ; User code execution
    call MAIN_PROGRAM
    
    ; If user code terminates, halt computer
    syscall TIME.Halt
    
    
    

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
    