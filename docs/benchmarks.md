# C-compiler benchmark results

Cycle counts and ROM sizes for three pure-C benchmarks compiled with each i8080-capable compiler and run on `v6emul`. The number in parentheses is the cycle ratio relative to v6llvmc -O2.

| Program | v6llvmc-O2 | v6llvmc-O1 | v6llvmc-Os | c8080 | z88dk |
|---|---|---|---|---|---|
| bsort | **104 B** / <span style="color:gray">3,495,664 cc</span> (**1.00x**) | **104 B** / <span style="color:gray">3,495,664 cc</span> (**1.00x**) | **95 B** / <span style="color:gray">3,297,040 cc</span> (**0.94x**) | **212 B** / <span style="color:gray">10,908,100 cc</span> (**3.12x**) | **1204 B** / <span style="color:gray">24,400,688 cc</span> (**6.98x**) |
| sieve | **226 B** / <span style="color:gray">4,728,144 cc</span> (**1.00x**) | **226 B** / <span style="color:gray">4,728,144 cc</span> (**1.00x**) | **217 B** / <span style="color:gray">4,643,952 cc</span> (**0.98x**) | **195 B** / <span style="color:gray">5,158,148 cc</span> (**1.09x**) | **9135 B** / <span style="color:gray">11,444,112 cc</span> (**2.42x**) |
| fib_crc | **611 B** / <span style="color:gray">65,788 cc</span> (**1.00x**) | **234 B** / <span style="color:gray">84,332 cc</span> (**1.28x**) | **222 B** / <span style="color:gray">81,428 cc</span> (**1.24x**) | **308 B** / <span style="color:gray">268,204 cc</span> (**4.08x**) | **1155 B** / <span style="color:gray">284,048 cc</span> (**4.32x**) |
| fannkuch | FAIL (error: Undefined temporary symbol 
1 error generated.) | **316 B** / <span style="color:gray">22,390,768 cc</span> | FAIL (error: Undefined temporary symbol 
1 error generated.) | **373 B** / <span style="color:gray">32,033,296 cc</span> | **1440 B** / <span style="color:gray">59,145,260 cc</span> |
| lfsr16 | **130 B** / <span style="color:gray">1,492,324 cc</span> (**1.00x**) | **130 B** / <span style="color:gray">1,492,324 cc</span> (**1.00x**) | **127 B** / <span style="color:gray">1,492,336 cc</span> (**1.00x**) | **176 B** / <span style="color:gray">2,623,212 cc</span> (**1.76x**) | **1019 B** / <span style="color:gray">4,473,860 cc</span> (**3.00x**) |

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
