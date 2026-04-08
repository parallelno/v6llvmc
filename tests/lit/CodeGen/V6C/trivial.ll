; RUN: llc -march=v6c -o - %s | FileCheck %s
; M3 test: trivial function emits valid assembly with RET.

target datalayout = "e-p:16:8-i1:8-i8:8-i16:8-i32:8-i64:8-n8:16-S8"
target triple = "i8080-unknown-v6c"

; CHECK-LABEL: empty:
; CHECK: RET
define void @empty() {
  ret void
}
