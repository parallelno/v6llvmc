// RUN: clang -target i8080-unknown-v6c -E -dM %s -o - | FileCheck %s
//
// Verify that the V6C target defines the expected built-in macros.

// CHECK-DAG: #define __V6C__
// CHECK-DAG: #define __I8080__
// CHECK-DAG: #define __CHAR_UNSIGNED__
