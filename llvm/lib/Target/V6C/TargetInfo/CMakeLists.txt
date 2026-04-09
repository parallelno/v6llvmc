add_llvm_component_library(LLVMV6CInfo
  V6CTargetInfo.cpp

  LINK_COMPONENTS
    MC
    Support

  ADD_TO_COMPONENT
    V6C
)
