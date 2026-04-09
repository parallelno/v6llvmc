//===-- V6CLoadStoreOpt.cpp - V6C Load/Store Optimizations ----------------===//
//
// Part of the V6C backend for LLVM.
//
// Post-RA pass for load/store optimizations:
//
// 1. Adjacent 8-bit loads from consecutive addresses via (HL) that feed into
//    a register pair can be recognized and left as-is efficiently (the
//    INX HL sequence is already optimal). But if we see:
//      LXI HL, addr; MOV r, M  followed by  LXI HL, addr+1; MOV r2, M
//    Merge into: LXI HL, addr; MOV r, M; INX HL; MOV r2, M
//    Saving one LXI (3 bytes, 12cc).
//
// 2. Adjacent stores: Same pattern for stores.
//      LXI HL, addr; MOV M, r  followed by  LXI HL, addr+1; MOV M, r2
//    Merge into: LXI HL, addr; MOV M, r; INX HL; MOV M, r2
//
// 3. Dead LXI elimination: If HL is loaded (LXI HL, X) and then
//    immediately overwritten (another LXI HL, Y) without use, remove the
//    first LXI.
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

#define DEBUG_TYPE "v6c-loadstore-opt"

static cl::opt<bool> DisableLoadStoreOpt(
    "v6c-disable-loadstore-opt",
    cl::desc("Disable V6C load/store merge optimizations"),
    cl::init(false), cl::Hidden);

namespace {

class V6CLoadStoreOpt : public MachineFunctionPass {
public:
  static char ID;
  V6CLoadStoreOpt() : MachineFunctionPass(ID) {}

  StringRef getPassName() const override {
    return "V6C Load/Store Optimization";
  }

  bool runOnMachineFunction(MachineFunction &MF) override;

private:
  bool mergeAdjacentAccess(MachineBasicBlock &MBB);
  bool eliminateDeadLXI(MachineBasicBlock &MBB);

  /// Check if MI is LXI HL, imm and return the immediate value.
  static bool isLXI_HL(const MachineInstr &MI, int64_t &Imm);

  /// Check if MI reads from M (uses HL implicitly).
  static bool isLoadViaM(const MachineInstr &MI);

  /// Check if MI writes to M (uses HL implicitly).
  static bool isStoreViaM(const MachineInstr &MI);

  /// Check if MI defines or clobbers any part of HL.
  static bool definesHL(const MachineInstr &MI);

  /// Check if MI uses any part of HL (aside from implicit use).
  static bool usesHL(const MachineInstr &MI);
};

} // end anonymous namespace

char V6CLoadStoreOpt::ID = 0;

bool V6CLoadStoreOpt::isLXI_HL(const MachineInstr &MI, int64_t &Imm) {
  if (MI.getOpcode() != V6C::LXI)
    return false;
  if (MI.getOperand(0).getReg() != V6C::HL)
    return false;
  if (!MI.getOperand(1).isImm())
    return false;
  Imm = MI.getOperand(1).getImm();
  return true;
}

bool V6CLoadStoreOpt::isLoadViaM(const MachineInstr &MI) {
  unsigned Opc = MI.getOpcode();
  return Opc == V6C::MOVrM || Opc == V6C::ADDM || Opc == V6C::ADCM ||
         Opc == V6C::SUBM || Opc == V6C::SBBM || Opc == V6C::ANAM ||
         Opc == V6C::XRAM || Opc == V6C::ORAM || Opc == V6C::CMPM;
}

bool V6CLoadStoreOpt::isStoreViaM(const MachineInstr &MI) {
  return MI.getOpcode() == V6C::MOVMr || MI.getOpcode() == V6C::MVIM;
}

bool V6CLoadStoreOpt::definesHL(const MachineInstr &MI) {
  for (const MachineOperand &MO : MI.operands()) {
    if (!MO.isReg() || !MO.isDef())
      continue;
    Register Reg = MO.getReg();
    if (Reg == V6C::HL || Reg == V6C::H || Reg == V6C::L)
      return true;
  }
  // Also check implicit defs.
  for (const MachineOperand &MO : MI.implicit_operands()) {
    if (!MO.isReg() || !MO.isDef())
      continue;
    Register Reg = MO.getReg();
    if (Reg == V6C::HL || Reg == V6C::H || Reg == V6C::L)
      return true;
  }
  return false;
}

bool V6CLoadStoreOpt::usesHL(const MachineInstr &MI) {
  for (const MachineOperand &MO : MI.operands()) {
    if (!MO.isReg() || !MO.isUse())
      continue;
    Register Reg = MO.getReg();
    if (Reg == V6C::HL || Reg == V6C::H || Reg == V6C::L)
      return true;
  }
  return false;
}

/// Merge patterns:
///   LXI HL, addr;  MOV r, M    (or MOV M, r)
///   LXI HL, addr+1; MOV r2, M  (or MOV M, r2)
/// Into:
///   LXI HL, addr; MOV r, M; INX HL; MOV r2, M
bool V6CLoadStoreOpt::mergeAdjacentAccess(MachineBasicBlock &MBB) {
  bool Changed = false;
  const TargetInstrInfo &TII = *MBB.getParent()->getSubtarget().getInstrInfo();

  for (auto I = MBB.begin(), E = MBB.end(); I != E; ) {
    // Look for: LXI HL, addr
    int64_t Addr1;
    if (!isLXI_HL(*I, Addr1)) {
      ++I;
      continue;
    }

    auto LXI1 = I;
    auto Access1 = std::next(I);
    if (Access1 == E) {
      ++I;
      continue;
    }

    // Next must be a load or store via M.
    bool IsLoad = isLoadViaM(*Access1);
    bool IsStore = isStoreViaM(*Access1);
    if (!IsLoad && !IsStore) {
      ++I;
      continue;
    }

    auto LXI2 = std::next(Access1);
    if (LXI2 == E) {
      ++I;
      continue;
    }

    int64_t Addr2;
    if (!isLXI_HL(*LXI2, Addr2)) {
      ++I;
      continue;
    }

    // Addresses must be consecutive.
    if (Addr2 != Addr1 + 1) {
      ++I;
      continue;
    }

    auto Access2 = std::next(LXI2);
    if (Access2 == E) {
      ++I;
      continue;
    }

    // Second access must be the same type (load or store via M).
    if (IsLoad && !isLoadViaM(*Access2)) {
      ++I;
      continue;
    }
    if (IsStore && !isStoreViaM(*Access2)) {
      ++I;
      continue;
    }

    // Merge: replace LXI2 with INX HL.
    BuildMI(MBB, *LXI2, LXI2->getDebugLoc(), TII.get(V6C::INX), V6C::HL)
        .addReg(V6C::HL);
    LXI2->eraseFromParent();

    Changed = true;
    // Advance past the merged sequence.
    I = std::next(Access2);
  }

  return Changed;
}

/// Remove LXI HL, X when HL is immediately overwritten without being used.
bool V6CLoadStoreOpt::eliminateDeadLXI(MachineBasicBlock &MBB) {
  bool Changed = false;

  for (auto I = MBB.begin(), E = MBB.end(); I != E; ) {
    int64_t Imm;
    if (!isLXI_HL(*I, Imm)) {
      ++I;
      continue;
    }

    // Look ahead: skip instructions that don't touch HL.
    auto Next = std::next(I);
    bool Dead = false;
    while (Next != E) {
      if (usesHL(*Next))
        break; // HL is used — not dead.
      if (definesHL(*Next)) {
        Dead = true; // HL is overwritten without being used.
        break;
      }
      ++Next;
    }

    if (Dead) {
      auto ToErase = I;
      ++I;
      ToErase->eraseFromParent();
      Changed = true;
    } else {
      ++I;
    }
  }

  return Changed;
}

bool V6CLoadStoreOpt::runOnMachineFunction(MachineFunction &MF) {
  if (DisableLoadStoreOpt)
    return false;

  bool Changed = false;
  for (MachineBasicBlock &MBB : MF) {
    Changed |= mergeAdjacentAccess(MBB);
    Changed |= eliminateDeadLXI(MBB);
  }
  return Changed;
}

FunctionPass *llvm::createV6CLoadStoreOptPass() {
  return new V6CLoadStoreOpt();
}
