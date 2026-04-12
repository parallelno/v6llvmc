//===-- V6CRedundantFlagElim.cpp - Remove redundant ORA A / ANA A ---------===//
//
// Part of the V6C backend for LLVM.
//
// Post-RA peephole: Remove ORA A (or ANA A) when the Z flag already reflects
// A's value from a preceding ALU instruction.  Both ORA A and ANA A are
// identity operations (A = A | A = A, A = A & A = A) used solely to set
// flags.  If a prior instruction already wrote A AND set FLAGS, the Z flag
// is still valid and the ORA A / ANA A is provably redundant.
//
// Algorithm (per basic block, no inter-BB analysis):
//   ZFlagValid = false
//   for each MI:
//     if MI is ORA A or ANA A and ZFlagValid: erase MI
//     else if MI writes A AND sets FLAGS (ALU op): ZFlagValid = true
//     else if MI writes A without FLAGS: ZFlagValid = false
//     else if MI writes FLAGS without A: ZFlagValid = false
//     else: ZFlagValid unchanged (MOV B,C, INX, DCX, NOP, etc.)
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

#define DEBUG_TYPE "v6c-redundant-flag-elim"

static cl::opt<bool> DisableRedundantFlagElim(
    "v6c-disable-redundant-flag-elim",
    cl::desc("Disable V6C redundant ORA A / ANA A elimination"),
    cl::init(false), cl::Hidden);

namespace {

class V6CRedundantFlagElim : public MachineFunctionPass {
public:
  static char ID;
  V6CRedundantFlagElim() : MachineFunctionPass(ID) {}

  StringRef getPassName() const override {
    return "V6C Redundant Flag-Setting Elimination";
  }

  bool runOnMachineFunction(MachineFunction &MF) override;

private:
  /// Return true if MI is ORA A (identity OR on accumulator).
  static bool isOraA(const MachineInstr &MI) {
    if (MI.getOpcode() != V6C::ORAr)
      return false;
    // ORAr operands: (outs Acc:$dst), (ins Acc:$lhs, GR8:$rs)
    // ORA A means $rs is A.
    return MI.getOperand(2).getReg() == V6C::A;
  }

  /// Return true if MI is ANA A (identity AND on accumulator).
  static bool isAnaA(const MachineInstr &MI) {
    if (MI.getOpcode() != V6C::ANAr)
      return false;
    // ANAr operands: (outs Acc:$dst), (ins Acc:$lhs, GR8:$rs)
    // ANA A means $rs is A.
    return MI.getOperand(2).getReg() == V6C::A;
  }

  /// Return true if MI is an ALU instruction that writes A AND sets FLAGS.
  /// After such an instruction, Z reflects A's value → ZFlagValid = true.
  static bool isAluWritesAAndFlags(const MachineInstr &MI) {
    switch (MI.getOpcode()) {
    // Register-source ALU ops (A = A op r, sets FLAGS)
    case V6C::ADDr:
    case V6C::ADCr:
    case V6C::SUBr:
    case V6C::SBBr:
    case V6C::ANAr:
    case V6C::XRAr:
    case V6C::ORAr:
    // Memory-source ALU ops (A = A op [HL], sets FLAGS)
    case V6C::ADDM:
    case V6C::ADCM:
    case V6C::SUBM:
    case V6C::SBBM:
    case V6C::ANAM:
    case V6C::XRAM:
    case V6C::ORAM:
    // Immediate ALU ops (A = A op imm, sets FLAGS)
    case V6C::ADI:
    case V6C::ACI:
    case V6C::SUI:
    case V6C::SBI:
    case V6C::ANI:
    case V6C::XRI:
    case V6C::ORI:
      return true;

    // INR/DCR with dst=A: writes A and sets FLAGS (except CY, but Z is set)
    case V6C::INRr:
    case V6C::DCRr:
      return MI.getOperand(0).getReg() == V6C::A;

    default:
      return false;
    }
  }

  /// Return true if MI writes A without setting FLAGS.
  /// After such an instruction, A's value changed but Z is stale.
  static bool isWritesANoFlags(const MachineInstr &MI) {
    switch (MI.getOpcode()) {
    // MOV A, r / MOV A, M / MVI A, imm / LDA addr / LDAX rp / POP PSW
    case V6C::MOVrr:
      return MI.getOperand(0).getReg() == V6C::A;
    case V6C::MOVrM:
      return MI.getOperand(0).getReg() == V6C::A;
    case V6C::MVIr:
      return MI.getOperand(0).getReg() == V6C::A;
    case V6C::LDA:
      return true; // Always writes A
    case V6C::LDAX:
      return true; // Always writes A
    default:
      break;
    }

    // POP PSW writes both A and FLAGS, but the Z flag after POP PSW
    // reflects the saved flags, not necessarily A's new value.
    // Conservatively invalidate.
    if (MI.getOpcode() == V6C::POP) {
      Register Reg = MI.getOperand(0).getReg();
      return Reg == V6C::PSW;
    }

    return false;
  }

  /// Return true if MI modifies FLAGS without writing A.
  /// After such an instruction, Z no longer reflects A.
  static bool isWritesFlagsNoA(const MachineInstr &MI) {
    switch (MI.getOpcode()) {
    // INR/DCR on non-A register: sets FLAGS, doesn't touch A
    case V6C::INRr:
    case V6C::DCRr:
      return MI.getOperand(0).getReg() != V6C::A;

    // INR M / DCR M: sets FLAGS, doesn't touch A
    case V6C::INRM:
    case V6C::DCRM:
      return true;

    // DAD: sets CY flag (and on real 8080, only CY — but we model Defs=[FLAGS])
    case V6C::DAD:
      return true;

    // CMP/CMPM/CPI: set FLAGS based on A-operand comparison, don't write A.
    // Z reflects comparison result, not A's own value.
    case V6C::CMPr:
    case V6C::CMPM:
    case V6C::CPI:
      return true;

    // Rotate instructions: modify A and set CY
    // These both write A AND set FLAGS, but only CY — Z is unchanged on 8080.
    // However, our TableGen models them as Defs=[FLAGS], so conservatively
    // treat as FLAGS-modifying.
    case V6C::RLC:
    case V6C::RRC:
    case V6C::RAL:
    case V6C::RAR:
      return true;

    // STC/CMC: only affect CY
    case V6C::STC:
    case V6C::CMC:
      return true;

    default:
      return false;
    }
  }

  /// Return true if MI is a control flow instruction (branch/call/return).
  static bool isControlFlow(const MachineInstr &MI) {
    return MI.isCall() || MI.isReturn() || MI.isBranch();
  }
};

} // end anonymous namespace

char V6CRedundantFlagElim::ID = 0;

bool V6CRedundantFlagElim::runOnMachineFunction(MachineFunction &MF) {
  if (DisableRedundantFlagElim)
    return false;

  bool Changed = false;

  for (MachineBasicBlock &MBB : MF) {
    bool ZFlagValid = false;

    for (MachineInstr &MI : llvm::make_early_inc_range(MBB)) {
      // Check for redundant ORA A / ANA A first.
      if (ZFlagValid && (isOraA(MI) || isAnaA(MI))) {
        MI.eraseFromParent();
        Changed = true;
        continue;
      }

      // Update ZFlagValid based on instruction effects.
      if (isAluWritesAAndFlags(MI)) {
        ZFlagValid = true;
      } else if (isWritesANoFlags(MI) || isWritesFlagsNoA(MI)) {
        ZFlagValid = false;
      } else if (isControlFlow(MI)) {
        ZFlagValid = false;
      }
      // else: instruction doesn't touch A or FLAGS → ZFlagValid unchanged
    }
  }

  return Changed;
}

FunctionPass *llvm::createV6CRedundantFlagElimPass() {
  return new V6CRedundantFlagElim();
}
