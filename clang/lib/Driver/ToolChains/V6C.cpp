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
#include "llvm/Option/ArgList.h"
#include "llvm/Support/FileSystem.h"
#include "llvm/Support/Path.h"

using namespace clang;
using namespace clang::driver;
using namespace clang::driver::toolchains;
using namespace clang::driver::tools;

/// Find v6c_link.py relative to the clang binary.
/// Search order: <bin>/../scripts/v6c_link.py, <bin>/v6c_link.py
static std::string findV6CLinkScript(const ToolChain &TC) {
  // Try relative to the driver (clang binary) directory
  StringRef Dir = TC.getDriver().Dir;

  // <dir>/../scripts/v6c_link.py  (development layout)
  SmallString<256> Path(Dir);
  llvm::sys::path::append(Path, "..", "scripts", "v6c_link.py");
  if (llvm::sys::fs::exists(Path))
    return std::string(Path);

  // <dir>/v6c_link.py  (installed alongside clang)
  Path = Dir;
  llvm::sys::path::append(Path, "v6c_link.py");
  if (llvm::sys::fs::exists(Path))
    return std::string(Path);

  // Fallback: assume it's on PATH
  return "v6c_link.py";
}

void v6c::Linker::ConstructJob(Compilation &C, const JobAction &JA,
                                const InputInfo &Output,
                                const InputInfoList &Inputs,
                                const llvm::opt::ArgList &TCArgs,
                                const char *LinkingOutput) const {
  llvm::opt::ArgStringList CmdArgs;

  std::string Script = findV6CLinkScript(getToolChain());
  CmdArgs.push_back(TCArgs.MakeArgString(Script));

  // Pass input files
  for (const auto &II : Inputs) {
    if (II.isFilename())
      CmdArgs.push_back(II.getFilename());
  }

  CmdArgs.push_back("-o");
  CmdArgs.push_back(Output.getFilename());

  // Pass start address if specified via -Wl,--base,<addr> or -Xlinker --base
  for (const auto *A : TCArgs.filtered(clang::driver::options::OPT_Xlinker)) {
    A->claim();
    CmdArgs.push_back(A->getValue());
  }
  for (const auto *A : TCArgs.filtered(clang::driver::options::OPT_Wl_COMMA)) {
    A->claim();
    for (StringRef Val : A->getValues())
      CmdArgs.push_back(TCArgs.MakeArgString(Val));
  }

  // Find Python interpreter
  const char *Exec = TCArgs.MakeArgString("python");
  C.addCommand(std::make_unique<Command>(JA, *this,
                                         ResponseFileSupport::AtFileCurCP(),
                                         Exec, CmdArgs, Inputs, Output));
}

V6CToolChain::V6CToolChain(const Driver &D, const llvm::Triple &Triple,
                            const llvm::opt::ArgList &Args)
    : ToolChain(D, Triple, Args) {}

void V6CToolChain::addClangTargetOptions(
    const llvm::opt::ArgList &DriverArgs, llvm::opt::ArgStringList &CC1Args,
    Action::OffloadKind) const {
  // Force freestanding mode — no hosted C library.
  CC1Args.push_back("-ffreestanding");
}

Tool *V6CToolChain::buildLinker() const {
  return new tools::v6c::Linker(*this);
}
