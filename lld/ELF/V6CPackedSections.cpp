//===- V6CPackedSections.cpp ----------------------------------------------===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

#include "V6CPackedSections.h"
#include "Config.h"
#include "InputSection.h"
#include "LinkerScript.h"
#include "OutputSections.h"
#include "lld/Common/ErrorHandler.h"
#include "lld/Common/Strings.h"
#include "llvm/ADT/DenseMap.h"
#include "llvm/ADT/STLExtras.h"
#include "llvm/BinaryFormat/ELF.h"
#include <cstdint>
#include <limits>
#include <optional>

using namespace llvm;
using namespace llvm::ELF;
using namespace lld;
using namespace lld::elf;

namespace {

constexpr uint64_t pageSize = 0x100;

struct SectionBlock {
  InputSection *section;
  V6CPackBlock layout;
};

struct Hole {
  uint64_t begin;
  uint64_t end;
};

static std::optional<V6CPackKind> getPackKind(StringRef name) {
  if (name == ".bss.pack.align")
    return V6CPackKind::Anchor;
  if (name == ".bss.pack.window")
    return V6CPackKind::Window;
  if (name == ".bss.pack")
    return V6CPackKind::Filler;
  return std::nullopt;
}

static bool checkedAdd(uint64_t lhs, uint64_t rhs, uint64_t &result) {
  if (rhs > std::numeric_limits<uint64_t>::max() - lhs)
    return false;
  result = lhs + rhs;
  return true;
}

static bool alignToPage(uint64_t value, uint64_t &result) {
  uint64_t biased;
  if (!checkedAdd(value, pageSize - 1, biased))
    return false;
  result = biased & ~(pageSize - 1);
  return true;
}

static bool fitsWindow(uint64_t addr, uint64_t size) {
  return size <= pageSize && (addr & (pageSize - 1)) + size <= pageSize;
}

static void addHole(SmallVectorImpl<Hole> &holes, uint64_t begin,
                    uint64_t end) {
  if (begin < end)
    holes.push_back({begin, end});
}

static bool placeInBestHole(V6CPackBlock &block, SmallVectorImpl<Hole> &holes,
                            bool window) {
  size_t best = std::numeric_limits<size_t>::max();
  uint64_t bestAddr = 0;
  uint64_t bestSize = std::numeric_limits<uint64_t>::max();

  for (size_t i = 0; i != holes.size(); ++i) {
    const Hole &hole = holes[i];
    uint64_t addr = hole.begin;
    if (window && !fitsWindow(addr, block.size)) {
      if (!alignToPage(addr, addr))
        continue;
    }
    if (addr > hole.end || block.size > hole.end - addr)
      continue;
    uint64_t holeSize = hole.end - hole.begin;
    if (holeSize < bestSize ||
        (holeSize == bestSize && hole.begin < holes[best].begin)) {
      best = i;
      bestAddr = addr;
      bestSize = holeSize;
    }
  }

  if (best == std::numeric_limits<size_t>::max())
    return false;

  Hole hole = holes[best];
  holes.erase(holes.begin() + best);
  uint64_t blockEnd = bestAddr + block.size;
  addHole(holes, hole.begin, bestAddr);
  addHole(holes, blockEnd, hole.end);
  block.addr = bestAddr;
  return true;
}

static bool appendBlock(V6CPackBlock &block, SmallVectorImpl<Hole> &holes,
                        uint64_t &cursor) {
  uint64_t addr = cursor;
  if (block.kind == V6CPackKind::Window && !fitsWindow(addr, block.size)) {
    if (!alignToPage(addr, addr))
      return false;
    addHole(holes, cursor, addr);
  }

  uint64_t end;
  if (!checkedAdd(addr, block.size, end))
    return false;
  block.addr = addr;
  cursor = end;
  return true;
}

static bool validateSection(InputSection &section, V6CPackKind kind) {
  bool valid = true;
  auto report = [&](const Twine &message) {
    error(toString(&section) + ": " + message);
    valid = false;
  };

  if (section.type != SHT_NOBITS)
    report("packed V6C section must have type SHT_NOBITS");
  if ((section.flags & (SHF_ALLOC | SHF_WRITE)) !=
      (SHF_ALLOC | SHF_WRITE))
    report("packed V6C section must have SHF_ALLOC and SHF_WRITE flags");
  if (section.flags &
      (SHF_EXECINSTR | SHF_TLS | SHF_MERGE | SHF_STRINGS | SHF_LINK_ORDER))
    report("packed V6C section has incompatible ELF flags");
  if (section.addralign != 1)
    report("packed V6C section must have alignment 1");
  if (section.getSize() == 0)
    report("packed V6C section must not be empty");
  if (kind == V6CPackKind::Window && section.getSize() > pageSize)
    report(".bss.pack.window section exceeds 256 bytes");
  if (!section.relocs().empty())
    report("packed V6C NOBITS section must not contain relocations");
  return valid;
}

} // namespace

V6CPackResult elf::assignV6CPackedBlockAddresses(
    MutableArrayRef<V6CPackBlock> blocks, uint64_t startAddr,
    uint64_t &endAddr) {
  endAddr = startAddr;
  if (startAddr > 0x10000)
    return V6CPackResult::AddressSpaceOverflow;
  for (const V6CPackBlock &block : blocks)
    if (block.size == 0 ||
        (block.kind == V6CPackKind::Window && block.size > pageSize))
      return V6CPackResult::InvalidBlock;

  auto bySizeThenOrder = [&](size_t lhs, size_t rhs) {
    if (blocks[lhs].size != blocks[rhs].size)
      return blocks[lhs].size > blocks[rhs].size;
    return blocks[lhs].originalOrder < blocks[rhs].originalOrder;
  };

  SmallVector<size_t, 0> anchors;
  SmallVector<size_t, 0> windows;
  SmallVector<size_t, 0> fillers;
  for (auto [index, block] : llvm::enumerate(blocks)) {
    if (block.kind == V6CPackKind::Anchor)
      anchors.push_back(index);
    else if (block.kind == V6CPackKind::Window)
      windows.push_back(index);
    else
      fillers.push_back(index);
  }
  llvm::sort(anchors, bySizeThenOrder);
  llvm::sort(windows, bySizeThenOrder);
  llvm::sort(fillers, bySizeThenOrder);

  SmallVector<Hole, 0> holes;
  uint64_t cursor = startAddr;
  for (size_t index : anchors) {
    uint64_t aligned;
    if (!alignToPage(cursor, aligned))
      return V6CPackResult::AddressOverflow;
    addHole(holes, cursor, aligned);
    cursor = aligned;
    if (!appendBlock(blocks[index], holes, cursor))
      return V6CPackResult::AddressOverflow;
  }

  for (size_t index : windows)
    if (!placeInBestHole(blocks[index], holes, true) &&
        !appendBlock(blocks[index], holes, cursor))
      return V6CPackResult::AddressOverflow;
  for (size_t index : fillers)
    if (!placeInBestHole(blocks[index], holes, false) &&
        !appendBlock(blocks[index], holes, cursor))
      return V6CPackResult::AddressOverflow;

  if (cursor > 0x10000)
    return V6CPackResult::AddressSpaceOverflow;

  endAddr = cursor;
  return V6CPackResult::Success;
}

bool elf::assignV6CPackedSectionOffsets(OutputSection &osec,
                                        uint64_t startAddr,
                                        uint64_t &endAddr) {
  if (config->emachine != EM_V6C || config->relocatable ||
      osec.name != ".bss.pack")
    return false;

  SmallVector<InputSectionDescription *, 3> descriptions;
  SmallVector<InputSection *, 0> sections;
  for (SectionCommand *command : osec.commands) {
    auto *description = dyn_cast<InputSectionDescription>(command);
    if (!description) {
      warn("V6C packed output section contains linker-script commands; "
           "using normal layout");
      return false;
    }
    descriptions.push_back(description);
    sections.append(description->sections.begin(), description->sections.end());
  }
  if (sections.empty())
    return false;

  DenseMap<InputSection *, uint64_t> originalOrder;
  for (auto [index, section] : llvm::enumerate(ctx.inputSections))
    if (auto *input = dyn_cast<InputSection>(section))
      originalOrder.try_emplace(input, index);

  SmallVector<SectionBlock, 0> blocks;
  bool valid = true;
  for (InputSection *section : sections) {
    std::optional<V6CPackKind> kind = getPackKind(section->name);
    if (!kind) {
      warn("V6C packed output section contains unrecognized input section '" +
           section->name + "'; using normal layout");
      return false;
    }
    valid &= validateSection(*section, *kind);
    blocks.push_back({section, {*kind, section->getSize(),
                  originalOrder.lookup(section)}});
  }

  endAddr = startAddr;
  if (!valid)
    return true;

  SmallVector<V6CPackBlock, 0> layout;
  llvm::transform(blocks, std::back_inserter(layout),
                  [](const SectionBlock &block) { return block.layout; });
  V6CPackResult result =
      assignV6CPackedBlockAddresses(layout, startAddr, endAddr);
  if (result == V6CPackResult::AddressOverflow) {
    error("V6C packed section address overflow");
    return true;
  }
  if (result == V6CPackResult::AddressSpaceOverflow) {
    error("V6C packed section exceeds the 16-bit address space");
    return true;
  }
  if (result == V6CPackResult::InvalidBlock) {
    error("invalid V6C packed block reached layout");
    return true;
  }
  for (auto [block, placed] : llvm::zip_equal(blocks, layout))
    block.layout.addr = placed.addr;

  llvm::sort(blocks, [](const SectionBlock &lhs, const SectionBlock &rhs) {
    if (lhs.layout.addr != rhs.layout.addr)
      return lhs.layout.addr < rhs.layout.addr;
    return lhs.layout.originalOrder < rhs.layout.originalOrder;
  });
  descriptions.front()->sections.clear();
  for (const SectionBlock &block : blocks) {
    block.section->outSecOff = block.layout.addr - startAddr;
    descriptions.front()->sections.push_back(block.section);
  }
  for (InputSectionDescription *description : drop_begin(descriptions))
    description->sections.clear();

  return true;
}