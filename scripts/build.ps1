# Quick build: sync, configure, ninja, crt0.o, tests -- no dist/ packaging.
# Pass any extra arguments through to build_release.ps1 (e.g. -SkipTests, -SkipBuild).
& (Join-Path $PSScriptRoot 'build_release.ps1') -SkipPackage @args
