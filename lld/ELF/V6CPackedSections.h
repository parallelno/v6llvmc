//===- V6CPackedSections.h --------------------------------------*- C++ -*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

#ifndef LLD_ELF_V6CPACKEDSECTIONS_H
#define LLD_ELF_V6CPACKEDSECTIONS_H

#include "llvm/ADT/ArrayRef.h"
#include <cstdint>

namespace lld::elf {

class OutputSection;

enum class V6CPackKind { Filler, Anchor, Window };

struct V6CPackBlock {
    V6CPackKind kind;
    uint64_t size;
    uint64_t originalOrder;
    uint64_t addr = 0;
};

enum class V6CPackResult {
    Success,
    InvalidBlock,
    AddressOverflow,
    AddressSpaceOverflow,
};

V6CPackResult
assignV6CPackedBlockAddresses(llvm::MutableArrayRef<V6CPackBlock> blocks,
                                                            uint64_t startAddr, uint64_t &endAddr);

bool assignV6CPackedSectionOffsets(OutputSection &osec, uint64_t startAddr,
                                   uint64_t &endAddr);

} // namespace lld::elf

#endif