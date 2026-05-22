set s=samples\03_demo\
set target=-target i8080-unknown-v6c
set stack_addr=0x8000
set stack_def=-Wl,--defsym=__stack_top=%stack_addr%

llvm-build\bin\clang %target% -O2 %stack_def% %s%\main.c -o %s%\main.rom
if %errorlevel% neq 0 exit /b %errorlevel%

tools\v6emul\v6emul --rom %s%\main.rom --load-addr 0x100 --halt-exit --run-cycles 30000000

C:\Work\Programming\devector\bin\devector.exe %s%\main.rom
