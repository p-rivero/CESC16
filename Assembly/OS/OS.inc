; Draft for a basic CESC16 OS

#ifndef _OS
#define _OS
; Include OS code only once

; Constants:
INTERRUPT_VECTOR = 0x0011
INIT_STACK = 0xFEFF ; The stack gets predecremented, so it could start at 0xFF00. However, I prefer leaving 1 extra space between stack and I/O
KEYBOARD_ADDR = 0xFF00
TERMINAL_ADDR = 0xFF40
TIMER_ADDR = 0xFF80
GPIO_3_ADDR = 0xFFC0

#bank data
HANDLERS:
.KEY_PRESSED:   #res 1
.KEY_RELEASED:  #res 1
.TMR:           #res 1

TMR_ACTIVE:     #res 1

#include "STARTUP.asm"
#include "MEMORY.asm"
#include "MATH.asm"
#include "INPUT.asm"
#include "TERMINAL_OUT.asm" ; TODO: Rename to OUTPUT.asm
#include "TIME.asm"
    
_OS_END:

#endif
