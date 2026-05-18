# V6C Compiler Options

LLVM hidden options understood by the V6C backend, plus debug-output
toggles. All are passed via `-mllvm <flag>` from the clang driver, or
directly to `llc`.

For build/setup, see [V6CBuildGuide.md](V6CBuildGuide.md). For C-level
language and inline asm reference, see
[V6CClangUsage.md](V6CClangUsage.md). For optimization-pass design
details, see [V6COptimization.md](V6COptimization.md).

## Recommended

| Option | Effect |
|--------|--------|
| `-mllvm --enable-deferred-spilling` | Defers spill code insertion, giving the greedy RA a second chance to find a better coloring. Can eliminate spills entirely on register-starved loops. **Experimental** in upstream LLVM — test thoroughly. |

## Situationally Useful

| Option | Effect |
|--------|--------|
| `-mllvm --sink-insts-to-avoid-spills` | Pre-RA pass that sinks definitions closer to uses, freeing registers across the gap. Helps in straight-line code with high register pressure. |
| `-mllvm --split-spill-mode=size` | Tells SplitKit to prefer smaller spill code over faster. Alternative: `=speed`. Default: `=default`. |
| `-mllvm --enable-spill-copy-elim` | Eliminates redundant register-to-register copies introduced by spill code. Unlikely to help on V6C (spills use PUSH/POP and LHLD/SHLD, not copies). |
| `-mllvm -mv6c-no-spill-patched-reload` | V6C-specific. Disables O61, the default-on pass that rewrites selected spill/reload pairs so the spill writes directly into a `LXI`/`MVI` immediate at the reload site (self-modifying code in `.text`). Use this when targeting ROM/EPROM where `.text` is not writable. Saves 6–22cc and 1–4B per patched reload when active. See [V6COptimization.md § O61](V6COptimization.md). |

## Not Recommended

| Option | Why |
|--------|-----|
| `-mllvm --regalloc=basic` | Replaces greedy RA with basic linear-scan. Worse code quality on V6C; may not terminate on complex functions. |

## Example: All Useful Options Combined

```bash
llvm-build/bin/clang -target i8080-unknown-v6c -O2 -S input.c -o output.s \
  -mllvm --enable-deferred-spilling \
  -mllvm -sink-insts-to-avoid-spills
```

## Debugging

| Option | Effect |
|--------|--------|
| `-mllvm -mv6c-annotate-pseudos` | Emits function header comments (C declaration + param→register map) and `;--- PSEUDO ---` comments before each pseudo expansion. Add `-fno-discard-value-names` to preserve original C parameter names in the surviving args. Add `-g` to also show constant-propagated parameters as a `[folded: x0=127, y0=127, ...]` comment — requires no extra runtime cost since `-g` only emits debug metadata used during compilation. |
| `-mllvm -mv6c-print-rt-helpers` | Emits the auto-included `v6c_arith.h` runtime helpers (`__mulqi3`, `__mulhi3`, `__udivhi3`, `__divhi3`, `__ashlhi3`, ...) into `.s` text output. Off by default — without it, helper bodies are suppressed so user code stands out. **Object-file emission (`-c` / `-filetype=obj`) always includes the helpers** so linking is unaffected. The filter relies on each helper being tagged `__attribute__((annotate("v6c-rt-helper")))` (already applied by the `V6C_RT` macro in `v6c_arith.h`); see [V6CClangUsage.md § Function Attributes](V6CClangUsage.md#function-attributes) and [V6CRuntimeAndInlineAsm.md](V6CRuntimeAndInlineAsm.md). |

### How `-mv6c-print-rt-helpers` works

The V6C `AsmPrinter::doInitialization` scans the module-level
`@llvm.global.annotations` global, collecting every function name
whose annotation string is `"v6c-rt-helper"`. In
`runOnMachineFunction`, when the streamer reports raw-text support
(i.e. `.s` output) and the flag is **off**, listed functions are
skipped before any directives or instructions are emitted.

This filter is purely cosmetic for the assembly listing; it has no
effect on:

- IR-level codegen, optimization, or linkage
- Object-file emission (`-filetype=obj`, `clang -c`)
- Section placement or `--gc-sections` pruning

To author your own helper that benefits from the same suppression,
tag it with `__attribute__((annotate("v6c-rt-helper")))`. The tag has
no codegen impact beyond a metadata entry the V6C `AsmPrinter`
recognizes.
