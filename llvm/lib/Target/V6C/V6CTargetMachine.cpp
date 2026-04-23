//===-- V6CTargetMachine.cpp - Define TargetMachine for V6C ---------------===//
//
// Part of the V6C backend for LLVM.
//
//===----------------------------------------------------------------------===//

#include "V6CTargetMachine.h"
#include "V6CTargetObjectFile.h"
#include "V6CTargetTransformInfo.h"

#include "llvm/CodeGen/MachineFunction.h"
#include "llvm/CodeGen/MachineFunctionPass.h"
#include "llvm/CodeGen/Passes.h"
#include "llvm/CodeGen/TargetPassConfig.h"
#include "llvm/MC/TargetRegistry.h"
#include "llvm/Support/CommandLine.h"

#include "V6C.h"
#include "MCTargetDesc/V6CMCTargetDesc.h"
#include "TargetInfo/V6CTargetInfo.h"

#include <optional>

static llvm::cl::opt<unsigned> V6CStartAddress(
    "mv6c-start-address",
    llvm::cl::desc("Start address for V6C binary (default: 0x0100)"),
    llvm::cl::init(0x0100));

static llvm::cl::opt<bool> V6CStaticStack(
    "mv6c-static-stack",
    llvm::cl::desc("Use static memory for non-reentrant function stack frames"),
    llvm::cl::init(true));

static llvm::cl::opt<bool> V6CNoStaticStack(
    "mv6c-no-static-stack",
    llvm::cl::desc("Disable static stack allocation"),
    llvm::cl::init(false));

static llvm::cl::opt<bool> V6CAnnotatePseudos(
    "mv6c-annotate-pseudos",
    llvm::cl::desc("Add asm comments showing pseudo expansion origins"),
    llvm::cl::init(false));

static llvm::cl::opt<bool> V6CSpillPatchedReload(
    "mv6c-spill-patched-reload",
    llvm::cl::desc("O61: rewrite HL spill/reload pairs as patched LXI HL "
                   "(self-modifying code, static-stack only)"),
    llvm::cl::init(false), llvm::cl::Hidden);

namespace llvm {

unsigned getV6CStartAddress() { return V6CStartAddress; }
bool getV6CStaticStackEnabled() { return V6CStaticStack && !V6CNoStaticStack; }
bool getV6CAnnotatePseudosEnabled() { return V6CAnnotatePseudos; }
bool getV6CSpillPatchedReloadEnabled() { return V6CSpillPatchedReload; }

// Data layout: little-endian, 16-bit pointers (8-bit aligned),
// all types 8-bit aligned, native integer widths 8 and 16, stack alignment 8.
static const char *V6CDataLayout =
    "e-p:16:8-i1:8-i8:8-i16:8-i32:8-i64:8-n8:16-S8";

static StringRef getCPU(StringRef CPU) {
  if (CPU.empty() || CPU == "generic")
    return "i8080";
  return CPU;
}

static Reloc::Model getEffectiveRelocModel(std::optional<Reloc::Model> RM) {
  return RM.value_or(Reloc::Static);
}

V6CTargetMachine::V6CTargetMachine(const Target &T, const Triple &TT,
                                    StringRef CPU, StringRef FS,
                                    const TargetOptions &Options,
                                    std::optional<Reloc::Model> RM,
                                    std::optional<CodeModel::Model> CM,
                                    CodeGenOptLevel OL, bool JIT)
    : LLVMTargetMachine(T, V6CDataLayout, TT, getCPU(CPU), FS, Options,
                        getEffectiveRelocModel(RM),
                        getEffectiveCodeModel(CM, CodeModel::Small), OL),
      SubTarget(TT, std::string(getCPU(CPU)), std::string(FS), *this) {
  TLOF = std::make_unique<V6CTargetObjectFile>();
  initAsmInfo();
}

V6CTargetMachine::~V6CTargetMachine() = default;

namespace {

// Debug-only verifier: every V6C CALL MachineInstr must carry a register mask
// operand after instruction selection.  Without a mask, IPRA cannot narrow
// the call-site clobber set and the allocator silently under-spills.
#ifndef NDEBUG
class V6CCallRegMaskVerifier : public MachineFunctionPass {
public:
  static char ID;
  V6CCallRegMaskVerifier() : MachineFunctionPass(ID) {}

  StringRef getPassName() const override {
    return "V6C CALL register-mask verifier (debug)";
  }

  bool runOnMachineFunction(MachineFunction &MF) override {
    for (const MachineBasicBlock &MBB : MF) {
      for (const MachineInstr &MI : MBB) {
        if (!MI.isCall())
          continue;
        bool HasMask = false;
        for (const MachineOperand &MO : MI.operands()) {
          if (MO.isRegMask()) {
            HasMask = true;
            break;
          }
        }
        assert(HasMask &&
               "V6C CALL instruction missing register mask operand; "
               "IPRA requires every call to carry a mask (see O39).");
      }
    }
    return false;
  }
};

char V6CCallRegMaskVerifier::ID = 0;
#endif // NDEBUG

class V6CPassConfig : public TargetPassConfig {
public:
  V6CPassConfig(V6CTargetMachine &TM, PassManagerBase &PM)
      : TargetPassConfig(TM, PM) {}

  V6CTargetMachine &getV6CTargetMachine() const {
    return getTM<V6CTargetMachine>();
  }

  bool addInstSelector() override {
    addPass(createV6CISelDag(getV6CTargetMachine(),
                              getOptLevel()));
    return false;
  }

  void addPreRegAlloc() override {
    addPass(createV6CDeadPhiConstPass());
    addPass(createV6CConstantSinkingPass());
#ifndef NDEBUG
    addPass(new V6CCallRegMaskVerifier());
#endif
  }

  void addPostRegAlloc() override {
    if (getV6CStaticStackEnabled())
      addPass(createV6CStaticStackAllocPass());
    addPass(createV6CSpillForwardingPass());
    if (getV6CSpillPatchedReloadEnabled())
      addPass(createV6CSpillPatchedReloadPass());
  }

  void addPreEmitPass() override {
    // Post-RA optimization pipeline per design §8.1 Phase 3.
    // Order: AccumulatorPlanning → Peephole → LoadImmCombine → LoadStoreOpt →
    //        XchgOpt → BranchOpt → ZeroTestOpt → RedundantFlagElim → SPTrickOpt
    addPass(createV6CAccumulatorPlanningPass());
    addPass(createV6CPeepholePass());
    addPass(createV6CLoadImmCombinePass());
    addPass(createV6CLoadStoreOptPass());
    addPass(createV6CXchgOptPass());
    addPass(createV6CBranchOptPass());
    addPass(createV6CZeroTestOptPass());
    addPass(createV6CRedundantFlagElimPass());
    addPass(createV6CSPTrickOptPass());
  }

  void addIRPasses() override {
    TargetPassConfig::addIRPasses();
    addPass(createV6CLoopPointerInductionPass());
    addPass(createV6CTypeNarrowingPass());
  }
};

} // namespace

TargetPassConfig *V6CTargetMachine::createPassConfig(PassManagerBase &PM) {
  return new V6CPassConfig(*this, PM);
}

TargetTransformInfo
V6CTargetMachine::getTargetTransformInfo(const Function &F) const {
  return TargetTransformInfo(V6CTTIImpl(this, F));
}

const V6CSubtarget *V6CTargetMachine::getSubtargetImpl() const {
  return &SubTarget;
}

const V6CSubtarget *
V6CTargetMachine::getSubtargetImpl(const Function &) const {
  return &SubTarget;
}

extern "C" LLVM_EXTERNAL_VISIBILITY void LLVMInitializeV6CTarget() {
  RegisterTargetMachine<V6CTargetMachine> X(getTheV6CTarget());
}

} // namespace llvm
