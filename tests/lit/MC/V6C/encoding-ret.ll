; RUN: llc -march=v6c -mtriple=i8080-unknown-v6c -filetype=obj %s -o %t.o
; RUN: python %S/../../../../scripts/elf_text_hex.py %t.o | FileCheck %s

; Test 1-byte RET encoding (0xC9)
; CHECK: 3E 2A C9
define i8 @ret42() {
  ret i8 42
}
