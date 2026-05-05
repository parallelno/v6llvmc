# V6C_STORE16_P Design Redesign

`V6C_STORE16_P` is the generic 16-bit store-through-pointer pseudo:

## Problem

It has a problem - a single blanket `Defs = [HL, A]` that is over-declared in
several shapes. One coarse `Defs` set cannot simultaneously be
truthful and tight across 9 different code shapes. The fix is to drop `Defs`
entirely, and have the post-RA expander emit truthful preservation per shape
using the cheapest mechanism available at the expansion site (`SpareR`, `DCX rp`,
`XCHG`, or `PUSH`/`POP`).

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
- `Defs = [HL, A]` is a coarse blanket that over-declares: most val≠HL
  shapes never touch `A`, and `val=HL, addr ∈ {BC, DE}` shapes never
  touch `HL`.
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
| 2  | HL  | DE   | `[PUSH D]; MOV A,L; STAX D; INX D; MOV A,H; STAX D; [POP D]`            | HL, A            | A; HL preserved; DE preserved (PUSH/POP elided iff DE dead) | over: HL          |
| 3  | HL  | BC   | `[PUSH B]; MOV A,L; STAX B; INX B; MOV A,H; STAX B; [POP B]`            | HL, A            | A; HL preserved; BC preserved (PUSH/POP elided iff BC dead) | over: HL          |
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
  better than the current `PUSH/POP` (1B/5cc vs 2B/22–23cc).
- Cases 1, 2, 3 use `A` as the high-byte staging register. In case 1
  this is just to get past the `INX H` carry; any dead GR8 works
  (mirrors O71 case 1). In cases 2–3 `A` is **mandatory**: `STAX rp`
  only accepts `A` as the source register. There is no GR8-spare
  substitution available for cases 2–3.

### Proposed truthful clobber model (mirror of O71)

Drop `Defs` from the pseudo entirely; have the expander emit
preservation in cheap-first order. The `addr` register selects the
preservation strategy (`XCHG` for DE, `STAX` or `PUSH H`/`POP H`
for BC, nothing for HL); `val` only affects details inside that
strategy.

`SpareR` denotes a GR8 dead at the pseudo location; `A` is the
fallback if no GR8 spare is available, with `PUSH PSW`/`POP PSW`
wrap if `A` is also live.

| Case | addr | val | expansion | preservation knobs |
|---|------|-----|---------------------------------------------|-------------------------------------------------------|
| 1    | BC   | BC    | `MOV H,B; MOV L,C; MOV M,C; INX H; MOV M,B`              | wrap `PUSH H`/`POP H` if HL live after                                          |
| 2    | BC   | DE    | `MOV H,B; MOV L,C; MOV M,E; INX H; MOV M,D`              | wrap `PUSH H`/`POP H` if HL live after                                          |
| 3    | BC   | HL    | `MOV A,L; STAX B; INX B; MOV A,H; STAX B`                | wrap `PUSH PSW`/`POP PSW` if A live; emit `DCX B` if BC live after              |
| 4    | DE   | BC    | `XCHG; MOV M,C; INX H; MOV M,B; XCHG`                    | emit `DCX D` if DE live after; HL preserved by construction                     |
| 5    | DE   | DE    | `XCHG; MOV SpareR,H; MOV M,L; INX H; MOV M,SpareR; XCHG` | per-byte SpareR (see notes); emit `DCX D` if DE live after                      |
| 6    | DE   | HL    | `XCHG; MOV M,E; INX H; MOV M,D; XCHG`                    | emit `DCX D` if DE live after; HL value delivered through XCHG (no `A` needed)  |
| 7    | HL   | BC    | `MOV M,C; INX H; MOV M,B`                                | emit `DCX H` if HL live after                                                   |
| 8    | HL   | DE    | `MOV M,E; INX H; MOV M,D`                                | emit `DCX H` if HL live after                                                   |
| 9    | HL   | HL    | `MOV SpareR,H; MOV M,L; INX H; MOV M,SpareR`             | if no SpareR, wrap `PUSH PSW`/`POP PSW` and use `SpareR=A`; emit `DCX H` if HL live after |

#### Notes on case 3 (`addr=BC, val=HL`)

`STAX` is the only path: `MOV H,B; MOV L,C` would destroy the value
in HL, and there is no XCHG-equivalent for BC. `STAX rp` only
accepts `A` as the source register, so `A` is mandatory here.

A would-be alternative — `XCHG; MOV H,B; MOV L,C; MOV M,E; INX H;
MOV M,D; XCHG` — preserves `A` but trades it for an unconditional
DE clobber (DE was used to hold the value mid-expansion). For most
inputs the `STAX` path (5B / 29cc + optional `DCX B` / `PUSH PSW`)
is cheaper than the XCHG-via-DE path (7B / 37cc + the same opt knobs
+ DE preservation if DE live).

#### Notes on case 6 (`addr=DE, val=HL`) — major win vs. today

The current expander uses `STAX D` and clobbers `A`. The XCHG path
preserves both `A` and `HL`:

```
XCHG          ; HL=address, DE=value
MOV M,E       ; mem[address]   = E = lo(value)
INX H         ; HL = address+1
MOV M,D       ; mem[address+1] = D = hi(value)
XCHG          ; HL=value (= original HL), DE=address+1
[DCX D]       ; only if DE live after — recovers DE = address
```

5B / 29cc + opt `DCX D` (1B/5cc) — vs current 7–9B and `A` clobber.

#### Notes on case 5 (`addr=DE, val=DE`)

`val=DE` and `addr=DE` coincide. The trailing `XCHG` is mandatory:
the leading `XCHG` parks original `HL` in `DE`, and the trailing
`XCHG` restores it. A GR8 temp is needed because `INX H` can carry
from L into H, so the high byte of the value must be saved before
`INX H`.

`SpareR` selection mirrors O71 case 4 (per-byte, not per-pair):
after the leading `XCHG`, `HL` holds the address (so `H`, `L` are
never candidates), and `DE` physically holds the original `HL`
bytes that the trailing `XCHG` will restore. Therefore:

- `B` is a candidate iff `B` is dead across the pseudo.
- `C` is a candidate iff `C` is dead across the pseudo.
- `D` is a candidate iff **`H`** is dead across the pseudo
  (using `D` would otherwise destroy `H_orig`).
- `E` is a candidate iff **`L`** is dead across the pseudo
  (using `E` would otherwise destroy `L_orig`).
- `A` is a candidate iff `A` is dead across the pseudo.
- `H`, `L` are never candidates.

When no SpareR is available, fall back to `SpareR=A` wrapped in
`PUSH PSW`/`POP PSW`.

#### Notes on case 9 (`addr=HL, val=HL`)

`INX H` can carry from `L` into `H`, so the high byte of the value
must be parked in a GR8 before `INX H`. Any GR8 dead at the pseudo
works; `H` and `L` are not candidates because both halves are live
across the relevant window.

When no SpareR is dead, fall back to `SpareR=A` wrapped in `PUSH
PSW`/`POP PSW`.

Note: a "FLAGS-dead" alternative without `SpareR` was considered
(`MOV M,L; INX H; MOV M,H; DCR M`) but is **not correct**. After
`INX H`, register `H` equals `H_orig + 1` only when `L_orig =
0xFF`; otherwise it equals `H_orig`. `DCR M` therefore stores the
right value only in the carry case and corrupts the high byte
otherwise. There does not appear to be a branchless fallback that
beats `SpareR=A + PUSH PSW`.

### Key wins vs. today

- **`A` preserved on 6/9 shapes** (cases 1, 2, 4, 5, 6, 7, 8 — i.e.,
  every shape except `val=HL, addr ∈ {BC}` and the SpareR-fallback
  path of cases 5, 9). RA no longer spills `A` across pointer
  stores in the common case.
- **`HL` preserved on 4/9 shapes** (cases 3, 4, 5, 6) — the
  `addr ∈ {BC, DE}` shapes either never touch HL (`STAX` for case
  3) or recover it via XCHG (cases 4–6).
- **`DCX D`/`DCX B` replaces `PUSH/POP D`/`PUSH/POP B`** in cases
  3, 4, 5, 6 whenever the address pair is live (1B/5cc vs
  2B/22–23cc).
- **`PUSH H`/`POP H` is needed only on cases 1, 2** — the only
  shapes where HL is fully overwritten by `MOV H,addrHi; MOV
  L,addrLo` and cannot be recovered by `DCX`.