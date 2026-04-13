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

bool V6CPeephole::runOnMachineFunction(MachineFunction &MF) {
  if (DisablePeephole)
    return false;

  bool Changed = false;
  for (MachineBasicBlock &MBB : MF) {
    Changed |= eliminateSelfMov(MBB);
    Changed |= eliminateRedundantMov(MBB);
    Changed |= foldCounterBranch(MBB);
    Changed |= eliminateTailCall(MBB);
  }
  return Changed;
}

FunctionPass *llvm::createV6CPeepholePass() {
  return new V6CPeephole();
}
