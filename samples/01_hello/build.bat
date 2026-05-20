@echo off
clang -O2 -target i8080-unknown-v6c main.c -o main.rom
if %errorlevel% neq 0 exit /b %errorlevel%
v6emul --rom main.rom --load-addr 0x0100 --halt-exit --dump-cpu
