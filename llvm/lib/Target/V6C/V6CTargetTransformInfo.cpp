//===-- V6CTargetTransformInfo.cpp - V6C specific TTI ---------------------===//
//
// Part of the V6C backend for LLVM.
//
//===----------------------------------------------------------------------===//

#include "V6CTargetTransformInfo.h"
#include "llvm/Analysis/TargetTransformInfo.h"

using namespace llvm;

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
  // On the 8080, register pressure is the dominant constraint.
  // Prefer fewer registers first, then fewer instructions.
  // NumBaseAdds (in-loop base address additions: LXI+DAD = 24cc each) ranks
  // before AddRecCost (loop IV increments: INX = 8cc each) because base
  // additions are 3x more expensive than IV increments.
  return std::tie(C1.NumRegs, C1.Insns, C1.NumBaseAdds, C1.NumIVMuls,
                  C1.AddRecCost, C1.ImmCost, C1.SetupCost, C1.ScaleCost) <
         std::tie(C2.NumRegs, C2.Insns, C2.NumBaseAdds, C2.NumIVMuls,
                  C2.AddRecCost, C2.ImmCost, C2.SetupCost, C2.ScaleCost);
}
