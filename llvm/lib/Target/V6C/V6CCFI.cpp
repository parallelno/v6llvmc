//===-- V6CCFI.cpp - Final DWARF call-frame information --------*- C++ -*-===//
//
// Part of the V6C backend for LLVM.
//
//===----------------------------------------------------------------------===//

#include "V6C.h"
#include "V6CFrameLowering.h"
#include "V6CMachineFunctionInfo.h"
#include "MCTargetDesc/V6CMCTargetDesc.h"
#include "llvm/CodeGen/MachineFrameInfo.h"
#include "llvm/CodeGen/MachineFunctionPass.h"
#include "llvm/CodeGen/MachineInstrBuilder.h"
#include "llvm/CodeGen/MachineModuleInfo.h"
#include "llvm/CodeGen/TargetInstrInfo.h"
#include "llvm/CodeGen/TargetRegisterInfo.h"
#include "llvm/CodeGen/TargetSubtargetInfo.h"
#include "llvm/IR/Function.h"
#include "llvm/MC/MCDwarf.h"

#include <optional>

using namespace llvm;

#define DEBUG_TYPE "v6c-cfi"

namespace {

struct CFAState {
  unsigned Reg;
  int64_t Offset;
  bool ReturnAddressAvailable;
};

class V6CCFI : public MachineFunctionPass {
public:
  static char ID;
  V6CCFI() : MachineFunctionPass(ID) {}

  StringRef getPassName() const override {
    return "V6C Final DWARF CFI";
  }

  bool runOnMachineFunction(MachineFunction &MF) override;

  void getAnalysisUsage(AnalysisUsage &AU) const override {
    AU.setPreservesCFG();
    MachineFunctionPass::getAnalysisUsage(AU);
  }

private:
  static MachineInstr *previousReal(MachineInstr &MI);
  static void buildCFI(MachineBasicBlock &MBB,
                       MachineBasicBlock::iterator InsertBefore,
                       const DebugLoc &DL, const MCCFIInstruction &CFI);
};

} // namespace

char V6CCFI::ID = 0;

MachineInstr *V6CCFI::previousReal(MachineInstr &MI) {
  MachineBasicBlock &MBB = *MI.getParent();
  auto I = MI.getIterator();
  while (I != MBB.begin()) {
    --I;
    if (!I->isTransient())
      return &*I;
  }
  return nullptr;
}

void V6CCFI::buildCFI(MachineBasicBlock &MBB,
                      MachineBasicBlock::iterator InsertBefore,
                      const DebugLoc &DL, const MCCFIInstruction &CFI) {
  MachineFunction &MF = *MBB.getParent();
  const TargetInstrInfo &TII = *MF.getSubtarget().getInstrInfo();
  unsigned CFIIndex = MF.addFrameInst(CFI);
  BuildMI(MBB, InsertBefore, DL, TII.get(TargetOpcode::CFI_INSTRUCTION))
      .addCFIIndex(CFIIndex);
}

bool V6CCFI::runOnMachineFunction(MachineFunction &MF) {
  if (!MF.getMMI().hasDebugInfo())
    return false;

  const Function &F = MF.getFunction();
  const TargetRegisterInfo *TRI = MF.getSubtarget().getRegisterInfo();
  const auto *TFI = static_cast<const V6CFrameLowering *>(
      MF.getSubtarget().getFrameLowering());
  const auto *FuncInfo = MF.getInfo<V6CMachineFunctionInfo>();
  const bool UseFP = TFI->hasFP(MF);
  const bool IsUnwindBoundary = F.hasFnAttribute(Attribute::Naked) ||
                                F.hasFnAttribute("interrupt");

  const unsigned DwarfSP = TRI->getDwarfRegNum(V6C::SP, true);
  const unsigned DwarfPC = TRI->getDwarfRegNum(V6C::PC, true);
  const unsigned DwarfBC = TRI->getDwarfRegNum(V6C::BC, true);
  const int64_t BodyCFAOffset =
      UseFP ? FuncInfo->getFrameCFAOffset()
            : 2 + static_cast<int64_t>(MF.getFrameInfo().getStackSize());

  bool IsEntry = true;
  for (MachineBasicBlock &MBB : MF) {
    auto First = MBB.begin();
    DebugLoc DL = First != MBB.end() ? First->getDebugLoc() : DebugLoc();

    CFAState State{DwarfSP, IsEntry ? 2 : BodyCFAOffset, true};
    if (!IsEntry && UseFP)
      State.Reg = DwarfBC;

    buildCFI(MBB, First, DL,
             MCCFIInstruction::cfiDefCfa(nullptr, State.Reg, State.Offset));
    if (IsUnwindBoundary) {
      buildCFI(MBB, First, DL,
               MCCFIInstruction::createUndefined(nullptr, DwarfPC));
      IsEntry = false;
      continue;
    }
    buildCFI(MBB, First, DL,
             MCCFIInstruction::createOffset(nullptr, DwarfPC, -2));

    bool FPActivated = !IsEntry && UseFP;
    std::optional<CFAState> StateBeforeSPRepurpose;

    for (auto I = MBB.begin(); I != MBB.end();) {
      MachineInstr &MI = *I++;
      if (MI.isTransient())
        continue;
      DL = MI.getDebugLoc();

      auto emitAfter = [&](const MCCFIInstruction &CFI) {
        buildCFI(MBB, I, DL, CFI);
      };
      auto setCFAOffset = [&](int64_t Offset) {
        State.Offset = Offset;
        emitAfter(MCCFIInstruction::cfiDefCfaOffset(nullptr, Offset));
      };
      auto setCFA = [&](unsigned Reg, int64_t Offset) {
        State.Reg = Reg;
        State.Offset = Offset;
        emitAfter(MCCFIInstruction::cfiDefCfa(nullptr, Reg, Offset));
      };

      if (MI.getOpcode() == V6C::LXI && MI.getNumOperands() >= 2 &&
          MI.getOperand(0).isReg() && MI.getOperand(0).getReg() == V6C::SP) {
        StateBeforeSPRepurpose = State;
        State.ReturnAddressAvailable = false;
        emitAfter(MCCFIInstruction::createUndefined(nullptr, DwarfPC));
        continue;
      }

      if (!State.ReturnAddressAvailable) {
        if (MI.getOpcode() == V6C::SPHL) {
          MachineInstr *Prev = previousReal(MI);
          if (Prev && Prev->getOpcode() == V6C::XCHG &&
              StateBeforeSPRepurpose) {
            State = *StateBeforeSPRepurpose;
            setCFA(State.Reg, State.Offset);
            emitAfter(MCCFIInstruction::createOffset(nullptr, DwarfPC, -2));
            State.ReturnAddressAvailable = true;
            StateBeforeSPRepurpose.reset();
          }
        }
        continue;
      }

      if (UseFP && !FPActivated && IsEntry &&
          MI.getOpcode() == V6C::PUSH && MI.getNumOperands() != 0 &&
          MI.getOperand(0).isReg() && MI.getOperand(0).getReg() == V6C::BC) {
        if (State.Reg == DwarfSP)
          setCFAOffset(State.Offset + 2);
        emitAfter(MCCFIInstruction::createOffset(nullptr, DwarfBC,
                                                  -State.Offset));
        continue;
      }

      if (UseFP && !FPActivated && IsEntry && MI.getOpcode() == V6C::MOVrr &&
          MI.getNumOperands() >= 2 && MI.getOperand(0).getReg() == V6C::C &&
          MI.getOperand(1).getReg() == V6C::L) {
        MachineInstr *Prev = previousReal(MI);
        if (Prev && Prev->getOpcode() == V6C::MOVrr &&
            Prev->getNumOperands() >= 2 && Prev->getOperand(0).getReg() == V6C::B &&
            Prev->getOperand(1).getReg() == V6C::H) {
          State.Reg = DwarfBC;
          emitAfter(MCCFIInstruction::createDefCfaRegister(nullptr, DwarfBC));
          FPActivated = true;
          continue;
        }
      }

      if (UseFP && FPActivated && MI.getOpcode() == V6C::POP &&
          MI.getNumOperands() != 0 && MI.getOperand(0).isReg() &&
          MI.getOperand(0).getReg() == V6C::BC) {
        setCFA(DwarfSP, 2 + FuncInfo->getPrologueArgSaveSize());
        emitAfter(MCCFIInstruction::createRestore(nullptr, DwarfBC));
        FPActivated = false;
        continue;
      }

      if (MI.getOpcode() == V6C::PUSH) {
        if (State.Reg == DwarfSP)
          setCFAOffset(State.Offset + 2);
        continue;
      }
      if (MI.getOpcode() == V6C::POP) {
        if (State.Reg == DwarfSP)
          setCFAOffset(State.Offset - 2);
        continue;
      }

      if ((MI.getOpcode() == V6C::INX || MI.getOpcode() == V6C::DCX) &&
          (MI.readsRegister(V6C::SP, TRI) ||
           MI.definesRegister(V6C::SP, TRI))) {
        if (State.Reg == DwarfSP)
          setCFAOffset(State.Offset + (MI.getOpcode() == V6C::DCX ? 1 : -1));
        continue;
      }

      if (MI.getOpcode() != V6C::SPHL || State.Reg != DwarfSP)
        continue;

      MachineInstr *Dad = previousReal(MI);
      MachineInstr *Lxi = Dad ? previousReal(*Dad) : nullptr;
      if (Dad && Dad->getOpcode() == V6C::DAD &&
          Dad->readsRegister(V6C::SP, TRI) && Lxi &&
          Lxi->getOpcode() == V6C::LXI && Lxi->getNumOperands() >= 2 &&
          Lxi->getOperand(0).isReg() && Lxi->getOperand(0).getReg() == V6C::HL &&
          Lxi->getOperand(1).isImm()) {
        setCFAOffset(State.Offset - Lxi->getOperand(1).getImm());
      } else {
        State.ReturnAddressAvailable = false;
        emitAfter(MCCFIInstruction::createUndefined(nullptr, DwarfPC));
      }
    }

    IsEntry = false;
  }

  return true;
}

FunctionPass *llvm::createV6CCFIPass() { return new V6CCFI(); }
