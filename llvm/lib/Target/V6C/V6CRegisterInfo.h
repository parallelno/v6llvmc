//===-- V6CRegisterInfo.h - V6C Register Information -----------*- C++ -*-===//
//
// Part of the V6C backend for LLVM.
//
//===----------------------------------------------------------------------===//

#ifndef LLVM_LIB_TARGET_V6C_V6CREGISTERINFO_H
#define LLVM_LIB_TARGET_V6C_V6CREGISTERINFO_H

#include "llvm/CodeGen/TargetRegisterInfo.h"

#define GET_REGINFO_HEADER
#include "V6CGenRegisterInfo.inc"

namespace llvm {

class V6CRegisterInfo : public V6CGenRegisterInfo {
public:
  V6CRegisterInfo();

  const MCPhysReg *getCalleeSavedRegs(const MachineFunction *MF) const override;
  const uint32_t *getCallPreservedMask(const MachineFunction &MF,
                                       CallingConv::ID CC) const override;
  BitVector getReservedRegs(const MachineFunction &MF) const override;
  bool eliminateFrameIndex(MachineBasicBlock::iterator MI, int SPAdj,
                           unsigned FIOperandNum,
                           RegScavenger *RS = nullptr) const override;
  Register getFrameRegister(const MachineFunction &MF) const override;
};

} // namespace llvm

#endif // LLVM_LIB_TARGET_V6C_V6CREGISTERINFO_H
