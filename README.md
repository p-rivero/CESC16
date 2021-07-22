# CESC16 documentation and tools

This repository contains the following:

## Architecture:
- [**MAIN DOCUMENTATION**](https://github.com/p-rivero/CESC16/blob/main/DOCS/CESC16.pdf)
- Extended information about the ISA it supports and the I/O interfaces
- Examples of some assembly programs
- A basic OS, including libraries for Math, I/O, and Flow control

## Computer:
- C++ code for generating the computer microcode
- Code for the Arduino I/O controllers **(not yet)**
- Schematics and PCBs
- Pictures of the finished build **(not yet)**
- A usage guide **(not yet)**

> *Important notice:* The used assembler is **customasm**, which you can find [here](https://github.com/hlorenzi/customasm).


# Other repositories

## Emulator
Run and debug CESC16 programs from a Linux system with the [CESC16 emulator](https://github.com/p-rivero/CESC16-emulator).
More details at the emulator's own repository.

## C compiler
`lcc` is a retargetable ANSI C compiler. [This repository](https://github.com/p-rivero/lcc) contains an `lcc` backend for the CESC16 architecture.

Writing new software for the CESC16 computer in C is much easier than using assembly. The code that the compiler produces is slightly slower than human-written assembly, but most of the time the speed difference is not very significant.
