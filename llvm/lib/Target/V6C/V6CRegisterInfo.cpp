//===-- V6CRegisterInfo.cpp - V6C Register Information --------------------===//
//
// Part of the V6C backend for LLVM.
//
//===----------------------------------------------------------------------===//

#include "V6CRegisterInfo.h"
#include "V6C.h"
#include "V6CFrameLowering.h"
#include "V6CMachineFunctionInfo.h"
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

const TargetRegisterClass *
V6CRegisterInfo::getLargestLegalSuperClass(
    const TargetRegisterClass *RC, const MachineFunction &MF) const {
  // Widen Acc (singleton {A}) to GR8 ({A,B,C,D,E,H,L}) so the register
  // allocator can park Acc-constrained values in other GPRs and insert
  // MOV A,r copies when the value is actually needed in A.
  if (V6C::AccRegClass.hasSubClassEq(RC))
    return &V6C::GR8RegClass;
  return TargetRegisterInfo::getLargestLegalSuperClass(RC, MF);
}

/// Check if a physical register is dead after a given instruction (O42).
/// Scans forward from MI (exclusive) to end of MBB.
/// Returns true if no read before redef, and Reg not in any successor livein.
static bool isRegDeadAfterMI(unsigned Reg, const MachineInstr &MI,
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

  // --- Static stack expansion (O10) ---
  // If this function uses static stack allocation, expand spill/reload
  // pseudos using direct global addresses instead of SP-relative sequences.
  auto *FuncInfo = MF.getInfo<V6CMachineFunctionInfo>();
  if (FuncInfo && FuncInfo->hasStaticStack() &&
      FuncInfo->hasStaticSlot(FrameIndex)) {
    GlobalVariable *GV = FuncInfo->getStaticStackGV();
    int64_t StaticOffset = FuncInfo->getStaticOffset(FrameIndex);

    unsigned Opc = MI.getOpcode();

    if (Opc == V6C::V6C_LEA_FI) {
      // LXI HL, __v6c_static_stack+offset (no DAD SP needed)
      Register DstReg = MI.getOperand(0).getReg();
      BuildMI(MBB, II, DL, TII.get(V6C::LXI))
          .addReg(DstReg, RegState::Define)
          .addGlobalAddress(GV, StaticOffset);
      MI.eraseFromParent();
      return true;
    }

    if (Opc == V6C::V6C_SPILL8) {
      Register SrcReg = MI.getOperand(0).getReg();
      if (SrcReg == V6C::A) {
        // STA __v6c_ss+offset (16cc, 3B)
        BuildMI(MBB, II, DL, TII.get(V6C::STA))
            .addReg(V6C::A)
            .addGlobalAddress(GV, StaticOffset);
      } else if (SrcReg == V6C::H || SrcReg == V6C::L) {
        // Spilling H or L: use DE as temp.
        bool SpillingH = (SrcReg == V6C::H);
        Register ValReg = SpillingH ? V6C::D : V6C::E;
        Register OtherReg = SpillingH ? V6C::E : V6C::D;
        Register OtherHL = SpillingH ? V6C::L : V6C::H;
        // O42: skip PUSH/POP DE when DE is dead after this instruction.
        bool DEDead = isRegDeadAfterMI(V6C::DE, MI, MBB, this);
        if (!DEDead)
          BuildMI(MBB, II, DL, TII.get(V6C::PUSH)).addReg(V6C::DE);
        BuildMI(MBB, II, DL, TII.get(V6C::MOVrr))
            .addReg(ValReg, RegState::Define).addReg(SrcReg);
        BuildMI(MBB, II, DL, TII.get(V6C::MOVrr))
            .addReg(OtherReg, RegState::Define).addReg(OtherHL);
        BuildMI(MBB, II, DL, TII.get(V6C::LXI))
            .addReg(V6C::HL, RegState::Define)
            .addGlobalAddress(GV, StaticOffset);
        BuildMI(MBB, II, DL, TII.get(V6C::MOVMr)).addReg(ValReg);
        // Restore HL from DE.
        BuildMI(MBB, II, DL, TII.get(V6C::MOVrr))
            .addReg(V6C::H, RegState::Define).addReg(V6C::D);
        BuildMI(MBB, II, DL, TII.get(V6C::MOVrr))
            .addReg(V6C::L, RegState::Define).addReg(V6C::E);
        if (!DEDead)
          BuildMI(MBB, II, DL, TII.get(V6C::POP), V6C::DE);
      } else {
        // B,C,D,E: PUSH HL; LXI HL, addr; MOV M, r; POP HL (42cc, 6B)
        // O42: skip PUSH/POP HL when HL is dead after this instruction.
        bool HLDead = isRegDeadAfterMI(V6C::HL, MI, MBB, this);
        if (!HLDead)
          BuildMI(MBB, II, DL, TII.get(V6C::PUSH)).addReg(V6C::HL);
        BuildMI(MBB, II, DL, TII.get(V6C::LXI))
            .addReg(V6C::HL, RegState::Define)
            .addGlobalAddress(GV, StaticOffset);
        BuildMI(MBB, II, DL, TII.get(V6C::MOVMr))
            .addReg(SrcReg, getKillRegState(MI.getOperand(0).isKill()));
        if (!HLDead)
          BuildMI(MBB, II, DL, TII.get(V6C::POP), V6C::HL);
      }
      MI.eraseFromParent();
      return true;
    }

    if (Opc == V6C::V6C_RELOAD8) {
      Register DstReg = MI.getOperand(0).getReg();
      if (DstReg == V6C::A) {
        // LDA __v6c_ss+offset (16cc, 3B)
        BuildMI(MBB, II, DL, TII.get(V6C::LDA), V6C::A)
            .addGlobalAddress(GV, StaticOffset);
      } else if (DstReg == V6C::H || DstReg == V6C::L) {
        // Reloading into H or L: use DE as temp.
        bool LoadingH = (DstReg == V6C::H);
        Register SaveOther = V6C::D;
        Register OtherHL = LoadingH ? V6C::L : V6C::H;
        // O42: skip PUSH/POP DE when DE is dead after this instruction.
        bool DEDead = isRegDeadAfterMI(V6C::DE, MI, MBB, this);
        if (!DEDead)
          BuildMI(MBB, II, DL, TII.get(V6C::PUSH)).addReg(V6C::DE);
        BuildMI(MBB, II, DL, TII.get(V6C::MOVrr))
            .addReg(SaveOther, RegState::Define).addReg(OtherHL);
        BuildMI(MBB, II, DL, TII.get(V6C::LXI))
            .addReg(V6C::HL, RegState::Define)
            .addGlobalAddress(GV, StaticOffset);
        BuildMI(MBB, II, DL, TII.get(V6C::MOVrM))
            .addReg(DstReg, RegState::Define);
        BuildMI(MBB, II, DL, TII.get(V6C::MOVrr))
            .addReg(OtherHL, RegState::Define).addReg(SaveOther);
        if (!DEDead)
          BuildMI(MBB, II, DL, TII.get(V6C::POP), V6C::DE);
      } else {
        // B,C,D,E: PUSH HL; LXI HL, addr; MOV r, M; POP HL (42cc, 6B)
        // O42: skip PUSH/POP HL when HL is dead after this instruction.
        bool HLDead = isRegDeadAfterMI(V6C::HL, MI, MBB, this);
        if (!HLDead)
          BuildMI(MBB, II, DL, TII.get(V6C::PUSH)).addReg(V6C::HL);
        BuildMI(MBB, II, DL, TII.get(V6C::LXI))
            .addReg(V6C::HL, RegState::Define)
            .addGlobalAddress(GV, StaticOffset);
        BuildMI(MBB, II, DL, TII.get(V6C::MOVrM))
            .addReg(DstReg, RegState::Define);
        if (!HLDead)
          BuildMI(MBB, II, DL, TII.get(V6C::POP), V6C::HL);
      }
      MI.eraseFromParent();
      return true;
    }

    if (Opc == V6C::V6C_SPILL16) {
      Register SrcReg = MI.getOperand(0).getReg();
      bool IsKill = MI.getOperand(0).isKill();
      if (SrcReg == V6C::HL) {
        // SHLD __v6c_ss+offset (16cc, 3B)
        BuildMI(MBB, II, DL, TII.get(V6C::SHLD))
            .addReg(V6C::HL)
            .addGlobalAddress(GV, StaticOffset);
      } else if (SrcReg == V6C::DE) {
        // XCHG; SHLD addr; XCHG (24cc, 5B)
        // O42: skip trailing XCHG when HL is dead (DE is killed or HL dead)
        bool HLDead = isRegDeadAfterMI(V6C::HL, MI, MBB, this);
        BuildMI(MBB, II, DL, TII.get(V6C::XCHG));
        BuildMI(MBB, II, DL, TII.get(V6C::SHLD))
            .addReg(V6C::HL)
            .addGlobalAddress(GV, StaticOffset);
        if (!IsKill && !HLDead)
          BuildMI(MBB, II, DL, TII.get(V6C::XCHG));
      } else {
        // BC: PUSH HL; LXI HL, addr; MOV M, C; INX HL; MOV M, B; POP HL
        MCRegister SrcLo = getSubReg(SrcReg, V6C::sub_lo);
        MCRegister SrcHi = getSubReg(SrcReg, V6C::sub_hi);
        // O42: when HL is dead, use MOV L,C; MOV H,B; SHLD addr (5B, 32cc)
        bool HLDead = isRegDeadAfterMI(V6C::HL, MI, MBB, this);
        if (HLDead) {
          BuildMI(MBB, II, DL, TII.get(V6C::MOVrr))
              .addReg(V6C::L, RegState::Define)
              .addReg(SrcLo, getKillRegState(IsKill));
          BuildMI(MBB, II, DL, TII.get(V6C::MOVrr))
              .addReg(V6C::H, RegState::Define)
              .addReg(SrcHi, getKillRegState(IsKill));
          BuildMI(MBB, II, DL, TII.get(V6C::SHLD))
              .addReg(V6C::HL)
              .addGlobalAddress(GV, StaticOffset);
        } else {
          BuildMI(MBB, II, DL, TII.get(V6C::PUSH)).addReg(V6C::HL);
          BuildMI(MBB, II, DL, TII.get(V6C::LXI))
              .addReg(V6C::HL, RegState::Define)
              .addGlobalAddress(GV, StaticOffset);
          BuildMI(MBB, II, DL, TII.get(V6C::MOVMr))
              .addReg(SrcLo, getKillRegState(IsKill));
          BuildMI(MBB, II, DL, TII.get(V6C::INX), V6C::HL).addReg(V6C::HL);
          BuildMI(MBB, II, DL, TII.get(V6C::MOVMr))
              .addReg(SrcHi, getKillRegState(IsKill));
          BuildMI(MBB, II, DL, TII.get(V6C::POP), V6C::HL);
        }
      }
      MI.eraseFromParent();
      return true;
    }

    if (Opc == V6C::V6C_RELOAD16) {
      Register DstReg = MI.getOperand(0).getReg();
      if (DstReg == V6C::HL) {
        // LHLD __v6c_ss+offset (16cc, 3B)
        BuildMI(MBB, II, DL, TII.get(V6C::LHLD), V6C::HL)
            .addGlobalAddress(GV, StaticOffset);
      } else if (DstReg == V6C::DE) {
        // O42: when HL is dead, use LHLD addr; XCHG (4B, 20cc)
        // instead of XCHG; LHLD addr; XCHG (5B, 24cc)
        bool HLDead = isRegDeadAfterMI(V6C::HL, MI, MBB, this);
        if (HLDead) {
          BuildMI(MBB, II, DL, TII.get(V6C::LHLD), V6C::HL)
              .addGlobalAddress(GV, StaticOffset);
          BuildMI(MBB, II, DL, TII.get(V6C::XCHG));
        } else {
          // XCHG; LHLD addr; XCHG (24cc, 5B)
          BuildMI(MBB, II, DL, TII.get(V6C::XCHG));
          BuildMI(MBB, II, DL, TII.get(V6C::LHLD), V6C::HL)
              .addGlobalAddress(GV, StaticOffset);
          BuildMI(MBB, II, DL, TII.get(V6C::XCHG));
        }
      } else {
        // BC: PUSH HL; LXI HL, addr; MOV C, M; INX HL; MOV B, M; POP HL
        MCRegister DstLo = getSubReg(DstReg, V6C::sub_lo);
        MCRegister DstHi = getSubReg(DstReg, V6C::sub_hi);
        // O42: when HL is dead, use LHLD addr; MOV C,L; MOV B,H (5B, 30cc)
        bool HLDead = isRegDeadAfterMI(V6C::HL, MI, MBB, this);
        if (HLDead) {
          BuildMI(MBB, II, DL, TII.get(V6C::LHLD), V6C::HL)
              .addGlobalAddress(GV, StaticOffset);
          BuildMI(MBB, II, DL, TII.get(V6C::MOVrr))
              .addReg(DstLo, RegState::Define).addReg(V6C::L);
          BuildMI(MBB, II, DL, TII.get(V6C::MOVrr))
              .addReg(DstHi, RegState::Define).addReg(V6C::H);
        } else {
          BuildMI(MBB, II, DL, TII.get(V6C::PUSH)).addReg(V6C::HL);
          BuildMI(MBB, II, DL, TII.get(V6C::LXI))
              .addReg(V6C::HL, RegState::Define)
              .addGlobalAddress(GV, StaticOffset);
          BuildMI(MBB, II, DL, TII.get(V6C::MOVrM))
              .addReg(DstLo, RegState::Define);
          BuildMI(MBB, II, DL, TII.get(V6C::INX), V6C::HL).addReg(V6C::HL);
          BuildMI(MBB, II, DL, TII.get(V6C::MOVrM))
              .addReg(DstHi, RegState::Define);
          BuildMI(MBB, II, DL, TII.get(V6C::POP), V6C::HL);
        }
      }
      MI.eraseFromParent();
      return true;
    }

    // Fallback for other instructions with frame indices in static mode:
    // replace with global address offset. This shouldn't normally happen.
    MI.getOperand(FIOperandNum)
        .ChangeToGA(GV, StaticOffset, MI.getOperand(FIOperandNum).getTargetFlags());
    return false;
  }
  // --- End static stack expansion ---

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
      // O42: skip PUSH/POP DE when DE is dead; adjust offset accordingly.
      bool DEDead = isRegDeadAfterMI(V6C::DE, MI, MBB, this);
      int AdjOffset = DEDead ? Offset : Offset + 2;
      if (!DEDead)
        BuildMI(MBB, II, DL, TII.get(V6C::PUSH)).addReg(V6C::DE);
      BuildMI(MBB, II, DL, TII.get(V6C::MOVrr))
          .addReg(ValReg, RegState::Define).addReg(SrcReg);
      BuildMI(MBB, II, DL, TII.get(V6C::MOVrr))
          .addReg(OtherReg, RegState::Define).addReg(OtherHL);
      BuildMI(MBB, II, DL, TII.get(V6C::LXI))
          .addReg(V6C::HL, RegState::Define).addImm(AdjOffset);
      BuildMI(MBB, II, DL, TII.get(V6C::DAD)).addReg(V6C::SP);
      BuildMI(MBB, II, DL, TII.get(V6C::MOVMr)).addReg(ValReg);
      // Restore HL from D/E.
      BuildMI(MBB, II, DL, TII.get(V6C::MOVrr))
          .addReg(V6C::H, RegState::Define).addReg(V6C::D);
      BuildMI(MBB, II, DL, TII.get(V6C::MOVrr))
          .addReg(V6C::L, RegState::Define).addReg(V6C::E);
      if (!DEDead)
        BuildMI(MBB, II, DL, TII.get(V6C::POP), V6C::DE);
    } else {
      // O42: skip PUSH/POP HL when HL is dead; adjust offset accordingly.
      bool HLDead = isRegDeadAfterMI(V6C::HL, MI, MBB, this);
      int AdjOffset = HLDead ? Offset : Offset + 2;
      if (!HLDead)
        BuildMI(MBB, II, DL, TII.get(V6C::PUSH)).addReg(V6C::HL);
      BuildMI(MBB, II, DL, TII.get(V6C::LXI))
          .addReg(V6C::HL, RegState::Define).addImm(AdjOffset);
      BuildMI(MBB, II, DL, TII.get(V6C::DAD)).addReg(V6C::SP);
      BuildMI(MBB, II, DL, TII.get(V6C::MOVMr))
          .addReg(SrcReg, getKillRegState(MI.getOperand(0).isKill()));
      if (!HLDead)
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
      bool LoadingH = (DstReg == V6C::H);
      Register SaveOther = V6C::D; // temp for non-target half
      Register OtherHL = LoadingH ? V6C::L : V6C::H;
      // O42: skip PUSH/POP DE when DE is dead; adjust offset accordingly.
      bool DEDead = isRegDeadAfterMI(V6C::DE, MI, MBB, this);
      int AdjOffset = DEDead ? Offset : Offset + 2;
      if (!DEDead)
        BuildMI(MBB, II, DL, TII.get(V6C::PUSH)).addReg(V6C::DE);
      BuildMI(MBB, II, DL, TII.get(V6C::MOVrr))
          .addReg(SaveOther, RegState::Define).addReg(OtherHL);
      BuildMI(MBB, II, DL, TII.get(V6C::LXI))
          .addReg(V6C::HL, RegState::Define).addImm(AdjOffset);
      BuildMI(MBB, II, DL, TII.get(V6C::DAD)).addReg(V6C::SP);
      // MOV H,M / MOV L,M: 8080 latches [HL] address before writing dst.
      BuildMI(MBB, II, DL, TII.get(V6C::MOVrM))
          .addReg(DstReg, RegState::Define);
      // Restore the non-target half.
      BuildMI(MBB, II, DL, TII.get(V6C::MOVrr))
          .addReg(OtherHL, RegState::Define).addReg(SaveOther);
      if (!DEDead)
        BuildMI(MBB, II, DL, TII.get(V6C::POP), V6C::DE);
    } else {
      // O42: skip PUSH/POP HL when HL is dead; adjust offset accordingly.
      bool HLDead = isRegDeadAfterMI(V6C::HL, MI, MBB, this);
      int AdjOffset = HLDead ? Offset : Offset + 2;
      if (!HLDead)
        BuildMI(MBB, II, DL, TII.get(V6C::PUSH)).addReg(V6C::HL);
      BuildMI(MBB, II, DL, TII.get(V6C::LXI))
          .addReg(V6C::HL, RegState::Define).addImm(AdjOffset);
      BuildMI(MBB, II, DL, TII.get(V6C::DAD)).addReg(V6C::SP);
      BuildMI(MBB, II, DL, TII.get(V6C::MOVrM))
          .addReg(DstReg, RegState::Define);
      if (!HLDead)
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
      // O42: skip PUSH/POP DE when DE is dead; adjust offset accordingly.
      bool DEDead = isRegDeadAfterMI(V6C::DE, MI, MBB, this);
      int AdjOffset = DEDead ? Offset : Offset + 2;
      if (!DEDead)
        BuildMI(MBB, II, DL, TII.get(V6C::PUSH)).addReg(V6C::DE);
      BuildMI(MBB, II, DL, TII.get(V6C::MOVrr))
          .addReg(V6C::D, RegState::Define).addReg(V6C::H);
      BuildMI(MBB, II, DL, TII.get(V6C::MOVrr))
          .addReg(V6C::E, RegState::Define).addReg(V6C::L);
      BuildMI(MBB, II, DL, TII.get(V6C::LXI))
          .addReg(V6C::HL, RegState::Define).addImm(AdjOffset);
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
      if (!DEDead)
        BuildMI(MBB, II, DL, TII.get(V6C::POP), V6C::DE);
    } else {
      // Spilling DE or BC: save HL, use HL for addressing, restore.
      MCRegister SrcLo = getSubReg(SrcReg, V6C::sub_lo);
      MCRegister SrcHi = getSubReg(SrcReg, V6C::sub_hi);
      // O42: skip PUSH/POP HL when HL is dead; adjust offset accordingly.
      bool HLDead = isRegDeadAfterMI(V6C::HL, MI, MBB, this);
      int AdjOffset = HLDead ? Offset : Offset + 2;
      if (!HLDead)
        BuildMI(MBB, II, DL, TII.get(V6C::PUSH)).addReg(V6C::HL);
      BuildMI(MBB, II, DL, TII.get(V6C::LXI))
          .addReg(V6C::HL, RegState::Define).addImm(AdjOffset);
      BuildMI(MBB, II, DL, TII.get(V6C::DAD)).addReg(V6C::SP);
      BuildMI(MBB, II, DL, TII.get(V6C::MOVMr))
          .addReg(SrcLo, getKillRegState(IsKill));
      BuildMI(MBB, II, DL, TII.get(V6C::INX), V6C::HL).addReg(V6C::HL);
      BuildMI(MBB, II, DL, TII.get(V6C::MOVMr))
          .addReg(SrcHi, getKillRegState(IsKill));
      if (!HLDead)
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
      // O42: skip PUSH/POP DE when DE is dead; adjust offset accordingly.
      bool DEDead = isRegDeadAfterMI(V6C::DE, MI, MBB, this);
      int AdjOffset = DEDead ? Offset : Offset + 2;
      if (!DEDead)
        BuildMI(MBB, II, DL, TII.get(V6C::PUSH)).addReg(V6C::DE);
      BuildMI(MBB, II, DL, TII.get(V6C::LXI))
          .addReg(V6C::HL, RegState::Define).addImm(AdjOffset);
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
      if (!DEDead)
        BuildMI(MBB, II, DL, TII.get(V6C::POP), V6C::DE);
    } else {
      // Reloading into DE or BC: save HL, load, restore HL.
      MCRegister LoadLo = getSubReg(DstReg, V6C::sub_lo);
      MCRegister LoadHi = getSubReg(DstReg, V6C::sub_hi);
      // O42: skip PUSH/POP HL when HL is dead; adjust offset accordingly.
      bool HLDead = isRegDeadAfterMI(V6C::HL, MI, MBB, this);
      int AdjOffset = HLDead ? Offset : Offset + 2;
      if (!HLDead)
        BuildMI(MBB, II, DL, TII.get(V6C::PUSH)).addReg(V6C::HL);
      BuildMI(MBB, II, DL, TII.get(V6C::LXI))
          .addReg(V6C::HL, RegState::Define).addImm(AdjOffset);
      BuildMI(MBB, II, DL, TII.get(V6C::DAD)).addReg(V6C::SP);
      BuildMI(MBB, II, DL, TII.get(V6C::MOVrM))
          .addReg(LoadLo, RegState::Define);
      BuildMI(MBB, II, DL, TII.get(V6C::INX), V6C::HL).addReg(V6C::HL);
      BuildMI(MBB, II, DL, TII.get(V6C::MOVrM))
          .addReg(LoadHi, RegState::Define);
      if (!HLDead)
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
