# Schematics and PCBs

The CPU is intended to be built on PCBs and has been designed using EasyEDA. It consists of 6 modules (plus an I/O module) that get connected using a backplane.

Each module is a separate EasyEDA project. All projects can be found in the `EasyEDA` folder.

How to import a project in EasyEDA:
1. Install the PC version of EasyEDA. The online editor doesn't allow importing local projects.
2. (Optional) Go to `Setting -> Desktop Edition Setting -> Run Mode Setting` and change the run mode to "Projects Offline".
3. Create a new local project. This will create the required directories.
4. Right-click the new project (folder icon) and choose "Open Project Directory".
5. Copy the project you want to import (folder that contains the `*.json` and `info` files) to the directory that just opened (which should be called "projects").

***

## Clock and Reset
This module is responsible for generating the clock signal.
The user can choose between 3 clock modes using 2 switches: **Manual** (button with 555 debouncing), **Slow** (555 timer, adjustable speed using a potentiometer) and **Fast** (crystal oscillator).

The module contains some extra logic to ensure that the clock signal stays valid during mode switching, even on extremely high clock frequencies.

The clock module also contains the circuit that generates the Reset signal. This signal is debounced and synchronized with the clock.

![Clock and Reset schematic](./img/schematic/CLK%2BReset.svg)

![Clock and Reset PCB](./img/pcb/CLK%2BReset.png)

***

## General Purpose Register (GPR)
This is an extremely simple module. Its only job is to implement a 16 bit register with `Load Enable` and `Output Enable` control lines, as well as LEDs to show the contents that are currently stored in the register.

There are 14 instances of this module connected to the CPU backplane.

![GPR schematic](./img/schematic/GPR.svg)

<img src="./img/pcb/GPR.png" alt="GPR PCB" width="400"/>

***

## Register file logic
A GPR by itself contains very little logic, so there needs to be a module in charge of decoding a few control signals into each individual `Load` and `Output` signal.

This module also contains the Zero Register (`zero`) and the Stack Pointer (`sp`), which is implemented as an Up/Down counter.

![Regfile logic schematic](./img/schematic/RegfileLogic.svg)

<img src="./img/pcb/RegfileLogic.png" alt="Regfile logic PCB" width="250"/>

***

## Arithmetic and Logic Unit (ALU)
The ALU module is based on 74HC181 ALU chips. This makes the rest of the module quite simple, since the 74181 is both [fascinating and very powerful](http://www.righto.com/2017/03/inside-vintage-74181-alu-chip-how-it.html).

The rest of the module is responsible for **generating the 4 ALU flags** (Zero, Carry, Overflow and Sign), **holding the ALU operands** (in the X and Y temporary registers), **right-shifting** (the only operation the 74181 cannot do) and **outputting the result** to the correct bus.

![ALU schematic](./img/schematic/ALU.svg)

![ALU PCB](./img/pcb/ALU.png)

***

## Memory module

This is a complex module that contains: 
- The RAM and ROM ICs, and the logic for managing memory reads and writes. The ROM chips are actually NOR flash (which is much cheaper) and use ZIF sockets to make programming easy.
- The Program Counter (PC), which is implemented as an Up counter.
- The Memory Address Register (MAR), which is a regular register.
- The logic for managing Memory-Mapped IO (MMIO). An address in `[0xFF00, 0xFFFF]` disables ROM and RAM, and activates the read or write signal on an I/O port.

![Memory schematic](./img/schematic/Memory.svg)

![Memory PCB](./img/pcb/Memory.png)

***

## Control module

This module is also quite complex. It contains: 
- The 3 control ROMs that contain the CPU microcode. Like the program ROMs, they are actually NOR flash chips.
- Extra logic to expand the output of the control ROMs into all the required control signals. This makes possible having just 3 ROMs (other homebrew CPUs of similar complexity usually have 4 or 5 control ROMs).
- The 8-bit Instruction Register (IR), 4-bit Flags register and 4-bit timestep counter. They are the inputs of the control ROMs.
- The logic for handling mode switching. ROM and RAM are separate banks (with 64k addresses each) and the CPU can fetch instructions from either of them, depending on whether it's running on System (ROM) or User (RAM) mode.
- The logic for handling interrupts. If the CPU is in System mode it will jump to `PC=0x0013`; if it's in User mode it will switch to System mode and jump to `PC=0x0011`.


![Control schematic](./img/schematic/Control.svg)

![Control PCB](./img/pcb/Control.png)

***

## I/O (Input + Output)

This is the only module where microcontrollers are allowed, since I don't consider it to be a part of the core CPU.

Some people may consider that implementing I/O using microcontrollers is cheating, but I disagree. All modern peripherals (keyboards, screens...) have microcontrollers inside, so a "microcontroller-free" design is already impossible.
You may reply that those microcontrollers "don't count", because they're not a part of our CPU; then the same can be said about the I/O module, it's not a part of the CPU since the CPU can execute instructions perfectly without it.

The I/O module contains 4 peripherals:
- [**Serial line + PS/2 keyboard**](https://github.com/p-rivero/CESC16/tree/main/Peripherals/Keyboard_Serial) (using an Arduino Nano, since it already has the ICs needed for USB serial).
- [**VGA terminal**](https://github.com/p-rivero/ArduinoVGA) (using an ATmega328P).
- **16-bit timer** (no microcontroller used, only 74-series chips).
- [**USB flash drive**](https://github.com/p-rivero/CESC16/tree/main/Peripherals/USB_Disk) (using an ATmega328P and a CH376S module).


![I/O schematic](./img/schematic/IO.svg)

![I/O PCB](./img/pcb/IO.png)

***

## Backplane
Finally, the backplane is responsible for connecting all the different modules using pin headers. This idea came from James Sharman's excellent [8-bit pipelined CPU](https://www.youtube.com/playlist?list=PLFhc0MFC8MiCDOh3cGFji3qQfXziB9yOw).

The schematic for the backplane is trivial, since it only contains the pin headers for each net. However, the PCB is rather complex, since there's a lot of connections with difficult routing.

![Backplane schematic](./img/schematic/Backplane.svg)

![Backplane PCB](./img/pcb/Backplane.png)
