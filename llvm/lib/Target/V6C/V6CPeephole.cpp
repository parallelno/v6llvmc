//===-- V6CPeephole.cpp - V6C Peephole Optimizations ---------------------===//
//
// Part of the V6C backend for LLVM.
//
// Post-RA peephole pass with pattern-based local optimizations:
//
// 1. Redundant MOV elimination: MOV A, X; MOV A, X → remove second.
//    Also MOV A, X; <no flags/A write>; MOV X, A → remove second MOV X, A
//    if X was not modified.
//
// 2. Redundant self-MOV elimination: MOV X, X → remove.
//
// 3. Strength reduction: SHL i8 by 1 expanded to ADD A, A (4cc vs shift
//    sequence). This pattern should already be handled by ISel, but catch
//    any post-RA instances.
//
//===----------------------------------------------------------------------===//

#include "V6C.h"
#include "MCTargetDesc/V6CMCTargetDesc.h"
#include "llvm/CodeGen/MachineFunctionPass.h"
#include "llvm/CodeGen/MachineInstrBuilder.h"
#include "llvm/CodeGen/MachineRegisterInfo.h"
#include "llvm/CodeGen/TargetInstrInfo.h"
#include "llvm/CodeGen/TargetSubtargetInfo.h"
#include "llvm/MC/MCRegisterInfo.h"
#include "llvm/Support/CommandLine.h"

using namespace llvm;

#define DEBUG_TYPE "v6c-peephole"

static cl::opt<bool> DisablePeephole(
    "v6c-disable-peephole",
    cl::desc("Disable V6C peephole optimizations"),
    cl::init(false), cl::Hidden);

static cl::opt<bool> DisableShldLhldFold(
    "v6c-disable-shld-lhld-fold",
    cl::desc("Disable SHLD/LHLD to PUSH/POP folding (O43)"),
    cl::init(false), cl::Hidden);

static cl::opt<bool> DisableMviAluFold(
    "v6c-disable-mvi-alu-fold",
    cl::desc("Disable MVI R,NN + ALU R -> ALU-immediate fold (O79)"),
    cl::init(false), cl::Hidden);

/// True if MI is an O61 patched-immediate site: it carries a
/// pre-instr `.LLo61_N:` label (referenced by SHLD/STA spills) and/or
/// its imm operand is flagged MO_PATCH_IMM.  Erasing such an MI loses
/// the label and orphans every spill that points at `Sym+1`, so
/// peepholes that rewrite or remove MI must skip these.
static bool isO61PatchedImm(const MachineInstr &MI) {
  if (MI.getPreInstrSymbol())
    return true;
  for (const MachineOperand &MO : MI.operands())
    if (MO.getTargetFlags() != 0)
      return true;
  return false;
}

namespace {

class V6CPeephole : public MachineFunctionPass {
public:
  static char ID;
  V6CPeephole() : MachineFunctionPass(ID) {}

  StringRef getPassName() const override {
    return "V6C Peephole Optimizations";
  }

  bool runOnMachineFunction(MachineFunction &MF) override;

private:
  bool eliminateSelfMov(MachineBasicBlock &MBB);
  bool eliminateRedundantMov(MachineBasicBlock &MBB);
  bool eliminateTailCall(MachineBasicBlock &MBB);
  bool foldCounterBranch(MachineBasicBlock &MBB);
  bool foldXraCmpZeroTest(MachineBasicBlock &MBB);
  bool cancelAdjacentXchg(MachineBasicBlock &MBB);
  bool foldXchgDad(MachineBasicBlock &MBB);
  bool foldShldLhldToPushPop(MachineBasicBlock &MBB);
  bool foldMovAluM(MachineBasicBlock &MBB);
  bool foldIncDecMviM(MachineBasicBlock &MBB);
  bool foldMviZeroToXraA(MachineBasicBlock &MBB);
  bool foldMviAluImm(MachineBasicBlock &MBB);
};

} // end anonymous namespace

char V6CPeephole::ID = 0;

/// Remove MOV X, X instructions (no-op copies to self).
bool V6CPeephole::eliminateSelfMov(MachineBasicBlock &MBB) {
  bool Changed = false;
  for (MachineInstr &MI : llvm::make_early_inc_range(MBB)) {
    if (MI.getOpcode() != V6C::MOVrr)
      continue;
    if (MI.getOperand(0).getReg() == MI.getOperand(1).getReg()) {
      MI.eraseFromParent();
      Changed = true;
    }
  }
  return Changed;
}

/// Remove redundant consecutive MOVs: if we see MOV X, Y followed by MOV X, Y
/// with no intervening write to X or Y, remove the second one.
bool V6CPeephole::eliminateRedundantMov(MachineBasicBlock &MBB) {
  bool Changed = false;
  for (auto I = MBB.begin(), E = MBB.end(); I != E; ) {
    MachineInstr &MI = *I;
    if (MI.getOpcode() != V6C::MOVrr) {
      ++I;
      continue;
    }

    Register Dst = MI.getOperand(0).getReg();
    Register Src = MI.getOperand(1).getReg();

    // Look at the next instruction.
    auto Next = std::next(I);
    if (Next == E) {
      ++I;
      continue;
    }

    MachineInstr &NextMI = *Next;
    if (NextMI.getOpcode() == V6C::MOVrr &&
        NextMI.getOperand(0).getReg() == Dst &&
        NextMI.getOperand(1).getReg() == Src) {
      // Duplicate MOV — remove the second one.
      NextMI.eraseFromParent();
      Changed = true;
      // Don't advance I; another dup might follow.
      continue;
    }

    // Check for MOV A, X; ...; MOV A, X (where nothing modifies A or X)
    // This is a more aggressive pattern — only look ahead a few instructions.
    ++I;
  }
  return Changed;
}

/// Return true if MBB contains only a single RET (plus optional debug instrs).
static bool isRetOnlyBlock(const MachineBasicBlock &MBB) {
  for (const MachineInstr &MI : MBB) {
    if (MI.isDebugInstr())
      continue;
    if (MI.getOpcode() == V6C::RET)
      return true; // RET found — any debug instrs after it are fine.
    return false;  // Non-debug, non-RET instruction → not RET-only.
  }
  return false; // Empty block.
}

/// Replace CALL target; RET → V6C_TAILJMP target (tail call elimination).
///
/// Pattern 1 (O14): CALL and RET in the same block.
/// Pattern 2 (O23): CALL is last instruction, sole successor is RET-only.
bool V6CPeephole::eliminateTailCall(MachineBasicBlock &MBB) {
  if (MBB.empty())
    return false;

  // Find the last non-debug instruction.
  auto LastIt = MBB.getLastNonDebugInstr();
  if (LastIt == MBB.end())
    return false;

  // --- Pattern 1: CALL; RET in the same block (O14) ---
  if (MBB.size() >= 2 && LastIt->getOpcode() == V6C::RET) {
    auto CallIt = std::prev(LastIt);
    while (CallIt != MBB.begin() && CallIt->isDebugInstr())
      CallIt = std::prev(CallIt);

    if (CallIt->getOpcode() == V6C::CALL) {
      const TargetInstrInfo &TII =
          *MBB.getParent()->getSubtarget().getInstrInfo();
      BuildMI(MBB, CallIt, CallIt->getDebugLoc(),
              TII.get(V6C::V6C_TAILJMP))
          .add(CallIt->getOperand(0));

      LastIt->eraseFromParent();
      CallIt->eraseFromParent();
      return true;
    }
  }

  // --- Pattern 2: CALL at end of block, sole successor is RET-only (O23) ---
  if (LastIt->getOpcode() == V6C::CALL && MBB.succ_size() == 1) {
    MachineBasicBlock *Succ = *MBB.succ_begin();
    if (isRetOnlyBlock(*Succ)) {
      const TargetInstrInfo &TII =
          *MBB.getParent()->getSubtarget().getInstrInfo();
      BuildMI(MBB, LastIt, LastIt->getDebugLoc(),
              TII.get(V6C::V6C_TAILJMP))
          .add(LastIt->getOperand(0));

      LastIt->eraseFromParent();
      MBB.removeSuccessor(Succ);
      return true;
    }
  }

  return false;
}

/// Check if a physical register is dead (not read) after iterator I.
/// Returns true if no instruction between I (exclusive) and the end of the
/// block reads Reg before an overlapping redef, and no successor has Reg as a
/// live-in.
///
/// Pair-register caveat: a def of one half kills the old pair value, but does
/// not prove the other half is safe to clobber. Whole-pair preservation checks
/// need explicit half-wise reasoning.
static bool isRegDeadAfter(MachineBasicBlock &MBB,
                           MachineBasicBlock::iterator I,
                           unsigned Reg,
                           const TargetRegisterInfo *TRI) {
  for (auto MI = std::next(I); MI != MBB.end(); ++MI) {
    bool usesReg = false, defsReg = false;
    for (const MachineOperand &MO : MI->operands()) {
      if (!MO.isReg() || !TRI->regsOverlap(MO.getReg(), Reg))
        continue;
      if (MO.isUse() && !MO.isUndef())
        usesReg = true;
      if (MO.isDef())
        defsReg = true;
    }
    if (usesReg)
      return false; // Read before redefined → live
    if (defsReg)
      return true;  // Redefined before read → dead
  }
  // Reached end of block: check if any successor needs Reg.
  for (MachineBasicBlock *Succ : MBB.successors()) {
    for (MCRegAliasIterator AI(Reg, TRI, /*IncludeSelf=*/true); AI.isValid();
         ++AI) {
      if (Succ->isLiveIn(*AI))
        return false;
    }
  }
  return true;
}

/// Return true if MI is a redundant zero-test: ORA A or CPI 0.
static bool isRedundantZeroTest(const MachineInstr &MI) {
  // ORA A: ORAr with all three operands (dst, lhs, src) = A.
  if (MI.getOpcode() == V6C::ORAr &&
      MI.getOperand(0).getReg() == V6C::A &&
      MI.getOperand(1).getReg() == V6C::A &&
      MI.getOperand(2).getReg() == V6C::A)
    return true;
  // CPI 0: compare A with immediate 0.
  if (MI.getOpcode() == V6C::CPI &&
      MI.getOperand(1).isImm() && MI.getOperand(1).getImm() == 0)
    return true;
  return false;
}

/// Return true when Reg can be read at I without an undef annotation. This is
/// used before replacing MVI A,0 or MOV A,r with XRA A; XRA A's old A input is
/// irrelevant, but the MIR verifier still needs the uses marked undef if A is
/// not live here.
static bool isRegLiveBefore(MachineBasicBlock &MBB,
                            MachineBasicBlock::iterator I, Register Reg,
                            const TargetRegisterInfo *TRI) {
  while (I != MBB.begin()) {
    --I;
    bool FoundDef = false;
    bool FoundClobber = false;
    bool FoundKilledUse = false;
    for (const MachineOperand &MO : I->operands()) {
      if (MO.isReg() && MO.isDef() && MO.getReg().isPhysical() &&
          TRI->regsOverlap(MO.getReg(), Reg))
        FoundDef = true;
      else if (MO.isReg() && MO.isUse() && MO.isKill() &&
               MO.getReg().isPhysical() && TRI->regsOverlap(MO.getReg(), Reg))
        FoundKilledUse = true;
      else if (MO.isRegMask() && MO.clobbersPhysReg(Reg))
        FoundClobber = true;
    }
    if (FoundDef)
      return true;
    if (FoundKilledUse)
      return false;
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

static void markRegUsesUndef(MachineInstr *MI, Register Reg) {
  for (MachineOperand &MO : MI->operands()) {
    if (MO.isReg() && MO.isUse() && MO.getReg() == Reg)
      MO.setIsUndef(true);
  }
}

/// Return true if MI is a DCR r or INR r instruction.
static bool isDcrOrInr(const MachineInstr &MI) {
  return MI.getOpcode() == V6C::DCRr || MI.getOpcode() == V6C::INRr;
}

/// Fold DCR/INR + redundant flag test + JNZ/JZ into DCR/INR + JNZ/JZ.
///
/// Pattern A: DCR A; ORA A; Jcc → DCR A; Jcc (remove ORA A)
/// Pattern B: DCR r; MOV A,r; ORA A; Jcc → DCR r; Jcc (remove MOV+ORA, A dead)
/// Pattern C: MOV A,r; DCR A; MOV r,A; ORA A; Jcc → DCR r; Jcc (A dead)
bool V6CPeephole::foldCounterBranch(MachineBasicBlock &MBB) {
  bool Changed = false;
  const TargetRegisterInfo *TRI =
      MBB.getParent()->getSubtarget().getRegisterInfo();
  const TargetInstrInfo &TII = *MBB.getParent()->getSubtarget().getInstrInfo();

  for (auto I = MBB.begin(), E = MBB.end(); I != E; ++I) {
    MachineInstr &BrMI = *I;
    // Match JNZ or JZ.
    if (BrMI.getOpcode() != V6C::JNZ && BrMI.getOpcode() != V6C::JZ)
      continue;

    // We need at least 2 instructions before the branch for Pattern A.
    if (I == MBB.begin())
      continue;
    auto OraIt = std::prev(I);
    if (OraIt == MBB.begin())
      continue;

    // The instruction before the branch must be ORA A or CPI 0.
    if (!isRedundantZeroTest(*OraIt))
      continue;

    auto PreOraIt = std::prev(OraIt);

    // --- Try Pattern C first (5 instructions → 2) ---
    // MOV A,r; DCR/INR A; MOV r,A; ORA A; Jcc
    if (PreOraIt != MBB.begin()) {
      auto MovRaIt = PreOraIt;  // MOV r, A
      auto DcrAIt = std::prev(MovRaIt);
      if (DcrAIt != MBB.begin()) {
        auto MovArIt = std::prev(DcrAIt);  // MOV A, r

        if (MovRaIt->getOpcode() == V6C::MOVrr &&
            MovRaIt->getOperand(1).getReg() == V6C::A &&
            isDcrOrInr(*DcrAIt) &&
            DcrAIt->getOperand(0).getReg() == V6C::A &&
            MovArIt->getOpcode() == V6C::MOVrr &&
            MovArIt->getOperand(0).getReg() == V6C::A) {
          Register CounterReg = MovArIt->getOperand(1).getReg();
          Register StoreReg = MovRaIt->getOperand(0).getReg();
          // MOV A,r and MOV r,A must refer to the same register r.
          if (CounterReg == StoreReg && CounterReg != V6C::A &&
              isRegDeadAfter(MBB, I, V6C::A, TRI)) {
            // Replace 5 instructions with DCR/INR r + Jcc.
            unsigned NewOpc = (DcrAIt->getOpcode() == V6C::DCRr)
                                  ? V6C::DCRr : V6C::INRr;
            BuildMI(MBB, *MovArIt, MovArIt->getDebugLoc(),
                    TII.get(NewOpc), CounterReg)
                .addReg(CounterReg);
            // Remove MOV A,r; DCR A; MOV r,A; ORA A (keep Jcc).
            OraIt->eraseFromParent();
            MovRaIt->eraseFromParent();
            DcrAIt->eraseFromParent();
            MovArIt->eraseFromParent();
            Changed = true;
            continue;
          }
        }
      }
    }

    // --- Try Pattern B (4 instructions → 2) ---
    // DCR r; MOV A,r; ORA A; Jcc
    if (PreOraIt->getOpcode() == V6C::MOVrr &&
        PreOraIt->getOperand(0).getReg() == V6C::A) {
      Register SrcReg = PreOraIt->getOperand(1).getReg();
      if (SrcReg != V6C::A && PreOraIt != MBB.begin()) {
        auto DcrIt = std::prev(PreOraIt);
        if (isDcrOrInr(*DcrIt) &&
            DcrIt->getOperand(0).getReg() == SrcReg &&
            isRegDeadAfter(MBB, I, V6C::A, TRI)) {
          // Remove MOV A,r and ORA A — keep DCR r and Jcc.
          OraIt->eraseFromParent();
          PreOraIt->eraseFromParent();
          Changed = true;
          continue;
        }
      }
    }

    // --- Try Pattern A (3 instructions → 2) ---
    // DCR A; ORA A; Jcc
    if (isDcrOrInr(*PreOraIt) &&
        PreOraIt->getOperand(0).getReg() == V6C::A) {
      // Remove ORA A — DCR A already set Z.
      OraIt->eraseFromParent();
      Changed = true;
      continue;
    }
  }
  return Changed;
}

/// Replace MOV A,r; ORA A; Jcc with XRA A; CMP r; Jcc (O38).
///
/// The transform saves 4cc (8cc vs 12cc) and leaves A = 0, which enables
/// O13 (LoadImmCombine) to cascade-eliminate downstream MVI A, 0.
///
/// Safety: A changes from r to 0. Valid when:
///  - Condition 1: A is dead on the fallthrough path, OR
///  - Condition 2: the next instruction on fallthrough is MVI A, 0
///    (so A = 0 is already the expected value).
bool V6CPeephole::foldXraCmpZeroTest(MachineBasicBlock &MBB) {
  bool Changed = false;
  const TargetRegisterInfo *TRI =
      MBB.getParent()->getSubtarget().getRegisterInfo();
  const TargetInstrInfo &TII = *MBB.getParent()->getSubtarget().getInstrInfo();

  for (auto I = MBB.begin(), E = MBB.end(); I != E; ++I) {
    MachineInstr &MovMI = *I;
    // Match MOV A, r (r != A).
    if (MovMI.getOpcode() != V6C::MOVrr ||
        MovMI.getOperand(0).getReg() != V6C::A)
      continue;
    Register SrcReg = MovMI.getOperand(1).getReg();
    if (SrcReg == V6C::A)
      continue;

    // Next must be ORA A or CPI 0.
    auto OraIt = std::next(I);
    if (OraIt == E)
      continue;
    if (!isRedundantZeroTest(*OraIt))
      continue;

    // Next must be JZ or JNZ.
    auto BrIt = std::next(OraIt);
    if (BrIt == E)
      continue;
    if (BrIt->getOpcode() != V6C::JZ && BrIt->getOpcode() != V6C::JNZ)
      continue;

    // Check safety: A must be dead or A=0 acceptable on fallthrough.
    bool Safe = isRegDeadAfter(MBB, BrIt, V6C::A, TRI);
    if (!Safe) {
      // Condition 2: first non-debug instruction in the fallthrough successor
      // is MVI A, 0. Since XRA A sets A=0, the value change is benign.
      MachineBasicBlock *FallThrough = nullptr;
      for (MachineBasicBlock *Succ : MBB.successors()) {
        if (MBB.isLayoutSuccessor(Succ)) {
          FallThrough = Succ;
          break;
        }
      }
      if (FallThrough) {
        auto FTIt = FallThrough->begin();
        while (FTIt != FallThrough->end() && FTIt->isDebugInstr())
          ++FTIt;
        if (FTIt != FallThrough->end() &&
            FTIt->getOpcode() == V6C::MVIr &&
            FTIt->getOperand(0).getReg() == V6C::A &&
            FTIt->getOperand(1).isImm() &&
            FTIt->getOperand(1).getImm() == 0)
          Safe = true;
      }
    }
    if (!Safe)
      continue;

    // Replace MOV A, r with XRA A.
    MachineInstr *XraMI =
        BuildMI(MBB, MovMI, MovMI.getDebugLoc(), TII.get(V6C::XRAr), V6C::A)
            .addReg(V6C::A)
            .addReg(V6C::A)
            .getInstr();
    if (!isRegLiveBefore(MBB, XraMI->getIterator(), V6C::A, TRI))
      markRegUsesUndef(XraMI, V6C::A);
    // Replace ORA A with CMP r.
    BuildMI(MBB, *OraIt, OraIt->getDebugLoc(), TII.get(V6C::CMPr))
        .addReg(V6C::A)
        .addReg(SrcReg);

    // Advance iterator past the branch before erasing MOV and ORA.
    I = BrIt;
    MovMI.eraseFromParent();
    OraIt->eraseFromParent();
    Changed = true;
  }
  return Changed;
}

/// Return true if MI reads or writes DE, HL, or any sub-register (D,E,H,L).
static bool touchesDEorHL(const MachineInstr &MI,
                          const TargetRegisterInfo *TRI) {
  for (const MachineOperand &MO : MI.operands()) {
    if (!MO.isReg())
      continue;
    Register Reg = MO.getReg();
    if (TRI->regsOverlap(Reg, V6C::DE) || TRI->regsOverlap(Reg, V6C::HL))
      return true;
  }
  return false;
}

/// Cancel XCHG pairs: XCHG; ...; XCHG → ... (remove both XCHGs).
/// Two XCHG instructions swap HL↔DE twice, which is a no-op.
/// Safe when all intervening instructions are DE/HL-agnostic (don't
/// read or write D, E, H, L, DE, or HL). Also handles the simple
/// adjacent case (no intervening instructions). Skips debug instrs.
bool V6CPeephole::cancelAdjacentXchg(MachineBasicBlock &MBB) {
  bool Changed = false;
  const TargetRegisterInfo *TRI =
      MBB.getParent()->getSubtarget().getRegisterInfo();

  for (auto I = MBB.begin(), E = MBB.end(); I != E; ) {
    if (I->getOpcode() != V6C::XCHG) {
      ++I;
      continue;
    }
    // Scan forward looking for a matching XCHG.
    auto J = std::next(I);
    bool CanCancel = true;
    while (J != E) {
      if (J->isDebugInstr()) {
        ++J;
        continue;
      }
      if (J->getOpcode() == V6C::XCHG)
        break; // Found matching XCHG.
      if (touchesDEorHL(*J, TRI)) {
        CanCancel = false;
        break; // Intervening instr uses DE/HL — can't cancel.
      }
      ++J;
    }
    if (CanCancel && J != E && J->getOpcode() == V6C::XCHG) {
      // XCHG pair found — delete both.
      MBB.erase(J);        // erase second XCHG
      I = MBB.erase(I);    // erase first XCHG, I now points to next
      Changed = true;
      continue;             // re-check from new I (may be another XCHG)
    }
    ++I;
  }
  return Changed;
}

/// Fold XCHG; DAD DE → DAD DE.
///
/// XCHG swaps HL↔DE, then DAD DE computes (old-DE) + (old-HL) → HL.
/// Without XCHG, DAD DE computes (old-HL) + (old-DE) → HL — same result
/// because addition is commutative.  However DE differs: with XCHG it
/// holds old-HL; without, old-DE.  Safe only when DE is dead after DAD.
bool V6CPeephole::foldXchgDad(MachineBasicBlock &MBB) {
  bool Changed = false;
  const TargetRegisterInfo *TRI =
      MBB.getParent()->getSubtarget().getRegisterInfo();

  for (auto I = MBB.begin(), E = MBB.end(); I != E; ++I) {
    if (I->getOpcode() != V6C::XCHG)
      continue;

    auto Next = std::next(I);
    if (Next == E || Next->getOpcode() != V6C::DAD)
      continue;

    // DAD operand must be DE.
    if (Next->getOperand(0).getReg() != V6C::DE)
      continue;

    // DE must be dead after DAD (DE value differs with/without XCHG).
    if (!isRegDeadAfter(MBB, Next, V6C::DE, TRI))
      continue;

    // Safe to remove the XCHG.
    I = MBB.erase(I);
    // I now points at DAD — continue loop from there.
    Changed = true;
  }
  return Changed;
}

/// Return true if two MachineOperands represent the same address
/// (both GlobalAddress with same GV and offset, or both identical immediates).
static bool isSameAddress(const MachineOperand &A, const MachineOperand &B) {
  if (A.getType() != B.getType())
    return false;
  if (A.isGlobal())
    return A.getGlobal() == B.getGlobal() && A.getOffset() == B.getOffset();
  if (A.isImm())
    return A.getImm() == B.getImm();
  return false;
}

/// Check if any LHLD of the same address is reachable from AfterD
/// without passing through a covering SHLD.  ShldC is the SHLD being
/// folded — it doesn't count as a covering store (it will be removed).
static bool isUncoveredLhldReachable(
    MachineBasicBlock &MBB,
    MachineBasicBlock::iterator AfterD,
    MachineBasicBlock::iterator ShldC,
    const MachineOperand &Addr) {

  // 1. Scan remainder of current BB after the folded LHLD.
  for (auto I = AfterD, E = MBB.end(); I != E; ++I) {
    if (I->getOpcode() == V6C::SHLD && isSameAddress(Addr, I->getOperand(1)))
      return false;  // another SHLD covers all forward paths
    if (I->getOpcode() == V6C::LHLD && isSameAddress(Addr, I->getOperand(1)))
      return true;   // uncovered reader in same BB
  }

  // 2. BFS through successor BBs (including self-loops via back-edges).
  //    Do NOT pre-insert MBB — it must be revisited when reached via a
  //    back-edge so the self-loop scan (begin → ShldC) runs.
  SmallPtrSet<MachineBasicBlock *, 8> Visited;
  SmallVector<MachineBasicBlock *, 8> Worklist;

  for (auto *Succ : MBB.successors())
    if (Visited.insert(Succ).second)
      Worklist.push_back(Succ);

  while (!Worklist.empty()) {
    MachineBasicBlock *Cur = Worklist.pop_back_val();
    bool IsSelf = (Cur == &MBB);

    // Self-loop: scan from BB top to ShldC (C is being folded, not a cover).
    auto ScanEnd = IsSelf ? MachineBasicBlock::iterator(ShldC) : Cur->end();

    for (auto I = Cur->begin(); I != ScanEnd; ++I) {
      if (I->getOpcode() == V6C::SHLD && isSameAddress(Addr, I->getOperand(1)))
        goto next_bb;  // covered — don't follow successors
      if (I->getOpcode() == V6C::LHLD && isSameAddress(Addr, I->getOperand(1)))
        return true;   // uncovered reader
    }

    // No kill found — propagate to successors.
    for (auto *Succ : Cur->successors())
      if (Visited.insert(Succ).second)
        Worklist.push_back(Succ);
    next_bb:;
  }

  return false;  // no uncovered reader reachable
}

/// Replace SHLD addr / LHLD addr pairs with PUSH HL / POP HL (O43).
///
/// When a static-stack spill (SHLD) and its matching reload (LHLD) are in
/// the same basic block with SP delta == 0 at the LHLD, PUSH HL + POP HL
/// is cheaper: 28cc/2B vs 40cc/6B.
///
/// SP delta tracking: PUSH decrements by 2, POP increments by 2.
/// CALL/Ccc/RST are net-zero (callee restores SP via RET).
/// Any other SP modifier (SPHL, LXI SP, INX SP, DCX SP) causes abort.
bool V6CPeephole::foldShldLhldToPushPop(MachineBasicBlock &MBB) {
  if (DisableShldLhldFold)
    return false;
  bool Changed = false;
  const TargetRegisterInfo *TRI =
      MBB.getParent()->getSubtarget().getRegisterInfo();
  const TargetInstrInfo &TII = *MBB.getParent()->getSubtarget().getInstrInfo();

  for (auto I = MBB.begin(), E = MBB.end(); I != E; ++I) {
    if (I->getOpcode() != V6C::SHLD)
      continue;

    const MachineOperand &ShldAddr = I->getOperand(1);
    int SPDelta = 0;
    bool Abort = false;
    MachineBasicBlock::iterator MatchIt;
    bool Found = false;

    for (auto J = std::next(I); J != E; ++J) {
      if (J->isDebugInstr())
        continue;

      // Check for matching LHLD.
      if (J->getOpcode() == V6C::LHLD &&
          isSameAddress(ShldAddr, J->getOperand(1))) {
        if (SPDelta == 0) {
          MatchIt = J;
          Found = true;
        } else {
          Abort = true;
        }
        break;
      }

      // Abort on re-spill to same address.
      if (J->getOpcode() == V6C::SHLD &&
          isSameAddress(ShldAddr, J->getOperand(1))) {
        Abort = true;
        break;
      }

      // SP delta tracking.
      if (J->modifiesRegister(V6C::SP, TRI)) {
        unsigned Opc = J->getOpcode();
        if (Opc == V6C::PUSH) {
          SPDelta -= 2;
        } else if (Opc == V6C::POP) {
          SPDelta += 2;
          if (SPDelta > 0) { Abort = true; break; }
        } else if (J->isCall()) {
          // CALL/Ccc/RST: net-zero SP effect, skip.
        } else {
          // Unknown SP modifier (SPHL, LXI SP, INX SP, DCX SP, etc.)
          Abort = true;
          break;
        }
      }
    }

    if (Abort || !Found)
      continue;

    // Safety: check that no uncovered LHLD reads this address via any
    // forward path (including loop back-edges and cross-BB paths).
    if (isUncoveredLhldReachable(MBB, std::next(MatchIt), I, ShldAddr))
      continue;

    // Replace SHLD with PUSH HL.
    BuildMI(MBB, *I, I->getDebugLoc(), TII.get(V6C::PUSH))
        .addReg(V6C::HL);
    // Replace LHLD with POP HL.
    BuildMI(MBB, *MatchIt, MatchIt->getDebugLoc(), TII.get(V6C::POP), V6C::HL);

    MatchIt->eraseFromParent();
    I = MBB.erase(I);
    Changed = true;
    --I; // compensate for ++I in loop header
  }
  return Changed;
}

/// Map a register-form ALU opcode (V6C::ADDr/.../CMPr) to its memory-form
/// counterpart (V6C::ADDM/.../CMPM). Returns 0 if Opc is not foldable.
static unsigned aluRegToMemOpcode(unsigned Opc) {
  switch (Opc) {
  case V6C::ADDr: return V6C::ADDM;
  case V6C::ADCr: return V6C::ADCM;
  case V6C::SUBr: return V6C::SUBM;
  case V6C::SBBr: return V6C::SBBM;
  case V6C::ANAr: return V6C::ANAM;
  case V6C::XRAr: return V6C::XRAM;
  case V6C::ORAr: return V6C::ORAM;
  case V6C::CMPr: return V6C::CMPM;
  default:        return 0;
  }
}

/// Stage 2 helper for O65: walk MIs in [Begin, End) and report whether
/// every MI is safe to cross while preserving the value of `R` AND the
/// A / FLAGS / [HL] observer chain.
///
/// Each crossed MI must:
///   * not read or write R (or any aliasing reg),
///   * not read or write any reg overlapping HL,
///   * not write A (a write to A would clobber the eventual OP M's lhs),
///   * not write FLAGS (downstream Jcc must observe the OP M's flags),
///   * not be a call / branch / return / barrier,
///   * not be mayStore (a store could alias [HL]).
static bool scanBetweenSafe(MachineBasicBlock::iterator Begin,
                            MachineBasicBlock::iterator End, Register R,
                            const TargetRegisterInfo *TRI) {
  for (auto K = Begin; K != End; ++K) {
    if (K->isDebugInstr())
      continue;
    if (K->isCall() || K->isBranch() || K->isReturn() || K->isBarrier())
      return false;
    if (K->mayStore())
      return false;
    for (const MachineOperand &MO : K->operands()) {
      if (!MO.isReg() || !MO.getReg())
        continue;
      Register Reg = MO.getReg();
      bool TouchesR  = TRI->regsOverlap(Reg, R);
      bool TouchesHL = TRI->regsOverlap(Reg, V6C::HL);
      bool TouchesA  = TRI->regsOverlap(Reg, V6C::A);
      bool TouchesF  = TRI->regsOverlap(Reg, V6C::FLAGS);
      if (!TouchesR && !TouchesHL && !TouchesA && !TouchesF)
        continue;
      if (TouchesR || TouchesHL)
        return false; // any read or write of R or HL is unsafe
      if (MO.isDef() && (TouchesA || TouchesF))
        return false; // crossing a write to A or FLAGS is unsafe
      // Pure read of A or FLAGS is fine.
    }
  }
  return true;
}

/// Fold MOV r, M; ...; OP r -> ...; OP M when r is dead after OP (O65,
/// stages 1+2).
///
/// Stage 1 -- strict adjacency (debug MIs skipped).
/// Stage 2 -- arbitrary independent MIs between the MOV and the OP, as
///            long as scanBetweenSafe() approves every crossed MI. The
///            forward window is bounded by kMaxScanWindow to avoid
///            quadratic behavior in pathologically large blocks.
bool V6CPeephole::foldMovAluM(MachineBasicBlock &MBB) {
  bool Changed = false;
  const TargetRegisterInfo *TRI =
      MBB.getParent()->getSubtarget().getRegisterInfo();
  const TargetInstrInfo &TII =
      *MBB.getParent()->getSubtarget().getInstrInfo();

  static constexpr unsigned kMaxScanWindow = 16;

  for (auto I = MBB.begin(), E = MBB.end(); I != E;) {
    if (I->getOpcode() != V6C::MOVrM) {
      ++I;
      continue;
    }

    Register MovDst = I->getOperand(0).getReg();
    if (MovDst == V6C::A) {
      ++I;
      continue;
    }

    // Walk forward up to kMaxScanWindow non-debug MIs looking for the
    // matching OPr. Stop early on any unsafe MI.
    auto J = std::next(I);
    unsigned Steps = 0;
    bool Failed = false;
    while (J != E && Steps < kMaxScanWindow) {
      if (J->isDebugInstr()) {
        ++J;
        continue;
      }
      // Is this the candidate ALU op?
      unsigned MemOpc = aluRegToMemOpcode(J->getOpcode());
      if (MemOpc != 0) {
        bool IsCMP = (J->getOpcode() == V6C::CMPr);
        unsigned RhsIdx = IsCMP ? 1 : 2;
        if (J->getOperand(RhsIdx).getReg() == MovDst)
          break; // found
      }
      // Otherwise it must be safe to cross.
      if (!scanBetweenSafe(J, std::next(J), MovDst, TRI)) {
        Failed = true;
        break;
      }
      ++J;
      ++Steps;
    }

    if (Failed || J == E || Steps >= kMaxScanWindow) {
      ++I;
      continue;
    }

    unsigned MemOpc = aluRegToMemOpcode(J->getOpcode());
    if (MemOpc == 0) {
      ++I;
      continue;
    }

    bool IsCMP = (J->getOpcode() == V6C::CMPr);

    // r must be dead after the ALU op.
    if (!isRegDeadAfter(MBB, J, MovDst, TRI)) {
      ++I;
      continue;
    }

    // Build OP M before J. For non-CMP: outs Acc:$dst tied to ins Acc:$lhs.
    //                      For CMP:    no outs.
    MachineInstrBuilder MIB =
        BuildMI(MBB, *J, J->getDebugLoc(), TII.get(MemOpc));
    if (!IsCMP)
      MIB.addReg(V6C::A, RegState::Define);
    MIB.addReg(V6C::A);

    // Erase the ALU op and the original MOV.
    auto Next = std::next(J);
    J->eraseFromParent();
    auto INext = std::next(I);
    I->eraseFromParent();
    // Resume scanning from where the MOV used to be: any MI that was
    // between MOV and OP is now adjacent to the new OP M.
    I = (INext == Next) ? Next : INext;
    Changed = true;
  }
  return Changed;
}

/// Find the next non-debug iterator at or after K (does not advance past End).
static MachineBasicBlock::iterator
nextNonDebug(MachineBasicBlock::iterator K, MachineBasicBlock::iterator End) {
  while (K != End && K->isDebugInstr())
    ++K;
  return K;
}

/// Stage 3 fold for O65: collapse MOV A, M; INR/DCR A; MOV M, A into
/// INR M / DCR M, and MVI A, imm; MOV M, A into MVI M, imm. In both
/// cases A must be dead after the MOV M, A.
///
/// Adjacency: debug MIs are skipped between the head, middle, and tail
/// instructions of each shape.
bool V6CPeephole::foldIncDecMviM(MachineBasicBlock &MBB) {
  bool Changed = false;
  const TargetRegisterInfo *TRI =
      MBB.getParent()->getSubtarget().getRegisterInfo();
  const TargetInstrInfo &TII =
      *MBB.getParent()->getSubtarget().getInstrInfo();

  for (auto I = MBB.begin(), E = MBB.end(); I != E;) {
    unsigned Opc = I->getOpcode();

    // ---- Shape A: MOV A, M ; INR/DCR A ; MOV M, A -> INR/DCR M ----
    if (Opc == V6C::MOVrM && I->getOperand(0).getReg() == V6C::A) {
      auto Mid = nextNonDebug(std::next(I), E);
      if (Mid != E &&
          (Mid->getOpcode() == V6C::INRr || Mid->getOpcode() == V6C::DCRr) &&
          Mid->getOperand(0).getReg() == V6C::A) {
        auto Tail = nextNonDebug(std::next(Mid), E);
        if (Tail != E && Tail->getOpcode() == V6C::MOVMr &&
            Tail->getOperand(0).getReg() == V6C::A &&
            isRegDeadAfter(MBB, Tail, V6C::A, TRI)) {
          unsigned MemOpc =
              (Mid->getOpcode() == V6C::INRr) ? V6C::INRM : V6C::DCRM;
          BuildMI(MBB, *Tail, Tail->getDebugLoc(), TII.get(MemOpc));
          auto Next = std::next(Tail);
          Tail->eraseFromParent();
          Mid->eraseFromParent();
          I->eraseFromParent();
          I = Next;
          Changed = true;
          continue;
        }
      }
    }

    // ---- Shape B: MVI A, imm ; MOV M, A -> MVI M, imm ----
    // O61 patched MVIs are still foldable: MVI M, imm has its own
    // imm byte at the same `Sym+1` offset (both encodings are
    // [opcode, imm] with the imm at byte offset 1), so we forward
    // the pre-instr `.LLo61_N:` label and the operand's target flags
    // (e.g. MO_PATCH_IMM) onto the new MVI M.
    if (Opc == V6C::MVIr && I->getOperand(0).getReg() == V6C::A) {
      auto Tail = nextNonDebug(std::next(I), E);
      if (Tail != E && Tail->getOpcode() == V6C::MOVMr &&
          Tail->getOperand(0).getReg() == V6C::A &&
          isRegDeadAfter(MBB, Tail, V6C::A, TRI)) {
        const MachineOperand &ImmOp = I->getOperand(1);
        MachineFunction &MF = *MBB.getParent();
        MachineInstr *NewMI =
            BuildMI(MBB, *Tail, Tail->getDebugLoc(), TII.get(V6C::MVIM))
                .add(ImmOp)
                .getInstr();
        if (MCSymbol *PreSym = I->getPreInstrSymbol())
          NewMI->setPreInstrSymbol(MF, PreSym);
        auto Next = std::next(Tail);
        Tail->eraseFromParent();
        I->eraseFromParent();
        I = Next;
        Changed = true;
        continue;
      }
    }

    ++I;
  }
  return Changed;
}

/// O55 Pattern 2: replace `MVI A, 0` with `XRA A` when FLAGS is dead
/// after the instruction. Saves 1 byte and 4 cycles per instance.
///
/// `XRA A` zeroes A *and* clobbers FLAGS (Z=1, S=0, P=1, CY=0, AC=0),
/// while `MVI A, 0` leaves FLAGS untouched. The rewrite is therefore
/// only legal when no live FLAGS use follows.
bool V6CPeephole::foldMviZeroToXraA(MachineBasicBlock &MBB) {
  bool Changed = false;
  const TargetRegisterInfo *TRI =
      MBB.getParent()->getSubtarget().getRegisterInfo();
  const TargetInstrInfo &TII =
      *MBB.getParent()->getSubtarget().getInstrInfo();

  for (MachineInstr &MI : llvm::make_early_inc_range(MBB)) {
    if (MI.getOpcode() != V6C::MVIr)
      continue;
    if (MI.getOperand(0).getReg() != V6C::A)
      continue;
    if (!MI.getOperand(1).isImm() || MI.getOperand(1).getImm() != 0)
      continue;
    // Skip O61 patched MVIs: imm 0 is a placeholder, real value is
    // written to MI's imm byte at runtime by an STA spill, and
    // erasing the MI loses the .LLo61_N label.
    if (isO61PatchedImm(MI))
      continue;
    if (!isRegDeadAfter(MBB, MI.getIterator(), V6C::FLAGS, TRI))
      continue;

    MachineInstr *XraMI = BuildMI(MBB, MI, MI.getDebugLoc(), TII.get(V6C::XRAr),
                                  V6C::A)
                              .addReg(V6C::A)
                              .addReg(V6C::A)
                              .getInstr();
    if (!isRegLiveBefore(MBB, XraMI->getIterator(), V6C::A, TRI))
      markRegUsesUndef(XraMI, V6C::A);
    MI.eraseFromParent();
    Changed = true;
  }
  return Changed;
}

/// Map register-form ALU opcode -> immediate-form opcode.
/// Both forms set FLAGS identically (same ALU function bits in the
/// 8080 encoding).  CPI has no def of A; the others tie dst = lhs = A.
static unsigned aluRegToImmOpc(unsigned Opc) {
  switch (Opc) {
  case V6C::ADDr: return V6C::ADI;
  case V6C::ADCr: return V6C::ACI;
  case V6C::SUBr: return V6C::SUI;
  case V6C::SBBr: return V6C::SBI;
  case V6C::ANAr: return V6C::ANI;
  case V6C::XRAr: return V6C::XRI;
  case V6C::ORAr: return V6C::ORI;
  case V6C::CMPr: return V6C::CPI;
  default:        return 0;
  }
}

/// Return the GR8-source-operand index of a register-form ALU op.
/// For writers (ADDr/.../ORAr): operands are (dst=A, lhs=A, src=GR8).
/// For CMPr: operands are (lhs=A, src=GR8) with no def.
static unsigned aluRegSrcOpIdx(unsigned Opc) {
  return (Opc == V6C::CMPr) ? 1u : 2u;
}

/// O79: fold `MVI R, NN; ... ; ALU R` into `... ; ALU-immediate NN`
/// when no instruction strictly between the MVI and the ALU op
/// reads or writes R (or its 16-bit alias), and R is dead after the
/// ALU op.  Saves 1B / 4cc per fire and frees R for register
/// allocation across the gap.
///
/// The fold preserves O61 patched-immediate metadata: the
/// pre-instruction MCSymbol (`.LLo61_N` label, used by spill
/// `STA <Sym+1>`) and the imm operand's MO_PATCH_IMM target flag
/// are transferred to the new ALU-immediate instruction.  Both
/// `MVI r,imm8` and `ADI/SUI/.../CPI` are 2-byte instructions
/// with the imm at offset +1, so `<Sym+1>` keeps targeting the
/// correct byte.
bool V6CPeephole::foldMviAluImm(MachineBasicBlock &MBB) {
  if (DisableMviAluFold)
    return false;

  bool Changed = false;
  MachineFunction &MF = *MBB.getParent();
  const TargetRegisterInfo *TRI = MF.getSubtarget().getRegisterInfo();
  const TargetInstrInfo &TII = *MF.getSubtarget().getInstrInfo();

  for (auto I = MBB.begin(), E = MBB.end(); I != E; ) {
    MachineInstr &MVI = *I;
    auto NextI = std::next(I);

    if (MVI.getOpcode() != V6C::MVIr) { I = NextI; continue; }
    Register R = MVI.getOperand(0).getReg();
    if (R == V6C::A) { I = NextI; continue; }
    // The fold copies the imm operand wholesale; it must be a real
    // immediate (target-flagged O61 placeholders are still .isImm()).
    if (!MVI.getOperand(1).isImm()) { I = NextI; continue; }

    // Forward-scan for the ALU consumer.
    MachineBasicBlock::iterator J = NextI;
    bool Blocked = false;
    for (; J != E; ++J) {
      MachineInstr &Cand = *J;
      if (Cand.isDebugInstr()) continue;
      // Hard barriers.
      if (Cand.isCall() || Cand.isInlineAsm() ||
          Cand.hasUnmodeledSideEffects()) {
        Blocked = true;
        break;
      }

      // Recognise the ALU-on-R consumer.
      unsigned ImmOpc = aluRegToImmOpc(Cand.getOpcode());
      if (ImmOpc) {
        unsigned SrcIdx = aluRegSrcOpIdx(Cand.getOpcode());
        const MachineOperand &SrcMO = Cand.getOperand(SrcIdx);
        if (SrcMO.isReg() && SrcMO.getReg() == R) {
          // Match — don't run the read/write barrier on this MI;
          // its read of R is the success case.
          break;
        }
      }

      // Any operand reading or writing R (or an aliasing 16-bit
      // pair) blocks; regmasks on calls handled above.
      for (const MachineOperand &MO : Cand.operands()) {
        if (MO.isRegMask() && MO.clobbersPhysReg(R)) {
          Blocked = true;
          break;
        }
        if (!MO.isReg() || !MO.getReg())
          continue;
        if (TRI->regsOverlap(MO.getReg(), R)) {
          Blocked = true;
          break;
        }
      }
      if (Blocked)
        break;
    }
    if (Blocked || J == E) { I = NextI; continue; }

    // R must be dead after the ALU consumer (its only purpose was
    // to deliver the materialized immediate).
    if (!isRegDeadAfter(MBB, J, R, TRI)) { I = NextI; continue; }

    MachineInstr &Cons = *J;
    unsigned ImmOpc = aluRegToImmOpc(Cons.getOpcode());

    // Build the immediate-form ALU op at the consumer's position.
    DebugLoc DL = Cons.getDebugLoc();
    MachineInstrBuilder MIB = BuildMI(MBB, Cons, DL, TII.get(ImmOpc));
    if (ImmOpc != V6C::CPI) {
      // ADI/ACI/.../ORI: (outs Acc:$dst)(ins Acc:$lhs, imm8:$imm)
      MIB.addReg(V6C::A, RegState::Define).addReg(V6C::A);
    } else {
      // CPI: (outs)(ins Acc:$lhs, imm8:$imm)
      MIB.addReg(V6C::A);
    }
    // Copy the imm operand wholesale to preserve target flags
    // (notably V6CII::MO_PATCH_IMM for O61 patched landing pads).
    MIB.add(MVI.getOperand(1));

    // Transfer pre-instruction symbol (e.g. O61 `.LLo61_N` label).
    if (MCSymbol *PreSym = MVI.getPreInstrSymbol())
      MIB.getInstr()->setPreInstrSymbol(MF, PreSym);

    // Erase the consumer first (frees J), then erase MVI.
    Cons.eraseFromParent();
    I = MBB.erase(MVI);
    Changed = true;
  }
  return Changed;
}

bool V6CPeephole::runOnMachineFunction(MachineFunction &MF) {
  if (DisablePeephole)
    return false;

  bool Changed = false;
  for (MachineBasicBlock &MBB : MF) {
    Changed |= cancelAdjacentXchg(MBB);
    Changed |= foldShldLhldToPushPop(MBB);
    Changed |= foldMovAluM(MBB);
    Changed |= foldIncDecMviM(MBB);
    Changed |= eliminateSelfMov(MBB);
    Changed |= eliminateRedundantMov(MBB);
    Changed |= foldCounterBranch(MBB);
    Changed |= foldXraCmpZeroTest(MBB);
    Changed |= foldXchgDad(MBB);
    Changed |= eliminateTailCall(MBB);
    Changed |= foldMviAluImm(MBB);
    Changed |= foldMviZeroToXraA(MBB);
  }
  return Changed;
}

FunctionPass *llvm::createV6CPeepholePass() {
  return new V6CPeephole();
}
