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
#include "V6CInstrCost.h"
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

// Pick a GR16All pair whose halves are dead at MBBI. PSW (A+FLAGS) is
// preferred — at function boundaries A is typically dead unless it is
// the i8 arg-1 / i8 return register, and FLAGS is always dead.
Register V6CFrameLowering::chooseDeadPair(const MachineBasicBlock &MBB,
                                          MachineBasicBlock::iterator MBBI,
                                          bool IsPrologue) const {
  if (IsPrologue) {
    // At entry: a half is "live" iff it appears in the MBB live-in set.
    auto IsLive = [&](unsigned R) { return MBB.isLiveIn(R); };
    bool ALive = IsLive(V6C::A);
    bool BLive = IsLive(V6C::B) || IsLive(V6C::BC);
    bool CLive = IsLive(V6C::C) || IsLive(V6C::BC);
    bool DLive = IsLive(V6C::D) || IsLive(V6C::DE);
    bool ELive = IsLive(V6C::E) || IsLive(V6C::DE);
    bool HLive = IsLive(V6C::H) || IsLive(V6C::HL);
    bool LLive = IsLive(V6C::L) || IsLive(V6C::HL);
    if (!ALive)               return V6C::PSW;
    if (!BLive && !CLive)     return V6C::BC;
    if (!DLive && !ELive)     return V6C::DE;
    if (!HLive && !LLive)     return V6C::HL;
    return V6C::NoRegister;
  }

  // Epilogue: a half is "live" iff it is used by the terminating RET.
  bool AUsed = false, BUsed = false, CUsed = false;
  bool DUsed = false, EUsed = false, HUsed = false, LUsed = false;
  if (MBBI != MBB.end() && MBBI->isReturn()) {
    for (const MachineOperand &MO : MBBI->operands()) {
      if (!MO.isReg()) continue;
      Register R = MO.getReg();
      if (R == V6C::A)                          AUsed = true;
      if (R == V6C::B  || R == V6C::BC)         BUsed = true;
      if (R == V6C::C  || R == V6C::BC)         CUsed = true;
      if (R == V6C::D  || R == V6C::DE)         DUsed = true;
      if (R == V6C::E  || R == V6C::DE)         EUsed = true;
      if (R == V6C::H  || R == V6C::HL)         HUsed = true;
      if (R == V6C::L  || R == V6C::HL)         LUsed = true;
    }
  }
  if (!AUsed)               return V6C::PSW;
  if (!BUsed && !CUsed)     return V6C::BC;
  if (!DUsed && !EUsed)     return V6C::DE;
  if (!HUsed && !LUsed)     return V6C::HL;
  return V6C::NoRegister;
}

void V6CFrameLowering::emitSPAdjustment(MachineBasicBlock &MBB,
                                        MachineBasicBlock::iterator MBBI,
                                        int64_t Amount, const DebugLoc &DL,
                                        bool IsPrologue,
                                        V6COptMode Mode) const {
  if (Amount == 0)
    return;

  const TargetInstrInfo &TII = *MBB.getParent()->getSubtarget().getInstrInfo();
  const uint64_t AbsN = static_cast<uint64_t>(Amount < 0 ? -Amount : Amount);

  // Tier 1 — PUSH/POP x (AbsN/2) when a dead GR16All pair is available
  // and the PUSH/POP cost beats LXI+DAD+SPHL under Mode.
  bool PushPopEligible =
      (AbsN % 2 == 0) && AbsN >= 2 &&
      (AbsN == 2 || AbsN == 4 ||
       (AbsN == 6 && Mode == V6COptMode::Size));
  if (PushPopEligible) {
    Register Pair = chooseDeadPair(MBB, MBBI, IsPrologue);
    if (Pair != V6C::NoRegister) {
      unsigned N = static_cast<unsigned>(AbsN / 2);
      for (unsigned I = 0; I < N; ++I) {
        if (IsPrologue) {
          // PUSH reads Pair; the value is undef (we just want SP-=2).
          BuildMI(MBB, MBBI, DL, TII.get(V6C::PUSH))
              .addReg(Pair, RegState::Undef);
        } else {
          // POP defines Pair; mark the def Dead.
          BuildMI(MBB, MBBI, DL, TII.get(V6C::POP))
              .addReg(Pair, RegState::Define | RegState::Dead);
        }
      }
      return;
    }
  }

  // Tier 2 — DCX SP / INX SP x AbsN. Wins over LXI on bytes and cycles
  // for AbsN in {2, 4}; ties on bytes and loses on cycles at AbsN=6.
  // Used when PUSH/POP wasn't eligible OR no dead pair was available.
  if (AbsN == 2 || AbsN == 4) {
    unsigned Op = IsPrologue ? V6C::DCX : V6C::INX;
    for (unsigned I = 0; I < AbsN; ++I) {
      // INX/DCX have a tied $rp = $src constraint: pass SP as both
      // def and use.
      BuildMI(MBB, MBBI, DL, TII.get(Op), V6C::SP).addReg(V6C::SP);
    }
    return;
  }

  // Tier 3 — LXI HL, ±N; DAD SP; SPHL. Used for AbsN >= 6 (non-Size at
  // n=6), AbsN >= 8, and any odd size. Clobbers HL and FLAGS — caller
  // is responsible for HL save/restore around this site if needed.
  int64_t LxiImm = IsPrologue ? -static_cast<int64_t>(AbsN)
                              :  static_cast<int64_t>(AbsN);
  BuildMI(MBB, MBBI, DL, TII.get(V6C::LXI))
      .addReg(V6C::HL, RegState::Define)
      .addImm(LxiImm);
  BuildMI(MBB, MBBI, DL, TII.get(V6C::DAD)).addReg(V6C::SP);
  BuildMI(MBB, MBBI, DL, TII.get(V6C::SPHL));
}

bool V6CFrameLowering::spAdjustClobbersHL(const MachineBasicBlock &MBB,
                                          MachineBasicBlock::iterator MBBI,
                                          int64_t Amount, bool IsPrologue,
                                          V6COptMode Mode) const {
  if (Amount == 0)
    return false;
  const uint64_t AbsN = static_cast<uint64_t>(Amount < 0 ? -Amount : Amount);

  // Tier 1 — PUSH/POP x (AbsN/2): does not touch HL.
  bool PushPopEligible =
      (AbsN % 2 == 0) && AbsN >= 2 &&
      (AbsN == 2 || AbsN == 4 ||
       (AbsN == 6 && Mode == V6COptMode::Size));
  if (PushPopEligible &&
      chooseDeadPair(MBB, MBBI, IsPrologue) != V6C::NoRegister)
    return false;

  // Tier 2 — DCX/INX SP x AbsN for AbsN in {2, 4}: does not touch HL.
  if (AbsN == 2 || AbsN == 4)
    return false;

  // Tier 3 — LXI HL, ±N; DAD SP; SPHL: clobbers HL.
  return true;
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
  V6COptMode Mode = getV6COptMode(MF);

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
      emitSPAdjustment(MBB, MBBI, -static_cast<int64_t>(OrigStackSize), DL,
                       /*IsPrologue=*/true, Mode);
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
  // The save is only needed if HL will actually be clobbered by either the
  // FP setup (LXI 0; DAD SP) or the SP-adjust tier picked below.
  bool NeedHLSave = HLIsLiveIn && !DEIsLiveIn && NeedSPAdjust;
  bool HLClobberedByAdjust =
      StackSize > 0 &&
      spAdjustClobbersHL(MBB, MBBI, -static_cast<int64_t>(StackSize),
                         /*IsPrologue=*/true, Mode);
  bool DoSave = NeedHLSave && (UseFP || HLClobberedByAdjust);
  if (DoSave) {
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
    if (DoSave) {
      BuildMI(MBB, MBBI, DL, TII.get(V6C::MOVrr))
          .addReg(V6C::H, RegState::Define).addReg(V6C::D);
      BuildMI(MBB, MBBI, DL, TII.get(V6C::MOVrr))
          .addReg(V6C::L, RegState::Define).addReg(V6C::E);
    }
    return;
  }

  emitSPAdjustment(MBB, MBBI, -static_cast<int64_t>(StackSize), DL,
                   /*IsPrologue=*/true, Mode);

  if (DoSave) {
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
  V6COptMode Mode = getV6COptMode(MF);

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

  // Only save HL if the SP-adjust tier we'll pick actually clobbers it.
  // Tier 1 (PUSH/POP PSW/...) and Tier 2 (DCX/INX SP) leave HL alone.
  bool ClobbersHL = spAdjustClobbersHL(MBB, MBBI,
                                       static_cast<int64_t>(StackSize),
                                       /*IsPrologue=*/false, Mode);
  bool DoSave = NeedHLSave && ClobbersHL;
  if (DoSave) {
    BuildMI(MBB, MBBI, DL, TII.get(V6C::MOVrr))
        .addReg(V6C::D, RegState::Define)
        .addReg(V6C::H);
    BuildMI(MBB, MBBI, DL, TII.get(V6C::MOVrr))
        .addReg(V6C::E, RegState::Define)
        .addReg(V6C::L);
  }
  // Adjust SP back: SP += StackSize. Helper picks PUSH/POP, DCX/INX SP,
  // or LXI+DAD+SPHL based on size, opt mode, and register pressure.
  emitSPAdjustment(MBB, MBBI, static_cast<int64_t>(StackSize), DL,
                   /*IsPrologue=*/false, Mode);
  if (DoSave) {
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
