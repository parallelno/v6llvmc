@echo off

REM Update the path to emulator devector.exe if needed.
set s=samples\04_game
set out=%s%\out
set app=%s%\app\music
set v6asm=tools\v6asm\v6asm.exe
set e=C:\Work\Programming\devector\bin\devector.exe

REM Set the compiler and emulator paths.
set compiler=llvm-build\bin\clang
set emulator=tools\v6emul\v6emul

set target=-target i8080-unknown-v6c
set stack_addr=0x8000
set stack_def=-Wl,--defsym=__stack_top=%stack_addr%

REM Assemble the v6 library.
%v6asm% %s%\asm\v6\v6_interruption.asm -o %out%\v6_interruption.o -f obj -I %s%
REM Check for build errors.
if %errorlevel% neq 0 exit /b %errorlevel%

REM Assemble the song01.
%v6asm% %app%\song01.asm -o %out%\song01.o -f obj -I %s%
REM Check for build errors.
if %errorlevel% neq 0 exit /b %errorlevel%

REM Build the ROM.
%compiler% %target% -O2 %stack_def% %s%\main.c %out%\v6_interruption.o %out%\song01.o -o %out%\main.rom

REM Check for build errors.
if %errorlevel% neq 0 exit /b %errorlevel%

REM Run the ROM in the emulator.
%e% %out%\main.rom
