; RUN: llc -march=v6c -v6c-disable-peephole -v6c-disable-redundant-flag-elim < %s | FileCheck %s

; When both the peephole (O18) and redundant-flag-elim (O17) are disabled,
; ORA A should be preserved after DCR A (the ZeroTestOpt pass would have
; converted CPI 0 → ORA A, and nothing removes it).

target datalayout = "e-p:16:8-i1:8-i8:8-i16:8-i32:8-i64:8-n8:16-S8"
target triple = "i8080-unknown-v6c"

@g_out = external global i8

; CHECK-LABEL: test_decr_loop:
; CHECK:       DCR A
; CHECK-NEXT:  ORA A
; CHECK-NEXT:  JNZ
define void @test_decr_loop(i8 %n) {
entry:
  %cmp = icmp eq i8 %n, 0
  br i1 %cmp, label %exit, label %loop

loop:
  %i = phi i8 [ %n, %entry ], [ %dec, %loop ]
  store volatile i8 %i, ptr @g_out
  %dec = add i8 %i, -1
  %done = icmp eq i8 %dec, 0
  br i1 %done, label %exit, label %loop

exit:
  ret void
}
