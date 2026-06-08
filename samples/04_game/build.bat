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
tools\v6asm\v6asm.exe %s%\asm\v6\v6_interruption.asm -o %out%\v6_interruption.o -f obj -I %s%
REM Check for build errors.
if %errorlevel% neq 0 exit /b %errorlevel%

REM Build the ROM.
%compiler% %target% -O2 %stack_def% %s%main.c %out%\v6_interruption.o -o %out%\main.rom

REM Check for build errors.
if %errorlevel% neq 0 exit /b %errorlevel%

REM Run the ROM in the emulator.
%e% %out%\main.rom
