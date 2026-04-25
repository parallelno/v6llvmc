; Verify O51: V6C LSR formula tie-breaker defaults to Regs-first
; (auto-dispatch) and can be forced via -v6c-lsr-strategy=regs-first.
;
; Regs-first keeps register pressure tight: the four-pointer axpy3 fits in
; a 10-byte static spill area (highest slot __v6c_ss.axpy3+8). The
; Insns-first shape would extend the area to 12 bytes by allocating
; __v6c_ss.axpy3+10 (see lsr-strategy-speed.ll for the opt-in path).
;
; RUN: llc -march=v6c -O2 -mv6c-static-stack < %s | FileCheck %s --check-prefix=AUTO
; RUN: llc -march=v6c -O2 -mv6c-static-stack -v6c-lsr-strategy=regs-first < %s | FileCheck %s --check-prefix=EXPLICIT

target datalayout = "e-p:16:8-i1:8-i8:8-i16:8-i32:8-i64:8-n8:16-S8"
target triple = "i8080-unknown-v6c"

define dso_local void @axpy3(ptr nocapture writeonly %0, ptr nocapture readonly %1, ptr nocapture readonly %2, ptr nocapture readonly %3, i16 %4) norecurse optsize {
  %6 = icmp eq i16 %4, 0
  br i1 %6, label %7, label %8

7:
  ret void

8:
  %9 = phi i16 [ %19, %8 ], [ 0, %5 ]
  %10 = getelementptr inbounds i16, ptr %1, i16 %9
  %11 = load i16, ptr %10, align 1
  %12 = getelementptr inbounds i16, ptr %2, i16 %9
  %13 = load i16, ptr %12, align 1
  %14 = add nsw i16 %13, %11
  %15 = getelementptr inbounds i16, ptr %3, i16 %9
  %16 = load i16, ptr %15, align 1
  %17 = add nsw i16 %14, %16
  %18 = getelementptr inbounds i16, ptr %0, i16 %9
  store i16 %17, ptr %18, align 1
  %19 = add nuw i16 %9, 1
  %20 = icmp eq i16 %19, %4
  br i1 %20, label %7, label %8
}

; Regs-first allocates a smaller spill area: highest slot is +8, total 10
; bytes. The +10 slot must NOT appear under either selection path.

; AUTO-LABEL: axpy3:
; AUTO-NOT:    __v6c_ss.axpy3+10
; AUTO:        .comm   __v6c_ss.axpy3,10,1

; EXPLICIT-LABEL: axpy3:
; EXPLICIT-NOT: __v6c_ss.axpy3+10
; EXPLICIT:     .comm   __v6c_ss.axpy3,10,1
