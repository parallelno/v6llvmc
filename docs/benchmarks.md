# C-compiler benchmark results

Cycle counts and ROM sizes for three pure-C benchmarks compiled with each i8080-capable compiler and run on `v6emul`. The number in parentheses is the cycle ratio relative to v6llvmc -O2.

| Program | v6llvmc-O2 | v6llvmc-O1 | v6llvmc-Os | c8080 | z88dk |
|---|---|---|---|---|---|
| bsort | 261 B / 51,464 cc (1.00x) | 200 B / 50,384 cc (0.98x) | 209 B / 52,784 cc (1.03x) | 227 B / 47,900 cc (0.93x) | 1189 B / 92,212 cc (1.79x) |
| sieve | 303 B / 87,640 cc (1.00x) | 180 B / 89,460 cc (1.02x) | 180 B / 89,460 cc (1.02x) | 212 B / 148,184 cc (1.69x) | 1342 B / 195,472 cc (2.23x) |
| fib_crc | 635 B / 68,528 cc (1.00x) | 257 B / 89,492 cc (1.31x) | 245 B / 86,588 cc (1.26x) | 308 B / 268,204 cc (3.91x) | 1155 B / 284,048 cc (4.14x) |

All compilers produced the same checksum byte per program (`bsort`=0xC4, `sieve`=0x36, `fib_crc`=0x2B), confirming the ROMs are functionally equivalent.

## Compiler invocations

- **v6llvmc**: `clang -target i8080-unknown-v6c -O2 prog.c -o prog.rom`
- **c8080**: `c8080 -Ocpm prog.c -o prog.com -a prog.asm` (CP/M `.COM`, ORG=0x0100)
- **z88dk**: `zcc +cpm -clib=8080 -m8080 -compiler=sccz80 -SO3 -O3 -create-app prog.c`
  with the BDOS region (0x0000-0x00FF) stubbed out by the runner so the CP/M crt0 returns from `BDOS` calls harmlessly.

## Reproducing

```
python tests/benchmarks_c/run_benchmarks.py
```
