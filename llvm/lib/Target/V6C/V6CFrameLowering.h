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

enum class V6COptMode;

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

private:
  /// Pick a GR16All pair whose halves are dead at MBBI for use as
  /// PUSH/POP filler when adjusting SP. Returns V6C::PSW when A+FLAGS
  /// are dead, otherwise BC/DE/HL in that fallback order, or
  /// V6C::NoRegister when none qualifies.
  Register chooseDeadPair(const MachineBasicBlock &MBB,
                          MachineBasicBlock::iterator MBBI,
                          bool IsPrologue) const;

  /// Emit an SP adjustment of |Amount| bytes at MBBI. Negative Amount
  /// allocates (prologue), positive deallocates (epilogue). Chooses
  /// between PUSH/POP x n/2, DCX/INX SP x n, or LXI+DAD+SPHL based
  /// on the dual cost model (O11) and register liveness.
  void emitSPAdjustment(MachineBasicBlock &MBB,
                        MachineBasicBlock::iterator MBBI,
                        int64_t Amount, const DebugLoc &DL,
                        bool IsPrologue, V6COptMode Mode) const;
};

} // namespace llvm

#endif // LLVM_LIB_TARGET_V6C_V6CFRAMELOWERING_H
