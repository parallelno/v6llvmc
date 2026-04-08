# V6C Project Structure

```
v6llvmc/
├── llvm-project/                 # Full LLVM monorepo (gitignored, build source)
├── llvm/                         # Git-tracked mirror of V6C changes
│   ├── lib/Target/V6C/           # Full mirror of V6C backend
│   ├── include/llvm/TargetParser/ # Modified upstream: Triple.h
│   └── lib/TargetParser/         # Modified upstream: Triple.cpp
├── llvm-build/                   # Build output directory (gitignored)
├── scripts/
│   └── sync_llvm_mirror.ps1      # Mirror sync script (run after builds)
├── clang/lib/Basic/Targets/      # Clang frontend integration
├── compiler-rt/lib/builtins/v6c/ # Runtime library
├── lld/V6C/                      # Linker
├── tests/
│   ├── golden/                   # Emulator trust baseline (15 programs)
│   ├── lit/                      # LLVM FileCheck tests
│   ├── unit/                     # Standalone C unit tests
│   ├── integration/              # End-to-end C→binary→emulator tests
│   ├── runtime/                  # Runtime library standalone tests
│   └── benchmarks/               # Performance measurements
├── docs/                         # Documentation
├── tools/
│   ├── v6asm/                    # 8080 assembler
│   └── v6emul/                   # Vector 06c emulator
└── design/                       # Design & implementation plan
```

## Key Directories

| Directory | Git-tracked | Description |
|-----------|-------------|-------------|
| `llvm-project/` | No | Full LLVM monorepo, pinned to `llvmorg-18.1.0`. Build reads from here. |
| `llvm/` | Yes | Mirror of all V6C-related changes. Authoritative source for recovery. |
| `llvm-build/` | No | CMake/Ninja build output. |
| `design/` | Yes | [design.md](../design/design.md) (architecture spec) and [plan.md](../design/plan.md) (milestones). |
| `tests/` | Yes | All test suites. See [golden tests README](../tests/golden/README.md). |
| `tools/` | Yes | Pre-built `v6asm` and `v6emul` binaries. |
