//===- V6CPackedSectionsTest.cpp --------------------------------*- C++ -*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

#include "V6CPackedSections.h"
#include "gtest/gtest.h"
#include <limits>

using namespace lld::elf;

namespace {

V6CPackBlock block(V6CPackKind kind, uint64_t size, uint64_t order) {
  return {kind, size, order};
}

TEST(V6CPackedSections, EmptyAndSingleBlock) {
  uint64_t end = 0;
  EXPECT_EQ(V6CPackResult::Success,
            assignV6CPackedBlockAddresses({}, 0x123, end));
  EXPECT_EQ(0x123u, end);

  V6CPackBlock filler = block(V6CPackKind::Filler, 7, 0);
  EXPECT_EQ(V6CPackResult::Success,
            assignV6CPackedBlockAddresses(filler, 0x123, end));
  EXPECT_EQ(0x123u, filler.addr);
  EXPECT_EQ(0x12au, end);
}

TEST(V6CPackedSections, WindowValidationAndPagePlacement) {
  uint64_t end = 0;
  V6CPackBlock exact = block(V6CPackKind::Window, 256, 0);
  EXPECT_EQ(V6CPackResult::Success,
            assignV6CPackedBlockAddresses(exact, 0x101, end));
  EXPECT_EQ(0x200u, exact.addr);
  EXPECT_EQ(0x300u, end);

  V6CPackBlock oversized = block(V6CPackKind::Window, 257, 0);
  EXPECT_EQ(V6CPackResult::InvalidBlock,
            assignV6CPackedBlockAddresses(oversized, 0, end));
}

TEST(V6CPackedSections, HolesBestFitAndStableTies) {
  V6CPackBlock blocks[] = {
      block(V6CPackKind::Anchor, 100, 0),
      block(V6CPackKind::Anchor, 300, 1),
      block(V6CPackKind::Window, 120, 2),
      block(V6CPackKind::Window, 256, 3),
      block(V6CPackKind::Window, 200, 4),
      block(V6CPackKind::Window, 20, 5),
      block(V6CPackKind::Window, 20, 6),
      block(V6CPackKind::Filler, 40, 7),
      block(V6CPackKind::Filler, 60, 8),
  };
  uint64_t end = 0;
  ASSERT_EQ(V6CPackResult::Success,
            assignV6CPackedBlockAddresses(blocks, 0x10a, end));
  EXPECT_EQ(0x400u, blocks[0].addr);
  EXPECT_EQ(0x200u, blocks[1].addr);
  EXPECT_EQ(0x464u, blocks[2].addr);
  EXPECT_EQ(0x500u, blocks[3].addr);
  EXPECT_EQ(0x32cu, blocks[4].addr);
  EXPECT_EQ(0x4dcu, blocks[5].addr);
  EXPECT_EQ(0x10au, blocks[6].addr);
  EXPECT_EQ(0x15au, blocks[7].addr);
  EXPECT_EQ(0x11eu, blocks[8].addr);
  EXPECT_EQ(0x600u, end);
}

TEST(V6CPackedSections, ReferenceWorkloadHasNoWaste) {
  V6CPackBlock blocks[] = {
      block(V6CPackKind::Anchor, 256, 0),
      block(V6CPackKind::Anchor, 256, 1),
      block(V6CPackKind::Anchor, 256, 2),
      block(V6CPackKind::Anchor, 240, 3),
      block(V6CPackKind::Window, 227, 4),
      block(V6CPackKind::Window, 17, 5),
      block(V6CPackKind::Window, 64, 6),
      block(V6CPackKind::Window, 62, 7),
      block(V6CPackKind::Filler, 16, 8),
      block(V6CPackKind::Filler, 10, 9),
      block(V6CPackKind::Filler, 2, 10),
      block(V6CPackKind::Filler, 512, 11),
      block(V6CPackKind::Filler, 482, 12),
      block(V6CPackKind::Filler, 480, 13),
      block(V6CPackKind::Filler, 240, 14),
      block(V6CPackKind::Filler, 31, 15),
      block(V6CPackKind::Filler, 17, 16),
      block(V6CPackKind::Filler, 16, 17),
      block(V6CPackKind::Filler, 16, 18),
      block(V6CPackKind::Filler, 15, 19),
      block(V6CPackKind::Filler, 14, 20),
      block(V6CPackKind::Filler, 2, 21),
      block(V6CPackKind::Filler, 1, 22),
  };
  uint64_t end = 0;
  ASSERT_EQ(V6CPackResult::Success,
            assignV6CPackedBlockAddresses(blocks, 0, end));
  EXPECT_EQ(3232u, end);
}

TEST(V6CPackedSections, RejectsInvalidAndOverflowingBlocks) {
  uint64_t end = 0;
  V6CPackBlock empty = block(V6CPackKind::Filler, 0, 0);
  EXPECT_EQ(V6CPackResult::InvalidBlock,
            assignV6CPackedBlockAddresses(empty, 0, end));

  V6CPackBlock addressSpace = block(V6CPackKind::Filler, 257, 0);
  EXPECT_EQ(V6CPackResult::AddressSpaceOverflow,
            assignV6CPackedBlockAddresses(addressSpace, 0xff00, end));

  V6CPackBlock arithmetic = block(V6CPackKind::Anchor, 1, 0);
  EXPECT_EQ(V6CPackResult::AddressSpaceOverflow,
            assignV6CPackedBlockAddresses(
                arithmetic, std::numeric_limits<uint64_t>::max(), end));
}

} // namespace
