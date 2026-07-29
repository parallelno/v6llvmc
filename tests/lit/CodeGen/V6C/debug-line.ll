; RUN: llc -mtriple=i8080-unknown-v6c -filetype=obj -o %t.o %s
; RUN: llvm-readelf -S %t.o | FileCheck %s
; RUN: llvm-readelf -r %t.o | FileCheck %s --check-prefix=RELOC
; RUN: lld -flavor gnu -m elf32v6c -e answer -o %t.elf %t.o
; RUN: llvm-readelf -S %t.elf | FileCheck %s --check-prefix=LINKED
; RUN: llvm-readelf -r %t.elf | FileCheck %s --check-prefix=LINKED-RELOC

; CHECK-DAG: .debug_info
; CHECK-DAG: .debug_abbrev
; CHECK-DAG: .debug_line
; CHECK-DAG: .debug_str

; RELOC: Relocation section '.rela.debug_info'
; RELOC: 00000016{{.*}}00000505

; LINKED-DAG: .debug_info
; LINKED-DAG: .debug_abbrev
; LINKED-DAG: .debug_line
; LINKED-DAG: .debug_str

; LINKED-RELOC: There are no relocations in this file.

target datalayout = "e-p:16:8-i1:8-i8:8-i16:8-i32:8-i64:8-n8:16-S8"
target triple = "i8080-unknown-v6c"

define i8 @answer() !dbg !10 {
entry:
  ret i8 42, !dbg !13
}

!llvm.dbg.cu = !{!0}
!llvm.module.flags = !{!6, !7}
!0 = distinct !DICompileUnit(language: DW_LANG_C11, file: !1, producer: "V6C test", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
!1 = !DIFile(filename: "debug-line.c", directory: "/")
!6 = !{i32 2, !"Dwarf Version", i32 4}
!7 = !{i32 2, !"Debug Info Version", i32 3}
!10 = distinct !DISubprogram(name: "answer", scope: !1, file: !1, line: 1, type: !11, scopeLine: 1, spFlags: DISPFlagDefinition, unit: !0)
!11 = !DISubroutineType(types: !12)
!12 = !{!14}
!13 = !DILocation(line: 2, column: 3, scope: !10)
!14 = !DIBasicType(name: "char", size: 8, encoding: DW_ATE_signed_char)