# sync_llvm_mirror.ps1
# Syncs all V6C-related modifications from llvm-project/ (gitignored build source)
# into llvm/ (git-tracked mirror). Run after every successful build.
#
# V6C target directory — full mirror (all files are ours)
# Upstream modified files — individual copies (only our changes to LLVM files)

$root = Split-Path $PSScriptRoot -Parent
if (-not $root) { $root = Split-Path (Get-Location) -Parent }

# V6C backend target directory
robocopy "$root\llvm-project\llvm\lib\Target\V6C" "$root\llvm\lib\Target\V6C" /MIR /NFL /NDL /NJH /NJS

# Modified upstream LLVM files
# M1: i8080 architecture registration in Triple
xcopy /Y /I "$root\llvm-project\llvm\include\llvm\TargetParser\Triple.h" "$root\llvm\include\llvm\TargetParser\" > $null
xcopy /Y /I "$root\llvm-project\llvm\lib\TargetParser\Triple.cpp" "$root\llvm\lib\TargetParser\" > $null

# M9: Clang frontend integration
# TargetInfo (Basic/Targets)
xcopy /Y /I "$root\llvm-project\clang\lib\Basic\Targets\I8080.h" "$root\clang\lib\Basic\Targets\" > $null
xcopy /Y /I "$root\llvm-project\clang\lib\Basic\Targets\I8080.cpp" "$root\clang\lib\Basic\Targets\" > $null
xcopy /Y /I "$root\llvm-project\clang\lib\Basic\Targets.cpp" "$root\clang\lib\Basic\" > $null
xcopy /Y /I "$root\llvm-project\clang\lib\Basic\CMakeLists.txt" "$root\clang\lib\Basic\" > $null
# TargetCodeGenInfo (CodeGen/Targets)
if (-not (Test-Path "$root\clang\lib\CodeGen\Targets")) { New-Item -ItemType Directory -Path "$root\clang\lib\CodeGen\Targets" -Force > $null }
xcopy /Y /I "$root\llvm-project\clang\lib\CodeGen\Targets\V6C.cpp" "$root\clang\lib\CodeGen\Targets\" > $null
xcopy /Y /I "$root\llvm-project\clang\lib\CodeGen\TargetInfo.h" "$root\clang\lib\CodeGen\" > $null
xcopy /Y /I "$root\llvm-project\clang\lib\CodeGen\CodeGenModule.cpp" "$root\clang\lib\CodeGen\" > $null
xcopy /Y /I "$root\llvm-project\clang\lib\CodeGen\CMakeLists.txt" "$root\clang\lib\CodeGen\" > $null
# Driver ToolChain
if (-not (Test-Path "$root\clang\lib\Driver\ToolChains")) { New-Item -ItemType Directory -Path "$root\clang\lib\Driver\ToolChains" -Force > $null }
xcopy /Y /I "$root\llvm-project\clang\lib\Driver\ToolChains\V6C.h" "$root\clang\lib\Driver\ToolChains\" > $null
xcopy /Y /I "$root\llvm-project\clang\lib\Driver\ToolChains\V6C.cpp" "$root\clang\lib\Driver\ToolChains\" > $null
xcopy /Y /I "$root\llvm-project\clang\lib\Driver\Driver.cpp" "$root\clang\lib\Driver\" > $null
xcopy /Y /I "$root\llvm-project\clang\lib\Driver\CMakeLists.txt" "$root\clang\lib\Driver\" > $null
# Clang.cpp (unsigned char default)
xcopy /Y /I "$root\llvm-project\clang\lib\Driver\ToolChains\Clang.cpp" "$root\clang\lib\Driver\ToolChains\" > $null

Write-Host "Mirror sync complete."
