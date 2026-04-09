//===-- V6CAsmBackend.cpp - V6C Assembler Backend -------------------------===//
//
// Part of the V6C backend for LLVM.
//
// Implements the MCAsmBackend for the V6C target, handling fixups (address
// and immediate patching) and creating the ELF object writer.
//
//===----------------------------------------------------------------------===//

#include "V6CFixupKinds.h"
#include "MCTargetDesc/V6CMCTargetDesc.h"

#include "llvm/MC/MCAsmBackend.h"
#include "llvm/MC/MCAssembler.h"
#include "llvm/MC/MCContext.h"
#include "llvm/MC/MCELFObjectWriter.h"
#include "llvm/MC/MCFixupKindInfo.h"
#include "llvm/MC/MCObjectWriter.h"
#include "llvm/MC/MCSubtargetInfo.h"
#include "llvm/MC/MCValue.h"
#include "llvm/MC/TargetRegistry.h"
#include "llvm/Support/ErrorHandling.h"

using namespace llvm;

namespace {

class V6CAsmBackend : public MCAsmBackend {
public:
  V6CAsmBackend() : MCAsmBackend(llvm::endianness::little) {}

  unsigned getNumFixupKinds() const override {
    return V6C::NumTargetFixupKinds;
  }

  const MCFixupKindInfo &getFixupKindInfo(MCFixupKind Kind) const override {
    const static MCFixupKindInfo Infos[V6C::NumTargetFixupKinds] = {
        // name              offset  size  flags
        {"fixup_v6c_8",   0, 8, 0},
        {"fixup_v6c_16",  0, 16, 0},
    };

    if (Kind < FirstTargetFixupKind)
      return MCAsmBackend::getFixupKindInfo(Kind);

    assert(unsigned(Kind - FirstTargetFixupKind) < getNumFixupKinds() &&
           "Invalid kind!");
    return Infos[Kind - FirstTargetFixupKind];
  }

  void applyFixup(const MCAssembler &Asm, const MCFixup &Fixup,
                  const MCValue &Target, MutableArrayRef<char> Data,
                  uint64_t Value, bool IsResolved,
                  const MCSubtargetInfo *STI) const override {
    unsigned Offset = Fixup.getOffset();
    MCFixupKind Kind = Fixup.getKind();

    if (Kind == FK_Data_1 ||
        Kind == static_cast<MCFixupKind>(V6C::fixup_v6c_8)) {
      // 8-bit value, single byte.
      assert(Offset < Data.size() && "Fixup offset out of range");
      Data[Offset] = static_cast<char>(Value & 0xFF);
      return;
    }

    if (Kind == FK_Data_2 ||
        Kind == static_cast<MCFixupKind>(V6C::fixup_v6c_16)) {
      // 16-bit value, little-endian.
      assert(Offset + 1 < Data.size() && "Fixup offset out of range");
      Data[Offset] = static_cast<char>(Value & 0xFF);         // low byte
      Data[Offset + 1] = static_cast<char>((Value >> 8) & 0xFF); // high byte
      return;
    }

    if (Kind == FK_Data_4) {
      assert(Offset + 3 < Data.size() && "Fixup offset out of range");
      Data[Offset] = static_cast<char>(Value & 0xFF);
      Data[Offset + 1] = static_cast<char>((Value >> 8) & 0xFF);
      Data[Offset + 2] = static_cast<char>((Value >> 16) & 0xFF);
      Data[Offset + 3] = static_cast<char>((Value >> 24) & 0xFF);
      return;
    }

    llvm_unreachable("Unknown fixup kind!");
  }

  bool fixupNeedsRelaxation(const MCFixup &Fixup, uint64_t Value,
                            const MCRelaxableFragment *DF,
                            const MCAsmLayout &Layout) const override {
    // 8080 has no relaxable instructions.
    return false;
  }

  bool writeNopData(raw_ostream &OS, uint64_t Count,
                    const MCSubtargetInfo *STI) const override {
    // NOP on 8080 is 0x00.
    for (uint64_t i = 0; i < Count; ++i)
      OS.write('\0');
    return true;
  }

  std::unique_ptr<MCObjectTargetWriter>
  createObjectTargetWriter() const override;
};

} // anonymous namespace

// ===== ELF Object Writer ===== //

namespace {

class V6CELFObjectWriter : public MCELFObjectTargetWriter {
public:
  V6CELFObjectWriter()
      : MCELFObjectTargetWriter(/*Is64Bit=*/false, /*OSABI=*/0,
                                /*EMachine=*/ELF::EM_NONE,
                                /*HasRelocationAddend=*/true) {}

  unsigned getRelocType(MCContext &Ctx, const MCValue &Target,
                        const MCFixup &Fixup,
                        bool IsPCRel) const override {
    MCFixupKind Kind = Fixup.getKind();
    switch (static_cast<unsigned>(Kind)) {
    case FK_Data_1:
    case V6C::fixup_v6c_8:
      return V6C::R_V6C_8;
    case FK_Data_2:
    case V6C::fixup_v6c_16:
      return V6C::R_V6C_16;
    default:
      return V6C::R_V6C_NONE;
    }
  }
};

} // anonymous namespace

std::unique_ptr<MCObjectTargetWriter>
V6CAsmBackend::createObjectTargetWriter() const {
  return std::make_unique<V6CELFObjectWriter>();
}

namespace llvm {

MCAsmBackend *createV6CAsmBackend(const Target &T,
                                   const MCSubtargetInfo &STI,
                                   const MCRegisterInfo &MRI,
                                   const MCTargetOptions &Options) {
  return new V6CAsmBackend();
}

} // namespace llvm
