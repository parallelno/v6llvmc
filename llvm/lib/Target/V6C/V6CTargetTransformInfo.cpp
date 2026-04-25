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
