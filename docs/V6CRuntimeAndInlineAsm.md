# V6C Runtime and Inline Asm

This document describes the V6C math runtime (`v6c_arith.h`) and the
calling-convention contract that lets compiler-emitted libcalls and
hand-written inline asm coexist on the V6C target.

## Why a header-only runtime?

V6C targets the Vector-06C (Soviet i8080-clone). The CPU has no MUL,
no DIV, and only single-amount shifts. Any `unsigned a * b` therefore
lowers to a libcall. Historically these were assembled `.s` files
shipped under `compiler-rt/lib/builtins/v6c/`. Empirically that broke
two things V6C cares about:

1. **IPRA per-call clobber sets.** V6C's `getCallPreservedMask` is
   empty (no callee-saves). Without IPRA, every call is treated as
   clobbering every register. With IPRA, the clobber set of each
   *internal* (same-TU `static`) callee is recovered exactly. Asm
   stubs in a separate library are external — IPRA can't see them.
2. **Cross-call elision.** When the caller is already in HL/DE the
   shape ISel wants, a per-TU `static` definition lets the assembler
   (and same-TU peepholes) collapse argument shuffles.

So O70 made the runtime header-only:

```c
#define V6C_RT static __attribute__((noinline, used, naked))

V6C_RT unsigned char __mulqi3(unsigned char a, unsigned char b) {
    __asm__ volatile ( /* 8-iteration shift-add ending in MOV A,L; RET */ );
}
```

Each translation unit gets its own per-TU copy. `--gc-sections` (now
on by default for V6C in ld.lld) prunes the ones the program never
calls. IPRA recovers each routine's true clobber set.

## What the header provides

Every libcall the V6C backend can emit:

| Symbol            | C signature                            | Operation                  |
|-------------------|----------------------------------------|----------------------------|
| `__mulqi3`        | `u8(u8,u8)`                            | i8 multiply, low byte → A  |
| `__v6c_mulqihi3`  | `u16(u8,u8)`                           | i8×i8 widening → HL        |
| `__mulhi3`        | `u16(u16,u16)`                         | i16 multiply low 16        |
| `__udivhi3`       | `u16(u16,u16)`                         | unsigned div               |
| `__umodhi3`       | `u16(u16,u16)`                         | unsigned mod               |
| `__divhi3`        | `i16(i16,i16)`                         | signed div (truncated)     |
| `__modhi3`        | `i16(i16,i16)`                         | signed mod (C99)           |
| `__udivmodhi4`    | `u16(u16,u16,u16*)`                    | fused unsigned divmod      |
| `__divmodhi4`     | `i16(i16,i16,i16*)`                    | fused signed divmod        |
| `__ashlhi3`       | `u16(u16,u8)`                          | logical left shift         |
| `__lshrhi3`       | `u16(u16,u8)`                          | logical right shift        |
| `__ashrhi3`       | `i16(i16,u8)`                          | arithmetic right shift     |

ISel automatically lowers `*`, `/`, `%`, `<<`, `>>` to the matching
symbol. The `udivmod`/`divmod` fused calls only fire when the
mid-level optimizer keeps `q=a/b` and `r=a%b` as separate
udiv/urem — the default mid-level rewrite of `a%b` to `a-(a/b)*b`
defeats fusion (and is usually faster anyway when there are 0 or
1 callers of `q*b`).

## Auto-include

The clang driver passes `-include v6c_arith.h` automatically when the
target triple is `i8080-unknown-v6c`. The header is searched at:

1. `<resource-dir>/lib/v6c/include/v6c_arith.h`
2. `<bin>/../../compiler-rt/lib/builtins/v6c/include/v6c_arith.h` (dev tree)

To suppress (and supply your own runtime):

```sh
clang -target i8080-unknown-v6c -fno-v6c-auto-include main.c -o out.rom
```

You'll then see `ld.lld: error: undefined symbol: __mulhi3` (etc.)
unless you provide them.

## Calling convention contract (free-list C ABI)

| Type    | Arg #1 | Arg #2 | Arg #3 | Return |
|---------|--------|--------|--------|--------|
| `i8`    | A      | B      | C      | A      |
| `i16`   | HL     | DE     | BC     | HL     |
| ptr     | (i16)  | (i16)  | (i16)  | (i16)  |

No callee-saves. Stack used only for arg #4+ and IPRA-determined
spills. The runtime header conforms to this convention so ISel
emits no shuffle code at the call site when the operands are
already in the right registers.

## Writing inline asm against the runtime

Naked functions in the V6C target accept ONLY inline asm — any C
statement (including `(void)param;`) is rejected. Reference parameters
implicitly via the calling convention:

```c
static __attribute__((noinline, used, naked))
unsigned my_helper(unsigned hl_arg, unsigned de_arg) {
    /* hl_arg is in HL, de_arg is in DE. Return value goes in HL. */
    __asm__ volatile (
        "DAD  D    \n\t"   /* HL += DE */
        "RET       \n\t"
    );
}
```

For non-naked functions, use standard GCC inline-asm constraints
(currently a small subset is supported — see
`tests/lit/Clang/V6C/inline-asm.c` for the recognized list).

## See also

- `design/plan_O70_math_header.md` — design rationale.
- `tests/v6c_lib/linkage_smoke.c` — exercises every operator.
- `tests/v6c_lib/divmod_combined.c` — fused divmod runtime check.
- `tests/lit/CodeGen/V6C/i8_mul_libcall.ll` — i8 MUL → __mulqi3.
- `tests/lit/CodeGen/V6C/divmod-fusion.ll` — udiv+urem fusion.
