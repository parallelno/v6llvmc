# V6C_LOAD16_P Redesign

## Status

Proposed.

## Background

`V6C_LOAD16_P` is the generic 16-bit load-through-pointer pseudo:

```tablegen
let mayLoad = 1 in
def V6C_LOAD16_P : V6CPseudo<(outs GR16:$dst), (ins GR16:$addr),
    "# LOAD16P $dst, ($addr)",
    [(set i16:$dst, (load i16:$addr))]>;
```

It declares **no `Defs`**. The td comment claims this is safe because the
post-RA expansion preserves `HL` and `A` in every shape (XCHG round-trip when
`addr=DE`, PUSH/POP when `addr=BC`).

The actual post-RA expansion in `V6CInstrInfo.cpp` walks nine `(addr, dst)`
shape combinations. The contract is broken in several of them.

## Problem

### Per-shape behaviour today

| addr | dst       | emitted sequence                                 | actually clobbered            |
|------|-----------|--------------------------------------------------|-------------------------------|
| HL   | HL        | `MOV A,M; INX H; MOV H,M; MOV L,A`               | **A**, HL (HL covered by `$dst`) |
| HL   | BC/DE     | `MOV lo,M; INX H; MOV hi,M`                      | **HL (= orig + 1)**           |
| DE   | BC        | `XCHG; MOV C,M; INX H; MOV B,M; XCHG`            | none external — OK            |
| DE   | DE        | `XCHG; MOV E,M; INX H; MOV D,M; XCHG`            | **wrong value in HL/DE** (see bug 3) |
| DE   | HL        | `XCHG; MOV A,M; INX H; MOV H,M; MOV L,A; XCHG`   | **wrong value in HL/DE** (see bug 3); **A** |
| BC   | HL        | `[PUSH H]; MOV H,B; MOV L,C; MOV A,M; INX H; MOV H,M; MOV L,A; [POP H]` | **A**; HL preserved iff `!HLDead` |
| BC   | BC/DE     | `[PUSH H]; MOV H,B; MOV L,C; MOV lo,M; INX H; MOV hi,M; [POP H]` | HL preserved iff `!HLDead`; otherwise HL = orig_BC + 1 |

`HLDead` is computed via `isRegDeadAtMI`: when HL is dead after the pseudo,
the PUSH/POP is skipped to save bytes/cycles. In that case HL is genuinely
clobbered but the pseudo still claims it isn't.

### Concrete correctness bugs

1. **`addr=HL, dst=HL` silently corrupts `A`.**
   The expansion uses `A` as a low-byte temporary (necessary because
   `INX H` may carry into `H` before the high byte is read). `A` is not
   in `Defs`, so RA believes a value in `A` survives this load.

2. **`addr=HL, dst∈{BC,DE}` lies about `HL`.**
   The expansion does `INX H` directly on the address register. After
   the pseudo, `HL = original_HL + 1`. RA is told `HL` is unchanged and
   any later use of the original pointer reads `pointer + 1`.

3. **`addr=DE, dst∈{HL,DE}` produces wrong values in HL and DE.**
   The `XCHG; load; XCHG` idiom only preserves `HL` when the inner load
   leaves `HL` unchanged. With `dst=DE` the inner load deposits the
   loaded value into DE (= old HL after first XCHG), then the trailing
   XCHG swaps that value back into HL while pushing the supposed-to-be-
   preserved old HL value out into DE — both registers end up wrong.
   With `dst=HL` the inner load deposits the result in HL via the
   A-temp path, and the trailing XCHG moves it into DE while HL gets the
   unrelated DE input.

   Observed in `temp\asm_inline\custom_cc.s`:

   ```asm
   ;--- V6C_ADD16 ---       HL = sum
   DAD     B
   ;--- V6C_LOAD16_P ---    addr=DE, dst=DE
   XCHG
   MOV     E, M
   INX     H
   MOV     D, M
   XCHG                     ; HL = loaded (wrong), DE = ptr+1 (wrong)
   ;--- V6C_ADD16 ---
   DAD     D                ; HL = loaded + (ptr+1)  -- WRONG
   ```

4. **`addr=BC` with `HLDead` skips PUSH/POP and leaks `HL = orig_BC + 1`.**
   Benign in the common case where the dead flag is honest, but fragile:
   any liveness recompute that re-reads the pseudo's declared `Defs` will
   not see the HL clobber.

5. **`addr=BC, dst=HL` always clobbers `A`.**
   Same as bug 1 — uses A-temp for the dst-overlap-HL case and does not
   declare `A`.

### Why a single blanket `Defs` is not the answer

Adding `Defs = [HL, A, FLAGS]` to the single pseudo would close the
correctness holes but is over-conservative for the most common shape
`addr=HL, dst∈{BC,DE}` where the expansion is just
`MOV r,M; INX H; MOV r,M`:

- `A` is genuinely preserved. Marking it clobbered raises pressure on the
  1-element `Acc` pressure class and breaks A-keeping peepholes around
  pointer loads.
- `FLAGS` is not written at all. `INX rp` does not set flags on 8080;
  only `DAD` and the ALU ops do. `FLAGS` should not appear in any
  honest `Defs` for this family.
- `HL` *is* clobbered in this shape, so listing it is correct. But the
  `addr=DE, dst=BC` shape preserves HL via the XCHG round-trip, and a
  blanket `Defs=[HL]` would lie in the conservative direction there.

The single-pseudo model conflates shapes whose honest clobber sets are
different. Any choice for `Defs` is wrong for some shape.

## Solution

Split `V6C_LOAD16_P` into per-shape pseudos that each declare honest,
minimal `Defs`. Selection happens in isel / pre-RA based on operand
register classes; post-RA expansion is the same code paths as today,
minus the bug fixes.

### Proposed shape pseudos

| Pseudo                  | addr class | dst class      | expansion shape                                       | honest Defs |
|-------------------------|------------|----------------|-------------------------------------------------------|-------------|
| `V6C_LOAD16_P_HL_RP`    | GR16Ptr    | GR16Idx (BC/DE)| `MOV lo,M; INX H; MOV hi,M`                           | `HL`        |
| `V6C_LOAD16_P_HL_HL`    | GR16Ptr    | GR16Ptr (HL)   | `MOV A,M; INX H; MOV H,M; MOV L,A`                    | `A` (HL covered by `$dst`) |
| `V6C_LOAD16_P_DE_RP`    | DE-only    | GR16Idx        | `XCHG; MOV lo,M; INX H; MOV hi,M; XCHG`               | (none external) |
| `V6C_LOAD16_P_DE_HL`    | DE-only    | GR16Ptr        | `XCHG; MOV A,M; INX H; MOV H,M; MOV L,A`              | `DE`, `A` (HL covered by `$dst`) |
| `V6C_LOAD16_P_BC_RP`    | BC-only    | GR16Idx        | `[PUSH H]; MOV H,B; MOV L,C; MOV lo,M; INX H; MOV hi,M; [POP H]` | `HL` if `HLDead`, else none external; `A` not touched |
| `V6C_LOAD16_P_BC_HL`    | BC-only    | GR16Ptr        | `[PUSH H]; MOV H,B; MOV L,C; MOV A,M; INX H; MOV H,M; MOV L,A; [POP H]` | `A`, plus `HL` if `HLDead` (HL is `$dst`) |

Notes:

- The `DE_RP` shape genuinely preserves both `HL` and `DE` (both come
  back via the trailing XCHG). No external `Defs` needed.
- The `DE_HL` shape drops the trailing XCHG (the loaded value owns HL).
  After expansion, `DE` holds the pre-existing HL value — i.e. `DE` is
  clobbered. `Defs = [DE, A]`.
- The `DE_DE` shape (currently buggy) is simply not in the table. With
  `addr=DE` constrained to a DE-only operand class and `dst` operand
  excluded from DE, the `addr=DE, dst=DE` overlap cannot occur. If RA
  must place both in DE, the copy is forced *outside* the pseudo, where
  it is honest and visible.

  Alternative: keep a `V6C_LOAD16_P_DE_DE` shape with the corrected
  expansion `XCHG; MOV A,M; INX H; MOV H,M; MOV L,A; XCHG` (load into
  HL via A-temp, then trailing XCHG places loaded into DE and old HL
  back into HL). `Defs = [A]` only.
- `BC_*` shapes keep the existing HLDead optimization. The `Defs` set is
  conditional on the optimization decision, which TableGen cannot
  express directly. Either:
  - Always declare `Defs = [HL]` on `BC_*` pseudos (slightly
    pessimistic when PUSH/POP fires), or
  - Have two variants `_BC_*_PRESERVE_HL` and `_BC_*_KILL_HL`, and pick
    between them post-RA based on liveness, before the final
    expansion. This is the cleaner model but adds machinery.

### Selection

Two viable strategies:

1. **Pre-RA shape selection in isel.** Constrain the operand register
   classes on each shape pseudo (GR16Ptr / GR16Idx / DE-only /
   BC-only). Isel picks the shape whose operand classes match the
   incoming addr/dst regclasses. RA then has no choice but to allocate
   into the right physreg per shape.

   Drawback: forces RA's hand earlier than necessary; loses the freedom
   to migrate between shapes based on global pressure.

2. **One pre-RA pseudo, post-RA shape dispatch with honest Defs.**
   Keep a single pre-RA `V6C_LOAD16_P` for isel/scheduling simplicity,
   but switch to one of the shape pseudos *immediately after RA*
   (before any pass that consumes liveness) based on the chosen
   physregs. Each shape pseudo carries its honest `Defs`, and the
   liveness recomputation pass that runs after expansion sees
   correct information.

   This matches the current code's structure (single td pseudo, big
   switch in `expandPostRAPseudos`) and only needs the dispatch to emit
   per-shape pseudo opcodes instead of inlining the expansion directly.

   Drawback: the pre-RA pseudo still has to declare *some* `Defs`
   covering the union of the worst-case clobbers of all shapes RA
   might choose, which is back to over-conservative for pre-RA passes
   that read it (e.g. machine-CSE, machine-LICM). However those passes
   tolerate over-conservative clobbers — they just miss optimizations,
   they don't miscompile.

Recommendation: start with **strategy 2**. The pre-RA `V6C_LOAD16_P` keeps
its current isel pattern but is annotated `Defs = [HL, A]` (the union of
worst-case clobbers across the shape table; `FLAGS` excluded because no
shape sets flags). Post-RA, dispatch into one of the per-shape pseudos
with minimal honest `Defs`. Liveness-sensitive passes after expansion
(register scavenging, late peepholes, cleanup) see precise information.

After this is stable, evaluate strategy 1 for additional pre-RA accuracy
on hot paths.

## Correctness Conditions

- `addr=HL, dst=HL`: must use A-temp for low byte; declare `A` clobbered.
- `addr=HL, dst∈{BC,DE}`: declare `HL` clobbered (`HL` becomes `orig+1`).
- `addr=DE, dst=BC`: XCHG round-trip preserves HL and DE; no external
  clobbers beyond `$dst`.
- `addr=DE, dst=HL`: drop trailing XCHG; declare `DE`, `A` clobbered.
- `addr=DE, dst=DE`: forbidden by operand class, OR use the corrected
  expansion that loads via A-temp and lets the trailing XCHG place the
  result into DE; declare `A` clobbered.
- `addr=BC, dst=*`: PUSH/POP path preserves HL when `!HLDead`; in the
  HL-dead path HL is clobbered and the pseudo's `Defs` must reflect
  that. `A` is clobbered iff `dst=HL`.
- No shape sets `FLAGS`.

## Expected Effects

- Bug 1 (A corruption with `addr=HL, dst=HL`): fixed by honest `Defs=[A]`
  on `_HL_HL`. RA will spill or relocate any live `A` across the load.
- Bug 2 (HL corruption with `addr=HL, dst∈{BC,DE}`): fixed by honest
  `Defs=[HL]`. RA will copy the original pointer if needed elsewhere.
- Bug 3 (XCHG-pair miscompile with `addr=DE, dst∈{HL,DE}`): fixed by
  forbidding the overlap or rewriting the expansion. The buggy code
  pattern observed in `custom_cc.s` becomes well-defined.
- Bug 4 (HLDead leak): folded into honest per-shape `Defs`.
- The common, fast `addr=HL, dst=BC/DE` shape keeps `A` and `FLAGS`
  preserved across the load, unblocking the existing A-keeping and
  flag-keeping peepholes that today are stymied by even an
  imprecise blanket `Defs`.

## Tests

- Add a lit test that exercises each of the seven shape pseudos and
  verifies the emitted asm matches the table above.
- Add a regression test for bug 3 derived from the `custom_cc.c`
  reproducer: assert that a sequence
  `DAD B; <16-bit load via DE pointer>; DAD D` computes
  `sum + loaded`, not `loaded + (ptr+1)`.
- Add a regression test for bug 1: a value live in `A` across a
  `addr=HL, dst=HL` load is preserved (RA must spill / route).
- Add a regression test for bug 2: a value live in the original
  pointer (in HL) across a `addr=HL, dst=BC` load is preserved.
- Keep the `custom_cc.c` end-to-end runtime test as a guard.

## Risk

Medium. Splitting the pseudo touches isel patterns, post-RA expansion,
and the operand class system. The bugs being fixed are real
miscompiles, so the upside is significant; the main risk is
shape-selection coverage gaps (some `(addr, dst)` regclass combination
not mapped to any shape pseudo).

## Dependencies

- Existing `V6C_LOAD16_P` post-RA expansion code paths.
- O42 `isRegDeadAtMI` helper for the BC PUSH/POP optimization.
- Operand register class definitions in `V6CRegisterInfo.td`
  (GR16Ptr, GR16Idx).

## Out of Scope

- `V6C_STORE16_P` redesign — covered separately in
  `V6C_STORE16_P_redesign.md`. The two redesigns are structurally
  parallel and should land together if practical.
- `V6C_LOAD16_G` / `V6C_STORE16_G` — separate pseudos with the same
  shape-conflation pattern; consider a follow-up after this lands.
