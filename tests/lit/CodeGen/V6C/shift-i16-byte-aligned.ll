; RUN: llc -march=v6c < %s | FileCheck %s
;
; O62 — Efficient i16 shift expansion for constant amount >= 8.
; Verifies that V6C_SRL16 / V6C_SRA16 / V6C_SHL16 expansions for byte-
; aligned (and slightly larger) shift amounts:
;   1. skip the dead "copy Src to Dst" prologue,
;   2. zero/sign-extend the unused half via i8-domain ops,
;   3. use a half-width per-bit loop (DstLo only) for the residual
;      shift amount (ShAmt - 8), since DstHi is provably 0 / sign byte.
;
; The i8080 ABI passes the i16 argument in HL and the ptr in DE, so
; Src == Dst == HL at expansion time. This still exercises the changed
; code paths; the dst != src case is covered by the C-level feature
; test in tests/features/32.

target triple = "i8080-unknown-v6c"

;===----------------------------------------------------------------------===
; SRL i16 by 8
;===----------------------------------------------------------------------===
; New expansion: byte-lane move H -> L + zero H. No per-bit RAR loop.
; CHECK-LABEL: srl8_i16:
; CHECK-NEXT: ; %bb.0:
; CHECK-NEXT:  MOV L, H
; CHECK-NEXT:  MVI H, 0
; CHECK-NEXT:  MOV A, L
; CHECK-NOT:   RAR
define void @srl8_i16(i16 %x, ptr %p) {
  %r = lshr i16 %x, 8
  store i16 %r, ptr %p
  ret void
}

;===----------------------------------------------------------------------===
; SRL i16 by 10
;===----------------------------------------------------------------------===
; Half-width per-bit loop on L only. H must NOT appear in the per-bit body.
; CHECK-LABEL: srl10_i16:
; CHECK-NEXT: ; %bb.0:
; CHECK-NEXT:  MOV L, H
; CHECK-NEXT:  MVI H, 0
; CHECK-NEXT:  MOV A, L
; CHECK-NEXT:  ORA A
; CHECK-NEXT:  RAR
; CHECK-NEXT:  MOV L, A
; CHECK-NEXT:  MOV A, L
; CHECK-NEXT:  ORA A
; CHECK-NEXT:  RAR
; CHECK-NEXT:  MOV L, A
define void @srl10_i16(i16 %x, ptr %p) {
  %r = lshr i16 %x, 10
  store i16 %r, ptr %p
  ret void
}

;===----------------------------------------------------------------------===
; ASHR i16 by 8
;===----------------------------------------------------------------------===
; New expansion:
;   MOV A, H   ; capture sign byte (SrcHi)
;   MOV L, H   ; byte-lane move SrcHi -> DstLo
;   RLC
;   SBB A
;   MOV H, A   ; sign byte into DstHi
; No per-bit ASHR loop is needed for exactly 8.
; CHECK-LABEL: ashr8_i16:
; CHECK-NEXT: ; %bb.0:
; CHECK-NEXT:  MOV A, H
; CHECK-NEXT:  MOV L, H
; CHECK-NEXT:  RLC
; CHECK-NEXT:  SBB A
; CHECK-NEXT:  MOV H, A
define void @ashr8_i16(i16 %x, ptr %p) {
  %r = ashr i16 %x, 8
  store i16 %r, ptr %p
  ret void
}

;===----------------------------------------------------------------------===
; ASHR i16 by 10
;===----------------------------------------------------------------------===
; Byte-aligned sign-extend prologue followed by a HALF-WIDTH arithmetic
; shift loop on DstLo (= L) only. DstHi (= H, the sign byte) must NOT be
; rotated in the per-bit body.
; CHECK-LABEL: ashr10_i16:
; CHECK-NEXT: ; %bb.0:
; CHECK-NEXT:  MOV A, H
; CHECK-NEXT:  MOV L, H
; CHECK-NEXT:  RLC
; CHECK-NEXT:  SBB A
; CHECK-NEXT:  MOV H, A
; CHECK-NEXT:  MOV A, L
; CHECK-NEXT:  RLC
; CHECK-NEXT:  MOV A, L
; CHECK-NEXT:  RAR
; CHECK-NEXT:  MOV L, A
; CHECK-NEXT:  MOV A, L
; CHECK-NEXT:  RLC
; CHECK-NEXT:  MOV A, L
; CHECK-NEXT:  RAR
; CHECK-NEXT:  MOV L, A
define void @ashr10_i16(i16 %x, ptr %p) {
  %r = ashr i16 %x, 10
  store i16 %r, ptr %p
  ret void
}

;===----------------------------------------------------------------------===
; SHL i16 by 8 — sanity check (custom-lowered via BUILD_PAIR in ISel)
;===----------------------------------------------------------------------===
; This case never reaches the V6C_SHL16 pseudo (LowerSHL_i16 emits
; BUILD_PAIR(0, lo) directly), so the diff vs. before O62 is zero.
; Locked down here only to detect future regressions.
; CHECK-LABEL: shl8_i16:
; CHECK:       MOV H, L
; CHECK-NOT:   ADD A
define void @shl8_i16(i16 %x, ptr %p) {
  %r = shl i16 %x, 8
  store i16 %r, ptr %p
  ret void
}

;===----------------------------------------------------------------------===
; SHL i16 by 10 — sanity check (custom-lowered via BUILD_PAIR in ISel)
;===----------------------------------------------------------------------===
; CHECK-LABEL: shl10_i16:
; CHECK-NEXT: ; %bb.0:
; CHECK-NEXT:  MOV A, L
; CHECK-NEXT:  ADD A
; CHECK-NEXT:  ADD A
; CHECK-NEXT:  MVI L, 0
; CHECK-NEXT:  MOV H, A
define void @shl10_i16(i16 %x, ptr %p) {
  %r = shl i16 %x, 10
  store i16 %r, ptr %p
  ret void
}
