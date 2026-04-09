//===-- V6CZeroTestOpt.cpp - Replace CPI 0 with ORA A --------------------===//
//
// Part of the V6C backend for LLVM.
//
// Post-RA peephole: Replace CPI 0 (8cc) with ORA A (4cc) when testing the
// accumulator against zero. Both set Z and S flags identically for zero-test.
// CPI also sets CY=0, while ORA A sets CY=0, so flags are compatible.
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

#define DEBUG_TYPE "v6c-zero-test-opt"

static cl::opt<bool> DisableZeroTestOpt(
    "v6c-disable-zero-test-opt",
    cl::desc("Disable V6C CPI 0 -> ORA A optimization"),
    cl::init(false), cl::Hidden);

namespace {

class V6CZeroTestOpt : public MachineFunctionPass {
public:
  static char ID;
  V6CZeroTestOpt() : MachineFunctionPass(ID) {}

  StringRef getPassName() const override {
    return "V6C Zero Test Optimization";
  }

  bool runOnMachineFunction(MachineFunction &MF) override;
};

} // end anonymous namespace

char V6CZeroTestOpt::ID = 0;

bool V6CZeroTestOpt::runOnMachineFunction(MachineFunction &MF) {
  if (DisableZeroTestOpt)
    return false;

  const TargetInstrInfo &TII = *MF.getSubtarget().getInstrInfo();
  bool Changed = false;

  for (MachineBasicBlock &MBB : MF) {
    for (MachineInstr &MI : llvm::make_early_inc_range(MBB)) {
      // Look for CPI with immediate operand == 0.
      if (MI.getOpcode() != V6C::CPI)
        continue;

      // CPI has operands: (Acc:$lhs, imm8:$imm)
      // Operand 0 is $lhs (Acc register), operand 1 is the immediate.
      const MachineOperand &ImmOp = MI.getOperand(1);
      if (!ImmOp.isImm() || ImmOp.getImm() != 0)
        continue;

      // Replace CPI 0 with ORA A (which is: A = A | A, sets Z/S flags).
      DebugLoc DL = MI.getDebugLoc();
      BuildMI(MBB, MI, DL, TII.get(V6C::ORAr), V6C::A)
          .addReg(V6C::A)
          .addReg(V6C::A);
      MI.eraseFromParent();
      Changed = true;
    }
  }

  return Changed;
}

FunctionPass *llvm::createV6CZeroTestOptPass() {
  return new V6CZeroTestOpt();
}
