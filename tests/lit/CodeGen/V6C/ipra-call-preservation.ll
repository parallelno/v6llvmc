; RUN: llc -march=v6c -O2 < %s | FileCheck %s --check-prefix=IPRA
; RUN: llc -march=v6c -O2 -enable-ipra=false < %s | FileCheck %s --check-prefix=NOIPRA

target datalayout = "e-p:16:8-i1:8-i8:8-i16:8-i32:8-i64:8-n8:16-S8"
target triple = "i8080-unknown-v6c"

@sink = global i16 0, align 1

define void @action_b() {
entry:
  store volatile i16 2, ptr @sink, align 1
  ret void
}

declare void @extern_action()

define i16 @test_external(i16 returned %x) {
entry:
  call void @extern_action()
  call void @action_b()
  ret i16 %x
}

define i16 @test_direct(i16 returned %x) {
entry:
  call void @action_b()
  ret i16 %x
}

; IPRA-LABEL: test_external:
; The extern_action call's clobbers are unknown, so %x is spilled to
; stack. HL holds the live %x at entry; XCHG (1B/4cc) parks it in DE
; before the frame-setup `LXI H, 0xfffe` overwrites HL. (Previously
; the backend used `MOV D, H; MOV E, L` here — 2B/10cc — XCHG is
; strictly better and HL is dead-on-entry to the LXI.)
; IPRA:       XCHG
; IPRA-NEXT:  LXI H, 0xfffe
; IPRA:       CALL extern_action
; IPRA-NEXT:  CALL action_b
; IPRA:       MOV E, M
; IPRA:       MOV D, M

; IPRA-LABEL: test_direct:
; IPRA:       MOV D, H
; IPRA-NEXT:  MOV E, L
; IPRA-NEXT:  CALL action_b
; IPRA-NEXT:  XCHG
; IPRA-NEXT:  RET
; IPRA-NOT:   LXI H, 0xfffe
; IPRA-NOT:   PUSH D

; NOIPRA-LABEL: test_external:
; NOIPRA:       XCHG
; NOIPRA-NEXT:  LXI H, 0xfffe
; NOIPRA:       CALL extern_action
; NOIPRA-NEXT:  CALL action_b
; NOIPRA:       MOV E, M
; NOIPRA:       MOV D, M

; NOIPRA-LABEL: test_direct:
; NOIPRA:       XCHG
; NOIPRA-NEXT:  LXI H, 0xfffe
; NOIPRA:       CALL action_b
; NOIPRA:       MOV E, M
; NOIPRA:       MOV D, M