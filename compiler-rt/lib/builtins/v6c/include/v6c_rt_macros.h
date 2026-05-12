/* v6c_rt_macros.h - Shared internal macros for V6C runtime headers.
 *
 * Sole owner of the `V6C_RT` decoration used by every header-only
 * inline-asm runtime routine (math in `v6c_arith.h`, string/memory
 * in `<string.h>`). Pull this in instead of redefining `V6C_RT`
 * locally — that way the attribute set stays consistent and the
 * `annotate("v6c-rt-helper")` tag (used to suppress these bodies
 * from `-S` output unless `-mv6c-print-rt-helpers` is passed) is
 * applied uniformly.
 *
 * This header is pure macro plumbing: no declarations, no includes.
 * It is safe to pull into any V6C runtime header without dragging
 * in math prototypes or libc surface.
 *
 * Attribute rationale (see also docs/V6CRuntimeAndInlineAsm.md):
 *   - static: per-TU local symbol; no multi-definition link errors.
 *   - noinline + used: keeps the IR definition alive across `-O2`
 *     even when no source statement directly mentions the symbol —
 *     libcalls are inserted post-IR, in CodeGen. `--gc-sections`
 *     (on by default for V6C) then prunes unused copies at link time.
 *   - naked: no compiler-emitted prologue/epilogue. Body is exactly
 *     the inline-asm string; every byte hand-placed; relies on the
 *     V6C C calling convention having operands already in named
 *     registers. Each body must emit its own `RET`.
 *   - annotate("v6c-rt-helper"): tag for V6CAsmPrinter to suppress
 *     these bodies from `.s` dumps by default.
 */
/* No file-level include guard: each consumer header `#undef`s
 * `V6C_RT` at end-of-file to keep the macro out of user code, so
 * re-including this file must re-establish the definition. The inner
 * `#ifndef V6C_RT` keeps successive includes warning-free in case a
 * downstream header forgets to undef. */

#ifndef __V6C__
#error "v6c_rt_macros.h is V6C-only; compile with -target i8080-unknown-v6c"
#endif

#ifndef V6C_RT
#define V6C_RT static __attribute__((noinline, used, naked, \
                                     annotate("v6c-rt-helper")))
#endif
