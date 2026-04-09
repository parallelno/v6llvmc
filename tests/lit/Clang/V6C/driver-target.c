// RUN: clang -target i8080-unknown-v6c -### %s 2>&1 | FileCheck %s
//
// Verify that the clang driver accepts the i8080-unknown-v6c target.

// CHECK: "-triple" "i8080-unknown-v6c"
// CHECK: "-ffreestanding"

void dummy(void) {}
