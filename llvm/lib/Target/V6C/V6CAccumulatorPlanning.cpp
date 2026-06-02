//===-- V6CAccumulatorPlanning.cpp - Minimize A register traffic ----------===//
//
// Part of the V6C backend for LLVM.
//
// Post-RA MachineFunction pass that previously eliminated redundant
// accumulator (A) moves within a basic block.
//
// As of O92, the redundant-move elimination logic has been folded into the
// unified cross-BB physical-register value-forwarding pass
// (V6CRegValueForwarding), which subsumes this pass's A-specific, intra-block
// behavior with a register-agnostic, cross-block dataflow. This pass is
// retained as a no-op placeholder in the pipeline; it no longer performs any
// transformation.
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
};

} // end anonymous namespace

char V6CAccumulatorPlanning::ID = 0;

bool V6CAccumulatorPlanning::runOnMachineFunction(MachineFunction &MF) {
  // Redundant accumulator-move elimination is now handled by O92
  // (V6CRegValueForwarding). This pass is a no-op placeholder.
  (void)DisableAccPlanning;
  return false;
}

FunctionPass *llvm::createV6CAccumulatorPlanningPass() {
  return new V6CAccumulatorPlanning();
}
