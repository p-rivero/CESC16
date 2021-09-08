; ======================
;   INTERRUPTS EXAMPLE
; ======================
; This example shows how to attach and detach interrupt handlers for different interrupt events

; Include libraries
#include "OS/OS.inc"

#bank data
Sync:   #res 1

#bank program

str_done: str("DONE!\n")
#align 32
str_input: str("Got input: ")
#align 32
str_end1: str(" (")
#align 32
str_end2: str(")\n")
#align 32


; User program entry point
MAIN_PROGRAM:
.main:
    mov [Sync], zero ; Initialize variables
    
    ; Attach interrupt handlers (defined below). The old handlers get stored in the stack
    mov a0, .Key_Handler
    syscall INPUT.AttachInterrupt
    
    mov a0, .TMR_Handler
    syscall TIME.AttachInterrupt
    
    
    ; Start timer (count 1000 ticks = 16000 cycles)
    mov a0, 1000
    syscall TIME.SetTimer
    
..wait:             ; Wait until the timer overflows and Sync gets set to 1.
    test [Sync]     ; Even if main program is halted, keystrokes will still trigger
    jz ..wait       ; interrupts and call OUTPUT.char
    
    mov a0, str_done
    syscall PRINT.string
    
    ; Stay on an endless loop after finishing, comment out this line if you wish to detach the handlers and return
    jmp pc
    
    ; Remember to pop the old handlers in the correct order (stack = LIFO)
    syscall TIME.DetachInterrupt
    syscall INPUT.DetachInterrupt
    
    ret
    
    
; INTERRUPT HANDLERS:
; Routine that will get called whenever a key is pressed down. The ASCII is stored in a0
.Key_Handler:
    push s0
    mov s0, a0      ; Store the ASCII of the key
    ; Print "Got input: "
    mov a0, str_input
    syscall PRINT.string
    ; Print the pressed char
    mov a0, s0
    syscall OUTPUT.char
    ; Print " ("
    mov a0, str_end1
    syscall PRINT.string
    ; Print the ASCII code of the char
    mov a0, s0
    syscall PRINT.hex
    ; Print ")\n"
    mov a0, str_end2
    syscall PRINT.string
    pop s0
    ret
   
; Routine that will get called whenever the timer overflows.
.TMR_Handler:
    mov [Sync], 1  ; The global variable Sync signals the main program to exit the loop
    ret
    
