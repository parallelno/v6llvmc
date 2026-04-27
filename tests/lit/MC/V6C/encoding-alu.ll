; RUN: llc -march=v6c -mtriple=i8080-unknown-v6c -filetype=obj %s -o %t.o
; RUN: python %scripts/elf_text_hex.py %t.o | FileCheck %s

; ADD B (0x80) + RET (0xC9)
; CHECK: 80 C9
define i8 @add(i8 %a, i8 %b) {
  %c = add i8 %a, %b
  ret i8 %c
}
