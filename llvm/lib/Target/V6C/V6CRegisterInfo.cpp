//===-- V6CRegisterInfo.cpp - V6C Register Information --------------------===//
//
// Part of the V6C backend for LLVM.
//
//===----------------------------------------------------------------------===//

#include "V6CRegisterInfo.h"
#include "V6C.h"
#include "V6CFrameLowering.h"
#include "MCTargetDesc/V6CMCTargetDesc.h"
#include "llvm/CodeGen/MachineFunction.h"
#include "llvm/CodeGen/MachineFrameInfo.h"
#include "llvm/CodeGen/MachineInstrBuilder.h"
#include "llvm/CodeGen/TargetInstrInfo.h"
#include "llvm/CodeGen/TargetSubtargetInfo.h"

#define GET_REGINFO_TARGET_DESC
#include "V6CGenRegisterInfo.inc"

using namespace llvm;

V6CRegisterInfo::V6CRegisterInfo() : V6CGenRegisterInfo(/*RA=*/0) {}

const MCPhysReg *
V6CRegisterInfo::getCalleeSavedRegs(const MachineFunction *MF) const {
  // Per design §6.1: no callee-saved registers — all are caller-saved.
  static const MCPhysReg CalleeSavedRegs[] = {0};
  return CalleeSavedRegs;
}

const uint32_t *
V6CRegisterInfo::getCallPreservedMask(const MachineFunction &MF,
                                       CallingConv::ID CC) const {
  // No registers are preserved across calls.
  static const uint32_t Mask[(V6C::NUM_TARGET_REGS + 31) / 32] = {0};
  return Mask;
}

BitVector V6CRegisterInfo::getReservedRegs(const MachineFunction &MF) const {
  BitVector Reserved(getNumRegs());
  Reserved.set(V6C::SP);
  Reserved.set(V6C::FLAGS);
  Reserved.set(V6C::PSW);

  // When using a frame pointer, reserve BC (and its sub-registers B, C).
  const V6CFrameLowering *TFI = static_cast<const V6CFrameLowering *>(
      MF.getSubtarget().getFrameLowering());
  if (TFI->hasFP(MF)) {
    Reserved.set(V6C::BC);
    Reserved.set(V6C::B);
    Reserved.set(V6C::C);
  }

  return Reserved;
}

bool V6CRegisterInfo::eliminateFrameIndex(MachineBasicBlock::iterator II,
                                           int SPAdj,
                                           unsigned FIOperandNum,
                                           RegScavenger *RS) const {
  MachineInstr &MI = *II;
  MachineBasicBlock &MBB = *MI.getParent();
  MachineFunction &MF = *MBB.getParent();
  const MachineFrameInfo &MFI = MF.getFrameInfo();
  const TargetInstrInfo &TII = *MF.getSubtarget().getInstrInfo();
  DebugLoc DL = MI.getDebugLoc();

  int FrameIndex = MI.getOperand(FIOperandNum).getIndex();
  int Offset = MFI.getObjectOffset(FrameIndex) + MFI.getStackSize() + SPAdj;

  unsigned Opc = MI.getOpcode();
  if (Opc == V6C::V6C_LEA_FI) {
    // Expand: LXI $dst, offset; DAD SP
    // Note: DAD always uses HL, so $dst must be HL (regalloc should ensure this).
    Register DstReg = MI.getOperand(0).getReg();
    BuildMI(MBB, II, DL, TII.get(V6C::LXI))
        .addReg(DstReg, RegState::Define)
        .addImm(Offset);
    BuildMI(MBB, II, DL, TII.get(V6C::DAD))
        .addReg(V6C::SP);
    MI.eraseFromParent();
    return true;
  }

  if (Opc == V6C::V6C_SPILL8) {
    // Expand: PUSH HL; LXI HL, offset+2; DAD SP; MOV M, r; POP HL
    // PUSH/POP preserves HL so the RA doesn't see HL clobbered.
    Register SrcReg = MI.getOperand(0).getReg();
    bool SrcIsHorL = (SrcReg == V6C::H || SrcReg == V6C::L);
    if (SrcIsHorL) {
      // Spilling H or L: use DE as temp to avoid clobbering A.
      // Save DE, copy H/L pair into D/E, use HL for address, store, restore.
      bool SpillingH = (SrcReg == V6C::H);
      Register ValReg = SpillingH ? V6C::D : V6C::E;
      Register OtherReg = SpillingH ? V6C::E : V6C::D;
      Register OtherHL = SpillingH ? V6C::L : V6C::H;
      BuildMI(MBB, II, DL, TII.get(V6C::PUSH)).addReg(V6C::DE);
      BuildMI(MBB, II, DL, TII.get(V6C::MOVrr))
          .addReg(ValReg, RegState::Define).addReg(SrcReg);
      BuildMI(MBB, II, DL, TII.get(V6C::MOVrr))
          .addReg(OtherReg, RegState::Define).addReg(OtherHL);
      BuildMI(MBB, II, DL, TII.get(V6C::LXI))
          .addReg(V6C::HL, RegState::Define).addImm(Offset + 2);
      BuildMI(MBB, II, DL, TII.get(V6C::DAD)).addReg(V6C::SP);
      BuildMI(MBB, II, DL, TII.get(V6C::MOVMr)).addReg(ValReg);
      // Restore HL from D/E.
      BuildMI(MBB, II, DL, TII.get(V6C::MOVrr))
          .addReg(V6C::H, RegState::Define).addReg(V6C::D);
      BuildMI(MBB, II, DL, TII.get(V6C::MOVrr))
          .addReg(V6C::L, RegState::Define).addReg(V6C::E);
      BuildMI(MBB, II, DL, TII.get(V6C::POP), V6C::DE);
    } else {
      BuildMI(MBB, II, DL, TII.get(V6C::PUSH)).addReg(V6C::HL);
      BuildMI(MBB, II, DL, TII.get(V6C::LXI))
          .addReg(V6C::HL, RegState::Define).addImm(Offset + 2);
      BuildMI(MBB, II, DL, TII.get(V6C::DAD)).addReg(V6C::SP);
      BuildMI(MBB, II, DL, TII.get(V6C::MOVMr))
          .addReg(SrcReg, getKillRegState(MI.getOperand(0).isKill()));
      BuildMI(MBB, II, DL, TII.get(V6C::POP), V6C::HL);
    }
    MI.eraseFromParent();
    return true;
  }

  if (Opc == V6C::V6C_RELOAD8) {
    // Expand: PUSH HL; LXI HL, offset+2; DAD SP; MOV r, M; POP HL
    // PUSH/POP preserves HL so the RA doesn't see HL clobbered.
    Register DstReg = MI.getOperand(0).getReg();
    bool DstIsHorL = (DstReg == V6C::H || DstReg == V6C::L);
    if (DstIsHorL) {
      // Reloading into H or L: use DE as temp to avoid clobbering A.
      // Save DE, save the non-target half of HL in D, load via LXI+DAD,
      // use MOV H/L,M (8080 latches address before write), restore.
      bool LoadingH = (DstReg == V6C::H);
      Register SaveOther = V6C::D; // temp for non-target half
      Register OtherHL = LoadingH ? V6C::L : V6C::H;
      BuildMI(MBB, II, DL, TII.get(V6C::PUSH)).addReg(V6C::DE);
      BuildMI(MBB, II, DL, TII.get(V6C::MOVrr))
          .addReg(SaveOther, RegState::Define).addReg(OtherHL);
      BuildMI(MBB, II, DL, TII.get(V6C::LXI))
          .addReg(V6C::HL, RegState::Define).addImm(Offset + 2);
      BuildMI(MBB, II, DL, TII.get(V6C::DAD)).addReg(V6C::SP);
      // MOV H,M / MOV L,M: 8080 latches [HL] address before writing dst.
      BuildMI(MBB, II, DL, TII.get(V6C::MOVrM))
          .addReg(DstReg, RegState::Define);
      // Restore the non-target half.
      BuildMI(MBB, II, DL, TII.get(V6C::MOVrr))
          .addReg(OtherHL, RegState::Define).addReg(SaveOther);
      BuildMI(MBB, II, DL, TII.get(V6C::POP), V6C::DE);
    } else {
      BuildMI(MBB, II, DL, TII.get(V6C::PUSH)).addReg(V6C::HL);
      BuildMI(MBB, II, DL, TII.get(V6C::LXI))
          .addReg(V6C::HL, RegState::Define).addImm(Offset + 2);
      BuildMI(MBB, II, DL, TII.get(V6C::DAD)).addReg(V6C::SP);
      BuildMI(MBB, II, DL, TII.get(V6C::MOVrM))
          .addReg(DstReg, RegState::Define);
      BuildMI(MBB, II, DL, TII.get(V6C::POP), V6C::HL);
    }
    MI.eraseFromParent();
    return true;
  }

  if (Opc == V6C::V6C_SPILL16) {
    // Expand: store 16-bit register to stack slot.
    // All paths preserve registers OTHER than the src (if killed) and FLAGS.
    Register SrcReg = MI.getOperand(0).getReg();
    bool IsKill = MI.getOperand(0).isKill();

    if (SrcReg == V6C::HL) {
      // Spilling HL: save DE, copy HL→DE, use HL for addressing, restore.
      BuildMI(MBB, II, DL, TII.get(V6C::PUSH)).addReg(V6C::DE);
      BuildMI(MBB, II, DL, TII.get(V6C::MOVrr))
          .addReg(V6C::D, RegState::Define).addReg(V6C::H);
      BuildMI(MBB, II, DL, TII.get(V6C::MOVrr))
          .addReg(V6C::E, RegState::Define).addReg(V6C::L);
      BuildMI(MBB, II, DL, TII.get(V6C::LXI))
          .addReg(V6C::HL, RegState::Define).addImm(Offset + 2);
      BuildMI(MBB, II, DL, TII.get(V6C::DAD)).addReg(V6C::SP);
      BuildMI(MBB, II, DL, TII.get(V6C::MOVMr)).addReg(V6C::E);
      BuildMI(MBB, II, DL, TII.get(V6C::INX), V6C::HL).addReg(V6C::HL);
      BuildMI(MBB, II, DL, TII.get(V6C::MOVMr)).addReg(V6C::D);
      if (!IsKill) {
        // Restore HL from DE.
        BuildMI(MBB, II, DL, TII.get(V6C::MOVrr))
            .addReg(V6C::H, RegState::Define).addReg(V6C::D);
        BuildMI(MBB, II, DL, TII.get(V6C::MOVrr))
            .addReg(V6C::L, RegState::Define).addReg(V6C::E);
      }
      BuildMI(MBB, II, DL, TII.get(V6C::POP), V6C::DE);
    } else {
      // Spilling DE or BC: save HL, use HL for addressing, restore.
      MCRegister SrcLo = getSubReg(SrcReg, V6C::sub_lo);
      MCRegister SrcHi = getSubReg(SrcReg, V6C::sub_hi);
      BuildMI(MBB, II, DL, TII.get(V6C::PUSH)).addReg(V6C::HL);
      BuildMI(MBB, II, DL, TII.get(V6C::LXI))
          .addReg(V6C::HL, RegState::Define).addImm(Offset + 2);
      BuildMI(MBB, II, DL, TII.get(V6C::DAD)).addReg(V6C::SP);
      BuildMI(MBB, II, DL, TII.get(V6C::MOVMr))
          .addReg(SrcLo, getKillRegState(IsKill));
      BuildMI(MBB, II, DL, TII.get(V6C::INX), V6C::HL).addReg(V6C::HL);
      BuildMI(MBB, II, DL, TII.get(V6C::MOVMr))
          .addReg(SrcHi, getKillRegState(IsKill));
      BuildMI(MBB, II, DL, TII.get(V6C::POP), V6C::HL);
    }
    MI.eraseFromParent();
    return true;
  }

  if (Opc == V6C::V6C_RELOAD16) {
    // Expand: load 16-bit register from stack slot.
    // All paths preserve registers OTHER than the dst and FLAGS.
    Register DstReg = MI.getOperand(0).getReg();

    if (DstReg == V6C::HL) {
      // Reloading into HL: save DE, load via HL into DE, copy to HL, restore.
      BuildMI(MBB, II, DL, TII.get(V6C::PUSH)).addReg(V6C::DE);
      BuildMI(MBB, II, DL, TII.get(V6C::LXI))
          .addReg(V6C::HL, RegState::Define).addImm(Offset + 2);
      BuildMI(MBB, II, DL, TII.get(V6C::DAD)).addReg(V6C::SP);
      BuildMI(MBB, II, DL, TII.get(V6C::MOVrM))
          .addReg(V6C::E, RegState::Define);
      BuildMI(MBB, II, DL, TII.get(V6C::INX), V6C::HL).addReg(V6C::HL);
      BuildMI(MBB, II, DL, TII.get(V6C::MOVrM))
          .addReg(V6C::D, RegState::Define);
      BuildMI(MBB, II, DL, TII.get(V6C::MOVrr))
          .addReg(V6C::H, RegState::Define).addReg(V6C::D);
      BuildMI(MBB, II, DL, TII.get(V6C::MOVrr))
          .addReg(V6C::L, RegState::Define).addReg(V6C::E);
      BuildMI(MBB, II, DL, TII.get(V6C::POP), V6C::DE);
    } else {
      // Reloading into DE or BC: save HL, load, restore HL.
      MCRegister LoadLo = getSubReg(DstReg, V6C::sub_lo);
      MCRegister LoadHi = getSubReg(DstReg, V6C::sub_hi);
      BuildMI(MBB, II, DL, TII.get(V6C::PUSH)).addReg(V6C::HL);
      BuildMI(MBB, II, DL, TII.get(V6C::LXI))
          .addReg(V6C::HL, RegState::Define).addImm(Offset + 2);
      BuildMI(MBB, II, DL, TII.get(V6C::DAD)).addReg(V6C::SP);
      BuildMI(MBB, II, DL, TII.get(V6C::MOVrM))
          .addReg(LoadLo, RegState::Define);
      BuildMI(MBB, II, DL, TII.get(V6C::INX), V6C::HL).addReg(V6C::HL);
      BuildMI(MBB, II, DL, TII.get(V6C::MOVrM))
          .addReg(LoadHi, RegState::Define);
      BuildMI(MBB, II, DL, TII.get(V6C::POP), V6C::HL);
    }
    MI.eraseFromParent();
    return true;
  }

  // For other instructions with frame indices, replace the FI operand
  // with SP + offset. This is a fallback; specific pseudos are preferred.
  MI.getOperand(FIOperandNum).ChangeToImmediate(Offset);
  return false;
}

Register
V6CRegisterInfo::getFrameRegister(const MachineFunction &MF) const {
  const V6CFrameLowering *TFI = static_cast<const V6CFrameLowering *>(
      MF.getSubtarget().getFrameLowering());
  if (TFI->hasFP(MF))
    return V6C::BC;
  return V6C::SP;
}
