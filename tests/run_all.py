#!/usr/bin/env python3
"""
Master test runner for the Vector 06c LLVM backend project.

Runs all available test suites and reports aggregate results.
"""

import argparse
import subprocess
import sys
from pathlib import Path


def find_project_root():
    p = Path(__file__).resolve()
    for parent in [p] + list(p.parents):
        if (parent / "design").is_dir():
            return parent
    return Path.cwd()


def run_suite(name, cmd, cwd):
    """Run a test suite and return (passed, output)."""
    print(f"\n{'='*60}")
    print(f"  {name}")
    print(f"{'='*60}\n")
    try:
        result = subprocess.run(
            cmd, cwd=str(cwd), timeout=300,
            capture_output=False  # let output flow through
        )
        return result.returncode == 0
    except FileNotFoundError:
        print(f"  SKIPPED: command not found ({cmd[0]})")
        return None
    except subprocess.TimeoutExpired:
        print(f"  TIMEOUT: suite exceeded 5 minute limit")
        return False


def main():
    parser = argparse.ArgumentParser(description="Run all V6C test suites")
    parser.add_argument("--golden-only", action="store_true", help="Run only golden tests")
    args = parser.parse_args()

    root = find_project_root()
    results = {}

    # Golden tests (always available)
    ok = run_suite(
        "Golden Tests (Emulator Trust Baseline)",
        [sys.executable, str(root / "tests" / "run_golden_tests.py")],
        root
    )
    results["golden"] = ok

    if not args.golden_only:
        # Lit tests — source of truth in llvm-project/, mirrors to tests/lit/
        lit_dirs = [
            root / "llvm-project" / "llvm" / "test" / "CodeGen" / "V6C",
            root / "llvm-project" / "llvm" / "test" / "MC" / "V6C",
            root / "llvm-project" / "clang" / "test" / "CodeGen" / "V6C",
        ]
        lit_paths = [str(d) for d in lit_dirs if d.exists() and (any(d.rglob("*.ll")) or any(d.rglob("*.c")))]
        if lit_paths:
            ok = run_suite(
                "Lit Tests (FileCheck)",
                ["lit"] + lit_paths + ["-v"],
                root
            )
            results["lit"] = ok

        # Emulator round-trip tests (available from M4+)
        emu_test_script = root / "tests" / "run_emulator_tests.py"
        if emu_test_script.exists():
            ok = run_suite(
                "Emulator Round-Trip Tests",
                [sys.executable, str(emu_test_script)],
                root
            )
            results["emulator"] = ok

    # Summary
    print(f"\n{'='*60}")
    print(f"  SUMMARY")
    print(f"{'='*60}\n")

    total = 0
    passed = 0
    skipped = 0
    for name, result in results.items():
        if result is None:
            status = "SKIPPED"
            skipped += 1
        elif result:
            status = "PASS"
            passed += 1
        else:
            status = "FAIL"
        total += 1
        print(f"  {name:30s} {status}")

    print(f"\n  {passed}/{total - skipped} suites passed", end="")
    if skipped:
        print(f" ({skipped} skipped)", end="")
    print()

    failed = total - skipped - passed
    sys.exit(0 if failed == 0 else 1)


if __name__ == "__main__":
    main()
