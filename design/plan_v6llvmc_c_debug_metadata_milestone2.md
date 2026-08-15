# Plan: C Debug Metadata Milestone 2 - Call-Frame Information

**Status:** Proposed
**Depends on:** Milestone 1
**Blocks:** Frame-sensitive variables and semantic Call Stack

## 1. Problem

### Current behavior

V6C emits no `.debug_frame`. Frame lowering selects among PUSH/POP, repeated
INX/DCX SP, and LXI/DAD/SPHL adjustments based on frame size, liveness, and
optimization mode. It may save argument pairs, establish BC as a frame
pointer, and preserve return registers through several instruction sequences.

### Desired behavior

Every unwindable C function must have CIE/FDE rules that recover CFA, caller
SP, return PC, saved registers, and frame pointer at every PC in prologue,
body, and epilogue. Unsupported interrupt/trampoline boundaries must stop
honestly.

### Root cause

`V6CFrameLowering` emits machine instructions but no `CFI_INSTRUCTION`
records, and no target policy currently requests debugger-only frame data.

## 2. Strategy

### Approach: emit CFI beside the actual stack mutations

Prefer `.debug_frame`. Define entry CFA from SP and the two-byte return address,
then update CFA/register rules immediately after each generated PUSH, POP, SP
adjustment, FP establishment/restoration, and temporary save. Use the real
selected prologue path rather than duplicating its cost-model decision.

### Why this works

CFI follows the emitted instruction stream, so all existing optimizations and
dynamic prologue choices remain enabled. The unwind description observes the
chosen code instead of constraining code generation.

### Summary of changes

- Configure debugger CFI emission and return-address register.
- Add reusable CFI builders to frame lowering.
- Cover all prologue/epilogue tiers, multiple returns, FP modes, tail calls,
  naked/runtime helpers, and interrupt boundaries.
- Verify unwind rows against real emulator snapshots.

## 3. Implementation Steps

### Step 3.1 - Read references and capture baselines [ ]

Review milestone 1's frozen ABI/register map, `V6CFrameLowering`, calling
convention, tail-call transforms, naked/interrupt handling, MC CFI support,
and v6vscode's CFI consumer plan. Capture current full benchmark, ROM, `.text`,
and assembly baselines.

> **Implementation Notes**:

### Step 3.2 - Define the CIE and unwind policy [ ]

Specify code/data alignment, CFA at function entry, return-address column and
location, caller SP derivation, initial same/undefined rules, tail-call policy,
naked helper policy, and explicit interrupt/trampoline stop rules.

> **Implementation Notes**:

### Step 3.3 - Add target CFI emission plumbing [ ]

Configure `.debug_frame` generation and add helpers that insert
`TargetOpcode::CFI_INSTRUCTION` using milestone 1's register numbers. Keep CFI
instructions metadata-only and excluded from optimization matching.

> **Implementation Notes**:

### Step 3.4 - Instrument every prologue path [ ]

Emit state changes for saved HL/DE/BC/PSW where semantically recoverable,
every PUSH-based allocation, every INX/DCX SP step or aggregate equivalent,
LXI/DAD/SPHL completion, BC frame-pointer setup, stack argument layout, and
temporary saves. Test CFA at each instruction boundary.

> **Implementation Notes**:

### Step 3.5 - Instrument every epilogue and return path [ ]

Cover FP and omitted-FP restoration, all SP adjustment tiers, saved return
registers, multiple returns, conditional returns, tail calls, and unsupported
boundaries. Use remember/restore state only where LLVM's generated control flow
requires it.

> **Implementation Notes**:

### Step 3.6 - Build [ ]

Run `pwsh scripts/build.ps1 -SkipTests`.

> **Implementation Notes**:

### Step 3.7 - Add focused CFI lit tests [ ]

Use IR/MIR and `llvm-dwarfdump --debug-frame` assertions for leaf/non-leaf,
frame sizes selecting every adjustment tier, HL/DE live-ins, BC FP, stack
arguments, spills, multiple/conditional returns, tail calls, naked helpers,
and interrupts. Verify object and final linked ELF FDE ranges.

> **Implementation Notes**:

### Step 3.8 - Add unwind integration and emulator tests [ ]

Create a noinline three-function fixture. Stop in prologue, body, and epilogue;
capture emulator registers/memory; evaluate CFI; and prove each recovered
caller SP/PC against execution. Include one honest boundary-stop fixture.

> **Implementation Notes**:

### Step 3.9 - Prove optimization and performance non-regression [ ]

No optimization may be disabled or deleted. CFI must not change executable
instructions. Require baseline-identical `-g0` output, executable-byte identity
between `-g` and matching `-g0`, identical checksums, and no cycle or code-size
increase in any benchmark row.

> **Implementation Notes**:

### Step 3.10 - Run regression tests [ ]

Run relevant lit tests, emulator tests, then `python tests/run_all.py` with the
benchmark suite enabled.

> **Implementation Notes**:

### Step 3.11 - Verify assembly and create `result.txt` [ ]

Follow `tests/features/result.md`. Include assembly identity evidence,
`llvm-dwarfdump --debug-frame`, per-PC expected/actual unwind rows, emulator
snapshots, and old/new benchmark tables.

> **Implementation Notes**:

### Step 3.12 - Document, sync, and mark complete [ ]

Publish the CFI contract and limitations, sync mirrors, verify final linked
ELFs, and mark all steps plus the master milestone complete.

> **Implementation Notes**:

## 4. Expected Results

- A real three-function C chain unwinds from stopped emulator state.
- Prologue and epilogue stops recover only state valid at that PC.
- Executable output and all benchmark performance remain unchanged.

## 5. Risks & Mitigations

| Risk | Mitigation |
|------|------------|
| CFI is attached after the wrong instruction | Assert rows at every prologue/epilogue PC. |
| Liveness-dependent path is omitted | Force every path with dedicated MIR/IR fixtures. |
| Tail calls fabricate frames | Specify and test frame replacement semantics. |
| Metadata changes code layout | Compare executable sections and ROM, not whole ELF size. |

## 6. Relationship to Other Improvements

CFI describes existing optimized frame lowering without changing its cost
model. Milestone 3 uses CFA/frame-base facts; v6vscode Call Stack consumes the
final rules.

## 7. Future Enhancements

`.eh_frame` and exception unwinding remain out of scope unless a runtime use
case is approved.

## 8. References

- [Master Plan](plan_v6llvmc_c_debug_metadata.md)
- [Milestone 1](plan_v6llvmc_c_debug_metadata_milestone1.md)
- [V6C Build Guide](../docs/V6CBuildGuide.md)
- [Vector 06c CPU Timings](../docs/Vector_06c_instruction_timings.md)
- [Future Improvements](future_plans/README.md)
