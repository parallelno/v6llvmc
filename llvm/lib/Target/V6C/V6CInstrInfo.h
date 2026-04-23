//===-- V6CInstrInfo.h - V6C Instruction Information -----------*- C++ -*-===//
//
// Part of the V6C backend for LLVM.
//
//===----------------------------------------------------------------------===//

#ifndef LLVM_LIB_TARGET_V6C_V6CINSTRINFO_H
#define LLVM_LIB_TARGET_V6C_V6CINSTRINFO_H

#include "V6CRegisterInfo.h"
#include "llvm/CodeGen/TargetInstrInfo.h"

#define GET_INSTRINFO_HEADER
#include "V6CGenInstrInfo.inc"
#undef GET_INSTRINFO_HEADER

namespace llvm {

/// V6C target operand flags for MachineOperand::getTargetFlags().
namespace V6CII {
enum {
  MO_NO_FLAG = 0,
  MO_LO8 = 1, // Low byte of 16-bit value
  MO_HI8 = 2, // High byte of 16-bit value
  MO_PATCH_IMM = 4, // O61: operand is an MCSymbol pointing at a patched
                    // reload site; lower as `Sym + 1` (the imm field).
};
} // namespace V6CII

class V6CInstrInfo : public V6CGenInstrInfo {
  const V6CRegisterInfo RI;

public:
  V6CInstrInfo();

  const V6CRegisterInfo &getRegisterInfo() const { return RI; }

  void copyPhysReg(MachineBasicBlock &MBB, MachineBasicBlock::iterator MI,
                   const DebugLoc &DL, MCRegister DestReg, MCRegister SrcReg,
                   bool KillSrc) const override;

  void storeRegToStackSlot(MachineBasicBlock &MBB,
                           MachineBasicBlock::iterator MI, Register SrcReg,
                           bool isKill, int FrameIndex,
                           const TargetRegisterClass *RC,
                           const TargetRegisterInfo *TRI,
                           Register VReg) const override;

  void loadRegFromStackSlot(MachineBasicBlock &MBB,
                            MachineBasicBlock::iterator MI, Register DestReg,
                            int FrameIndex, const TargetRegisterClass *RC,
                            const TargetRegisterInfo *TRI,
                            Register VReg) const override;

  bool expandPostRAPseudo(MachineInstr &MI) const override;

  bool analyzeBranch(MachineBasicBlock &MBB, MachineBasicBlock *&TBB,
                     MachineBasicBlock *&FBB,
                     SmallVectorImpl<MachineOperand> &Cond,
                     bool AllowModify = false) const override;

  unsigned removeBranch(MachineBasicBlock &MBB,
                        int *BytesRemoved = nullptr) const override;

  unsigned insertBranch(MachineBasicBlock &MBB, MachineBasicBlock *TBB,
                        MachineBasicBlock *FBB,
                        ArrayRef<MachineOperand> Cond,
                        const DebugLoc &DL,
                        int *BytesAdded = nullptr) const override;

  bool
  reverseBranchCondition(SmallVectorImpl<MachineOperand> &Cond) const override;
};

} // namespace llvm

#endif // LLVM_LIB_TARGET_V6C_V6CINSTRINFO_H
