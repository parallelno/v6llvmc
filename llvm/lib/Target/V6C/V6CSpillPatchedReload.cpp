//===-- V6CSpillPatchedReload.cpp - O61 rewrite ----------------*- C++ -*-===//
//
// Part of the V6C backend for LLVM.
//
// O61 (Stage 2): for static-stack-eligible functions, rewrite single-source
// HL V6C_SPILL16 / V6C_RELOAD16 pairs into a patched LXI <DstRP> reload
// whose imm bytes are written by the SHLD spill (self-modifying code).
//
// Stage 2 filter:
//   * function has hasStaticStack(),
//   * exactly one V6C_SPILL16 for the FI with src = HL,
//   * one or more V6C_RELOAD16 for the FI, each with dst in {HL, DE, BC}.
//
// Stage 2 chooser (K <= 1 patched reload per spill):
//   * score each reload as BlockFrequency(bb) * Delta(dst, HL-live-after)
//     using the per-reload cycle-saving table from the O61 design doc;
//   * pick the single reload with the highest score;
//   * rewrite it as `LXI <DstRP>, 0` with a pre-instr label .Lo61_N: and
//     MO_PATCH_IMM on the imm operand;
//   * rewrite the spill as `SHLD <Sym, MO_PATCH_IMM>` (lowers to Sym+1);
//   * rewrite every other reload as the classical reload sequence for its
//     destination register, but reading from <Sym, MO_PATCH_IMM> (Sym+1)
//     instead of the BSS slot.
//
//===---------------------------------------------------------------------===//

#include "V6C.h"
#include "V6CInstrInfo.h"
#include "V6CMachineFunctionInfo.h"
#include "MCTargetDesc/V6CMCTargetDesc.h"

#include "llvm/ADT/DenseMap.h"
#include "llvm/ADT/SmallVector.h"
#include "llvm/CodeGen/MachineBlockFrequencyInfo.h"
#include "llvm/CodeGen/MachineFunctionPass.h"
#include "llvm/CodeGen/MachineInstrBuilder.h"
#include "llvm/CodeGen/TargetInstrInfo.h"
#include "llvm/CodeGen/TargetRegisterInfo.h"
#include "llvm/CodeGen/TargetSubtargetInfo.h"
#include "llvm/MC/MCContext.h"
#include "llvm/MC/MCSymbol.h"
#include "llvm/Support/Debug.h"

#define DEBUG_TYPE "v6c-spill-patched-reload"

using namespace llvm;

namespace {

/// Per-reload cycle saving when the reload is rewritten as a patched
/// `LXI <DstReg>, 0`. Returns 0 for unsupported destinations (Stage 2:
/// HL/DE/BC only; A/r8 is Stage 4 territory).
///
/// Values mirror the O61 design doc "Reloads" table:
/// design/future_plans/O61_spill_in_reload_immediate.md
static int deltaForReload(unsigned DstReg, bool HLLive) {
  switch (DstReg) {
  case V6C::HL: return 8;              // LHLD (20) -> LXI HL (12)
  case V6C::DE: return HLLive ? 16 : 12;
  case V6C::BC: return HLLive ? 52 : 24;
  default:      return 0;              // A, r8 deferred to Stage 4
  }
}

/// Return true if physical register Reg is dead after MI. Scans forward
/// to end of MBB, then checks successor live-ins.
///
/// Mirrors the helper in V6CRegisterInfo.cpp (same name, same semantics).
/// The helper there is a file-local `static`, so we duplicate it here
/// rather than export a shared utility for three uses in two files.
static bool isRegDeadAfterMI(unsigned Reg, const MachineInstr &MI,
                             MachineBasicBlock &MBB,
                             const TargetRegisterInfo *TRI) {
  for (auto I = std::next(MI.getIterator()); I != MBB.end(); ++I) {
    bool usesReg = false, defsReg = false;
    for (const MachineOperand &MO : I->operands()) {
      if (!MO.isReg() || !TRI->regsOverlap(MO.getReg(), Reg))
        continue;
      if (MO.isUse())
        usesReg = true;
      if (MO.isDef())
        defsReg = true;
    }
    if (usesReg)
      return false;
    if (defsReg)
      return true;
  }
  for (MachineBasicBlock *Succ : MBB.successors()) {
    for (MCRegAliasIterator AI(Reg, TRI, /*IncludeSelf=*/true); AI.isValid();
         ++AI) {
      if (Succ->isLiveIn(*AI))
        return false;
    }
  }
  return true;
}

class V6CSpillPatchedReload : public MachineFunctionPass {
public:
  static char ID;
  V6CSpillPatchedReload() : MachineFunctionPass(ID) {}

  StringRef getPassName() const override {
    return "V6C Spill Into Reload Immediate (O61)";
  }

  void getAnalysisUsage(AnalysisUsage &AU) const override {
    AU.addRequired<MachineBlockFrequencyInfo>();
    AU.setPreservesCFG();
    MachineFunctionPass::getAnalysisUsage(AU);
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
  const TargetRegisterInfo *TRI = MF.getSubtarget().getRegisterInfo();
  auto &MBFI = getAnalysis<MachineBlockFrequencyInfo>();

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

    // Stage 2 filter: single HL-source spill, reload dsts in {HL,DE,BC}.
    if (E.Spills.size() != 1 || E.Reloads.empty())
      continue;
    MachineInstr *Spill = E.Spills.front();
    if (Spill->getOperand(0).getReg() != V6C::HL)
      continue;
    bool AllSupported = true;
    for (auto *R : E.Reloads) {
      Register Dst = R->getOperand(0).getReg();
      if (Dst != V6C::HL && Dst != V6C::DE && Dst != V6C::BC) {
        AllSupported = false;
        break;
      }
    }
    if (!AllSupported)
      continue;

    // Chooser: pick the single reload with the highest BFreq * Delta
    // (K <= 1 per spill; Stage 3 will lift this to K <= 2).
    size_t WinnerIdx = 0;
    uint64_t BestScore = 0;
    int BestDelta = 0;
    bool HaveWinner = false;
    for (size_t i = 0, n = E.Reloads.size(); i < n; ++i) {
      MachineInstr *R = E.Reloads[i];
      bool HLLive = !isRegDeadAfterMI(V6C::HL, *R, *R->getParent(), TRI);
      int D = deltaForReload(R->getOperand(0).getReg(), HLLive);
      if (D <= 0)
        continue;
      uint64_t Freq =
          MBFI.getBlockFreq(R->getParent()).getFrequency();
      // Delta <= 52, Freq is normalised; overflow is only theoretical
      // and would still produce a valid ordering among hot blocks.
      uint64_t Score = Freq * (uint64_t)D;
      if (!HaveWinner || Score > BestScore) {
        BestScore = Score;
        BestDelta = D;
        WinnerIdx = i;
        HaveWinner = true;
      }
    }
    if (!HaveWinner || BestDelta == 0)
      continue;

    LLVM_DEBUG(dbgs() << "O61: patching spill/reload pair for FI "
                      << KV.first << " (" << E.Reloads.size()
                      << " reloads, winner idx=" << WinnerIdx
                      << ", delta=" << BestDelta << ")\n");

    // Materialise the patched-site label.
    MCSymbol *Sym =
        MF.getContext().createTempSymbol("Lo61_", /*AlwaysAddSuffix=*/true);

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

    // Winning reload becomes the patched site: LXI <DstRP>, 0 with
    // pre-instr label.
    MachineInstr *PatchedReload = E.Reloads[WinnerIdx];
    {
      MachineBasicBlock *MBB = PatchedReload->getParent();
      DebugLoc DL = PatchedReload->getDebugLoc();
      Register WinnerDst = PatchedReload->getOperand(0).getReg();
      MachineInstrBuilder NewLxi =
          BuildMI(*MBB, PatchedReload, DL, TII.get(V6C::LXI))
              .addReg(WinnerDst, RegState::Define)
              .addImm(0);
      // Tag the imm operand so constant-tracking passes treat it as opaque.
      NewLxi->getOperand(1).setTargetFlags(V6CII::MO_PATCH_IMM);
      // Emit `Sym:` immediately before the LXI opcode byte.
      NewLxi->setPreInstrSymbol(MF, Sym);
      PatchedReload->eraseFromParent();
    }

    // Every other reload: emit the classical reload sequence for its
    // destination register, reading from <Sym, MO_PATCH_IMM> (= Sym+1)
    // instead of the BSS slot. These sequences mirror the static-stack
    // expansion in V6CRegisterInfo::eliminateFrameIndex.
    for (size_t i = 0, n = E.Reloads.size(); i < n; ++i) {
      if (i == WinnerIdx)
        continue;
      MachineInstr *R = E.Reloads[i];
      MachineBasicBlock *MBB = R->getParent();
      DebugLoc DL = R->getDebugLoc();
      Register Dst = R->getOperand(0).getReg();
      bool HLLive = !isRegDeadAfterMI(V6C::HL, *R, *MBB, TRI);

      if (Dst == V6C::HL) {
        // LHLD <Sym, MO_PATCH_IMM>   (20cc, 3B)
        BuildMI(*MBB, R, DL, TII.get(V6C::LHLD), V6C::HL)
            .addSym(Sym, V6CII::MO_PATCH_IMM);
      } else if (Dst == V6C::DE) {
        if (HLLive) {
          // XCHG; LHLD ... ; XCHG  (28cc, 5B)
          BuildMI(*MBB, R, DL, TII.get(V6C::XCHG));
          BuildMI(*MBB, R, DL, TII.get(V6C::LHLD), V6C::HL)
              .addSym(Sym, V6CII::MO_PATCH_IMM);
          BuildMI(*MBB, R, DL, TII.get(V6C::XCHG));
        } else {
          // LHLD ... ; XCHG        (24cc, 4B)
          BuildMI(*MBB, R, DL, TII.get(V6C::LHLD), V6C::HL)
              .addSym(Sym, V6CII::MO_PATCH_IMM);
          BuildMI(*MBB, R, DL, TII.get(V6C::XCHG));
        }
      } else {
        assert(Dst == V6C::BC && "Stage 2 reload dst must be HL/DE/BC");
        if (HLLive) {
          // PUSH HL; LHLD ... ; MOV C,L; MOV B,H; POP HL  (64cc, 7B)
          BuildMI(*MBB, R, DL, TII.get(V6C::PUSH)).addReg(V6C::HL);
          BuildMI(*MBB, R, DL, TII.get(V6C::LHLD), V6C::HL)
              .addSym(Sym, V6CII::MO_PATCH_IMM);
          BuildMI(*MBB, R, DL, TII.get(V6C::MOVrr))
              .addReg(V6C::C, RegState::Define).addReg(V6C::L);
          BuildMI(*MBB, R, DL, TII.get(V6C::MOVrr))
              .addReg(V6C::B, RegState::Define).addReg(V6C::H);
          BuildMI(*MBB, R, DL, TII.get(V6C::POP), V6C::HL);
        } else {
          // LHLD ... ; MOV C,L; MOV B,H  (36cc, 5B)
          BuildMI(*MBB, R, DL, TII.get(V6C::LHLD), V6C::HL)
              .addSym(Sym, V6CII::MO_PATCH_IMM);
          BuildMI(*MBB, R, DL, TII.get(V6C::MOVrr))
              .addReg(V6C::C, RegState::Define).addReg(V6C::L);
          BuildMI(*MBB, R, DL, TII.get(V6C::MOVrr))
              .addReg(V6C::B, RegState::Define).addReg(V6C::H);
        }
      }
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
