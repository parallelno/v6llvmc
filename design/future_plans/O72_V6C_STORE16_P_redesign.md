# V6C_STORE16_P Design Redesign

## Problem
. V6C_STORE16_P — also overconservative AND has a real bug
Declared Defs = [HL, A]. Per shape:

val	addr	expansion	actually clobbered
HL	HL	MOV A,H; MOV M,L; INX H; MOV M,A	A, HL (HL = orig+1)
HL	DE	[PUSH D]; MOV A,L; STAX D; INX D; MOV A,H; STAX D; [POP D]	A; DE preserved by PUSH/POP only when not dead — otherwise DE = orig+1, but pseudo claims DE preserved
HL	BC	symmetric to DE	A; BC = orig+1 if BC was dead
≠HL	HL	MOV M,lo; INX H; MOV M,hi	HL (= orig+1); A not touched
≠HL	≠HL	MOV H,addrHi; MOV L,addrLo; MOV M,lo; INX H; MOV M,hi	HL clobbered (consistent with Defs); A not touched
Issues:

Overconservative for val≠HL & addr≠HL: declares A clobbered, but A is genuinely preserved.
Overconservative for val≠HL & addr=HL: same — A preserved but declared clobbered.
Underconservative / bug for val=HL, addr=DE (or BC) when DE/BC is dead at the pseudo: the "skip PUSH/POP when dead" optimization leaves DE/BC holding orig_addr + 1 after the pseudo, but Defs does not include DE/BC. That's fine if "dead" really means dead — isRegDeadAtMI checks the kill flag/liveness at this MI, so the value is unused downstream and the lie is benign. However it's a fragile pattern: any later pass that reads liveness after this expansion sees an INX D that doesn't appear in any Defs, with D/E not redefined. As long as expansion is expandPostRAPseudos and no liveness recompute happens that re-reads the original pseudo, it works. Worth reviewing.
val=HL, addr=HL correctly clobbers HL (already in Defs) and A (already in Defs). OK.
The INX rp for rp=DE/BC does not bump HL, so the Defs=[HL] on those shapes is wrong-direction over-conservative (HL is preserved when val=HL, addr∈{DE,BC} until the optional PUSH/POP path — actually HL is genuinely preserved there, so Defs=[HL] is a lie in the over-conservative direction).
So V6C_STORE16_P has the same structural problem: one pseudo, many shapes, single coarse Defs set that is simultaneously too tight (under-declares BC/DE clobber when the dead-optimization fires) and too loose (declares A and HL clobbered in shapes where they're preserved).

## Full picture of `V6C_STORE16_P` today

### TableGen declaration

```tablegen
let mayStore = 1, Defs = [HL, A] in
def V6C_STORE16_P : V6CPseudo<(outs), (ins GR16:$val, GR16:$addr),
    "# STORE16P $val, ($addr)",
    [(store i16:$val, i16:$addr)]>;
```

- Two GR16 inputs: `$val`, `$addr`. Each is independently in `{HL, BC, DE}`,
  giving 9 shapes total.
- `Defs = [HL, A]` is a coarse blanket that simultaneously over-declares
  (most val≠HL shapes never touch `A`; addr=HL with val≠HL doesn't
  touch `A`) and under-declares (the val=HL, addr∈{BC,DE} shapes use
  the O42 "DE/BC dead → skip PUSH/POP" path, which leaves the address
  pair = `orig+1`, while `Defs` lists neither BC nor DE).
- No `FLAGS` in `Defs`; none of the shapes touch flags, which is correct.

### Current expander structure (`V6CInstrInfo.cpp::expandPostRAPseudo`)

```
if val == HL:
    if addr == HL:        MOV A,H; MOV M,L; INX H; MOV M,A
    elif addr == DE:      [PUSH D];  MOV A,L; STAX D; INX D; MOV A,H; STAX D; [POP D]
    elif addr == BC:      [PUSH B];  MOV A,L; STAX B; INX B; MOV A,H; STAX B; [POP B]
                          (PUSH/POP elided when addr-pair is dead at MI — O42)
else  # val ∈ {BC, DE}
    if addr != HL:        MOV H,addrHi; MOV L,addrLo
    MOV M,valLo; INX H; MOV M,valHi
```

### Per-shape expansion table (current behaviour vs. truthful clobbers)

| #  | val | addr | current expansion                                                       | declared `Defs` | actual clobbers                                          | over / under-decl |
|----|-----|------|-------------------------------------------------------------------------|------------------|-----------------------------------------------------------|-------------------|
| 1  | HL  | HL   | `MOV A,H; MOV M,L; INX H; MOV M,A`                                      | HL, A            | A; HL = orig+1                                            | exact             |
| 2  | HL  | DE   | `[PUSH D]; MOV A,L; STAX D; INX D; MOV A,H; STAX D; [POP D]`            | HL, A            | A; HL preserved; DE preserved iff PUSH/POP emitted, else DE = orig+1 | over: HL; under: DE when PUSH/POP elided |
| 3  | HL  | BC   | `[PUSH B]; MOV A,L; STAX B; INX B; MOV A,H; STAX B; [POP B]`            | HL, A            | A; HL preserved; BC preserved iff PUSH/POP emitted, else BC = orig+1 | over: HL; under: BC when PUSH/POP elided |
| 4  | BC  | HL   | `MOV M,C; INX H; MOV M,B`                                               | HL, A            | HL = orig+1; A preserved                                  | over: A           |
| 5  | DE  | HL   | `MOV M,E; INX H; MOV M,D`                                               | HL, A            | HL = orig+1; A preserved                                  | over: A           |
| 6  | BC  | BC   | `MOV H,B; MOV L,C; MOV M,C; INX H; MOV M,B`                             | HL, A            | HL fully overwritten; A preserved                         | over: A           |
| 7  | BC  | DE   | `MOV H,D; MOV L,E; MOV M,C; INX H; MOV M,B`                             | HL, A            | HL fully overwritten; A preserved                         | over: A           |
| 8  | DE  | BC   | `MOV H,B; MOV L,C; MOV M,E; INX H; MOV M,D`                             | HL, A            | HL fully overwritten; A preserved                         | over: A           |
| 9  | DE  | DE   | `MOV H,D; MOV L,E; MOV M,E; INX H; MOV M,D`                             | HL, A            | HL fully overwritten; A preserved                         | over: A           |

Notes:
- Cases 4–9 never write `A`, but the blanket `Defs=[HL,A]` forces RA to
  treat `A` as clobbered across **every** 16-bit pointer store. On a
  1-element pressure class this is the single most expensive part of
  the current declaration.
- Cases 6–9 fully overwrite HL (both bytes via `MOV H,addrHi; MOV
  L,addrLo`), so DCX-recovery is impossible — these are the only
  cases where HL truly cannot be cheaply recovered without
  PUSH/POP HL.
- Cases 4–5 mutate HL only via `INX H`, so a single `DCX H` recovers
  the original pointer cheaply (1B / 5cc).
- Cases 2–3 mutate DE/BC only via `INX D`/`INX B`, so a single
  `DCX D`/`DCX B` recovers the address pair cheaply — strictly
  better than the current `PUSH/POP` (1B/5cc vs 2B/22–23cc) and
  it eliminates the dead-optimization correctness wart entirely
  (no more "skip PUSH/POP when dead and silently leak orig+1").
- Cases 1, 2, 3 use `A` as the high-byte staging register. In case 1
  this is just to get past the `INX H` carry; any dead GR8 works
  (mirrors O71 case 1). In cases 2–3 `A` is **mandatory**: `STAX rp`
  only accepts `A` as the source register. There is no GR8-spare
  substitution available for cases 2–3.

### Proposed truthful clobber model (mirror of O71)

Drop `Defs` from the pseudo entirely; have the expander emit
preservation in cheap-first order:

| Case | val | addr | truthful expansion                                                                  | preservation knobs                                                       |
|------|-----|------|-------------------------------------------------------------------------------------|--------------------------------------------------------------------------|
| 1    | HL  | HL   | `MOV SpareR,H; MOV M,L; INX H; MOV M,SpareR`                                        | if no SpareR, wrap `PUSH PSW`/`POP PSW` and use `SpareR=A`; optional `DCX H` if HL live after |
| 2    | HL  | DE   | `MOV A,L; STAX D; INX D; MOV A,H; STAX D`                                           | wrap `PUSH PSW`/`POP PSW` if A live; emit `DCX D` if DE live after       |
| 3    | HL  | BC   | `MOV A,L; STAX B; INX B; MOV A,H; STAX B`                                           | wrap `PUSH PSW`/`POP PSW` if A live; emit `DCX B` if BC live after       |
| 4    | BC  | HL   | `MOV M,C; INX H; MOV M,B`                                                           | optional `DCX H` if HL live after                                        |
| 5    | DE  | HL   | `MOV M,E; INX H; MOV M,D`                                                           | optional `DCX H` if HL live after                                        |
| 6    | BC  | BC   | `MOV H,B; MOV L,C; MOV M,C; INX H; MOV M,B`                                         | wrap `PUSH H`/`POP H` if HL live after                                   |
| 7    | BC  | DE   | `MOV H,D; MOV L,E; MOV M,C; INX H; MOV M,B`                                         | wrap `PUSH H`/`POP H` if HL live after                                   |
| 8    | DE  | BC   | `MOV H,B; MOV L,C; MOV M,E; INX H; MOV M,D`                                         | wrap `PUSH H`/`POP H` if HL live after                                   |
| 9    | DE  | DE   | `MOV H,D; MOV L,E; MOV M,E; INX H; MOV M,D`                                         | wrap `PUSH H`/`POP H` if HL live after                                   |

`SpareR` (case 1 only) selection: any GR8 dead at MI; `H` and `L` are
not candidates because both are live across the first `MOV M,L` /
`INX H` window, but **after** `MOV M,L` the low half is dead, and
**before** `INX H` the high half must already be saved — so the
candidate set is `{B, C, D, E, A}` minus whichever are live across
the pseudo. Default fallback `SpareR=A` with `PUSH PSW`/`POP PSW`
when `A` is also live.

### Key wins vs. today

- **A preserved on 6/9 shapes** (cases 4–9) — RA no longer spills `A`
  across every pointer store.
- **HL preserved on 2/9 shapes** (cases 2, 3) — RA no longer treats
  HL as clobbered when storing HL through DE/BC.
- **`DCX D`/`DCX B` replaces `PUSH/POP D`/`PUSH/POP B`** in cases 2–3
  whenever the address pair is live (1B/5cc vs 2B/22–23cc) and
  closes the existing correctness wart of "skip PUSH/POP when dead
  and silently leak orig+1".
- **Cases 6–9 are the only shapes that need `PUSH H`/`POP H`**, and
  only when HL is actually live after — matches the structural
  reason (HL fully overwritten by `MOV H,addrHi; MOV L,addrLo`,
  not recoverable by DCX).