//===-- V6CInstrInfo.cpp - V6C Instruction Information --------------------===//
//
// Part of the V6C backend for LLVM.
//
//===----------------------------------------------------------------------===//

#include "V6CInstrInfo.h"
#include "V6C.h"
#include "V6CISelLowering.h"
#include "V6CInstrCost.h"
#include "MCTargetDesc/V6CMCTargetDesc.h"
#include "llvm/CodeGen/MachineBasicBlock.h"
#include "llvm/CodeGen/MachineInstrBuilder.h"

#define GET_INSTRINFO_CTOR_DTOR
#include "V6CGenInstrInfo.inc"

using namespace llvm;

V6CInstrInfo::V6CInstrInfo()
    : V6CGenInstrInfo(V6C::ADJCALLSTACKDOWN, V6C::ADJCALLSTACKUP), RI() {}

void V6CInstrInfo::copyPhysReg(MachineBasicBlock &MBB,
                                MachineBasicBlock::iterator MI,
                                const DebugLoc &DL, MCRegister DestReg,
                                MCRegister SrcReg, bool KillSrc) const {
  // 8-bit register copy: MOV dest, src
  if (V6C::GR8RegClass.contains(DestReg) &&
      V6C::GR8RegClass.contains(SrcReg)) {
    BuildMI(MBB, MI, DL, get(V6C::MOVrr))
        .addReg(DestReg, RegState::Define)
        .addReg(SrcReg, getKillRegState(KillSrc));
    return;
  }

  // 16-bit pair copy: two MOV instructions (hi byte, then lo byte)
  if (V6C::GR16RegClass.contains(DestReg) &&
      V6C::GR16RegClass.contains(SrcReg)) {
    // DE↔HL with source killed: use XCHG (1B/4cc vs 2B/16cc).
    // Safe because source is dead — the reverse swap side-effect is harmless.
    if (KillSrc &&
        ((DestReg == V6C::HL && SrcReg == V6C::DE) ||
         (DestReg == V6C::DE && SrcReg == V6C::HL))) {
      BuildMI(MBB, MI, DL, get(V6C::XCHG));
      return;
    }

    const TargetRegisterInfo *TRI = &RI;
    MCRegister DestHi = TRI->getSubReg(DestReg, V6C::sub_hi);
    MCRegister DestLo = TRI->getSubReg(DestReg, V6C::sub_lo);
    MCRegister SrcHi = TRI->getSubReg(SrcReg, V6C::sub_hi);
    MCRegister SrcLo = TRI->getSubReg(SrcReg, V6C::sub_lo);

    BuildMI(MBB, MI, DL, get(V6C::MOVrr))
        .addReg(DestHi, RegState::Define)
        .addReg(SrcHi, getKillRegState(KillSrc));
    BuildMI(MBB, MI, DL, get(V6C::MOVrr))
        .addReg(DestLo, RegState::Define)
        .addReg(SrcLo, getKillRegState(KillSrc));
    return;
  }

  // SP → HL: LXI HL, 0 + DAD SP (no direct MOV path on 8080).
  if (DestReg == V6C::HL && SrcReg == V6C::SP) {
    BuildMI(MBB, MI, DL, get(V6C::LXI), V6C::HL).addImm(0);
    BuildMI(MBB, MI, DL, get(V6C::DAD))
        .addReg(V6C::SP);
    return;
  }

  llvm_unreachable("Cannot copy between these register classes");
}

void V6CInstrInfo::storeRegToStackSlot(
    MachineBasicBlock &MBB, MachineBasicBlock::iterator MI, Register SrcReg,
    bool isKill, int FrameIndex, const TargetRegisterClass *RC,
    const TargetRegisterInfo *TRI, Register VReg) const {
  DebugLoc DL;
  if (MI != MBB.end())
    DL = MI->getDebugLoc();

  if (V6C::GR8RegClass.hasSubClassEq(RC) ||
      V6C::AccRegClass.hasSubClassEq(RC)) {
    BuildMI(MBB, MI, DL, get(V6C::V6C_SPILL8))
        .addReg(SrcReg, getKillRegState(isKill))
        .addFrameIndex(FrameIndex);
    return;
  }

  if (V6C::GR16RegClass.hasSubClassEq(RC)) {
    BuildMI(MBB, MI, DL, get(V6C::V6C_SPILL16))
        .addReg(SrcReg, getKillRegState(isKill))
        .addFrameIndex(FrameIndex);
    return;
  }

  llvm_unreachable("Cannot store this register to stack slot");
}

void V6CInstrInfo::loadRegFromStackSlot(
    MachineBasicBlock &MBB, MachineBasicBlock::iterator MI, Register DestReg,
    int FrameIndex, const TargetRegisterClass *RC,
    const TargetRegisterInfo *TRI, Register VReg) const {
  DebugLoc DL;
  if (MI != MBB.end())
    DL = MI->getDebugLoc();

  if (V6C::GR8RegClass.hasSubClassEq(RC) ||
      V6C::AccRegClass.hasSubClassEq(RC)) {
    BuildMI(MBB, MI, DL, get(V6C::V6C_RELOAD8))
        .addReg(DestReg, RegState::Define)
        .addFrameIndex(FrameIndex);
    return;
  }

  if (V6C::GR16RegClass.hasSubClassEq(RC)) {
    BuildMI(MBB, MI, DL, get(V6C::V6C_RELOAD16))
        .addReg(DestReg, RegState::Define)
        .addFrameIndex(FrameIndex);
    return;
  }

  llvm_unreachable("Cannot load this register from stack slot");
}

//===----------------------------------------------------------------------===//
// Branch Analysis
//===----------------------------------------------------------------------===//

/// Map a Jcc opcode to a V6CCC condition code.
static V6CCC::CondCode getCondFromJcc(unsigned Opc) {
  switch (Opc) {
  default: llvm_unreachable("Not a V6C conditional branch");
  case V6C::JNZ: return V6CCC::COND_NZ;
  case V6C::JZ:  return V6CCC::COND_Z;
  case V6C::JNC: return V6CCC::COND_NC;
  case V6C::JC:  return V6CCC::COND_C;
  case V6C::JPO: return V6CCC::COND_PO;
  case V6C::JPE: return V6CCC::COND_PE;
  case V6C::JP:  return V6CCC::COND_P;
  case V6C::JM:  return V6CCC::COND_M;
  }
}

/// Map a V6CCC condition code to a Jcc opcode.
static unsigned getJccFromCond(V6CCC::CondCode CC) {
  switch (CC) {
  case V6CCC::COND_NZ: return V6C::JNZ;
  case V6CCC::COND_Z:  return V6C::JZ;
  case V6CCC::COND_NC: return V6C::JNC;
  case V6CCC::COND_C:  return V6C::JC;
  case V6CCC::COND_PO: return V6C::JPO;
  case V6CCC::COND_PE: return V6C::JPE;
  case V6CCC::COND_P:  return V6C::JP;
  case V6CCC::COND_M:  return V6C::JM;
  }
  llvm_unreachable("Unknown V6C condition code");
}

/// Return the opposite condition code.
static V6CCC::CondCode getOppositeCond(V6CCC::CondCode CC) {
  switch (CC) {
  case V6CCC::COND_NZ: return V6CCC::COND_Z;
  case V6CCC::COND_Z:  return V6CCC::COND_NZ;
  case V6CCC::COND_NC: return V6CCC::COND_C;
  case V6CCC::COND_C:  return V6CCC::COND_NC;
  case V6CCC::COND_PO: return V6CCC::COND_PE;
  case V6CCC::COND_PE: return V6CCC::COND_PO;
  case V6CCC::COND_P:  return V6CCC::COND_M;
  case V6CCC::COND_M:  return V6CCC::COND_P;
  }
  llvm_unreachable("Unknown V6C condition code");
}

static bool isCondBranch(unsigned Opc) {
  switch (Opc) {
  case V6C::JNZ: case V6C::JZ: case V6C::JNC: case V6C::JC:
  case V6C::JPO: case V6C::JPE: case V6C::JP: case V6C::JM:
    return true;
  default:
    return false;
  }
}

static bool isUncondBranch(unsigned Opc) {
  return Opc == V6C::JMP;
}

bool V6CInstrInfo::analyzeBranch(MachineBasicBlock &MBB,
                                  MachineBasicBlock *&TBB,
                                  MachineBasicBlock *&FBB,
                                  SmallVectorImpl<MachineOperand> &Cond,
                                  bool AllowModify) const {
  TBB = nullptr;
  FBB = nullptr;
  Cond.clear();

  // Scan backwards to find branch instructions.
  MachineBasicBlock::iterator I = MBB.end();
  MachineBasicBlock::iterator UnCondBrIter = MBB.end();

  while (I != MBB.begin()) {
    --I;

    if (I->isDebugInstr())
      continue;

    // Not a terminator — stop.
    if (!I->isTerminator())
      break;

    // Handle JMP (unconditional branch).
    if (isUncondBranch(I->getOpcode())) {
      UnCondBrIter = I;

      if (!TBB) {
        TBB = I->getOperand(0).getMBB();
        continue;
      }

      // Multiple unconditional branches — give up.
      return true;
    }

    // Handle Jcc (conditional branch).
    if (isCondBranch(I->getOpcode())) {
      V6CCC::CondCode CC = getCondFromJcc(I->getOpcode());

      if (!TBB) {
        // This is the last branch — conditional with fallthrough.
        TBB = I->getOperand(0).getMBB();
        Cond.push_back(MachineOperand::CreateImm(CC));
        continue;
      }

      // Already have a conditional branch — that means we have
      // Jcc + JMP: conditional to TBB, unconditional (fallthrough) to FBB.
      FBB = TBB;
      TBB = I->getOperand(0).getMBB();
      Cond.push_back(MachineOperand::CreateImm(CC));
      continue;
    }

    // Unknown terminator — give up.
    return true;
  }

  return false;
}

unsigned V6CInstrInfo::removeBranch(MachineBasicBlock &MBB,
                                     int *BytesRemoved) const {
  MachineBasicBlock::iterator I = MBB.end();
  unsigned Count = 0;

  while (I != MBB.begin()) {
    --I;
    if (I->isDebugInstr())
      continue;
    if (!isUncondBranch(I->getOpcode()) && !isCondBranch(I->getOpcode()))
      break;

    if (BytesRemoved)
      *BytesRemoved += 3; // All branches are 3 bytes
    I->eraseFromParent();
    I = MBB.end();
    ++Count;
  }

  return Count;
}

unsigned V6CInstrInfo::insertBranch(MachineBasicBlock &MBB,
                                     MachineBasicBlock *TBB,
                                     MachineBasicBlock *FBB,
                                     ArrayRef<MachineOperand> Cond,
                                     const DebugLoc &DL,
                                     int *BytesAdded) const {
  assert(TBB && "insertBranch requires a true block");

  if (Cond.empty()) {
    // Unconditional branch.
    assert(!FBB && "Unconditional branch with false block?");
    BuildMI(&MBB, DL, get(V6C::JMP)).addMBB(TBB);
    if (BytesAdded)
      *BytesAdded = 3;
    return 1;
  }

  // Conditional branch.
  assert(Cond.size() == 1 && "V6C branch condition has single operand");
  auto CC = static_cast<V6CCC::CondCode>(Cond[0].getImm());
  unsigned JccOpc = getJccFromCond(CC);
  BuildMI(&MBB, DL, get(JccOpc)).addMBB(TBB);

  if (!FBB) {
    if (BytesAdded)
      *BytesAdded = 3;
    return 1;
  }

  // Conditional + unconditional: Jcc TBB; JMP FBB
  BuildMI(&MBB, DL, get(V6C::JMP)).addMBB(FBB);
  if (BytesAdded)
    *BytesAdded = 6;
  return 2;
}

bool V6CInstrInfo::reverseBranchCondition(
    SmallVectorImpl<MachineOperand> &Cond) const {
  assert(Cond.size() == 1 && "Invalid V6C branch condition");
  auto CC = static_cast<V6CCC::CondCode>(Cond[0].getImm());
  Cond[0].setImm(getOppositeCond(CC));
  return false;
}

//===----------------------------------------------------------------------===//
// Helpers for INX/DCX peephole in expandPostRAPseudo
//===----------------------------------------------------------------------===//

/// Scan backward from \p From in \p MBB looking for an LXI that defines
/// \p Reg with no intervening redefinition. Returns the LXI MachineInstr
/// if found, nullptr otherwise. Stops at the beginning of the block or
/// after a reasonable scan window (16 instructions).
/// If no LXI is found in the current block and \p Reg is not modified before
/// \p From, also checks predecessor blocks for a defining LXI (handles loop
/// preheader constants like LXI BC, 1).
static MachineInstr *findDefiningLXI(MachineBasicBlock &MBB,
                                     MachineBasicBlock::iterator From,
                                     Register Reg,
                                     const TargetRegisterInfo *TRI) {
  const unsigned ScanLimit = 16;
  unsigned Count = 0;
  for (auto I = From; I != MBB.begin() && Count < ScanLimit; ++Count) {
    --I;
    MachineInstr &Cand = *I;

    // Found LXI defining Reg — return it.
    if (Cand.getOpcode() == V6C::LXI &&
        Cand.getOperand(0).getReg() == Reg)
      return &Cand;

    // If something else defines Reg (including sub-registers), stop.
    if (Cand.modifiesRegister(Reg, TRI))
      return nullptr;
  }

  // Reg is not modified in the current BB before From.
  // Check predecessor blocks: if ALL predecessors have the same LXI value
  // (or don't modify Reg, inheriting from their own predecessors),
  // we can use it. For simplicity, require exactly one non-self predecessor
  // (covers the common loop-preheader case).
  MachineInstr *PredLXI = nullptr;
  for (MachineBasicBlock *Pred : MBB.predecessors()) {
    if (Pred == &MBB)
      continue; // Skip self-loop (back-edge) — Reg unchanged in current BB.
    // Scan backward from end of predecessor.
    unsigned PredCount = 0;
    bool Found = false;
    for (auto I = Pred->end(); I != Pred->begin() && PredCount < ScanLimit;
         ++PredCount) {
      --I;
      if (I->getOpcode() == V6C::LXI && I->getOperand(0).getReg() == Reg) {
        if (PredLXI && PredLXI->getOperand(1).getImm() !=
                            I->getOperand(1).getImm())
          return nullptr; // Conflicting values from different predecessors.
        PredLXI = &*I;
        Found = true;
        break;
      }
      if (I->modifiesRegister(Reg, TRI))
        return nullptr; // Reg modified by non-LXI in predecessor.
    }
    if (!Found && !PredLXI)
      return nullptr; // Predecessor doesn't define Reg via LXI.
  }
  return PredLXI;
}

/// Return true if the FLAGS register implicit-def on \p MI is dead.
static bool isFlagsDefDead(const MachineInstr &MI) {
  for (const MachineOperand &MO : MI.implicit_operands()) {
    if (MO.isReg() && MO.isDef() && MO.getReg() == V6C::FLAGS)
      return MO.isDead();
  }
  // No FLAGS implicit def found — conservatively safe (no flags produced).
  return true;
}

/// Return true if \p Reg is not used by any instruction between \p After
/// (exclusive) and the next redefinition or end of \p MBB.
static bool isRegDeadAfter(MachineBasicBlock &MBB,
                           MachineBasicBlock::iterator After,
                           Register Reg,
                           const TargetRegisterInfo *TRI) {
  for (auto I = std::next(After), E = MBB.end(); I != E; ++I) {
    if (I->readsRegister(Reg, TRI))
      return false;
    if (I->modifiesRegister(Reg, TRI))
      return true; // Redefined before use — the LXI's value is dead.
  }
  // Reached end of block. Check if Reg is live-out.
  return !MBB.isLiveIn(Reg) || MBB.succ_empty();
}

/// Check if a physical register is dead after a given instruction.
/// Scans forward from MI (exclusive) to the end of MBB.
/// Returns true if no read before redef, and Reg not in any successor livein.
static bool isRegDeadAtMI(unsigned Reg, const MachineInstr &MI,
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

bool V6CInstrInfo::expandPostRAPseudo(MachineInstr &MI) const {
  MachineBasicBlock &MBB = *MI.getParent();
  DebugLoc DL = MI.getDebugLoc();

  // Speculatively insert annotation comment before expansion.
  // Removed in `default` case when no expansion occurs.
  MachineInstr *CommentMI = nullptr;
  if (getV6CAnnotatePseudosEnabled()) {
    CommentMI = BuildMI(MBB, MI, DL, get(V6C::V6C_PSEUDO_COMMENT))
                    .addImm(MI.getOpcode())
                    .getInstr();
  }

  switch (MI.getOpcode()) {
  default:
    if (CommentMI)
      CommentMI->eraseFromParent();
    return false;

  case V6C::V6C_BUILD_PAIR: {
    // Combine two i8 values into i16 register pair.
    Register Dst = MI.getOperand(0).getReg();
    Register Lo = MI.getOperand(1).getReg();
    Register Hi = MI.getOperand(2).getReg();
    MCRegister DstLo = RI.getSubReg(Dst, V6C::sub_lo);
    MCRegister DstHi = RI.getSubReg(Dst, V6C::sub_hi);
    // Copy hi first in case DstLo == Hi (avoids clobbering).
    if (Hi != DstHi)
      BuildMI(MBB, MI, DL, get(V6C::MOVrr), DstHi).addReg(Hi);
    if (Lo != DstLo)
      BuildMI(MBB, MI, DL, get(V6C::MOVrr), DstLo).addReg(Lo);
    MI.eraseFromParent();
    return true;
  }

  case V6C::V6C_SEXT: {
    // Sign-extend i8 to i16 via RLC + SBB.
    // RLC rotates A left: bit 7 → carry.
    // SBB A: A = A - A - carry = -carry = 0x00 or 0xFF.
    Register Dst = MI.getOperand(0).getReg();
    Register Src = MI.getOperand(1).getReg();
    MCRegister DstLo = RI.getSubReg(Dst, V6C::sub_lo);
    MCRegister DstHi = RI.getSubReg(Dst, V6C::sub_hi);

    // Copy source to destination low byte first.
    if (Src != DstLo)
      BuildMI(MBB, MI, DL, get(V6C::MOVrr), DstLo).addReg(Src);
    // Compute sign extension: MOV A, Src; RLC; SBB A; MOV DstHi, A
    BuildMI(MBB, MI, DL, get(V6C::MOVrr), V6C::A).addReg(Src);
    BuildMI(MBB, MI, DL, get(V6C::RLC), V6C::A).addReg(V6C::A);
    BuildMI(MBB, MI, DL, get(V6C::SBBr), V6C::A)
        .addReg(V6C::A).addReg(V6C::A);
    BuildMI(MBB, MI, DL, get(V6C::MOVrr), DstHi).addReg(V6C::A);
    MI.eraseFromParent();
    return true;
  }

  case V6C::V6C_BRCOND: {
    MachineBasicBlock *Target = MI.getOperand(0).getMBB();
    int64_t CC = MI.getOperand(1).getImm();

    unsigned JccOpc;
    switch (CC) {
    default: llvm_unreachable("Unknown V6C condition code");
    case V6CCC::COND_NZ: JccOpc = V6C::JNZ; break;
    case V6CCC::COND_Z:  JccOpc = V6C::JZ;  break;
    case V6CCC::COND_NC: JccOpc = V6C::JNC; break;
    case V6CCC::COND_C:  JccOpc = V6C::JC;  break;
    case V6CCC::COND_PO: JccOpc = V6C::JPO; break;
    case V6CCC::COND_PE: JccOpc = V6C::JPE; break;
    case V6CCC::COND_P:  JccOpc = V6C::JP;  break;
    case V6CCC::COND_M:  JccOpc = V6C::JM;  break;
    }

    BuildMI(MBB, MI, DL, get(JccOpc)).addMBB(Target);
    MI.eraseFromParent();
    return true;
  }

  //===------------------------------------------------------------------===//
  // M7: i16 arithmetic pseudo expansions
  //===------------------------------------------------------------------===//

  // O41: Pre-RA INX/DCX pseudos — expand to N copies of INX/DCX rp.
  case V6C::V6C_INX16: {
    Register Rp = MI.getOperand(0).getReg();
    unsigned Count = MI.getOperand(2).getImm();
    for (unsigned I = 0; I < Count; ++I)
      BuildMI(MBB, MI, DL, get(V6C::INX), Rp).addReg(Rp);
    MI.eraseFromParent();
    return true;
  }
  case V6C::V6C_DCX16: {
    Register Rp = MI.getOperand(0).getReg();
    unsigned Count = MI.getOperand(2).getImm();
    for (unsigned I = 0; I < Count; ++I)
      BuildMI(MBB, MI, DL, get(V6C::DCX), Rp).addReg(Rp);
    MI.eraseFromParent();
    return true;
  }

  case V6C::V6C_DAD: {
    // V6C_DAD: HL = HL + rp via physical DAD instruction.
    // $dst and $lhs are tied and constrained to HL (GR16Ptr).
    Register DstReg = MI.getOperand(0).getReg();
    Register RpReg = MI.getOperand(2).getReg();
    assert(DstReg == V6C::HL && "V6C_DAD operands must be HL");
    (void)DstReg;

    // Try INX/DCX chains for small constants loaded by a preceding LXI.
    // INX/DCX set no flags, so this is only valid when FLAGS is dead.
    if (isFlagsDefDead(MI)) {
      MachineInstr *LXI = findDefiningLXI(MBB, MI.getIterator(), RpReg, &RI);
      if (LXI) {
        int64_t ImmVal = LXI->getOperand(1).getImm();
        if (ImmVal > 0x7FFF)
          ImmVal -= 0x10000;
        if (ImmVal != 0) {
          unsigned AbsVal =
              static_cast<unsigned>(ImmVal > 0 ? ImmVal : -ImmVal);
          unsigned InxOpc = ImmVal > 0 ? V6C::INX : V6C::DCX;
          V6COptMode Mode = getV6COptMode(*MBB.getParent());
          V6CInstrCost InxCost = V6CCost::INX * AbsVal;
          V6CInstrCost DadCost = V6CCost::LXI + V6CCost::DAD;
          if (InxCost.isCheaperOrEqual(DadCost, Mode)) {
            for (unsigned I = 0; I < AbsVal; ++I)
              BuildMI(MBB, MI, DL, get(InxOpc), V6C::HL).addReg(V6C::HL);
            Register ConstReg = LXI->getOperand(0).getReg();
            if (LXI->getParent() == &MBB &&
                isRegDeadAfter(MBB, MI.getIterator(), ConstReg, &RI))
              LXI->eraseFromParent();
            MI.eraseFromParent();
            return true;
          }
        }
      }
    }

    BuildMI(MBB, MI, DL, get(V6C::DAD)).addReg(RpReg);
    MI.eraseFromParent();
    return true;
  }

  case V6C::V6C_ADD16: {
    // dst = lhs + rhs (16-bit)
    Register DstReg = MI.getOperand(0).getReg();
    Register LhsReg = MI.getOperand(1).getReg();
    Register RhsReg = MI.getOperand(2).getReg();

    // INX/DCX chains for small constants via cost model.
    // Checked BEFORE DAD so that HL benefits too (INX doesn't clobber
    // a helper pair).
    if (isFlagsDefDead(MI)) {
      // Try RhsReg as the constant.
      MachineInstr *LXI = findDefiningLXI(MBB, MI.getIterator(), RhsReg, &RI);
      Register BaseReg = LhsReg;
      if (!LXI) {
        // Try LhsReg as the constant (add is commutative).
        LXI = findDefiningLXI(MBB, MI.getIterator(), LhsReg, &RI);
        BaseReg = RhsReg;
      }
      if (LXI && DstReg == BaseReg) {
        int64_t ImmVal = LXI->getOperand(1).getImm();
        // Normalize unsigned 16-bit to signed.
        if (ImmVal > 0x7FFF)
          ImmVal -= 0x10000;
        if (ImmVal != 0) {
          unsigned AbsVal =
              static_cast<unsigned>(ImmVal > 0 ? ImmVal : -ImmVal);
          unsigned InxOpc = ImmVal > 0 ? V6C::INX : V6C::DCX;
          V6COptMode Mode = getV6COptMode(*MBB.getParent());
          V6CInstrCost InxCost = V6CCost::INX * AbsVal;
          V6CInstrCost DadCost = V6CCost::LXI + V6CCost::DAD;
          if (InxCost.isCheaperOrEqual(DadCost, Mode)) {
            for (unsigned I = 0; I < AbsVal; ++I)
              BuildMI(MBB, MI, DL, get(InxOpc), DstReg).addReg(DstReg);
            Register ConstReg = LXI->getOperand(0).getReg();
            if (LXI->getParent() == &MBB &&
                isRegDeadAfter(MBB, MI.getIterator(), ConstReg, &RI))
              LXI->eraseFromParent();
            MI.eraseFromParent();
            return true;
          }
        }
      }
    }

    // DAD rp: HL = HL + rp. Only sets Carry flag.
    // Optimization: if dst==HL and one operand is HL, use DAD rp (12cc)
    // instead of the full 6-instruction 8-bit chain (~40cc).
    if (DstReg == V6C::HL && LhsReg == V6C::HL) {
      BuildMI(MBB, MI, DL, get(V6C::DAD)).addReg(RhsReg);
      MI.eraseFromParent();
      return true;
    }
    if (DstReg == V6C::HL && RhsReg == V6C::HL) {
      // ADD is commutative: HL = rp + HL → DAD rp
      BuildMI(MBB, MI, DL, get(V6C::DAD)).addReg(LhsReg);
      MI.eraseFromParent();
      return true;
    }

    // --- Path A: one operand is HL, DstReg != HL ---
    // Use DAD + copy result out (via XCHG for DE, MOV pair for BC).
    if (DstReg != V6C::HL &&
        (LhsReg == V6C::HL || RhsReg == V6C::HL)) {
      Register OtherReg = (LhsReg == V6C::HL) ? RhsReg : LhsReg;
      bool HLDead = isRegDeadAfter(MBB, MI.getIterator(), V6C::HL, &RI);

      if (DstReg == V6C::DE) {
        if (HLDead) {
          // A1-DE: DAD OtherReg; XCHG → 16cc, 2B
          BuildMI(MBB, MI, DL, get(V6C::DAD)).addReg(OtherReg);
          BuildMI(MBB, MI, DL, get(V6C::XCHG));
          MI.eraseFromParent();
          return true;
        }
        if (OtherReg == V6C::DE) {
          // A2-DE: DE = HL + DE, HL live. XCHG; DAD DE; XCHG → 20cc, 3B
          BuildMI(MBB, MI, DL, get(V6C::XCHG));
          BuildMI(MBB, MI, DL, get(V6C::DAD)).addReg(V6C::DE);
          BuildMI(MBB, MI, DL, get(V6C::XCHG));
          MI.eraseFromParent();
          return true;
        }
        // dest=DE, HL live, OtherReg!=DE → fall to byte chain.
      }

      if (HLDead) {
        // A-general (dest=BC): DAD + MOV pair → 28cc, 3B
        BuildMI(MBB, MI, DL, get(V6C::DAD)).addReg(OtherReg);
        MCRegister DstHi = RI.getSubReg(DstReg, V6C::sub_hi);
        MCRegister DstLo = RI.getSubReg(DstReg, V6C::sub_lo);
        BuildMI(MBB, MI, DL, get(V6C::MOVrr), DstHi).addReg(V6C::H);
        BuildMI(MBB, MI, DL, get(V6C::MOVrr), DstLo).addReg(V6C::L);
        MI.eraseFromParent();
        return true;
      }
      // HL live, not A2-DE → fall through to byte chain.
    }

    // --- Path B: DstReg == HL, neither operand is HL ---
    // Copy one operand into HL (via XCHG for DE, MOV pair otherwise),
    // then DAD the other.
    if (DstReg == V6C::HL && LhsReg != V6C::HL && RhsReg != V6C::HL) {
      // B1-DE: one operand is DE (not both), DE dead → XCHG + DAD
      if (LhsReg != RhsReg) {
        Register DEOp = Register();
        Register NonDEOp = Register();
        if (LhsReg == V6C::DE) {
          DEOp = LhsReg;
          NonDEOp = RhsReg;
        } else if (RhsReg == V6C::DE) {
          DEOp = RhsReg;
          NonDEOp = LhsReg;
        }
        if (DEOp && isRegDeadAfter(MBB, MI.getIterator(), V6C::DE, &RI)) {
          // XCHG; DAD NonDEOp → 16cc, 2B
          BuildMI(MBB, MI, DL, get(V6C::XCHG));
          BuildMI(MBB, MI, DL, get(V6C::DAD)).addReg(NonDEOp);
          MI.eraseFromParent();
          return true;
        }
      }

      // B-general: MOV pair + DAD → 28cc, 3B
      {
        MCRegister LhsHi = RI.getSubReg(LhsReg, V6C::sub_hi);
        MCRegister LhsLo = RI.getSubReg(LhsReg, V6C::sub_lo);
        BuildMI(MBB, MI, DL, get(V6C::MOVrr), V6C::H).addReg(LhsHi);
        BuildMI(MBB, MI, DL, get(V6C::MOVrr), V6C::L).addReg(LhsLo);
        BuildMI(MBB, MI, DL, get(V6C::DAD)).addReg(RhsReg);
        MI.eraseFromParent();
        return true;
      }
    }

    // General case: expand to 8-bit chain.
    MCRegister DstLo = RI.getSubReg(DstReg, V6C::sub_lo);
    MCRegister DstHi = RI.getSubReg(DstReg, V6C::sub_hi);
    MCRegister LhsLo = RI.getSubReg(LhsReg, V6C::sub_lo);
    MCRegister LhsHi = RI.getSubReg(LhsReg, V6C::sub_hi);
    MCRegister RhsLo = RI.getSubReg(RhsReg, V6C::sub_lo);
    MCRegister RhsHi = RI.getSubReg(RhsReg, V6C::sub_hi);

    BuildMI(MBB, MI, DL, get(V6C::MOVrr), V6C::A).addReg(LhsLo);
    BuildMI(MBB, MI, DL, get(V6C::ADDr), V6C::A)
        .addReg(V6C::A).addReg(RhsLo);
    BuildMI(MBB, MI, DL, get(V6C::MOVrr), DstLo).addReg(V6C::A);
    BuildMI(MBB, MI, DL, get(V6C::MOVrr), V6C::A).addReg(LhsHi);
    BuildMI(MBB, MI, DL, get(V6C::ADCr), V6C::A)
        .addReg(V6C::A).addReg(RhsHi);
    BuildMI(MBB, MI, DL, get(V6C::MOVrr), DstHi).addReg(V6C::A);

    MI.eraseFromParent();
    return true;
  }

  case V6C::V6C_SUB16: {
    // dst = lhs - rhs (16-bit)
    Register DstReg = MI.getOperand(0).getReg();
    Register LhsReg = MI.getOperand(1).getReg();
    Register RhsReg = MI.getOperand(2).getReg();

    // DCX/INX chains for small constants via cost model.
    // Subtraction is not commutative: only RhsReg can be the constant.
    if (isFlagsDefDead(MI) && DstReg == LhsReg) {
      MachineInstr *LXI = findDefiningLXI(MBB, MI.getIterator(), RhsReg, &RI);
      if (LXI) {
        int64_t ImmVal = LXI->getOperand(1).getImm();
        // Normalize unsigned 16-bit to signed.
        if (ImmVal > 0x7FFF)
          ImmVal -= 0x10000;
        if (ImmVal != 0) {
          unsigned AbsVal =
              static_cast<unsigned>(ImmVal > 0 ? ImmVal : -ImmVal);
          unsigned InxOpc = ImmVal > 0 ? V6C::DCX : V6C::INX;
          V6COptMode Mode = getV6COptMode(*MBB.getParent());
          V6CInstrCost InxCost = V6CCost::INX * AbsVal;
          V6CInstrCost DadCost = V6CCost::LXI + V6CCost::DAD;
          if (InxCost.isCheaperOrEqual(DadCost, Mode)) {
            for (unsigned I = 0; I < AbsVal; ++I)
              BuildMI(MBB, MI, DL, get(InxOpc), DstReg).addReg(DstReg);
            Register ConstReg = LXI->getOperand(0).getReg();
            if (LXI->getParent() == &MBB &&
                isRegDeadAfter(MBB, MI.getIterator(), ConstReg, &RI))
              LXI->eraseFromParent();
            MI.eraseFromParent();
            return true;
          }
        }
      }
    }

    MCRegister DstLo = RI.getSubReg(DstReg, V6C::sub_lo);
    MCRegister DstHi = RI.getSubReg(DstReg, V6C::sub_hi);
    MCRegister LhsLo = RI.getSubReg(LhsReg, V6C::sub_lo);
    MCRegister LhsHi = RI.getSubReg(LhsReg, V6C::sub_hi);
    MCRegister RhsLo = RI.getSubReg(RhsReg, V6C::sub_lo);
    MCRegister RhsHi = RI.getSubReg(RhsReg, V6C::sub_hi);

    BuildMI(MBB, MI, DL, get(V6C::MOVrr), V6C::A).addReg(LhsLo);
    BuildMI(MBB, MI, DL, get(V6C::SUBr), V6C::A)
        .addReg(V6C::A).addReg(RhsLo);
    BuildMI(MBB, MI, DL, get(V6C::MOVrr), DstLo).addReg(V6C::A);
    BuildMI(MBB, MI, DL, get(V6C::MOVrr), V6C::A).addReg(LhsHi);
    BuildMI(MBB, MI, DL, get(V6C::SBBr), V6C::A)
        .addReg(V6C::A).addReg(RhsHi);
    BuildMI(MBB, MI, DL, get(V6C::MOVrr), DstHi).addReg(V6C::A);

    MI.eraseFromParent();
    return true;
  }

  case V6C::V6C_AND16:
  case V6C::V6C_OR16:
  case V6C::V6C_XOR16: {
    // dst = lhs OP rhs (16-bit, pair-wise 8-bit)
    unsigned OpOpc;
    switch (MI.getOpcode()) {
    case V6C::V6C_AND16: OpOpc = V6C::ANAr; break;
    case V6C::V6C_OR16:  OpOpc = V6C::ORAr; break;
    case V6C::V6C_XOR16: OpOpc = V6C::XRAr; break;
    default: llvm_unreachable("unexpected opcode");
    }

    Register DstReg = MI.getOperand(0).getReg();
    Register LhsReg = MI.getOperand(1).getReg();
    Register RhsReg = MI.getOperand(2).getReg();

    MCRegister DstLo = RI.getSubReg(DstReg, V6C::sub_lo);
    MCRegister DstHi = RI.getSubReg(DstReg, V6C::sub_hi);
    MCRegister LhsLo = RI.getSubReg(LhsReg, V6C::sub_lo);
    MCRegister LhsHi = RI.getSubReg(LhsReg, V6C::sub_hi);
    MCRegister RhsLo = RI.getSubReg(RhsReg, V6C::sub_lo);
    MCRegister RhsHi = RI.getSubReg(RhsReg, V6C::sub_hi);

    BuildMI(MBB, MI, DL, get(V6C::MOVrr), V6C::A).addReg(LhsLo);
    BuildMI(MBB, MI, DL, get(OpOpc), V6C::A)
        .addReg(V6C::A).addReg(RhsLo);
    BuildMI(MBB, MI, DL, get(V6C::MOVrr), DstLo).addReg(V6C::A);
    BuildMI(MBB, MI, DL, get(V6C::MOVrr), V6C::A).addReg(LhsHi);
    BuildMI(MBB, MI, DL, get(OpOpc), V6C::A)
        .addReg(V6C::A).addReg(RhsHi);
    BuildMI(MBB, MI, DL, get(V6C::MOVrr), DstHi).addReg(V6C::A);

    MI.eraseFromParent();
    return true;
  }

  case V6C::V6C_CMP16_ZERO: {
    // O34: Zero-test for i16 — MOV A, Hi; ORA Lo → Z=1 iff pair==0.
    Register SrcReg = MI.getOperand(0).getReg();
    MCRegister SrcLo = RI.getSubReg(SrcReg, V6C::sub_lo);
    MCRegister SrcHi = RI.getSubReg(SrcReg, V6C::sub_hi);
    BuildMI(MBB, MI, DL, get(V6C::MOVrr), V6C::A).addReg(SrcHi);
    BuildMI(MBB, MI, DL, get(V6C::ORAr), V6C::A)
        .addReg(V6C::A).addReg(SrcLo);
    MI.eraseFromParent();
    return true;
  }

  case V6C::V6C_CMP16: {
    // Compare lhs vs rhs (16-bit) via SUB/SBB.
    // Sets FLAGS: C for unsigned, S for signed. Z only for hi byte.
    Register LhsReg = MI.getOperand(0).getReg();
    Register RhsReg = MI.getOperand(1).getReg();

    MCRegister LhsLo = RI.getSubReg(LhsReg, V6C::sub_lo);
    MCRegister LhsHi = RI.getSubReg(LhsReg, V6C::sub_hi);
    MCRegister RhsLo = RI.getSubReg(RhsReg, V6C::sub_lo);
    MCRegister RhsHi = RI.getSubReg(RhsReg, V6C::sub_hi);

    BuildMI(MBB, MI, DL, get(V6C::MOVrr), V6C::A).addReg(LhsLo);
    BuildMI(MBB, MI, DL, get(V6C::SUBr), V6C::A)
        .addReg(V6C::A).addReg(RhsLo);
    BuildMI(MBB, MI, DL, get(V6C::MOVrr), V6C::A).addReg(LhsHi);
    BuildMI(MBB, MI, DL, get(V6C::SBBr), V6C::A)
        .addReg(V6C::A).addReg(RhsHi);

    MI.eraseFromParent();
    return true;
  }

  case V6C::V6C_CMP16_IMM: {
    // O24: Compare lhs vs immediate (16-bit) via MVI+SUB/SBB.
    // Same as BR_CC16_IMM ordering expansion, minus the Jcc.
    // The K→K-1 + CC inversion was already done in LowerSELECT_CC.
    Register LhsReg = MI.getOperand(0).getReg();
    MachineOperand &RhsOp = MI.getOperand(1);

    MCRegister LhsLo = RI.getSubReg(LhsReg, V6C::sub_lo);
    MCRegister LhsHi = RI.getSubReg(LhsReg, V6C::sub_hi);

    auto addImmLo = [&](MachineInstrBuilder &MIB) {
      if (RhsOp.isImm()) {
        MIB.addImm(RhsOp.getImm() & 0xFF);
      } else if (RhsOp.isGlobal()) {
        MIB.addGlobalAddress(RhsOp.getGlobal(), RhsOp.getOffset(),
                             V6CII::MO_LO8);
      } else if (RhsOp.isSymbol()) {
        MIB.addExternalSymbol(RhsOp.getSymbolName(), V6CII::MO_LO8);
      } else {
        llvm_unreachable("Unexpected operand type in V6C_CMP16_IMM");
      }
    };
    auto addImmHi = [&](MachineInstrBuilder &MIB) {
      if (RhsOp.isImm()) {
        MIB.addImm((RhsOp.getImm() >> 8) & 0xFF);
      } else if (RhsOp.isGlobal()) {
        MIB.addGlobalAddress(RhsOp.getGlobal(), RhsOp.getOffset(),
                             V6CII::MO_HI8);
      } else if (RhsOp.isSymbol()) {
        MIB.addExternalSymbol(RhsOp.getSymbolName(), V6CII::MO_HI8);
      } else {
        llvm_unreachable("Unexpected operand type in V6C_CMP16_IMM");
      }
    };

    {
      auto MIB = BuildMI(MBB, MI, DL, get(V6C::MVIr), V6C::A);
      addImmLo(MIB);
    }
    BuildMI(MBB, MI, DL, get(V6C::SUBr), V6C::A)
        .addReg(V6C::A).addReg(LhsLo);
    {
      auto MIB = BuildMI(MBB, MI, DL, get(V6C::MVIr), V6C::A);
      addImmHi(MIB);
    }
    BuildMI(MBB, MI, DL, get(V6C::SBBr), V6C::A)
        .addReg(V6C::A).addReg(LhsHi);

    MI.eraseFromParent();
    return true;
  }

  case V6C::V6C_BR_CC16: {
    // Fused 16-bit compare + conditional branch.
    // Different sequences depending on condition code.
    // Operand layout: 0=$lhs, 1=$rhs, 2=$cc, 3=$dst
    Register LhsReg = MI.getOperand(0).getReg();
    Register RhsReg = MI.getOperand(1).getReg();
    int64_t CC = MI.getOperand(2).getImm();
    MachineBasicBlock *Target = MI.getOperand(3).getMBB();

    MCRegister LhsLo = RI.getSubReg(LhsReg, V6C::sub_lo);
    MCRegister LhsHi = RI.getSubReg(LhsReg, V6C::sub_hi);
    MCRegister RhsLo = RI.getSubReg(RhsReg, V6C::sub_lo);
    MCRegister RhsHi = RI.getSubReg(RhsReg, V6C::sub_hi);

    if (CC == V6CCC::COND_Z || CC == V6CCC::COND_NZ) {
      // EQ/NE: CMP-based non-destructive expansion with MBB splitting.
      // Each byte is compared independently with an early-exit branch.
      // Neither LHS nor RHS is clobbered.
      //
      // IMPORTANT: We must NOT splice instructions from MBB to the new
      // block — ExpandPostRAPseudos uses make_early_inc_range which
      // pre-advances the iterator, and splicing would move that iterator
      // into the new MBB, causing an infinite loop. Instead, we record
      // MBB's successors, clear them, and set up both blocks from scratch.

      // Record original successors before modifying.
      SmallVector<MachineBasicBlock *, 2> OrigSuccessors(
          MBB.successors().begin(), MBB.successors().end());

      // Find the fallthrough successor (the one that's not Target).
      MachineBasicBlock *FallthroughMBB = nullptr;
      for (auto *Succ : OrigSuccessors) {
        if (Succ != Target) {
          FallthroughMBB = Succ;
          break;
        }
      }
      // If there's only one successor (Target == fallthrough), use it.
      if (!FallthroughMBB && OrigSuccessors.size() == 1)
        FallthroughMBB = OrigSuccessors[0];

      // Remove all original successors from MBB.
      while (!MBB.succ_empty())
        MBB.removeSuccessor(MBB.succ_begin());

      // Erase all terminators from MBB (V6C_BR_CC16 + any trailing JMP).
      // We must not use MI after this since it gets erased here.
      while (!MBB.empty() && MBB.back().isTerminator())
        MBB.pop_back();

      // Create CompareHiMBB for the second byte comparison.
      MachineFunction *MF = MBB.getParent();
      MachineBasicBlock *CompareHiMBB =
          MF->CreateMachineBasicBlock(MBB.getBasicBlock());
      MF->insert(std::next(MBB.getIterator()), CompareHiMBB);

      if (CC == V6CCC::COND_NZ) {
        // NE: both JNZ go to Target.
        //   MBB: MOV A, LhsLo; CMP RhsLo; JNZ Target → fallthrough CompareHiMBB
        //   CompareHiMBB: MOV A, LhsHi; CMP RhsHi; JNZ Target; JMP FallthroughMBB

        BuildMI(&MBB, DL, get(V6C::MOVrr), V6C::A).addReg(LhsLo);
        BuildMI(&MBB, DL, get(V6C::CMPr))
            .addReg(V6C::A).addReg(RhsLo);
        BuildMI(&MBB, DL, get(V6C::JNZ)).addMBB(Target);

        MBB.addSuccessor(Target);
        MBB.addSuccessor(CompareHiMBB);

        BuildMI(CompareHiMBB, DL, get(V6C::MOVrr), V6C::A).addReg(LhsHi);
        BuildMI(CompareHiMBB, DL, get(V6C::CMPr))
            .addReg(V6C::A).addReg(RhsHi);
        BuildMI(CompareHiMBB, DL, get(V6C::JNZ)).addMBB(Target);
        // Explicit JMP so analyzeBranch sees Cond+Uncond (Jcc Target + JMP Fallthrough).
        // BranchFolding will remove this JMP if FallthroughMBB is the layout successor.
        BuildMI(CompareHiMBB, DL, get(V6C::JMP)).addMBB(FallthroughMBB);

        CompareHiMBB->addSuccessor(Target);
        CompareHiMBB->addSuccessor(FallthroughMBB);

      } else {
        // EQ: first JNZ skips to fallthrough, second JZ jumps to target.
        //   MBB: MOV A, LhsLo; CMP RhsLo; JNZ FallthroughMBB → fallthrough CompareHiMBB
        //   CompareHiMBB: MOV A, LhsHi; CMP RhsHi; JZ Target; JMP FallthroughMBB

        BuildMI(&MBB, DL, get(V6C::MOVrr), V6C::A).addReg(LhsLo);
        BuildMI(&MBB, DL, get(V6C::CMPr))
            .addReg(V6C::A).addReg(RhsLo);
        BuildMI(&MBB, DL, get(V6C::JNZ)).addMBB(FallthroughMBB);

        MBB.addSuccessor(FallthroughMBB);
        MBB.addSuccessor(CompareHiMBB);

        BuildMI(CompareHiMBB, DL, get(V6C::MOVrr), V6C::A).addReg(LhsHi);
        BuildMI(CompareHiMBB, DL, get(V6C::CMPr))
            .addReg(V6C::A).addReg(RhsHi);
        BuildMI(CompareHiMBB, DL, get(V6C::JZ)).addMBB(Target);
        // Explicit JMP so analyzeBranch sees Cond+Uncond (Jcc Target + JMP Fallthrough).
        // BranchFolding will remove this JMP if FallthroughMBB is the layout successor.
        BuildMI(CompareHiMBB, DL, get(V6C::JMP)).addMBB(FallthroughMBB);

        CompareHiMBB->addSuccessor(Target);
        CompareHiMBB->addSuccessor(FallthroughMBB);
      }

      // MI was already erased by the pop_back loop above.
      return true;
    }

    // For C/NC/M/P: use SUB/SBB sequence then Jcc.
    // SUB lo, SBB hi → carry/sign flag correct for unsigned/signed comparison.
    {
      unsigned JccOpc;
      switch (CC) {
      default: llvm_unreachable("Unknown V6C condition code");
      case V6CCC::COND_C:  JccOpc = V6C::JC;  break;
      case V6CCC::COND_NC: JccOpc = V6C::JNC; break;
      case V6CCC::COND_M:  JccOpc = V6C::JM;  break;
      case V6CCC::COND_P:  JccOpc = V6C::JP;  break;
      case V6CCC::COND_PO: JccOpc = V6C::JPO; break;
      case V6CCC::COND_PE: JccOpc = V6C::JPE; break;
      }

      BuildMI(MBB, MI, DL, get(V6C::MOVrr), V6C::A).addReg(LhsLo);
      BuildMI(MBB, MI, DL, get(V6C::SUBr), V6C::A)
          .addReg(V6C::A).addReg(RhsLo);
      BuildMI(MBB, MI, DL, get(V6C::MOVrr), V6C::A).addReg(LhsHi);
      BuildMI(MBB, MI, DL, get(V6C::SBBr), V6C::A)
          .addReg(V6C::A).addReg(RhsHi);
      BuildMI(MBB, MI, DL, get(JccOpc)).addMBB(Target);

      MI.eraseFromParent();
      return true;
    }
  }

  case V6C::V6C_BR_CC16_IMM: {
    // Fused 16-bit compare + branch with immediate RHS.
    // Operand layout: 0=$lhs(GR16), 1=$rhs(imm16), 2=$cc, 3=$dst
    // Expansion: MVI A, lo8(rhs); CMP LhsLo; Jcc; MVI A, hi8(rhs); CMP LhsHi; Jcc
    Register LhsReg = MI.getOperand(0).getReg();
    MachineOperand &RhsOp = MI.getOperand(1);
    int64_t CC = MI.getOperand(2).getImm();
    MachineBasicBlock *Target = MI.getOperand(3).getMBB();

    assert((CC == V6CCC::COND_Z || CC == V6CCC::COND_NZ ||
            CC == V6CCC::COND_C || CC == V6CCC::COND_NC ||
            CC == V6CCC::COND_M || CC == V6CCC::COND_P) &&
           "V6C_BR_CC16_IMM: unsupported condition code");

    MCRegister LhsLo = RI.getSubReg(LhsReg, V6C::sub_lo);
    MCRegister LhsHi = RI.getSubReg(LhsReg, V6C::sub_hi);

    // --- O27: Fast zero-test path (MOV A, Hi; ORA Lo; Jcc) ---
    // When comparing against immediate 0, use the 8080 idiom:
    //   MOV A, Hi; ORA Lo → Z flag set iff (Hi|Lo)==0, i.e. pair==0
    // This avoids the MBB split and saves 10B+24cc per instance.
    if (RhsOp.isImm() && RhsOp.getImm() == 0) {
      unsigned JccOpc = (CC == V6CCC::COND_Z) ? V6C::JZ : V6C::JNZ;
      BuildMI(MBB, MI, DL, get(V6C::MOVrr), V6C::A).addReg(LhsHi);
      BuildMI(MBB, MI, DL, get(V6C::ORAr), V6C::A)
          .addReg(V6C::A).addReg(LhsLo);
      BuildMI(MBB, MI, DL, get(JccOpc)).addMBB(Target);
      MI.eraseFromParent();
      return true;
    }

    // Build MVI operands: for plain integers, mask directly.
    // For global addresses, use target flags (MO_LO8/MO_HI8) — the
    // AsmPrinter wraps them in V6CMCExpr for lo8/hi8 assembly output.
    auto addImmLo = [&](MachineInstrBuilder &MIB) {
      if (RhsOp.isImm()) {
        MIB.addImm(RhsOp.getImm() & 0xFF);
      } else if (RhsOp.isGlobal()) {
        MIB.addGlobalAddress(RhsOp.getGlobal(), RhsOp.getOffset(),
                             V6CII::MO_LO8);
      } else if (RhsOp.isSymbol()) {
        MIB.addExternalSymbol(RhsOp.getSymbolName(), V6CII::MO_LO8);
      } else {
        llvm_unreachable("Unexpected operand type in V6C_BR_CC16_IMM");
      }
    };
    auto addImmHi = [&](MachineInstrBuilder &MIB) {
      if (RhsOp.isImm()) {
        MIB.addImm((RhsOp.getImm() >> 8) & 0xFF);
      } else if (RhsOp.isGlobal()) {
        MIB.addGlobalAddress(RhsOp.getGlobal(), RhsOp.getOffset(),
                             V6CII::MO_HI8);
      } else if (RhsOp.isSymbol()) {
        MIB.addExternalSymbol(RhsOp.getSymbolName(), V6CII::MO_HI8);
      } else {
        llvm_unreachable("Unexpected operand type in V6C_BR_CC16_IMM");
      }
    };

    // O24: Ordering conditions (C/NC/M/P) — MVI+SUB/SBB then Jcc.
    // Unlike EQ/NE, ordering processes both bytes via the borrow chain
    // before a single conditional branch. No MBB splitting needed.
    if (CC == V6CCC::COND_C || CC == V6CCC::COND_NC ||
        CC == V6CCC::COND_M || CC == V6CCC::COND_P) {
      unsigned JccOpc;
      switch (CC) {
      default: llvm_unreachable("Unknown ordering CC");
      case V6CCC::COND_C:  JccOpc = V6C::JC;  break;
      case V6CCC::COND_NC: JccOpc = V6C::JNC; break;
      case V6CCC::COND_M:  JccOpc = V6C::JM;  break;
      case V6CCC::COND_P:  JccOpc = V6C::JP;  break;
      }

      {
        auto MIB = BuildMI(MBB, MI, DL, get(V6C::MVIr), V6C::A);
        addImmLo(MIB);
      }
      BuildMI(MBB, MI, DL, get(V6C::SUBr), V6C::A)
          .addReg(V6C::A).addReg(LhsLo);
      {
        auto MIB = BuildMI(MBB, MI, DL, get(V6C::MVIr), V6C::A);
        addImmHi(MIB);
      }
      BuildMI(MBB, MI, DL, get(V6C::SBBr), V6C::A)
          .addReg(V6C::A).addReg(LhsHi);
      BuildMI(MBB, MI, DL, get(JccOpc)).addMBB(Target);

      MI.eraseFromParent();
      return true;
    }

    // EQ/NE: Same MBB-splitting pattern as V6C_BR_CC16 EQ/NE path.
    SmallVector<MachineBasicBlock *, 2> OrigSuccessors(
        MBB.successors().begin(), MBB.successors().end());

    MachineBasicBlock *FallthroughMBB = nullptr;
    for (auto *Succ : OrigSuccessors) {
      if (Succ != Target) {
        FallthroughMBB = Succ;
        break;
      }
    }
    if (!FallthroughMBB && OrigSuccessors.size() == 1)
      FallthroughMBB = OrigSuccessors[0];

    while (!MBB.succ_empty())
      MBB.removeSuccessor(MBB.succ_begin());

    while (!MBB.empty() && MBB.back().isTerminator())
      MBB.pop_back();

    // O29: When lo8 == hi8, skip the hi-byte MVI (A already holds the value
    // from the lo-byte comparison — CMP and Jcc don't modify A).
    bool SameLoHi = RhsOp.isImm() &&
        (RhsOp.getImm() & 0xFF) == ((RhsOp.getImm() >> 8) & 0xFF);

    MachineFunction *MF = MBB.getParent();
    MachineBasicBlock *CompareHiMBB =
        MF->CreateMachineBasicBlock(MBB.getBasicBlock());
    MF->insert(std::next(MBB.getIterator()), CompareHiMBB);

    if (CC == V6CCC::COND_NZ) {
      // NE: MVI A, lo8; CMP LhsLo; JNZ Target | MVI A, hi8; CMP LhsHi; JNZ Target
      {
        auto MIB = BuildMI(&MBB, DL, get(V6C::MVIr), V6C::A);
        addImmLo(MIB);
      }
      BuildMI(&MBB, DL, get(V6C::CMPr))
          .addReg(V6C::A).addReg(LhsLo);
      BuildMI(&MBB, DL, get(V6C::JNZ)).addMBB(Target);

      MBB.addSuccessor(Target);
      MBB.addSuccessor(CompareHiMBB);

      if (!SameLoHi) {
        auto MIB = BuildMI(CompareHiMBB, DL, get(V6C::MVIr), V6C::A);
        addImmHi(MIB);
      }
      BuildMI(CompareHiMBB, DL, get(V6C::CMPr))
          .addReg(V6C::A).addReg(LhsHi);
      BuildMI(CompareHiMBB, DL, get(V6C::JNZ)).addMBB(Target);
      BuildMI(CompareHiMBB, DL, get(V6C::JMP)).addMBB(FallthroughMBB);

      CompareHiMBB->addSuccessor(Target);
      CompareHiMBB->addSuccessor(FallthroughMBB);
    } else {
      // EQ: MVI A, lo8; CMP LhsLo; JNZ Fallthrough | MVI A, hi8; CMP LhsHi; JZ Target
      {
        auto MIB = BuildMI(&MBB, DL, get(V6C::MVIr), V6C::A);
        addImmLo(MIB);
      }
      BuildMI(&MBB, DL, get(V6C::CMPr))
          .addReg(V6C::A).addReg(LhsLo);
      BuildMI(&MBB, DL, get(V6C::JNZ)).addMBB(FallthroughMBB);

      MBB.addSuccessor(FallthroughMBB);
      MBB.addSuccessor(CompareHiMBB);

      if (!SameLoHi) {
        auto MIB = BuildMI(CompareHiMBB, DL, get(V6C::MVIr), V6C::A);
        addImmHi(MIB);
      }
      BuildMI(CompareHiMBB, DL, get(V6C::CMPr))
          .addReg(V6C::A).addReg(LhsHi);
      BuildMI(CompareHiMBB, DL, get(V6C::JZ)).addMBB(Target);
      BuildMI(CompareHiMBB, DL, get(V6C::JMP)).addMBB(FallthroughMBB);

      CompareHiMBB->addSuccessor(Target);
      CompareHiMBB->addSuccessor(FallthroughMBB);
    }

    // MI was already erased by the pop_back loop above.
    return true;
  }

  //===------------------------------------------------------------------===//
  // M7: i16 load/store pseudo expansions
  //===------------------------------------------------------------------===//

  case V6C::V6C_LOAD16_P: {
    // Load 16-bit value from address in register pair.
    // addr=HL: load directly (dst must be DE or BC).
    // addr=DE: XCHG; load into dst; XCHG (preserves HL, 4cc overhead).
    // addr=BC: PUSH HL; MOV H,B; MOV L,C; load; POP HL (preserves HL).
    Register DstReg = MI.getOperand(0).getReg();
    Register AddrReg = MI.getOperand(1).getReg();

    MCRegister DstLo = RI.getSubReg(DstReg, V6C::sub_lo);
    MCRegister DstHi = RI.getSubReg(DstReg, V6C::sub_hi);

    // Helper: emit the MOVrM; INX HL; MOVrM load sequence.
    auto emitLoad = [&]() {
      if (DstLo == V6C::L || DstLo == V6C::H) {
        // Dst overlaps HL — use A as temp for the low byte.
        BuildMI(MBB, MI, DL, get(V6C::MOVrM), V6C::A);
        BuildMI(MBB, MI, DL, get(V6C::INX), V6C::HL).addReg(V6C::HL);
        BuildMI(MBB, MI, DL, get(V6C::MOVrM), DstHi);
        BuildMI(MBB, MI, DL, get(V6C::MOVrr), DstLo).addReg(V6C::A);
      } else {
        BuildMI(MBB, MI, DL, get(V6C::MOVrM), DstLo);
        BuildMI(MBB, MI, DL, get(V6C::INX), V6C::HL).addReg(V6C::HL);
        BuildMI(MBB, MI, DL, get(V6C::MOVrM), DstHi);
      }
    };

    if (AddrReg == V6C::HL) {
      // Addr already in HL — load directly.
      emitLoad();
    } else if (AddrReg == V6C::DE) {
      // XCHG to get addr into HL (preserves both via swap).
      BuildMI(MBB, MI, DL, get(V6C::XCHG));
      emitLoad();
      BuildMI(MBB, MI, DL, get(V6C::XCHG));
    } else {
      // Addr=BC: preserve HL via PUSH/POP.
      // O42: skip PUSH/POP HL when HL is dead after this instruction.
      bool HLDead = isRegDeadAtMI(V6C::HL, MI, MBB, &RI);
      if (!HLDead)
        BuildMI(MBB, MI, DL, get(V6C::PUSH))
            .addReg(V6C::HL, RegState::Kill)
            .addReg(V6C::SP, RegState::ImplicitDefine);
      BuildMI(MBB, MI, DL, get(V6C::MOVrr), V6C::H).addReg(V6C::B);
      BuildMI(MBB, MI, DL, get(V6C::MOVrr), V6C::L).addReg(V6C::C);
      emitLoad();
      if (!HLDead)
        BuildMI(MBB, MI, DL, get(V6C::POP), V6C::HL)
            .addReg(V6C::SP, RegState::ImplicitDefine);
    }

    MI.eraseFromParent();
    return true;
  }

  case V6C::V6C_STORE16_P: {
    // Store 16-bit value to address in register pair.
    Register ValReg = MI.getOperand(0).getReg();
    Register AddrReg = MI.getOperand(1).getReg();

    MCRegister ValLo = RI.getSubReg(ValReg, V6C::sub_lo);
    MCRegister ValHi = RI.getSubReg(ValReg, V6C::sub_hi);

    if (ValReg == V6C::HL) {
      // Value is in HL — can't just copy addr to HL (would clobber value).
      if (AddrReg == V6C::HL) {
        // Self-store: store HL to [HL]. Use A to save hi byte
        // because INX HL might carry from L into H.
        BuildMI(MBB, MI, DL, get(V6C::MOVrr), V6C::A).addReg(V6C::H);
        BuildMI(MBB, MI, DL, get(V6C::MOVMr)).addReg(V6C::L);
        BuildMI(MBB, MI, DL, get(V6C::INX), V6C::HL).addReg(V6C::HL);
        BuildMI(MBB, MI, DL, get(V6C::MOVMr)).addReg(V6C::A);
      } else if (AddrReg == V6C::DE) {
        // Use STAX DE + PUSH/POP to preserve DE.
        // O42: skip PUSH/POP DE when DE is dead after this instruction.
        bool DEDead = isRegDeadAtMI(V6C::DE, MI, MBB, &RI);
        if (!DEDead)
          BuildMI(MBB, MI, DL, get(V6C::PUSH)).addReg(V6C::DE);
        BuildMI(MBB, MI, DL, get(V6C::MOVrr), V6C::A).addReg(V6C::L);
        BuildMI(MBB, MI, DL, get(V6C::STAX))
            .addReg(V6C::A).addReg(V6C::DE);
        BuildMI(MBB, MI, DL, get(V6C::INX), V6C::DE).addReg(V6C::DE);
        BuildMI(MBB, MI, DL, get(V6C::MOVrr), V6C::A).addReg(V6C::H);
        BuildMI(MBB, MI, DL, get(V6C::STAX))
            .addReg(V6C::A).addReg(V6C::DE);
        if (!DEDead)
          BuildMI(MBB, MI, DL, get(V6C::POP), V6C::DE);
      } else {
        // Addr=BC: use STAX BC + PUSH/POP to preserve BC.
        // O42: skip PUSH/POP BC when BC is dead after this instruction.
        bool BCDead = isRegDeadAtMI(V6C::BC, MI, MBB, &RI);
        if (!BCDead)
          BuildMI(MBB, MI, DL, get(V6C::PUSH)).addReg(V6C::BC);
        BuildMI(MBB, MI, DL, get(V6C::MOVrr), V6C::A).addReg(V6C::L);
        BuildMI(MBB, MI, DL, get(V6C::STAX))
            .addReg(V6C::A).addReg(V6C::BC);
        BuildMI(MBB, MI, DL, get(V6C::INX), V6C::BC).addReg(V6C::BC);
        BuildMI(MBB, MI, DL, get(V6C::MOVrr), V6C::A).addReg(V6C::H);
        BuildMI(MBB, MI, DL, get(V6C::STAX))
            .addReg(V6C::A).addReg(V6C::BC);
        if (!BCDead)
          BuildMI(MBB, MI, DL, get(V6C::POP), V6C::BC);
      }
    } else {
      // Value is NOT in HL — safe to copy addr to HL.
      if (AddrReg != V6C::HL) {
        MCRegister AddrHi = RI.getSubReg(AddrReg, V6C::sub_hi);
        MCRegister AddrLo = RI.getSubReg(AddrReg, V6C::sub_lo);
        BuildMI(MBB, MI, DL, get(V6C::MOVrr), V6C::H).addReg(AddrHi);
        BuildMI(MBB, MI, DL, get(V6C::MOVrr), V6C::L).addReg(AddrLo);
      }
      BuildMI(MBB, MI, DL, get(V6C::MOVMr)).addReg(ValLo);
      BuildMI(MBB, MI, DL, get(V6C::INX), V6C::HL).addReg(V6C::HL);
      BuildMI(MBB, MI, DL, get(V6C::MOVMr)).addReg(ValHi);
    }

    MI.eraseFromParent();
    return true;
  }

  case V6C::V6C_LOAD16_G: {
    // Load 16-bit from global address.
    // dst=HL: LHLD addr (3B, 16cc) — optimal.
    // dst=DE: XCHG; LHLD addr; XCHG (5B, 24cc) — preserves HL via swap.
    // dst=BC: PUSH HL; LHLD addr; MOV B,H; MOV C,L; POP HL (7B, 46cc).
    Register DstReg = MI.getOperand(0).getReg();
    MachineOperand &AddrOp = MI.getOperand(1);

    auto emitLHLD = [&](MachineBasicBlock::iterator InsertPt) {
      auto MIB = BuildMI(MBB, InsertPt, DL, get(V6C::LHLD), V6C::HL);
      if (AddrOp.isGlobal())
        MIB.addGlobalAddress(AddrOp.getGlobal(), AddrOp.getOffset());
      else
        MIB.addImm(AddrOp.getImm());
    };

    if (DstReg == V6C::HL) {
      emitLHLD(MI);
    } else if (DstReg == V6C::DE) {
      // XCHG; LHLD addr; XCHG — saves 2B + 22cc vs PUSH/POP path.
      BuildMI(MBB, MI, DL, get(V6C::XCHG));
      emitLHLD(MI);
      BuildMI(MBB, MI, DL, get(V6C::XCHG));
    } else {
      // BC case: PUSH HL; LHLD; MOV B,H; MOV C,L; POP HL
      MCRegister DstLo = RI.getSubReg(DstReg, V6C::sub_lo);
      MCRegister DstHi = RI.getSubReg(DstReg, V6C::sub_hi);

      // O42: skip PUSH/POP HL when HL is dead after this instruction.
      bool HLDead = isRegDeadAtMI(V6C::HL, MI, MBB, &RI);
      if (!HLDead)
        BuildMI(MBB, MI, DL, get(V6C::PUSH))
            .addReg(V6C::HL, RegState::Kill)
            .addReg(V6C::SP, RegState::ImplicitDefine);
      emitLHLD(MI);
      BuildMI(MBB, MI, DL, get(V6C::MOVrr), DstHi).addReg(V6C::H);
      BuildMI(MBB, MI, DL, get(V6C::MOVrr), DstLo).addReg(V6C::L);
      if (!HLDead)
        BuildMI(MBB, MI, DL, get(V6C::POP), V6C::HL)
            .addReg(V6C::SP, RegState::ImplicitDefine);
    }

    MI.eraseFromParent();
    return true;
  }

  case V6C::V6C_STORE16_G: {
    // Store 16-bit to global address.
    Register ValReg = MI.getOperand(0).getReg();
    MachineOperand &AddrOp = MI.getOperand(1);

    if (ValReg == V6C::HL) {
      // Best case: SHLD addr
      auto MIB = BuildMI(MBB, MI, DL, get(V6C::SHLD)).addReg(V6C::HL);
      if (AddrOp.isGlobal())
        MIB.addGlobalAddress(AddrOp.getGlobal(), AddrOp.getOffset());
      else
        MIB.addImm(AddrOp.getImm());
    } else {
      MCRegister ValLo = RI.getSubReg(ValReg, V6C::sub_lo);
      MCRegister ValHi = RI.getSubReg(ValReg, V6C::sub_hi);

      auto MIB = BuildMI(MBB, MI, DL, get(V6C::LXI), V6C::HL);
      if (AddrOp.isGlobal())
        MIB.addGlobalAddress(AddrOp.getGlobal(), AddrOp.getOffset());
      else
        MIB.addImm(AddrOp.getImm());
      BuildMI(MBB, MI, DL, get(V6C::MOVMr)).addReg(ValLo);
      BuildMI(MBB, MI, DL, get(V6C::INX), V6C::HL).addReg(V6C::HL);
      BuildMI(MBB, MI, DL, get(V6C::MOVMr)).addReg(ValHi);
    }

    MI.eraseFromParent();
    return true;
  }

  case V6C::V6C_LOAD8_G: {
    // Expand to: LXI HL, addr; MOV $dst, M
    Register DstReg = MI.getOperand(0).getReg();
    MachineOperand &AddrOp = MI.getOperand(1);

    MachineInstrBuilder LXI = BuildMI(MBB, MI, DL, get(V6C::LXI))
        .addReg(V6C::HL, RegState::Define);
    if (AddrOp.isImm())
      LXI.addImm(AddrOp.getImm());
    else if (AddrOp.isGlobal())
      LXI.addGlobalAddress(AddrOp.getGlobal(), AddrOp.getOffset());
    else if (AddrOp.isSymbol())
      LXI.addExternalSymbol(AddrOp.getSymbolName());

    BuildMI(MBB, MI, DL, get(V6C::MOVrM))
        .addReg(DstReg, RegState::Define);

    MI.eraseFromParent();
    return true;
  }

  case V6C::V6C_STORE8_G: {
    // Expand to: LXI HL, addr; MOV M, $src
    Register SrcReg = MI.getOperand(0).getReg();
    MachineOperand &AddrOp = MI.getOperand(1);

    MachineInstrBuilder LXI = BuildMI(MBB, MI, DL, get(V6C::LXI))
        .addReg(V6C::HL, RegState::Define);
    if (AddrOp.isImm())
      LXI.addImm(AddrOp.getImm());
    else if (AddrOp.isGlobal())
      LXI.addGlobalAddress(AddrOp.getGlobal(), AddrOp.getOffset());
    else if (AddrOp.isSymbol())
      LXI.addExternalSymbol(AddrOp.getSymbolName());

    BuildMI(MBB, MI, DL, get(V6C::MOVMr))
        .addReg(SrcReg);

    MI.eraseFromParent();
    return true;
  }

  case V6C::V6C_SHL16: {
    // Left shift i16 by constant amount.
    // For 1-7: unrolled ADD self (lo+carry→hi).
    // For 8+: move lo→hi, zero lo, then shift hi in i8 domain.
    Register DstReg = MI.getOperand(0).getReg();
    Register SrcReg = MI.getOperand(1).getReg();
    unsigned ShAmt = MI.getOperand(2).getImm();

    MCRegister DstHi = RI.getSubReg(DstReg, V6C::sub_hi);
    MCRegister DstLo = RI.getSubReg(DstReg, V6C::sub_lo);
    MCRegister SrcHi = RI.getSubReg(SrcReg, V6C::sub_hi);
    MCRegister SrcLo = RI.getSubReg(SrcReg, V6C::sub_lo);

    if (DstReg != SrcReg) {
      BuildMI(MBB, MI, DL, get(V6C::MOVrr), DstHi).addReg(SrcHi);
      BuildMI(MBB, MI, DL, get(V6C::MOVrr), DstLo).addReg(SrcLo);
    }

    if (ShAmt >= 8) {
      BuildMI(MBB, MI, DL, get(V6C::MOVrr), DstHi).addReg(DstLo);
      BuildMI(MBB, MI, DL, get(V6C::MVIr), DstLo).addImm(0);
      ShAmt -= 8;
      // Remaining: shift DstHi left by ShAmt in i8 domain (ADD A,A).
      for (unsigned i = 0; i < ShAmt; ++i) {
        BuildMI(MBB, MI, DL, get(V6C::MOVrr), V6C::A).addReg(DstHi);
        BuildMI(MBB, MI, DL, get(V6C::ADDr), V6C::A)
            .addReg(V6C::A).addReg(V6C::A);
        BuildMI(MBB, MI, DL, get(V6C::MOVrr), DstHi).addReg(V6C::A);
      }
    } else {
      // SHL by 1-7: unrolled 16-bit ADD self.
      for (unsigned i = 0; i < ShAmt; ++i) {
        BuildMI(MBB, MI, DL, get(V6C::MOVrr), V6C::A).addReg(DstLo);
        BuildMI(MBB, MI, DL, get(V6C::ADDr), V6C::A)
            .addReg(V6C::A).addReg(DstLo);
        BuildMI(MBB, MI, DL, get(V6C::MOVrr), DstLo).addReg(V6C::A);
        BuildMI(MBB, MI, DL, get(V6C::MOVrr), V6C::A).addReg(DstHi);
        BuildMI(MBB, MI, DL, get(V6C::ADCr), V6C::A)
            .addReg(V6C::A).addReg(DstHi);
        BuildMI(MBB, MI, DL, get(V6C::MOVrr), DstHi).addReg(V6C::A);
      }
    }

    MI.eraseFromParent();
    return true;
  }

  case V6C::V6C_SRL16: {
    // Logical right shift i16 by constant amount.
    // For 1-7: unrolled ORA A (clear CY) + RAR hi + RAR lo.
    // For 8+: move hi→lo, zero hi, then shift lo right.
    Register DstReg = MI.getOperand(0).getReg();
    Register SrcReg = MI.getOperand(1).getReg();
    unsigned ShAmt = MI.getOperand(2).getImm();

    MCRegister DstHi = RI.getSubReg(DstReg, V6C::sub_hi);
    MCRegister DstLo = RI.getSubReg(DstReg, V6C::sub_lo);
    MCRegister SrcHi = RI.getSubReg(SrcReg, V6C::sub_hi);
    MCRegister SrcLo = RI.getSubReg(SrcReg, V6C::sub_lo);

    if (DstReg != SrcReg) {
      BuildMI(MBB, MI, DL, get(V6C::MOVrr), DstHi).addReg(SrcHi);
      BuildMI(MBB, MI, DL, get(V6C::MOVrr), DstLo).addReg(SrcLo);
    }

    if (ShAmt >= 8) {
      // Move hi to lo, zero hi.
      BuildMI(MBB, MI, DL, get(V6C::MOVrr), DstLo).addReg(DstHi);
      BuildMI(MBB, MI, DL, get(V6C::MVIr), DstHi).addImm(0);
      ShAmt -= 8;
    }

    // Per-bit logical right shift: clear CY, RAR hi, RAR lo.
    for (unsigned i = 0; i < ShAmt; ++i) {
      // Load hi to A, ORA A to clear carry, RAR, store back.
      BuildMI(MBB, MI, DL, get(V6C::MOVrr), V6C::A).addReg(DstHi);
      BuildMI(MBB, MI, DL, get(V6C::ORAr), V6C::A)
          .addReg(V6C::A).addReg(V6C::A); // CY = 0, A unchanged
      BuildMI(MBB, MI, DL, get(V6C::RAR), V6C::A).addReg(V6C::A);
      BuildMI(MBB, MI, DL, get(V6C::MOVrr), DstHi).addReg(V6C::A);
      // Load lo to A, RAR (carry = hi bit 0), store back.
      BuildMI(MBB, MI, DL, get(V6C::MOVrr), V6C::A).addReg(DstLo);
      BuildMI(MBB, MI, DL, get(V6C::RAR), V6C::A).addReg(V6C::A);
      BuildMI(MBB, MI, DL, get(V6C::MOVrr), DstLo).addReg(V6C::A);
    }

    MI.eraseFromParent();
    return true;
  }

  case V6C::V6C_SRA16: {
    // Arithmetic right shift i16 by constant amount.
    // For 1-7: set CY=sign bit via RLC, then RAR hi, RAR lo.
    // For 8+: move hi→lo, sign-extend to hi, then shift remaining.
    Register DstReg = MI.getOperand(0).getReg();
    Register SrcReg = MI.getOperand(1).getReg();
    unsigned ShAmt = MI.getOperand(2).getImm();

    MCRegister DstHi = RI.getSubReg(DstReg, V6C::sub_hi);
    MCRegister DstLo = RI.getSubReg(DstReg, V6C::sub_lo);
    MCRegister SrcHi = RI.getSubReg(SrcReg, V6C::sub_hi);
    MCRegister SrcLo = RI.getSubReg(SrcReg, V6C::sub_lo);

    if (DstReg != SrcReg) {
      BuildMI(MBB, MI, DL, get(V6C::MOVrr), DstHi).addReg(SrcHi);
      BuildMI(MBB, MI, DL, get(V6C::MOVrr), DstLo).addReg(SrcLo);
    }

    if (ShAmt >= 8) {
      // Move hi to lo. Sign-extend hi byte: RLC (CY=sign), SBB A (A=0/-1).
      // Read DstHi before overwriting DstLo in case they alias (they don't
      // for valid register pairs, but be safe).
      BuildMI(MBB, MI, DL, get(V6C::MOVrr), V6C::A).addReg(DstHi);
      BuildMI(MBB, MI, DL, get(V6C::MOVrr), DstLo).addReg(DstHi);
      BuildMI(MBB, MI, DL, get(V6C::RLC), V6C::A).addReg(V6C::A);
      BuildMI(MBB, MI, DL, get(V6C::SBBr), V6C::A)
          .addReg(V6C::A).addReg(V6C::A);
      BuildMI(MBB, MI, DL, get(V6C::MOVrr), DstHi).addReg(V6C::A);
      ShAmt -= 8;
    }

    // Per-bit arithmetic right shift:
    // RLC to get sign bit into CY, reload hi, RAR hi, RAR lo.
    for (unsigned i = 0; i < ShAmt; ++i) {
      BuildMI(MBB, MI, DL, get(V6C::MOVrr), V6C::A).addReg(DstHi);
      BuildMI(MBB, MI, DL, get(V6C::RLC), V6C::A)
          .addReg(V6C::A); // CY = sign bit, A = junk
      BuildMI(MBB, MI, DL, get(V6C::MOVrr), V6C::A)
          .addReg(DstHi); // reload hi
      BuildMI(MBB, MI, DL, get(V6C::RAR), V6C::A)
          .addReg(V6C::A); // A = sign:hi[7:1], CY = hi[0]
      BuildMI(MBB, MI, DL, get(V6C::MOVrr), DstHi).addReg(V6C::A);
      BuildMI(MBB, MI, DL, get(V6C::MOVrr), V6C::A).addReg(DstLo);
      BuildMI(MBB, MI, DL, get(V6C::RAR), V6C::A)
          .addReg(V6C::A); // A = hi[0]:lo[7:1]
      BuildMI(MBB, MI, DL, get(V6C::MOVrr), DstLo).addReg(V6C::A);
    }

    MI.eraseFromParent();
    return true;
  }

  case V6C::V6C_LOAD8_P: {
    // HL-preserving expansion with 4-priority chain.
    Register DstReg = MI.getOperand(0).getReg();
    Register AddrReg = MI.getOperand(1).getReg();

    if (AddrReg == V6C::HL) {
      // Priority 1: addr is HL — just load (7cc)
      BuildMI(MBB, MI, DL, get(V6C::MOVrM))
          .addReg(DstReg, RegState::Define);
    } else if (DstReg == V6C::A &&
               (AddrReg == V6C::BC || AddrReg == V6C::DE)) {
      // Priority 2: LDAX — dst is A (7cc)
      BuildMI(MBB, MI, DL, get(V6C::LDAX))
          .addReg(DstReg, RegState::Define)
          .addReg(AddrReg);
    } else if ((AddrReg == V6C::BC || AddrReg == V6C::DE) &&
               isRegDeadAtMI(V6C::A, MI, MBB, &RI)) {
      // Priority 3: LDAX then move — A is dead (12cc)
      BuildMI(MBB, MI, DL, get(V6C::LDAX))
          .addReg(V6C::A, RegState::Define)
          .addReg(AddrReg);
      BuildMI(MBB, MI, DL, get(V6C::MOVrr))
          .addReg(DstReg, RegState::Define).addReg(V6C::A);
    } else {
      // Priority 4: fallback — save/restore HL (43cc)
      // O42: skip PUSH/POP HL when HL is dead after this instruction.
      bool HLDead = isRegDeadAtMI(V6C::HL, MI, MBB, &RI);
      if (!HLDead)
        BuildMI(MBB, MI, DL, get(V6C::PUSH)).addReg(V6C::HL);
      MCRegister Hi = RI.getSubReg(AddrReg, V6C::sub_hi);
      MCRegister Lo = RI.getSubReg(AddrReg, V6C::sub_lo);
      BuildMI(MBB, MI, DL, get(V6C::MOVrr))
          .addReg(V6C::H, RegState::Define).addReg(Hi);
      BuildMI(MBB, MI, DL, get(V6C::MOVrr))
          .addReg(V6C::L, RegState::Define).addReg(Lo);
      BuildMI(MBB, MI, DL, get(V6C::MOVrM))
          .addReg(DstReg, RegState::Define);
      if (!HLDead)
        BuildMI(MBB, MI, DL, get(V6C::POP))
            .addDef(V6C::HL);
    }
    MI.eraseFromParent();
    return true;
  }

  case V6C::V6C_STORE8_P: {
    // HL-preserving expansion with 4-priority chain.
    Register SrcReg = MI.getOperand(0).getReg();
    Register AddrReg = MI.getOperand(1).getReg();

    if (AddrReg == V6C::HL) {
      // Priority 1: addr is HL — just store (7cc)
      BuildMI(MBB, MI, DL, get(V6C::MOVMr)).addReg(SrcReg);
    } else if (SrcReg == V6C::A &&
               (AddrReg == V6C::BC || AddrReg == V6C::DE)) {
      // Priority 2: STAX — src already in A (7cc)
      BuildMI(MBB, MI, DL, get(V6C::STAX))
          .addReg(SrcReg).addReg(AddrReg);
    } else if ((AddrReg == V6C::BC || AddrReg == V6C::DE) &&
               isRegDeadAtMI(V6C::A, MI, MBB, &RI)) {
      // Priority 3: route through A for STAX — A is dead (12cc)
      BuildMI(MBB, MI, DL, get(V6C::MOVrr))
          .addReg(V6C::A, RegState::Define).addReg(SrcReg);
      BuildMI(MBB, MI, DL, get(V6C::STAX))
          .addReg(V6C::A).addReg(AddrReg);
    } else {
      // Priority 4: fallback — save/restore HL (43cc)
      // O42: skip PUSH/POP HL when HL is dead after this instruction.
      bool HLDead = isRegDeadAtMI(V6C::HL, MI, MBB, &RI);
      if (!HLDead)
        BuildMI(MBB, MI, DL, get(V6C::PUSH)).addReg(V6C::HL);
      MCRegister Hi = RI.getSubReg(AddrReg, V6C::sub_hi);
      MCRegister Lo = RI.getSubReg(AddrReg, V6C::sub_lo);
      BuildMI(MBB, MI, DL, get(V6C::MOVrr))
          .addReg(V6C::H, RegState::Define).addReg(Hi);
      BuildMI(MBB, MI, DL, get(V6C::MOVrr))
          .addReg(V6C::L, RegState::Define).addReg(Lo);
      BuildMI(MBB, MI, DL, get(V6C::MOVMr)).addReg(SrcReg);
      if (!HLDead)
        BuildMI(MBB, MI, DL, get(V6C::POP))
            .addDef(V6C::HL);
    }
    MI.eraseFromParent();
    return true;
  }
  }
}
