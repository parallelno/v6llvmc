//===-- V6CSpillPatchedReload.cpp - O61 Stage 1 rewrite --------*- C++ -*-===//
//
// Part of the V6C backend for LLVM.
//
// O61 Stage 1: for static-stack-eligible functions, rewrite HL-only
// V6C_SPILL16/V6C_RELOAD16 pairs into a patched LXI HL reload whose
// imm bytes are written by the SHLD spill (self-modifying code).
//
// Stage 1 candidate filter (hard-coded - no cost model):
//   * function has hasStaticStack(),
//   * exactly one V6C_SPILL16 for the FI with src = HL,
//   * one or more V6C_RELOAD16 for the FI, all with dst = HL.
//
// First reload (program order) is the patched site: LXI HL, 0 with a
// pre-instr label .Lo61_N:. The SHLD is retargeted to write that
// label+1 (the LXI's imm field). Remaining reloads become
// LHLD <Sym, MO_PATCH_IMM> and read the same imm bytes.
//
//===---------------------------------------------------------------------===//

#include "V6C.h"
#include "V6CInstrInfo.h"
#include "V6CMachineFunctionInfo.h"
#include "MCTargetDesc/V6CMCTargetDesc.h"

#include "llvm/ADT/DenseMap.h"
#include "llvm/ADT/SmallVector.h"
#include "llvm/CodeGen/MachineFunctionPass.h"
#include "llvm/CodeGen/MachineInstrBuilder.h"
#include "llvm/CodeGen/TargetInstrInfo.h"
#include "llvm/CodeGen/TargetSubtargetInfo.h"
#include "llvm/MC/MCContext.h"
#include "llvm/MC/MCSymbol.h"
#include "llvm/Support/Debug.h"

#define DEBUG_TYPE "v6c-spill-patched-reload"

using namespace llvm;

namespace {

class V6CSpillPatchedReload : public MachineFunctionPass {
public:
  static char ID;
  V6CSpillPatchedReload() : MachineFunctionPass(ID) {}

  StringRef getPassName() const override {
    return "V6C Spill Into Reload Immediate (O61 Stage 1)";
  }

  bool runOnMachineFunction(MachineFunction &MF) override;
};

} // end anonymous namespace

char V6CSpillPatchedReload::ID = 0;

bool V6CSpillPatchedReload::runOnMachineFunction(MachineFunction &MF) {
  if (!getV6CSpillPatchedReloadEnabled())
    return false;

  auto *MFI = MF.getInfo<V6CMachineFunctionInfo>();
  if (!MFI || !MFI->hasStaticStack())
    return false;

  const TargetInstrInfo &TII = *MF.getSubtarget().getInstrInfo();

  // Group spills and reloads by frame index, preserving program order
  // via the per-FI push_back sequence.
  struct PerFI {
    SmallVector<MachineInstr *, 2> Spills;
    SmallVector<MachineInstr *, 4> Reloads;
  };
  DenseMap<int, PerFI> Slots;

  for (auto &MBB : MF) {
    for (auto &MI : MBB) {
      unsigned Opc = MI.getOpcode();
      if (Opc == V6C::V6C_SPILL16)
        Slots[MI.getOperand(1).getIndex()].Spills.push_back(&MI);
      else if (Opc == V6C::V6C_RELOAD16)
        Slots[MI.getOperand(1).getIndex()].Reloads.push_back(&MI);
    }
  }

  bool Changed = false;
  for (auto &KV : Slots) {
    PerFI &E = KV.second;

    // Stage 1 filter.
    if (E.Spills.size() != 1 || E.Reloads.empty())
      continue;
    MachineInstr *Spill = E.Spills.front();
    if (Spill->getOperand(0).getReg() != V6C::HL)
      continue;
    bool AllHL = true;
    for (auto *R : E.Reloads) {
      if (R->getOperand(0).getReg() != V6C::HL) {
        AllHL = false;
        break;
      }
    }
    if (!AllHL)
      continue;

    LLVM_DEBUG(dbgs() << "O61: patching HL spill/reload pair for FI "
                      << KV.first << " (" << E.Reloads.size()
                      << " reloads)\n");

    // Materialise the patched-site label.
    MCSymbol *Sym = MF.getContext().createTempSymbol("Lo61_", /*AlwaysAddSuffix=*/true);

    // Rewrite the spill: SHLD <Sym, MO_PATCH_IMM>.
    {
      MachineBasicBlock *MBB = Spill->getParent();
      DebugLoc DL = Spill->getDebugLoc();
      bool IsKill = Spill->getOperand(0).isKill();
      BuildMI(*MBB, Spill, DL, TII.get(V6C::SHLD))
          .addReg(V6C::HL, getKillRegState(IsKill))
          .addSym(Sym, V6CII::MO_PATCH_IMM);
      Spill->eraseFromParent();
    }

    // First reload = patched site: LXI HL, 0 with pre-instr label.
    MachineInstr *PatchedReload = E.Reloads.front();
    {
      MachineBasicBlock *MBB = PatchedReload->getParent();
      DebugLoc DL = PatchedReload->getDebugLoc();
      MachineInstrBuilder NewLxi =
          BuildMI(*MBB, PatchedReload, DL, TII.get(V6C::LXI))
              .addReg(V6C::HL, RegState::Define)
              .addImm(0);
      // Tag the imm operand so constant-tracking passes treat it as opaque.
      NewLxi->getOperand(1).setTargetFlags(V6CII::MO_PATCH_IMM);
      // Emit `Sym:` immediately before the LXI opcode byte.
      NewLxi->setPreInstrSymbol(MF, Sym);
      PatchedReload->eraseFromParent();
    }

    // Remaining reloads: LHLD <Sym, MO_PATCH_IMM>.
    for (size_t i = 1, n = E.Reloads.size(); i < n; ++i) {
      MachineInstr *R = E.Reloads[i];
      MachineBasicBlock *MBB = R->getParent();
      DebugLoc DL = R->getDebugLoc();
      BuildMI(*MBB, R, DL, TII.get(V6C::LHLD), V6C::HL)
          .addSym(Sym, V6CII::MO_PATCH_IMM);
      R->eraseFromParent();
    }

    Changed = true;
  }

  return Changed;
}

namespace llvm {
FunctionPass *createV6CSpillPatchedReloadPass() {
  return new V6CSpillPatchedReload();
}
} // namespace llvm
