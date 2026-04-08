#!/usr/bin/env python3
"""Verify v6asm output against expected opcode bytes from all_opcodes.asm."""

import re
import sys

def parse_expected(asm_path):
    """Parse expected bytes from comments in asm file."""
    entries = []
    with open(asm_path, 'r') as f:
        for lineno, line in enumerate(f, 1):
            # Match lines with Expected: 0xNN 0xNN ...
            m = re.search(r';\s*Expected:\s*((?:0x[0-9A-Fa-f]{2}\s*)+)', line)
            if m:
                hex_str = m.group(1).strip()
                expected = [int(h, 16) for h in re.findall(r'0x([0-9A-Fa-f]{2})', hex_str)]
                # Extract instruction mnemonic (strip leading whitespace and comments)
                instr = line.split(';')[0].strip()
                entries.append((lineno, instr, expected))
    return entries

def main():
    asm_path = 'tests/unit/encoding/all_opcodes.asm'
    rom_path = 'tests/unit/encoding/all_opcodes.rom'

    entries = parse_expected(asm_path)

    with open(rom_path, 'rb') as f:
        rom = f.read()

    offset = 0
    errors = 0
    total = 0

    for lineno, instr, expected in entries:
        total += 1
        nbytes = len(expected)
        actual = list(rom[offset:offset + nbytes])

        if actual != expected:
            errors += 1
            exp_str = ' '.join(f'0x{b:02X}' for b in expected)
            act_str = ' '.join(f'0x{b:02X}' for b in actual)
            print(f'FAIL line {lineno}: {instr}')
            print(f'  Expected: {exp_str}')
            print(f'  Actual:   {act_str}')

        offset += nbytes

    if offset != len(rom):
        print(f'\nWARNING: ROM is {len(rom)} bytes but expected {offset} bytes from instructions')

    if errors == 0:
        print(f'OK: All {total} instruction encodings match.')
    else:
        print(f'\nFAILED: {errors}/{total} instruction encodings did not match.')

    return 1 if errors else 0

if __name__ == '__main__':
    sys.exit(main())
