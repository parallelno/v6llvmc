// RUN: clang -target i8080-unknown-v6c -E %s -o - | FileCheck %s
// RUN: clang -target i8080-unknown-v6c -O2 -S %s -o - | FileCheck %s --check-prefix=ASM
// RUN: clang -target i8080-unknown-v6c -### -c %s 2>&1 | FileCheck %s --check-prefix=DRIVER
//
// DRIVER asserts the driver injects -internal-isystem pointing at the
// V6C resource-dir include directory and emits -ffunction-sections by
// default. Honors -nostdinc / -fno-function-sections per Clang
// convention (covered by negative checks below).
//
// RUN: clang -target i8080-unknown-v6c -nostdinc -### -c %s 2>&1 | FileCheck %s --check-prefix=NOSTDINC
// RUN: clang -target i8080-unknown-v6c -fno-function-sections -### -c %s 2>&1 | FileCheck %s --check-prefix=NOFUNCSEC
//
// Phase 6: V6C driver auto-injects <resource-dir>/lib/v6c/include/ so
// `<string.h>`, `<stdlib.h>`, `<v6c.h>` resolve without any -I flag.
// Also verify -ffunction-sections is on by default (per-function ELF
// sections so ld.lld --gc-sections can prune unreachable helpers).

#include <string.h>
#include <stdlib.h>
#include <v6c.h>

// CHECK: void *memcpy(
// CHECK: void *memset(
// CHECK: void abort(
// CHECK: __v6c_out(

void test_use(char *p) {
    memset(p, 0, 4);
    __v6c_out(0xED, 0x42);
}

// ASM: .section{{.*}}.text.test_use

// DRIVER: -ffunction-sections
// DRIVER: -internal-isystem
// DRIVER-SAME: V6C
// DRIVER-SAME: include

// NOSTDINC-NOT: ToolChains{{[/\\]+}}V6C{{[/\\]+}}include"

// NOFUNCSEC-NOT: -ffunction-sections
