//===-- V6CBranchOpt.cpp - V6C Branch Optimizations ----------------------===//
//
// Part of the V6C backend for LLVM.
//
// Post-RA pass for branch optimizations:
//
// 1. Redundant JMP elimination: JMP to the immediately following block
//    (layout successor) is removed — the fall-through is free.
//
// 2. Conditional branch inversion: if a Jcc jumps over a JMP, invert the
//    condition and remove the JMP.
//    Example:  JZ .Ltmp1 / JMP .Ltmp2 / .Ltmp1:
//           →  JNZ .Ltmp2 / .Ltmp1:
//
// 3. Dead block removal: blocks with no predecessors (after other opts)
//    are removed.
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
  bool removeRedundantJMP(MachineFunction &MF);
  bool invertConditionalBranch(MachineFunction &MF);
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
    if (Last.getOpcode() != V6C::JMP)
      continue;

    --LastI; // Points to second-to-last instruction.
    MachineInstr &Prev = *LastI;
    unsigned InvOpc = getInvertedJcc(Prev.getOpcode());
    if (!InvOpc)
      continue;

    // The Jcc target must be the layout successor (fall-through after the JMP).
    MachineBasicBlock *JccTarget = Prev.getOperand(0).getMBB();
    MachineFunction::iterator NextBB = std::next(MBB.getIterator());
    if (NextBB == MF.end() || &*NextBB != JccTarget)
      continue;

    // Transform: invert the Jcc to jump to the JMP's target, remove JMP.
    MachineBasicBlock *JmpTarget = Last.getOperand(0).getMBB();
    const TargetInstrInfo &TII = *MF.getSubtarget().getInstrInfo();

    BuildMI(MBB, Prev, Prev.getDebugLoc(), TII.get(InvOpc))
        .addMBB(JmpTarget);

    // Update CFG: MBB now branches to JmpTarget and falls through to JccTarget.
    // The old successors are still correct since we flipped the condition.
    Last.eraseFromParent();
    Prev.eraseFromParent();
    Changed = true;
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
  Changed |= invertConditionalBranch(MF);
  Changed |= removeRedundantJMP(MF);
  Changed |= removeDeadBlocks(MF);
  return Changed;
}

FunctionPass *llvm::createV6CBranchOptPass() {
  return new V6CBranchOpt();
}
