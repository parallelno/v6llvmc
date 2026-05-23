; ModuleID = 'samples\03_demo\main.c'
source_filename = "samples\\03_demo\\main.c"
target datalayout = "e-p:16:8-i1:8-i8:8-i16:8-i32:8-i64:8-n8:16-S8"
target triple = "i8080-unknown-v6c"

@__v6c_rand_state = dso_local local_unnamed_addr global i16 1, align 1
@font = dso_local local_unnamed_addr global <{ [63 x i8], [193 x i8] }> <{ [63 x i8] c"\00\18$B~BB\00\00|B|BB|\00\00<B@@B<\00\00xDBBDx\00\00~@|@@~\00\00~@|@@@\00\00<B@NB<\00\00BB~BBB", [193 x i8] zeroinitializer }>, align 1
@BIT_MASK = dso_local local_unnamed_addr constant [8 x i8] c"\80@ \10\08\04\02\01", align 1
@palette = dso_local local_unnamed_addr global [16 x i8] c"\00\11\223DUfw\88\99\AA\BB\CC\DD\EE\FF", align 1
@pos = dso_local local_unnamed_addr global [16 x i8] c"\FF\FE\FF\FA\FF\C8\FF\8C\FF\7F\FFd\FF(\FF\00", align 1
@llvm.compiler.used = appending global [15 x ptr] [ptr @__ashlhi3, ptr @__ashrhi3, ptr @__divhi3, ptr @__divmodhi4, ptr @__lshrhi3, ptr @__modhi3, ptr @__mulhi3, ptr @__mulqi3, ptr @__udivhi3, ptr @__udivmodhi4, ptr @__umodhi3, ptr @__v6c_mulqihi3, ptr @__v6c_neg_de_body, ptr @__v6c_neg_hl_body, ptr @__v6c_udivmod16_body], section "llvm.metadata"

; Function Attrs: naked noinline nounwind
define internal i8 @__mulqi3(i8 noundef %0, i8 noundef %1) #0 {
  tail call void asm sideeffect "MOV  E, B           \0A\09MVI  D, 0           \0A\09LXI  H, 0           \0A\09MVI  B, 8           \0A1:                  \0A\09DAD  H              \0A\09RLC                 \0A\09JNC  2f             \0A\09DAD  D              \0A2:                  \0A\09DCR  B              \0A\09JNZ  1b             \0A\09MOV  A, L           \0A\09RET                 \0A\09", ""() #4, !srcloc !2
  unreachable
}

; Function Attrs: naked noinline nounwind
define internal i16 @__v6c_mulqihi3(i8 noundef %0, i8 noundef %1) #0 {
  tail call void asm sideeffect "MOV  E, B           \0A\09MVI  D, 0           \0A\09LXI  H, 0           \0A\09MVI  B, 8           \0A1:                  \0A\09DAD  H              \0A\09RLC                 \0A\09JNC  2f             \0A\09DAD  D              \0A2:                  \0A\09DCR  B              \0A\09JNZ  1b             \0A\09RET                 \0A\09", ""() #4, !srcloc !3
  unreachable
}

; Function Attrs: naked noinline nounwind
define internal i16 @__mulhi3(i16 noundef %0, i16 noundef %1) #0 {
  tail call void asm sideeffect "XCHG                \0A\09MOV  A, H           \0A\09MOV  C, L           \0A\09LXI  H, 0           \0A\09MVI  B, 8           \0A1:                  \0A\09DAD  H              \0A\09RLC                 \0A\09JNC  2f             \0A\09DAD  D              \0A2:                  \0A\09DCR  B              \0A\09JNZ  1b             \0A\09MOV  A, C           \0A\09MVI  B, 8           \0A3:                  \0A\09DAD  H              \0A\09RLC                 \0A\09JNC  4f             \0A\09DAD  D              \0A4:                  \0A\09DCR  B              \0A\09JNZ  3b             \0A\09RET                 \0A\09", ""() #4, !srcloc !4
  unreachable
}

; Function Attrs: naked noinline nounwind
define internal void @__v6c_udivmod16_body() #0 {
  tail call void asm sideeffect "MOV  A, D           \0A\09ORA  E              \0A\09JNZ  1f             \0A\09LXI  H, 0xFFFF      \0A\09LXI  B, 0           \0A\09RET                 \0A1:                  \0A\09LXI  B, 0           \0A\09MVI  A, 16          \0A\09PUSH PSW            \0A2:                  \0A\09DAD  H              \0A\09MOV  A, C           \0A\09RAL                 \0A\09MOV  C, A           \0A\09MOV  A, B           \0A\09RAL                 \0A\09MOV  B, A           \0A\09MOV  A, C           \0A\09SUB  E              \0A\09MOV  A, B           \0A\09SBB  D              \0A\09JC   3f             \0A\09MOV  A, C           \0A\09SUB  E              \0A\09MOV  C, A           \0A\09MOV  A, B           \0A\09SBB  D              \0A\09MOV  B, A           \0A\09INX  H              \0A3:                  \0A\09POP  PSW            \0A\09DCR  A              \0A\09PUSH PSW            \0A\09JNZ  2b             \0A\09POP  PSW            \0A\09RET                 \0A\09", ""() #4, !srcloc !5
  unreachable
}

; Function Attrs: naked noinline nounwind
define internal i16 @__udivhi3(i16 noundef %0, i16 noundef %1) #0 {
  tail call void asm sideeffect "CALL __v6c_udivmod16_body \0A\09RET                       \0A\09", ""() #4, !srcloc !6
  unreachable
}

; Function Attrs: naked noinline nounwind
define internal i16 @__umodhi3(i16 noundef %0, i16 noundef %1) #0 {
  tail call void asm sideeffect "CALL __v6c_udivmod16_body \0A\09MOV  H, B                 \0A\09MOV  L, C                 \0A\09RET                       \0A\09", ""() #4, !srcloc !7
  unreachable
}

; Function Attrs: naked noinline nounwind
define internal i16 @__udivmodhi4(i16 noundef %0, i16 noundef %1, ptr noundef %2) #0 {
  tail call void asm sideeffect "PUSH B                    \0A\09CALL __v6c_udivmod16_body \0A\09XTHL                      \0A\09MOV  M, C                 \0A\09INX  H                    \0A\09MOV  M, B                 \0A\09POP  H                    \0A\09RET                       \0A\09", ""() #4, !srcloc !8
  unreachable
}

; Function Attrs: naked noinline nounwind
define internal i16 @__divmodhi4(i16 noundef %0, i16 noundef %1, ptr noundef %2) #0 {
  tail call void asm sideeffect "PUSH B                     \0A\09MOV  A, H                  \0A\09PUSH PSW                   \0A\09MOV  A, H                  \0A\09XRA  D                     \0A\09PUSH PSW                   \0A\09MOV  A, H                  \0A\09ORA  A                     \0A\09JP   1f                    \0A\09CALL __v6c_neg_hl_body     \0A1:                         \0A\09MOV  A, D                  \0A\09ORA  A                     \0A\09JP   2f                    \0A\09CALL __v6c_neg_de_body     \0A2:                         \0A\09CALL __v6c_udivmod16_body  \0A\09POP  PSW                   \0A\09ORA  A                     \0A\09JP   3f                    \0A\09CALL __v6c_neg_hl_body     \0A3:                         \0A\09POP  PSW                   \0A\09ORA  A                     \0A\09JP   4f                    \0A\09MOV  A, C                  \0A\09CMA                        \0A\09MOV  C, A                  \0A\09MOV  A, B                  \0A\09CMA                        \0A\09MOV  B, A                  \0A\09INX  B                     \0A4:                         \0A\09XTHL                       \0A\09MOV  M, C                  \0A\09INX  H                     \0A\09MOV  M, B                  \0A\09POP  H                     \0A\09RET                        \0A\09", ""() #4, !srcloc !9
  unreachable
}

; Function Attrs: naked noinline nounwind
define internal void @__v6c_neg_hl_body() #0 {
  tail call void asm sideeffect "MOV  A, L           \0A\09CMA                 \0A\09MOV  L, A           \0A\09MOV  A, H           \0A\09CMA                 \0A\09MOV  H, A           \0A\09INX  H              \0A\09RET                 \0A\09", ""() #4, !srcloc !10
  unreachable
}

; Function Attrs: naked noinline nounwind
define internal void @__v6c_neg_de_body() #0 {
  tail call void asm sideeffect "MOV  A, E           \0A\09CMA                 \0A\09MOV  E, A           \0A\09MOV  A, D           \0A\09CMA                 \0A\09MOV  D, A           \0A\09INX  D              \0A\09RET                 \0A\09", ""() #4, !srcloc !11
  unreachable
}

; Function Attrs: naked noinline nounwind
define internal i16 @__divhi3(i16 noundef %0, i16 noundef %1) #0 {
  tail call void asm sideeffect "MOV  A, H                  \0A\09XRA  D                     \0A\09PUSH PSW                   \0A\09MOV  A, H                  \0A\09ORA  A                     \0A\09JP   1f                    \0A\09CALL __v6c_neg_hl_body     \0A1:                         \0A\09MOV  A, D                  \0A\09ORA  A                     \0A\09JP   2f                    \0A\09CALL __v6c_neg_de_body     \0A2:                         \0A\09CALL __v6c_udivmod16_body  \0A\09POP  PSW                   \0A\09ORA  A                     \0A\09JP   3f                    \0A\09CALL __v6c_neg_hl_body     \0A3:                         \0A\09RET                        \0A\09", ""() #4, !srcloc !12
  unreachable
}

; Function Attrs: naked noinline nounwind
define internal i16 @__modhi3(i16 noundef %0, i16 noundef %1) #0 {
  tail call void asm sideeffect "MOV  A, H                  \0A\09PUSH PSW                   \0A\09ORA  A                     \0A\09JP   1f                    \0A\09CALL __v6c_neg_hl_body     \0A1:                         \0A\09MOV  A, D                  \0A\09ORA  A                     \0A\09JP   2f                    \0A\09CALL __v6c_neg_de_body     \0A2:                         \0A\09CALL __v6c_udivmod16_body  \0A\09MOV  H, B                  \0A\09MOV  L, C                  \0A\09POP  PSW                   \0A\09ORA  A                     \0A\09JP   3f                    \0A\09CALL __v6c_neg_hl_body     \0A3:                         \0A\09RET                        \0A\09", ""() #4, !srcloc !13
  unreachable
}

; Function Attrs: naked noinline nounwind
define internal i16 @__ashlhi3(i16 noundef %0, i8 noundef %1) #0 {
  tail call void asm sideeffect "MOV  A, E           \0A\09ANI  0x0F           \0A\09JZ   2f             \0A\09CPI  16             \0A\09JNC  3f             \0A\09MOV  E, A           \0A1:                  \0A\09DAD  H              \0A\09DCR  E              \0A\09JNZ  1b             \0A2:                  \0A\09RET                 \0A3:                  \0A\09LXI  H, 0           \0A\09RET                 \0A\09", ""() #4, !srcloc !14
  unreachable
}

; Function Attrs: naked noinline nounwind
define internal i16 @__lshrhi3(i16 noundef %0, i8 noundef %1) #0 {
  tail call void asm sideeffect "MOV  A, E           \0A\09ANI  0x0F           \0A\09JZ   2f             \0A\09CPI  16             \0A\09JNC  3f             \0A\09MOV  E, A           \0A1:                  \0A\09ORA  A              \0A\09MOV  A, H           \0A\09RAR                 \0A\09MOV  H, A           \0A\09MOV  A, L           \0A\09RAR                 \0A\09MOV  L, A           \0A\09DCR  E              \0A\09JNZ  1b             \0A2:                  \0A\09RET                 \0A3:                  \0A\09LXI  H, 0           \0A\09RET                 \0A\09", ""() #4, !srcloc !15
  unreachable
}

; Function Attrs: naked noinline nounwind
define internal i16 @__ashrhi3(i16 noundef %0, i8 noundef %1) #0 {
  tail call void asm sideeffect "MOV  A, E           \0A\09ANI  0x0F           \0A\09JZ   2f             \0A\09CPI  16             \0A\09JNC  3f             \0A\09MOV  E, A           \0A1:                  \0A\09MOV  A, H           \0A\09RAL                 \0A\09MOV  A, H           \0A\09RAR                 \0A\09MOV  H, A           \0A\09MOV  A, L           \0A\09RAR                 \0A\09MOV  L, A           \0A\09DCR  E              \0A\09JNZ  1b             \0A2:                  \0A\09RET                 \0A3:                  \0A\09MOV  A, H           \0A\09RAL                 \0A\09SBB  A              \0A\09MOV  H, A           \0A\09MOV  L, A           \0A\09RET                 \0A\09", ""() #4, !srcloc !16
  unreachable
}

; Function Attrs: nofree norecurse nosync nounwind memory(readwrite, inaccessiblemem: none)
define dso_local void @main() local_unnamed_addr #1 {
  br label %2

1:                                                ; preds = %2
  ret void

2:                                                ; preds = %0, %2
  %3 = phi i16 [ 0, %0 ], [ %10, %2 ]
  %4 = shl nuw nsw i16 %3, 1
  %5 = getelementptr inbounds [16 x i8], ptr @pos, i16 0, i16 %4
  %6 = load i8, ptr %5, align 1, !tbaa !17
  %7 = or disjoint i16 %4, 1
  %8 = getelementptr inbounds [16 x i8], ptr @pos, i16 0, i16 %7
  %9 = load i8, ptr %8, align 1, !tbaa !17
  tail call fastcc void @draw_line(i8 noundef %6, i8 noundef %9) #5
  %10 = add nuw nsw i16 %3, 1
  %11 = icmp eq i16 %10, 8
  br i1 %11, label %1, label %2, !llvm.loop !20
}

; Function Attrs: nofree noinline norecurse nosync nounwind memory(readwrite, inaccessiblemem: none)
define internal fastcc void @draw_line(i8 noundef %0, i8 noundef %1) unnamed_addr #2 {
  %3 = zext i8 %0 to i16
  %4 = icmp ult i8 %0, 127
  br i1 %4, label %5, label %7

5:                                                ; preds = %2
  %6 = xor i16 %3, 127
  br label %9

7:                                                ; preds = %2
  %8 = add nsw i16 %3, -127
  br label %9

9:                                                ; preds = %7, %5
  %10 = phi i16 [ %6, %5 ], [ %8, %7 ]
  %11 = zext i8 %1 to i16
  %12 = icmp ult i8 %1, 127
  br i1 %12, label %13, label %15

13:                                               ; preds = %9
  %14 = add nsw i16 %11, -127
  br label %17

15:                                               ; preds = %9
  %16 = sub nsw i16 127, %11
  br label %17

17:                                               ; preds = %15, %13
  %18 = phi i16 [ %14, %13 ], [ %16, %15 ]
  %19 = icmp sgt i8 %0, -1
  %20 = select i1 %19, i8 -1, i8 1
  %21 = icmp sgt i8 %1, -1
  %22 = select i1 %21, i8 -1, i8 1
  tail call fastcc void @draw_pixel(i8 noundef 127, i8 noundef 127) #5
  %23 = icmp eq i8 %0, 127
  %24 = icmp eq i8 %1, 127
  %25 = and i1 %24, %23
  br i1 %25, label %50, label %26

26:                                               ; preds = %17
  %27 = add nsw i16 %18, %10
  br label %28

28:                                               ; preds = %26, %44
  %29 = phi i8 [ %39, %44 ], [ 127, %26 ]
  %30 = phi i16 [ %46, %44 ], [ %27, %26 ]
  %31 = phi i8 [ %45, %44 ], [ 127, %26 ]
  %32 = shl nsw i16 %30, 1
  %33 = icmp slt i16 %32, %18
  br i1 %33, label %37, label %34

34:                                               ; preds = %28
  %35 = add nsw i16 %30, %18
  %36 = add i8 %29, %20
  br label %37

37:                                               ; preds = %34, %28
  %38 = phi i16 [ %35, %34 ], [ %30, %28 ]
  %39 = phi i8 [ %36, %34 ], [ %29, %28 ]
  %40 = icmp sgt i16 %32, %10
  br i1 %40, label %44, label %41

41:                                               ; preds = %37
  %42 = add nsw i16 %38, %10
  %43 = add i8 %31, %22
  br label %44

44:                                               ; preds = %41, %37
  %45 = phi i8 [ %43, %41 ], [ %31, %37 ]
  %46 = phi i16 [ %42, %41 ], [ %38, %37 ]
  tail call fastcc void @draw_pixel(i8 noundef %39, i8 noundef %45) #5
  %47 = icmp eq i8 %39, %0
  %48 = icmp eq i8 %45, %1
  %49 = and i1 %48, %47
  br i1 %49, label %50, label %28

50:                                               ; preds = %44, %17
  ret void
}

; Function Attrs: mustprogress nofree noinline norecurse nosync nounwind willreturn memory(readwrite, inaccessiblemem: none)
define internal fastcc void @draw_pixel(i8 noundef %0, i8 noundef %1) unnamed_addr #3 {
  %3 = lshr i8 %0, 3
  %4 = zext nneg i8 %3 to i16
  %5 = shl nuw nsw i16 %4, 8
  %6 = zext i8 %1 to i16
  %7 = or disjoint i16 %5, %6
  %8 = and i8 %0, 7
  %9 = xor i8 %8, 7
  %10 = shl nuw i8 1, %9
  %11 = getelementptr inbounds i8, ptr inttoptr (i16 -32768 to ptr), i16 %7
  %12 = load i8, ptr %11, align 1, !tbaa !17
  %13 = or i8 %12, %10
  store i8 %13, ptr %11, align 1, !tbaa !17
  ret void
}

attributes #0 = { naked noinline nounwind "no-builtins" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "v6c-rt-helper" }
attributes #1 = { nofree norecurse nosync nounwind memory(readwrite, inaccessiblemem: none) "no-builtins" "no-trapping-math"="true" "stack-protector-buffer-size"="8" }
attributes #2 = { nofree noinline norecurse nosync nounwind memory(readwrite, inaccessiblemem: none) "no-builtins" "no-trapping-math"="true" "stack-protector-buffer-size"="8" }
attributes #3 = { mustprogress nofree noinline norecurse nosync nounwind willreturn memory(readwrite, inaccessiblemem: none) "no-builtins" "no-trapping-math"="true" "stack-protector-buffer-size"="8" }
attributes #4 = { nounwind }
attributes #5 = { nobuiltin "no-builtins" }

!llvm.module.flags = !{!0}
!llvm.ident = !{!1}

!0 = !{i32 1, !"wchar_size", i32 2}
!1 = !{!"clang version 18.1.0rc (https://github.com/llvm/llvm-project.git 461274b81d8641eab64d494accddc81d7db8a09e)"}
!2 = !{i64 16067, i64 16090, i64 16159, i64 16229, i64 16324, i64 16346, i64 16382, i64 16439, i64 16502, i64 16578, i64 16600, i64 16636, i64 16672, i64 16708, i64 16773}
!3 = !{i64 17368, i64 17391, i64 17427, i64 17463, i64 17511, i64 17533, i64 17569, i64 17605, i64 17641, i64 17689, i64 17711, i64 17747, i64 17783, i64 17819}
!4 = !{i64 18383, i64 18406, i64 18482, i64 18547, i64 18619, i64 18691, i64 18713, i64 18775, i64 18811, i64 18847, i64 18895, i64 18917, i64 18953, i64 18989, i64 19025, i64 19101, i64 19123, i64 19184, i64 19220, i64 19256, i64 19304, i64 19326, i64 19362, i64 19398, i64 19434}
!5 = !{i64 20046, i64 20069, i64 20105, i64 20141, i64 20177, i64 20213, i64 20261, i64 20283, i64 20319, i64 20377, i64 20448, i64 20470, i64 20519, i64 20605, i64 20641, i64 20721, i64 20757, i64 20793, i64 20829, i64 20907, i64 20943, i64 20979, i64 21015, i64 21051, i64 21186, i64 21222, i64 21258, i64 21294, i64 21330, i64 21366, i64 21441, i64 21463, i64 21499, i64 21535, i64 21571, i64 21607, i64 21643, i64 21703}
!6 = !{i64 22072, i64 22101, i64 22143}
!7 = !{i64 22511, i64 22540, i64 22582, i64 22624, i64 22666}
!8 = !{i64 23388, i64 23417, i64 23485, i64 23546, i64 23610, i64 23677, i64 23719, i64 23787, i64 23851}
!9 = !{i64 24426, i64 24456, i64 24525, i64 24568, i64 24643, i64 24686, i64 24729, i64 24810, i64 24853, i64 24896, i64 24951, i64 24980, i64 25023, i64 25066, i64 25109, i64 25164, i64 25193, i64 25236, i64 25337, i64 25380, i64 25423, i64 25478, i64 25507, i64 25614, i64 25657, i64 25700, i64 25778, i64 25821, i64 25864, i64 25907, i64 25950, i64 25993, i64 26048, i64 26077, i64 26120, i64 26185, i64 26228, i64 26271, i64 26314, i64 26386}
!10 = !{i64 26717, i64 26740, i64 26776, i64 26812, i64 26848, i64 26884, i64 26920, i64 26956, i64 26992}
!11 = !{i64 27323, i64 27346, i64 27382, i64 27418, i64 27454, i64 27490, i64 27526, i64 27562, i64 27598}
!12 = !{i64 27972, i64 28002, i64 28045, i64 28128, i64 28171, i64 28214, i64 28257, i64 28312, i64 28341, i64 28384, i64 28427, i64 28470, i64 28525, i64 28554, i64 28597, i64 28640, i64 28683, i64 28726, i64 28781, i64 28810, i64 28853}
!13 = !{i64 29270, i64 29300, i64 29343, i64 29413, i64 29456, i64 29511, i64 29540, i64 29583, i64 29626, i64 29669, i64 29724, i64 29753, i64 29796, i64 29839, i64 29882, i64 29925, i64 29968, i64 30011, i64 30066, i64 30095, i64 30138}
!14 = !{i64 30543, i64 30566, i64 30602, i64 30638, i64 30674, i64 30710, i64 30758, i64 30780, i64 30816, i64 30852, i64 30900, i64 30922, i64 30970, i64 30992, i64 31028, i64 31064}
!15 = !{i64 31428, i64 31451, i64 31487, i64 31523, i64 31559, i64 31595, i64 31643, i64 31665, i64 31701, i64 31757, i64 31793, i64 31829, i64 31865, i64 31901, i64 31937, i64 31973, i64 32021, i64 32043, i64 32091, i64 32113, i64 32149, i64 32185}
!16 = !{i64 32553, i64 32576, i64 32612, i64 32648, i64 32684, i64 32720, i64 32768, i64 32790, i64 32826, i64 32862, i64 32921, i64 32957, i64 33036, i64 33072, i64 33108, i64 33144, i64 33180, i64 33228, i64 33250, i64 33298, i64 33320, i64 33387, i64 33423, i64 33459, i64 33528, i64 33564, i64 33600}
!17 = !{!18, !18, i64 0}
!18 = !{!"omnipotent char", !19, i64 0}
!19 = !{!"Simple C/C++ TBAA"}
!20 = distinct !{!20, !21}
!21 = !{!"llvm.loop.mustprogress"}
