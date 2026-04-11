add_llvm_component_library(LLVMV6CDesc
  V6CAsmBackend.cpp
  V6CInstPrinter.cpp
  V6CMCAsmInfo.cpp
  V6CMCCodeEmitter.cpp
  V6CMCExpr.cpp
  V6CMCTargetDesc.cpp

  LINK_COMPONENTS
    MC
    Support
    V6CInfo

  ADD_TO_COMPONENT
    V6C
)
