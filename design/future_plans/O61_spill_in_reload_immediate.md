# O61: Spill Into the Reload's Immediate Operand

## Example

A function exercising spill/reload traffic under register pressure. A
self-contained reproducer lives at [temp/o61_test.c](../../temp/o61_test.c):

```c
// temp/o61_test.c
__attribute__((leaf)) extern void use8(unsigned char x);

__attribute__((noinline))
unsigned char arr_sum(unsigned char* arr, unsigned char n) {
    unsigned char sum = 0;
    for (unsigned char i = 0; i < n; ++i) {
        sum += arr[i];
        unsigned char tmp2 = (int)(arr) >> 8;
        unsigned char tmp = tmp2 & i + n & arr[i-1];
        use8(tmp);
        sum |= tmp2;
    }
    return sum;
}
```

Build with:

```
llvm-build\bin\clang -target i8080-unknown-v6c -O2 -S temp\o61_test.c \
    -o temp\o61_test.asm \
    -mllvm --enable-deferred-spilling -mllvm -mv6c-annotate-pseudos \
    -mllvm -v6c-disable-shld-lhld-fold
```

The loop body holds `arr` (HL/DE pointer), `i`, `n`, `sum`, `tmp2`, and the
transient `arr[i]` / `arr[i-1]` loads simultaneously — more live values than
GPRs — so RA emits multiple `V6C_SPILL*` / `V6C_RELOAD*` pairs per iteration.
Each reload is a prime O61 candidate: the spilled value is consumed exactly
once, on a single code path, and the function is static-stack-eligible
(`noinline`, no address-taken locals, not reachable from an ISR).

### Disabling O43 for O61 measurements

[O43](O43_shld_lhld_to_push_pop.md) (`foldShldLhldToPushPop`) rewrites
adjacent `SHLD addr` / `LHLD addr` pairs into `PUSH H` / `POP H`, collapsing
the very spill/reload pairs that O61 wants to rewrite into patched `LXI`
reloads. When measuring or prototyping O61, O43 must be disabled so the
SHLD/LHLD pairs survive into the expansion stage where the O61 rewrite
runs. Disable via the existing hidden flag:

```
-mllvm -v6c-disable-shld-lhld-fold
```

Full command for the reproducer:

```
llvm-build\bin\clang -target i8080-unknown-v6c -O2 -S temp\o61_test.c \
    -o temp\o61_test.asm \
    -mllvm --enable-deferred-spilling -mllvm -mv6c-annotate-pseudos \
    -mllvm -v6c-disable-shld-lhld-fold
```

Once O61 lands, the two passes should coexist via a cost model that picks
whichever form is cheaper per pair rather than running both blindly — O43
wins when the SHLD/LHLD pair is tight and HL-only; O61 wins across the
broader set of registers and when the spill/reload are far apart (PUSH/POP
requires an empty intervening stack-discipline window, O61 does not).

## The Idea

Under **static stack allocation**, code lives at link-time-known addresses in
RAM (the Vector 06c runs code from RAM). The classical spill/reload pair

```
spill:   SHLD __v6c_ss.f+N        ; HL -> data slot        20cc
...
reload:  LHLD __v6c_ss.f+N        ; slot -> HL             20cc
```

can be collapsed by making the **reload instruction itself be the data slot**.
The spill patches the immediate operand of the reload (self-modifying code):

```
spill:   SHLD reload_site+1        ; HL -> imm16 of LXI    20cc
...
reload_site:
         LXI  HL, 0x0000           ; imm16 was patched     12cc
```

Invariants:
* `reload_site+1` is the absolute address of the first byte of the `imm16`
  field of `LXI HL, imm16` (opcode `0x21`, then lo, hi).
* After the spill, the LXI's immediate bytes equal the value written.
* The reload executes the patched LXI and materialises the value in HL.

The same construction works for any `imm16`/`imm8`-carrying instruction whose
immediate position is known:

| Reg  | Reload instruction | Opcode byte | imm addr  | Cost |
|------|--------------------|-------------|-----------|------|
| HL   | `LXI  HL, nn`      | `0x21`      | site+1    | 12cc |
| DE   | `LXI  DE, nn`      | `0x11`      | site+1    | 12cc |
| BC   | `LXI  BC, nn`      | `0x01`      | site+1    | 12cc |
| A    | `MVI  A,  n`       | `0x3E`      | site+1    | 8cc  |
| B    | `MVI  B,  n`       | `0x06`      | site+1    | 8cc  |
| C    | `MVI  C,  n`       | `0x0E`      | site+1    | 8cc  |
| D    | `MVI  D,  n`       | `0x16`      | site+1    | 8cc  |
| E    | `MVI  E,  n`       | `0x1E`      | site+1    | 8cc  |
| H    | `MVI  H,  n`       | `0x26`      | site+1    | 8cc  |
| L    | `MVI  L,  n`       | `0x2E`      | site+1    | 8cc  |

## Cycle/Size Comparison vs Current Spilling

Baseline assumes static stack (SHLD/LHLD/STA/LDA are available). All
cycle figures are V6C cycles per
[V6CInstructionTimings.md](../../docs/V6CInstructionTimings.md):
`MOV r,r`/`MVI r,d8` = 8cc, `LXI rp,d16` = 12cc, `LDA`/`STA` = 16cc,
`LHLD`/`SHLD` = 20cc, `XCHG` = 4cc.

### Reloads (reload site only)

`Δ/reload` is positive when patching saves cycles/bytes.

| Target | Current reload (best case)                          | Cost  | Bytes | Patched reload | Cost  | Bytes | Δ/reload   |
|--------|------------------------------------------------------|-------|-------|----------------|-------|-------|------------|
| HL     | `LHLD addr`                                          | 20cc  | 3     | `LXI HL,imm`   | 12cc  | 3     | +8cc,  0B  |
| DE (HL dead) | `LHLD addr; XCHG`                              | 24cc  | 4     | `LXI DE,imm`   | 12cc  | 3     | +12cc, +1B |
| DE (HL live) | `XCHG; LHLD addr; XCHG`                        | 28cc  | 5     | `LXI DE,imm`   | 12cc  | 3     | +16cc, +2B |
| BC (HL dead) | `LHLD addr; MOV C,L; MOV B,H`                  | 36cc  | 5     | `LXI BC,imm`   | 12cc  | 3     | +24cc, +2B |
| BC (HL live) | `PUSH H; LHLD addr; MOV C,L; MOV B,H; POP H`   | 64cc  | 7     | `LXI BC,imm`   | 12cc  | 3     | +52cc, +4B |
| A      | `LDA addr`                                           | 16cc  | 3     | `MVI A,imm`    | 8cc   | 2     | +8cc,  +1B |
| r8 (A dead)  | `LDA addr; MOV r,A`                            | 24cc  | 4     | `MVI r,imm`    | 8cc   | 2     | +16cc, +2B |
| r8 (A live)  | save/restore A around `LDA;MOV r,A`            | 52cc+ | 6+    | `MVI r,imm`    | 8cc   | 2     | +44cc+     |

For non-accumulator 8-bit regs and non-HL 16-bit pairs the win is large —
precisely the cases where the current backend routes through HL/A and
burns cycles. The smallest wins are on `HL` and `A` themselves — their
classical reload (`LHLD` / `LDA`) is already a single direct instruction,
so patching only saves the difference between a load and a like-sized
immediate-form instruction.

### Spill side

Each spill does the same absolute-address store it does today, just
targeting a code address instead of a BSS address:

| Reg          | Spill instruction              | Cost     |
|--------------|--------------------------------|----------|
| HL           | `SHLD site+1`                  | 20cc     |
| DE (HL dead) | `XCHG; SHLD site+1`            | 24cc     |
| DE (HL live) | `XCHG; SHLD site+1; XCHG`      | 28cc     |
| BC           | through HL/A/PUSH-POP          | 36–48cc  |
| A            | `STA site+1`                   | 16cc     |
| r8 (non-A)   | `MOV A,r; STA site+1`          | 24cc     |

Spill cost is unchanged from today (except the target address). The
optimization is a pure reload-side improvement.

### Memory footprint

* Current: each spill slot takes 1B (i8) or 2B (i16) in `__v6c_ss.f` BSS
  **plus** the reload-site instruction (LHLD = 3B, LDA = 3B, +routing).
* Patched: the reload-site instruction *is* the slot. BSS usage drops by
  1B/2B per spill slot. Reload-site size either stays the same (HL) or
  shrinks (all other cases).

## Prerequisites

1. **Static stack eligibility** (already enforced by `V6CStaticStackAlloc`):
   no recursion, not reachable from ISRs, no taken address, has frame
   objects. The reload-site must be written only by this function's spill.
2. **Code is in RAM**. V6C runs from RAM; OK.
3. **Spill dominates reload** on every path. Already an invariant of spill
   insertion (RA only inserts a reload where the slot is defined on every
   reaching path). Multiple spills joining into a single reload (Φ-style)
   still work — every spill writes the same physical bytes.
4. **Reload-site addressability at link time.** The spill's operand must be
   `reload_site+offset`. That means either:
   * an assembler-level local symbol emitted next to the reload, referenced
     from the spill — the V6C object writer already supports `R_V6C_16`
     relocations (see M10), so this is straightforward, OR
   * an `MCSymbol` materialised in the MCStreamer and referenced as the
     spill's operand.


## Pitfalls and Non-Issues

* **Interrupts.** An ISR cannot trample the reload-site because the static
  stack pass already forbids running this optimization for any function
  reachable from an ISR. Good.
* **Instruction prefetch.** The 8080 has no instruction prefetch beyond the
  fetched byte currently being decoded. Patching bytes that have not yet
  been fetched is safe. The 20cc SHLD completes and commits to memory
  before the next fetch cycle.
* **Debugger breakpoints.** A software breakpoint at the reload site
  overwrites the `LXI` opcode with `RST`. Patching the imm bytes does not
  disturb the opcode. Low risk.
* **Disassembler / symbolic debugging.** The reload site looks like a
  mutable literal. DWARF/line info still points at the LXI. Cosmetic only.
* **ROM targets.** Not applicable — Vector 06c runs RAM. Would need a
  guard if cross-targeting a ROM-only variant.
* **Relocations after link.** `site+1` is a fully resolved absolute address
  once the linker places the function. Nothing special at runtime.
* **Function entry before first spill.** The first execution of the reload
  site before a spill runs would read the initial (linker-placed) bytes.
  Safe only if reload is **unreachable** before the spill — same property
  RA already guarantees for a reload from an uninitialised slot (it never
  emits one). So this is not a new constraint.
* **Multiple spills on diverging paths (no join).** Each path must dominate
  the reload it reaches; RA ensures this. If two paths spill the *same*
  vreg and both reach the same reload, the reload reads whichever spill
  executed last — which is also the semantics of the classical slot.
* **Function called twice from the same activation chain.** Forbidden by
  `norecurse`; already enforced.
* **Tail-merged spill, two reload sites.** Each site has its own imm slot;
  spill must write both. Either duplicate the spill or keep a classical
  slot — the cost model picks.

## How It Maps Onto the Current Pipeline

The optimization is an **expansion-time rewrite**, not a new RA feature.
The RA continues to create `V6C_SPILL*` / `V6C_RELOAD*` pseudos exactly as
today. The change happens in `eliminateFrameIndex` /
`expandPostRAPseudo` in `V6CRegisterInfo.cpp`, keyed on:

1. Function is in the static-stack set (already a queryable attribute).
2. The cost model (see [Cost Model](#cost-model)) selects `K ≥ 1`
   reload sites of this spill to patch. `K = 0` falls back to the
   classical slot path.
3. The reload site's register is a whole register pair (LXI) or a single
   8-bit reg (MVI) — i.e. the reload instruction itself admits an
   immediate operand of the right width.

Rewrite (per patched site):
* Allocate a private `MCSymbol` at the reload site (an `.Ltmp` label).
* Replace the reload pseudo with `LXI r16, 0` or `MVI r8, 0`
  whose immediate carries the target flag `MO_PATCHED_IMM`.
* Replace **every** spill of this slot with a store of the spilled
  value to `Sym+1` (`SHLD Sym+1` or `STA Sym+1`) — same shape as the
  classical spill, just a different address operand.
* Emit the `.Ltmp` label immediately before the reload instruction in
  the asm/object stream so `Sym+1` resolves to the imm byte.
* For each *unpatched* reload of the same slot, retarget its memory
  operand from the classical BSS slot to `Sym+1` of one of the patched
  sites — the patched site's imm bytes serve as the data slot.

No change to RA, no change to pseudo set, no new register class, no new
verifier property. The single invasive change outside the expansion
logic is the `MO_PATCHED_IMM` flag plus its `LoadImmCombine` /
`AccumulatorPlanning` opt-out.

## Interactions With Other Features / Opts

* **O39 Static Stack Alloc** — this optimization *requires* static stack
  eligibility. Functions that fail the static stack criteria fall back to
  the classical slot path.
* **LoadImmCombine / AccumulatorPlanning** — both passes assume the
  immediate of an `MVI`/`LXI` is a known constant derivable from the
  instruction itself. A patched imm is *not* known at compile time. The
  reload's `LXI/MVI` must be marked with `MO_PATCHED_IMM` (or similar) so
  these passes treat it as an opaque load, not as a constant-producing
  instruction. This is the single invasive change outside the expansion
  logic.
* **V6CLoadStoreOpt / INX HL merging** — does not run on the reload site
  (no consecutive LXI+MOV pattern).
* **V6CRedundantFlagElim / ZeroTestOpt** — `LXI` and `MVI` do not touch
  flags, so no interaction.
* **Linker / relocations** — no change. The spill's `SHLD Sym+1` uses the
  existing `R_V6C_16` relocation.

## Cost Model

A patched reload site doubles as a 1- or 2-byte data slot, so the
remaining (un-patched) reloads of the same spill can read directly from
a patched site's imm-field bytes with a normal `LHLD` / `LDA`. For a
spill with `N` reloads we pick `K ∈ {0..N}` reload sites to patch:

```
cost(K) =   K * spill_cost
          + Σ_{i ∈ patched}     reload_imm_cost(i)
          + Σ_{j ∉ patched}     reload_slot_cost(j)
```

The patched sites act as the slot for the unpatched ones, so no
separate BSS slot is needed when `K ≥ 1`. When `K = 0` the slot stays
classical and O61 is a no-op for that spill (O43 remains free to fold
it into PUSH/POP).

### Patching decisions are not independent

The first patch is much cheaper than the second:

* **First patch** pays one spill (always, since patching always replaces
  the original spill instruction with the same-shape store to a code
  address). The reload-side savings for any single reload always exceed
  the difference between the patched reload `LXI`/`MVI` and a classical
  `LHLD`/`LDA`, so K = 1 is always profitable.
* **Each additional patch** pays a *full extra spill* (16cc `STA` or
  20cc `SHLD`) plus the patched `MVI`/`LXI` (8/12cc), in exchange for
  removing a classical reload (16cc `LDA` or 20cc `LHLD`) plus any
  routing MOVs/XCHGs.

For a single-source spill, the second patch pays only when the reload
target is something other than the spill's own register class:

| 2nd patch target | Extra spill | Patched reload | Classical reload removed | Δ (positive = win)         |
|------------------|-------------|----------------|---------------------------|----------------------------|
| A                | 16 (`STA`)  | 8 (`MVI A`)    | 16 (`LDA`)                | **−8** (lose, skip)        |
| HL               | 20 (`SHLD`) | 12 (`LXI HL`)  | 20 (`LHLD`)               | **−12** (lose, skip)       |
| r8 (non-A)       | 16 (`STA`)  | 8 (`MVI r`)    | 16+8 (`LDA;MOV r,A`)      | **0** (tied; worth it: avoids clobbering A) |
| DE               | 20 (`SHLD`) | 12 (`LXI DE`)  | 20+8 (`LHLD;XCHG`, +XCHG if HL live) | **+4 to +12** (win)  |
| BC               | 20 (`SHLD`) | 12 (`LXI BC`)  | 20+16 (`LHLD;MOV C,L;MOV B,H`)       | **+4** (win, plus avoids HL clobber) |

Patching a third site is never profitable: by the second patch the
remaining reloads are already reading from a 1B/2B imm slot via a plain
`LDA`/`LHLD`, exactly equivalent to the classical case but with no
extra spill.

**Hard cap: `K ≤ 2` per spill.**

**Never patch a 2nd `A`-target reload** (Δ = −8) **and never patch a
2nd `HL`-target reload** (Δ = −12). The classical `LDA` / `LHLD` of
those targets is *already* the minimum-cost reload shape — adding a
patch only buys an extra full spill. The chooser must explicitly skip
these candidates when picking the second patch, even if their
block-frequency × Δ would otherwise rank them. Both are valid first
patches when they are the *only* reload (K = 1, where the spill is
already paid).

### Multi-source spills (≥2 spills writing the same vreg)

When the same spill slot is written from two or more program points
(typical for vregs defined on diverging paths that join), every patch
must be performed *by every spill source*. The spill cost is multiplied
by the number of source points, which dominates the model.

**Hard cap: if a spill has > 1 source, `K ≤ 1`.**

### Which reload to patch first

When K = 1, all candidate reloads save at least the per-reload Δ from
the [Reloads table](#reloads-reload-site-only). To break ties, prefer:

1. **Reloads in inner loops / hot blocks.** Patched savings multiply by
   trip count; classical reloads outside the loop incur the savings
   only once.
2. **Reloads with the highest per-occurrence Δ** (BC live-HL > r8
   A-live > DE live-HL > BC HL-dead > …). The big wins live in routing
   pressure cases.
3. **Reloads that move the remaining spill/reload pair toward LIFO
   layout.** O43 (`SHLD/LHLD → PUSH/POP`) folds adjacent SHLD/LHLD
   pairs that share an address into a `PUSH H`/`POP H` (16cc + 12cc =
   28cc, one byte each, no BSS). If patching the chosen reload leaves
   the *remaining* spill/reload pair adjacent and HL-typed, O43 can
   then collapse it to PUSH/POP — a compounding win on top of O61.

**Prototype scoring.** For the first implementation, score each
candidate by `block_frequency(reload) × Δ(reload)` only and pick the
top-K. This captures the bulk of the win without a non-local search.
The LIFO-affinity heuristic (#3) is a second-order refinement that
should be layered on later, once measurements exist to justify the
extra chooser complexity.

### Worked example: `arr_sum` slot `__v6c_ss.arr_sum+2`

Spill source: HL, one source point (`SHLD` = 20cc). Reloads in program
order:

| # | Original sequence       | cc  | Target | Δ if patched |
|---|--------------------------|-----|--------|---------------|
| 1 | `LHLD +2`                | 20  | HL     | +8            |
| 2 | `XCHG; LHLD +2; XCHG`    | 28  | DE     | +16           |
| 3 | `LHLD +2`                | 20  | HL     | +8            |

Classical baseline: 1 SHLD (20) + 3 reloads (20 + 28 + 20) = **88 cc**.

* **K = 1, patch reload #2 (DE)**: 1×20 spill + 12 (LXI DE) + 20
  (LHLD from #2's imm bytes) + 20 (same) = **72 cc**, saves 16 cc.
* **K = 2, patch #2 plus one HL reload**: 2×20 spill + 12 + 12 + 20
  = **84 cc**, saves only 4 cc — because the second patch is HL
  (Δ = −12 from the second-patch table). **Forbidden by the
  "never patch a 2nd HL-target reload" rule.**
* **K = 3 (naïve all-patch)**: 3×20 + 3×12 = **96 cc**, regression.

K = 1 patching reload #2 wins, in agreement with all the rules above.

### Implementation implications

1. After RA, enumerate spill sources and reload sites per frame index.
2. Compute candidate Δ for each reload using the per-target reload
   table; sort descending.
3. Pick K with the rule above (`K ≤ 2` for single-source spills,
   `K ≤ 1` for multi-source). Among equal-Δ candidates, prefer hot
   blocks and reloads whose patching enables a downstream O43 fold.
4. Rewrite the K chosen reloads to `LXI`/`MVI` + `MO_PATCHED_IMM`,
   re-target the spill stores to `patched_site_n + offset`, and
   re-target any unpatched reload's address operand to one of the
   patched sites' imm bytes (a plain `LHLD`/`LDA`).
5. For K = 0 the slot stays classical; O43 stays free to fold it.

## Open Questions

* Can `SHLD` on I8080 write to a code-address that is about to be fetched
  without violating any pipeline assumption? On the real KR580VM80A there
  is no prefetch queue; the instruction fetched immediately after SHLD
  reads the bus freshly. **Expected safe**, but must be verified on real
  HW + emulator.
* Does the static stack alloc pass already guarantee "function runs to
  completion without concurrent re-entry"? Yes — that's exactly what the
  criteria enforce. So patched code bytes can't be observed mid-patch by
  another activation.
* Is there a case where the reload site is emitted inside a data region
  (e.g. jump-table)? No — reloads are always in the `.text` stream for
  this function.
* What about `V6C_LEA_FI` (address-of spill slot)? Not applicable —
  a patched reload has no addressable slot. If `&spillslot` is needed,
  the function falls back to the classical slot. RA does not emit
  `V6C_LEA_FI` against spill slots today, only against user allocas, so
  this is moot.
* How does this interact with **two-operand spills** (16-bit pair spilled
  via two 8-bit stores through A)? Each byte goes to its own imm field
  (`site+1` for lo, `site+2` for hi — both bytes of the same `LXI`).
  Still one reload instruction. Still a win.

## Recommended Scope of a Minimal Prototype

The cost model says the biggest per-reload wins come from `BC`-target
reloads (Δ = +24..+52 cc) and `r8`-non-A targets with A live
(Δ ≥ +44 cc). `HL` and `A` reloads have the *smallest* per-occurrence
Δ (+8 cc each) because their classical form is already a single
direct instruction. A staged rollout that maximises measurable signal
while keeping each step bounded:

1. **Stage 1 — plumbing on the `HL`-spill / `HL`-reload pair only.**
   Build the symbol-emission, `MO_PATCHED_IMM` flag, and AsmPrinter
   handling end-to-end on the simplest spill/reload shape (one SHLD
   spills, one LXI reload). Per-occurrence win is small (+8 cc), but
   the goal is to land the infrastructure with K = 1 hard-coded.
2. **Stage 2 — add the cost model** and extend to `DE` / `BC` reload
   targets. This is where the real cycles live (+12..+52 cc per
   reload). Implement the per-reload Δ table and the
   `block_frequency × Δ` chooser. Still K ≤ 1 in the chooser to
   defer the multi-patch logic.
3. **Stage 3 — enable K = 2** with the two hard rules:
   `K ≤ 2` for single-source spills, `K ≤ 1` for multi-source spills,
   and the chooser must skip `A`/`HL`-target candidates when picking
   the second patch.
4. **Stage 4 — extend reload-side handling to individual `B..L` r8
   targets** (the `r8 A-live` case, Δ ≥ +44 cc).

At every stage:
* Gate behind `-mv6c-spill-patched-reload` for A/B testing.
* Measure cycle count and code size, and the golden suite, focusing
  on the 3–5 functions with the highest spill traffic.
* Verify that disabling the flag yields byte-identical output to
  baseline.

## Summary

The optimization trades classical BSS spill slots for self-modifying
imm-field slots. Under the conditions static stack already guarantees,
it is safe and requires **no** RA changes.

Key rules from the cost model:
* `K ≤ 2` patched reloads per single-source spill.
* `K ≤ 1` patched reload per multi-source spill.
* Never use an `A`- or `HL`-target reload as the *second* patch.
* Bias the first patch toward inner-loop reloads with the highest Δ
  (`block_frequency × Δ`).

Savings: **+8..+52+ cc per patched reload** (and 0..+4 B per reload
site). The single invasive change in the rest of the compiler is
teaching constant-tracking passes to treat patched `LXI`/`MVI`
immediates as opaque.