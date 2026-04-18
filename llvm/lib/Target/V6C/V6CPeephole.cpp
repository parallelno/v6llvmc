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
/// block reads Reg before redefining it, and no successor has Reg as a livein.
static bool isRegDeadAfter(MachineBasicBlock &MBB,
                           MachineBasicBlock::iterator I,
                           unsigned Reg,
                           const TargetRegisterInfo *TRI) {
  for (auto MI = std::next(I); MI != MBB.end(); ++MI) {
    bool usesReg = false, defsReg = false;
    for (const MachineOperand &MO : MI->operands()) {
      if (!MO.isReg() || !TRI->regsOverlap(MO.getReg(), Reg))
        continue;
      if (MO.isUse())
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
    BuildMI(MBB, MovMI, MovMI.getDebugLoc(), TII.get(V6C::XRAr), V6C::A)
        .addReg(V6C::A)
        .addReg(V6C::A);
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

bool V6CPeephole::runOnMachineFunction(MachineFunction &MF) {
  if (DisablePeephole)
    return false;

  bool Changed = false;
  for (MachineBasicBlock &MBB : MF) {
    Changed |= cancelAdjacentXchg(MBB);
    Changed |= foldShldLhldToPushPop(MBB);
    Changed |= eliminateSelfMov(MBB);
    Changed |= eliminateRedundantMov(MBB);
    Changed |= foldCounterBranch(MBB);
    Changed |= foldXraCmpZeroTest(MBB);
    Changed |= foldXchgDad(MBB);
    Changed |= eliminateTailCall(MBB);
  }
  return Changed;
}

FunctionPass *llvm::createV6CPeepholePass() {
  return new V6CPeephole();
}
