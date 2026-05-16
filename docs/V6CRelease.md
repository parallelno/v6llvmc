# V6C Release Procedure

Releases are produced by `.github/workflows/release.yml`, which is
triggered by pushing an annotated tag matching `v*` (or via the
**Run workflow** button on the Actions page). The job builds clang +
llc + lld + llvm-objcopy on `windows-latest`, packages the
`dist/v6c-<version>-windows-x64/` tree, and attaches the `.zip` to a
GitHub Release named after the tag.

## Naming Convention

Tags follow `vYYYY.MM.DD` (UTC date of the cut). Patch suffixes
(`-1`, `-2`) are allowed if the same day produces multiple drops.

## Manual Steps

```powershell
# 1. Confirm working tree is clean and main is in sync with origin.
git status
git pull --ff-only origin main

# 2. Sanity-check the build and tests locally.
cmd /c '"C:\Program Files\Microsoft Visual Studio\2022\Community\Common7\Tools\VsDevCmd.bat" -arch=amd64 >nul 2>&1 && ninja -C llvm-build clang llc'
python tests\run_all.py

# 3. Pick the version (UTC date).
$version = "v$(Get-Date -Format 'yyyy.MM.dd' -AsUTC)"

# 4. Create an annotated tag with release notes in the message.
$msg = @"
$version

Highlights:
- <one-line summary of the most user-visible fix>
- <next bullet>

Backend fixes since previous tag:
- ...

Benchmarks / docs:
- ...
"@
git tag -a $version -m $msg

# 5. Verify the tag, then push it (this triggers the workflow).
git tag -n10 $version
git push origin $version
```

## Verifying the Workflow

```powershell
# Watch the run on GitHub Actions:
Start-Process "https://github.com/parallelno/v6llvmc/actions"
```

The workflow finishes by creating a draft Release. Edit it on GitHub to
flesh out the release notes if needed, then publish.

## Rolling Back a Bad Tag

If the workflow fails or the tag was created in error:

```powershell
# Delete locally and on origin (also deletes the workflow's draft release
# manually via the Releases page if one was created).
git tag -d v2026.04.29
git push origin :refs/tags/v2026.04.29
```

Avoid re-using the same tag name after a publish — bump to the next
patch suffix (e.g. `v2026.04.29-1`) instead.

## Workflow Inputs

`workflow_dispatch` accepts an optional `version` input that overrides
the auto-derived UTC date. Use it for off-cycle drops without creating
a git tag (the workflow will still tag/release internally using the
override).
