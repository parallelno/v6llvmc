#!/usr/bin/env python3
"""
Runtime library test runner for the Vector 06c LLVM backend.

Assembles .asm test files in tests/runtime/ with v6asm,
executes in v6emul, and checks results against expected values.
Uses the same test header format as the golden test runner.
"""

import argparse
import os
import re
import subprocess
import sys
import tempfile
from pathlib import Path


def find_project_root():
    p = Path(__file__).resolve()
    for parent in [p] + list(p.parents):
        if (parent / "design").is_dir():
            return parent
    return Path.cwd()


def parse_test_header(asm_path):
    header = {
        "name": Path(asm_path).stem,
        "desc": "",
        "expect_halt": False,
        "expect_output": [],
    }
    with open(asm_path, "r") as f:
        for line in f:
            line = line.strip()
            if not line.startswith(";"):
                if line and not line.startswith("//"):
                    break
                continue
            line = line.lstrip("; ").strip()
            if line.startswith("TEST:"):
                header["name"] = line.split(":", 1)[1].strip()
            elif line.startswith("DESC:"):
                header["desc"] = line.split(":", 1)[1].strip()
            elif line.startswith("EXPECT_HALT:"):
                header["expect_halt"] = line.split(":", 1)[1].strip().lower() == "yes"
            elif line.startswith("EXPECT_OUTPUT:"):
                vals = line.split(":", 1)[1].strip()
                header["expect_output"] = [int(v.strip()) for v in vals.split(",") if v.strip()]
    return header


def run_test(asm_path, v6asm, v6emul, verbose=False):
    header = parse_test_header(asm_path)
    name = header["name"]

    with tempfile.TemporaryDirectory() as tmpdir:
        bin_path = os.path.join(tmpdir, "test.bin")

        # Assemble
        result = subprocess.run(
            [v6asm, str(asm_path), "-o", bin_path],
            capture_output=True, text=True
        )
        if result.returncode != 0:
            return name, "FAIL", f"Assembly failed: {result.stderr.strip()}"

        # Execute
        result = subprocess.run(
            [v6emul, "--rom", bin_path, "--load-addr", "0", "--halt-exit", "--dump-cpu"],
            capture_output=True, text=True, timeout=10
        )
        output = result.stdout

        if verbose:
            print(f"  [debug] {name}: {output.strip()}")

        # Check halt
        if header["expect_halt"]:
            if "HALT" not in output:
                return name, "FAIL", "Expected HALT but did not halt"

        # Check output values
        actual_outputs = []
        for line in output.split("\n"):
            m = re.match(r"TEST_OUT port=0x[Ee][Dd] value=0x([0-9A-Fa-f]+)", line)
            if m:
                actual_outputs.append(int(m.group(1), 16))

        expected = header["expect_output"]
        if actual_outputs != expected:
            return name, "FAIL", f"Expected output {expected}, got {actual_outputs}"

        # Extract cycle count
        cycles = "?"
        for line in output.split("\n"):
            m = re.match(r"HALT at PC=\S+ after (\d+) cpu_cycles", line)
            if m:
                cycles = m.group(1)

        return name, "PASS", f"OK ({cycles}cc)"


def main():
    parser = argparse.ArgumentParser(description="Runtime library test runner")
    parser.add_argument("-v", "--verbose", action="store_true")
    args = parser.parse_args()

    root = find_project_root()
    test_dir = root / "tests" / "runtime"
    v6asm = str(root / "tools" / "v6asm" / "v6asm.exe")
    v6emul = str(root / "tools" / "v6emul" / "v6emul.exe")

    if not test_dir.exists():
        print(f"Error: test directory not found: {test_dir}")
        sys.exit(1)

    test_files = sorted(test_dir.glob("test_*.asm"))
    if not test_files:
        print("No runtime test files found.")
        sys.exit(1)

    print(f"Running {len(test_files)} runtime library tests...")
    print(f"  v6asm:  {v6asm}")
    print(f"  v6emul: {v6emul}")
    print()

    passed = 0
    failed = 0
    for tf in test_files:
        name, status, msg = run_test(tf, v6asm, v6emul, verbose=args.verbose)
        if status == "PASS":
            print(f"  PASS: {name} - {msg}")
            passed += 1
        else:
            print(f"  FAIL: {name} - {msg}")
            failed += 1

    print(f"\nResults: {passed} passed, {failed} failed, {passed + failed} total")
    return 0 if failed == 0 else 1


if __name__ == "__main__":
    sys.exit(main())
