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
         LXI  HL, 0x0000           ; imm16 was patched     10cc
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
| HL   | `LXI  HL, nn`      | `0x21`      | site+1    | 10cc |
| DE   | `LXI  DE, nn`      | `0x11`      | site+1    | 10cc |
| BC   | `LXI  BC, nn`      | `0x01`      | site+1    | 10cc |
| A    | `MVI  A,  n`       | `0x3E`      | site+1    | 7cc  |
| B    | `MVI  B,  n`       | `0x06`      | site+1    | 7cc  |
| C    | `MVI  C,  n`       | `0x0E`      | site+1    | 7cc  |
| D    | `MVI  D,  n`       | `0x16`      | site+1    | 7cc  |
| E    | `MVI  E,  n`       | `0x1E`      | site+1    | 7cc  |
| H    | `MVI  H,  n`       | `0x26`      | site+1    | 7cc  |
| L    | `MVI  L,  n`       | `0x2E`      | site+1    | 7cc  |

## Cycle/Size Comparison vs Current Spilling

Baseline assumes static stack (SHLD/LHLD/STA/LDA are available). "Current"
figures taken from the data slot path; size counts only the reload section.

### Reloads (pure win — reload side only)

| Target | Current reload (best case)                         | Cost  | Bytes | Patched reload             | Cost  | Bytes | Delta/reload |
|--------|-----------------------------------------------------|-------|-------|-----------------------------|-------|-------|--------------|
| HL     | `LHLD addr`                                         | 20cc  | 3     | `LXI HL,imm`                | 10cc  | 3     | -10cc, 0B   |
| DE     | `LHLD addr; XCHG`                                   | 24cc  | 4     | `LXI DE,imm`                | 10cc  | 3     | -14cc, -1B  |
| BC     | `LHLD addr; MOV C,L; MOV B,H`                       | 30cc  | 5     | `LXI BC,imm`                | 10cc  | 3     | -20cc, -2B  |
| A      | `LDA addr`                                          | 13cc  | 3     | `MVI A,imm`                 | 7cc   | 2     | -6cc, -1B   |
| B..L   | `LDA addr; MOV r,A` (or routed via HL reload)       | 18cc+ | 4+    | `MVI r,imm`                 | 7cc   | 2     | -11cc, -2B  |

For non-accumulator 8-bit regs and non-HL 16-bit pairs the win is large —
precisely the cases where the current backend routes through HL/A and burns
cycles.

### Spill side

Each spill does *exactly* the same absolute-address store it does today, just
targeting a code address instead of a BSS address:

| Reg | Spill instruction | Cost |
|-----|-------------------|------|
| HL  | `SHLD site+1`     | 20cc |
| DE  | `XCHG; SHLD site+1; XCHG` (or drop second XCHG if HL dead) | 24–28cc |
| BC  | (same options as today: through HL, through A, or push/pop) | 36–48cc |
| A   | `STA site+1`      | 16cc |
| B..L| (same options as today: through A) | 19–32cc |

=> **spill cost is unchanged** (except for the target address).
The optimization is a pure **reload-side** improvement, but it pays for itself
as soon as any spill has ≥1 reload, which is the overwhelming common case.

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
5. **No shared reload site.** Each reload instruction must be a unique slot
   — so if the same vreg is reloaded at two sites, they are *two* patched
   sites and the spill must write *both* (double the spill cost on the
   second side). RA only emits one reload per use in the common case, so
   this is rare; a cost model should treat N reloads as N spill-writes.

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
2. The spill/reload pair share the same frame index and there is **exactly
   one reload** for this spill (or the cost model decides multi-reload is
   still a win).
3. The reload site's register is a whole register pair (LXI) or a single
   8-bit reg (MVI) — i.e. the reload instruction itself admits an
   immediate operand of the right width.

Rewrite:
* Allocate a private `MCSymbol` at the reload site (an `.Ltmp` label).
* Replace the reload pseudo with `LXI r16, 0` or `MVI r8, 0`
  whose immediate carries the target flag `MO_PATCHED_IMM`.
* Replace the spill pseudo with `SHLD Sym+1` or `STA Sym+1`
  (same spill sequence shape as today, just different address operand).
* Emit the `.Ltmp` label immediately before the reload instruction in
  the asm/object stream so `Sym+1` resolves to the imm byte.

No change to RA, no change to pseudo set, no new register class, no new
verifier property. This is the cheapest-to-implement entry of all the
spilling improvements discussed above.

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

## Cost Model (Sketch)

A spill/reload pair for register `R` costs (in cycles):

```
cost_classical(R, N_reloads) = spill_cost(R) + N_reloads * reload_cost_slot(R)
cost_patched  (R, N_reloads) = N_reloads * spill_cost(R) + N_reloads * reload_cost_imm(R)
```

Patched wins when:
```
N_reloads * (spill_cost(R) + reload_cost_imm(R))
  <  spill_cost(R) + N_reloads * reload_cost_slot(R)
```
For `N_reloads = 1` (the common case) it always wins: `reload_cost_imm`
is strictly less than `reload_cost_slot` for every register, and the
spill cost is identical.

For `N_reloads >= 2`, the spill is paid per reload site and the break-even
depends on the register. For HL (`spill=20, reload_imm=10, reload_slot=20`)
patched is never worse: `2*(20+10)=60` vs `20+2*20=60`, tied at
`N_reloads=2`. For A (`spill=16, reload_imm=7, reload_slot=13`) patched
wins up through `N_reloads=2` (`2*(16+7)=46` vs `16+2*13=42` — classical
wins at N=2!). So the cost model needs to actually check.

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

1. Limit to `HL`, `A` first — the two "clean" cases (SHLD and STA, no
   routing through other regs on the spill side, no cost-model risk at
   `N_reloads=2`).
2. Add `MO_PATCHED_IMM` target operand flag + AsmPrinter handling so
   `LoadImmCombine` skips these instructions.
3. Gate behind `-mv6c-spill-patched-reload` for A/B testing.
4. Measure against `tests/features/20/` and the golden suite; check
   codesize and cycle counts for the 3–5 functions with the highest spill
   traffic.
5. Extend to `DE`, `BC`, individual `B..L` once cost model is validated.

## Summary

The optimization trades classical BSS spill slots for self-modifying
imm-field slots. Under the conditions static stack already guarantees,
it is safe, requires **no** RA changes, and saves **10–20 cc per reload**
(and 1–2 B per reload site). The single invasive change in the rest of
the compiler is teaching constant-tracking passes to treat patched
`LXI`/`MVI` immediates as opaque.

---

## Revised Cost Model (V6C Cycles, Hybrid-K Strategy)

The earlier tables in this document use a mix of 8080 base timings
(`LXI=10`, `MVI=7`, `MOV r,r=5`) and V6C timings (`SHLD=20`,
`LDA=16`). On real V6C every instruction is bus-stretched; the correct
figures come from
[V6CInstructionTimings.md](../../docs/V6CInstructionTimings.md) and
[Vector_06c_instruction_timings.md](../../docs/Vector_06c_instruction_timings.md):

| Instruction        | V6C cc |
|--------------------|--------|
| `MOV r,r`          |  8     |
| `MOV r,M` / `MOV M,r` | 8   |
| `MVI r,d8`         |  8     |
| `LXI rp,d16`       | 12     |
| `LDA a16` / `STA a16` | 16  |
| `LHLD a16` / `SHLD a16` | 20 |
| `XCHG`             |  4     |
| `PUSH rp`          | 16     |
| `POP rp`           | 12     |

The "pure win — 10cc reload on HL" claim in the reload-comparison table
becomes **12cc** on V6C, and every other row shifts correspondingly.
The qualitative conclusions survive, but the break-even math changes.

### Per-target reload cost

| Target | Classical best case                     | cc  | Patched       | cc  | Savings/reload |
|--------|------------------------------------------|-----|---------------|-----|----------------|
| HL     | `LHLD addr`                              | 20  | `LXI HL,imm`  | 12  | 8              |
| DE (HL dead)  | `LHLD addr; XCHG`                 | 24  | `LXI DE,imm`  | 12  | 12             |
| DE (HL live)  | `XCHG; LHLD addr; XCHG`           | 28  | `LXI DE,imm`  | 12  | **16**         |
| BC (HL dead)  | `LHLD addr; MOV C,L; MOV B,H`     | 36  | `LXI BC,imm`  | 12  | 24             |
| BC (HL live, A dead) | `LDA;STA;LDA;STA` (via A × 2) | 64  | `LXI BC,imm`  | 12  | **52**         |
| BC (HL live, A live) | `PUSH H;LHLD;MOV;MOV;POP H`    | 64  | `LXI BC,imm`  | 12  | **52**         |
| A      | `LDA addr`                               | 16  | `MVI A,imm`   |  8  | 8              |
| r8 (A dead) | `LDA addr; MOV r,A`                 | 24  | `MVI r,imm`   |  8  | **16**         |
| r8 (A live, not A source) | through saved A            | 52+ | `MVI r,imm`   |  8  | **44+**        |

### Per-source spill cost (= write per patched site)

| Source | Sequence                         | cc  |
|--------|----------------------------------|-----|
| HL     | `SHLD site+1`                    | 20  |
| DE (HL dead) | `XCHG; SHLD site+1`        | 24  |
| DE (HL live) | `XCHG; SHLD site+1; XCHG`  | 28  |
| A      | `STA site+1`                     | 16  |
| r8 (non-A) | `MOV A,r; STA site+1`        | 24  |

### Hybrid-K Strategy

The original sketch implicitly assumed every reload either becomes a
patched `LXI`/`MVI` (K = N) or stays classical (K = 0). That's a
false dichotomy. For `N_reloads = N` we can pick any K ∈ {1..N} reload
sites to patch; the remaining `N − K` reloads read from the imm-field
bytes of *one of the already-patched sites* with a normal `LHLD`/`LDA`
(the patched site is itself a valid 2-byte / 1-byte slot). No separate
BSS slot is needed.

Cost:
```
cost_hybrid(K) =   K * spill_cost
                 + Σ_{i ∈ patched}   reload_imm_cost(i)
                 + Σ_{j ∉ patched}   reload_slot_cost(j)
```

Greedy rule: sort reloads by `reload_slot_cost − reload_imm_cost`
(descending) and include the *k*-th reload in the patched set iff its
marginal savings exceed `spill_cost`. For a single-source spill:

| Spill src | Spill cc | Patch a 2nd site when reload saves > | Typical reload targets that qualify |
|-----------|----------|--------------------------------------|--------------------------------------|
| HL (20cc) | 20       | 20 cc per reload                     | BC-reload (24/52 savings) |
| A  (16cc) | 16       | 16 cc per reload                     | r8-reload with A live (44+ savings) |
| DE live-HL (28cc) | 28 | 28 cc per reload                   | BC-reload HL-live (52 savings) |

**Practical takeaway:** patching *exactly one* reload (K = 1) is
almost always the optimum. Additional patches are profitable only when
the added reload targets `BC` under pressure, or when the spill source
is cheap (`A`) and the reload target routes through a saved accumulator.
A hard cap of K ≤ 2 loses almost nothing vs. the optimal greedy for
realistic register mixes.

### Applied to `arr_sum` slot `__v6c_ss.arr_sum+2`

Spill source: HL (`SHLD` = 20cc). Reloads, in program order:

| # | Original sequence            | cc  | Target | Savings if patched |
|---|-------------------------------|-----|--------|---------------------|
| 1 | `LHLD +2`                     | 20  | HL     | 8                   |
| 2 | `XCHG; LHLD +2; XCHG`         | 28  | DE (HL live) | **16**         |
| 3 | `LHLD +2`                     | 20  | HL     | 8                   |

Current total (O43 disabled, no O61): 20 + 20 + 28 + 20 = **88 cc**.

**Option A — patch all three** (naïve O61):
  spill 3×20 = 60, reloads 12+12+12 = 36 → **96 cc** (−8 cc regression)

**Option B — patch best two** (K = 2, cap rule):
  spill 2×20 = 40, reloads 12 (LXI DE) + 12 (LXI HL) + 20 (LHLD from a patched site's imm bytes) = 44 → **84 cc** (+4 cc saved)

**Option C — patch only the DE reload** (K = 1, greedy optimum):
  spill 1×20 = 20, reloads 20 (LHLD from DE-reload imm bytes) + 12 (LXI DE) + 20 (LHLD from same bytes) = 52 → **72 cc** (+16 cc saved, 18 % win)

**Option D — patch both HL reloads, leave DE classical**:
  spill 2×20 = 40, reloads 12 + 28 (DE kept) + 12 = 52 → **92 cc** (−4 cc regression)

### Max achievable on the full loop body

The inner loop `LBB0_4` of `arr_sum` spills/reloads four distinct slots.
Applying greedy K = 1 per slot with V6C-accurate timings:

| Slot                    | Classical total | O61 K=1 total | Saved |
|-------------------------|-----------------|----------------|-------|
| `+0` (BC: count/phase)  | SHLD+through-HL spill (40) + 2×reload (LHLD;MOV;MOV = 2×36)= 112 | 40 (keep classical SHLD for one write) + LXI BC (12) + LHLD site+1;MOV;MOV (36) = 88 | **24** |
| `+2` (HL/DE pointer)    | 88 (above)      | 72             | 16    |
| `+5` (16-bit constant)  | XCHG;SHLD;XCHG (28) + 2×reload with HL-live (2×28) = 84 | 28 + LXI DE (12) + LHLD;XCHG (24) = 64 | 20 |
| `+7` / `+4` (i8 tmp)    | 2×STA (32) + 3×LDA (48) = 80       | STA (16) + MVI r (8) + 2×LDA (32) = 56 | 24 |

Approximate inner-loop savings ≈ **16 + 24 + 20 + 24 = 84 cc per
iteration**, before counting additional follow-on wins where an O61
reload eliminates an XCHG pair the peephole can then cancel further.

### Implementation implications

1. The post-RA rewrite needs to enumerate *all* reloads of each spill
   and compute the greedy K for each slot using the V6C cost model
   (reuses [O11/O26 cost infra](O26_cost_model_infra.md)).
2. Choose exactly K reload sites to patch; the remaining reloads keep
   their original shape but retarget their memory operand from the
   classical BSS slot to `patched_site_n + offset` (where `n` is one
   of the patched sites — any one works, but picking the one closest
   in the linker order keeps the relocation local).
3. Mark every patched `LXI`/`MVI` with `MO_PATCHED_IMM` so the value
   trackers (`LoadImmCombine`, `AccumulatorPlanning`) treat them as
   opaque.
4. For K = 0 (no reload profitable to patch) the slot stays classical
   — O61 becomes a no-op for that slot, and O43 (SHLD/LHLD→PUSH/POP)
   remains free to fold it.
