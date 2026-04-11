# Reference test cases saved in this folder.
It is used by the implementation feature plan in Step 3.9 — Verify assembly

## Folder Layout:
tests\features\README.md - this doc
tests\features\01\ - first feature test case
tests\features\02\ - second feature test case
tests\features\NN\ ...

Compile ASM guide:
- tools\c8080\c8080.exe tests\features\<feature number>\c8080.c -a tests\features\<feature number>\c8080.asm
- llvm-build\bin\clang -target i8080-unknown-v6c -O2 -S tests\features\<feature number>\v6llvmc.c -o tests\features\<feature number>\v6llvmc.asm


## Preparation steps:
- Create a new folder in tests\features. The name is two digits.
- Create a test case that the new feature will improve.
- Store the test case to v6llvmc.c and c8080.c.
- Compile ASM with c8080.c to c8080.asm.
- Compile ASM with v6llvmc.c to v6llvmc.asm.
- Fix C code if required (c8080 can complain about syntax).
- Inform the user, then pause to let the user verify the new files.
- Return to the pipeline (Phase 2).

Each folder must have:
c8080.c - test for c8080 compiler
v6llvmc.c - test for this compiler

## Verification assembly steps:
- Compile ASM with v6llvmc.c to v6llvmc_improve01.asm.
- Analyze the ASM code for improvements.
- Present it to the user, explaining what changed and why.
- If the improvements didn't show up, investigate and fix, then repeat from the top of this section. Each recompiled ASM file gets the next number: v6llvmc_improve02.asm, v6llvmc_improve03.asm, etc.
- When the ASM shows the expected improvement, create result.txt.

## result.txt structure
- The C test case code.
- c8080 asm, but only the main func and dependent funcs body converted from Z80 asm to i8080 asm.
- c8080 stats: total CPU cc, length in bytes.
- v6llvmc asm.
- v6llvmc stats: total CPU cc, length in bytes.


## After verification each folder must have:
c8080.c - test for c8080 compiler
c8080.asm
v6llvmc.c - test for this compiler
v6llvmc.asm
v6llvmc_improve01.asm
v6llvmc_improve02.asm
...
v6llvmc_improveNN.asm
result.txt

## Reference
- CPU timings — docs\Vector_06c_instruction_timings.md
- Feature pipeline — design\pipeline_feature.md
- Feature plan prompt — design\feature_plan_prompt.md
- Future optimizations — design\future_plans\README.md