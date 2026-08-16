# V6C Debugger ABI and DWARF Register Map

**Contract version:** 1
**Target:** `i8080-unknown-v6c`
**Object format:** ELF32 little-endian, `EM_V6C` (`0x8080`)
**DWARF format:** DWARF v5, 16-bit target addresses

This document is normative for V6C debug metadata producers and consumers.
Changing a register number or frame rule requires a contract-version change,
compiler tests, and matching debugger compatibility tests.

## Machine and Stack

- The address space is 16 bits and byte-addressed.
- Multi-byte integer and address values are little-endian.
- The stack grows toward lower addresses and has byte alignment.
- `CALL` pushes the 16-bit address of the instruction after the call.
- At callee entry, `SP` points to the low return-address byte; `[SP+1]` is the
  high byte.
- `RET` pops that little-endian address into PC.
- The default startup value is `SP=0x0000`; the first two-byte push wraps to
  `0xfffe` as defined by 8080 arithmetic.

## Arguments and Results

Arguments use type-specific free lists. Assigning a byte register removes its
containing pair from the word list; assigning a pair removes both halves from
the byte list.

- i8 arguments: `A`, `B`, `C`, `D`, `E`, `L`, `H`.
- i16 and pointer arguments: `HL`, `DE`, `BC`.
- Overflow arguments occupy the caller-allocated outgoing area in source
  argument order, starting at caller `SP+0` before `CALL`.
- At callee entry, the first stack argument is at `SP+2`, after the return
  address. Later stack arguments follow at increasing addresses.
- The caller removes the outgoing argument area after return.
- i8 results use `A`.
- i16 and pointer results use `HL`.
- i32 results use `DE:HL`, with `DE` holding the high word.
- All allocatable registers are caller-saved. There are no ordinary
  callee-saved registers.

Aggregates are lowered by the frontend/backend ABI rules in force for their
component widths. A debugger must consume the emitted parameter location and
must not infer an aggregate convention from this summary.

## Frames

The stack frame is selected from the actual machine function shape:

- Leaf functions with no frame may have no prologue or epilogue adjustment.
- Fixed allocation may use dead-pair `PUSH`/`POP`, repeated `DCX SP`/`INX SP`,
  or `LXI HL,offset; DAD SP; SPHL`.
- When a frame pointer is required, `BC` is reserved. The prologue saves the
  incoming `BC`, captures the pre-local-allocation SP in `BC`, and the epilogue
  restores SP and then `BC`.
- Prologues may temporarily save live `HL`/`DE` argument values while forming
  addresses. Those saves are implementation details and are described by CFI
  when unwind emission is enabled.
- Static-stack allocation and alloca promotion may place locals or spills in
  per-function global storage rather than the runtime stack.
- O61 may store spill values in the immediate bytes of patched reload
  instructions. Debug locations must describe the actual surviving register
  or address and must not pretend these values use a conventional stack slot.

`DW_AT_frame_base`, frame-relative variable expressions, and call-frame rules
must follow the emitted prologue variant. A consumer must not decode prologue
instruction patterns.

## Tail Calls and Special Frames

- V6C post-RA optimization may replace a terminal `CALL; RET` shape with a
  tail jump. The callee reuses the caller's frame and return address.
- Naked runtime helpers define their own instruction bodies and do not receive
  compiler-generated frame setup.
- Interrupt/trampoline frames are not ordinary C frames. Unwinding stops at
  such a boundary unless the final ELF contains explicit rules for that exact
  frame shape.
- Until `.debug_frame` support is implemented, absence of CFI means physical
  caller unwinding is unavailable; it is not permission to scan stack words.

## DWARF Register Numbers

| Number | Register | Width | Overlap |
|-------:|----------|------:|---------|
| 0 | `A` | 8 | accumulator half of unnumbered `PSW` |
| 1 | `B` | 8 | high byte of `BC` |
| 2 | `C` | 8 | low byte of `BC` |
| 3 | `D` | 8 | high byte of `DE` |
| 4 | `E` | 8 | low byte of `DE` |
| 5 | `H` | 8 | high byte of `HL` |
| 6 | `L` | 8 | low byte of `HL` |
| 7 | `BC` | 16 | `B:C` |
| 8 | `DE` | 16 | `D:E` |
| 9 | `HL` | 16 | `H:L` |
| 10 | `SP` | 16 | stack pointer |
| 11 | `PC` | 16 | program counter and CFI return-address column |

Pairs have distinct numbers from their byte registers. A complete i16 value in
a physical pair uses the pair number. A byte value uses its byte-register
number. Split values may use pieces only when the published producer/consumer
operation table enables that representation.

`FLAGS` and `PSW` intentionally have no DWARF numbers in contract version 1.
They are not valid C variable locations or independently recoverable caller
state.

## Unwind Boundary Policy

A physical unwind may continue only when an FDE covers the current PC and its
rules recover a valid CFA, return PC, and caller SP. It stops on missing or
unsupported CFI, naked/interrupt/trampoline boundaries without explicit rules,
invalid memory, unchanged CFA, cycles, or addresses outside the 16-bit target
space.

## Verification

Use the final linked ELF as the authoritative metadata artifact. Verify it with
`llvm-dwarfdump --verify`, correlate symbols/ranges with executable sections,
and compare evaluated locations or unwind rules with coherent emulator
register and memory snapshots. The flat ROM contains executable bytes only;
debug sections remain in the companion ELF.
