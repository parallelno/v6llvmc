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

// Returns true if, immediately before MI, the i8080 carry flag is provably
// already zero. Walks backward over instructions that do not modify FLAGS
// (MOV/MVI/LXI/INX/DCX/loads/stores/etc.) to the most recent FLAGS-defining
// instruction; CY is known reset only when that defining op is one of the
// 8080 logical ops (ANA/ANI/XRA/XRI/ORA/ORI), all of which clear CY as a
// side effect. Returns false on BB entry (live-in CY unknown) or any other
// FLAGS definer (ADD/SUB/CMP/INR-DCR/RAR/RLC/etc., or pseudos that may
// expand to such).
static bool priorClearsCarry(const MachineBasicBlock &MBB,
                              MachineBasicBlock::const_iterator MI) {
  while (MI != MBB.begin()) {
    --MI;
    if (MI->isDebugInstr())
      continue;
    if (!MI->definesRegister(V6C::FLAGS, /*TRI=*/nullptr))
      continue;
    switch (MI->getOpcode()) {
    case V6C::ANAr:
    case V6C::ANAM:
    case V6C::ANI:
    case V6C::XRAr:
    case V6C::XRAM:
    case V6C::XRI:
    case V6C::ORAr:
    case V6C::ORAM:
    case V6C::ORI:
      return true;
    default:
      return false;
    }
  }
  return false;
}

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

  // SP → DE / BC: route via HL but preserve the caller's HL.
  // Sequence: PUSH HL; LXI HL,2; DAD SP; MOV DestHi,H; MOV DestLo,L; POP HL.
  // The +2 in the LXI immediate cancels the SP -= 2 done by PUSH HL, so the
  // value materialised is the original SP value. Clobbers FLAGS (reserved).
  if (SrcReg == V6C::SP &&
      (DestReg == V6C::DE || DestReg == V6C::BC)) {
    const TargetRegisterInfo *TRI = &RI;
    MCRegister DestHi = TRI->getSubReg(DestReg, V6C::sub_hi);
    MCRegister DestLo = TRI->getSubReg(DestReg, V6C::sub_lo);
    BuildMI(MBB, MI, DL, get(V6C::PUSH)).addReg(V6C::HL);
    BuildMI(MBB, MI, DL, get(V6C::LXI), V6C::HL).addImm(2);
    BuildMI(MBB, MI, DL, get(V6C::DAD)).addReg(V6C::SP);
    BuildMI(MBB, MI, DL, get(V6C::MOVrr))
        .addReg(DestHi, RegState::Define)
        .addReg(V6C::H);
    BuildMI(MBB, MI, DL, get(V6C::MOVrr))
        .addReg(DestLo, RegState::Define)
        .addReg(V6C::L);
    BuildMI(MBB, MI, DL, get(V6C::POP), V6C::HL);
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
        Cand.getOperand(0).getReg() == Reg) {
      // O61: a patched LXI carries an MCSymbol imm, not a concrete imm.
      // Its value is unknown at compile time, so we cannot fold from it.
      if (!Cand.getOperand(1).isImm())
        return nullptr;
      return &Cand;
    }

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
        // O61: patched LXI has an opaque (MCSymbol) imm — can't fold.
        if (!I->getOperand(1).isImm())
          return nullptr;
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

/// Return true if Reg has a visible value before iterator I in MBB.
/// Backward scan: the most recent event wins — an explicit def keeps Reg
/// live, while a regmask clobber (e.g. from a CALL) renders it undef.
static bool isRegLiveBefore(MachineBasicBlock &MBB,
                            MachineBasicBlock::iterator I, Register Reg,
                            const TargetRegisterInfo *TRI) {
  while (I != MBB.begin()) {
    --I;
    bool FoundDef = false, FoundClobber = false;
    for (const MachineOperand &MO : I->operands()) {
      if (MO.isReg() && MO.isDef() && MO.getReg().isPhysical() &&
          TRI->regsOverlap(MO.getReg(), Reg))
        FoundDef = true;
      else if (MO.isRegMask() && MO.clobbersPhysReg(Reg))
        FoundClobber = true;
    }
    if (FoundDef)
      return true;
    if (FoundClobber)
      return false;
  }
  for (MCRegAliasIterator AI(Reg, TRI, /*IncludeSelf=*/true); AI.isValid();
       ++AI) {
    if (MBB.isLiveIn(*AI))
      return true;
  }
  return false;
}

static void markXchgUseUndef(MachineInstr *XchgMI, Register Reg) {
  if (MachineOperand *MO = XchgMI->findRegisterUseOperand(Reg,
                                                          /*isKill=*/false))
    MO->setIsUndef(true);
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

/// O71 — Find a GR8 register that is dead at MI, or Register() if none.
/// Skips A (callers handle A specially via PUSH PSW / POP PSW). Skips
/// any register aliased by Exclude1 / Exclude2 (typically the address
/// pair and/or destination pair of a 16-bit load expansion).
static Register findDeadGR8AtMI(const MachineInstr &MI,
                                MachineBasicBlock &MBB,
                                const TargetRegisterInfo *TRI,
                                Register Exclude1 = Register(),
                                Register Exclude2 = Register()) {
  // GR8 minus A. Order is arbitrary; preferring the BC pair first leaves
  // H/L (often live as pointer halves) for last.
  static const unsigned Candidates[] = {
      V6C::B, V6C::C, V6C::D, V6C::E, V6C::H, V6C::L,
  };
  for (unsigned R : Candidates) {
    if (Exclude1 && TRI->regsOverlap(R, Exclude1))
      continue;
    if (Exclude2 && TRI->regsOverlap(R, Exclude2))
      continue;
    if (isRegDeadAtMI(R, MI, MBB, TRI))
      return Register(R);
  }
  return Register();
}

/// O49 — Direct memory M-operand pseudo expansion helper.
/// Emits any M-operand instruction (ADDM/SUBM/.../MVIM/INRM/DCRM) with
/// appropriate HL/DE/BC address staging. `Emit` is a callable that
/// builds the physical instruction at the insertion point.
template <typename EmitFn>
static void expandMemOpM(MachineBasicBlock &MBB, MachineInstr &MI,
                         const V6CInstrInfo &TII,
                         const V6CRegisterInfo &RI,
                         Register AddrReg, EmitFn Emit) {
  DebugLoc DL = MI.getDebugLoc();
  auto Ip = MI.getIterator();

  if (AddrReg == V6C::HL) {
    Emit(MBB, Ip);
    return;
  }
  if (AddrReg == V6C::DE) {
    // XCHG; OP M; XCHG — restores HL and DE. The trailing XCHG is
    // omitted when HL is dead after MI: after the first XCHG the
    // address sits in HL while old-HL sits in DE, so skipping the
    // restore leaves DE holding old-HL (fine, DE may also be dead)
    // and HL holding the address (fine if HL is dead).
    bool HLDead = isRegDeadAtMI(V6C::HL, MI, MBB, &RI);
    BuildMI(MBB, Ip, DL, TII.get(V6C::XCHG));
    Emit(MBB, Ip);
    if (!HLDead)
      BuildMI(MBB, Ip, DL, TII.get(V6C::XCHG));
    return;
  }
  // AddrReg == V6C::BC — no swap instruction; copy B→H, C→L, restore HL.
  bool HLDead = isRegDeadAtMI(V6C::HL, MI, MBB, &RI);
  if (!HLDead)
    BuildMI(MBB, Ip, DL, TII.get(V6C::PUSH))
        .addReg(V6C::HL, RegState::Kill)
        .addReg(V6C::SP, RegState::ImplicitDefine);
  BuildMI(MBB, Ip, DL, TII.get(V6C::MOVrr), V6C::L).addReg(V6C::C);
  BuildMI(MBB, Ip, DL, TII.get(V6C::MOVrr), V6C::H).addReg(V6C::B);
  Emit(MBB, Ip);
  if (!HLDead)
    BuildMI(MBB, Ip, DL, TII.get(V6C::POP), V6C::HL)
        .addReg(V6C::SP, RegState::ImplicitDefine);
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

    // DE = DE + DE. Preserve HL with XCHG; DAD H; XCHG (18cc, 3B),
    // instead of the general A-byte chain (24cc, 6B). The second XCHG
    // restores old HL; if it was undef, mark the XCHG implicit reads as
    // undef for the MIR verifier.
    if (DstReg == V6C::DE && LhsReg == V6C::DE && RhsReg == V6C::DE) {
      bool HLLive = isRegLiveBefore(MBB, MI.getIterator(), V6C::HL, &RI);
      MachineInstr *FirstXchg = BuildMI(MBB, MI, DL, get(V6C::XCHG)).getInstr();
      BuildMI(MBB, MI, DL, get(V6C::DAD)).addReg(V6C::HL);
      MachineInstr *SecondXchg = BuildMI(MBB, MI, DL, get(V6C::XCHG)).getInstr();
      if (!HLLive) {
        markXchgUseUndef(FirstXchg, V6C::HL);
        markXchgUseUndef(SecondXchg, V6C::DE);
      }
      MI.eraseFromParent();
      return true;
    }

    // DE = DE + BC. Preserve HL with XCHG; DAD B; XCHG (20cc, 3B),
    // instead of the general A-byte chain. This is valid even when old HL
    // is live because the second XCHG restores it. If old HL is undef, mark
    // the corresponding XCHG implicit reads as undef for the MIR verifier.
    if (DstReg == V6C::DE &&
        ((LhsReg == V6C::DE && RhsReg == V6C::BC) ||
         (LhsReg == V6C::BC && RhsReg == V6C::DE))) {
      bool HLLive = isRegLiveBefore(MBB, MI.getIterator(), V6C::HL, &RI);
      MachineInstr *FirstXchg = BuildMI(MBB, MI, DL, get(V6C::XCHG)).getInstr();
      BuildMI(MBB, MI, DL, get(V6C::DAD)).addReg(V6C::BC);
      MachineInstr *SecondXchg = BuildMI(MBB, MI, DL, get(V6C::XCHG)).getInstr();
      if (!HLLive) {
        markXchgUseUndef(FirstXchg, V6C::HL);
        markXchgUseUndef(SecondXchg, V6C::DE);
      }
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

  case V6C::V6C_CMP8_ZERO: {
    // O80: Zero-test for i8 with three liveness-driven shapes.
    //   src = A          → ORA A                  (1B / 4cc)
    //   src ≠ A, A dead  → XRA A; CMP src         (2B / 8cc, O38 path)
    //   src ≠ A, A live  → INR src; DCR src       (2B / 16cc, A-preserving)
    // INR/DCR set Z/S/P/AC from src's original value and leave A and CY
    // untouched. All zero-test consumers (V6C_BRCOND / V6C_SELECT_CC)
    // read only Z/S/P, so the CY/AC divergence vs ORA A is unobservable.
    Register Src = MI.getOperand(0).getReg();
    bool SrcKilled = MI.getOperand(0).isKill();

    if (Src == V6C::A) {
      // Shape 1: src already in A → ORA A.
      BuildMI(MBB, MI, DL, get(V6C::ORAr), V6C::A)
          .addReg(V6C::A).addReg(V6C::A);
    } else if (isRegDeadAtMI(V6C::A, MI, MBB, &RI)) {
      // Shape 2: A dead → XRA A; CMP src (preserves O38 emission).
      BuildMI(MBB, MI, DL, get(V6C::XRAr), V6C::A)
          .addReg(V6C::A).addReg(V6C::A);
      BuildMI(MBB, MI, DL, get(V6C::CMPr))
          .addReg(V6C::A)
          .addReg(Src, getKillRegState(SrcKilled));
    } else {
      // Shape 3: A live → INR src; DCR src (A-preserving zero-test).
      // Both INR/DCR are tied ($rd = $src). The kill flag belongs only
      // on the second use (DCR) so the first (INR) doesn't kill src
      // before the pair completes.
      BuildMI(MBB, MI, DL, get(V6C::INRr), Src).addReg(Src);
      BuildMI(MBB, MI, DL, get(V6C::DCRr), Src)
          .addReg(Src, getKillRegState(SrcKilled));
    }

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
    // IMPORTANT: ORA only sets Z meaningfully — the C flag is cleared and
    // the S flag reflects bit 7 of the OR result, not the sign of $lhs.
    // So this fast path is only valid for EQ/NE (Z/NZ). For ordering
    // conditions (C/NC/M/P) against 0 we must fall through to the
    // MVI+SUB/SBB sequence below, which produces correct flags.
    if (RhsOp.isImm() && RhsOp.getImm() == 0 &&
        (CC == V6CCC::COND_Z || CC == V6CCC::COND_NZ)) {
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
    // O71 — Honest per-shape preservation.
    //
    // The pseudo declares (outs GR16:$dst, ins GR16:$addr) with no Defs.
    // Pre-RA passes treat the load as preserving every register except
    // $dst. The expander dispatches on the (addr, dst) physreg pair and
    // emits whatever cheap recovery code the shape needs to honour that
    // contract for live registers (DCX rp to undo INX, dead-GR8 spare to
    // avoid clobbering A, PUSH PSW / POP PSW or PUSH H / POP H as
    // last-resort wrappers).
    Register DstReg  = MI.getOperand(0).getReg();
    Register AddrReg = MI.getOperand(1).getReg();

    MCRegister DstLo = RI.getSubReg(DstReg, V6C::sub_lo);
    MCRegister DstHi = RI.getSubReg(DstReg, V6C::sub_hi);

    // Helper closures. All emit at MI (replaced below by eraseFromParent).
    auto emitDCX = [&](MCRegister Pair) {
      BuildMI(MBB, MI, DL, get(V6C::DCX), Pair).addReg(Pair);
    };
    auto emitINXHL = [&]() {
      BuildMI(MBB, MI, DL, get(V6C::INX), V6C::HL).addReg(V6C::HL);
    };
    auto emitMOVrM = [&](MCRegister Dst) {
      BuildMI(MBB, MI, DL, get(V6C::MOVrM), Dst);
    };
    auto emitMOVrr = [&](MCRegister Dst, MCRegister Src) {
      BuildMI(MBB, MI, DL, get(V6C::MOVrr), Dst).addReg(Src);
    };
    auto emitXCHG = [&]() {
      BuildMI(MBB, MI, DL, get(V6C::XCHG));
    };

    if (AddrReg == V6C::HL && DstReg == V6C::HL) {
      // Case 1: addr=HL, dst=HL.
      //   MOV Spare, M; INX H; MOV H, M; MOV L, Spare
      // Spare candidate must avoid HL (its halves are the destination).
      // No DCX H — dst=HL means original HL is being overwritten by
      // definition; not live across the pseudo as the prior value.
      Register Spare = findDeadGR8AtMI(MI, MBB, &RI, V6C::HL);
      bool UseA = !Spare;
      MCRegister Tmp = UseA ? MCRegister(V6C::A) : Spare.asMCReg();
      bool ALive = UseA && !isRegDeadAtMI(V6C::A, MI, MBB, &RI);
      if (ALive)
        BuildMI(MBB, MI, DL, get(V6C::PUSH)).addReg(V6C::PSW);
      emitMOVrM(Tmp);
      emitINXHL();
      emitMOVrM(V6C::H);
      emitMOVrr(V6C::L, Tmp);
      if (ALive)
        BuildMI(MBB, MI, DL, get(V6C::POP), V6C::PSW);
    } else if (AddrReg == V6C::HL) {
      // Case 2: addr=HL, dst ∈ {BC, DE}.
      //   MOV DstLo, M; INX H; MOV DstHi, M; (DCX H if HL live)
      emitMOVrM(DstLo);
      emitINXHL();
      emitMOVrM(DstHi);
      if (!isRegDeadAtMI(V6C::HL, MI, MBB, &RI))
        emitDCX(V6C::HL);
    } else if (AddrReg == V6C::DE && DstReg == V6C::DE) {
      // Case 4: addr=DE, dst=DE.
      //   XCHG; MOV Spare, M; INX H; MOV H, M; MOV L, Spare; XCHG
      //
      // Spare selection here is subtle. After the leading XCHG:
      //   HL = address     (used by the load body, must not be clobbered)
      //   DE = orig HL     (D = H_orig, E = L_orig)
      // The trailing XCHG swaps DE↔HL again, restoring orig HL into HL
      // and delivering *p (currently in HL) into DE. Whatever value is
      // sitting in D (resp. E) at the moment of XCHG #2 ends up in H
      // (resp. L) post-load. So the spare may be:
      //   B  iff B is dead across MI
      //   C  iff C is dead across MI
      //   D  iff H is dead across MI   (using D clobbers H_orig)
      //   E  iff L is dead across MI   (using E clobbers L_orig)
      //   H, L — never (they hold the address mid-sequence)
      // Falls back to A with PUSH PSW / POP PSW iff A is live.
      // No DCX D — dst=DE means caller wanted DE redefined.
      auto findCase4Spare = [&]() -> Register {
        if (isRegDeadAtMI(V6C::B, MI, MBB, &RI)) return Register(V6C::B);
        if (isRegDeadAtMI(V6C::C, MI, MBB, &RI)) return Register(V6C::C);
        if (isRegDeadAtMI(V6C::H, MI, MBB, &RI)) return Register(V6C::D);
        if (isRegDeadAtMI(V6C::L, MI, MBB, &RI)) return Register(V6C::E);
        return Register();
      };
      Register Spare = findCase4Spare();
      bool UseA = !Spare;
      MCRegister Tmp = UseA ? MCRegister(V6C::A) : Spare.asMCReg();
      bool ALive = UseA && !isRegDeadAtMI(V6C::A, MI, MBB, &RI);
      if (ALive)
        BuildMI(MBB, MI, DL, get(V6C::PUSH)).addReg(V6C::PSW);
      emitXCHG();
      emitMOVrM(Tmp);
      emitINXHL();
      emitMOVrM(V6C::H);
      emitMOVrr(V6C::L, Tmp);
      emitXCHG();
      if (ALive)
        BuildMI(MBB, MI, DL, get(V6C::POP), V6C::PSW);
    } else if (AddrReg == V6C::DE) {
      // Cases 3a / 3b: addr=DE, dst ∈ {BC, HL}.
      //   XCHG; MOV LoadLo, M; INX H; MOV LoadHi, M; XCHG; (DCX D if DE live)
      // For dst=BC: LoadLo=C, LoadHi=B (BC halves) — trailing XCHG just
      //             restores HL from the DE-stashed orig-HL.
      // For dst=HL: LoadLo=E, LoadHi=D — we cannot stage in H/L because
      //             HL holds the address after the leading XCHG. Stage
      //             in DE halves; the trailing XCHG then delivers
      //             HL ← loaded, DE ← address+1.
      MCRegister LoadLo, LoadHi;
      if (DstReg == V6C::HL) {
        LoadLo = V6C::E;
        LoadHi = V6C::D;
      } else {
        LoadLo = DstLo;
        LoadHi = DstHi;
      }
      emitXCHG();
      emitMOVrM(LoadLo);
      emitINXHL();
      emitMOVrM(LoadHi);
      emitXCHG();
      if (!isRegDeadAtMI(V6C::DE, MI, MBB, &RI))
        emitDCX(V6C::DE);
    } else if (DstReg == V6C::HL) {
      // Case 6: addr=BC, dst=HL. Two shapes; pick whichever is cheapest.
      //
      //   Shape A — M-staging (used when A is live AND a non-HL/BC GR8
      //   spare is dead, i.e. spare ∈ {D,E}). 6B / 48cc, no A traffic,
      //   BC preserved automatically:
      //     MOV H,B; MOV L,C; MOV S,M; INX H; MOV H,M; MOV L,S
      //
      //   Shape B — LDAX (otherwise). A is the staging temp; BC is
      //   corrupted by INX B and recovered with DCX B if live:
      //     [A-preserve]; LDAX B; MOV L,A; INX B; LDAX B; MOV H,A;
      //     [A-restore]; (DCX B if BC live)
      //   A-preserve = none (A dead) | PUSH PSW / POP PSW (A live, no spare).
      //   With A dead: 5B / 40cc (+1B/8cc if DCX B). With A live + no
      //   spare: 7B / 68cc (+1B/8cc if DCX B).
      //
      // No PUSH H / POP H — dst=HL means original HL is dead.
      bool ADead = isRegDeadAtMI(V6C::A, MI, MBB, &RI);
      Register Spare = findDeadGR8AtMI(MI, MBB, &RI, V6C::HL, V6C::BC);
      if (!ADead && Spare) {
        // Shape A.
        MCRegister Tmp = Spare.asMCReg();
        emitMOVrr(V6C::H, V6C::B);
        emitMOVrr(V6C::L, V6C::C);
        emitMOVrM(Tmp);
        emitINXHL();
        emitMOVrM(V6C::H);
        emitMOVrr(V6C::L, Tmp);
      } else {
        // Shape B.
        bool APushPop = !ADead;
        if (APushPop)
          BuildMI(MBB, MI, DL, get(V6C::PUSH)).addReg(V6C::PSW);
        BuildMI(MBB, MI, DL, get(V6C::LDAX), V6C::A).addReg(V6C::BC);
        emitMOVrr(V6C::L, V6C::A);
        BuildMI(MBB, MI, DL, get(V6C::INX), V6C::BC).addReg(V6C::BC);
        BuildMI(MBB, MI, DL, get(V6C::LDAX), V6C::A).addReg(V6C::BC);
        emitMOVrr(V6C::H, V6C::A);
        if (APushPop)
          BuildMI(MBB, MI, DL, get(V6C::POP), V6C::PSW);
        if (!isRegDeadAtMI(V6C::BC, MI, MBB, &RI))
          emitDCX(V6C::BC);
      }
    } else if (DstReg == V6C::BC) {
      // Case 5b: addr=BC, dst=BC. Three-tier dispatch (no DCX BC needed
      // since BC is the destination):
      //
      //   Tier 1 — HL fully dead (5B / 40cc):
      //     MOV H,B; MOV L,C; MOV C,M; INX H; MOV B,M
      //
      //   Tier 2 — A dead AND a GR8 spare (excluding BC) is dead
      //   (6B / 48cc). The spare buffers the low byte across INX B so we
      //   never write into the address pair before the second LDAX:
      //     LDAX B; MOV S,A; INX B; LDAX B; MOV B,A; MOV C,S
      //
      //   Tier 3 — worst case (7B / 68cc): PUSH H wraps tier-1 body.
      bool HLDead = isRegDeadAtMI(V6C::HL, MI, MBB, &RI);
      if (HLDead) {
        emitMOVrr(V6C::H, V6C::B);
        emitMOVrr(V6C::L, V6C::C);
        emitMOVrM(V6C::C);
        emitINXHL();
        emitMOVrM(V6C::B);
      } else {
        bool ADead = isRegDeadAtMI(V6C::A, MI, MBB, &RI);
        Register Spare =
            ADead ? findDeadGR8AtMI(MI, MBB, &RI, V6C::BC) : Register();
        if (Spare) {
          MCRegister Tmp = Spare.asMCReg();
          BuildMI(MBB, MI, DL, get(V6C::LDAX), V6C::A).addReg(V6C::BC);
          emitMOVrr(Tmp, V6C::A);
          BuildMI(MBB, MI, DL, get(V6C::INX), V6C::BC).addReg(V6C::BC);
          BuildMI(MBB, MI, DL, get(V6C::LDAX), V6C::A).addReg(V6C::BC);
          emitMOVrr(V6C::B, V6C::A);
          emitMOVrr(V6C::C, Tmp);
        } else {
          BuildMI(MBB, MI, DL, get(V6C::PUSH))
              .addReg(V6C::HL, RegState::Kill)
              .addReg(V6C::SP, RegState::ImplicitDefine);
          emitMOVrr(V6C::H, V6C::B);
          emitMOVrr(V6C::L, V6C::C);
          emitMOVrM(V6C::C);
          emitINXHL();
          emitMOVrM(V6C::B);
          BuildMI(MBB, MI, DL, get(V6C::POP), V6C::HL)
              .addReg(V6C::SP, RegState::ImplicitDefine);
        }
      }
    } else {
      // Case 5a: addr=BC, dst=DE. Four-way dispatch:
      //
      //   HL dead (any A) — current shape (5B / 40cc, BC preserved):
      //     MOV H,B; MOV L,C; MOV E,M; INX H; MOV D,M
      //
      //   HL live, A dead — LDAX shape (5B/40cc + 1B/8cc DCX if BC live):
      //     LDAX B; MOV E,A; INX B; LDAX B; MOV D,A; (DCX B if BC live)
      //
      //   HL live, A live, spare ∈ {H,L} dead — LDAX shape with cheap
      //   MOV-wrap A-preservation (7B / 56cc + DCX if BC live). Spare
      //   must be ≠ A, B, C, D, E so it can only come from {H, L}, and
      //   we already know one of H/L is live so the other half must be
      //   the candidate (case-4-style per-byte rule).
      //
      //   Otherwise (HL fully live, A live) — PUSH H wraps current shape
      //   (7B / 68cc, BC preserved).
      bool HLDead = isRegDeadAtMI(V6C::HL, MI, MBB, &RI);
      if (HLDead) {
        emitMOVrr(V6C::H, V6C::B);
        emitMOVrr(V6C::L, V6C::C);
        emitMOVrM(V6C::E);
        emitINXHL();
        emitMOVrM(V6C::D);
      } else {
        bool ADead = isRegDeadAtMI(V6C::A, MI, MBB, &RI);
        auto findCase5aSpare = [&]() -> Register {
          if (isRegDeadAtMI(V6C::H, MI, MBB, &RI)) return Register(V6C::H);
          if (isRegDeadAtMI(V6C::L, MI, MBB, &RI)) return Register(V6C::L);
          return Register();
        };
        Register Spare = ADead ? Register() : findCase5aSpare();
        if (ADead || Spare) {
          MCRegister Tmp;
          if (!ADead) {
            Tmp = Spare.asMCReg();
            emitMOVrr(Tmp, V6C::A);
          }
          BuildMI(MBB, MI, DL, get(V6C::LDAX), V6C::A).addReg(V6C::BC);
          emitMOVrr(V6C::E, V6C::A);
          BuildMI(MBB, MI, DL, get(V6C::INX), V6C::BC).addReg(V6C::BC);
          BuildMI(MBB, MI, DL, get(V6C::LDAX), V6C::A).addReg(V6C::BC);
          emitMOVrr(V6C::D, V6C::A);
          if (!ADead)
            emitMOVrr(V6C::A, Tmp);
          if (!isRegDeadAtMI(V6C::BC, MI, MBB, &RI))
            emitDCX(V6C::BC);
        } else {
          BuildMI(MBB, MI, DL, get(V6C::PUSH))
              .addReg(V6C::HL, RegState::Kill)
              .addReg(V6C::SP, RegState::ImplicitDefine);
          emitMOVrr(V6C::H, V6C::B);
          emitMOVrr(V6C::L, V6C::C);
          emitMOVrM(V6C::E);
          emitINXHL();
          emitMOVrM(V6C::D);
          BuildMI(MBB, MI, DL, get(V6C::POP), V6C::HL)
              .addReg(V6C::SP, RegState::ImplicitDefine);
        }
      }
    }

    MI.eraseFromParent();
    return true;
  }

  case V6C::V6C_STORE16_P: {
    // O72 — Honest per-shape preservation, mirroring O71's LOAD16_P
    // redesign. The pseudo declares (ins GR16:$val, GR16:$addr) with no
    // Defs. Pre-RA passes treat the store as preserving every register
    // except memory. The expander dispatches on the (addr, val) physreg
    // pair and emits whatever cheap recovery code each shape needs.
    Register ValReg  = MI.getOperand(0).getReg();
    Register AddrReg = MI.getOperand(1).getReg();

    MCRegister ValLo = RI.getSubReg(ValReg, V6C::sub_lo);
    MCRegister ValHi = RI.getSubReg(ValReg, V6C::sub_hi);

    auto emitDCX = [&](MCRegister Pair) {
      BuildMI(MBB, MI, DL, get(V6C::DCX), Pair).addReg(Pair);
    };
    auto emitINXHL = [&]() {
      BuildMI(MBB, MI, DL, get(V6C::INX), V6C::HL).addReg(V6C::HL);
    };
    auto emitINX = [&](MCRegister Pair) {
      BuildMI(MBB, MI, DL, get(V6C::INX), Pair).addReg(Pair);
    };
    auto emitMOVMr = [&](MCRegister Src) {
      BuildMI(MBB, MI, DL, get(V6C::MOVMr)).addReg(Src);
    };
    auto emitMOVrr = [&](MCRegister Dst, MCRegister Src) {
      BuildMI(MBB, MI, DL, get(V6C::MOVrr), Dst).addReg(Src);
    };
    auto emitXCHG = [&]() {
      BuildMI(MBB, MI, DL, get(V6C::XCHG));
    };
    auto emitSTAX = [&](MCRegister Pair) {
      BuildMI(MBB, MI, DL, get(V6C::STAX)).addReg(V6C::A).addReg(Pair);
    };

    if (AddrReg == V6C::HL && ValReg == V6C::HL) {
      // Row 1: addr=HL, val=HL.
      //   MOV Spare, H; MOV M, L; INX H; MOV M, Spare; (DCX H if HL live)
      // INX H may carry from L into H, so the high byte must be parked
      // in a GR8 *before* INX. Spare candidate avoids HL (its halves are
      // the value and the address).
      Register Spare = findDeadGR8AtMI(MI, MBB, &RI, V6C::HL);
      bool UseA = !Spare;
      MCRegister Tmp = UseA ? MCRegister(V6C::A) : Spare.asMCReg();
      bool ALive = UseA && !isRegDeadAtMI(V6C::A, MI, MBB, &RI);
      if (ALive)
        BuildMI(MBB, MI, DL, get(V6C::PUSH)).addReg(V6C::PSW);
      emitMOVrr(Tmp, V6C::H);
      emitMOVMr(V6C::L);
      emitINXHL();
      emitMOVMr(Tmp);
      if (ALive)
        BuildMI(MBB, MI, DL, get(V6C::POP), V6C::PSW);
      if (!isRegDeadAtMI(V6C::HL, MI, MBB, &RI))
        emitDCX(V6C::HL);
    } else if (AddrReg == V6C::HL) {
      // Row 2: addr=HL, val ∈ {BC, DE}.
      //   MOV M, ValLo; INX H; MOV M, ValHi; (DCX H if HL live)
      emitMOVMr(ValLo);
      emitINXHL();
      emitMOVMr(ValHi);
      if (!isRegDeadAtMI(V6C::HL, MI, MBB, &RI))
        emitDCX(V6C::HL);
    } else if (AddrReg == V6C::DE && ValReg == V6C::DE) {
      // Row 4: addr=DE, val=DE.
      //   XCHG; MOV Spare, H; MOV M, L; INX H; MOV M, Spare; XCHG;
      //   (DCX D if DE live)
      // After leading XCHG: HL = orig DE = address (= value), DE = orig HL.
      // The body stores the two halves of the address-which-is-the-value
      // through HL. The trailing XCHG restores HL from DE; whatever sits
      // in D / E at that moment ends up in H / L. So Spare candidates:
      //   B  iff B dead;  C iff C dead;
      //   D  iff H dead   (using D would otherwise destroy H_orig);
      //   E  iff L dead   (using E would otherwise destroy L_orig);
      //   A  iff A dead   (with PUSH PSW fallback);
      //   H, L — never (they hold the address mid-sequence).
      auto findRow4Spare = [&]() -> Register {
        if (isRegDeadAtMI(V6C::B, MI, MBB, &RI)) return Register(V6C::B);
        if (isRegDeadAtMI(V6C::C, MI, MBB, &RI)) return Register(V6C::C);
        if (isRegDeadAtMI(V6C::H, MI, MBB, &RI)) return Register(V6C::D);
        if (isRegDeadAtMI(V6C::L, MI, MBB, &RI)) return Register(V6C::E);
        return Register();
      };
      Register Spare = findRow4Spare();
      bool UseA = !Spare;
      MCRegister Tmp = UseA ? MCRegister(V6C::A) : Spare.asMCReg();
      bool ALive = UseA && !isRegDeadAtMI(V6C::A, MI, MBB, &RI);
      if (ALive)
        BuildMI(MBB, MI, DL, get(V6C::PUSH)).addReg(V6C::PSW);
      emitXCHG();
      emitMOVrr(Tmp, V6C::H);
      emitMOVMr(V6C::L);
      emitINXHL();
      emitMOVMr(Tmp);
      emitXCHG();
      if (ALive)
        BuildMI(MBB, MI, DL, get(V6C::POP), V6C::PSW);
      if (!isRegDeadAtMI(V6C::DE, MI, MBB, &RI))
        emitDCX(V6C::DE);
    } else if (AddrReg == V6C::DE) {
      // Rows 3a/3b: addr=DE, val ∈ {HL, BC}.
      //   XCHG; MOV M, lo; INX H; MOV M, hi; XCHG; (DCX D if DE live)
      // For val=HL: after leading XCHG, HL = address, DE = orig HL.
      //   Body stores mem[address] = E (= L_orig = lo of val),
      //   mem[address+1] = D (= H_orig = hi of val). Trailing XCHG
      //   restores HL = orig HL, leaves DE = address+1.
      // For val=BC: BC is unaffected by XCHG. lo = C, hi = B.
      MCRegister StoreLo, StoreHi;
      if (ValReg == V6C::HL) {
        StoreLo = V6C::E;
        StoreHi = V6C::D;
      } else {
        StoreLo = ValLo;
        StoreHi = ValHi;
      }
      emitXCHG();
      emitMOVMr(StoreLo);
      emitINXHL();
      emitMOVMr(StoreHi);
      emitXCHG();
      if (!isRegDeadAtMI(V6C::DE, MI, MBB, &RI))
        emitDCX(V6C::DE);
    } else if (ValReg != V6C::BC) {
      // Row 5: addr=BC, val ∈ {HL, DE}.
      //   [MOV Spare, A | PUSH PSW]    if A live
      //   MOV A, lo; STAX B; INX B; MOV A, hi; STAX B
      //   [MOV A, Spare | POP PSW]
      //   (DCX B if BC live)
      // STAX rp only accepts A as source. The Spare exclusion set is
      // {A, BC, ValReg}: the body reads both halves of the value via
      // MOV A, lo / MOV A, hi, and writes/reads BC via STAX/INX, so the
      // save target must survive the body unchanged.
      bool ALive = !isRegDeadAtMI(V6C::A, MI, MBB, &RI);
      Register Spare;
      if (ALive)
        Spare = findDeadGR8AtMI(MI, MBB, &RI, V6C::BC, ValReg);
      bool UsePush = ALive && !Spare;
      if (Spare)
        emitMOVrr(Spare.asMCReg(), V6C::A);
      else if (UsePush)
        BuildMI(MBB, MI, DL, get(V6C::PUSH)).addReg(V6C::PSW);
      emitMOVrr(V6C::A, ValLo);
      emitSTAX(V6C::BC);
      emitINX(V6C::BC);
      emitMOVrr(V6C::A, ValHi);
      emitSTAX(V6C::BC);
      if (Spare)
        emitMOVrr(V6C::A, Spare.asMCReg());
      else if (UsePush)
        BuildMI(MBB, MI, DL, get(V6C::POP), V6C::PSW);
      if (!isRegDeadAtMI(V6C::BC, MI, MBB, &RI))
        emitDCX(V6C::BC);
    } else {
      // Row 6: addr=BC, val=BC. Three-tier dispatch on HL liveness and
      // GR8 spare availability:
      //   6a — HL dead: use HL as scratch, no restore.
      //   6b — HL live, GR8 spare available: STAX-body with A saved into
      //        the spare (HL untouched).
      //   6c — HL live, no GR8 spare: PUSH H / scratch body / POP H.
      bool HLDead = isRegDeadAtMI(V6C::HL, MI, MBB, &RI);
      bool BCLive = !isRegDeadAtMI(V6C::BC, MI, MBB, &RI);

      if (HLDead) {
        // 6a — 5B / 40cc.
        emitMOVrr(V6C::H, V6C::B);
        emitMOVrr(V6C::L, V6C::C);
        emitMOVMr(V6C::C);
        emitINXHL();
        emitMOVMr(V6C::B);
        if (BCLive)
          emitDCX(V6C::BC);
      } else {
        // HL live.  Body reads both halves of BC, so Spare must exclude
        // BC. A is excluded automatically by findDeadGR8AtMI.
        Register Spare = findDeadGR8AtMI(MI, MBB, &RI, V6C::BC);
        if (Spare) {
          // 6b — STAX body, save A into Spare. HL untouched.
          bool ALive = !isRegDeadAtMI(V6C::A, MI, MBB, &RI);
          if (ALive)
            emitMOVrr(Spare.asMCReg(), V6C::A);
          emitMOVrr(V6C::A, V6C::C);
          emitSTAX(V6C::BC);
          emitINX(V6C::BC);
          emitMOVrr(V6C::A, V6C::B);
          emitSTAX(V6C::BC);
          if (ALive)
            emitMOVrr(V6C::A, Spare.asMCReg());
          if (BCLive)
            emitDCX(V6C::BC);
        } else {
          // 6c — PUSH H / scratch body / POP H.
          BuildMI(MBB, MI, DL, get(V6C::PUSH))
              .addReg(V6C::HL, RegState::Kill)
              .addReg(V6C::SP, RegState::ImplicitDefine);
          emitMOVrr(V6C::H, V6C::B);
          emitMOVrr(V6C::L, V6C::C);
          emitMOVMr(V6C::C);
          emitINXHL();
          emitMOVMr(V6C::B);
          BuildMI(MBB, MI, DL, get(V6C::POP), V6C::HL)
              .addReg(V6C::SP, RegState::ImplicitDefine);
          if (BCLive)
            emitDCX(V6C::BC);
        }
      }
    }

    MI.eraseFromParent();
    return true;
  }

  case V6C::V6C_LOAD16_G: {
    // Load 16-bit from global address. O73: per-shape, liveness-aware.
    //   dst=HL: LHLD addr                                   (3B / 20cc)
    //   dst=DE: XCHG; LHLD addr; XCHG                       (5B / 28cc)
    //   dst=BC, HL dead:    LHLD; MOV B,H; MOV C,L          (5B / 36cc)
    //   dst=BC, A dead:     LDA; MOV C,A; LDA+1; MOV B,A    (8B / 48cc)
    //   dst=BC, fallback:   PUSH H; LHLD; MOVs; POP H       (7B / 64cc)
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
      // dst=DE, HL dead: LHLD addr; XCHG (4B / 24cc).
      //   HL is scratch — LHLD overwrites it, XCHG moves loaded value
      //   into DE; HL ends up holding old DE which is dead anyway.
      // dst=DE, HL live: XCHG; LHLD addr; XCHG (5B / 28cc).
      //   First XCHG saves HL into DE (the value brought into HL by
      //   the first XCHG is dead, since the second XCHG overwrites HL
      //   with the loaded value). If DE wasn't live before, annotate
      //   the first XCHG's DE read as undef.
      if (isRegDeadAtMI(V6C::HL, MI, MBB, &RI)) {
        emitLHLD(MI);
        BuildMI(MBB, MI, DL, get(V6C::XCHG));
      } else {
        MachineInstr *FirstXchg =
            BuildMI(MBB, MI, DL, get(V6C::XCHG)).getInstr();
        emitLHLD(MI);
        BuildMI(MBB, MI, DL, get(V6C::XCHG));
        if (!isRegLiveBefore(MBB, FirstXchg->getIterator(), V6C::DE, &RI))
          markXchgUseUndef(FirstXchg, V6C::DE);
      }
    } else {
      // BC: three-way dispatch on (HLDead, ADead). See O73 design.
      MCRegister DstLo = RI.getSubReg(DstReg, V6C::sub_lo);
      MCRegister DstHi = RI.getSubReg(DstReg, V6C::sub_hi);

      bool HLDead = isRegDeadAtMI(V6C::HL, MI, MBB, &RI);
      bool ADead  = isRegDeadAtMI(V6C::A, MI, MBB, &RI);

      if (HLDead) {
        // 5B / 36cc: LHLD addr; MOV B,H; MOV C,L (HL is scratch).
        emitLHLD(MI);
        BuildMI(MBB, MI, DL, get(V6C::MOVrr), DstHi).addReg(V6C::H);
        BuildMI(MBB, MI, DL, get(V6C::MOVrr), DstLo).addReg(V6C::L);
      } else if (ADead) {
        // 8B / 48cc: LDA addr; MOV C,A; LDA addr+1; MOV B,A.
        // Preserves HL — strictly cheaper than PUSH/POP wrap (−16cc, +1B).
        auto emitLDA = [&](int64_t Bias) {
          auto MIB = BuildMI(MBB, MI, DL, get(V6C::LDA), V6C::A);
          if (AddrOp.isGlobal())
            MIB.addGlobalAddress(AddrOp.getGlobal(),
                                 AddrOp.getOffset() + Bias);
          else
            MIB.addImm(AddrOp.getImm() + Bias);
        };
        emitLDA(0);
        BuildMI(MBB, MI, DL, get(V6C::MOVrr), DstLo).addReg(V6C::A);
        emitLDA(1);
        BuildMI(MBB, MI, DL, get(V6C::MOVrr), DstHi).addReg(V6C::A);
      } else {
        // 7B / 64cc fallback: PUSH H; LHLD; MOV B,H; MOV C,L; POP H.
        BuildMI(MBB, MI, DL, get(V6C::PUSH))
            .addReg(V6C::HL, RegState::Kill)
            .addReg(V6C::SP, RegState::ImplicitDefine);
        emitLHLD(MI);
        BuildMI(MBB, MI, DL, get(V6C::MOVrr), DstHi).addReg(V6C::H);
        BuildMI(MBB, MI, DL, get(V6C::MOVrr), DstLo).addReg(V6C::L);
        BuildMI(MBB, MI, DL, get(V6C::POP), V6C::HL)
            .addReg(V6C::SP, RegState::ImplicitDefine);
      }
    }

    MI.eraseFromParent();
    return true;
  }

  case V6C::V6C_STORE16_G: {
    // Store 16-bit to global address. O74: per-shape, liveness-aware.
    //   val=HL:                 SHLD addr                            (3B / 20cc)
    //   val=DE, HL dead:        XCHG; SHLD addr                      (4B / 24cc)
    //   val=DE, fallback:       XCHG; SHLD addr; XCHG                (5B / 28cc)
    //   val=BC, HL dead:        MOV H,B; MOV L,C; SHLD addr          (5B / 36cc)
    //   val=BC, A dead:         MOV A,C; STA; MOV A,B; STA+1         (8B / 48cc)
    //   val=BC, fallback:       PUSH H; MOV H,B; MOV L,C; SHLD; POP H (7B / 64cc)
    Register ValReg = MI.getOperand(0).getReg();
    MachineOperand &AddrOp = MI.getOperand(1);

    auto emitSHLD = [&]() {
      auto MIB = BuildMI(MBB, MI, DL, get(V6C::SHLD)).addReg(V6C::HL);
      if (AddrOp.isGlobal())
        MIB.addGlobalAddress(AddrOp.getGlobal(), AddrOp.getOffset());
      else
        MIB.addImm(AddrOp.getImm());
    };

    if (ValReg == V6C::HL) {
      emitSHLD();
    } else if (ValReg == V6C::DE) {
      bool HLDead = isRegDeadAtMI(V6C::HL, MI, MBB, &RI);
      BuildMI(MBB, MI, DL, get(V6C::XCHG));
      emitSHLD();
      if (!HLDead)
        BuildMI(MBB, MI, DL, get(V6C::XCHG));
    } else {
      // val=BC: three-way dispatch on (HLDead, ADead).
      bool HLDead = isRegDeadAtMI(V6C::HL, MI, MBB, &RI);
      bool ADead  = isRegDeadAtMI(V6C::A,  MI, MBB, &RI);

      if (HLDead) {
        // 5B / 36cc: MOV H,B; MOV L,C; SHLD addr.
        BuildMI(MBB, MI, DL, get(V6C::MOVrr), V6C::H).addReg(V6C::B);
        BuildMI(MBB, MI, DL, get(V6C::MOVrr), V6C::L).addReg(V6C::C);
        emitSHLD();
      } else if (ADead) {
        // 8B / 48cc: MOV A,C; STA addr; MOV A,B; STA addr+1.
        // Preserves HL — strictly cheaper than PUSH/POP wrap (−16cc, +1B).
        auto emitSTA = [&](int64_t Bias) {
          auto MIB = BuildMI(MBB, MI, DL, get(V6C::STA)).addReg(V6C::A);
          if (AddrOp.isGlobal())
            MIB.addGlobalAddress(AddrOp.getGlobal(),
                                 AddrOp.getOffset() + Bias);
          else
            MIB.addImm(AddrOp.getImm() + Bias);
        };
        BuildMI(MBB, MI, DL, get(V6C::MOVrr), V6C::A).addReg(V6C::C);
        emitSTA(0);
        BuildMI(MBB, MI, DL, get(V6C::MOVrr), V6C::A).addReg(V6C::B);
        emitSTA(1);
      } else {
        // 7B / 64cc fallback: PUSH H; MOV H,B; MOV L,C; SHLD; POP H.
        BuildMI(MBB, MI, DL, get(V6C::PUSH))
            .addReg(V6C::HL, RegState::Kill)
            .addReg(V6C::SP, RegState::ImplicitDefine);
        BuildMI(MBB, MI, DL, get(V6C::MOVrr), V6C::H).addReg(V6C::B);
        BuildMI(MBB, MI, DL, get(V6C::MOVrr), V6C::L).addReg(V6C::C);
        emitSHLD();
        BuildMI(MBB, MI, DL, get(V6C::POP), V6C::HL)
            .addReg(V6C::SP, RegState::ImplicitDefine);
      }
    }

    MI.eraseFromParent();
    return true;
  }

  case V6C::V6C_SHL16: {
    // Left shift i16 by constant amount.
    // For 1-7: unrolled ADD self (lo+carry→hi).
    // For 8+ (O62): byte-lane move SrcLo → DstHi; zero DstLo; then
    //   shift DstHi left by (ShAmt - 8) in i8 domain. The leading
    //   2-MOV "copy Src to Dst" prologue is skipped because both
    //   halves of the source-as-dst are immediately overwritten.
    Register DstReg = MI.getOperand(0).getReg();
    Register SrcReg = MI.getOperand(1).getReg();
    unsigned ShAmt = MI.getOperand(2).getImm();

    MCRegister DstHi = RI.getSubReg(DstReg, V6C::sub_hi);
    MCRegister DstLo = RI.getSubReg(DstReg, V6C::sub_lo);
    MCRegister SrcHi = RI.getSubReg(SrcReg, V6C::sub_hi);
    MCRegister SrcLo = RI.getSubReg(SrcReg, V6C::sub_lo);

    if (ShAmt >= 8) {
      // O62: skip leading copy, emit byte-lane move directly from SrcLo.
      // GR16 pairs are disjoint (BC, DE, HL), so DstHi != SrcLo always
      // holds for distinct pairs. For DstReg == SrcReg the MOV becomes
      // MOV DstHi, DstLo (still distinct halves), matching today's
      // in-place expansion.
      if (DstHi != SrcLo)
        BuildMI(MBB, MI, DL, get(V6C::MOVrr), DstHi).addReg(SrcLo);
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
      // SHL by 1-7: unrolled 16-bit ADD self. Needs both halves of Src
      // as live-in, so the generic copy prologue is required.
      if (DstReg != SrcReg) {
        BuildMI(MBB, MI, DL, get(V6C::MOVrr), DstHi).addReg(SrcHi);
        BuildMI(MBB, MI, DL, get(V6C::MOVrr), DstLo).addReg(SrcLo);
      }
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
    // For 8+ (O62): byte-lane move SrcHi → DstLo; zero DstHi; then
    //   shift DstLo right by (ShAmt - 8) in i8 domain. The leading
    //   2-MOV "copy Src to Dst" prologue is skipped, and the per-bit
    //   loop is half-width because DstHi is provably zero.
    Register DstReg = MI.getOperand(0).getReg();
    Register SrcReg = MI.getOperand(1).getReg();
    unsigned ShAmt = MI.getOperand(2).getImm();

    MCRegister DstHi = RI.getSubReg(DstReg, V6C::sub_hi);
    MCRegister DstLo = RI.getSubReg(DstReg, V6C::sub_lo);
    MCRegister SrcHi = RI.getSubReg(SrcReg, V6C::sub_hi);
    MCRegister SrcLo = RI.getSubReg(SrcReg, V6C::sub_lo);

    if (ShAmt >= 8) {
      // O62 byte-aligned fast path.
      if (DstLo != SrcHi)
        BuildMI(MBB, MI, DL, get(V6C::MOVrr), DstLo).addReg(SrcHi);
      BuildMI(MBB, MI, DL, get(V6C::MVIr), DstHi).addImm(0);
      ShAmt -= 8;
      // Half-width per-bit logical right shift on DstLo only.
      bool CYClear = priorClearsCarry(MBB, MI);
      for (unsigned i = 0; i < ShAmt; ++i) {
        BuildMI(MBB, MI, DL, get(V6C::MOVrr), V6C::A).addReg(DstLo);
        if (!CYClear)
          BuildMI(MBB, MI, DL, get(V6C::ORAr), V6C::A)
              .addReg(V6C::A).addReg(V6C::A); // CY = 0
        BuildMI(MBB, MI, DL, get(V6C::RAR), V6C::A).addReg(V6C::A);
        BuildMI(MBB, MI, DL, get(V6C::MOVrr), DstLo).addReg(V6C::A);
        // After RAR, CY holds the previous LSB — unknown for next iter.
        CYClear = false;
      }
    } else {
      // SRL by 1-7: full 2-byte per-bit RAR loop. Needs both halves
      // as live-in.
      if (DstReg != SrcReg) {
        BuildMI(MBB, MI, DL, get(V6C::MOVrr), DstHi).addReg(SrcHi);
        BuildMI(MBB, MI, DL, get(V6C::MOVrr), DstLo).addReg(SrcLo);
      }
      bool CYClear = priorClearsCarry(MBB, MI);
      for (unsigned i = 0; i < ShAmt; ++i) {
        // Load hi to A, ORA A to clear carry, RAR, store back.
        BuildMI(MBB, MI, DL, get(V6C::MOVrr), V6C::A).addReg(DstHi);
        if (!CYClear)
          BuildMI(MBB, MI, DL, get(V6C::ORAr), V6C::A)
              .addReg(V6C::A).addReg(V6C::A); // CY = 0, A unchanged
        BuildMI(MBB, MI, DL, get(V6C::RAR), V6C::A).addReg(V6C::A);
        BuildMI(MBB, MI, DL, get(V6C::MOVrr), DstHi).addReg(V6C::A);
        // Load lo to A, RAR (carry = hi bit 0), store back.
        BuildMI(MBB, MI, DL, get(V6C::MOVrr), V6C::A).addReg(DstLo);
        BuildMI(MBB, MI, DL, get(V6C::RAR), V6C::A).addReg(V6C::A);
        BuildMI(MBB, MI, DL, get(V6C::MOVrr), DstLo).addReg(V6C::A);
        // After lo RAR, CY = old DstLo bit 0 — unknown for next iter.
        CYClear = false;
      }
    }

    MI.eraseFromParent();
    return true;
  }

  case V6C::V6C_SRA16: {
    // Arithmetic right shift i16 by constant amount.
    // For 1-7: set CY=sign bit via RLC, then RAR hi, RAR lo.
    // For 8+ (O62): byte-lane move SrcHi → DstLo; sign-extend SrcHi
    //   into DstHi via RLC+SBB; then per-bit 8-bit arithmetic right
    //   shift on DstLo only (DstHi is already the sign byte).
    Register DstReg = MI.getOperand(0).getReg();
    Register SrcReg = MI.getOperand(1).getReg();
    unsigned ShAmt = MI.getOperand(2).getImm();

    MCRegister DstHi = RI.getSubReg(DstReg, V6C::sub_hi);
    MCRegister DstLo = RI.getSubReg(DstReg, V6C::sub_lo);
    MCRegister SrcHi = RI.getSubReg(SrcReg, V6C::sub_hi);
    MCRegister SrcLo = RI.getSubReg(SrcReg, V6C::sub_lo);

    if (ShAmt >= 8) {
      // O62 byte-aligned fast path. Read SrcHi into A first so that the
      // subsequent byte-lane MOV to DstLo cannot clobber the source
      // (safe even if DstLo aliases SrcHi; harmless when they don't).
      BuildMI(MBB, MI, DL, get(V6C::MOVrr), V6C::A).addReg(SrcHi);
      if (DstLo != SrcHi)
        BuildMI(MBB, MI, DL, get(V6C::MOVrr), DstLo).addReg(SrcHi);
      BuildMI(MBB, MI, DL, get(V6C::RLC), V6C::A).addReg(V6C::A);
      BuildMI(MBB, MI, DL, get(V6C::SBBr), V6C::A)
          .addReg(V6C::A).addReg(V6C::A);
      BuildMI(MBB, MI, DL, get(V6C::MOVrr), DstHi).addReg(V6C::A);
      ShAmt -= 8;
      // Half-width per-bit arithmetic right shift on DstLo only.
      // DstHi (sign byte) is already correct and stays correct under
      // any further ASHR. The original sign bit is preserved as bit 7
      // of DstLo and rematerialised each iteration via RLC.
      for (unsigned i = 0; i < ShAmt; ++i) {
        BuildMI(MBB, MI, DL, get(V6C::MOVrr), V6C::A).addReg(DstLo);
        BuildMI(MBB, MI, DL, get(V6C::RLC), V6C::A)
            .addReg(V6C::A); // CY = bit 7 = sign, A = junk
        BuildMI(MBB, MI, DL, get(V6C::MOVrr), V6C::A).addReg(DstLo);
        BuildMI(MBB, MI, DL, get(V6C::RAR), V6C::A)
            .addReg(V6C::A); // A = sign:lo[7:1]
        BuildMI(MBB, MI, DL, get(V6C::MOVrr), DstLo).addReg(V6C::A);
      }
    } else {
      // SRA by 1-7: full 2-byte per-bit RAR loop.
      if (DstReg != SrcReg) {
        BuildMI(MBB, MI, DL, get(V6C::MOVrr), DstHi).addReg(SrcHi);
        BuildMI(MBB, MI, DL, get(V6C::MOVrr), DstLo).addReg(SrcLo);
      }
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
    }

    MI.eraseFromParent();
    return true;
  }

  case V6C::V6C_ROTL16_1: {
    // O68 Phase 2: rotl i16 x, 1
    //   DAD H        ; HL <<= 1, CY = old bit 15      (10cc, 1B)
    //   MVI A, 0     ; (does not touch flags — CY preserved) ( 7cc, 2B)
    //   ADC L        ; A = 0 + L + CY = L | CY        ( 4cc, 1B)
    //   MOV L, A     ;                                ( 5cc, 1B)
    // GR16Ptr / tied $dst=$src guarantees Dst == Src == HL post-RA,
    // so no framing is needed. Total: 4 instr / 5B / 26cc, A clobbered
    // (matches today's expand semantics). MVI A,0 chosen over MOV A,L
    // + ACI 0 to break the L→A→A dep chain and save 1cc.
    BuildMI(MBB, MI, DL, get(V6C::DAD)).addReg(V6C::HL);
    BuildMI(MBB, MI, DL, get(V6C::MVIr), V6C::A).addImm(0);
    BuildMI(MBB, MI, DL, get(V6C::ADCr), V6C::A).addReg(V6C::A).addReg(V6C::L);
    BuildMI(MBB, MI, DL, get(V6C::MOVrr), V6C::L).addReg(V6C::A);
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
      // Priority 4: AddrReg ∈ {BC, DE}, DstReg != A. O76 — three-way
      // dispatch on (AddrReg, A-liveness, dead-GR8 availability):
      //   7  : addr=DE, A live           → XCHG bypass        (3B/16cc)
      //   6a : addr=BC, A live, SpareR   → SpareR-A envelope  (4B/32cc)
      //   6b : addr=BC, A live, no spare → PSW-wrap fallback  (4B/44cc)
      //   4/5: A dead                    → LDAX + MOV         (2B/16cc)
      bool ALive = !isRegDeadAtMI(V6C::A, MI, MBB, &RI);

      // partner(dst) = XCHG image of dst. After `XCHG; MOV r,M; XCHG`
      // the byte loaded into `partnerOf(dst)` ends up in `dst`. Correct
      // for every non-A dst:
      //   - dst ∈ {B, C, H, L}: bypass preserves DE.
      //   - dst ∈ {D, E}      : bypass clobbers DE, but RA's
      //     subreg-def-kills-superreg-use invariant guarantees DE is
      //     dead-after the pseudo whenever it allocates dst ∈ {D, E}
      //     for addr=DE. See plan_O76_V6C_LOAD8_P_redesign.md.
      auto partnerOf = [](Register R) -> Register {
        switch (R) {
        case V6C::B: return V6C::B;
        case V6C::C: return V6C::C;
        case V6C::H: return V6C::D;
        case V6C::L: return V6C::E;
        case V6C::D: return V6C::H;
        case V6C::E: return V6C::L;
        default:     return Register();
        }
      };

      if (ALive && AddrReg == V6C::DE) {
        // 7: XCHG bypass. 3B / 16cc, unconditional for any non-A dst.
        BuildMI(MBB, MI, DL, get(V6C::XCHG));
        BuildMI(MBB, MI, DL, get(V6C::MOVrM))
            .addReg(partnerOf(DstReg), RegState::Define);
        BuildMI(MBB, MI, DL, get(V6C::XCHG));
      } else if (ALive) {
        // 6a / 6b: addr=BC, A live. Try SpareR-A first (saves 12cc vs
        // PSW-wrap, same byte count). Exclude A and DstReg — SpareR
        // must survive the post-LDAX `MOV dst,A`.
        Register SpareR = findDeadGR8AtMI(MI, MBB, &RI,
                                          /*Exclude1=*/V6C::A,
                                          /*Exclude2=*/DstReg);
        if (SpareR) {
          // 6a: MOV spareR,A; LDAX; MOV dst,A; MOV A,spareR.
          BuildMI(MBB, MI, DL, get(V6C::MOVrr), SpareR).addReg(V6C::A);
          BuildMI(MBB, MI, DL, get(V6C::LDAX))
              .addReg(V6C::A, RegState::Define).addReg(AddrReg);
          BuildMI(MBB, MI, DL, get(V6C::MOVrr))
              .addReg(DstReg, RegState::Define).addReg(V6C::A);
          BuildMI(MBB, MI, DL, get(V6C::MOVrr), V6C::A).addReg(SpareR);
        } else {
          // 6b: PUSH PSW; LDAX; MOV dst,A; POP PSW (legacy fallback).
          BuildMI(MBB, MI, DL, get(V6C::PUSH)).addReg(V6C::PSW);
          BuildMI(MBB, MI, DL, get(V6C::LDAX))
              .addReg(V6C::A, RegState::Define).addReg(AddrReg);
          BuildMI(MBB, MI, DL, get(V6C::MOVrr))
              .addReg(DstReg, RegState::Define).addReg(V6C::A);
          BuildMI(MBB, MI, DL, get(V6C::POP), V6C::PSW);
        }
      } else {
        // 4 / 5: A dead — plain LDAX + MOV.
        BuildMI(MBB, MI, DL, get(V6C::LDAX))
            .addReg(V6C::A, RegState::Define).addReg(AddrReg);
        BuildMI(MBB, MI, DL, get(V6C::MOVrr))
            .addReg(DstReg, RegState::Define).addReg(V6C::A);
      }
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
      // Priority 4: AddrReg ∈ {BC, DE}, SrcReg != A. O77 — three-way
      // dispatch on (AddrReg, A-liveness, dead-GR8 availability):
      //   7  : addr=DE, A live           → XCHG bypass        (3B/16cc)
      //   6a : addr=BC, A live, SpareR   → SpareR-A envelope  (4B/32cc)
      //   6b : addr=BC, A live, no spare → PSW-wrap fallback  (4B/44cc)
      //   4/5: A dead                    → MOV A,src + STAX   (2B/16cc)
      bool ALive = !isRegDeadAtMI(V6C::A, MI, MBB, &RI);

      // partner(src) = XCHG image of src. After `XCHG; MOV M,r; XCHG`
      // the byte stored is the value originally in `src` for every
      // non-A src — the body MOV M,r only reads a register and writes
      // memory, so the trailing XCHG fully restores DE. Unlike the
      // load (O76), there is no `src ∈ {D, E}` edge case.
      auto partnerOf = [](Register R) -> Register {
        switch (R) {
        case V6C::B: return V6C::B;
        case V6C::C: return V6C::C;
        case V6C::H: return V6C::D;
        case V6C::L: return V6C::E;
        case V6C::D: return V6C::H;
        case V6C::E: return V6C::L;
        default:     return Register();
        }
      };

      if (ALive && AddrReg == V6C::DE) {
        // 7: XCHG bypass. 3B / 16cc, unconditional for any non-A src.
        BuildMI(MBB, MI, DL, get(V6C::XCHG));
        BuildMI(MBB, MI, DL, get(V6C::MOVMr))
            .addReg(partnerOf(SrcReg));
        BuildMI(MBB, MI, DL, get(V6C::XCHG));
      } else if (ALive) {
        // 6a / 6b: addr=BC, A live. Try SpareR-A first (saves 12cc vs
        // PSW-wrap, same byte count). Exclude AddrReg (BC) and SrcReg
        // — SpareR must not alias the address pair (STAX B reads BC)
        // nor the source (`MOV spareR,A` would clobber src before it
        // is read into A).
        Register SpareR =
            findDeadGR8AtMI(MI, MBB, &RI, AddrReg, SrcReg);
        if (SpareR) {
          // 6a: MOV spareR,A; MOV A,src; STAX B; MOV A,spareR.
          BuildMI(MBB, MI, DL, get(V6C::MOVrr), SpareR).addReg(V6C::A);
          BuildMI(MBB, MI, DL, get(V6C::MOVrr))
              .addReg(V6C::A, RegState::Define).addReg(SrcReg);
          BuildMI(MBB, MI, DL, get(V6C::STAX))
              .addReg(V6C::A).addReg(AddrReg);
          BuildMI(MBB, MI, DL, get(V6C::MOVrr), V6C::A).addReg(SpareR);
        } else {
          // 6b: PUSH PSW; MOV A,src; STAX B; POP PSW (legacy fallback).
          BuildMI(MBB, MI, DL, get(V6C::PUSH)).addReg(V6C::PSW);
          BuildMI(MBB, MI, DL, get(V6C::MOVrr))
              .addReg(V6C::A, RegState::Define).addReg(SrcReg);
          BuildMI(MBB, MI, DL, get(V6C::STAX))
              .addReg(V6C::A).addReg(AddrReg);
          BuildMI(MBB, MI, DL, get(V6C::POP), V6C::PSW);
        }
      } else {
        // 4 / 5: A dead — plain MOV A,src + STAX.
        BuildMI(MBB, MI, DL, get(V6C::MOVrr))
            .addReg(V6C::A, RegState::Define).addReg(SrcReg);
        BuildMI(MBB, MI, DL, get(V6C::STAX))
            .addReg(V6C::A).addReg(AddrReg);
      }
    }
    MI.eraseFromParent();
    return true;
  }

  //===------------------------------------------------------------------===//
  // O49 — Direct memory ALU / store / RMW pseudos.
  //===------------------------------------------------------------------===//

  case V6C::V6C_ADD_M_P:
  case V6C::V6C_ADC_M_P:
  case V6C::V6C_SUB_M_P:
  case V6C::V6C_SBB_M_P:
  case V6C::V6C_ANA_M_P:
  case V6C::V6C_ORA_M_P:
  case V6C::V6C_XRA_M_P: {
    // Operands: 0=$dst(Acc tied), 1=$lhs(Acc tied), 2=$addr(GR16).
    unsigned MOpc;
    switch (MI.getOpcode()) {
    case V6C::V6C_ADD_M_P: MOpc = V6C::ADDM; break;
    case V6C::V6C_ADC_M_P: MOpc = V6C::ADCM; break;
    case V6C::V6C_SUB_M_P: MOpc = V6C::SUBM; break;
    case V6C::V6C_SBB_M_P: MOpc = V6C::SBBM; break;
    case V6C::V6C_ANA_M_P: MOpc = V6C::ANAM; break;
    case V6C::V6C_ORA_M_P: MOpc = V6C::ORAM; break;
    case V6C::V6C_XRA_M_P: MOpc = V6C::XRAM; break;
    default: llvm_unreachable("unexpected ALU M opcode");
    }
    Register AddrReg = MI.getOperand(2).getReg();
    expandMemOpM(MBB, MI, *this, RI, AddrReg,
        [&](MachineBasicBlock &B, MachineBasicBlock::iterator Ip) {
          // Physical M ALU ops: (outs Acc:$dst)(ins Acc:$lhs), tied.
          BuildMI(B, Ip, DL, get(MOpc), V6C::A).addReg(V6C::A);
        });
    MI.eraseFromParent();
    return true;
  }

  case V6C::V6C_CMP_M_P: {
    // Operands: 0=$lhs(Acc), 1=$addr(GR16). No register output.
    Register AddrReg = MI.getOperand(1).getReg();
    expandMemOpM(MBB, MI, *this, RI, AddrReg,
        [&](MachineBasicBlock &B, MachineBasicBlock::iterator Ip) {
          // Physical CMPM: (outs)(ins Acc:$lhs).
          BuildMI(B, Ip, DL, get(V6C::CMPM)).addReg(V6C::A);
        });
    MI.eraseFromParent();
    return true;
  }

  case V6C::V6C_STORE8_IMM_P: {
    // Operands: 0=$imm(imm8), 1=$addr(GR16).
    // Per-shape dispatch (O78). See design/future_plans/O78_*.md.
    int64_t Imm = MI.getOperand(0).getImm();
    Register AddrReg = MI.getOperand(1).getReg();

    if (AddrReg == V6C::HL) {
      // Row 1: direct.  2B / 12cc.
      BuildMI(MBB, MI, DL, get(V6C::MVIM)).addImm(Imm);
    } else {
      bool ADead = isRegDeadAtMI(V6C::A, MI, MBB, &RI);
      if (ADead) {
        // Rows 2/3: A dead → MVI A, imm; STAX rp.  3B / 16cc.
        BuildMI(MBB, MI, DL, get(V6C::MVIr), V6C::A).addImm(Imm);
        BuildMI(MBB, MI, DL, get(V6C::STAX))
            .addReg(V6C::A).addReg(AddrReg);
      } else if (AddrReg == V6C::DE) {
        // Row 4: A live, addr=DE → XCHG bypass.  4B / 20cc.
        BuildMI(MBB, MI, DL, get(V6C::XCHG));
        BuildMI(MBB, MI, DL, get(V6C::MVIM)).addImm(Imm);
        BuildMI(MBB, MI, DL, get(V6C::XCHG));
      } else {
        // AddrReg == V6C::BC, A live.
        bool HLDead = isRegDeadAtMI(V6C::HL, MI, MBB, &RI);
        bool DEDead = isRegDeadAtMI(V6C::DE, MI, MBB, &RI);
        if (HLDead) {
          // Row 5: BC + HL dead.  4B / 28cc.
          BuildMI(MBB, MI, DL, get(V6C::MOVrr), V6C::L).addReg(V6C::C);
          BuildMI(MBB, MI, DL, get(V6C::MOVrr), V6C::H).addReg(V6C::B);
          BuildMI(MBB, MI, DL, get(V6C::MVIM)).addImm(Imm);
        } else if (DEDead) {
          // Row 6: BC + HL live + DE dead → DE-route.  5B / 36cc.
          BuildMI(MBB, MI, DL, get(V6C::MOVrr), V6C::D).addReg(V6C::B);
          BuildMI(MBB, MI, DL, get(V6C::MOVrr), V6C::E).addReg(V6C::C);
          BuildMI(MBB, MI, DL, get(V6C::XCHG));
          BuildMI(MBB, MI, DL, get(V6C::MVIM)).addImm(Imm);
          BuildMI(MBB, MI, DL, get(V6C::XCHG));
        } else {
          // Row 7: BC, all live → PUSH H envelope (legacy).  6B / 56cc.
          BuildMI(MBB, MI, DL, get(V6C::PUSH))
              .addReg(V6C::HL, RegState::Kill)
              .addReg(V6C::SP, RegState::ImplicitDefine);
          BuildMI(MBB, MI, DL, get(V6C::MOVrr), V6C::L).addReg(V6C::C);
          BuildMI(MBB, MI, DL, get(V6C::MOVrr), V6C::H).addReg(V6C::B);
          BuildMI(MBB, MI, DL, get(V6C::MVIM)).addImm(Imm);
          BuildMI(MBB, MI, DL, get(V6C::POP), V6C::HL)
              .addReg(V6C::SP, RegState::ImplicitDefine);
        }
      }
    }
    MI.eraseFromParent();
    return true;
  }

  case V6C::V6C_INR_M_P:
  case V6C::V6C_DCR_M_P: {
    // Operand: 0=$addr(GR16).
    unsigned MOpc = (MI.getOpcode() == V6C::V6C_INR_M_P) ? V6C::INRM
                                                        : V6C::DCRM;
    Register AddrReg = MI.getOperand(0).getReg();
    expandMemOpM(MBB, MI, *this, RI, AddrReg,
        [&](MachineBasicBlock &B, MachineBasicBlock::iterator Ip) {
          BuildMI(B, Ip, DL, get(MOpc));
        });
    MI.eraseFromParent();
    return true;
  }
  }
}
