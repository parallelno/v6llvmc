# V6C Debug Metadata

V6C debug builds use DWARF v5 metadata in the final linked ELF. When a build
also produces a flat ROM, that ELF is retained as the ROM's debug companion.
Use the ROM to run the program and the final ELF for symbols and source-line
lookup.

## What a Debug Build Produces

Pass `-g` to the V6C Clang driver:

```bash
llvm-build/bin/clang -target i8080-unknown-v6c -g \
    main.c -o game.rom
```

This produces:

| File | Purpose |
|------|---------|
| `game.rom` | Flat binary to load and run on Vector-06C or in an emulator. |
| `game.elf` | Final linked debug companion with symbols and DWARF metadata. |

The ROM is derived from `game.elf`, so code addresses in the ELF are the CPU
addresses for the default V6C linker script. A normal non-debug ROM build does
not retain the intermediate ELF.

The companion ELF contains final symbols and standard DWARF v5 sections,
including `.debug_info`, `.debug_abbrev`, `.debug_line`, indexed string and
address tables, and range/location lists when required. It records source file
names and instruction source locations for C and supported assembly inputs.

## C Programs

Compile and link a single C source file in one command:

```bash
llvm-build/bin/clang -target i8080-unknown-v6c -O0 -g \
    hello.c -o hello.rom
```

For multiple translation units, compile each object with debug information and
link the final program with debug information enabled:

```bash
llvm-build/bin/clang -target i8080-unknown-v6c -O0 -g -c main.c -o main.o
llvm-build/bin/clang -target i8080-unknown-v6c -O0 -g -c sprite.c -o sprite.o
llvm-build/bin/clang -target i8080-unknown-v6c -g \
    main.o sprite.o -o game.rom
```

Headers included by a C translation unit are represented in the line table
when they contain executable source locations.

## ELF-First Workflow

For custom linking, produce the final ELF explicitly and derive the ROM from
it:

```bash
llvm-build/bin/clang -target i8080-unknown-v6c -O0 -g -c main.c -o main.o
llvm-build/bin/ld.lld -m elf32v6c \
    -T clang/lib/Driver/ToolChains/V6C/v6c.ld \
    main.o -o game.elf
llvm-build/bin/llvm-objcopy -O binary game.elf game.rom
```

Use this form when supplying a custom linker script or linking objects from
multiple producers. Keep the final linked ELF with the ROM; relocatable `.o`
files do not contain final CPU addresses.

## v6asm Objects

The packaged v6asm assembler can emit compatible debug ELF objects. Enable
debug metadata with `-g`, then link its object with Clang-produced objects:

```bash
tools/v6asm/v6asm.exe -g -f obj asm-leaf.asm -o asm-leaf.o
llvm-build/bin/clang -target i8080-unknown-v6c -O0 -g \
    -fno-v6c-auto-include -c c-entry.c -o c-entry.o
llvm-build/bin/ld.lld -m elf32v6c -e c_entry \
    c-entry.o asm-leaf.o -o mixed.elf
llvm-build/bin/llvm-objcopy -O binary mixed.elf mixed.rom
```

The resulting `mixed.elf` contains the symbols and source-line information
from both C and v6asm inputs.

## Inspecting a Debug Companion

Inspect the final ELF rather than the ROM:

```bash
# Verify the DWARF sections and final symbols.
llvm-build/bin/llvm-readelf -S -s game.elf

# Inspect final instruction addresses with symbols.
llvm-build/bin/llvm-objdump -d game.elf

# Display the raw DWARF line-table payload when diagnosing metadata.
llvm-build/bin/llvm-readelf -x .debug_line game.elf
```

For source-to-address tools, use rows from the final ELF that belong to a
final executable section. This matters when linking with `--gc-sections`:
discarded code has no executable address and must not become a breakpoint.

## Scope and Limitations

- DWARF v5 is the supported format emitted by `-g`. Existing line-table-only
  DWARF v4 artifacts remain a consumer compatibility case.
- The final ELF is authoritative. Its default virtual addresses are already
  16-bit CPU addresses; do not add the ROM base address again.
- Metadata is non-loadable and does not become part of the flat ROM image.
- This repository provides debug artifacts and inspection support. A DAP
  adapter that turns source lines into emulator breakpoints is not included
  here; it must consume the final ELF companion.
- Optimized code can merge, move, or remove source statements. For predictable
  source-line inspection, begin with `-O0`.

## Related Documentation

- [V6CBuildGuide.md](V6CBuildGuide.md) for build setup and custom link flows.
- [V6CClangUsage.md](V6CClangUsage.md) for the Clang driver and V6C C support.
- [V6CDebugABI.md](V6CDebugABI.md) for the normative ABI and register map.
- [Source Debug Metadata Plan](../design/future_plans/plan_source_debug_metadata.md)
  for the broader artifact and future adapter contract.