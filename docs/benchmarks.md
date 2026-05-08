# C-compiler benchmark results

Cycle counts and ROM sizes for three pure-C benchmarks compiled with each i8080-capable compiler and run on `v6emul`. The number in parentheses is the cycle ratio relative to v6llvmc -O2.

| Program | v6llvmc-O2 | v6llvmc-O1 | v6llvmc-Os | c8080 | z88dk |
|---|---|---|---|---|---|
| bsort | 171 B / 21,372 cc (1.00x) | 140 B / 23,544 cc (1.10x) | 131 B / 22,728 cc (1.06x) | 227 B / 47,900 cc (2.24x) | 1183 B / 99,084 cc (4.64x) |
| sieve | 227 B / 4,888,812 cc (1.00x) | 227 B / 4,888,812 cc (1.00x) | 218 B / 4,804,620 cc (0.98x) | 195 B / 5,158,148 cc (1.06x) | 9135 B / 11,444,112 cc (2.34x) |
| fib_crc | 627 B / 67,324 cc (1.00x) | 236 B / 85,868 cc (1.28x) | 224 B / 82,964 cc (1.23x) | 308 B / 268,204 cc (3.98x) | 1155 B / 284,048 cc (4.22x) |

All compilers produced the same checksum byte per program (`bsort`=0xC4, `sieve`=0xEC, `fib_crc`=0x2B), confirming the ROMs are functionally equivalent.

## Compiler invocations

- **v6llvmc**: `clang -target i8080-unknown-v6c -O2 prog.c -o prog.rom`
- **c8080**: `c8080 -Ocpm prog.c -o prog.com -a prog.asm` (CP/M `.COM`, ORG=0x0100)
- **z88dk**: `zcc +cpm -clib=8080 -m8080 -compiler=sccz80 -SO3 -O3 -create-app prog.c`
  with the BDOS region (0x0000-0x00FF) stubbed out by the runner so the CP/M crt0 returns from `BDOS` calls harmlessly.

## Reproducing

```
python tests/benchmarks_c/run_benchmarks.py
```
