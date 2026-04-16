; RUN: llc -mtriple=i8080-unknown-v6c -filetype=obj -o %t.o %s
; RUN: not python %scripts/v6c_link.py %t.o -o %t.bin --base 0x0100 2>&1 | FileCheck %s

; Test: Undefined symbol detection.
; Linking a file that references an undefined function must produce an error.

; CHECK: Error: Undefined symbol 'nonexistent_func'

declare i8 @nonexistent_func()

define i8 @main() {
  %r = call i8 @nonexistent_func()
  ret i8 %r
}
