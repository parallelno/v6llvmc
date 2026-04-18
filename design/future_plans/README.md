# Future Optimizations — V6C Backend

## Optimization Plans

| ID | Optimization | File | Source |
|----|-------------|------|--------|
| O1 | Redundant MOV Elimination after BUILD_PAIR + ADD16 | [O01_redundant_mov_elimination.md](O01_redundant_mov_elimination.md) | V6C |
| O2 | Sequential Address Reuse (LXI → INX Folding) | [O02_sequential_lxi_inx_folding.md](O02_sequential_lxi_inx_folding.md) | V6C |
| O3 | Narrow-Type Arithmetic (i8 Chain Instead of i16) | [O03_narrow_type_arithmetic.md](O03_narrow_type_arithmetic.md) | V6C |
| O4 | ADD M / SUB M Direct Memory Operand | [O04_add_sub_m_direct_memory.md](O04_add_sub_m_direct_memory.md) | V6C |
| O5 | BUILD_PAIR(x, 0) + ADD16 Fusion | [O05_build_pair_add16_fusion.md](O05_build_pair_add16_fusion.md) | V6C |
| O6 | LDA/STA for Absolute Address Loads | [O06_lda_sta_absolute_addr.md](O06_lda_sta_absolute_addr.md) | V6C |
| O7 | Loop Strength Reduction via TTI | [O07_loop_strength_reduction.md](O07_loop_strength_reduction.md) | V6C |
| O8 | Spill Optimization (Tier 1/2 Strategy) | [O08_spill_optimization.md](O08_spill_optimization.md) | V6C |
| O9 | Inline Assembly Completion (MC Asm Parser) | [O09_inline_assembly.md](O09_inline_assembly.md) | V6C |
| O10 | Static Stack Allocation (Non-Reentrant) | [O10_static_stack_allocation.md](O10_static_stack_allocation.md) | llvm-mos |
| O11 | Dual Cost Model (Bytes + Cycles) | [O11_dual_cost_model.md](O11_dual_cost_model.md) | llvm-mos |
| O12 | Global Copy Optimization (Cross-BB) | [O12_global_copy_optimization.md](O12_global_copy_optimization.md) | llvm-mos |
| O13 | Load-Immediate Combining (Register Value Tracking) | [O13_load_immediate_combining.md](O13_load_immediate_combining.md) | llvm-mos |
| O14 | Tail Call Optimization (CALL+RET → JMP) | [O14_tail_call_optimization.md](O14_tail_call_optimization.md) | llvm-mos |
| O15 | Conditional Call Optimization (Branch-over-Call → CC/CZ) | [O15_conditional_call_optimization.md](O15_conditional_call_optimization.md) | llvm-z80 |
| O16 | Post-RA Store-to-Load Forwarding (Spill/Reload) | [O16_store_to_load_forwarding.md](O16_store_to_load_forwarding.md) | llvm-z80 |
| O17 | Redundant Flag-Setting Elimination (Post-RA) | [O17_redundant_flag_elimination.md](O17_redundant_flag_elimination.md) | llvm-z80 |
| O18 | Loop Counter DEC+Branch Peephole | [O18_loop_counter_peephole.md](O18_loop_counter_peephole.md) | llvm-z80 |
| O19 | Inline Arithmetic Expansion (Mul/Div) | [O19_inline_arithmetic_expansion.md](O19_inline_arithmetic_expansion.md) | llvm-z80 |
| O20 | Honest Store/Load Pseudo Defs (Remove False HL Clobber) | [O20_honest_store_load_defs.md](O20_honest_store_load_defs.md) | V6C |
| O21 | LHLD/SHLD 16-bit Absolute Address Patterns | [O21_lhld_shld_absolute_addr.md](O21_lhld_shld_absolute_addr.md) | V6C |
| O22 | TTI Cost Hooks Expansion | [O22_tti_cost_hooks.md](O22_tti_cost_hooks.md) | V6C |
| O23 | Conditional Tail Call Optimization | [O23_conditional_tail_call.md](O23_conditional_tail_call.md) | V6C |
| O24 | I16 Immediate Unsigned Comparison | [O24_sui_sbi_immediate_cmp.md](O24_i16_immediate_cmp.md) | V6C |
| O26 | Cost Model Infrastructure (getInstrCost + copyCost) | [O26_cost_model_infra.md](O26_cost_model_infra.md) | V6C |
| O27 | i16 Zero-Test Optimization (MOV+ORA) | [O27_i16_zero_test.md](O27_i16_zero_test.md) | V6C |
| O28 | Branch Threading Through JMP-Only Blocks | [O28_branch_threading_jmp_only.md](O28_branch_threading_jmp_only.md) | V6C |
| O29 | Cross-BB Immediate Value Propagation | [O29_cross_bb_imm_propagation.md](O29_cross_bb_imm_propagation.md) | V6C |
| O30 | Conditional Return Peephole (Jcc RET → Rcc) | [O30_conditional_return.md](O30_conditional_return.md) | V6C |
| O31 | Dead PHI-Constant Elimination for Zero-Tested Branches | [O31_dead_phi_constant.md](O31_dead_phi_constant.md) | V6C |
| O32 | XCHG in copyPhysReg (RA-Time DE↔HL Swap) | [O32_xchg_in_copy_phys_reg.md](O32_xchg_in_copy_phys_reg.md) | V6C |
| O33 | XCHG Peephole Relaxation (Drop isRegLiveBefore Guard) | [O33_xchg_peephole_relaxation.md](O33_xchg_peephole_relaxation.md) | V6C |
| O34 | SELECT_CC Zero-Test ISel Gap | [O34_select_cc_zero_test.md](O34_select_cc_zero_test.md) | V6C |
| O35 | Conditional Return Over RET (Jcc-over-RET → Rcc) | [O35_conditional_return_over_ret.md](O35_conditional_return_over_ret.md) | V6C |
| O36 | Redundant LXI After Zero-Test Branch | [O36_redundant_lxi_after_zero_test.md](O36_redundant_lxi_after_zero_test.md) | V6C |
| O37 | Deferred Zero-Load After Zero-Test | [O37_deferred_zero_load.md](O37_deferred_zero_load.md) | V6C |
| O38 | XRA+CMP i8 Zero-Test Peephole | [O38_xra_cmp_zero_test.md](O38_xra_cmp_zero_test.md) | V6C |
| O39 | Interprocedural Register Allocation (IPRA) Integration | [O39_ipra_integration.md](O39_ipra_integration.md) | V6C |
| O40 | ADD16 DAD-Based Expansion (Post-RA) | [O40_add16_dad_expansion.md](O40_add16_dad_expansion.md) | V6C |
| O41 | Pre-RA INX/DCX Pseudo (Small-Constant Pointer Add) | [O41_pre_ra_inx_dcx_pseudo.md](O41_pre_ra_inx_dcx_pseudo.md) | V6C |
| O42 | Liveness-Aware Pseudo Expansion (Skip PUSH/POP When Dead) | [O42_liveness_aware_expansion.md](O42_liveness_aware_expansion.md) | V6C |
| O43 | SHLD/LHLD to PUSH/POP Peephole (Static Stack Spill Shortening) ✅ | [O43_shld_lhld_to_push_pop.md](O43_shld_lhld_to_push_pop.md) | V6C |
| O43-fix | SHLD/LHLD Safety Guard (Block fold when uncovered LHLD reachable) ✅ | [O43_fix_shld_lhld_safety_guard.md](O43_fix_shld_lhld_safety_guard.md) | V6C |
| O44 | Adjacent XCHG Cancellation Peephole ✅ | [O44_xchg_cancellation.md](O44_xchg_cancellation.md) | V6C |
| O45 | Adjacent POP/PUSH Cancellation Peephole | [O45_pop_push_cancellation.md](O45_pop_push_cancellation.md) | V6C |
| O46 | MVI M, imm8 Immediate Store Peephole | [O46_mvi_m_immediate_store.md](O46_mvi_m_immediate_store.md) | V6C |

---

## Summary Table

| ID | Optimization | Source | Savings/instance | Frequency | Complexity | Risk | Dependencies | Complete |
|----|-------------|--------|-----------------|-----------|------------|------|-------------|-----|
| O1 | Redundant MOV elimination | V6C | 8cc, 1B | Very high | Low | Low | None (superseded by O12) | [ ] |
| O2 | Sequential LXI → INX | V6C | 4cc, 2B | High | Medium | Low-Med | None | [ ] |
| O3 | Narrow-type arithmetic | V6C | 30-100cc | Very high | High | Med-High | None | [ ] |
| O4 | ADD M / SUB M direct | V6C | 4-8cc, 1B | High | Medium | Low-Med | O2 helps | [ ] |
| O5 | BUILD_PAIR(x,0)+ADD16 | V6C | 16-24cc | Very high | Medium | Low-Med | None | [ ] |
| O6 | LDA/STA absolute addr | V6C | 2cc, 1B | Medium | Low | Low | None | [x] |
| O7 | Loop Strength Reduction (TTI) | V6C | 120-160cc/iter | High (loops) | Medium | Medium | None | [x] |
| O8 | Spill Optimization (T1/T2) | V6C | 64-76cc/pair | Very high | High | Med-High | O10 enhances T2 | [ ] |
| O9 | Inline Assembly (MC parser) | V6C | N/A (feature) | N/A | High | Low | None | [ ] |
| O10 | Static Stack (non-reentrant) | llvm-mos | 32-36cc/access | Very high | Medium | Medium | LTO/single-TU | [x] |
| O11 | Dual Cost Model (Bytes+Cycles) | llvm-mos | N/A (infra) | N/A | Low | Very Low | None | [x] |
| O12 | Global Copy Opt (cross-BB) | llvm-mos | 8cc, 1B | Very high | Medium | Low | O11 | [ ] |
| O13 | LdImm Combining (value track) | llvm-mos | 1B or 4cc+1B | High | Low | Very Low | None | [x] |
| O14 | Tail Call (CALL+RET→JMP) | llvm-mos | 18cc, 1B | Medium | Very Low | Very Low | None | [x] |
| O15 | Conditional Call (JNZ+CALL→CNZ) | llvm-z80 | 12cc, 3B | Medium | Medium | Low | None | [ ] |
| O16 | Store-to-Load Forwarding | llvm-z80 | 44-52cc/reload | Very high | Medium | Low-Med | None | [x] |
| O17 | Redundant Flag Elimination | llvm-z80 | 4cc, 1B | Med-high | Low | Very Low | None | [x] |
| O18 | Loop Counter DCR+JNZ | llvm-z80 | 20cc, 4B/iter | Very high | Low | Very Low | None | [x] |
| O19 | Inline Arithmetic (Mul/Div) | llvm-z80 | 100-200cc | Medium | Medium | Low | None | [ ] |
| O20 | Honest Store/Load Defs (HL clobber) | V6C | 14cc, 2B/iter | Very high | Medium | Low-Med | None | [x] |
| O21 | LHLD/SHLD 16-bit absolute addr | V6C | 14-22cc, 3-4B | Medium | Low | Very Low | O6 done | [x] |
| O22 | TTI Cost Hooks Expansion | V6C | indirect (better decisions) | High | Low-Med | Low | O7 done | [ ] |
| O23 | Conditional Tail Call | V6C | 14cc, 1B | Medium | Low-Med | Low | O14 done | [x] |
| O24 | I16 Immediate Unsigned CMP | V6C | 2cc, 1B + free reg pair | Med-high | Medium | Low | None | [ ] |
| O26 | Cost Model Infra (getInstrCost) | V6C | N/A (infra) | N/A | Low | Very Low | O11 done | [ ] |
| O27 | i16 Zero-Test (MOV+ORA) | V6C | 24cc, 10B | Very high | Low-Med | Low | None | [x] |
| O28 | Branch Threading (JMP-only blocks) | V6C | 10cc, 3B | Medium | Low | Very Low | O27 enables | [x] |
| O29 | Cross-BB Immediate Propagation | V6C | 7cc, 1B | Medium | Low-Med | Low | O13 done | [x] |
| O30 | Conditional Return (Jcc RET→Rcc) | V6C | 3B, 1 instr | Med-High | Low | Very Low | O27 done | [x] |
| O31 | Dead PHI-Constant Elimination | V6C | 9-11B, 40-60cc | Very high | Medium | Low | O27 done | [x] |
| O32 | XCHG in copyPhysReg (RA-time swap) | V6C | 12cc, 1B | Med-High | Very Low | Very Low | None | [x] |
| O33 | XCHG Peephole Relaxation | V6C | 12cc, 1B | Low | Very Low | Very Low | None | [ ] |
| O34 | SELECT_CC Zero-Test ISel Gap | V6C | 15cc, 3B + spill savings | Medium | Low-Med | Low | O27 done | [x] |
| O35 | Conditional Return Over RET (Jcc-over-RET → Rcc) | 18cc, 3B | Medium | Very Low | Very Low | O28 done | [x] |
| O36 | Branch-Implied Value Propagation | 12cc, 3B+ | Medium | Low | Low | O27+O35+O13 done | [x] |
| O37 | Deferred Zero-Load After Zero-Test | 16cc, 4B | Medium | Low-Med | Low | O36 done | [x] |
| O38 | XRA+CMP i8 Zero-Test | 4cc + cascade 4B+16cc | Med-high | Low | Very Low | O13 benefits | [x] |
| O39 | IPRA Integration (eliminate call spills) | 13-18 instr/func | Very high | Medium | Medium | None | [x] |
| O40 | ADD16 DAD-Based Expansion | V6C | 12cc, 3B | Med-High | Very Low | Very Low | None | [x] |
| O41 | Pre-RA INX/DCX Pseudo (±1..±3) | V6C | 12cc, 3B + free reg pair | Very high | Low | Very Low | O20 done | [x] |
| O42 | Liveness-Aware Pseudo Expansion | V6C | 21-24cc, 2-3B per PUSH/POP | Very high | Low-Med | Low | O10+O20 done | [x] |
| O43 | SHLD/LHLD→PUSH/POP Peephole | V6C | 12cc, 4B per pair | Med-High | Low | Very Low | O10 done | [x] |
| O43-fix | SHLD/LHLD Safety Guard (correctness) | V6C | N/A (bugfix) | N/A | Low | Very Low | O43 done | [x] |
| O44 | Adjacent XCHG Cancellation | V6C | 8cc, 2B per pair | Medium | Very Low | Very Low | None | [x] |
| O45 | Adjacent POP/PUSH Cancellation | V6C | 24cc, 2B per pair | High | Very Low | Very Low | O42 done | [ ] |
| O46 | MVI M, imm8 Immediate Store | V6C | 4cc, 1B per instance | Low-Med | Very Low | Very Low | None | [ ] |

### Recommended order

**Phase 1 — Quick wins (Low complexity, immediate benefit)**:
1. ~~**O14** — trivial tail-call peephole, 18cc savings, ~15 lines~~ ✅
2. ~~**O18** — loop counter DCR+JNZ peephole, 20cc savings per iteration, ~40 lines~~ ✅
3. ~~**O17** — redundant flag elimination, 4cc+1B per instance, ~50 lines~~ ✅
4. ~~**O11** — cost model infrastructure, enables cost-aware decisions everywhere~~ ✅
5. ~~**O13** — register value tracking peephole, saves bytes on MVI→MOV/INR~~ ✅
6. ~~**O6** — simple ISel pattern for LDA/STA~~ ✅

**Phase 2 — Quick extensions (Low complexity, builds on completed work)**:
7. ~~**O21** — LHLD/SHLD for i16 globals, ISel patterns like O6, ~20 lines~~ ✅
8. ~~**O23** — conditional tail call, extends O14 peephole, ~20 lines~~ ✅
9. ~~**O27** — i16 zero-test (MOV A,H; ORA L), 10B+24cc per zero comparison, ~15 lines~~ ✅
10. ~~**O32** — XCHG in copyPhysReg, 1B+12cc per DE↔HL copy, ~10 lines~~ ✅
11. **O33** — XCHG peephole relaxation, drop isRegLiveBefore guard, ~10 lines
12. ~~**O34** — SELECT_CC zero-test ISel gap, 3B+15cc + spill cascade savings, ~30 lines~~ ✅
13. ~~**O28** — branch threading through JMP-only blocks, 3B+10cc, synergy with O27, ~25 lines~~ ✅
14. ~~**O35** — conditional return over RET (Jcc-over-RET → Rcc), 3B per instance, ~20 lines~~ ✅
15. ~~**O36** — branch-implied value propagation, 12cc+3B per instance, extends O13 seeding, ~50 lines~~ ✅
16. **O26** — cost model getInstrCost/copyCost infra, extends O11, ~70 lines
17. ~~**O29** — cross-BB immediate propagation, 1B+7cc per redundant MVI, ~30 lines~~ ✅
18. ~~**O30** — conditional return peephole (Jcc RET → Rcc), 3B per instance, ~30 lines~~ ✅
19. ~~**O31** — dead PHI-constant elimination, 9-11B+40-60cc, eliminates LXI+shuffle, ~70 lines~~ ✅
20. ~~**O37** — deferred zero-load after zero-test, 4B+16cc, sink LXI past branch, ~40 lines~~ ✅
21. ~~**O38** — XRA+CMP i8 zero-test, 4cc + cascade MVI elimination, ~40 lines~~ ✅
22. ~~**O40** — ADD16 DAD-based expansion, 12cc+3B per non-HL ADD16, ~30 lines~~ ✅
23. ~~**O41** — pre-RA INX/DCX pseudo for ±1..±3 constants, frees register pair, ~40 lines~~ ✅
24. ~~**O42** — liveness-aware pseudo expansion, skip PUSH/POP when dead, 21-24cc per instance, ~80 lines~~ ✅
25. ~~**O43** — SHLD/LHLD→PUSH/POP peephole, 12cc+4B per short-lived HL spill, ~40 lines~~ ✅
26. ~~**O44** — adjacent XCHG cancellation, 8cc+2B per pair, ~15 lines~~ ✅
27. **O45** — adjacent POP/PUSH cancellation, 24cc+2B per pair, ~20 lines
28. **O46** — MVI M, imm8 ISel pattern, 4cc+1B per immediate store, ~30 lines

**Phase 3 — Core optimizations (Medium complexity, high payoff)**:
19. ~~**O39** — IPRA integration, eliminates 13-18 spill instructions per function with calls, ~20 lines~~ ✅
20. ~~**O20** — honest store/load defs, 14cc+2B per loop iteration, ~100 lines~~ ✅
21. ~~**O16** — store-to-load forwarding, 44-52cc per eliminated reload~~ ✅
22. **O12** — cross-BB copy optimization, supersedes O1
22. **O24** — I16 immediate unsigned comparison, frees register pair
23. **O15** — conditional call, 12cc+3B per instance, reduces branch count
24. **O5** — BUILD_PAIR+ADD16 fusion, high per-instance savings
25. **O2** — sequential LXI→INX folding
26. **O4** — ADD M / SUB M direct memory, builds on O2

**Phase 4 — Loop & stack (Medium-High complexity, massive payoff)**:
27. ~~**O7** — TTI for Loop Strength Reduction, existing LLVM pass just needs cost info~~ ✅
28. **O22** — TTI cost hooks (arithmetic, memory, cmp costs), extends O7
29. ~~**O10** — static stack allocation for non-reentrant functions, supersedes O8 T2~~ ✅
30. **O19** — inline arithmetic expansion for mul/div, 2-3× faster than libcalls

**Phase 5 — Advanced (High complexity)**:
30. **O3** — narrow-type arithmetic, highest per-instance savings but complex DAGCombine
31. **O8** — remaining spill optimization (T1 PUSH/POP), complements O10

**Deferred**:
- **O9** — inline assembly MC parser, implement when needed

### Comparison with AVR

AVR's LLVM backend benefits from 32 GPRs, 3 pointer pairs (X/Y/Z), and
post-increment addressing (`LD r, Z+`). The i8080 has 7 registers, 1
pointer pair for general memory access (HL), and no auto-increment.

This means:
- **Register pressure** is the dominant bottleneck on V6C. AVR rarely spills;
  V6C spills often. Optimizations that reduce live ranges (O3, O5) have
  outsized impact.
- **Address setup cost** dominates on V6C. AVR's `LD r, Z+` is 2cc; V6C
  needs `INX HL` (6cc) or `LXI HL` (10cc). O2 and O4 directly address this.
- **Accumulator bottleneck** has no AVR equivalent. AVR's ALU works on any
  register. V6C funnels everything through A. O1 (eliminating redundant MOV
  through A) is V6C-specific and high impact.

### Reference: llvm-mos (6502)

See [llvm-mos analysis](llvm_mos_analysis.md) for detailed notes on 6502 backend techniques applicable to V6C.

The **llvm-mos** project (https://github.com/llvm-mos/llvm-mos) targets the
MOS 6502 — the closest architectural match to i8080 among LLVM backends.
It is accumulator-only with even fewer registers (A, X, Y; no register pairs).
Their backend has 12+ custom optimization passes solving the same fundamental
problems we face. Full analysis: [llvm_mos_analysis.md](llvm_mos_analysis.md).

**Passes directly adapted for V6C** (O10-O14 above):
- **`MOSNonReentrant` + `MOSStaticStackAlloc`** → O10 (static stack for non-reentrant
  functions, 3-5× faster spill/reload)
- **`MOSInstrCost`** → O11 (dual Bytes+Cycles cost model)
- **`MOSCopyOpt`** → O12 (inter-BB copy forwarding + immediate rematerialization)
- **`MOSLateOptimization::combineLdImm`** → O13 (register value tracking,
  replace MVI with MOV/INR/DCR)
- **`MOSLateOptimization::tailJMP`** → O14 (CALL+RET → JMP tail calls)

**Passes with indirect value for V6C**:
- **`MOSIndexIV`** — IR-level loop pass that narrows indices to 8 bits via SCEV
  analysis. Complements O7 (TTI). Almost target-independent; minimal porting.
- **`MOSZeroPageAlloc`** — frequency-weighted call-graph-aware allocation of
  scarce fast-access memory. No direct 8080 zero page, but the algorithm is
  valuable for O8/O10 global bss slot allocation decisions.
- **`MOSLateOptimization::lowerCmpZeros`** — eliminates compare-against-zero
  by scanning backward past known-safe instructions. Enhances existing V6C
  `ZERO_TEST` pass.
- **`MOSShiftRotateChain`** — chains constant shifts to share intermediate
  results via dominance analysis. Lower priority for 8080 (shifts less common).

**Key architectural insight**: The 8080 has *more* registers (7 vs 3) but
*fewer* addressing modes (no indexed, no zero page). llvm-mos compensates for
its tiny register file with zero-page "soft registers" and indexed addressing.
V6C must compensate for its addressing limitations with better register
utilization and cheaper pointer management — different mechanism, same goal.

### Reference: llvm-z80

Two Z80 LLVM backends were analyzed — full details in
[llvm_z80_analysis.md](llvm_z80_analysis.md).

**jacobly0/llvm-project** (https://github.com/jacobly0/llvm-project, `z80`
branch, 171 stars) — mature Z80/eZ80 backend, GlobalISel, ~LLVM 15. 14
custom passes. Key contribution: comprehensive `RegVal` tracking in
`Z80MachineLateOptimization` that knows per-register constants, flag states,
and sub-register composition. This is the inspiration for O13's "enhanced"
form.

**llvm-z80/llvm-z80** (https://github.com/llvm-z80/llvm-z80, `main` branch,
34 stars) — newer active Z80+SM83 backend, ~LLVM 20, ports from llvm-mos.
23 custom passes. Key contribution: SM83 (Game Boy) is an 8080 subset, so
its SM83 code paths are directly applicable to V6C.

**Passes directly adapted for V6C** (O15-O19 above):
- **`Z80MachineEarlyOptimization`** (jacobly0) → O15 (conditional call,
  JNZ+CALL → CNZ using the 8080's CC/CNC/CZ/CNZ/CP/CM/CPE/CPO)
- **`Z80LateOptimization` IX-forwarding** (llvm-z80) → O16 (store-to-load
  forwarding, tracking spilled register values to eliminate redundant reloads)
- **`Z80PostRACompareMerge`** (llvm-z80) → O17 (redundant flag elimination,
  erase ORA A when preceding ALU already set Z flag)
- **`Z80LateOptimization` loop counter** (llvm-z80) → O18 (5-instruction
  loop counter → DCR r; JNZ, saving 20cc+4B per iteration)
- **`Z80ExpandPseudo` inline arithmetic** (llvm-z80) → O19 (shift-add mul,
  restoring div inline instead of library calls)

**Passes enhancing existing V6C plans**:
- **`Z80TargetTransformInfo`** — `areInlineCompatible()` restricts inlining
  to ≤10 instructions or InlineHint-annotated functions (because with few
  registers, inlining large functions causes massive spilling). Enhances O7.
  `isLSRCostLess()` prioritizes instruction count over register pressure.
  Enhances O7's TTI cost model.
- **`Z80MachineLateOptimization` RegVal** (jacobly0) — extends O13 with
  comprehensive per-register constant tracking, flag state awareness,
  sub-register composition knowledge, and many more peephole patterns
  (SLA A→ADD A,A, LD 0→SBC r,r when carry known, LD imm±1→INC/DEC).
- **`Z80InstrCost`** + **`Z80ShiftRotateChain`** + **`Z80IndexIV`** — all
  ported from llvm-mos, confirming the value of O11 (dual cost model).

**Key architectural insight**: The Z80 is a strict superset of the 8080. Any
Z80 optimization using only base 8080 instructions applies directly to V6C.
The SM83 (Game Boy CPU) is an 8080 subset (no IX/IY, no relative jumps, no
block instructions) — making the llvm-z80 SM83 code paths the most directly
portable to V6C. The main Z80-only features (IX+d indexing, relative jumps,
DJNZ, block I/O) require 8080-specific alternatives when porting.
