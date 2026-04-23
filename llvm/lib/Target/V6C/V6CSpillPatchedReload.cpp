//===-- V6CSpillPatchedReload.cpp - O61 rewrite ----------------*- C++ -*-===//
//
// Part of the V6C backend for LLVM.
//
// O61 (Stage 3): for static-stack-eligible functions, rewrite HL-source
// V6C_SPILL16 / V6C_RELOAD16 groups into patched LXI <DstRP> reloads
// whose imm bytes are written by SHLD spills (self-modifying code).
//
// Stage 3 filter:
//   * function has hasStaticStack(),
//   * one or more V6C_SPILL16 for the FI, every spill with src = HL,
//   * one or more V6C_RELOAD16 for the FI, each with dst in {HL, DE, BC}.
//
// Stage 3 chooser:
//   * K <= 2 patched reloads per single-source spill,
//   * K <= 1 patched reload per multi-source spill,
//   * the 2nd-patch chooser must skip HL-target candidates (the
//     2nd-patch Delta for HL is -12 cc per the O61 design doc),
//   * score each reload as BlockFrequency(bb) * Delta(dst, HL-live-after)
//     using the per-reload cycle-saving table from the O61 design doc;
//   * pick the 1st winner from {HL, DE, BC}; pick the 2nd (if allowed)
//     from {DE, BC} only;
//   * rewrite each winner as `LXI <DstRP>, 0` with a pre-instr label
//     .Lo61_N: and MO_PATCH_IMM on the imm operand;
//   * rewrite every original spill as a sequence of one `SHLD
//     <Syms[i], MO_PATCH_IMM>` per winner (kill flag only on the last);
//   * rewrite every non-winner reload as the classical reload sequence
//     for its destination register, reading from <Syms[0], MO_PATCH_IMM>
//     instead of the BSS slot.
//
//===---------------------------------------------------------------------===//

#include "V6C.h"
#include "V6CInstrInfo.h"
#include "V6CMachineFunctionInfo.h"
#include "MCTargetDesc/V6CMCTargetDesc.h"

#include "llvm/ADT/DenseMap.h"
#include "llvm/ADT/STLExtras.h"
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

/// Score a single reload candidate. Returns 0 if ineligible (dst not in
/// the permitted set, or Delta <= 0), otherwise BlockFrequency * Delta.
/// When AllowHL is false the caller is picking a 2nd patch, in which
/// case HL-target reloads are excluded per the O61 2nd-patch rule
/// (Delta = -12 cc on the 2nd patch: net loss).
static uint64_t scoreReload(const MachineInstr &R, bool AllowHL,
                            const MachineBlockFrequencyInfo &MBFI,
                            const TargetRegisterInfo *TRI) {
  Register Dst = R.getOperand(0).getReg();
  if (Dst == V6C::HL) {
    if (!AllowHL)
      return 0;
  } else if (Dst != V6C::DE && Dst != V6C::BC) {
    // A and r8 are Stage 4 territory.
    return 0;
  }
  MachineBasicBlock *MBB = const_cast<MachineBasicBlock *>(R.getParent());
  bool HLLive = !isRegDeadAfterMI(V6C::HL, R, *MBB, TRI);
  int D = deltaForReload(Dst, HLLive);
  if (D <= 0)
    return 0;
  uint64_t Freq = MBFI.getBlockFreq(MBB).getFrequency();
  // Delta <= 52, Freq is normalised; overflow is only theoretical
  // and would still produce a valid ordering among hot blocks.
  return Freq * (uint64_t)D;
}

/// Return the index in `Reloads` of the best-scoring eligible candidate,
/// or -1 if no candidate is eligible. Candidates in `Excluded` are
/// skipped (used to prevent picking the same reload twice). When
/// AllowHL is false, HL-target reloads are skipped (2nd-patch rule).
/// Ties keep the first candidate (program order) — deterministic.
static int pickBestReload(ArrayRef<MachineInstr *> Reloads,
                          ArrayRef<int> Excluded, bool AllowHL,
                          const MachineBlockFrequencyInfo &MBFI,
                          const TargetRegisterInfo *TRI) {
  int Best = -1;
  uint64_t BestScore = 0;
  for (size_t i = 0, n = Reloads.size(); i < n; ++i) {
    if (llvm::is_contained(Excluded, (int)i))
      continue;
    uint64_t Score = scoreReload(*Reloads[i], AllowHL, MBFI, TRI);
    if (Score == 0)
      continue;
    if (Best < 0 || Score > BestScore) {
      Best = (int)i;
      BestScore = Score;
    }
  }
  return Best;
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

    // Stage 3 filter: >=1 HL-source spill, reload dsts in {HL,DE,BC}.
    if (E.Spills.empty() || E.Reloads.empty())
      continue;
    bool AllHLSources = llvm::all_of(E.Spills, [](MachineInstr *S) {
      return S->getOperand(0).getReg() == V6C::HL;
    });
    if (!AllHLSources)
      continue;
    bool AllSupported =
        llvm::all_of(E.Reloads, [](MachineInstr *R) {
          Register D = R->getOperand(0).getReg();
          return D == V6C::HL || D == V6C::DE || D == V6C::BC;
        });
    if (!AllSupported)
      continue;

    // Chooser: pick up to two reloads. K <= 2 for single-source spills,
    // K <= 1 for multi-source spills. The 2nd pick additionally
    // excludes HL-target reloads (Stage 3 2nd-patch rule).
    SmallVector<int, 2> Winners;
    int W1 = pickBestReload(E.Reloads, /*Excluded=*/{},
                            /*AllowHL=*/true, MBFI, TRI);
    if (W1 < 0)
      continue;
    Winners.push_back(W1);

    if (E.Spills.size() == 1) {
      int Exc[] = {W1};
      int W2 = pickBestReload(E.Reloads, Exc, /*AllowHL=*/false, MBFI, TRI);
      if (W2 >= 0)
        Winners.push_back(W2);
    }

    LLVM_DEBUG(dbgs() << "O61: patching FI " << KV.first << " -- "
                      << E.Spills.size() << " spill(s), "
                      << E.Reloads.size() << " reload(s), K="
                      << Winners.size() << "\n");

    // Materialise one .Lo61_N label per winner.
    SmallVector<MCSymbol *, 2> Syms;
    for (size_t i = 0; i < Winners.size(); ++i)
      Syms.push_back(MF.getContext().createTempSymbol(
          "Lo61_", /*AlwaysAddSuffix=*/true));

    // Rewrite every original spill as a sequence of SHLDs (one per
    // winner). Kill flag goes only on the last emitted SHLD since HL
    // must be live across the preceding stores.
    for (MachineInstr *Spill : E.Spills) {
      MachineBasicBlock *MBB = Spill->getParent();
      DebugLoc DL = Spill->getDebugLoc();
      bool IsKill = Spill->getOperand(0).isKill();
      for (size_t si = 0; si < Syms.size(); ++si) {
        bool Kill = IsKill && (si + 1 == Syms.size());
        BuildMI(*MBB, Spill, DL, TII.get(V6C::SHLD))
            .addReg(V6C::HL, getKillRegState(Kill))
            .addSym(Syms[si], V6CII::MO_PATCH_IMM);
      }
      Spill->eraseFromParent();
    }

    // Each winner reload becomes the patched site: LXI <DstRP>, 0 with
    // a pre-instr label and MO_PATCH_IMM on the imm operand.
    for (size_t wi = 0; wi < Winners.size(); ++wi) {
      MachineInstr *PR = E.Reloads[Winners[wi]];
      MachineBasicBlock *MBB = PR->getParent();
      DebugLoc DL = PR->getDebugLoc();
      Register WinnerDst = PR->getOperand(0).getReg();
      MachineInstrBuilder NewLxi =
          BuildMI(*MBB, PR, DL, TII.get(V6C::LXI))
              .addReg(WinnerDst, RegState::Define)
              .addImm(0);
      NewLxi->getOperand(1).setTargetFlags(V6CII::MO_PATCH_IMM);
      NewLxi->setPreInstrSymbol(MF, Syms[wi]);
      PR->eraseFromParent();
    }

    // Every non-winner reload becomes the classical reload sequence for
    // its destination register, reading from Syms[0]+1 (the first
    // patched site's imm bytes serve as the shared slot storage). These
    // sequences mirror the static-stack expansion in
    // V6CRegisterInfo::eliminateFrameIndex.
    auto isWinner = [&](size_t i) {
      return llvm::is_contained(Winners, (int)i);
    };
    for (size_t i = 0, n = E.Reloads.size(); i < n; ++i) {
      if (isWinner(i))
        continue;
      MachineInstr *R = E.Reloads[i];
      MachineBasicBlock *MBB = R->getParent();
      DebugLoc DL = R->getDebugLoc();
      Register Dst = R->getOperand(0).getReg();
      bool HLLive = !isRegDeadAfterMI(V6C::HL, *R, *MBB, TRI);

      if (Dst == V6C::HL) {
        // LHLD <Syms[0], MO_PATCH_IMM>   (20cc, 3B)
        BuildMI(*MBB, R, DL, TII.get(V6C::LHLD), V6C::HL)
            .addSym(Syms[0], V6CII::MO_PATCH_IMM);
      } else if (Dst == V6C::DE) {
        if (HLLive) {
          // XCHG; LHLD ... ; XCHG  (28cc, 5B)
          BuildMI(*MBB, R, DL, TII.get(V6C::XCHG));
          BuildMI(*MBB, R, DL, TII.get(V6C::LHLD), V6C::HL)
              .addSym(Syms[0], V6CII::MO_PATCH_IMM);
          BuildMI(*MBB, R, DL, TII.get(V6C::XCHG));
        } else {
          // LHLD ... ; XCHG        (24cc, 4B)
          BuildMI(*MBB, R, DL, TII.get(V6C::LHLD), V6C::HL)
              .addSym(Syms[0], V6CII::MO_PATCH_IMM);
          BuildMI(*MBB, R, DL, TII.get(V6C::XCHG));
        }
      } else {
        assert(Dst == V6C::BC && "Stage 3 reload dst must be HL/DE/BC");
        if (HLLive) {
          // PUSH HL; LHLD ... ; MOV C,L; MOV B,H; POP HL  (64cc, 7B)
          BuildMI(*MBB, R, DL, TII.get(V6C::PUSH)).addReg(V6C::HL);
          BuildMI(*MBB, R, DL, TII.get(V6C::LHLD), V6C::HL)
              .addSym(Syms[0], V6CII::MO_PATCH_IMM);
          BuildMI(*MBB, R, DL, TII.get(V6C::MOVrr))
              .addReg(V6C::C, RegState::Define).addReg(V6C::L);
          BuildMI(*MBB, R, DL, TII.get(V6C::MOVrr))
              .addReg(V6C::B, RegState::Define).addReg(V6C::H);
          BuildMI(*MBB, R, DL, TII.get(V6C::POP), V6C::HL);
        } else {
          // LHLD ... ; MOV C,L; MOV B,H  (36cc, 5B)
          BuildMI(*MBB, R, DL, TII.get(V6C::LHLD), V6C::HL)
              .addSym(Syms[0], V6CII::MO_PATCH_IMM);
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
