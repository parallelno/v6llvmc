//===--- V6C.cpp - V6C (Intel 8080) ToolChain Implementation -------------===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

#include "V6C.h"
#include "CommonArgs.h"
#include "clang/Driver/Compilation.h"
#include "clang/Driver/Driver.h"
#include "clang/Driver/InputInfo.h"
#include "clang/Driver/Options.h"
#include "llvm/ADT/SmallString.h"
#include "llvm/Option/ArgList.h"
#include "llvm/Support/FileSystem.h"
#include "llvm/Support/Path.h"

using namespace clang;
using namespace clang::driver;
using namespace clang::driver::toolchains;
using namespace clang::driver::tools;
using namespace llvm::opt;

/// Search a list of candidate paths for the first one that exists.
/// Returns empty string if none exist.
static std::string findFirstExisting(llvm::ArrayRef<std::string> Candidates) {
  for (const auto &P : Candidates)
    if (llvm::sys::fs::exists(P))
      return P;
  return std::string();
}

/// Locate a V6C driver data file (linker script) by name.
/// Search order:
///   1. <bin>/../lib/clang/<ver>/v6c/<filename>           (installed)
///   2. <bin>/../../clang/lib/Driver/ToolChains/V6C/...   (workspace dev tree)
///   3. <bin>/../../llvm-project/clang/lib/...            (llvm-project mirror)
static std::string findV6CDriverFile(const ToolChain &TC, StringRef Filename) {
  StringRef Dir = TC.getDriver().Dir;
  llvm::SmallString<256> Installed(TC.getDriver().ResourceDir);
  llvm::sys::path::append(Installed, "v6c", Filename);

  llvm::SmallString<256> DevTree(Dir);
  llvm::sys::path::append(DevTree, "..", "..", "clang", "lib");
  llvm::sys::path::append(DevTree, "Driver", "ToolChains", "V6C", Filename);

  llvm::SmallString<256> MirrorTree(Dir);
  llvm::sys::path::append(MirrorTree, "..", "..", "llvm-project", "clang");
  llvm::sys::path::append(MirrorTree, "lib", "Driver", "ToolChains", "V6C");
  llvm::sys::path::append(MirrorTree, Filename);

  return findFirstExisting({std::string(Installed), std::string(DevTree),
                            std::string(MirrorTree)});
}

/// Locate a V6C runtime artifact (crt0.o) by name.
/// Search order:
///   1. <ResourceDir>/lib/v6c/<filename>                    (installed)
///   2. <bin>/../../compiler-rt/lib/builtins/v6c/<filename> (workspace dev tree)
/// Returns empty string if not found — caller should skip linking it.
static std::string findV6CRuntimeFile(const ToolChain &TC, StringRef Filename) {
  StringRef Dir = TC.getDriver().Dir;
  llvm::SmallString<256> Installed(TC.getDriver().ResourceDir);
  llvm::sys::path::append(Installed, "lib", "v6c", Filename);

  llvm::SmallString<256> DevTree(Dir);
  llvm::sys::path::append(DevTree, "..", "..", "compiler-rt", "lib");
  llvm::sys::path::append(DevTree, "builtins", "v6c", Filename);

  return findFirstExisting({std::string(Installed), std::string(DevTree)});
}

void v6c::Linker::ConstructJob(Compilation &C, const JobAction &JA,
                                const InputInfo &Output,
                                const InputInfoList &Inputs,
                                const ArgList &Args,
                                const char *LinkingOutput) const {
  const ToolChain &TC = getToolChain();
  const Driver &D = TC.getDriver();

  // If the requested output is .elf or .o, the link result IS the final
  // product; otherwise produce a flat ROM via llvm-objcopy. Detect by
  // file extension (case-insensitive).
  StringRef OutName = Output.getFilename();
  StringRef Ext = llvm::sys::path::extension(OutName);
  bool ProduceFlat = !Ext.equals_insensitive(".elf") &&
                     !Ext.equals_insensitive(".o");

  // ----- ld.lld invocation -----
  ArgStringList CmdArgs;

  // ELF emulation — picks the V6C lld backend.
  CmdArgs.push_back("-m");
  CmdArgs.push_back("elf32v6c");

  // Default linker script (skipped when the user supplied -T <script>).
  if (!Args.hasArg(options::OPT_T)) {
    std::string Script = findV6CDriverFile(TC, "v6c.ld");
    if (!Script.empty())
      CmdArgs.push_back(Args.MakeArgString(Twine("-T") + Script));
  }

  // Library search paths from -L and the toolchain.
  Args.AddAllArgs(CmdArgs, options::OPT_L);
  TC.AddFilePathLibArgs(Args, CmdArgs);

  // Forward user-supplied -T (in case both default and user scripts coexist;
  // ld.lld concatenates SECTIONS from multiple -T scripts).
  Args.AddAllArgs(CmdArgs, options::OPT_T);

  // crt0.o (suppressed by -nostartfiles or -nostdlib).
  bool UseStartFiles = !Args.hasArg(options::OPT_nostartfiles,
                                    options::OPT_nostdlib, options::OPT_r);
  if (UseStartFiles) {
    std::string Crt0 = findV6CRuntimeFile(TC, "crt0.o");
    if (!Crt0.empty())
      CmdArgs.push_back(Args.MakeArgString(Crt0));
  }

  // User input objects and -l libraries.
  // No default builtins archive: V6C ships header-only inline-asm wrappers
  // (`<resource-dir>/lib/v6c/include/`) plus per-routine `.o` files picked
  // up via the headers' `__asm__("CALL ...")` references and pruned by
  // ld.lld `--gc-sections`. See design/plan_asm_interop_overhaul.md.
  AddLinkerInputs(TC, Inputs, Args, CmdArgs, JA);

  // Forward -Wl,... and -Xlinker ... (covers --defsym, --gc-sections, etc.).
  // AddAllArgValues splits "-Wl,a,b,c" into individual tokens "a", "b", "c".
  Args.AddAllArgValues(CmdArgs, options::OPT_Wl_COMMA);
  Args.AddAllArgValues(CmdArgs, options::OPT_Xlinker);

  // Linker output: if we'll run objcopy, link into a temp .elf;
  // otherwise link directly to the final output.
  const char *LinkOutput;
  if (ProduceFlat) {
    SmallString<128> Stem(llvm::sys::path::stem(OutName));
    std::string TmpPath = D.GetTemporaryPath(Stem, "elf");
    LinkOutput = C.addTempFile(Args.MakeArgString(TmpPath));
  } else {
    LinkOutput = Output.getFilename();
  }
  CmdArgs.push_back("-o");
  CmdArgs.push_back(LinkOutput);

  std::string Linker = TC.GetProgramPath("ld.lld");
  C.addCommand(std::make_unique<Command>(
      JA, *this, ResponseFileSupport::AtFileCurCP(),
      Args.MakeArgString(Linker), CmdArgs, Inputs, Output));

  // ----- llvm-objcopy step (only when producing a flat ROM) -----
  if (ProduceFlat) {
    ArgStringList ObjArgs;
    ObjArgs.push_back("-O");
    ObjArgs.push_back("binary");
    ObjArgs.push_back(LinkOutput);
    ObjArgs.push_back(Output.getFilename());

    std::string ObjCopy = TC.GetProgramPath("llvm-objcopy");
    C.addCommand(std::make_unique<Command>(
        JA, *this, ResponseFileSupport::None(), Args.MakeArgString(ObjCopy),
        ObjArgs, Inputs, Output));
  }
}

V6CToolChain::V6CToolChain(const Driver &D, const llvm::Triple &Triple,
                            const ArgList &Args)
    : ToolChain(D, Triple, Args) {}

void V6CToolChain::addClangTargetOptions(
    const ArgList &DriverArgs, ArgStringList &CC1Args,
    Action::OffloadKind) const {
  // Force freestanding mode — no hosted C library.
  CC1Args.push_back("-ffreestanding");

  // Per-function ELF sections so ld.lld --gc-sections can prune
  // unreachable helpers transitively. User-passed -fno-function-sections
  // overrides.
  if (DriverArgs.hasFlag(options::OPT_ffunction_sections,
                         options::OPT_fno_function_sections,
                         /*Default=*/true))
    CC1Args.push_back("-ffunction-sections");
}

/// Locate the V6C resource-dir include directory that ships
/// `<string.h>`, `<stdlib.h>`, `<v6c.h>`. Search order mirrors
/// findV6CDriverFile / findV6CRuntimeFile.
static std::string findV6CIncludeDir(const ToolChain &TC) {
  StringRef Dir = TC.getDriver().Dir;
  llvm::SmallString<256> Installed(TC.getDriver().ResourceDir);
  llvm::sys::path::append(Installed, "lib", "v6c", "include");

  llvm::SmallString<256> DevTree(Dir);
  llvm::sys::path::append(DevTree, "..", "..", "clang", "lib");
  llvm::sys::path::append(DevTree, "Driver", "ToolChains", "V6C", "include");

  llvm::SmallString<256> MirrorTree(Dir);
  llvm::sys::path::append(MirrorTree, "..", "..", "llvm-project", "clang");
  llvm::sys::path::append(MirrorTree, "lib", "Driver", "ToolChains", "V6C");
  llvm::sys::path::append(MirrorTree, "include");

  return findFirstExisting({std::string(Installed), std::string(DevTree),
                            std::string(MirrorTree)});
}

void V6CToolChain::AddClangSystemIncludeArgs(
    const ArgList &DriverArgs, ArgStringList &CC1Args) const {
  if (DriverArgs.hasArg(options::OPT_nostdinc))
    return;

  // V6C-specific resource headers come first so they can shadow nothing
  // (Clang's stock freestanding directory has no <string.h>).
  if (!DriverArgs.hasArg(options::OPT_nostdlibinc)) {
    std::string IncDir = findV6CIncludeDir(*this);
    if (!IncDir.empty()) {
      CC1Args.push_back("-internal-isystem");
      CC1Args.push_back(DriverArgs.MakeArgString(IncDir));
    }
  }

  // Standard freestanding headers (stdint.h, stddef.h, ...) under the
  // resource directory.
  if (!DriverArgs.hasArg(options::OPT_nobuiltininc)) {
    llvm::SmallString<128> Dir(getDriver().ResourceDir);
    llvm::sys::path::append(Dir, "include");
    CC1Args.push_back("-internal-isystem");
    CC1Args.push_back(DriverArgs.MakeArgString(Dir));
  }
}

Tool *V6CToolChain::buildLinker() const {
  return new tools::v6c::Linker(*this);
}
