//===-- V6CXchgOpt.cpp - Replace MOV pairs with XCHG --------------------===//
//
// Part of the V6C backend for LLVM.
//
// Post-RA peephole: Detect sequences of MOVs that transfer DE↔HL and replace
// them with the much cheaper XCHG (4cc vs 16cc for two MOVs).
//
// Patterns detected:
//   MOV D, H; MOV E, L  → XCHG  (HL → DE, but also swaps DE → HL)
//   MOV H, D; MOV L, E  → XCHG  (DE → HL, but also swaps HL → DE)
//   MOV D, H; MOV E, L; MOV H, X; MOV L, Y → Only first pair to XCHG
//     if DE was dead before the sequence.
//
//===----------------------------------------------------------------------===//

#include "V6C.h"
#include "MCTargetDesc/V6CMCTargetDesc.h"
#include "llvm/CodeGen/MachineFunctionPass.h"
#include "llvm/CodeGen/MachineInstrBuilder.h"
#include "llvm/CodeGen/MachineRegisterInfo.h"
#include "llvm/CodeGen/TargetInstrInfo.h"
#include "llvm/CodeGen/TargetSubtargetInfo.h"
#include "llvm/Support/CommandLine.h"

using namespace llvm;

#define DEBUG_TYPE "v6c-xchg-opt"

static cl::opt<bool> DisableXchgOpt(
    "v6c-disable-xchg-opt",
    cl::desc("Disable V6C DE<->HL XCHG optimization"),
    cl::init(false), cl::Hidden);

namespace {

class V6CXchgOpt : public MachineFunctionPass {
public:
  static char ID;
  V6CXchgOpt() : MachineFunctionPass(ID) {}

  StringRef getPassName() const override {
    return "V6C XCHG Optimization";
  }

  bool runOnMachineFunction(MachineFunction &MF) override;

private:
  bool tryXchg(MachineBasicBlock &MBB, MachineBasicBlock::iterator I);
};

} // end anonymous namespace

char V6CXchgOpt::ID = 0;

/// Check if MI is MOV rd, rs where rd and rs are the specified registers.
static bool isMovReg(const MachineInstr &MI, unsigned Dst, unsigned Src) {
  return MI.getOpcode() == V6C::MOVrr &&
         MI.getOperand(0).getReg() == Dst &&
         MI.getOperand(1).getReg() == Src;
}

/// Check if a physical register (or any alias) is defined before iterator I
/// in the given MBB — either as a livein or by a preceding instruction.
static bool isRegLiveBefore(MachineBasicBlock &MBB,
                            MachineBasicBlock::iterator I,
                            unsigned Reg,
                            const TargetRegisterInfo *TRI) {
  for (MCRegAliasIterator AI(Reg, TRI, /*IncludeSelf=*/true); AI.isValid();
       ++AI) {
    if (MBB.isLiveIn(*AI))
      return true;
  }
  for (auto MI = MBB.begin(); MI != I; ++MI) {
    for (const MachineOperand &MO : MI->operands()) {
      if (MO.isReg() && MO.isDef() && TRI->regsOverlap(MO.getReg(), Reg))
        return true;
    }
  }
  return false;
}

/// Mark the implicit-use operand of XCHG for `Reg` as `undef` when it
/// wasn't proven live before the swap. This is a static annotation only —
/// it tells the MIR verifier we knowingly read a possibly-undefined value
/// that goes into a register proved dead after the swap. Codegen output
/// is unchanged.
static void markUndefIfNotLive(MachineInstr *XchgMI, MachineBasicBlock &MBB,
                               unsigned Reg, const TargetRegisterInfo *TRI) {
  // Scan up to (but not including) XCHG itself — its own implicit-def of Reg
  // must not be counted as a live definition of Reg before the swap.
  if (isRegLiveBefore(MBB, XchgMI->getIterator(), Reg, TRI))
    return;
  if (MachineOperand *MO = XchgMI->findRegisterUseOperand(Reg, /*isKill=*/false))
    MO->setIsUndef(true);
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

bool V6CXchgOpt::tryXchg(MachineBasicBlock &MBB,
                           MachineBasicBlock::iterator I) {
  MachineInstr &First = *I;
  auto Next = std::next(I);
  if (Next == MBB.end())
    return false;
  MachineInstr &Second = *Next;

  const TargetInstrInfo &TII = *MBB.getParent()->getSubtarget().getInstrInfo();
  const TargetRegisterInfo *TRI =
      MBB.getParent()->getSubtarget().getRegisterInfo();

  // XCHG swaps DE↔HL. Both pairs must be live (defined) before the swap.
  // If the "other" pair isn't live, XCHG would read an undefined register.

  // O33: dropped isRegLiveBefore() — if HL/DE is dead after, the swap's
  // side-effect into the other pair is harmless even when undefined.
  // Pattern 1: MOV D, H; MOV E, L → XCHG  (copies HL→DE, but also DE→HL)
  if (isMovReg(First, V6C::D, V6C::H) && isMovReg(Second, V6C::E, V6C::L)) {
    if (!isRegDeadAfter(MBB, Next, V6C::HL, TRI))
      return false; // HL is live after → XCHG would corrupt it
    MachineInstr *XchgMI =
        BuildMI(MBB, First, First.getDebugLoc(), TII.get(V6C::XCHG));
    // DE is the "other" pair: its value is unobserved post-swap (HL is dead).
    // If DE wasn't defined before, annotate the implicit use as undef so
    // -verify-machineinstrs is satisfied.
    markUndefIfNotLive(XchgMI, MBB, V6C::DE, TRI);
    First.eraseFromParent();
    Second.eraseFromParent();
    return true;
  }

  // Pattern 2: MOV H, D; MOV L, E → XCHG  (copies DE→HL, but also HL→DE)
  if (isMovReg(First, V6C::H, V6C::D) && isMovReg(Second, V6C::L, V6C::E)) {
    if (!isRegDeadAfter(MBB, Next, V6C::DE, TRI))
      return false; // DE is live after → XCHG would corrupt it
    MachineInstr *XchgMI =
        BuildMI(MBB, First, First.getDebugLoc(), TII.get(V6C::XCHG));
    markUndefIfNotLive(XchgMI, MBB, V6C::HL, TRI);
    First.eraseFromParent();
    Second.eraseFromParent();
    return true;
  }

  // Pattern 3: MOV E, L; MOV D, H → XCHG (reversed order, same as pattern 1)
  if (isMovReg(First, V6C::E, V6C::L) && isMovReg(Second, V6C::D, V6C::H)) {
    if (!isRegDeadAfter(MBB, Next, V6C::HL, TRI))
      return false; // HL is live after → XCHG would corrupt it
    MachineInstr *XchgMI =
        BuildMI(MBB, First, First.getDebugLoc(), TII.get(V6C::XCHG));
    markUndefIfNotLive(XchgMI, MBB, V6C::DE, TRI);
    First.eraseFromParent();
    Second.eraseFromParent();
    return true;
  }

  // Pattern 4: MOV L, E; MOV H, D → XCHG (reversed order, same as pattern 2)
  if (isMovReg(First, V6C::L, V6C::E) && isMovReg(Second, V6C::H, V6C::D)) {
    if (!isRegDeadAfter(MBB, Next, V6C::DE, TRI))
      return false; // DE is live after → XCHG would corrupt it
    MachineInstr *XchgMI =
        BuildMI(MBB, First, First.getDebugLoc(), TII.get(V6C::XCHG));
    markUndefIfNotLive(XchgMI, MBB, V6C::HL, TRI);
    First.eraseFromParent();
    Second.eraseFromParent();
    return true;
  }

  return false;
}

bool V6CXchgOpt::runOnMachineFunction(MachineFunction &MF) {
  if (DisableXchgOpt)
    return false;

  bool Changed = false;

  for (MachineBasicBlock &MBB : MF) {
    for (auto I = MBB.begin(), E = MBB.end(); I != E; ) {
      if (tryXchg(MBB, I)) {
        // tryXchg erased two instructions and inserted XCHG before them.
        // Iterator I is now invalid. Restart from beginning of block
        // (safe since XCHG can't form another pattern).
        I = MBB.begin();
        Changed = true;
      } else {
        ++I;
      }
    }

    // Cancel adjacent XCHG pairs that tryXchg may have created by placing
    // a new XCHG next to an existing one.  XCHG; XCHG = no-op (O44).
    for (auto I = MBB.begin(), E = MBB.end(); I != E; ) {
      if (I->getOpcode() != V6C::XCHG) {
        ++I;
        continue;
      }
      auto J = std::next(I);
      while (J != E && J->isDebugInstr())
        ++J;
      if (J != E && J->getOpcode() == V6C::XCHG) {
        MBB.erase(J);
        I = MBB.erase(I);
        Changed = true;
        continue;
      }
      ++I;
    }
  }

  return Changed;
}

FunctionPass *llvm::createV6CXchgOptPass() {
  return new V6CXchgOpt();
}
