set(LLVM_LINK_COMPONENTS
  BinaryFormat
  MC
  Object
  Option
  ProfileData
  Support
  TargetParser
  WindowsDriver
  )

if(WIN32)
  # MSVCToolChain.cpp uses version.dll.
  set(system_libs version)
endif()

add_clang_library(clangDriver
  Action.cpp
  Compilation.cpp
  Distro.cpp
  Driver.cpp
  DriverOptions.cpp
  Job.cpp
  Multilib.cpp
  MultilibBuilder.cpp
  OffloadBundler.cpp
  OptionUtils.cpp
  Phases.cpp
  SanitizerArgs.cpp
  Tool.cpp
  ToolChain.cpp
  ToolChains/Arch/AArch64.cpp
  ToolChains/Arch/ARM.cpp
  ToolChains/Arch/CSKY.cpp
  ToolChains/Arch/LoongArch.cpp
  ToolChains/Arch/M68k.cpp
  ToolChains/Arch/Mips.cpp
  ToolChains/Arch/PPC.cpp
  ToolChains/Arch/RISCV.cpp
  ToolChains/Arch/Sparc.cpp
  ToolChains/Arch/SystemZ.cpp
  ToolChains/Arch/VE.cpp
  ToolChains/Arch/X86.cpp
  ToolChains/AIX.cpp
  ToolChains/AMDGPU.cpp
  ToolChains/AMDGPUOpenMP.cpp
  ToolChains/AVR.cpp
  ToolChains/BareMetal.cpp
  ToolChains/Clang.cpp
  ToolChains/CommonArgs.cpp
  ToolChains/CrossWindows.cpp
  ToolChains/CSKYToolChain.cpp
  ToolChains/Cuda.cpp
  ToolChains/Darwin.cpp
  ToolChains/DragonFly.cpp
  ToolChains/Flang.cpp
  ToolChains/FreeBSD.cpp
  ToolChains/Fuchsia.cpp
  ToolChains/Gnu.cpp
  ToolChains/Haiku.cpp
  ToolChains/HIPUtility.cpp
  ToolChains/HIPAMD.cpp
  ToolChains/HIPSPV.cpp
  ToolChains/Hexagon.cpp
  ToolChains/HLSL.cpp
  ToolChains/Hurd.cpp
  ToolChains/Linux.cpp
  ToolChains/MipsLinux.cpp
  ToolChains/MinGW.cpp
  ToolChains/MSP430.cpp
  ToolChains/MSVC.cpp
  ToolChains/NaCl.cpp
  ToolChains/NetBSD.cpp
  ToolChains/OHOS.cpp
  ToolChains/OpenBSD.cpp
  ToolChains/PS4CPU.cpp
  ToolChains/RISCVToolchain.cpp
  ToolChains/Solaris.cpp
  ToolChains/SPIRV.cpp
  ToolChains/TCE.cpp
  ToolChains/V6C.cpp
  ToolChains/VEToolchain.cpp
  ToolChains/WebAssembly.cpp
  ToolChains/XCore.cpp
  ToolChains/PPCLinux.cpp
  ToolChains/PPCFreeBSD.cpp
  ToolChains/InterfaceStubs.cpp
  ToolChains/ZOS.cpp
  Types.cpp
  XRayArgs.cpp

  DEPENDS
  ClangDriverOptions

  LINK_LIBS
  clangBasic
  ${system_libs}
  )

# --- V6C: stage crt0.o into the build resource directory ---
# The V6C clang driver looks for crt0.o under <ResourceDir>/lib/v6c/.
# Without this rule, ld.lld emits "cannot find entry symbol _start"
# for any V6C link until crt0.s is manually assembled.
include(GetClangResourceDir)
get_filename_component(_v6c_crt0_src
  "${CMAKE_CURRENT_SOURCE_DIR}/../../../../compiler-rt/lib/builtins/v6c/crt0.s"
  ABSOLUTE)
if(EXISTS "${_v6c_crt0_src}")
  get_clang_resource_dir(_v6c_resource_dir
    PREFIX "${LLVM_LIBRARY_OUTPUT_INTDIR}/.." SUBDIR lib/v6c)
  set(_v6c_crt0_out "${_v6c_resource_dir}/crt0.o")
  add_custom_command(
    OUTPUT "${_v6c_crt0_out}"
    COMMAND ${CMAKE_COMMAND} -E make_directory "${_v6c_resource_dir}"
    COMMAND $<TARGET_FILE:clang> -target i8080-unknown-v6c
            -c "${_v6c_crt0_src}" -o "${_v6c_crt0_out}"
    DEPENDS clang "${_v6c_crt0_src}"
    COMMENT "Building V6C crt0.o"
    VERBATIM)
  add_custom_target(v6c-crt0 ALL DEPENDS "${_v6c_crt0_out}")
  get_clang_resource_dir(_v6c_install_dir SUBDIR lib/v6c)
  install(FILES "${_v6c_crt0_out}"
          DESTINATION "${_v6c_install_dir}"
          COMPONENT clang-resource-headers)
endif()
