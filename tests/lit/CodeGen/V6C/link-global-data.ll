; RUN: llc -mtriple=i8080-unknown-v6c -filetype=obj -o %t_a.o %s
; RUN: llc -mtriple=i8080-unknown-v6c -filetype=obj -o %t_b.o %S/Inputs/link-global-data-b.ll
; RUN: python %S/../../../../scripts/v6c_link.py %t_a.o %t_b.o -o %t.bin --base 0x0100
; RUN: python -c "import sys; d=open(sys.argv[1],'rb').read(); print(len(d),'bytes'); assert len(d)>0" %t.bin

; Test: Cross-file global variable access. main.o reads a global defined in b.o.
; This tests 16-bit address relocations across objects.
; Success = linker exits 0 and produces non-empty binary.

@shared_val = external global i8

define i8 @main() {
  %v = load i8, ptr @shared_val
  ret i8 %v
}
