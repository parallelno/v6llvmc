Investigate if it is possible to teach compiler+linker to operate fraction of address.
like take a hi or lo byte of a address that will be resolved at the linking time.
============================
A special aligment that guarantee aligment INTO block, not at start of the block.
For example the data below all:
static block_align(256) uint8_t arr[10]
static block_align(256) uint8_t arr[10]
static int A = 10;
Research it. perhaps it can be done via lld scripts.
============================
important insights that can improve the V6C_LOAD8_FI:
1. The main goal for V6C compiler is to make static stack funcs the most performant, because they have less overhead.
2. In static-stack mode V6C_LOAD8_FI is not very popular. It is used only for arg passing via stack.

2. Register spilling is the biggest problem of the C compiler for i8080.
3. if the V6C_LOAD8_FI is inside a hot code (a loop), it will clobber hl (the most popular and effective regpair), and flags unconditionally increasing the register pressure.
4. we can read the reg without clobbering hl:
hl live, de dead:
new: xchg; lxi h, offset; dad sp; mov reg8, m; xchg; 40cc
old: clobbers hl, which can lead to spilling or less optimal
================================
possible bug. the svofski line draw program doesnt work when compiled with v6asm.
compare v6asm binary output with what the downloaded line bin from https://svofski.github.io/pretty-8080-assembler/
================================
optimization template:
make an optimization peephole design document and store it to design\future_plans\ folder. add it to design\future_plans\README.md.
...
================================
