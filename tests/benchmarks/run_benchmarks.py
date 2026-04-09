#!/usr/bin/env python3
"""Performance benchmark runner for M11 runtime library functions.

Assembles benchmark .asm files, executes in v6emul, extracts cycle counts.

Usage:
    python run_benchmarks.py [-v]
"""

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


ROOT = find_project_root()
BENCH_DIR = ROOT / "tests" / "benchmarks"
V6ASM = ROOT / "tools" / "v6asm" / "v6asm.exe"
V6EMUL = ROOT / "tools" / "v6emul" / "v6emul.exe"


def parse_header(asm_path):
    header = {"name": Path(asm_path).stem, "desc": "", "expect_output": []}
    with open(asm_path, "r") as f:
        for line in f:
            line = line.strip()
            if not line.startswith(";"):
                if line:
                    break
                continue
            line = line.lstrip("; ").strip()
            if line.startswith("TEST:"):
                header["name"] = line.split(":", 1)[1].strip()
            elif line.startswith("DESC:"):
                header["desc"] = line.split(":", 1)[1].strip()
            elif line.startswith("EXPECT_OUTPUT:"):
                vals = line.split(":", 1)[1].strip()
                header["expect_output"] = [
                    int(v.strip()) for v in vals.split(",") if v.strip()
                ]
    return header


def run_benchmark(asm_path, verbose=False):
    header = parse_header(asm_path)
    name = header["name"]

    with tempfile.TemporaryDirectory() as tmpdir:
        bin_path = os.path.join(tmpdir, "bench.bin")

        # Assemble
        r = subprocess.run(
            [str(V6ASM), str(asm_path), "-o", bin_path],
            capture_output=True, text=True, timeout=30,
        )
        if r.returncode != 0:
            return name, header["desc"], None, None, f"v6asm error: {r.stderr}"

        # Run
        r = subprocess.run(
            [str(V6EMUL), "--rom", bin_path, "--load-addr", "0",
             "--halt-exit", "--dump-cpu"],
            capture_output=True, text=True, timeout=30,
        )
        output_text = r.stdout + "\n" + r.stderr

        if verbose:
            print(f"    [output] {output_text.strip()[:300]}")

        # Extract outputs
        outputs = []
        for line in output_text.split("\n"):
            m = re.search(r"TEST_OUT port=0xED value=0x([0-9A-Fa-f]+)", line)
            if m:
                outputs.append(int(m.group(1), 16))

        # Extract cycle count
        cycles = None
        for line in output_text.split("\n"):
            m = re.search(r"after (\d+) cpu_cycles", line)
            if m:
                cycles = int(m.group(1))

        # Check correctness
        if outputs != header["expect_output"]:
            return name, header["desc"], cycles, False, \
                f"expected={header['expect_output']}, got={outputs}"

        return name, header["desc"], cycles, True, None


def main():
    verbose = "-v" in sys.argv or "--verbose" in sys.argv

    bench_files = sorted(BENCH_DIR.glob("bench_*.asm"))
    if not bench_files:
        print("No benchmark files found.")
        sys.exit(1)

    print("M11 Runtime Library Performance Benchmarks")
    print(f"  v6asm:  {V6ASM}")
    print(f"  v6emul: {V6EMUL}")
    print()
    print(f"  {'Benchmark':<20} {'Cycles':>10}  Description")
    print(f"  {'-'*20} {'-'*10}  {'-'*40}")

    all_pass = True
    for bench_file in bench_files:
        name, desc, cycles, ok, err = run_benchmark(bench_file, verbose)
        if ok:
            cyc_str = f"{cycles:,}" if cycles else "?"
            print(f"  {name:<20} {cyc_str:>10}  {desc}")
        else:
            all_pass = False
            print(f"  {name:<20}      FAIL  {err}")

    print()
    if all_pass:
        print("All benchmarks passed.")
    else:
        print("Some benchmarks failed!")
        sys.exit(1)


if __name__ == "__main__":
    main()
