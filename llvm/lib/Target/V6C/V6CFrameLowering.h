//===-- V6CFrameLowering.h - V6C Frame Lowering ----------------*- C++ -*-===//
//
// Part of the V6C backend for LLVM.
//
// M5: Frame Lowering & Calling Convention.
//
// The 8080 has no frame pointer register and no base+offset addressing.
// SP is adjusted via LXI+DAD+SPHL. When a frame pointer is needed
// (alloca, -fno-omit-frame-pointer), BC is reserved as the FP.
//
//===----------------------------------------------------------------------===//

#ifndef LLVM_LIB_TARGET_V6C_V6CFRAMELOWERING_H
#define LLVM_LIB_TARGET_V6C_V6CFRAMELOWERING_H

#include "llvm/CodeGen/TargetFrameLowering.h"

namespace llvm {

class V6CFrameLowering : public TargetFrameLowering {
public:
  V6CFrameLowering()
      : TargetFrameLowering(StackGrowsDown, /*StackAlign=*/Align(1),
                            /*LocalAreaOffset=*/0) {}

  void emitPrologue(MachineFunction &MF,
                    MachineBasicBlock &MBB) const override;
  void emitEpilogue(MachineFunction &MF,
                    MachineBasicBlock &MBB) const override;
  bool hasFP(const MachineFunction &MF) const override;

  MachineBasicBlock::iterator
  eliminateCallFramePseudoInstr(MachineFunction &MF, MachineBasicBlock &MBB,
                                MachineBasicBlock::iterator I) const override;
};

} // namespace llvm

#endif // LLVM_LIB_TARGET_V6C_V6CFRAMELOWERING_H
