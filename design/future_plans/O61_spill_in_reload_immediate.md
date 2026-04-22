# O60: Spill Into the Reload's Immediate Operand

## Example

A function exercising spill/reload traffic under register pressure:

```c
unsigned char arr_sum(unsigned char* arr, unsigned char n) {
    unsigned char sum = 0;
    for (unsigned char i = 0; i < n; ++i) {
        sum += arr[i];
        unsigned char tmp2 = (int)(arr) >> 8;
        unsigned char tmp = tmp2 & 0xFF + n & arr[i-1];
    }
    return sum;
}
```

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
