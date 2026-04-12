# Plan: Redundant Flag-Setting Elimination (Post-RA)

## 1. Problem

### Current behavior

The V6C backend frequently emits `ORA A` (or `ANA A`) before conditional
branches to set the zero flag, even when the preceding ALU instruction
already set the flags correctly:

```asm
XRA  E          ; sets Z flag (A = A XOR E)
ORA  A          ; redundant — Z already reflects A's value
JZ   .label
```

The existing `V6CZeroTestOpt` pass replaces `CPI 0` with `ORA A` (saving
4cc), but this introduces new `ORA A` instructions that may themselves be
redundant after a preceding ALU operation. Additionally, pseudo expansion
and other passes can emit `ORA A` / `ANA A` for flag-setting purposes even
when the flags are already valid from a prior instruction.

### Desired behavior

Redundant `ORA A` / `ANA A` instructions should be eliminated when the
preceding instruction already set the Z flag based on A's current value:

```asm
; Before                    ; After
ANA  D       ;  4cc         ANA  D       ;  4cc
ORA  A       ;  4cc  ←del
JZ   label   ; 12cc         JZ   label   ; 12cc
```

### Root cause

Post-RA passes (especially `V6CZeroTestOpt` which converts `CPI 0` to
`ORA A`) and pseudo expansion don't track whether the Z flag is already
valid from a prior ALU operation. They conservatively insert `ORA A` to
guarantee flags are set, even when they already are.

---

## 2. Strategy

### Approach: Post-RA forward scan with Z-flag validity tracking

Add a new `MachineFunctionPass` (`V6CRedundantFlagElim`) that runs after
`V6CZeroTestOpt` in the pre-emit pipeline. It performs a simple forward
scan through each basic block, tracking whether the Z flag is "valid for
A" — meaning it was set by an instruction that both defines FLAGS and
operates on A.

### Why this works

On the 8080, all ALU instructions that modify A also set all flags (Z, S,
CY, P, AC). When we encounter `ORA A` or `ANA A` (which are identity
operations — they don't change A's value, only set flags), and the Z flag
is already valid for A from a preceding ALU instruction, the `ORA A`/
`ANA A` is provably redundant and can be safely deleted.

The analysis is strictly intra-BB with no inter-BB dataflow, making it
simple and safe.

### Summary of changes

| Step | What | Where |
|------|------|-------|
| 3.1 | New pass file | `V6CRedundantFlagElim.cpp` |
| 3.2 | Declare factory function | `V6C.h` |
| 3.3 | Register in pipeline | `V6CTargetMachine.cpp` |
| 3.4 | Add to build | `CMakeLists.txt` |
| 3.5 | Build | `ninja -C llvm-build clang llc` |
| 3.6 | Lit test | `tests/lit/CodeGen/V6C/redundant-flag-elim.ll` |
| 3.7 | Run regression tests | `python tests\run_all.py` |
| 3.8 | Verification assembly | `tests\features\README.md` steps |
| 3.9 | Sync mirror | `scripts\sync_llvm_mirror.ps1` |

---

## 3. Implementation Steps

### Step 3.1 — Create V6CRedundantFlagElim.cpp [x]

**File**: `llvm-project/llvm/lib/Target/V6C/V6CRedundantFlagElim.cpp`

Post-RA `MachineFunctionPass` with a forward scan through each basic block:

**Algorithm**:
1. Initialize `ZFlagValid = false` at the start of each basic block.
2. For each instruction:
   - If `ORA A` (ORAr with both src and dst being A) or `ANA A` (ANAr with
     src being A) and `ZFlagValid == true`: erase the instruction.
   - Else if the instruction defines FLAGS **and** defines/modifies A
     (ALU instructions: ADDr, ADCr, SUBr, SBBr, ANAr, ORAr, XRAr, and
     their immediate/memory variants; CMPr/CMPM/CPI; INRr with dst=A;
     DCRr with dst=A): set `ZFlagValid = true`.
   - Else if the instruction modifies A without setting flags (MOVrr with
     dst=A, MVI with dst=A, LDA, LDAX, POP PSW, etc.): set
     `ZFlagValid = false`.
   - Else if the instruction defines FLAGS without A (INRr/DCRr with dst≠A,
     DAD, INRM, DCRM, RLC, RRC, RAL, RAR): set `ZFlagValid = false`
     (flags no longer reflect A).
   - Else if branch/call/return: set `ZFlagValid = false` (conservative).
   - Else: keep `ZFlagValid` unchanged (e.g., MOV B,C, INX, DCX, NOP).

**CLI toggle**: `-v6c-disable-redundant-flag-elim`

> **Design Notes**:
> - `ORA A` is an identity operation: `A = A | A = A`. It only sets flags.
> - `ANA A` is also identity: `A = A & A = A`. It only sets flags.
> - We only need to check the Z flag validity for A, since ORA A / ANA A
>   are used exclusively to set the Z (and S) flag based on A's value.
> - CMP/CPI sets flags but does NOT modify A. After CMP, the Z flag
>   reflects `A - operand`, not just A. However, `ORA A` after CMP would
>   set Z based on A (not the comparison result), so this is a different
>   semantic. We should NOT mark ZFlagValid after CMP/CPI — we only want
>   to track when Z reflects A's value from an operation that wrote A.
>
>   Wait — actually, the pattern we're eliminating is `ORA A` used to test
>   if A is zero. If the preceding instruction is, e.g., `XRA E` (A = A^E),
>   then Z already reflects whether A is zero. `ORA A` after that is
>   redundant. But after `CMP E`, Z reflects A-E, not A. An `ORA A` after
>   `CMP E` would be used to test A itself (ignoring the comparison), which
>   is a different intent — so we should NOT eliminate it.
>
>   Therefore: `ZFlagValid = true` only for ALU instructions that **write A
>   and set FLAGS**. CMP/CPI set FLAGS but don't write A, so after CMP the
>   Z flag doesn't reflect A's value — it reflects the comparison result.
>   `ZFlagValid` stays false after CMP/CPI.

> **Implementation Notes**: (empty — filled after completion)

### Step 3.2 — Declare factory function in V6C.h [x]

**File**: `llvm-project/llvm/lib/Target/V6C/V6C.h`

Add:
```cpp
FunctionPass *createV6CRedundantFlagElimPass();
```

> **Implementation Notes**: (empty)

### Step 3.3 — Register pass in pipeline [x]

**File**: `llvm-project/llvm/lib/Target/V6C/V6CTargetMachine.cpp`

Add the pass **after** `V6CZeroTestOpt` (which creates `ORA A` from
`CPI 0`) and **before** `V6CSPTrickOpt`:

```cpp
addPass(createV6CZeroTestOptPass());
addPass(createV6CRedundantFlagElimPass());  // ← NEW
addPass(createV6CSPTrickOptPass());
```

> **Design Notes**: Must run after ZeroTestOpt because that pass creates
> `ORA A` instructions that may be redundant. Must run before SPTrickOpt
> since that pass restructures code significantly.

> **Implementation Notes**: (empty)

### Step 3.4 — Add to CMakeLists.txt [x]

**File**: `llvm-project/llvm/lib/Target/V6C/CMakeLists.txt`

Add `V6CRedundantFlagElim.cpp` to the source list.

> **Implementation Notes**: (empty)

### Step 3.5 — Build [x]

```
cmd /c "call ""C:\Program Files\Microsoft Visual Studio\2022\Community\Common7\Tools\VsDevCmd.bat"" -arch=amd64 >nul 2>&1 && ninja -C llvm-build clang llc 2>&1"
```

> **Implementation Notes**: (empty)

### Step 3.6 — Lit test: redundant-flag-elim.ll [x]

**File**: `tests/lit/CodeGen/V6C/redundant-flag-elim.ll`

Test cases:
1. ALU op + ORA A → ORA A eliminated (e.g., XRA + ORA A + JZ)
2. MOV A,r + ORA A → ORA A kept (MOV doesn't set flags)
3. CMP r + ORA A → ORA A kept (CMP sets flags for comparison, not A's value)
4. ALU op + MOV A,r + ORA A → ORA A kept (A was modified without flags)
5. Disabled pass → ORA A kept

> **Implementation Notes**: (empty)

### Step 3.7 — Run regression tests [x]

```
python tests\run_all.py
```

> **Implementation Notes**: (empty)

### Step 3.8 — Verification assembly steps from `tests\features\README.md` [x]

Follow feature test verification steps per `tests\features\README.md`.

> **Implementation Notes**: (empty)

### Step 3.9 — Sync mirror [x]

```
powershell -ExecutionPolicy Bypass -File scripts\sync_llvm_mirror.ps1
```

> **Implementation Notes**: (empty)

---

## 4. Expected Results

### Example 1: ALU + conditional branch

```asm
; Before                    ; After
ANA  D       ;  4cc         ANA  D       ;  4cc
ORA  A       ;  4cc  ←del
JZ   label   ; 12cc         JZ   label   ; 12cc
; Savings: 4cc, 1 byte per instance
```

### Example 2: XOR + conditional branch

```asm
; Before                    ; After
XRA  E       ;  4cc         XRA  E       ;  4cc
ORA  A       ;  4cc  ←del
JNZ  label   ; 12cc         JNZ  label   ; 12cc
; Savings: 4cc, 1 byte per instance
```

### Example 3: Subtract + conditional branch

```asm
; Before                    ; After
SUB  C       ;  4cc         SUB  C       ;  4cc
ORA  A       ;  4cc  ←del
JZ   label   ; 12cc         JZ   label   ; 12cc
; Savings: 4cc, 1 byte per instance
```

---

## 5. Risks & Mitigations

| Risk | Mitigation |
|------|------------|
| Incorrect elimination when Z flag has different semantics | Only eliminate when preceding insn writes A AND sets FLAGS. CMP/CPI excluded since Z reflects comparison, not A value. |
| Intervening instruction modifies A between ALU op and ORA A | Forward scan resets `ZFlagValid` on any A-modifying non-ALU instruction. |
| Intervening instruction modifies FLAGS without A | Forward scan resets `ZFlagValid` on any FLAGS-modifying non-A instruction (DAD, INR B, etc.). |
| Pseudo-instructions that expand later | Pass runs pre-emit, after all pseudos are expanded. |
| Pass ordering interaction | Runs after ZeroTestOpt (which creates ORA A) and before SPTrickOpt. |

---

## 6. Relationship to Other Improvements

- **V6CZeroTestOpt**: That pass converts `CPI 0` → `ORA A`. This pass
  eliminates the resulting `ORA A` when it's redundant after a prior ALU op.
  Together they form a two-stage optimization: first replace expensive
  zero-tests, then eliminate redundant ones.

- **V6CAccumulatorPlanning**: The accumulator planning pass tracks A contents
  for MOV elimination. This pass tracks FLAGS validity — orthogonal concerns.

- **V6CPeephole**: The peephole pass eliminates self-MOV and duplicate MOV.
  This pass eliminates redundant flag-setting — different patterns.

---

## 7. Future Enhancements

- **Inter-BB analysis**: Currently intra-BB only. Could extend to dominator-
  based analysis if more instances are found across basic blocks.
- **Carry flag tracking**: Could track CY flag validity separately for
  optimizations involving `STC` / `CMC` sequences.
- **ANA A elimination**: Same pass already handles `ANA A` — could be
  extended to other identity flag-setting patterns if they arise.

---

## 8. References

* [V6C Build Guide](docs\V6CBuildGuide.md)
* [Vector 06c CPU Timings](docs\Vector_06c_instruction_timings.md)
* [Future Improvements](design\future_plans\README.md)
* [llvm-z80 Z80PostRACompareMerge](design\future_plans\llvm_z80_analysis.md) §S7
* [V6CZeroTestOpt](llvm\lib\Target\V6C\V6CZeroTestOpt.cpp) — creates ORA A that this pass eliminates
