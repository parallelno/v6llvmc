// RUN: clang -target i8080-unknown-v6c -S -emit-llvm %s -o - | FileCheck %s
//
// Verify that V6C target-specific builtins lower to the correct LLVM
// intrinsics.

void test_di(void) {
// CHECK-LABEL: @test_di
// CHECK: call void @llvm.v6c.di()
    __builtin_v6c_di();
}

void test_ei(void) {
// CHECK-LABEL: @test_ei
// CHECK: call void @llvm.v6c.ei()
    __builtin_v6c_ei();
}

void test_hlt(void) {
// CHECK-LABEL: @test_hlt
// CHECK: call void @llvm.v6c.hlt()
    __builtin_v6c_hlt();
}

void test_nop(void) {
// CHECK-LABEL: @test_nop
// CHECK: call void @llvm.v6c.nop()
    __builtin_v6c_nop();
}

unsigned char test_in(void) {
// CHECK-LABEL: @test_in
// CHECK: call i8 @llvm.v6c.in(i8 16)
    return __builtin_v6c_in(0x10);
}

void test_out(unsigned char val) {
// CHECK-LABEL: @test_out
// CHECK: call void @llvm.v6c.out(i8 32, i8
    __builtin_v6c_out(0x20, val);
}
