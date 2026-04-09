//===-- V6CFrameLowering.cpp - V6C Frame Lowering -------------------------===//
//
// Part of the V6C backend for LLVM.
//
// M5: Frame Lowering & Calling Convention.
//
// 8080 stack frame lowering. The 8080 has no frame pointer or
// stack-relative addressing, so we adjust SP via LXI+DAD sequences.
//
// When a frame pointer is needed (alloca, -fno-omit-frame-pointer),
// BC is reserved as the FP and saved/restored in prologue/epilogue.
//
//===----------------------------------------------------------------------===//

#include "V6CFrameLowering.h"
#include "V6C.h"
#include "MCTargetDesc/V6CMCTargetDesc.h"
#include "llvm/CodeGen/MachineFrameInfo.h"
#include "llvm/CodeGen/MachineFunction.h"
#include "llvm/CodeGen/MachineInstrBuilder.h"
#include "llvm/CodeGen/TargetInstrInfo.h"
#include "llvm/CodeGen/TargetSubtargetInfo.h"
#include "llvm/IR/Function.h"

using namespace llvm;

bool V6CFrameLowering::hasFP(const MachineFunction &MF) const {
  const MachineFrameInfo &MFI = MF.getFrameInfo();
  return MF.getTarget().Options.DisableFramePointerElim(MF) ||
         MFI.hasVarSizedObjects() ||
         MFI.isFrameAddressTaken();
}

// Emit prologue: subtract the stack frame size from SP.
// On 8080 there is no SUB SP,imm, so we use:
//   LXI HL, -FrameSize
//   DAD SP
//   SPHL
//
// With frame pointer (BC):
//   PUSH BC           ; save old FP
//   LXI HL, 0
//   DAD SP
//   MOV B, H
//   MOV C, L          ; BC = SP (new frame pointer)
//   LXI HL, -FrameSize
//   DAD SP
//   SPHL
void V6CFrameLowering::emitPrologue(MachineFunction &MF,
                                     MachineBasicBlock &MBB) const {
  MachineFrameInfo &MFI = MF.getFrameInfo();
  uint64_t StackSize = MFI.getStackSize();
  bool UseFP = hasFP(MF);

  const TargetInstrInfo &TII = *MF.getSubtarget().getInstrInfo();
  MachineBasicBlock::iterator MBBI = MBB.begin();
  DebugLoc DL;
  if (MBBI != MBB.end())
    DL = MBBI->getDebugLoc();

  // The prologue uses HL as scratch (LXI+DAD+SPHL) to adjust SP.
  // Determine which argument registers need saving.
  bool HLIsLiveIn = MBB.isLiveIn(V6C::HL) || MBB.isLiveIn(V6C::H) ||
                    MBB.isLiveIn(V6C::L);
  bool DEIsLiveIn = MBB.isLiveIn(V6C::DE) || MBB.isLiveIn(V6C::D) ||
                    MBB.isLiveIn(V6C::E);
  bool NeedSPAdjust = UseFP || StackSize > 0;

  // Case 1: Both HL and DE are live-in. Save via PUSH, reload after frame setup.
  if (HLIsLiveIn && DEIsLiveIn && NeedSPAdjust) {
    // Save both arg register pairs on the stack.
    BuildMI(MBB, MBBI, DL, TII.get(V6C::PUSH)).addReg(V6C::HL);
    BuildMI(MBB, MBBI, DL, TII.get(V6C::PUSH)).addReg(V6C::DE);
    // Account for the 4 extra bytes in the total stack size so that
    // eliminateFrameIndex computes correct SP-relative offsets.
    uint64_t OrigStackSize = StackSize;
    StackSize += 4;
    MFI.setStackSize(StackSize);

    if (UseFP) {
      BuildMI(MBB, MBBI, DL, TII.get(V6C::PUSH)).addReg(V6C::BC);
      BuildMI(MBB, MBBI, DL, TII.get(V6C::LXI))
          .addReg(V6C::HL, RegState::Define).addImm(0);
      BuildMI(MBB, MBBI, DL, TII.get(V6C::DAD)).addReg(V6C::SP);
      BuildMI(MBB, MBBI, DL, TII.get(V6C::MOVrr))
          .addReg(V6C::B, RegState::Define).addReg(V6C::H);
      BuildMI(MBB, MBBI, DL, TII.get(V6C::MOVrr))
          .addReg(V6C::C, RegState::Define).addReg(V6C::L);
    }

    if (OrigStackSize > 0) {
      BuildMI(MBB, MBBI, DL, TII.get(V6C::LXI))
          .addReg(V6C::HL, RegState::Define)
          .addImm(-static_cast<int64_t>(OrigStackSize));
      BuildMI(MBB, MBBI, DL, TII.get(V6C::DAD)).addReg(V6C::SP);
      BuildMI(MBB, MBBI, DL, TII.get(V6C::SPHL));
    }

    // Reload saved DE from stack: at SP + OrigStackSize.
    BuildMI(MBB, MBBI, DL, TII.get(V6C::LXI))
        .addReg(V6C::HL, RegState::Define)
        .addImm(static_cast<int64_t>(OrigStackSize));
    BuildMI(MBB, MBBI, DL, TII.get(V6C::DAD)).addReg(V6C::SP);
    BuildMI(MBB, MBBI, DL, TII.get(V6C::MOVrM))
        .addReg(V6C::E, RegState::Define);
    BuildMI(MBB, MBBI, DL, TII.get(V6C::INX), V6C::HL).addReg(V6C::HL);
    BuildMI(MBB, MBBI, DL, TII.get(V6C::MOVrM))
        .addReg(V6C::D, RegState::Define);
    // Reload saved HL: at SP + OrigStackSize + 2 (next 2 bytes on stack).
    BuildMI(MBB, MBBI, DL, TII.get(V6C::INX), V6C::HL).addReg(V6C::HL);
    BuildMI(MBB, MBBI, DL, TII.get(V6C::MOVrM))
        .addReg(V6C::A, RegState::Define);   // A = saved L
    BuildMI(MBB, MBBI, DL, TII.get(V6C::INX), V6C::HL).addReg(V6C::HL);
    BuildMI(MBB, MBBI, DL, TII.get(V6C::MOVrM))
        .addReg(V6C::H, RegState::Define);   // H = saved H (from [HL])
    BuildMI(MBB, MBBI, DL, TII.get(V6C::MOVrr))
        .addReg(V6C::L, RegState::Define)
        .addReg(V6C::A);                     // L = saved L (from A)
    return;
  }

  // Case 2: Only HL is live-in (DE is free). Save HL to DE via MOV pairs.
  bool NeedHLSave = HLIsLiveIn && !DEIsLiveIn && NeedSPAdjust;
  if (NeedHLSave) {
    BuildMI(MBB, MBBI, DL, TII.get(V6C::MOVrr))
        .addReg(V6C::D, RegState::Define).addReg(V6C::H);
    BuildMI(MBB, MBBI, DL, TII.get(V6C::MOVrr))
        .addReg(V6C::E, RegState::Define).addReg(V6C::L);
  }

  if (UseFP) {
    BuildMI(MBB, MBBI, DL, TII.get(V6C::PUSH)).addReg(V6C::BC);
    BuildMI(MBB, MBBI, DL, TII.get(V6C::LXI))
        .addReg(V6C::HL, RegState::Define).addImm(0);
    BuildMI(MBB, MBBI, DL, TII.get(V6C::DAD)).addReg(V6C::SP);
    BuildMI(MBB, MBBI, DL, TII.get(V6C::MOVrr))
        .addReg(V6C::B, RegState::Define).addReg(V6C::H);
    BuildMI(MBB, MBBI, DL, TII.get(V6C::MOVrr))
        .addReg(V6C::C, RegState::Define).addReg(V6C::L);
  }

  if (StackSize == 0) {
    if (NeedHLSave) {
      BuildMI(MBB, MBBI, DL, TII.get(V6C::MOVrr))
          .addReg(V6C::H, RegState::Define).addReg(V6C::D);
      BuildMI(MBB, MBBI, DL, TII.get(V6C::MOVrr))
          .addReg(V6C::L, RegState::Define).addReg(V6C::E);
    }
    return;
  }

  BuildMI(MBB, MBBI, DL, TII.get(V6C::LXI))
      .addReg(V6C::HL, RegState::Define)
      .addImm(-static_cast<int64_t>(StackSize));
  BuildMI(MBB, MBBI, DL, TII.get(V6C::DAD)).addReg(V6C::SP);
  BuildMI(MBB, MBBI, DL, TII.get(V6C::SPHL));

  if (NeedHLSave) {
    BuildMI(MBB, MBBI, DL, TII.get(V6C::MOVrr))
        .addReg(V6C::H, RegState::Define).addReg(V6C::D);
    BuildMI(MBB, MBBI, DL, TII.get(V6C::MOVrr))
        .addReg(V6C::L, RegState::Define).addReg(V6C::E);
  }
}

// Emit epilogue: add the stack frame size back to SP.
// Same approach: LXI HL, FrameSize; DAD SP; SPHL
//
// With frame pointer:
//   MOV H, B
//   MOV L, C          ; HL = BC (frame pointer = original SP)
//   SPHL              ; SP = HL (restore SP)
//   POP BC            ; restore old FP
//
// If HL carries a return value (i16/ptr), the epilogue must preserve it
// by saving to DE (MOV D,H; MOV E,L) and restoring after SP adjustment.
void V6CFrameLowering::emitEpilogue(MachineFunction &MF,
                                     MachineBasicBlock &MBB) const {
  MachineFrameInfo &MFI = MF.getFrameInfo();
  uint64_t StackSize = MFI.getStackSize();
  bool UseFP = hasFP(MF);

  const TargetInstrInfo &TII = *MF.getSubtarget().getInstrInfo();
  MachineBasicBlock::iterator MBBI = MBB.getLastNonDebugInstr();
  DebugLoc DL;
  if (MBBI != MBB.end())
    DL = MBBI->getDebugLoc();

  // Check if HL carries a return value by inspecting the RET instruction.
  // Also check DE — if both carry return values (i32), we can't use DE as
  // scratch and must skip the save (TODO: handle i32 returns).
  bool HLUsedByRet = false;
  bool DEUsedByRet = false;
  if (MBBI != MBB.end() && MBBI->isReturn()) {
    for (const MachineOperand &MO : MBBI->operands()) {
      if (!MO.isReg()) continue;
      if (MO.getReg() == V6C::HL || MO.getReg() == V6C::H ||
          MO.getReg() == V6C::L)
        HLUsedByRet = true;
      if (MO.getReg() == V6C::DE || MO.getReg() == V6C::D ||
          MO.getReg() == V6C::E)
        DEUsedByRet = true;
    }
  }
  bool NeedHLSave = HLUsedByRet && !DEUsedByRet;

  if (UseFP) {
    if (NeedHLSave) {
      BuildMI(MBB, MBBI, DL, TII.get(V6C::MOVrr))
          .addReg(V6C::D, RegState::Define)
          .addReg(V6C::H);
      BuildMI(MBB, MBBI, DL, TII.get(V6C::MOVrr))
          .addReg(V6C::E, RegState::Define)
          .addReg(V6C::L);
    }
    // Restore SP from frame pointer: HL = BC; SPHL; POP BC
    BuildMI(MBB, MBBI, DL, TII.get(V6C::MOVrr))
        .addReg(V6C::H, RegState::Define)
        .addReg(V6C::B);
    BuildMI(MBB, MBBI, DL, TII.get(V6C::MOVrr))
        .addReg(V6C::L, RegState::Define)
        .addReg(V6C::C);
    BuildMI(MBB, MBBI, DL, TII.get(V6C::SPHL));
    BuildMI(MBB, MBBI, DL, TII.get(V6C::POP))
        .addReg(V6C::BC, RegState::Define);
    if (NeedHLSave) {
      BuildMI(MBB, MBBI, DL, TII.get(V6C::MOVrr))
          .addReg(V6C::H, RegState::Define)
          .addReg(V6C::D);
      BuildMI(MBB, MBBI, DL, TII.get(V6C::MOVrr))
          .addReg(V6C::L, RegState::Define)
          .addReg(V6C::E);
    }
    return;
  }

  if (StackSize == 0)
    return;

  if (NeedHLSave) {
    BuildMI(MBB, MBBI, DL, TII.get(V6C::MOVrr))
        .addReg(V6C::D, RegState::Define)
        .addReg(V6C::H);
    BuildMI(MBB, MBBI, DL, TII.get(V6C::MOVrr))
        .addReg(V6C::E, RegState::Define)
        .addReg(V6C::L);
  }
  // LXI HL, StackSize
  BuildMI(MBB, MBBI, DL, TII.get(V6C::LXI))
      .addReg(V6C::HL, RegState::Define)
      .addImm(static_cast<int64_t>(StackSize));
  // DAD SP  (HL = HL + SP = SP + StackSize)
  BuildMI(MBB, MBBI, DL, TII.get(V6C::DAD))
      .addReg(V6C::SP);
  // SPHL  (SP = HL)
  BuildMI(MBB, MBBI, DL, TII.get(V6C::SPHL));
  if (NeedHLSave) {
    BuildMI(MBB, MBBI, DL, TII.get(V6C::MOVrr))
        .addReg(V6C::H, RegState::Define)
        .addReg(V6C::D);
    BuildMI(MBB, MBBI, DL, TII.get(V6C::MOVrr))
        .addReg(V6C::L, RegState::Define)
        .addReg(V6C::E);
  }
}

MachineBasicBlock::iterator V6CFrameLowering::eliminateCallFramePseudoInstr(
    MachineFunction &MF, MachineBasicBlock &MBB,
    MachineBasicBlock::iterator I) const {
  // ADJCALLSTACKDOWN / ADJCALLSTACKUP are markers.
  // On V6C, stack arguments are pushed via explicit PUSH / store instructions
  // generated during call lowering. The pseudo-instructions are simply erased.
  // If the call frame is not reserved in the local frame (has calls and no FP),
  // we would need to adjust SP here. For now, callers manage SP explicitly.
  return MBB.erase(I);
}
