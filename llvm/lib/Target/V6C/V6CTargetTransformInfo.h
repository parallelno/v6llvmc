//===-- V6CTargetTransformInfo.h - V6C specific TTI -------------*- C++ -*-===//
//
// Part of the V6C backend for LLVM.
//
//===----------------------------------------------------------------------===//

#ifndef LLVM_LIB_TARGET_V6C_V6CTARGETTRANSFORMINFO_H
#define LLVM_LIB_TARGET_V6C_V6CTARGETTRANSFORMINFO_H

#include "V6CTargetMachine.h"
#include "llvm/Analysis/TargetTransformInfo.h"
#include "llvm/CodeGen/BasicTTIImpl.h"

namespace llvm {

class V6CTTIImpl : public BasicTTIImplBase<V6CTTIImpl> {
  using BaseT = BasicTTIImplBase<V6CTTIImpl>;
  using TTI = TargetTransformInfo;
  friend BaseT;

  const V6CSubtarget *ST;
  const V6CTargetLowering *TLI;

  const V6CSubtarget *getST() const { return ST; }
  const V6CTargetLowering *getTLI() const { return TLI; }

public:
  explicit V6CTTIImpl(const V6CTargetMachine *TM, const Function &F)
      : BaseT(TM, F.getParent()->getDataLayout()),
        ST(TM->getSubtargetImpl(F)),
        TLI(ST->getTargetLowering()) {}

  // --- Register model ---
  unsigned getNumberOfRegisters(unsigned ClassID) const;
  TypeSize getRegisterBitWidth(TTI::RegisterKind K) const;

  // --- Addressing & LSR ---
  bool isLegalAddressingMode(Type *Ty, GlobalValue *BaseGV,
                             int64_t BaseOffset, bool HasBaseReg,
                             int64_t Scale, unsigned AddrSpace,
                             Instruction *I = nullptr) const;

  InstructionCost getAddressComputationCost(Type *Ty, ScalarEvolution *SE,
                                            const SCEV *Ptr) const;

  bool isNumRegsMajorCostOfLSR() const { return true; }

  bool isLSRCostLess(const TTI::LSRCost &C1, const TTI::LSRCost &C2) const;
};

} // namespace llvm

#endif
