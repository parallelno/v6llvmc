# V6C Optimization Passes

The V6C backend includes 11 custom optimization passes targeting the specific constraints of the Intel 8080 architecture. Each pass is individually toggleable via a command-line flag.

In addition to these custom passes, the target now enables LLVM's built-in
interprocedural register allocation (IPRA) by default at optimized levels.
IPRA is not a V6C-specific pass, but it materially reduces call-site spill /
reload traffic by narrowing preserved-register masks for direct calls when the
callee's real register usage is known.

## LSR Strategy (`-v6c-lsr-strategy`)

`V6CTTIImpl::isLSRCostLess` ranks LSR formula cost vectors with one of two
lexicographic orderings over the generic `LSRCost` fields. Both orderings
keep all other fields (`AddRecCost`, `NumIVMuls`, `NumBaseAdds`,
`ImmCost`, `SetupCost`, `ScaleCost`) in their LLVM-default positions; only
the `NumRegs`/`Insns` priority swaps.

* `regs-first` — `NumRegs` then `Insns` (default). Minimises register
  pressure first, which on i8080's 3 GP pairs (`HL`, `DE`, `BC`) is
  usually the correct proxy for total post-RA cost: every IV beyond the
  third forces a spill slot plus an in-loop reload sequence
  (`LXI HL,slot` / `MOV r,M` / `INX HL` / ... or `LHLD slot`).
* `insns-first` — `Insns` then `NumRegs` (Z80-style). Picks the formula
  with fewest pre-RA instructions; will accept +1 GP-pair pressure for
  one less in-loop ADD/INX or one less load fold.

**Flag.** `-v6c-lsr-strategy={auto,insns-first,regs-first}`. `auto` is the
default and currently maps to `regs-first` unconditionally — neither the
optimisation level (`-O2` vs `-Os`) nor per-function attributes
(`optsize`, `minsize`, `hot`, `cold`) change the dispatch yet. The
captured `Function *` is reserved for that future use; see plan §7.

**Examples.**

```bash
# Default: auto = regs-first at every -O level.
clang -target i8080-unknown-v6c -O2 file.c -S -o file.asm

# Opt in to insns-first for the whole TU (e.g. when the loop matches
# the bsort_two profile: >3 IVs, all touched every iteration).
clang -target i8080-unknown-v6c -O2 file.c -S -o file.asm \
      -mllvm -v6c-lsr-strategy=insns-first

# Force regs-first explicitly (bisection / pinning a known-good shape;
# byte-identical to -O2 default today, but immune to a future
# auto-dispatch change).
clang -target i8080-unknown-v6c -O2 file.c -S -o file.asm \
      -mllvm -v6c-lsr-strategy=regs-first

# Combine with -Os; insns-first overrides the size-mode default
# (which is also regs-first today).
clang -target i8080-unknown-v6c -Os file.c -S -o file.asm \
      -mllvm -v6c-lsr-strategy=insns-first
```

**Per-function selection (not yet supported).** `__attribute__((optsize))`
or `__attribute__((hot))` on individual functions does **not** currently
switch ordering — the flag is TU-global. If you need per-function
control today, split the loops across two compilation units. Plan §7
tracks the attribute-driven dispatch as a future enhancement.

**Empirical results.**

*Regression corpus A/B*
([tests/features/43/result.txt](../tests/features/43/result.txt)). All
42 feature tests rebuilt at `-O2` with each strategy and compared on
`.text` bytes:

| outcome                          | tests |
|----------------------------------|------:|
| `insns < regs` (insns-first wins) |     0 |
| `insns > regs` (insns-first regresses) | 3 |
| identical                        |    39 |

The three regressions: test 20 +235 B, test 29 +315 B, test 43 +53 B.
On test 43's `axpy3` kernel (4 stream pointers + counter) the inner
body grew 71 → 80 instructions (+12.7 %) under insns-first because LSR
picked formulas with one extra pointer IV and the post-RA reload
sequence is invisible to the `Insns` cost estimate. This is what set
the `auto = regs-first` default.

*Bubble-sort microbenchmark*
([tests/features/43/result_bsort.txt](../tests/features/43/result_bsort.txt)).
Counter-example showing where insns-first does help:

| function   | regs-first | insns-first | Δ      |
|------------|-----------:|------------:|-------:|
| `bsort` (2 ptrs) | 526 insn | 526 insn | 0 (byte-identical) |
| `bsort_two` (4 ptrs, all touched/iter) | 410 insn | 367 insn | **−43 (−10.5 %)** |

Both kernels nominally exceed the GP budget, but `bsort_two` touches
every stream every iteration, so insns-first's "one INX rp per stream"
schedule beats regs-first's pointer-fold-plus-recover schedule.
`axpy3` does not behave this way because its formulas only need one of
the streams reloaded per inner iteration.

**When to opt in.** Use `-mllvm -v6c-lsr-strategy=insns-first` for
loops where (a) the IV count exceeds 3 GP pairs and (b) every IV is
touched on every iteration. Verify with the A/B procedure documented
in `result_bsort.txt` before committing to it. For everything else
the default (`regs-first`) is the safer choice.

## Pass Pipeline Order

1. **IR-level** (in `addIRPasses()`): V6CLoopPointerInduction → V6CTypeNarrowing
2. **Post-register allocation** (in `addPostRegAlloc()`): V6CStaticStackAlloc
3. **Pre-register allocation** (in `addPreRegAlloc()`): V6CDeadPhiConst
4. **Pre-emit** (in `addPreEmitPass()`): V6CAccumulatorPlanning → V6CLoadImmCombine → V6CPeephole → V6CLoadStoreOpt → V6CXchgOpt → V6CBranchOpt → V6CZeroTestOpt → V6CRedundantFlagElim → V6CSPTrickOpt

## Pass Descriptions

### V6CZeroTestOpt

**Purpose:** Replace `CPI 0` (compare immediate 0, 8cc) with `ORA A` (OR accumulator with itself, 4cc) for zero-testing. Both set the Zero flag identically, but `ORA A` is 1 byte / 4 cycles cheaper.

**Pattern:**
```
Before: CPI 0       ; 2 bytes, 8cc
After:  ORA A       ; 1 byte, 4cc
```

**Toggle:** `-v6c-disable-zero-test-opt`

**Impact:** Saves 4 cycles and 1 byte per zero comparison. Common in loop termination and null checks.

---

### V6CXchgOpt

**Purpose:** Detect consecutive MOV instructions that swap DE and HL byte-by-byte, and replace them with the single `XCHG` instruction.

**Pattern:**
```
Before: MOV D, H    ; 8cc
        MOV E, L    ; 8cc  (total: 16cc, 2 bytes)
After:  XCHG        ; 4cc, 1 byte
```

**Toggle:** `-v6c-disable-xchg-opt`

**Impact:** Saves 12 cycles and 1 byte per DE↔HL swap. Frequent in 16-bit operations where values move between register pairs.

---

### V6CPeephole

**Purpose:** General peephole optimizations including:
- **Self-MOV elimination:** Remove `MOV X, X` (no-op moves).
- **Redundant consecutive MOV elimination:** Remove `MOV A, B; MOV A, B` sequences.
- **Strength reduction:** Replace `SHL 1` patterns with `ADD A, A` (same operation, already native).

**Toggle:** `-v6c-disable-peephole`

**Impact:** Eliminates dead code generated by pseudo-instruction expansion and register allocation.

---

### V6CLoadImmCombine

**Purpose:** Replace redundant `MVI r, imm` (move-immediate) instructions when the value is already available in another register or can be derived from the current register value.

**Patterns:**
- If another register already holds the same immediate → replace with `MOV r, r'` (1 byte saved)
- If the target register holds `imm - 1` → replace with `INR r` (1 byte saved)
- If the target register holds `imm + 1` → replace with `DCR r` (1 byte saved)

```
Before: MVI B, 5        ; 2 bytes
        ...              ; (A already = 5)
        MVI C, 5         ; 2 bytes (redundant)
After:  MVI B, 5         ; 2 bytes
        ...              ; (A already = 5)
        MOV C, A         ; 1 byte
```

**Toggle:** `-v6c-disable-load-imm-combine`

**Impact:** Saves 1 byte per replaced MVI. Per-basic-block analysis tracks all 7 general-purpose registers (A, B, C, D, E, H, L). Prefers non-A source registers to avoid accumulator contention.

---

### V6CAccumulatorPlanning

**Purpose:** Minimize accumulator traffic (MOV A,r / MOV r,A) by tracking which value is currently in A and reordering independent instructions to reduce round-trip moves.

**Pattern:**
```
Before: MOV A, B    ; load B into A
        ADD C       ; A += C
        MOV B, A    ; save result
        MOV A, D    ; load D into A (new value)
        ADD E       ; A += E
After:  (reordered to minimize A save/restore when possible)
```

**Toggle:** `-v6c-disable-acc-planning`

**Impact:** Reduces total MOV instructions involving A, which dominate 8080 code due to the accumulator architecture. Typical improvement: 5–15% fewer MOV-to/from-A instructions per basic block.

---

### V6CLoadStoreOpt

**Purpose:** Merge adjacent memory accesses that use consecutive addresses. When two loads/stores target addresses that differ by 1, replace the second `LXI HL, addr` with `INX HL`.

**Pattern:**
```
Before: LXI H, addr     ; 12cc
        MOV A, M         ; 8cc
        LXI H, addr+1   ; 12cc  (redundant — HL already near)
        MOV B, M         ; 8cc
After:  LXI H, addr     ; 12cc
        MOV A, M         ; 8cc
        INX H            ; 8cc   (saves 4cc + 2 bytes)
        MOV B, M         ; 8cc
```

Also eliminates dead `LXI HL` instructions whose result is overwritten before use.

**Toggle:** `-v6c-disable-loadstore-opt`

**Impact:** Reduces code size and cycle count for struct field access and array operations.

---

### V6CBranchOpt

**Purpose:** Optimize control flow:
- **Branch threading:** Thread conditional/unconditional branches through JMP-only blocks, redirecting them directly to the final target. Also handles tail-call (`V6C_TAILJMP`) targets.
- **Fallthrough elimination:** Remove `JMP` to the immediately following block.
- **Branch inversion:** When a conditional branch jumps over an unconditional jump (including `V6C_TAILJMP`), invert the condition and eliminate the jump.
- **Dead block removal:** Remove basic blocks with no predecessors.
- **Conditional return folding:** Fold conditional branches to return blocks into conditional return instructions.

**Pattern (branch threading):**
```
Before: JZ  .LBB1       ; conditional branch to JMP-only block
        ...
.LBB1:  JMP bar         ; JMP-only block
After:  JZ  bar         ; conditional branch directly to final target
```

**Pattern (branch inversion):**
```
Before: JZ  skip       ; if zero, jump over
        JMP target      ; unconditional jump
skip:   ...
After:  JNZ target      ; inverted: if not zero, jump to target
        ...              ; fall through
```

**Toggle:** `-v6c-disable-branch-opt`

**Impact:** Eliminates 3-byte/12cc unconditional jumps. Branch threading saves 3 bytes per threaded JMP-only block. Particularly effective after other passes create new fallthrough opportunities.

---

### V6CRedundantFlagElim

**Purpose:** Remove redundant `ORA A` / `ANA A` instructions when the Z flag already reflects the accumulator's value from a preceding ALU instruction. Both `ORA A` and `ANA A` are identity operations used solely to set flags.

**Pattern:**
```
Before: ANI 0x0F        ; A = A & 0x0F, sets Z flag
        ORA A           ; redundant — Z already reflects A
        JZ  target      ; branch on zero
After:  ANI 0x0F        ; A = A & 0x0F, sets Z flag
        JZ  target      ; branch on zero (ORA A eliminated)
```

**Toggle:** `-v6c-disable-redundant-flag-elim`

**Impact:** Saves 1 byte and 4 cycles per eliminated `ORA A` / `ANA A`. Common after instruction selection inserts flag-setting instructions before conditional branches.

---

## Debug Tools

### Disable SHLD/LHLD → PUSH/POP Fold (O43)

**Flag:** `-mllvm -v6c-disable-shld-lhld-fold` (default: off / fold enabled)

**Purpose:** Disables the O43 peephole in `V6CPeephole` that rewrites
adjacent `SHLD addr` / `LHLD addr` pairs into `PUSH H` / `POP H`. Intended
for:

1. **Debugging / A-B testing O43.** Compare codegen with and without the
   fold to attribute size/cycle deltas or isolate a suspected miscompile.
2. **Measuring future spill/reload research.** Experiments like O61 (spill
   into the reload's immediate operand) operate on the same SHLD/LHLD
   pairs that O43 consumes; running O43 first hides the opportunity. Pass
   this flag during prototyping so the SHLD/LHLD pairs survive to the
   later stage.

**Usage:**
```bash
clang -target i8080-unknown-v6c -O2 -S input.c -o output.s \
    -mllvm -v6c-disable-shld-lhld-fold
```

**Scope:** Does not affect any other peephole. Leave disabled in
production builds — O43 saves 12cc + 4B per folded pair.

---

### O61 — Spill Into the Reload's Immediate Operand

**Flag:** `-mllvm -mv6c-spill-patched-reload` (default: **off**)

**Purpose:** Enables the `V6CSpillPatchedReload` post-RA pass. Instead of
lowering a spill/reload pair to `SHLD slot` / `LHLD slot` (i16) or
`STA slot` / `LDA slot; MOV r, M` (i8), the pass rewrites the **reload**
to `LXI rp, 0` (i16) or `MVI r, 0` (i8) at a labelled site `.LLo61_N:`,
and rewrites the **spill** to store the live value directly into the
reload's immediate byte(s) — i.e. `SHLD .LLo61_N+1` / `STA .LLo61_N+1`
(self-modifying code).

**Preconditions:**
- Static stack allocation must be active for the function
  (`hasStaticStack()` — enabled by default, see `-mv6c-no-static-stack`).
- The SHLD/LHLD → PUSH/POP fold (O43) consumes the same pairs; for
  prototyping or A/B measurements combine with
  `-mllvm -v6c-disable-shld-lhld-fold`.

**Chooser (summary):** scores reloads by
`BlockFrequency × Δ(cycles)` and admits up to:
- K ≤ 2 patched reloads per single-source spill,
- K ≤ 1 patched reload per multi-source spill.
On the second patch of a single-source group the chooser excludes `A`
(i8, Δ = −8cc only) and `H`/`L` (they alias the `HL` pair used by the
unpatched classical reload fallback).

**Per-pattern savings (HL dead in the "before" path):**

| Width | Before                           | After        | Δ          |
|-------|----------------------------------|--------------|------------|
| i16   | `LHLD slot` = 16cc, 3B           | `LXI rp, 0` patched = 10cc, 3B | −6cc (HL dst), −12cc on `DAD` fold path |
| i8 → A | `LDA slot` = 13cc, 3B           | `MVI A, 0` patched = 7cc, 2B | −6cc, −1B |
| i8 → r8 | `LXI HL, slot` + `MOV r, M` = 17cc, 4B | `MVI r, 0` patched = 7cc, 2B | −10cc, −2B + BSS slot eliminated |

With HL live in the "before" path (classical reload wrapped in
`PUSH HL` / `POP HL`), the i8 non-A saving rises to −22cc / −4B.

**Usage:**
```bash
clang -target i8080-unknown-v6c -O2 -S input.c -o output.s \
    -mllvm -mv6c-spill-patched-reload
```

For clean demonstration of every patched site (no SHLD/LHLD pairs
getting folded away into `PUSH`/`POP`), combine with the O43 disable
flag:
```bash
clang -target i8080-unknown-v6c -O2 -S input.c -o output.s \
    -mllvm -mv6c-spill-patched-reload \
    -mllvm -v6c-disable-shld-lhld-fold
```

**Status:** Stages 1–5 complete (Stage 5 widens the i16 spill source
from HL-only to `{HL, DE, BC}`, unlocking DE/BC argument-routed spill
traffic); off by default pending broader code-in-RAM safety review
(the patched imm bytes live in `.text`, which assumes code is
RAM-resident and writable — true on Vector-06c but not on ROM/EPROM
targets). Test assets live under `tests/features/37/` (i8 scope),
`tests/features/39/` (Stage 5 DE/BC), and
`llvm/test/CodeGen/V6C/spill-patched-reload-*.ll`.

---

### Pseudo Expansion & Func Declaration Annotations

**Flag:** `-mv6c-annotate-pseudos` (default: off)

**Purpose:** Two features in one flag:
1. **Function header comments** — emits a C-like declaration and parameter→register mapping at the start of each function.
2. **Pseudo expansion comments** — inserts `;--- PSEUDO_NAME ---` before each pseudo-instruction expansion.

Useful for understanding calling convention register assignments and debugging code generation.

**Usage:**
```bash
clang -target i8080-unknown-v6c -O2 -S input.c -o output.s -mllvm -mv6c-annotate-pseudos
llc -march=v6c -O2 -mv6c-annotate-pseudos < input.ll
```

Add `-fno-discard-value-names` to preserve original C parameter names (otherwise they appear as `arg0`, `arg1`, etc.).

**Example output:**
```asm
	;=== char multi_live(char x, char y, char z) ===
	;  x = A
	;  y = E
	;  z = C
	;--- V6C_RELOAD8 ---
	LDA	__v6c_ss.multi_live+1
	;--- V6C_RELOAD8 ---
	MOV	D, H
	LXI	HL, __v6c_ss.multi_live
	MOV	L, M
	MOV	H, D
```

**Register assignment** (position-based, V6C calling convention):
| Position | i8 | i16/ptr |
|----------|-----|--------|
| Arg 1    | A   | HL     |
| Arg 2    | E   | DE     |
| Arg 3    | C   | BC     |
| Arg 4+   | stack | stack |

**Scope:** Function headers via `emitFunctionBodyStart` (V6CAsmPrinter.cpp). Pseudo comments cover both `expandPostRAPseudo` (V6CInstrInfo.cpp) and `eliminateFrameIndex` (V6CRegisterInfo.cpp) expansions.

**Note:** When enabled, annotation comments inserted between real instructions may reduce some peephole optimization opportunities (adjacency-sensitive patterns like XCHG cancellation or consecutive load/store merging). Use only for debugging, not production builds.

---

### V6CSPTrickOpt

**Purpose:** Replace byte-by-byte memory copy/set sequences (≥6 bytes) with the SP-trick: temporarily repurpose SP as a high-speed sequential read pointer using `POP` (12cc per 2 bytes vs 8cc per byte for MOV).

**Pattern:**
```
Before: (6+ individual MOV M,r / MOV r,M sequences)
After:  DI              ; disable interrupts (SP is unsafe)
        LXI SP, src     ; point SP at source
        POP D           ; load 2 bytes
        POP H           ; load 2 bytes
        ...
        SHLD dst+N      ; store via SHLD
        ...
        LXI SP, saved   ; restore SP
        EI              ; re-enable interrupts
```

**Toggle:** `-v6c-disable-sp-trick`

**Constraints:** Not used inside interrupt service routines (ISR). Always wrapped in DI/EI.

**Impact:** Major speedup for `memcpy`/`memset` of ≥6 bytes. Example: 64-byte copy drops from ~1024cc to ~400cc.

---

### V6CTypeNarrowing

**Purpose:** IR-level pass that narrows provably-bounded `i16` operations to `i8`. The 8080's native word is 8 bits; 16-bit operations expand to multi-instruction sequences. Narrowing saves significant code size and cycles.

**Patterns detected:**
- Loop induction variables with constant bounds fitting in 8 bits
- Values that are zero-extended from `i8` and only used in `i8`-width operations
- Truncated results where only the low byte is consumed

**Toggle:** `-v6c-disable-type-narrowing`

**Impact:** Eliminates unnecessary 16-bit pseudo-instruction expansions. A loop counter bounded 0..255 narrows from a 6-instruction 16-bit compare to a single `CPI` instruction.

---

### V6CStaticStackAlloc

**Purpose:** Replace the dynamic stack frame of provably non-reentrant functions with a statically-allocated global memory region. On the 8080, SP-relative access requires expensive `LXI HL, offset; DAD SP` sequences (20+ cycles, 4+ bytes). Static allocation replaces these with direct `SHLD`/`LHLD`/`STA`/`LDA` instructions and eliminates the stack frame prologue/epilogue entirely.

**Eligibility criteria** (see [V6CStaticStackAlloc.md](V6CStaticStackAlloc.md) for full details):
1. Function has `norecurse` attribute (inferred by `PostOrderFunctionAttrs` at `-O2`)
2. Function does not have `__attribute__((interrupt))` (the `"interrupt"` function attribute)
3. Function is not reachable from any interrupt handler (module-wide BFS from all `"interrupt"` functions)
4. Function's address is not taken
5. Function has non-fixed frame objects (spill slots or locals)

**Allocation scheme:** Each eligible function gets its own BSS symbol (`__v6c_ss.<funcname>`), sized to the function's stack frame. `eliminateFrameIndex` expands spill/reload pseudos to direct memory operations:

```
Before (SP-relative):
  PUSH HL             ; 16cc, 1B — save HL
  LXI  HL, offset     ; 12cc, 3B — compute stack address
  DAD  SP             ; 12cc, 1B
  MOV  M, E           ; 8cc,  1B — store low byte
  INX  HL             ; 8cc,  1B
  MOV  M, D           ; 8cc,  1B — store high byte
  POP  HL             ; 12cc, 1B — restore HL
  Total: 76cc, 9B

After (static, pair in HL):
  SHLD __v6c_ss.func+N  ; 20cc, 3B
  Total: 20cc, 3B
```

**Toggle:** Enabled by default. Disable with `-mv6c-no-static-stack`.

**Impact:** For spill-heavy functions, saves 32-56 cycles and 4-6 bytes per spill/reload operation. Eliminates prologue (PUSH + LXI + DAD SP + SPHL) and epilogue (LXI + DAD SP + SPHL + restore) entirely. In the feature test, `heavy_spill` improved by 404cc (53%) and 53B (52%).
