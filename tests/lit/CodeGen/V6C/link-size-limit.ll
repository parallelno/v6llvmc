; RUN: llc -mtriple=i8080-unknown-v6c -filetype=obj -o %t.o %s
; RUN: not python %scripts/v6c_link.py %t.o -o %t.bin --base 0xFFFE 2>&1 | FileCheck %s

; Test: Size validation — program at base 0xFFFE with code exceeding 64KB.
; The linker must reject this with an error.

; CHECK: Error: Output exceeds 64KB address space

target datalayout = "e-p:16:8-i1:8-i8:8-i16:8-i32:8-i64:8-n8:16-S8"
target triple = "i8080-unknown-v6c"

define i8 @main() {
  ret i8 0
}
