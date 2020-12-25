; Draft for a basic CESC16 OS

#ifndef _OS
#define _OS
; Include OS code only once

; Constants:
INTERRUPT_VECTOR = 0x0011
INIT_STACK = 0xFEFF ; The stack gets predecremented, so it could start at 0xFF00. However, I prefer leaving 1 extra space between stack and I/O
KEYBOARD_ADDR = 0xFF00
TERMINAL_ADDR = 0xFF40
GPIO_2_ADDR = 0xFF80
GPIO_3_ADDR = 0xFFC0

#bank data
KEY_PRESSED_HANDLER:    #res 1
KEY_RELEASED_HANDLER:   #res 1

#include "STARTUP.asm"
#include "MATH.asm"
#include "KEYBOARD_IN.asm"
#include "TERMINAL_OUT.asm"
#include "TIME.asm"
    
_OS_END:

#endif
