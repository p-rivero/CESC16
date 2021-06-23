# Assembly tools

## Syntax highlighting on VSCode

`asm.json` provides custom syntax highlighting in Visual Studio Code, which makes programming in CESC16 assembly much easier. How to use:

 1. Install the `ASM Code Lens` extension, which provides many useful features for coding in assembly
 2. Navigate to the VSCode extensions folder:
    - Windows: `%USERPROFILE%\.vscode\extensions`
    - Windows WSL: `~/.vscode-server/extensions`
    - Linux and macOS: `~/.vscode/extensions`
 3. Navigate to `maziac.asm-code-lens-x.x.x/grammar` (replace `x.x.x` with the version number)
 4. Replace the `asm.json` file in the extension folder with the custom version in *this* folder.
 
Now .asm files in VSCode use the CESC16 syntax highlighting.


## Syntax highlighting on Notepad++

`syntax.xml` provides custom syntax highlighting in Notepad++. How to use:

 1. Open Notepad++ and go to Language -> User Defined Language -> Define your language
 2. Click "Import..." and select `syntax.xml`
 3. *(OPTIONAL)* Go to Settings -> Style configurator and select the theme you prefer. I recommend using *Zenburn*
 4. Restart Notepad++
 
Now the custom language "CESC16" is associated with .asm files in Notepad++.


## Autocompletion on Notepad++

`CESC16.xml` provides code autocompletion for keywords in CESC16 assembly. How to use:

 1. Make sure syntax highlighting is working (.asm files are associated with the custom CESC16 language)
 2. Move `CESC16.xml` to `C:\Program Files (x86)\Notepad++\autoCompletion\` (or the equivalent autocompletion path on your OS and installation)
 3. Restart Notepad++

Now Notepad++ should suggest assembly keywords while typing code on .asm files

