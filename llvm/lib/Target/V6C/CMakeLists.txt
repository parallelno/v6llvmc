# V6C Target — CMakeLists.txt
#
# Build the V6C (Vector 06c / Intel 8080) LLVM backend.
# Enable with: cmake ... -DLLVM_EXPERIMENTAL_TARGETS_TO_BUILD="V6C"

add_llvm_component_group(V6C)

set(LLVM_TARGET_DEFINITIONS V6C.td)

tablegen(LLVM V6CGenRegisterInfo.inc   -gen-register-info)
tablegen(LLVM V6CGenInstrInfo.inc      -gen-instr-info)
tablegen(LLVM V6CGenSubtargetInfo.inc  -gen-subtarget)
tablegen(LLVM V6CGenDAGISel.inc        -gen-dag-isel)
tablegen(LLVM V6CGenAsmWriter.inc      -gen-asm-writer)
tablegen(LLVM V6CGenAsmMatcher.inc     -gen-asm-matcher)
tablegen(LLVM V6CGenCallingConv.inc    -gen-callingconv)
tablegen(LLVM V6CGenMCCodeEmitter.inc  -gen-emitter)

add_public_tablegen_target(V6CCommonTableGen)

add_llvm_target(V6CCodeGen
  V6CAccumulatorPlanning.cpp
  V6CAsmPrinter.cpp
  V6CBranchOpt.cpp
  V6CConstantSinking.cpp
  V6CDeadPhiConst.cpp
  V6CFrameLowering.cpp
  V6CISelDAGToDAG.cpp
  V6CISelLowering.cpp
  V6CInstrInfo.cpp
  V6CLoadImmCombine.cpp
  V6CLoadStoreOpt.cpp
  V6CLoopPointerInduction.cpp
  V6CMCInstLower.cpp
  V6CPeephole.cpp
  V6CRedundantFlagElim.cpp
  V6CRegisterInfo.cpp
  V6CSPTrickOpt.cpp
  V6CSpillExpand.cpp
  V6CSpillForwarding.cpp
  V6CSpillPatchedReload.cpp
  V6CStaticStackAlloc.cpp
  V6CSubtarget.cpp
  V6CTargetMachine.cpp
  V6CTargetTransformInfo.cpp
  V6CTypeNarrowing.cpp
  V6CXchgOpt.cpp
  V6CZeroTestOpt.cpp

  LINK_COMPONENTS
    Analysis
    AsmPrinter
    CodeGen
    CodeGenTypes
    Core
    MC
    SelectionDAG
    Support
    Target
    V6CDesc
    V6CInfo

  ADD_TO_COMPONENT
    V6C
)

add_subdirectory(AsmParser)
add_subdirectory(MCTargetDesc)
add_subdirectory(TargetInfo)
