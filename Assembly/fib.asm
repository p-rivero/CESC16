#include "OS/OS.inc"
#bank program

Title: str("Fibonacci sequence:\n")
#align 32

MAIN_PROGRAM:
    ; Print title in cyan
    mov a0, COLOR.CYAN
    syscall OUTPUT.SetColor    
    mov a0, Title
    syscall OUTPUT.string_ROM
    
    ; Print rest of lines in white
    mov a0, COLOR.WHITE
    syscall OUTPUT.SetColor
    
; Compute Fibonacci sequence
    mov s0, 1
    mov s1, 1

.fib_loop:
    mov a0, s0
    syscall OUTPUT.uint16
    mov a0, "\n"
    syscall OUTPUT.char
    
    add t0, s0, s1
    mov s0, s1
    mov s1, t0
    jnc .fib_loop
    
    ; Print remaining number
    mov a0, s0
    syscall OUTPUT.uint16
    
    ret
    
