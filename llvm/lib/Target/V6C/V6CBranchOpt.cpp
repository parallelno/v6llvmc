//===-- V6CBranchOpt.cpp - V6C Branch Optimizations ----------------------===//
//
// Part of the V6C backend for LLVM.
//
// Post-RA pass for branch optimizations:
//
// 1. Branch threading: if a branch (Jcc or JMP) targets a block whose
//    only instruction is JMP target, redirect the branch directly to
//    target.
//
// 2. Redundant JMP elimination: JMP to the immediately following block
//    (layout successor) is removed — the fall-through is free.
//
// 3. Conditional branch inversion: if a Jcc jumps over a JMP, invert the
//    condition and remove the JMP.
//    Example:  JZ .Ltmp1 / JMP .Ltmp2 / .Ltmp1:
//           →  JNZ .Ltmp2 / .Ltmp1:
//
// 4. Dead block removal: blocks with no predecessors (after other opts)
//    are removed.
//
// 5. Conditional return folding: Jcc to a block containing only RET is
//    replaced with the corresponding Rcc instruction (e.g. JZ→RZ).
//
// 6. Conditional return over RET: if a Jcc jumps over a fallthrough RET
//    to its layout successor, replace Jcc+RET with the inverted Rcc.
//    Example:  JZ .Lskip / RET / .Lskip:
//           →  RNZ / .Lskip:
//
//===----------------------------------------------------------------------===//

#include "V6C.h"
#include "MCTargetDesc/V6CMCTargetDesc.h"
#include "V6CISelLowering.h"
#include "llvm/CodeGen/MachineFunctionPass.h"
#include "llvm/CodeGen/MachineInstrBuilder.h"
#include "llvm/CodeGen/TargetInstrInfo.h"
#include "llvm/CodeGen/TargetSubtargetInfo.h"
#include "llvm/Support/CommandLine.h"

using namespace llvm;

#define DEBUG_TYPE "v6c-branch-opt"

static cl::opt<bool> DisableBranchOpt(
    "v6c-disable-branch-opt",
    cl::desc("Disable V6C branch optimizations"),
    cl::init(false), cl::Hidden);

namespace {

class V6CBranchOpt : public MachineFunctionPass {
public:
  static char ID;
  V6CBranchOpt() : MachineFunctionPass(ID) {}

  StringRef getPassName() const override {
    return "V6C Branch Optimization";
  }

  bool runOnMachineFunction(MachineFunction &MF) override;

private:
  bool invertConditionalOverRET(MachineFunction &MF);
  bool threadJMPOnlyBlocks(MachineFunction &MF);
  bool removeRedundantJMP(MachineFunction &MF);
  bool invertConditionalBranch(MachineFunction &MF);
  bool foldConditionalReturns(MachineFunction &MF);
  bool removeDeadBlocks(MachineFunction &MF);

  /// Get the inverted opcode for a conditional jump, or 0 if not invertible.
  static unsigned getInvertedJcc(unsigned Opc);
};

} // end anonymous namespace

char V6CBranchOpt::ID = 0;

unsigned V6CBranchOpt::getInvertedJcc(unsigned Opc) {
  switch (Opc) {
  case V6C::JNZ: return V6C::JZ;
  case V6C::JZ:  return V6C::JNZ;
  case V6C::JNC: return V6C::JC;
  case V6C::JC:  return V6C::JNC;
  case V6C::JPO: return V6C::JPE;
  case V6C::JPE: return V6C::JPO;
  case V6C::JP:  return V6C::JM;
  case V6C::JM:  return V6C::JP;
  default: return 0;
  }
}

/// Thread branches through JMP-only successor blocks.
/// If a branch (Jcc or JMP) targets a block whose only non-debug
/// instruction is JMP/V6C_TAILJMP target, redirect the branch to
/// target directly.
bool V6CBranchOpt::threadJMPOnlyBlocks(MachineFunction &MF) {
  bool Changed = false;

  for (MachineBasicBlock &MBB : MF) {
    for (MachineInstr &MI : MBB.terminators()) {
      // Must be a branch to an MBB (Jcc or JMP).
      if (MI.getOpcode() != V6C::JMP && !getInvertedJcc(MI.getOpcode()))
        continue;
      if (!MI.getOperand(0).isMBB())
        continue;

      MachineBasicBlock *Target = MI.getOperand(0).getMBB();

      // Check if Target is a JMP-only block.
      auto FirstNonDbg = Target->getFirstNonDebugInstr();
      if (FirstNonDbg == Target->end())
        continue;
      if (FirstNonDbg->getOpcode() != V6C::JMP &&
          FirstNonDbg->getOpcode() != V6C::V6C_TAILJMP)
        continue;
      // Verify it's the only non-debug instruction.
      auto Next = std::next(FirstNonDbg);
      while (Next != Target->end() && Next->isDebugInstr())
        ++Next;
      if (Next != Target->end())
        continue;

      // Redirect our branch to the JMP's final target.
      MachineOperand &FinalTargetOp = FirstNonDbg->getOperand(0);

      if (FinalTargetOp.isMBB()) {
        // Internal branch: redirect to the final MBB.
        MI.getOperand(0).setMBB(FinalTargetOp.getMBB());
        MBB.replaceSuccessor(Target, FinalTargetOp.getMBB());
      } else if (FinalTargetOp.isGlobal()) {
        // External tail call (global address): redirect Jcc to symbol.
        MI.getOperand(0).ChangeToGA(FinalTargetOp.getGlobal(),
                                     FinalTargetOp.getOffset(),
                                     FinalTargetOp.getTargetFlags());
        MBB.removeSuccessor(Target);
      } else if (FinalTargetOp.isSymbol()) {
        MI.getOperand(0).ChangeToES(FinalTargetOp.getSymbolName(),
                                     FinalTargetOp.getTargetFlags());
        MBB.removeSuccessor(Target);
      } else if (FinalTargetOp.isMCSymbol()) {
        MI.getOperand(0).ChangeToMCSymbol(FinalTargetOp.getMCSymbol(),
                                           FinalTargetOp.getTargetFlags());
        MBB.removeSuccessor(Target);
      } else {
        continue; // Unknown operand type — skip.
      }
      Changed = true;
    }
  }

  return Changed;
}

/// Remove unconditional JMP instructions that jump to the next block
/// in layout order (fall-through).
bool V6CBranchOpt::removeRedundantJMP(MachineFunction &MF) {
  bool Changed = false;

  for (MachineBasicBlock &MBB : MF) {
    // Find the last instruction in the block.
    if (MBB.empty())
      continue;

    MachineInstr &Last = MBB.back();
    if (Last.getOpcode() != V6C::JMP)
      continue;
    if (!Last.getOperand(0).isMBB())
      continue;

    // Check if the JMP target is the layout successor.
    MachineBasicBlock *Target = Last.getOperand(0).getMBB();
    MachineFunction::iterator NextBB = std::next(MBB.getIterator());
    if (NextBB != MF.end() && &*NextBB == Target) {
      Last.eraseFromParent();
      Changed = true;
    }
  }

  return Changed;
}

/// Look for patterns: Jcc .Lskip / JMP .Ltarget / .Lskip:
/// Transform to: Jcc_inv .Ltarget / .Lskip:
/// Also handles V6C_TAILJMP (tail call) as the unconditional branch.
/// Saves 3 bytes and ~12cc.
bool V6CBranchOpt::invertConditionalBranch(MachineFunction &MF) {
  bool Changed = false;

  for (MachineBasicBlock &MBB : MF) {
    // Need at least 2 instructions.
    if (MBB.size() < 2)
      continue;

    auto LastI = MBB.end();
    --LastI; // Points to last instruction.
    MachineInstr &Last = *LastI;
    if (Last.getOpcode() != V6C::JMP &&
        Last.getOpcode() != V6C::V6C_TAILJMP)
      continue;

    --LastI; // Points to second-to-last instruction.
    MachineInstr &Prev = *LastI;
    unsigned InvOpc = getInvertedJcc(Prev.getOpcode());
    if (!InvOpc)
      continue;

    // The Jcc target must be the layout successor (fall-through after the JMP).
    if (!Prev.getOperand(0).isMBB())
      continue;
    MachineBasicBlock *JccTarget = Prev.getOperand(0).getMBB();
    MachineFunction::iterator NextBB = std::next(MBB.getIterator());
    if (NextBB == MF.end() || &*NextBB != JccTarget)
      continue;

    // Transform: invert the Jcc to jump to the JMP/V6C_TAILJMP's target,
    // remove the unconditional branch.
    const TargetInstrInfo &TII = *MF.getSubtarget().getInstrInfo();

    BuildMI(MBB, Prev, Prev.getDebugLoc(), TII.get(InvOpc))
        .add(Last.getOperand(0));

    // Update CFG: MBB now branches to JmpTarget and falls through to JccTarget.
    // The old successors are still correct since we flipped the condition.
    Last.eraseFromParent();
    Prev.eraseFromParent();
    Changed = true;
  }

  return Changed;
}

/// Map Jcc opcode to corresponding Rcc opcode, or 0 if not a Jcc.
static unsigned getConditionalReturn(unsigned JccOpc) {
  switch (JccOpc) {
  case V6C::JZ:  return V6C::RZ;
  case V6C::JNZ: return V6C::RNZ;
  case V6C::JC:  return V6C::RC;
  case V6C::JNC: return V6C::RNC;
  case V6C::JPE: return V6C::RPE;
  case V6C::JPO: return V6C::RPO;
  case V6C::JP:  return V6C::RP;
  case V6C::JM:  return V6C::RM;
  default: return 0;
  }
}

/// Return true if MBB contains only RET (ignoring debug instructions).
static bool isReturnOnlyBlock(const MachineBasicBlock &MBB) {
  for (const MachineInstr &MI : MBB) {
    if (MI.isDebugInstr())
      continue;
    return MI.getOpcode() == V6C::RET;
  }
  return false; // empty block
}

/// Look for the pattern:
///   MBB: ... Jcc target [JMP retBB]
///   retBB: RET                          (layout successor of MBB, RET-only)
///   target: ...                         (layout successor of retBB)
///
/// Transform to:
///   MBB: ... Rcc_inv                    (inverted conditional return)
///   target: ...                         (falls through from MBB)
///
/// The retBB is removed (dead — no other predecessors).
bool V6CBranchOpt::invertConditionalOverRET(MachineFunction &MF) {
  bool Changed = false;
  const TargetInstrInfo &TII = *MF.getSubtarget().getInstrInfo();
  SmallVector<MachineBasicBlock *, 4> DeadBlocks;

  for (MachineBasicBlock &MBB : MF) {
    if (MBB.empty())
      continue;

    // Find Jcc (and optional JMP to RET block).
    MachineInstr *JccMI = nullptr;
    MachineInstr *JmpMI = nullptr;

    MachineInstr &Last = MBB.back();
    if (getInvertedJcc(Last.getOpcode())) {
      // Pattern A: block ends with single Jcc.
      JccMI = &Last;
    } else if (Last.getOpcode() == V6C::JMP && Last.getOperand(0).isMBB()) {
      // Pattern B: block ends with Jcc + JMP.
      auto It = Last.getIterator();
      if (It != MBB.begin()) {
        --It;
        if (getInvertedJcc(It->getOpcode())) {
          JccMI = &*It;
          JmpMI = &Last;
        }
      }
    }

    if (!JccMI || !JccMI->getOperand(0).isMBB())
      continue;

    MachineBasicBlock *JccTarget = JccMI->getOperand(0).getMBB();

    // Layout successor of MBB must be a RET-only block.
    MachineFunction::iterator NextIt = std::next(MBB.getIterator());
    if (NextIt == MF.end())
      continue;
    MachineBasicBlock &RetBB = *NextIt;
    if (!isReturnOnlyBlock(RetBB))
      continue;

    // If JMP present, it must target RetBB (the RET-only layout successor).
    if (JmpMI && JmpMI->getOperand(0).getMBB() != &RetBB)
      continue;

    // RetBB must have exactly one predecessor (MBB).
    if (RetBB.pred_size() != 1)
      continue;

    // JccTarget must be the layout successor of RetBB.
    MachineFunction::iterator AfterRet = std::next(NextIt);
    if (AfterRet == MF.end() || &*AfterRet != JccTarget)
      continue;

    // Don't fire if JccTarget is a JMP-only block — threading handles
    // that case better (redirects Jcc to the final target directly).
    {
      auto FirstNonDbg = JccTarget->getFirstNonDebugInstr();
      if (FirstNonDbg != JccTarget->end() &&
          (FirstNonDbg->getOpcode() == V6C::JMP ||
           FirstNonDbg->getOpcode() == V6C::V6C_TAILJMP)) {
        auto NextInst = std::next(FirstNonDbg);
        while (NextInst != JccTarget->end() && NextInst->isDebugInstr())
          ++NextInst;
        if (NextInst == JccTarget->end())
          continue; // JMP-only block — let threading handle it
      }
    }

    // Map inverted Jcc → Rcc.
    unsigned InvOpc = getInvertedJcc(JccMI->getOpcode());
    unsigned RccOpc = getConditionalReturn(InvOpc);
    if (!RccOpc)
      continue;

    // Replace with Rcc_inv.
    BuildMI(MBB, *JccMI, JccMI->getDebugLoc(), TII.get(RccOpc));

    // Remove old instructions.
    if (JmpMI)
      JmpMI->eraseFromParent();
    JccMI->eraseFromParent();

    // Remove successor edge to RetBB.
    MBB.removeSuccessor(&RetBB);

    // RetBB is now dead.
    DeadBlocks.push_back(&RetBB);
    Changed = true;
  }

  // Remove dead RET blocks.
  for (MachineBasicBlock *Dead : DeadBlocks) {
    while (!Dead->succ_empty())
      Dead->removeSuccessor(Dead->succ_begin());
    Dead->eraseFromParent();
  }

  return Changed;
}

/// Replace Jcc .Lret with Rcc when .Lret contains only RET.
bool V6CBranchOpt::foldConditionalReturns(MachineFunction &MF) {
  bool Changed = false;
  const TargetInstrInfo &TII = *MF.getSubtarget().getInstrInfo();

  for (MachineBasicBlock &MBB : MF) {
    for (auto I = MBB.terminators().begin(), E = MBB.terminators().end();
         I != E; ++I) {
      unsigned RccOpc = getConditionalReturn(I->getOpcode());
      if (!RccOpc)
        continue;
      if (!I->getOperand(0).isMBB())
        continue;

      MachineBasicBlock *Target = I->getOperand(0).getMBB();
      if (!isReturnOnlyBlock(*Target))
        continue;

      // Replace Jcc with Rcc.
      BuildMI(MBB, *I, I->getDebugLoc(), TII.get(RccOpc));

      // Update CFG: remove the edge to the RET block.
      MBB.removeSuccessor(Target);

      I->eraseFromParent();
      Changed = true;
      break; // terminators changed, move to next MBB
    }
  }
  return Changed;
}

/// Remove basic blocks that have no predecessors (dead code).
/// Skip the entry block.
bool V6CBranchOpt::removeDeadBlocks(MachineFunction &MF) {
  bool Changed = false;
  SmallVector<MachineBasicBlock *, 4> DeadBlocks;

  for (MachineBasicBlock &MBB : MF) {
    if (&MBB == &MF.front())
      continue; // Never remove entry block.
    if (MBB.pred_empty()) {
      DeadBlocks.push_back(&MBB);
    }
  }

  for (MachineBasicBlock *MBB : DeadBlocks) {
    // Remove successors to update CFG.
    while (!MBB->succ_empty())
      MBB->removeSuccessor(MBB->succ_begin());
    MBB->eraseFromParent();
    Changed = true;
  }

  return Changed;
}

bool V6CBranchOpt::runOnMachineFunction(MachineFunction &MF) {
  if (DisableBranchOpt)
    return false;

  bool Changed = false;
  Changed |= invertConditionalOverRET(MF);
  Changed |= threadJMPOnlyBlocks(MF);
  Changed |= invertConditionalBranch(MF);
  Changed |= removeRedundantJMP(MF);
  Changed |= foldConditionalReturns(MF);
  Changed |= removeDeadBlocks(MF);
  return Changed;
}

FunctionPass *llvm::createV6CBranchOptPass() {
  return new V6CBranchOpt();
}
