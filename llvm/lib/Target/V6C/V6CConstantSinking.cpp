//===-- V6CConstantSinking.cpp - Pre-RA Constant Sinking -----------------===//
//
// Part of the V6C backend for LLVM.
//
// Pre-RA pass: Sink constant materializations (LXI rp, imm / MVI r, imm)
// past conditional branches when the constant is used only in successor
// blocks.  This prevents register pressure from premature constant
// hoisting — RA sees shorter live ranges and avoids eviction cascades.
//
// After RA, O36 (branch-implied value propagation) eliminates the cloned
// constant on the branch-proven path (e.g., LXI HL,0 after a zero-test).
//
//===----------------------------------------------------------------------===//

#include "V6C.h"
#include "MCTargetDesc/V6CMCTargetDesc.h"
#include "llvm/ADT/PostOrderIterator.h"
#include "llvm/CodeGen/MachineFunctionPass.h"
#include "llvm/CodeGen/MachineInstrBuilder.h"
#include "llvm/CodeGen/MachineRegisterInfo.h"
#include "llvm/CodeGen/TargetInstrInfo.h"
#include "llvm/Support/CommandLine.h"

using namespace llvm;

#define DEBUG_TYPE "v6c-constant-sinking"

static cl::opt<bool> DisableConstantSinking(
    "v6c-disable-constant-sinking",
    cl::desc("Disable V6C pre-RA constant sinking"),
    cl::init(false), cl::Hidden);

namespace {

class V6CConstantSinking : public MachineFunctionPass {
public:
  static char ID;
  V6CConstantSinking() : MachineFunctionPass(ID) {}

  StringRef getPassName() const override {
    return "V6C Pre-RA Constant Sinking";
  }

  bool runOnMachineFunction(MachineFunction &MF) override;
};

} // anonymous namespace

char V6CConstantSinking::ID = 0;

/// Return true if Opc is a constant materialization we want to sink.
static bool isConstantMat(unsigned Opc) {
  return Opc == V6C::LXI || Opc == V6C::MVIr;
}

bool V6CConstantSinking::runOnMachineFunction(MachineFunction &MF) {
  if (DisableConstantSinking)
    return false;

  MachineRegisterInfo &MRI = MF.getRegInfo();
  const TargetInstrInfo &TII = *MF.getSubtarget().getInstrInfo();
  bool Changed = false;

  // RPO iteration: dominators before successors.
  ReversePostOrderTraversal<MachineFunction *> RPOT(&MF);

  for (MachineBasicBlock *MBB : RPOT) {
    // Only interesting if the block has a conditional branch (≥2 successors).
    if (MBB->succ_size() < 2)
      continue;

    // Build successor set for fast lookup.
    SmallPtrSet<MachineBasicBlock *, 4> Succs(MBB->succ_begin(),
                                               MBB->succ_end());

    // Collect sinkable instructions (iterate forward, decide, then mutate).
    SmallVector<MachineInstr *, 4> ToSink;

    for (MachineInstr &MI : *MBB) {
      if (!isConstantMat(MI.getOpcode()))
        continue;

      Register DstReg = MI.getOperand(0).getReg();
      if (!DstReg.isVirtual())
        continue;

      // Check: ALL uses must be in direct successor blocks, either as
      // non-PHI instructions or PHI inputs with incoming edge from MBB.
      bool CanSink = true;
      bool HasUse = false;
      for (MachineInstr &UseMI : MRI.use_nodbg_instructions(DstReg)) {
        HasUse = true;
        MachineBasicBlock *UseBB = UseMI.getParent();

        if (UseBB == MBB || !Succs.count(UseBB)) {
          CanSink = false;
          break;
        }
        // For PHI uses, verify the operand comes from MBB.
        if (UseMI.isPHI()) {
          bool FromMBB = false;
          for (unsigned i = 1, e = UseMI.getNumOperands(); i < e; i += 2) {
            if (UseMI.getOperand(i).getReg() == DstReg &&
                UseMI.getOperand(i + 1).getMBB() == MBB) {
              FromMBB = true;
              break;
            }
          }
          if (!FromMBB) {
            CanSink = false;
            break;
          }
        }
      }

      if (CanSink && HasUse)
        ToSink.push_back(&MI);
    }

    // Sink each collected instruction.
    for (MachineInstr *MI : ToSink) {
      Register DstReg = MI->getOperand(0).getReg();
      const TargetRegisterClass *RC = MRI.getRegClass(DstReg);
      unsigned Opc = MI->getOpcode();
      const MachineOperand &ImmOp = MI->getOperand(1);

      // Classify uses by successor block, distinguishing PHI vs non-PHI.
      struct SuccUses {
        SmallVector<MachineOperand *, 4> Ops;
        bool HasPhi = false;
        bool HasNonPhi = false;
      };
      DenseMap<MachineBasicBlock *, SuccUses> UsesByBlock;

      for (MachineOperand &MO : MRI.use_nodbg_operands(DstReg)) {
        MachineInstr *UseMI = MO.getParent();
        MachineBasicBlock *UseBB = UseMI->getParent();
        auto &SU = UsesByBlock[UseBB];
        SU.Ops.push_back(&MO);
        if (UseMI->isPHI())
          SU.HasPhi = true;
        else
          SU.HasNonPhi = true;
      }

      // Helper: add the immediate operand to a BuildMI.
      auto addImmOperand = [&](MachineInstrBuilder &MIB) {
        if (ImmOp.isImm())
          MIB.addImm(ImmOp.getImm());
        else if (ImmOp.isGlobal())
          MIB.addGlobalAddress(ImmOp.getGlobal(), ImmOp.getOffset(),
                               ImmOp.getTargetFlags());
        else if (ImmOp.isCImm())
          MIB.addCImm(ImmOp.getCImm());
      };

      for (auto &[SuccMBB, SU] : UsesByBlock) {
        if (SU.HasPhi && !SU.HasNonPhi) {
          // PHI-only uses: manually split MBB→SuccMBB edge.
          // Create a new block between MBB and SuccMBB.
          MachineBasicBlock *NewMBB = MF.CreateMachineBasicBlock();
          MF.insert(SuccMBB->getIterator(), NewMBB);

          // CFG: replace MBB→SuccMBB with MBB→NewMBB→SuccMBB.
          MBB->replaceSuccessor(SuccMBB, NewMBB);
          NewMBB->addSuccessor(SuccMBB);

          // Update terminator MBB references in MBB.
          for (MachineInstr &Term : MBB->terminators()) {
            for (MachineOperand &MO : Term.operands()) {
              if (MO.isMBB() && MO.getMBB() == SuccMBB)
                MO.setMBB(NewMBB);
            }
          }

          // Fix PHIs in SuccMBB: incoming MBB → NewMBB.
          SuccMBB->replacePhiUsesWith(MBB, NewMBB);

          // Place the constant materialization in NewMBB.
          Register NewReg = MRI.createVirtualRegister(RC);
          auto MIB = BuildMI(*NewMBB, NewMBB->end(), MI->getDebugLoc(),
                             TII.get(Opc), NewReg);
          addImmOperand(MIB);

          for (MachineOperand *MO : SU.Ops)
            MO->setReg(NewReg);

        } else if (!SU.HasPhi) {
          // Non-PHI uses only: clone into successor after PHIs.
          Register NewReg = MRI.createVirtualRegister(RC);
          auto InsertPt = SuccMBB->getFirstNonPHI();
          auto MIB = BuildMI(*SuccMBB, InsertPt, MI->getDebugLoc(),
                             TII.get(Opc), NewReg);
          addImmOperand(MIB);

          for (MachineOperand *MO : SU.Ops)
            MO->setReg(NewReg);
        }
        // Mixed PHI + non-PHI in same successor: skip (unlikely for constants).
      }

      // Erase the original if all uses were rewritten.
      if (MRI.use_nodbg_empty(DstReg)) {
        MI->eraseFromParent();
        Changed = true;
      }
    }
  }

  return Changed;
}

namespace llvm {

FunctionPass *createV6CConstantSinkingPass() {
  return new V6CConstantSinking();
}

} // namespace llvm
