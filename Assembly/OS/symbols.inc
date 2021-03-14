#bank program_labels

#addr 0x3
TMR_ACTIVE:

#addr 0x7c
OUTPUT:

#addr 0xbc
.uint32:

#addr 0x7c
.char:

#addr 0xb5
.int16:

#addr 0xbd
.int32:

#addr 0xcc
.string_RAM:

#addr 0xea
.SetColor:

#addr 0xd7
.string_ROM:

#addr 0xc5
.string:

#addr 0xe9
.Reset:

#addr 0x80
.uint16:

#addr 0x0
STARTUP:

#addr 0x0
.Reset:

#addr 0xff40
TERMINAL_ADDR:

#addr 0xfe
MAIN_PROGRAM:

#addr 0x0
HANDLERS:

#addr 0x1
.KEY_RELEASED:

#addr 0x2
.TMR:

#addr 0x0
.KEY_PRESSED:

#addr 0xffc0
GPIO_3_ADDR:

#addr 0xff80
TIMER_ADDR:

#addr 0x65
INPUT:

#addr 0x1a
.PAGEDOWN:

#addr 0x2000
.MASK_ENTER:

#addr 0x4000
.MASK_BREAK:

#addr 0x73
.Key_Pressed_Handler:

#addr 0x76
.Key_Released_Handler:

#addr 0x17
.HOME:

#addr 0x6b
.DetachInterrupt:

#addr 0x65
.AttachInterrupt:

#addr 0x16
.INSERT:

#addr 0x19
.PAGEUP:

#addr 0x37
MEMORY:

#addr 0x37
.MemCopy:

#addr 0x11
INTERRUPT_VECTOR:

#addr 0xfeff
INIT_STACK:

#addr 0x11
RAM_INT_HANDLER:

#addr 0x4
Print_Buffer:

#addr 0xeb
TIME:

#addr 0xed
.SetTimer:

#addr 0xf0
.CancelTimer:

#addr 0xf7
.DetachInterrupt:

#addr 0xf4
.AttachInterrupt:

#addr 0xec
.Wait_ms:

#addr 0xf2
.ReadTimer:

#addr 0xfb
.Timer_Handler:

#addr 0xeb
.Halt:

#addr 0xfe
_OS_END:

#addr 0xff00
KEYBOARD_ADDR:

#addr 0x44
MATH:

#addr 0x60
.UDiv32:

#addr 0x62
.Pow:

#addr 0x4e
.UMult32:

#addr 0x5f
.Div:

#addr 0x4e
.Mult32:

#addr 0x44
.Mult:

#addr 0x63
.Pow32:

#addr 0x61
.Div32:

#addr 0x5e
.UDiv:

#addr 0x64
.Sqrt:

#addr 0x44
.UMult:

#addr 0x13
MAIN_INTERRUPT_HANDLER:

#addr 0x24
.readKeyboard:

#addr 0x1d
.readTimer:

#addr 0x42
CALL_GATE:

#bank mem
