target datalayout = "e-p:16:8-i1:8-i8:8-i16:8-i32:8-i64:8-n8:16-S8"
target triple = "i8080-unknown-v6c"

define i8 @_start() section ".text.start" !dbg !10 {
entry:
  %value = call i8 @live(), !dbg !13
  ret i8 %value, !dbg !14
}

define i8 @live() section ".text.live" !dbg !15 {
entry:
  ret i8 42, !dbg !16
}

!llvm.dbg.cu = !{!0}
!llvm.module.flags = !{!6, !7}
!0 = distinct !DICompileUnit(language: DW_LANG_C11, file: !1, producer: "V6C test", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
!1 = !DIFile(filename: "live.c", directory: "/")
!6 = !{i32 2, !"Dwarf Version", i32 4}
!7 = !{i32 2, !"Debug Info Version", i32 3}
!10 = distinct !DISubprogram(name: "_start", scope: !1, file: !1, line: 1, type: !11, scopeLine: 1, spFlags: DISPFlagDefinition, unit: !0)
!11 = !DISubroutineType(types: !12)
!12 = !{!17}
!13 = !DILocation(line: 2, column: 3, scope: !10)
!14 = !DILocation(line: 3, column: 3, scope: !10)
!15 = distinct !DISubprogram(name: "live", scope: !1, file: !1, line: 5, type: !11, scopeLine: 5, spFlags: DISPFlagDefinition, unit: !0)
!16 = !DILocation(line: 6, column: 3, scope: !15)
!17 = !DIBasicType(name: "char", size: 8, encoding: DW_ATE_signed_char)

