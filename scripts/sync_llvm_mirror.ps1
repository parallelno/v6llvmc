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

Write-Host "Mirror sync complete."
