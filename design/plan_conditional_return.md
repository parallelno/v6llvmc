# Plan: Conditional Return Peephole — Jcc RET → Rcc (O30)

## 1. Problem

### Current behavior

When a conditional branch targets a block containing only `RET`, the
backend emits a 3-byte conditional jump followed by the 1-byte return:

```asm
test_ne_zero:
    MOV  A, H          ; 1B  4cc
    ORA  L             ; 1B  4cc
    JZ   .LBB0_2       ; 3B 12cc
    JMP  bar           ; 3B 12cc
.LBB0_2:
    RET                ; 1B 12cc
```

The `JZ .LBB0_2` + `.LBB0_2: RET` pair costs 4 bytes (3B jump + 1B RET)
and 24cc when taken (12cc jump + 12cc return).

### Desired behavior

```asm
test_ne_zero:
    MOV  A, H          ; 1B  4cc
    ORA  L             ; 1B  4cc
    RZ                 ; 1B 16cc (taken) / 8cc (not taken)
    JMP  bar           ; 3B 12cc
```

Savings: **3 bytes** per instance (3B Jcc → 1B Rcc, plus the RET block
may become dead and be removed). The Rcc instruction is 16cc when taken
vs Jcc+RET = 24cc when taken — also **8cc faster on the taken path**.

### Root cause

The 8080 conditional return instructions (`RZ`, `RNZ`, `RC`, `RNC`,
`RPO`, `RPE`, `RP`, `RM`) are defined in `V6CInstrInfo.td` but never
emitted. All returns go through unconditional `RET`. The peephole
pass does not look for Jcc → RET-only-block patterns.

---

## 2. Strategy

### Approach: Add `foldConditionalReturns()` to V6CBranchOpt

Add a new method to the existing `V6CBranchOpt` pass in
`V6CBranchOpt.cpp`. After `invertConditionalBranch` and
`removeRedundantJMP` have cleaned up branch patterns, scan for
conditional branches targeting RET-only blocks and replace them with
the corresponding conditional return instruction.

### Why this works

1. **1:1 opcode mapping** — every Jcc has a corresponding Rcc with
   identical condition semantics.
2. **RET-only block detection is trivial** — skip debug instrs, check
   for a single `RET` instruction.
3. **Existing dead-block cleanup** — `removeDeadBlocks()` already runs
   after other optimizations and will remove the RET block if it becomes
   unreachable.
4. **No register/flag side effects** — Rcc uses the same FLAGS as Jcc
   and pops SP identically to RET. No new register pressure.

### Run order within V6CBranchOpt::runOnMachineFunction

```
invertConditionalBranch  — may change which Jcc targets the RET block
removeRedundantJMP       — cleans up fall-through JMPs
foldConditionalReturns   — ← NEW: Jcc→RET becomes Rcc
removeDeadBlocks         — removes RET block if now unreachable
```

### Summary of changes

| Step | What | Where |
|------|------|-------|
| Add foldConditionalReturns | Replace Jcc→RET with Rcc | V6CBranchOpt.cpp |
| Add helper functions | getConditionalReturn, isReturnOnlyBlock | V6CBranchOpt.cpp |
| Wire into runOnMachineFunction | Call after removeRedundantJMP | V6CBranchOpt.cpp |
| Lit test | conditional-return.ll | tests/lit/CodeGen/V6C/ |
| Regression tests | run_all.py | tests/ |
| Feature test | tests/features/10/ | tests/features/ |

---

## 3. Implementation Steps

### Step 3.1 — Add helper functions and `foldConditionalReturns()` to V6CBranchOpt.cpp [x]

**File**: `llvm-project/llvm/lib/Target/V6C/V6CBranchOpt.cpp`

Add two static helpers:

```cpp
/// Map Jcc opcode to corresponding Rcc opcode, or 0 if not a Jcc.
static unsigned getConditionalReturn(unsigned JccOpc) {
  switch (JccOpc) {
  case V6C::JZ:  return V6C::RZ;
  case V6C::JNZ: return V6C::RNZ;
  case V6C::JC:  return V6C::RC;
  case V6C::JNC: return V6C::RNC;
  case V6C::JPE: return V6C::RPE;
  case V6C::JPO: return V6C::RPO;
  case V6C::JP:  return V6C::RP;
  case V6C::JM:  return V6C::RM;
  default: return 0;
  }
}

/// Return true if MBB contains only RET (ignoring debug instructions).
static bool isReturnOnlyBlock(const MachineBasicBlock &MBB) {
  for (const MachineInstr &MI : MBB) {
    if (MI.isDebugInstr())
      continue;
    return MI.getOpcode() == V6C::RET && MI.isTerminator();
  }
  return false; // empty block
}
```

Add the method to the class:

```cpp
bool V6CBranchOpt::foldConditionalReturns(MachineFunction &MF) {
  bool Changed = false;
  const TargetInstrInfo &TII = *MF.getSubtarget().getInstrInfo();

  for (MachineBasicBlock &MBB : MF) {
    // Look at terminators for conditional branches.
    for (auto I = MBB.terminators().begin(), E = MBB.terminators().end();
         I != E; ++I) {
      unsigned RccOpc = getConditionalReturn(I->getOpcode());
      if (!RccOpc)
        continue;

      MachineBasicBlock *Target = I->getOperand(0).getMBB();
      if (!isReturnOnlyBlock(*Target))
        continue;

      // Replace Jcc with Rcc.
      BuildMI(MBB, *I, I->getDebugLoc(), TII.get(RccOpc));

      // Update CFG: remove the edge to the RET block.
      MBB.removeSuccessor(Target);

      I->eraseFromParent();
      Changed = true;
      break; // terminators changed, move to next MBB
    }
  }
  return Changed;
}
```

Wire into `runOnMachineFunction`:

```cpp
bool V6CBranchOpt::runOnMachineFunction(MachineFunction &MF) {
  if (DisableBranchOpt)
    return false;

  bool Changed = false;
  Changed |= invertConditionalBranch(MF);
  Changed |= removeRedundantJMP(MF);
  Changed |= foldConditionalReturns(MF);
  Changed |= removeDeadBlocks(MF);
  return Changed;
}
```

> **Design Notes**: The `break` after erasing the terminator is needed
> because the terminator iterator is invalidated. Processing resumes
> on the next MBB. Multiple Jcc→RET patterns in the same block are
> rare (a block typically has at most one conditional branch to a RET
> block), but if they exist, a second pass over the function would
> catch them (the `Changed` flag is set, and re-running is optional).
>
> The `removeSuccessor` call is critical: without it, the RET block
> still appears reachable and `removeDeadBlocks` won't clean it up.

> **Implementation Notes**: Added `getConditionalReturn()` (static, 8-entry switch),
> `isReturnOnlyBlock()` (static, skips debug instrs), and `foldConditionalReturns()`
> method (~20 lines). Wired into `runOnMachineFunction` between `removeRedundantJMP`
> and `removeDeadBlocks`. Updated file header comment to list optimization #4.

### Step 3.2 — Build [x]

```
cmd /c "call ""C:\Program Files\Microsoft Visual Studio\2022\Community\Common7\Tools\VsDevCmd.bat"" -arch=amd64 >nul 2>&1 && ninja -C llvm-build clang llc 2>&1"
```

> **Implementation Notes**: Clean build, 22 targets rebuilt.

### Step 3.3 — Lit test: conditional-return.ll [x]

**File**: `tests/lit/CodeGen/V6C/conditional-return.ll`

Test cases:
1. `JZ .Lret; .Lret: RET` → `RZ` (zero condition)
2. `JNZ .Lret; .Lret: RET` → `RNZ` (non-zero condition)
3. RET block with other instructions before RET → does NOT fold
4. Multiple predecessors sharing same RET block → all get Rcc

> **Implementation Notes**: 3 test functions: `cond_ret_z` (RZ from JZ→RET),
> `no_fold_ret_val` (negative: LXI+RET block not folded), `multi_cond_ret`
> (two RZ in same function). Also updated 4 existing lit tests that expected
> JZ/JNZ where O30 now emits RZ/RNZ: dead-phi-const.ll, loop-counter-peephole.ll,
> cmp-based-br-cc16.ll, br-cc16-zero.ll.

### Step 3.4 — Run regression tests [x]

```
python tests\run_all.py
```

> **Implementation Notes**: 86/86 lit + 15/15 golden all pass.

### Step 3.5 — Verification assembly steps from `tests\features\README.md` [x]

Compile `tests\features\10\v6llvmc.c` to `v6llvmc_new01.asm` and verify
that `JZ`/`JNZ` to RET-only blocks are replaced with `RZ`/`RNZ`.

> **Implementation Notes**: v6llvmc_new01.asm confirms: test_ne_zero 9B→6B,
> test_eq_zero 9B→6B, test_multi_cond 30B→27B (all JZ→RZ folded).
> test_null_guard unchanged (correct: RET block not RET-only).

### Step 3.6 — Make sure result.txt is created. `tests\features\README.md` [x]

> **Implementation Notes**: result.txt created with c8080 vs v6llvmc comparison.
> Overall: 74B (c8080) vs 51B (v6llvmc) = 31% smaller.

### Step 3.7 — Sync mirror [x]

```
powershell -ExecutionPolicy Bypass -File scripts\sync_llvm_mirror.ps1
```

> **Implementation Notes**: Mirror sync complete.

### Example 1: test_ne_zero — conditional return on zero test

```asm
; Before (O27+O31 output)         ; After (O30)
test_ne_zero:                      test_ne_zero:
    MOV  D, H     ;  8cc              MOV  D, H     ;  8cc
    MOV  E, L     ;  8cc              MOV  E, L     ;  8cc
    LXI  HL, 0    ; 12cc              LXI  HL, 0    ; 12cc
    MOV  A, D     ;  8cc              MOV  A, D     ;  8cc
    ORA  E        ;  4cc              ORA  E        ;  4cc
    JZ   .LBB0_2  ; 12cc              RZ            ; 16cc (taken)
    MOV  H, D     ;  8cc              MOV  H, D     ;  8cc
    MOV  L, E     ;  8cc              MOV  L, E     ;  8cc
    JMP  bar      ; 12cc              JMP  bar      ; 12cc
.LBB0_2:                           ; (.LBB0_2 removed — dead)
    RET           ; 12cc
```

**Savings**: 3B code size (JZ 3B → RZ 1B, RET 1B block removed = net −3B),
8cc faster on taken path (16cc vs 12+12=24cc).

### Example 2: test_eq_zero — same pattern, different condition

Same savings apply. `JZ .Lret` → `RZ` when the RET block is the target.

### Example 3: test_const_42 — two-byte CMP with RET target

```asm
; The JZ .LBB2_2 at the end of the CMP expansion targets a RET block.
; After O30: JZ → RZ, saving 3B.
```

---

## 5. Risks & Mitigations

| Risk | Mitigation |
|------|------------|
| Removing successor edge corrupts CFG | Only remove edge when Jcc is replaced with Rcc (which is `isReturn=1`) |
| RET block removed while still reachable | `removeDeadBlocks` checks `pred_empty()` — other predecessors keep block alive |
| Rcc not recognized by later passes | Rcc instructions have `isReturn=1, isTerminator=1` — standard LLVM semantics |
| Debug instructions in RET block cause false negative | `isReturnOnlyBlock` explicitly skips debug instrs |

---

## 6. Relationship to Other Improvements

- **O14 (Tail Call)**: After CALL+RET → JMP, the RET block may serve
  only conditional-return paths, making it a prime Rcc candidate.
- **O23 (Conditional Tail Call)**: Reduces some RET blocks, but the
  remaining ones are still targets for Jcc→Rcc folding.
- **O27 (i16 Zero-Test)**: Produces `JZ .Lret` / `JNZ .Lret` patterns
  (from `MOV A,H; ORA L; JZ .Lret`) that are ideal candidates.
- **O28 (Branch Threading)**: Threading JMP-only blocks may redirect
  branches away from RET blocks or expose new Jcc→RET patterns.
  Both passes should run; O30 runs as part of BranchOpt which is
  already in the pipeline.
- **O31 (Dead PHI-Constant)**: Eliminates LXI+shuffle code but leaves
  Jcc→RET patterns intact — O30 cleans them up.

## 7. Future Enhancements

- **Iterative folding**: A second pass could catch cases where the
  first fold exposed new Jcc→RET patterns (e.g., if a JMP after the
  Rcc is removed, turning a two-terminator block into one).
- **Conditional call folding (O15)**: Similar pattern — `Jcc .Lskip;
  CALL target; .Lskip:` → `Ccc target`. Shares the condition-mapping
  infrastructure.

## 8. References

* [V6C Build Guide](docs\V6CBuildGuide.md)
* [Vector 06c CPU Timings](docs\Vector_06c_instruction_timings.md)
* [Future Improvements](design\future_plans\README.md)
* [O30 Feature Description](design\future_plans\O30_conditional_return.md)
* [V6CBranchOpt.cpp](llvm\lib\Target\V6C\V6CBranchOpt.cpp)
