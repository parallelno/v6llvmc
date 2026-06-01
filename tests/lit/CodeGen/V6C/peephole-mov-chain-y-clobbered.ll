; RUN: llc -march=v6c < %s | FileCheck %s
; RUN: llc -march=v6c --v6c-disable-peephole < %s | FileCheck %s --check-prefix=DISABLED
;
; O89: MOV-chain "rewrite-producer" collapse when Y is clobbered between
; producer and consumer.
;
; Pattern (before fix, with peephole disabled):
;
;   LHLD  .LLo61_0+1   ; reload spilled 16-bit value into HL
;   MOV   C, L         ; producer: X=C ← Y=L (save lo-byte before HL clobbered)
;   MOV   B, H         ; also save hi-byte
;   POP   H            ; clobbers HL (Y=L) — part of reload address setup
;   MOV   A, C         ; consumer: Z=A ← X=C
;   ANI   1            ; use A
;
; collapseMovChain previously terminated the scan when it saw POP H clobber Y=L
; (ClobbersY=true), so it never reached the consumer MOV A,C.
;
; The classic "rewrite consumer" transform (MOV A,C → MOV A,L) would be wrong
; here: after POP H, L holds the stack-restored value, not the spilled lo-byte.
;
; The "rewrite-producer" variant (O89) instead rewrites the *producer* before
; the clobber and erases the consumer:
;
;   LHLD  .LLo61_0+1   ; reload spilled value into HL
;   MOV   A, L         ; rewritten producer: Z=A ← Y=L  (saves 8 cc)
;   POP   H            ; clobbers HL — irrelevant, A already holds the value
;   ANI   1            ; consumer erased; A already set
;
; Preconditions checked: Z=A not read or written between producer and consumer,
; X=C dead after consumer.
;
; Trigger: LFSR-16 hot loop under register pressure that spills the 16-bit
; loop state (HL) and needs its lo-byte for the LSB test.

target datalayout = "e-p:16:8-i1:8-i8:8-i16:8-i32:8-i64:8-n8:16-S8"
target triple = "i8080-unknown-v6c"

; CHECK-LABEL:     main:
; CHECK:           LHLD    .LLo61_0+1
; CHECK-NEXT:      MOV     A, L
; CHECK-NEXT:      POP     H
; CHECK-NEXT:      ANI     1

; DISABLED-LABEL:  main:
; DISABLED:        LHLD    .LLo61_0+1
; DISABLED-NEXT:   MOV     C, L
; DISABLED:        MOV     A, C
; DISABLED-NEXT:   ANI     1

define dso_local noundef i16 @main(i16 noundef %0, ptr nocapture noundef readnone %1) local_unnamed_addr {
  %3 = alloca i16, align 2
  call void @llvm.lifetime.start.p0(i64 2, ptr nonnull %3)
  store volatile i16 -21279, ptr %3, align 2
  %4 = load volatile i16, ptr %3, align 2
  br label %5

5:
  %6 = phi i16 [ %4, %2 ], [ %13, %5 ]
  %7 = phi i16 [ 0, %2 ], [ %15, %5 ]
  %8 = phi i16 [ 0, %2 ], [ %14, %5 ]
  %9 = lshr i16 %6, 1
  %10 = and i16 %6, 1
  %11 = icmp eq i16 %10, 0
  %12 = xor i16 %9, -19456
  %13 = select i1 %11, i16 %9, i16 %12
  %14 = xor i16 %13, %8
  %15 = add nuw nsw i16 %7, 1
  %16 = icmp eq i16 %15, 4096
  br i1 %16, label %17, label %5

17:
  %18 = lshr i16 %14, 8
  %19 = xor i16 %18, %14
  %20 = trunc i16 %19 to i8
  tail call void @llvm.v6c.out(i8 -19, i8 %20)
  tail call void @llvm.v6c.hlt()
  unreachable
}

declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture)
declare void @llvm.v6c.out(i8, i8)
declare void @llvm.v6c.hlt()
