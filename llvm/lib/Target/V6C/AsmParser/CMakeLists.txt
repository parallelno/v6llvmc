# V6C AsmParser — TableGen-driven assembly parser for the i8080-canonical
# V6C assembly dialect. Built only when V6C is in LLVM_EXPERIMENTAL_TARGETS.

add_llvm_component_library(LLVMV6CAsmParser
  V6CAsmParser.cpp

  LINK_COMPONENTS
    MC
    MCParser
    Support
    V6CDesc
    V6CInfo

  ADD_TO_COMPONENT
    V6C
)
