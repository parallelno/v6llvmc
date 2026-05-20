llvm-build\bin\clang -O2 -target i8080-unknown-v6c main.c -o main.rom
if %errorlevel% neq 0 exit /b %errorlevel%
devector.exe main.rom
