# C-compiler benchmark results

Cycle counts and ROM sizes for three pure-C benchmarks compiled with each i8080-capable compiler and run on `v6emul`. The number in parentheses is the cycle ratio relative to v6llvmc -O2.

| Program | v6llvmc-O2 | v6llvmc-O1 | v6llvmc-Os | c8080 | z88dk |
|---|---|---|---|---|---|
| bsort | **97 B** / <span style="color:gray">3,297,044 cc</span> (**1.00x**) | **97 B** / <span style="color:gray">3,297,044 cc</span> (**1.00x**) | **97 B** / <span style="color:gray">3,297,044 cc</span> (**1.00x**) | **212 B** / <span style="color:gray">10,908,100 cc</span> (**3.31x**) | **1204 B** / <span style="color:gray">24,400,688 cc</span> (**7.40x**) |
| sieve | **210 B** / <span style="color:gray">4,641,172 cc</span> (**1.00x**) | **210 B** / <span style="color:gray">4,641,172 cc</span> (**1.00x**) | **210 B** / <span style="color:gray">4,641,172 cc</span> (**1.00x**) | **195 B** / <span style="color:gray">5,158,148 cc</span> (**1.11x**) | **9135 B** / <span style="color:gray">11,444,112 cc</span> (**2.47x**) |
| fib_crc | **187 B** / <span style="color:gray">60,096 cc</span> (**1.00x**) | **187 B** / <span style="color:gray">60,096 cc</span> (**1.00x**) | **187 B** / <span style="color:gray">60,096 cc</span> (**1.00x**) | **308 B** / <span style="color:gray">268,204 cc</span> (**4.46x**) | **1155 B** / <span style="color:gray">284,048 cc</span> (**4.73x**) |
| fannkuch | **330 B** / <span style="color:gray">29,264,076 cc</span> (**1.00x**) | **332 B** / <span style="color:gray">29,094,596 cc</span> (**0.99x**) | **330 B** / <span style="color:gray">29,264,076 cc</span> (**1.00x**) | **373 B** / <span style="color:gray">32,033,296 cc</span> (**1.09x**) | **1440 B** / <span style="color:gray">59,145,260 cc</span> (**2.02x**) |
| lfsr16 | **125 B** / <span style="color:gray">1,394,028 cc</span> (**1.00x**) | **125 B** / <span style="color:gray">1,394,028 cc</span> (**1.00x**) | **125 B** / <span style="color:gray">1,394,028 cc</span> (**1.00x**) | **176 B** / <span style="color:gray">2,623,212 cc</span> (**1.88x**) | **1019 B** / <span style="color:gray">4,473,860 cc</span> (**3.21x**) |

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
