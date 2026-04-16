; RUN: llc -mtriple=i8080-unknown-v6c -filetype=obj -o %t.o %s
; RUN: python %scripts/v6c_link.py %t.o -o %t.bin --base 0x0100 --map %t.map
; RUN: FileCheck %s < %t.map

; Test: Memory map output and section ordering.
; Sections must appear in order: .text, .rodata, .data, .bss

; CHECK: Sections:
; CHECK: .text
; CHECK: .data

target datalayout = "e-p:16:8-i1:8-i8:8-i16:8-i32:8-i64:8-n8:16-S8"
target triple = "i8080-unknown-v6c"

@mydata = global i8 77

define i8 @main() {
  %v = load i8, ptr @mydata
  ret i8 %v
}
