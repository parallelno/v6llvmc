; RUN: llc -mtriple=i8080-unknown-v6c -filetype=obj -o %t_main.o %s
; RUN: llc -mtriple=i8080-unknown-v6c -filetype=obj -o %t_helper.o %S/Inputs/link-helper.ll
; RUN: python %S/../../../../scripts/v6c_link.py %t_main.o %t_helper.o -o %t.bin --base 0x0100
; RUN: python -c "import sys; d=open(sys.argv[1],'rb').read(); print(len(d),'bytes'); assert len(d)>0" %t.bin

; Test: Cross-file function call. main.o calls helper() defined in helper.o.
; The linker must resolve the cross-object symbol reference.
; Success = linker exits 0 and produces non-empty binary.

declare i8 @helper(i8 %x)

define i8 @main() {
  %r = call i8 @helper(i8 42)
  ret i8 %r
}
