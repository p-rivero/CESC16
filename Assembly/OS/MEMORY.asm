

#bank program
MEMORY:

; Copy data from program memory to RAM
; Arguments: a0 = Address of first element in program memory (origin)
;            a1 = Address AFTER last element in program memory (will NOT be copied)
;            a2 = Address of first element in data memory (destination)
; Warning: The conversion from 32-bit program memory to 16-bit data memory is performed
;          using big endian format (upper bits get copied before lower bits).
;          This ensures that the #d16 get stored in the order that they were typed.
.MemCopy:
    cmp a1, a0      ; If (address of last element) <= (address of first element),
    jbe ..return    ; then return (nothing to copy)
    
    ; Todo: Unroll loop
..loop:
    peek t3, [a0], Up       ; Read upper 16-bit word / opcode
    mov [a2], t3            ; Store to lower address (big endian)
    peek t3, [a0], Low      ; Read lower 16-bit word / argument
    mov [a2+1], t3          ; Store to upper address (big endian)
    add a0, a0, 1           ; Increment program memory pointer
    add a2, a2, 2           ; Increment data memory pointer
    
    cmp a0, a1              ; Keep looping until there are no more words
    jne ..loop
    
..return:
    ret



; In order to call OS subroutines (or any subroutine stored in ROM) from a program running in RAM,
; this call gate must be used (otherwise the ret instruction would stay in ROM).
; If the subroutine will never return (STARTUP.Reset, TIME.Halt), then syscall can be used directly.
; Usage example:  mov t0, MATH.Mult
;                 syscall CALL_GATE
CALL_GATE:
    call t0
    sysret

