# Golden Test Suite

This directory contains hand-written 8080 assembly programs with known outcomes.
They serve as the **emulator trust baseline** — if these tests pass, we can trust
`v6emul` as a correctness oracle for compiler output validation.

## Test Format

Each `.asm` file contains a header with expected outcomes:

```asm
; TEST: <name>
; DESC: <description>
; EXPECT_HALT: yes
; EXPECT_OUTPUT: <val1>, <val2>, ...   (decimal values output via OUT 0xED)
; EXPECT_REG: A=<hex> [B=<hex>] ...
```

## Test List

| # | File | Description | Key Instructions |
|---|------|-------------|------------------|
| 01 | `01_nop_hlt.asm` | Minimal NOP + HLT | NOP, HLT |
| 02 | `02_mvi_regs.asm` | Load immediates to all registers | MVI |
| 03 | `03_mov_regs.asm` | Register-to-register MOV chain | MOV |
| 04 | `04_add_basic.asm` | ADD, ADI, ADC with carry | ADD, ADI, ADC |
| 05 | `05_sub_borrow.asm` | SUB, SUI, SBB with borrow | SUB, SUI, SBB |
| 06 | `06_logic_ops.asm` | AND, OR, XOR, complement | ANA, ORA, XRA, CMA, ANI, ORI, XRI |
| 07 | `07_inr_dcr.asm` | Increment/decrement with wrap | INR, DCR |
| 08 | `08_jmp_branch.asm` | Unconditional and conditional jumps | JMP, JZ, JNZ |
| 09 | `09_call_ret.asm` | Subroutine call/return, nesting | CALL, RET |
| 10 | `10_push_pop.asm` | Stack PUSH/POP with LIFO verify | PUSH, POP |
| 11 | `11_lxi_dad.asm` | 16-bit loads and addition | LXI, DAD |
| 12 | `12_memory_ops.asm` | All memory access modes | STA, LDA, MOV M, STAX, LDAX, SHLD, LHLD |
| 13 | `13_rotate.asm` | Bit rotation operations | RLC, RRC, RAL, RAR |
| 14 | `14_compare.asm` | Comparison with conditional branches | CMP, CPI, JZ, JC, JNC |
| 15 | `15_fibonacci.asm` | Compute fib(10)=55 via loop | Integration test |

## Running

From the project root:

```bash
python tests/run_golden_tests.py
```

Options:
- `--verbose` / `-v` — show emulator output for each test
- `--v6asm <path>` — path to v6asm executable
- `--v6emul <path>` — path to v6emul executable
- Positional args — run specific test files only

## Expected Outcome

All 15 tests should pass. If any test fails, either:
1. The emulator has a bug (unlikely for standard 8080 opcodes), or
2. The test itself has an error in expected values (fix the test).

Once all tests pass, `v6emul` is trusted as the execution oracle for all
subsequent compiler output validation.
