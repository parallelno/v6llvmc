//===-- V6CTargetTransformInfo.cpp - V6C specific TTI ---------------------===//
//
// Part of the V6C backend for LLVM.
//
//===----------------------------------------------------------------------===//

#include "V6CTargetTransformInfo.h"
#include "llvm/Analysis/TargetTransformInfo.h"
#include "llvm/IR/Function.h"
#include "llvm/Support/CommandLine.h"

using namespace llvm;

namespace {
/// Selects how V6C orders LSR formula cost vectors.
enum class LSRStrategy { Auto, InsnsFirst, RegsFirst };
} // namespace

// O22: master / per-hook switches for the V6C-specific TTI cost model.
// All default to ON. Use `-mllvm -v6c-tti-cost-hooks=0` to fall back to
// BasicTTI defaults wholesale, or any of the per-hook flags to bisect a
// regression to a single hook without rebuilding.
static cl::opt<bool> EnableTTICostHooks(
    "v6c-tti-cost-hooks",
    cl::desc("Master switch for V6C-specific TTI cost hooks (O22). "
             "Disable to fall back to BasicTTI defaults."),
    cl::init(true), cl::Hidden);

static cl::opt<bool> EnableArithCost(
    "v6c-tti-cost-arith",
    cl::desc("Enable V6C-specific TTI arithmetic cost (O22)."),
    cl::init(true), cl::Hidden);

static cl::opt<bool> EnableMemCost(
    "v6c-tti-cost-mem",
    cl::desc("Enable V6C-specific TTI memory cost (O22)."),
    cl::init(true), cl::Hidden);

static cl::opt<bool> EnableCmpCost(
    "v6c-tti-cost-cmp",
    cl::desc("Enable V6C-specific TTI cmp/select cost (O22)."),
    cl::init(true), cl::Hidden);

static cl::opt<bool> EnableScalingCost(
    "v6c-tti-cost-scaling",
    cl::desc("Enable V6C-specific TTI scaling-factor cost (O22)."),
    cl::init(true), cl::Hidden);

static cl::opt<LSRStrategy> LSRStrategyOpt(
    "v6c-lsr-strategy",
    cl::desc("LSR formula tie-breaker ordering on V6C."),
    cl::init(LSRStrategy::Auto),
    cl::values(
        clEnumValN(LSRStrategy::Auto, "auto",
                   "derive from optimization mode (default)"),
        clEnumValN(LSRStrategy::InsnsFirst, "insns-first",
                   "Z80-style: instruction count first"),
        clEnumValN(LSRStrategy::RegsFirst, "regs-first",
                   "V6C historical: register count first")),
    cl::Hidden);

// Z80-style: prioritize total in-loop instructions. Each in-loop reload on
// i8080 is ~30cc (LXI+LHLD+DAD+STAX), so trading +1 GP-pair pressure for
// fewer in-loop instructions is the right call when there's any pressure.
static bool insnsFirstLess(const TargetTransformInfo::LSRCost &C1,
                           const TargetTransformInfo::LSRCost &C2) {
  return std::tie(C1.Insns, C1.NumRegs, C1.AddRecCost, C1.NumIVMuls,
                  C1.NumBaseAdds, C1.ScaleCost, C1.ImmCost, C1.SetupCost) <
         std::tie(C2.Insns, C2.NumRegs, C2.AddRecCost, C2.NumIVMuls,
                  C2.NumBaseAdds, C2.ScaleCost, C2.ImmCost, C2.SetupCost);
}

// V6C historical: prioritize register count. Each spill is also bytes in
// the prologue / per access, so register count is the better proxy for
// code size on this target.
static bool regsFirstLess(const TargetTransformInfo::LSRCost &C1,
                          const TargetTransformInfo::LSRCost &C2) {
  return std::tie(C1.NumRegs, C1.Insns, C1.NumBaseAdds, C1.NumIVMuls,
                  C1.AddRecCost, C1.ImmCost, C1.SetupCost, C1.ScaleCost) <
         std::tie(C2.NumRegs, C2.Insns, C2.NumBaseAdds, C2.NumIVMuls,
                  C2.AddRecCost, C2.ImmCost, C2.SetupCost, C2.ScaleCost);
}

unsigned V6CTTIImpl::getNumberOfRegisters(unsigned ClassID) const {
  // ClassID 0 = scalar (general purpose register pairs: BC, DE, HL)
  // ClassID 1 = vector (none)
  return ClassID == 0 ? 3 : 0;
}

TypeSize V6CTTIImpl::getRegisterBitWidth(TTI::RegisterKind K) const {
  return TypeSize::getFixed(16);
}

bool V6CTTIImpl::isLegalAddressingMode(Type *Ty, GlobalValue *BaseGV,
                                        int64_t BaseOffset, bool HasBaseReg,
                                        int64_t Scale, unsigned AddrSpace,
                                        Instruction *I) const {
  // 8080 only supports [HL] indirect — no base+offset, no scaled index.
  // Legal: a single base register with zero offset, zero scale.
  if (BaseGV)
    return false;
  if (BaseOffset != 0)
    return false;
  if (Scale != 0 && Scale != 1)
    return false;
  // Must have at least a base register.
  if (!HasBaseReg && Scale == 0)
    return false;
  return true;
}

// Address computation on 8080 is expensive: LXI (12cc) + DAD (12cc) = 24cc
// for base+index, vs INX (8cc) for pointer increment.
// Returning non-zero makes LSR prefer strength-reduced pointer forms.
// The value is an abstract relative weight, not clock cycles.
InstructionCost V6CTTIImpl::getAddressComputationCost(Type *Ty,
                                                       ScalarEvolution *SE,
                                                       const SCEV *Ptr) const {
  return 2;
}

bool V6CTTIImpl::isLSRCostLess(const TTI::LSRCost &C1,
                                const TTI::LSRCost &C2) const {
  // V6C ranks LSR formulas via one of two lexicographic orderings over the
  // generic LSRCost fields:
  //
  //   regs-first  : NumRegs > Insns > NumBaseAdds > NumIVMuls > AddRecCost
  //                 > ImmCost > SetupCost > ScaleCost
  //   insns-first : Insns   > NumRegs > AddRecCost > NumIVMuls > NumBaseAdds
  //                 > ScaleCost > ImmCost > SetupCost  (Z80-style)
  //
  // Selection (per function):
  //   1. If `-v6c-lsr-strategy={insns-first,regs-first}` is given, honor it.
  //   2. Otherwise (auto), use Regs-first regardless of optimization mode.
  //      Empirically (O51 Step 3.7) Insns-first does not win on the V6C
  //      regression corpus — LSR's Insns estimate does not see the heavy
  //      reload sequences that result on the i8080 when an extra IV is
  //      kept "live" but the register file is too small to hold it. Insns-
  //      first remains available as opt-in for future targeted use.

  switch (LSRStrategyOpt) {
  case LSRStrategy::InsnsFirst:
    return insnsFirstLess(C1, C2);
  case LSRStrategy::RegsFirst:
    return regsFirstLess(C1, C2);
  case LSRStrategy::Auto:
    break;
  }

  return regsFirstLess(C1, C2);
}

// === O22: V6C-tuned TTI cost hooks ============================================
//
// Numbers below are abstract relative weights (not clock cycles) tuned to
// the i8080 cost ratios documented in design/future_plans/O22_tti_cost_hooks.md
// and reflect the multi-instruction expansions visible in the regression
// corpus (e.g. tests/features/51).
//
// Every hook:
//   1. Falls back to BaseT if its per-hook flag (or the master flag) is off.
//   2. Falls back to BaseT for any type it does not understand (vectors, FP,
//      pointer types, oversize integers) so we never produce *worse* numbers
//      than BasicTTI for cases we don't model explicitly.
// ============================================================================

InstructionCost V6CTTIImpl::getArithmeticInstrCost(
    unsigned Opcode, Type *Ty, TTI::TargetCostKind CostKind,
    TTI::OperandValueInfo Opd1Info, TTI::OperandValueInfo Opd2Info,
    ArrayRef<const Value *> Args, const Instruction *CxtI) {
  if (!EnableTTICostHooks || !EnableArithCost)
    return BaseT::getArithmeticInstrCost(Opcode, Ty, CostKind, Opd1Info,
                                         Opd2Info, Args, CxtI);

  if (!Ty || Ty->isVectorTy() || !Ty->isIntegerTy())
    return BaseT::getArithmeticInstrCost(Opcode, Ty, CostKind, Opd1Info,
                                         Opd2Info, Args, CxtI);

  unsigned BW = Ty->getIntegerBitWidth();
  // 8-bit native ALU op (ADD/SUB/AND/OR/XOR r): 4cc, 1 instruction.
  if (BW <= 8)
    return 1;
  // 16-bit ALU expands to multi-instruction sequences (DAD, ADC, manual
  // borrow, …) — ~24-48cc, 5-10 instructions.
  if (BW <= 16)
    return 6;
  // 32-bit goes through a libcall (__mulsi3, __addsi3, etc.).
  if (BW <= 32)
    return 20;
  return BaseT::getArithmeticInstrCost(Opcode, Ty, CostKind, Opd1Info,
                                       Opd2Info, Args, CxtI);
}

InstructionCost V6CTTIImpl::getMemoryOpCost(
    unsigned Opcode, Type *Src, MaybeAlign Alignment, unsigned AddressSpace,
    TTI::TargetCostKind CostKind, TTI::OperandValueInfo OpInfo,
    const Instruction *I) {
  if (!EnableTTICostHooks || !EnableMemCost)
    return BaseT::getMemoryOpCost(Opcode, Src, Alignment, AddressSpace,
                                  CostKind, OpInfo, I);

  if (!Src || Src->isVectorTy() || !Src->isIntegerTy())
    return BaseT::getMemoryOpCost(Opcode, Src, Alignment, AddressSpace,
                                  CostKind, OpInfo, I);

  unsigned BW = Src->getIntegerBitWidth();
  // Every memory access requires HL setup (LXI HL, addr) — there are no
  // free indexed addressing modes on i8080.
  if (BW <= 8)
    return 2; // LXI + MOV M / MOV r,M
  if (BW <= 16)
    return 4; // LXI + MOV + INX + MOV
  if (BW <= 32)
    return 8; // 2× i16 access pattern
  return BaseT::getMemoryOpCost(Opcode, Src, Alignment, AddressSpace,
                                CostKind, OpInfo, I);
}

InstructionCost V6CTTIImpl::getCmpSelInstrCost(
    unsigned Opcode, Type *ValTy, Type *CondTy, CmpInst::Predicate VecPred,
    TTI::TargetCostKind CostKind, const Instruction *I) {
  if (!EnableTTICostHooks || !EnableCmpCost)
    return BaseT::getCmpSelInstrCost(Opcode, ValTy, CondTy, VecPred,
                                     CostKind, I);

  if (!ValTy || ValTy->isVectorTy() || !ValTy->isIntegerTy())
    return BaseT::getCmpSelInstrCost(Opcode, ValTy, CondTy, VecPred,
                                     CostKind, I);

  unsigned BW = ValTy->getIntegerBitWidth();
  // i1 / i8: single CMP r (4cc).
  if (BW <= 8)
    return 1;
  // i16: BR_CC16 expansion is multi-instruction (CMP/CMP/Jcc/...).
  if (BW <= 16)
    return 4;
  if (BW <= 32)
    return 10;
  return BaseT::getCmpSelInstrCost(Opcode, ValTy, CondTy, VecPred,
                                   CostKind, I);
}

InstructionCost V6CTTIImpl::getScalingFactorCost(Type *Ty, GlobalValue *BaseGV,
                                                  int64_t BaseOffset,
                                                  bool HasBaseReg,
                                                  int64_t Scale,
                                                  unsigned AddrSpace) {
  if (!EnableTTICostHooks || !EnableScalingCost)
    return BaseT::getScalingFactorCost(Ty, BaseGV, BaseOffset, HasBaseReg,
                                       Scale, AddrSpace);

  // V6C only supports a single base register (HL) with no offset and no
  // scaled index. Anything else is invalid (mirrors isLegalAddressingMode).
  if (BaseGV || BaseOffset != 0 || (Scale != 0 && Scale != 1))
    return InstructionCost::getInvalid();
  if (!HasBaseReg && Scale == 0)
    return InstructionCost::getInvalid();
  return 0;
}
