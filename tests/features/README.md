Reference test cases saved in this folder.
Used by the implementation feature plan in Step 3.9 — Verify assembly

Folder Layout:
tests\features\README.mb - this doc
tests\features\01\ - first feature test case
tests\features\02\ - second feature test case
tests\features\NN\ ...

Each folder must have:
c8080.c - test for c8080 compiller
v6llvmc.c - test for this compiller

Compile ASM guide:
- tools\c8080\c8080.exe tests\features\<feature number>\c8080.c -a tests\features\<feature number>\c8080.asm
- llvm-build\bin\clang -target i8080-unknown-v6c -O2 -S tests\features\<feature number>\v6llvmc.c -o tests\features\<feature number>\.asm


Verification assembly preparation steps:
- Create a new folder in tests\features. The name is two digits.
- Create a test case that the new feature will improve.
- Store the test case to v6llvmc.c and c8080.c.
- Compile ASM with c8080.c to c8080.asm
- Compile ASM with v6llvmc.c to v6llvmc.asm
- Fix C code if required (c8080 can complain for syntax).


Verification assembly steps:
- Compile ASM with v6llvmc.c to v6llvmc_improve.asm
- Analize the ASM code for improvements.
- Print it to the user explaining what is going on in the code. For CPU timing use docs\Vector_06c_instruction_timings.md
- If the improvements didn't show up, investigate, then go back to Verification assembly steps back.