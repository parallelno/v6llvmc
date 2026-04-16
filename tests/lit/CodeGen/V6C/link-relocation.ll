; RUN: llc -mtriple=i8080-unknown-v6c -filetype=obj -o %t_main.o %s
; RUN: llc -mtriple=i8080-unknown-v6c -filetype=obj -o %t_helper.o %S/Inputs/link-helper.ll
; RUN: python %scripts/v6c_link.py %t_main.o %t_helper.o -o %t_0100.bin --base 0x0100
; RUN: python %scripts/v6c_link.py %t_main.o %t_helper.o -o %t_8000.bin --base 0x8000
; RUN: python -c "import sys; open(sys.argv[2],'w').write(' '.join(f'{b:02X}' for b in open(sys.argv[1],'rb').read()))" %t_0100.bin %t_0100.hex
; RUN: python -c "import sys; open(sys.argv[2],'w').write(' '.join(f'{b:02X}' for b in open(sys.argv[1],'rb').read()))" %t_8000.bin %t_8000.hex
; RUN: not diff %t_0100.hex %t_8000.hex

; Test: Start address relocation.
; The same program linked at base 0x0100 and 0x8000 must produce different
; binaries (because CALL addresses are relocated).
; The 'not diff' checks the files are different.

declare i8 @helper(i8 %x)

define i8 @main() {
  %r = call i8 @helper(i8 7)
  ret i8 %r
}
