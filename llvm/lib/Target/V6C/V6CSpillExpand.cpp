//===-- V6CSpillExpand.cpp - Shared i8 spill/reload expander --------------===//
//
// Part of the V6C backend for LLVM.
//
// See V6CSpillExpand.h.
//
//===----------------------------------------------------------------------===//

#include "V6CSpillExpand.h"
#include "V6C.h"
#include "MCTargetDesc/V6CMCTargetDesc.h"
#include "llvm/CodeGen/MachineInstr.h"
#include "llvm/CodeGen/TargetInstrInfo.h"
#include "llvm/CodeGen/TargetRegisterInfo.h"

using namespace llvm;

bool llvm::isRegDeadAfterMI(unsigned Reg, const MachineInstr &MI,
                            MachineBasicBlock &MBB,
                            const TargetRegisterInfo *TRI) {
  for (auto I = std::next(MI.getIterator()); I != MBB.end(); ++I) {
    bool usesReg = false, defsReg = false;
    for (const MachineOperand &MO : I->operands()) {
      if (!MO.isReg() || !TRI->regsOverlap(MO.getReg(), Reg))
        continue;
      if (MO.isUse())
        usesReg = true;
      if (MO.isDef())
        defsReg = true;
    }
    if (usesReg)
      return false;
    if (defsReg)
      return true;
  }
  for (MachineBasicBlock *Succ : MBB.successors()) {
    for (MCRegAliasIterator AI(Reg, TRI, /*IncludeSelf=*/true); AI.isValid();
         ++AI) {
      if (Succ->isLiveIn(*AI))
        return false;
    }
  }
  return true;
}

Register llvm::findDeadSpareGPR8(Register Excluded, const MachineInstr &MI,
                                 MachineBasicBlock &MBB,
                                 const TargetRegisterInfo *TRI) {
  static const MCPhysReg Candidates[] = {V6C::B, V6C::C, V6C::D, V6C::E};
  for (MCPhysReg R : Candidates) {
    if (Excluded && TRI->regsOverlap(R, Excluded))
      continue;
    if (isRegDeadAfterMI(R, MI, MBB, TRI))
      return Register(R);
  }
  return Register();
}

void llvm::expandSpill8Static(MachineInstr &MI,
                              MachineBasicBlock::iterator InsertBefore,
                              Register SrcReg, bool SrcIsKill,
                              const TargetInstrInfo &TII,
                              const TargetRegisterInfo *TRI,
                              AppendAddrFn AppendAddr) {
  MachineBasicBlock &MBB = *MI.getParent();
  DebugLoc DL = MI.getDebugLoc();

  // Shape C: SrcReg is H or L. A is the only possible router.
  if (SrcReg == V6C::H || SrcReg == V6C::L) {
    bool ADead = isRegDeadAfterMI(V6C::A, MI, MBB, TRI);
    // Row 1: A dead -> MOV A, H|L ; STA addr
    if (ADead) {
      BuildMI(MBB, InsertBefore, DL, TII.get(V6C::MOVrr))
          .addReg(V6C::A, RegState::Define)
          .addReg(SrcReg, getKillRegState(SrcIsKill));
      auto B = BuildMI(MBB, InsertBefore, DL, TII.get(V6C::STA))
                   .addReg(V6C::A);
      AppendAddr(B);
      return;
    }
    // Row 2: A live, Tmp in {B,C,D,E} dead -> save A in Tmp, route, restore.
    Register Tmp = findDeadSpareGPR8(/*Excluded=*/Register(), MI, MBB, TRI);
    if (Tmp) {
      BuildMI(MBB, InsertBefore, DL, TII.get(V6C::MOVrr))
          .addReg(Tmp, RegState::Define)
          .addReg(V6C::A);
      BuildMI(MBB, InsertBefore, DL, TII.get(V6C::MOVrr))
          .addReg(V6C::A, RegState::Define)
          .addReg(SrcReg, getKillRegState(SrcIsKill));
      auto B = BuildMI(MBB, InsertBefore, DL, TII.get(V6C::STA))
                   .addReg(V6C::A);
      AppendAddr(B);
      BuildMI(MBB, InsertBefore, DL, TII.get(V6C::MOVrr))
          .addReg(V6C::A, RegState::Define)
          .addReg(Tmp, RegState::Kill);
      return;
    }
    // Row 3 (fallback): PUSH PSW ; MOV A, H|L ; STA addr ; POP PSW
    BuildMI(MBB, InsertBefore, DL, TII.get(V6C::PUSH)).addReg(V6C::PSW);
    BuildMI(MBB, InsertBefore, DL, TII.get(V6C::MOVrr))
        .addReg(V6C::A, RegState::Define)
        .addReg(SrcReg, getKillRegState(SrcIsKill));
    auto B = BuildMI(MBB, InsertBefore, DL, TII.get(V6C::STA))
                 .addReg(V6C::A);
    AppendAddr(B);
    BuildMI(MBB, InsertBefore, DL, TII.get(V6C::POP), V6C::PSW);
    return;
  }

  // Shape B: SrcReg in {B, C, D, E}.
  assert((SrcReg == V6C::B || SrcReg == V6C::C ||
          SrcReg == V6C::D || SrcReg == V6C::E) &&
         "expandSpill8Static: expected GR8 src (A handled by caller)");

  bool HLDead = isRegDeadAfterMI(V6C::HL, MI, MBB, TRI);
  // Row 1: HL dead -> LXI HL, addr ; MOV M, r
  if (HLDead) {
    auto B = BuildMI(MBB, InsertBefore, DL, TII.get(V6C::LXI))
                 .addReg(V6C::HL, RegState::Define);
    AppendAddr(B);
    BuildMI(MBB, InsertBefore, DL, TII.get(V6C::MOVMr))
        .addReg(SrcReg, getKillRegState(SrcIsKill));
    return;
  }
  bool ADead = isRegDeadAfterMI(V6C::A, MI, MBB, TRI);
  // Row 2: HL live, A dead -> MOV A, r ; STA addr
  if (ADead) {
    BuildMI(MBB, InsertBefore, DL, TII.get(V6C::MOVrr))
        .addReg(V6C::A, RegState::Define)
        .addReg(SrcReg, getKillRegState(SrcIsKill));
    auto B = BuildMI(MBB, InsertBefore, DL, TII.get(V6C::STA))
                 .addReg(V6C::A);
    AppendAddr(B);
    return;
  }
  // Row 3: HL live, A live, Tmp in {B,C,D,E}\{r} dead
  Register Tmp = findDeadSpareGPR8(/*Excluded=*/SrcReg, MI, MBB, TRI);
  if (Tmp) {
    BuildMI(MBB, InsertBefore, DL, TII.get(V6C::MOVrr))
        .addReg(Tmp, RegState::Define)
        .addReg(V6C::A);
    BuildMI(MBB, InsertBefore, DL, TII.get(V6C::MOVrr))
        .addReg(V6C::A, RegState::Define)
        .addReg(SrcReg, getKillRegState(SrcIsKill));
    auto B = BuildMI(MBB, InsertBefore, DL, TII.get(V6C::STA))
                 .addReg(V6C::A);
    AppendAddr(B);
    BuildMI(MBB, InsertBefore, DL, TII.get(V6C::MOVrr))
        .addReg(V6C::A, RegState::Define)
        .addReg(Tmp, RegState::Kill);
    return;
  }
  // Row 4 (fallback): PUSH HL ; LXI HL, addr ; MOV M, r ; POP HL
  BuildMI(MBB, InsertBefore, DL, TII.get(V6C::PUSH)).addReg(V6C::HL);
  auto B = BuildMI(MBB, InsertBefore, DL, TII.get(V6C::LXI))
               .addReg(V6C::HL, RegState::Define);
  AppendAddr(B);
  BuildMI(MBB, InsertBefore, DL, TII.get(V6C::MOVMr))
      .addReg(SrcReg, getKillRegState(SrcIsKill));
  BuildMI(MBB, InsertBefore, DL, TII.get(V6C::POP), V6C::HL);
}

void llvm::expandReload8Static(MachineInstr &MI,
                               MachineBasicBlock::iterator InsertBefore,
                               Register DstReg,
                               const TargetInstrInfo &TII,
                               const TargetRegisterInfo *TRI,
                               AppendAddrFn AppendAddr) {
  MachineBasicBlock &MBB = *MI.getParent();
  DebugLoc DL = MI.getDebugLoc();

  // Shape C: DstReg is H or L. Need to set one half of HL without
  // clobbering the other (unless the other is dead).
  if (DstReg == V6C::H || DstReg == V6C::L) {
    Register OtherHL = (DstReg == V6C::H) ? V6C::L : V6C::H;
    bool OtherHLDead = isRegDeadAfterMI(OtherHL, MI, MBB, TRI);
    // Row 1: other half dead -> LXI HL, addr ; MOV Dst, M
    if (OtherHLDead) {
      auto B = BuildMI(MBB, InsertBefore, DL, TII.get(V6C::LXI))
                   .addReg(V6C::HL, RegState::Define);
      AppendAddr(B);
      BuildMI(MBB, InsertBefore, DL, TII.get(V6C::MOVrM))
          .addReg(DstReg, RegState::Define);
      return;
    }
    bool ADead = isRegDeadAfterMI(V6C::A, MI, MBB, TRI);
    // Row 2: A dead -> LDA addr ; MOV Dst, A
    if (ADead) {
      auto B = BuildMI(MBB, InsertBefore, DL, TII.get(V6C::LDA), V6C::A);
      AppendAddr(B);
      BuildMI(MBB, InsertBefore, DL, TII.get(V6C::MOVrr))
          .addReg(DstReg, RegState::Define)
          .addReg(V6C::A, RegState::Kill);
      return;
    }
    // Row 3: A live, Tmp in {B,C,D,E} dead -> save A in Tmp, route, restore.
    Register Tmp = findDeadSpareGPR8(/*Excluded=*/Register(), MI, MBB, TRI);
    if (Tmp) {
      BuildMI(MBB, InsertBefore, DL, TII.get(V6C::MOVrr))
          .addReg(Tmp, RegState::Define)
          .addReg(V6C::A);
      auto B = BuildMI(MBB, InsertBefore, DL, TII.get(V6C::LDA), V6C::A);
      AppendAddr(B);
      BuildMI(MBB, InsertBefore, DL, TII.get(V6C::MOVrr))
          .addReg(DstReg, RegState::Define)
          .addReg(V6C::A);
      BuildMI(MBB, InsertBefore, DL, TII.get(V6C::MOVrr))
          .addReg(V6C::A, RegState::Define)
          .addReg(Tmp, RegState::Kill);
      return;
    }
    // Row 4 (fallback): PUSH PSW ; LDA addr ; MOV Dst, A ; POP PSW
    BuildMI(MBB, InsertBefore, DL, TII.get(V6C::PUSH)).addReg(V6C::PSW);
    auto B = BuildMI(MBB, InsertBefore, DL, TII.get(V6C::LDA), V6C::A);
    AppendAddr(B);
    BuildMI(MBB, InsertBefore, DL, TII.get(V6C::MOVrr))
        .addReg(DstReg, RegState::Define)
        .addReg(V6C::A);
    BuildMI(MBB, InsertBefore, DL, TII.get(V6C::POP), V6C::PSW);
    return;
  }

  // Shape B: DstReg in {B, C, D, E}.
  assert((DstReg == V6C::B || DstReg == V6C::C ||
          DstReg == V6C::D || DstReg == V6C::E) &&
         "expandReload8Static: expected GR8 dst (A handled by caller)");

  bool HLDead = isRegDeadAfterMI(V6C::HL, MI, MBB, TRI);
  // Row 1: HL dead -> LXI HL, addr ; MOV r, M
  if (HLDead) {
    auto B = BuildMI(MBB, InsertBefore, DL, TII.get(V6C::LXI))
                 .addReg(V6C::HL, RegState::Define);
    AppendAddr(B);
    BuildMI(MBB, InsertBefore, DL, TII.get(V6C::MOVrM))
        .addReg(DstReg, RegState::Define);
    return;
  }
  bool ADead = isRegDeadAfterMI(V6C::A, MI, MBB, TRI);
  // Row 2: HL live, A dead -> LDA addr ; MOV r, A
  if (ADead) {
    auto B = BuildMI(MBB, InsertBefore, DL, TII.get(V6C::LDA), V6C::A);
    AppendAddr(B);
    BuildMI(MBB, InsertBefore, DL, TII.get(V6C::MOVrr))
        .addReg(DstReg, RegState::Define)
        .addReg(V6C::A, RegState::Kill);
    return;
  }
  // Row 3: HL live, A live, Tmp in {B,C,D,E}\{Dst} dead.
  Register Tmp = findDeadSpareGPR8(/*Excluded=*/DstReg, MI, MBB, TRI);
  if (Tmp) {
    BuildMI(MBB, InsertBefore, DL, TII.get(V6C::MOVrr))
        .addReg(Tmp, RegState::Define)
        .addReg(V6C::A);
    auto B = BuildMI(MBB, InsertBefore, DL, TII.get(V6C::LDA), V6C::A);
    AppendAddr(B);
    BuildMI(MBB, InsertBefore, DL, TII.get(V6C::MOVrr))
        .addReg(DstReg, RegState::Define)
        .addReg(V6C::A);
    BuildMI(MBB, InsertBefore, DL, TII.get(V6C::MOVrr))
        .addReg(V6C::A, RegState::Define)
        .addReg(Tmp, RegState::Kill);
    return;
  }
  // Row 4 (fallback): PUSH HL ; LXI HL, addr ; MOV r, M ; POP HL
  BuildMI(MBB, InsertBefore, DL, TII.get(V6C::PUSH)).addReg(V6C::HL);
  auto B = BuildMI(MBB, InsertBefore, DL, TII.get(V6C::LXI))
               .addReg(V6C::HL, RegState::Define);
  AppendAddr(B);
  BuildMI(MBB, InsertBefore, DL, TII.get(V6C::MOVrM))
      .addReg(DstReg, RegState::Define);
  BuildMI(MBB, InsertBefore, DL, TII.get(V6C::POP), V6C::HL);
}
