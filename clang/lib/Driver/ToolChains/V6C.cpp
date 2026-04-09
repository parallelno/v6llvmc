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
#include "clang/Driver/InputInfo.h"
#include "clang/Driver/Options.h"
#include "llvm/Option/ArgList.h"

using namespace clang;
using namespace clang::driver;
using namespace clang::driver::toolchains;
using namespace clang::driver::tools;

void v6c::Linker::ConstructJob(Compilation &C, const JobAction &JA,
                                const InputInfo &Output,
                                const InputInfoList &Inputs,
                                const llvm::opt::ArgList &TCArgs,
                                const char *LinkingOutput) const {
  llvm::opt::ArgStringList CmdArgs;

  for (const auto &II : Inputs) {
    if (II.isFilename())
      CmdArgs.push_back(II.getFilename());
  }

  CmdArgs.push_back("-o");
  CmdArgs.push_back(Output.getFilename());

  const char *Exec = TCArgs.MakeArgString(getToolChain().GetLinkerPath());
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
