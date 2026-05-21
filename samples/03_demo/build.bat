set s=samples\03_demo\
llvm-build\bin\clang -O2 -target i8080-unknown-v6c %s%\main.c -o %s%\main.rom
if %errorlevel% neq 0 exit /b %errorlevel%
C:\Work\Programming\devector\bin\devector.exe %s%\main.rom
