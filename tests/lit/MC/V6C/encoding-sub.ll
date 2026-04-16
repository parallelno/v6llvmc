; RUN: llc -march=v6c -mtriple=i8080-unknown-v6c -filetype=obj %s -o %t.o
; RUN: python %scripts/elf_text_hex.py %t.o | FileCheck %s

; Test all ALU reg operations: i8 a op i8 b → answer in A
; SUB E (0x93) + RET (0xC9)
; CHECK: 93 C9
define i8 @sub(i8 %a, i8 %b) {
  %c = sub i8 %a, %b
  ret i8 %c
}
