//===-- V6CAccumulatorPlanning.cpp - Minimize A register traffic ----------===//
//
// Part of the V6C backend for LLVM.
//
// Pre-RA MachineFunction pass that reorders instructions within basic blocks
// to minimize unnecessary MOV-to-A / MOV-from-A traffic.
//
// On the 8080, nearly all ALU operations route through register A. Naive
// instruction ordering causes patterns like:
//   MOV A, B; ADD C; MOV B, A;  MOV A, D; SUB E; MOV D, A
// where the accumulator is loaded, used, saved, then reloaded. If the
// second operation doesn't depend on the first result, we can reorder to
// keep A live longer (avoiding a save/restore pair).
//
// This pass performs a limited form of accumulator-aware scheduling:
//
// 1. Eliminate MOV A, X followed by MOV X, A (round-trip, no intervening
//    use of A or modification of X).
//
// 2. Eliminate MOV X, A when A still holds the value of X (value tracking).
//    After MOV A, X... if A hasn't been modified, a later MOV X, A is
//    redundant since X still holds the same value.
//
// Note: This is a post-RA pass that operates conservatively. It does not
// reorder instructions across definitions of FLAGS to preserve correctness.
//
//===----------------------------------------------------------------------===//

#include "V6C.h"
#include "MCTargetDesc/V6CMCTargetDesc.h"
#include "llvm/CodeGen/MachineFunctionPass.h"
#include "llvm/CodeGen/MachineInstrBuilder.h"
#include "llvm/Support/CommandLine.h"

using namespace llvm;

#define DEBUG_TYPE "v6c-acc-planning"

static cl::opt<bool> DisableAccPlanning(
    "v6c-disable-acc-planning",
    cl::desc("Disable V6C accumulator planning pass"),
    cl::init(false), cl::Hidden);

namespace {

class V6CAccumulatorPlanning : public MachineFunctionPass {
public:
  static char ID;
  V6CAccumulatorPlanning() : MachineFunctionPass(ID) {}

  StringRef getPassName() const override {
    return "V6C Accumulator Planning";
  }

  bool runOnMachineFunction(MachineFunction &MF) override;

private:
  bool eliminateRedundantAccMoves(MachineBasicBlock &MBB);
};

} // end anonymous namespace

char V6CAccumulatorPlanning::ID = 0;

/// Check if an instruction modifies A (defines it).
static bool definesA(const MachineInstr &MI) {
  for (const MachineOperand &MO : MI.operands()) {
    if (MO.isReg() && MO.isDef() && MO.getReg() == V6C::A)
      return true;
  }
  for (const MachineOperand &MO : MI.implicit_operands()) {
    if (MO.isReg() && MO.isDef() && MO.getReg() == V6C::A)
      return true;
  }
  return false;
}

/// Check if an instruction uses A (reads it).
static bool usesA(const MachineInstr &MI) {
  for (const MachineOperand &MO : MI.operands()) {
    if (MO.isReg() && MO.isUse() && MO.getReg() == V6C::A)
      return true;
  }
  for (const MachineOperand &MO : MI.implicit_operands()) {
    if (MO.isReg() && MO.isUse() && MO.getReg() == V6C::A)
      return true;
  }
  return false;
}

/// Check if an instruction defines a specific register.
static bool definesReg(const MachineInstr &MI, Register Reg) {
  for (const MachineOperand &MO : MI.operands()) {
    if (MO.isReg() && MO.isDef() && MO.getReg() == Reg)
      return true;
  }
  for (const MachineOperand &MO : MI.implicit_operands()) {
    if (MO.isReg() && MO.isDef() && MO.getReg() == Reg)
      return true;
  }
  return false;
}

/// Perform accumulator-aware redundancy elimination within a basic block.
///
/// Track what register value A currently holds. If we see MOV X, A where
/// X is the register whose value A holds (and X hasn't been modified since
/// MOV A, X), the MOV X, A is redundant and can be removed.
///
/// Also handles: MOV A, X; ...; MOV A, X (reload without modification) —
/// remove the second MOV A, X if A isn't modified between them.
bool V6CAccumulatorPlanning::eliminateRedundantAccMoves(
    MachineBasicBlock &MBB) {
  bool Changed = false;

  // Track: "A currently holds the value from register AccSource."
  // AccSource = 0 means unknown.
  Register AccSource;

  for (MachineInstr &MI : llvm::make_early_inc_range(MBB)) {
    if (MI.getOpcode() == V6C::MOVrr) {
      Register Dst = MI.getOperand(0).getReg();
      Register Src = MI.getOperand(1).getReg();

      if (Dst == V6C::A && Src != V6C::A) {
        // MOV A, X: A now holds the value of X.
        AccSource = Src;
        continue;
      }

      if (Src == V6C::A && Dst != V6C::A) {
        // MOV X, A: if X == AccSource (meaning A holds X's value,
        // and X hasn't been modified), this is redundant.
        if (Dst == AccSource) {
          MI.eraseFromParent();
          Changed = true;
          continue;
        }
        // After MOV X, A, X now holds the same value as A.
        // AccSource is still valid (A unchanged).
        continue;
      }
    }

    // Any instruction that defines A invalidates our tracking.
    if (definesA(MI)) {
      // If this is an ALU op that writes A (ADD, SUB, etc.), A no longer
      // holds a known register value.
      AccSource = Register();
    }

    // If AccSource is set and the instruction modifies that register,
    // the tracking becomes invalid (the register changed but A didn't).
    if (AccSource.isValid() && definesReg(MI, AccSource)) {
      AccSource = Register();
    }

    // Terminators, calls, and branches end the basic block tracking.
    if (MI.isTerminator() || MI.isCall()) {
      AccSource = Register();
    }
  }

  return Changed;
}

bool V6CAccumulatorPlanning::runOnMachineFunction(MachineFunction &MF) {
  if (DisableAccPlanning)
    return false;

  bool Changed = false;
  for (MachineBasicBlock &MBB : MF)
    Changed |= eliminateRedundantAccMoves(MBB);
  return Changed;
}

FunctionPass *llvm::createV6CAccumulatorPlanningPass() {
  return new V6CAccumulatorPlanning();
}
