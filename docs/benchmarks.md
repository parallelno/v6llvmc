# C-compiler benchmark results

Cycle counts and ROM sizes for three pure-C benchmarks compiled with each i8080-capable compiler and run on `v6emul`. The number in parentheses is the cycle ratio relative to v6llvmc -O2.

| Program | v6llvmc-O2 | v6llvmc-O1 | v6llvmc-Os | c8080 | z88dk |
|---|---|---|---|---|---|
| bsort | **95 B** / <span style="color:gray">3,297,040 cc</span> (**1.00x**) | **95 B** / <span style="color:gray">3,297,040 cc</span> (**1.00x**) | **95 B** / <span style="color:gray">3,297,040 cc</span> (**1.00x**) | **212 B** / <span style="color:gray">10,908,100 cc</span> (**3.31x**) | **1204 B** / <span style="color:gray">24,400,688 cc</span> (**7.40x**) |
| sieve | **239 B** / <span style="color:gray">4,660,180 cc</span> (**1.00x**) | **239 B** / <span style="color:gray">4,660,180 cc</span> (**1.00x**) | **239 B** / <span style="color:gray">4,660,180 cc</span> (**1.00x**) | **195 B** / <span style="color:gray">5,158,148 cc</span> (**1.11x**) | **9135 B** / <span style="color:gray">11,444,112 cc</span> (**2.46x**) |
| fib_crc | **192 B** / <span style="color:gray">66,524 cc</span> (**1.00x**) | **192 B** / <span style="color:gray">66,524 cc</span> (**1.00x**) | **192 B** / <span style="color:gray">66,524 cc</span> (**1.00x**) | **308 B** / <span style="color:gray">268,204 cc</span> (**4.03x**) | **1155 B** / <span style="color:gray">284,048 cc</span> (**4.27x**) |
| fannkuch | **331 B** / <span style="color:gray">29,574,680 cc</span> (**1.00x**) | **333 B** / <span style="color:gray">29,405,200 cc</span> (**0.99x**) | **331 B** / <span style="color:gray">29,574,680 cc</span> (**1.00x**) | **373 B** / <span style="color:gray">32,033,296 cc</span> (**1.08x**) | **1440 B** / <span style="color:gray">59,145,260 cc</span> (**2.00x**) |
| lfsr16 | **127 B** / <span style="color:gray">1,492,336 cc</span> (**1.00x**) | **127 B** / <span style="color:gray">1,492,336 cc</span> (**1.00x**) | **127 B** / <span style="color:gray">1,492,336 cc</span> (**1.00x**) | **176 B** / <span style="color:gray">2,623,212 cc</span> (**1.76x**) | **1019 B** / <span style="color:gray">4,473,860 cc</span> (**3.00x**) |

All compilers produced the same checksum byte per program (`bsort`=0x98, `sieve`=0xEC, `fib_crc`=0x2B, `fannkuch`=0x10, `lfsr16`=0x1D), confirming the ROMs are functionally equivalent.

## Compiler invocations

- **v6llvmc**: `clang -target i8080-unknown-v6c -O2 prog.c -o prog.rom`
- **c8080**: `c8080 -Ocpm prog.c -o prog.com -a prog.asm` (CP/M `.COM`, ORG=0x0100)
- **z88dk**: `zcc +cpm -clib=8080 -m8080 -compiler=sccz80 -SO3 -O3 -create-app prog.c`
  with the BDOS region (0x0000-0x00FF) stubbed out by the runner so the CP/M crt0 returns from `BDOS` calls harmlessly.

## Reproducing

```
python tests/benchmarks_c/run_benchmarks.py
```
