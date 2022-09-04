## Installing the assembler:

Don't use customasm directly, use the `cesc16asm` shell script instead.

1. Add execution permission: `chmod +x cesc16asm`
2. (Recommended) Create symbolic link: `sudo ln -s $PWD/cesc16asm /usr/bin/cesc16asm`
3. Install customasm:

    **If you are using Linux:**
    1. Run `cargo install customasm`
    
    **If you are using Windows (WSL):**
    1. Go to https://github.com/hlorenzi/customasm/releases and download the latest version of customasm
    2. Place `customasm.exe` in this folder (next to `cesc16asm`)


## Using the assembler:

```
cesc16asm [options] <input file>
```

**Input file:** one (1) assembly file. In order to link several files, consider using the `#include` directive.

**Options:**

`-h --help`: Show help message and exit.

`-l --link`: Link pre-assembled hex files. Currently this option simply copies the input file to the output target.
This option exists to allow compatibility with the `lcc` ANSI C compiler.

`-n --no-bin`: Do not create `<name>.bin` file. Binary files are required for flashing the program ROMs on the real CPU, while hex files are used for the emulator.

`-o --output <name>`: Output hex result to `<name>` and binary to `<name>.bin`. Defaults to `out.hex`.

`-p --print`: Print the assembled file to stdout. Ignore `-o` option.
