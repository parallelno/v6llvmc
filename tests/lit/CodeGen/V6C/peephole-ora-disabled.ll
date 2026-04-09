; RUN: llc -march=v6c -v6c-disable-zero-test-opt < %s | FileCheck %s

; When the zero-test opt is disabled, CPI 0 should remain.
; CHECK-LABEL: test_disabled:
; CHECK:       CPI 0
; CHECK-NOT:   ORA A
define i8 @test_disabled(i8 %a) {
entry:
  %c = icmp eq i8 %a, 0
  br i1 %c, label %then, label %else
then:
  ret i8 1
else:
  ret i8 0
}
