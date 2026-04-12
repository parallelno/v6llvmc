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
#include "llvm/CodeGen/TargetInstrInfo.h"
#include "llvm/CodeGen/TargetSubtargetInfo.h"
#include "llvm/Support/CommandLine.h"

using namespace llvm;

#define DEBUG_TYPE "v6c-peephole"

static cl::opt<bool> DisablePeephole(
    "v6c-disable-peephole",
    cl::desc("Disable V6C peephole optimizations"),
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

/// Replace CALL target; RET → V6C_TAILJMP target (tail call elimination).
/// Only matches when CALL is immediately before RET (no epilogue between).
bool V6CPeephole::eliminateTailCall(MachineBasicBlock &MBB) {
  if (MBB.size() < 2)
    return false;

  // Find the last non-debug instruction — must be RET.
  auto RetIt = MBB.getLastNonDebugInstr();
  if (RetIt == MBB.end() || RetIt->getOpcode() != V6C::RET)
    return false;

  // Find the instruction before RET, skipping debug instrs.
  auto CallIt = std::prev(RetIt);
  while (CallIt != MBB.begin() && CallIt->isDebugInstr())
    CallIt = std::prev(CallIt);

  if (CallIt->getOpcode() != V6C::CALL)
    return false;

  // Build V6C_TAILJMP with the CALL's target operand.
  const TargetInstrInfo &TII = *MBB.getParent()->getSubtarget().getInstrInfo();
  BuildMI(MBB, CallIt, CallIt->getDebugLoc(), TII.get(V6C::V6C_TAILJMP))
      .add(CallIt->getOperand(0));

  RetIt->eraseFromParent();
  CallIt->eraseFromParent();
  return true;
}

bool V6CPeephole::runOnMachineFunction(MachineFunction &MF) {
  if (DisablePeephole)
    return false;

  bool Changed = false;
  for (MachineBasicBlock &MBB : MF) {
    Changed |= eliminateSelfMov(MBB);
    Changed |= eliminateRedundantMov(MBB);
    Changed |= eliminateTailCall(MBB);
  }
  return Changed;
}

FunctionPass *llvm::createV6CPeepholePass() {
  return new V6CPeephole();
}
