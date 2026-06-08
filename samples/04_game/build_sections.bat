@echo off

REM Update the path to emulator devector.exe if needed.
set s=samples\04_game\
set out=%s%out\
set e=C:\Work\Programming\devector\bin\devector.exe

REM Set the compiler and emulator paths.
set compiler=llvm-build\bin\clang
set emulator=tools\v6emul\v6emul

set target=-target i8080-unknown-v6c
set stack_addr=0x8000
set stack_def=-Wl,--defsym=__stack_top=%stack_addr%

REM Assemble the v6 library.
@echo on

tools\v6asm\v6asm.exe %s%\asm\v6\v6_interruption.asm -o %out%\v6_interruption.o -f obj -I %s%

@echo off
REM Check for build errors.
if %errorlevel% neq 0 exit /b %errorlevel%
@echo on

@echo off
REM Build the ROM. --print-gc-sections makes lld report every section it
REM garbage-collected (removed) during the link. -Map writes a link map that
REM lists every input section (per-function) that SURVIVED the garbage collection.
@echo on

%compiler% %target% -O2 %stack_def% -Wl,-Map=%out%\main.map %s%main.c %out%\v6_interruption.o -o %out%\main.o

@echo off
REM Check for build errors.
if %errorlevel% neq 0 exit /b %errorlevel%
@echo on

REM Compile asm
%compiler% %target% -O2 %s%main.c -S -o %out%\main.s

REM Print the merged output section headers in the linked ELF.
llvm-build\bin\llvm-readelf -S %out%\main.o

REM Print the link map: surviving input sections (per function) and their
REM addresses/sizes after garbage collection.
type %out%\main.map
