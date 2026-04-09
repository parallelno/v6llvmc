// RUN: clang -target i8080-unknown-v6c -S %s -o - | FileCheck %s
//
// Verify that Clang can compile a simple C function down to V6C assembly.

int add(int a, int b) {
  return a + b;
}
// CHECK: add:
// CHECK: RET
