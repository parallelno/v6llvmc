; RUN: llc -march=v6c -mtriple=i8080-unknown-v6c -filetype=obj %s -o %t.o
; RUN: python %S/../../../../scripts/elf_text_hex.py %t.o | FileCheck %s

; Branch encoding test: conditional branch uses JNZ/JZ (3-byte) with address fixups.
; The .text section bytes will have branch targets as relocations (zeros before linking).
; We verify the opcodes are correct.

; ORA A = B7 (zero-test optimization replaces CPI 0x00 with ORA A)
; JZ = CA xx xx (branch-opt inverts JNZ+JMP into JZ, eliminating JMP)
; MVI A, 0x01 = 3E 01
; RET = C9
; MVI A, 0x02 = 3E 02
; RET = C9

; Verify opcodes: ORA_A(B7), JZ(CA), MVI(3E) 02, RET(C9), MVI(3E) 01, RET(C9)
; Branch addresses are zero (unresolved relocations in .o file)
; Branch-opt inverted the conditional and removed the unconditional JMP.
; CHECK: B7 CA 00 00 3E 02 C9 3E 01 C9
define i8 @branch(i8 %x) {
entry:
  %cmp = icmp eq i8 %x, 0
  br i1 %cmp, label %then, label %else

then:
  ret i8 1

else:
  ret i8 2
}
