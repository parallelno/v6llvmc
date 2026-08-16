# Plan: C Debug Metadata Milestone 6 - Final-Link and Consumer Integration

**Status:** In progress
**Depends on:** Milestones 1-5
**Consumer:** v6vscode

## 1. Problem

### Current behavior

Individual metadata features may work in compiler fixtures, but proper C
debugging requires one frozen final-ELF contract consumed from coherent real
emulator state. Object-only success does not prove linked addresses, indexed
sections, CFI, locations, inline frames, and ROM execution agree.

### Desired behavior

Representative final V6C ELFs must pass producer verification and v6vscode
fixtures at `-O0/-O1/-O2/-Os`, unwind a real three-function chain, expose
recoverable parameters/locals for selected frames, reconstruct nested inline
calls, and represent unavailable values honestly.

### Root cause

Producer and consumer acceptance have not yet been exercised as one versioned
compatibility matrix across compilation, linking, ROM extraction, emulator
state, DWARF evaluation, and DAP-facing metadata indexes.

## 2. Strategy

### Approach: freeze and test the final linked-ELF contract end to end

Publish exact emitted tags, forms, range/location entries, expression
operations, CFI operations, register numbers, and limitations. Generate
checked-in deterministic fixtures from final ELFs, then validate them through
v6vscode and real emulator snapshots. Treat the ELF as authoritative and the
ROM as its executable projection.

### Why this works

It tests the same artifact and stopped state used in production, catches link
relocation/GC errors, and prevents the compiler and extension from developing
independent target heuristics.

### Summary of changes

- Freeze the V6C DWARF v5 producer compatibility table.
- Add final-link optimization-level matrix fixtures.
- Validate physical and inline frames plus frame-sensitive variables.
- Validate ROM/ELF address identity and unsupported-boundary behavior.
- Publish release and compatibility documentation.

## 3. Implementation Steps

### Step 3.1 - Read references and capture release baselines [x]

Review every completed milestone, v6vscode metadata/call-stack/variables plans,
v6emul stopped-state APIs, linker scripts, release workflow, and benchmark
runner. Capture final pre-integration benchmark, ROM, `.text`, and assembly
baselines.

> **Implementation Notes**: Reviewed the completed producer milestones, linker
> flow, ROM projection, feature fixtures, emulator stopped-state output, and
> benchmark runner. The release benchmark matrix remains the baseline gate.

### Step 3.2 - Publish the supported DWARF contract [x]

List exact versions, address/offset sizes, tags, attributes, forms, indexed
sections, range/location entries, register map, location operations including
`DW_OP_call_frame_cfa`, CFI operations, overlap policy, and known limitations.
Require a producer test and consumer entry before adding any operation.

> **Implementation Notes**: Added the contract-version-1 producer
> compatibility table to `V6CDebugABI.md`, covering container, sections,
> tags, locations, register map, CFI, O61 storage, and unavailable values.

### Step 3.3 - Build deterministic final-ELF fixtures [x]

Create source and build scripts for register/stack parameters, locals,
spills/reloads, static stack, O61, shadowing, types, leaf/non-leaf calls,
multiple returns, FP modes, tail calls, nested inline chains, and boundaries at
`-O0/-O1/-O2/-Os`. Keep final ELF, ROM, expected metadata, and emulator
snapshots reproducible.

> **Implementation Notes**: Added Feature 83. It deterministically builds a
> three-physical-call and nested-inline program at `-O0/-O1/-O2/-Os`, retaining
> final ELF/ROM pairs, DWARF/CFI dumps, and coherent emulator snapshots.

### Step 3.4 - Verify final linking and ROM correlation [x]

Run `llvm-dwarfdump --verify`; assert no unresolved debug relocations; ensure
all code ranges map to final executable sections; and prove symbols, line rows,
locations, and FDEs use the same 16-bit addresses executed by the ROM.

> **Implementation Notes**: Feature 83 runs `llvm-dwarfdump --verify`, checks
> required final debug sections and CFI for `leaf`, `middle`, and `main`, and
> byte-compares each ROM with `llvm-objcopy -O binary` of its companion ELF.

### Step 3.5 - Pass v6vscode producer-consumer tests [ ]

Run the extension's structured DWARF parser/index fixtures. Verify supported
features do not require prologue decoding or stack scanning and unsupported
optional metadata degrades only the dependent feature.

> **Implementation Notes**:

### Step 3.6 - Pass real-emulator semantic scenarios [ ]

From coherent stopped snapshots, unwind three physical calls, expand nested
inline calls, evaluate one recoverable parameter/local per selected frame,
verify optimized-out/inactive values are unavailable, and stop honestly at an
unsupported boundary.

> **Implementation Notes**:

### Step 3.7 - Build [ ]

Run `pwsh scripts/build.ps1 -SkipTests` for any integration corrections.

> **Implementation Notes**:

### Step 3.8 - Add final producer regression tests [ ]

Add final-link lit tests for every supported contract entry and regression
tests for malformed addresses, GC, mixed C/ASM, line-only fallback, and
multiple translation units.

> **Implementation Notes**:

### Step 3.9 - Prove optimization and performance non-regression [ ]

No optimization may be disabled, removed, or weakened. Require normal
benchmark executable output to match its baseline, all expected checksums,
and no release cycle or executable code-size increase. Validate debug builds
for end-to-end metadata and runtime correctness rather than byte identity with
non-debug builds.

> **Implementation Notes**:

### Step 3.10 - Run all regression suites [ ]

Run `python tests/run_all.py` with benchmarks, all final fixture scripts,
v6vscode unit/integration tests, Extension Host scenarios, and real-emulator
scenarios. A skipped required tool is not a pass for release acceptance.

> **Implementation Notes**:

### Step 3.11 - Verify assembly and create final `result.txt` [ ]

Include C fixtures, relevant unchanged assembly, all final metadata summaries,
emulator results, v6vscode results, and baseline/final cycle and code-size
comparison per `tests/features/result.md`.

> **Implementation Notes**:

### Step 3.12 - Documentation, sync, release gate, and completion [ ]

Update compiler, ABI, build, compatibility, project-template, and known-limit
documentation. Sync mirrors, verify hashes, mark all subplans/master/original
checklists complete, and update `future_plans/README.md` only after every gate
passes.

> **Implementation Notes**:

## 4. Expected Results

- Compiler, linker, extension, and emulator agree on one DWARF v5 contract.
- Three physical frames, nested inline frames, and tested values work from real
  stopped state.
- Existing executable output and benchmark performance do not regress.

## 5. Risks & Mitigations

| Risk | Mitigation |
|------|------------|
| Synthetic fixtures hide linker/runtime defects | Require final linked ELF plus real emulator scenarios. |
| Producer and consumer tables drift | Keep one versioned compatibility matrix tested in both repositories. |
| Optional metadata breaks baseline debugging | Test independent feature detection and ASM/line-only fallback. |
| Release silently skips benchmarks/tools | Treat skipped required acceptance suites as failures. |

## 6. Relationship to Other Improvements

Completion unblocks v6vscode semantic Call Stack, Variables, expressions, and
source-level stepping while preserving every V6C optimization.

## 7. Future Enhancements

Post-release additions include richer call-site parameter metadata, additional
expression operations, and broader mixed-language unwind support under a new
contract version.

## 8. References

- [Master Plan](plan_v6llvmc_c_debug_metadata.md)
- [Milestone 5](plan_v6llvmc_c_debug_metadata_milestone5.md)
- [V6C Build Guide](../docs/V6CBuildGuide.md)
- [C Benchmarks](../tests/benchmarks_c/README.md)
- [Future Improvements](future_plans/README.md)
