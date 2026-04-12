# O26. Cost Model Infrastructure (getInstrCost + copyCost)

*From plan_dual_cost_model.md Future Enhancements.*
*Extension of O11 (Dual Cost Model) with MachineInstr-level cost queries.*

## Problem

O11 introduced `V6CInstrCost` with pre-defined constants (e.g.,
`V6CCost::MOVrr`, `V6CCost::LXI`). Each optimization pass manually selects
the appropriate constant. This works but has limitations:

1. **No MachineInstr → cost mapping**: Passes must manually map opcodes to
   cost constants. If a pass encounters an unfamiliar opcode, it can't
   query its cost.

2. **No copy cost awareness**: Register allocation and copy-related passes
   (O12, O20) don't know that `MOV D,H; MOV E,L` (16cc) is cheaper than
   `PUSH HL; POP DE` (24cc) for a DE←HL pair copy, or that XCHG (4cc) is
   cheapest when both pairs are live.

3. **No scheduling integration**: The V6CSchedule.td defines SchedWrite
   resources with latencies, but these aren't connected to V6CInstrCost.
   Passes that compare expansion costs must duplicate cycle counts.

## Implementation

### getInstrCost(const MachineInstr &MI)

Add to `V6CInstrCost.h`:

```cpp
/// Compute the cost of a single MachineInstr.
inline V6CInstrCost getInstrCost(const MachineInstr &MI) {
  switch (MI.getOpcode()) {
  case V6C::MOVrr:  return V6CCost::MOVrr;
  case V6C::MOVrM:  return V6CCost::MOVrM;
  case V6C::MOVMr:  return V6CCost::MOVMr;
  case V6C::MVIr:   return V6CCost::MVI;
  case V6C::LXIrp:  return V6CCost::LXI;
  case V6C::INXrp:  return V6CCost::INX;
  case V6C::DCXrp:  return V6CCost::INX;  // same cost
  case V6C::DADrp:  return V6CCost::DAD;
  case V6C::PUSH:   return V6CCost::PUSH;
  case V6C::POP:    return V6CCost::POP;
  case V6C::CALL:   return V6CCost::CALL;
  case V6C::RET:    return V6CCost::RET;
  // ... ALU ops, branches, etc.
  default:           return V6CInstrCost(1, 4); // conservative default
  }
}

/// Compute total cost of a range of MachineInstrs.
inline V6CInstrCost getSequenceCost(MachineBasicBlock::iterator Begin,
                                     MachineBasicBlock::iterator End) {
  V6CInstrCost Total(0, 0);
  for (auto I = Begin; I != End; ++I)
    Total = Total + getInstrCost(*I);
  return Total;
}
```

### copyCost(MCRegister Src, MCRegister Dst)

```cpp
/// Cost of copying between physical registers or register pairs.
inline V6CInstrCost copyCost(MCRegister Src, MCRegister Dst) {
  // 8-bit register copy
  if (V6C::GR8RegClass.contains(Src) && V6C::GR8RegClass.contains(Dst))
    return V6CCost::MOVrr;  // MOV dst, src: 8cc, 1B

  // 16-bit pair copy
  if (Src == V6C::HL && Dst == V6C::DE)
    return V6CCost::MOVrr * 2;  // MOV D,H; MOV E,L: 16cc, 2B
  if (Src == V6C::DE && Dst == V6C::HL)
    return V6CCost::MOVrr * 2;  // MOV H,D; MOV L,E: 16cc, 2B
  // BC↔HL, BC↔DE: also 2 MOVs
  return V6CCost::MOVrr * 2;    // 16cc, 2B for any pair copy
}

/// Cost of XCHG (DE↔HL swap) — only valid when both are live.
inline V6CInstrCost xchgCost() {
  return V6CInstrCost(1, 4);  // XCHG: 4cc, 1B
}
```

### Scheduling integration (optional)

Map SchedWrite resources from V6CSchedule.td to V6CInstrCost in a
helper table. This ensures consistency between the scheduler's latency
model and the cost model used by optimization passes.

## Benefit

- **Reduces code duplication**: Passes don't manually map opcodes to costs
- **Enables cost-aware expansion**: Pseudos can query expansion cost to
  choose the cheapest sequence at expansion time
- **copyCost**: Enables O12 (global copy opt) and O20 (honest store/load
  defs) to make cost-aware register transfer decisions
- **getSequenceCost**: Use in V6CLoadStoreOpt, V6CSPTrickOpt, etc. to
  compare before/after costs of transformations

## Complexity

Low. ~60-80 lines in V6CInstrCost.h. Pure infrastructure — header-only,
no new passes.

## Risk

Very Low. Cost queries are read-only. Wrong costs → suboptimal (not
incorrect) code. Can be tuned incrementally.

## Dependencies

O11 (Dual Cost Model) — already complete. This extends it.

## Testing

1. Unit-level: verify getInstrCost returns correct values for key opcodes
2. No behavioral change expected — this is infrastructure for other passes
