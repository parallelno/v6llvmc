REM Update the path to emulator devector.exe if needed.
set s=samples\04_game\
set e=C:\Work\Programming\devector\bin\devector.exe

REM Set the compiler and emulator paths.
set compiler=llvm-build\bin\clang
set emulator=tools\v6emul\v6emul

set target=-target i8080-unknown-v6c
set stack_addr=0x8000
set stack_def=-Wl,--defsym=__stack_top=%stack_addr%

REM Assemble the v6 library.
tools\v6asm\v6asm.exe %s%\asm\v6\v6_interruption.asm -o %s%\out\v6_interruption.o -f obj -I %s%
REM Check for build errors.
if %errorlevel% neq 0 exit /b %errorlevel%

REM Build the ROM. --print-gc-sections makes lld report every section it
REM garbage-collected (removed) during the link.
%compiler% %target% -O2 %stack_def% -Wl,--print-gc-sections %s%main.c %s%\out\v6_interruption.o -o %s%\out\main.o
REM Check for build errors.
if %errorlevel% neq 0 exit /b %errorlevel%

REM Print the section headers that SURVIVED garbage collection in the linked ELF.
llvm-build\bin\llvm-readelf -S %s%\out\main.o
