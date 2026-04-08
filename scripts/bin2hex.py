#!/usr/bin/env python3
"""Convert a flat binary file to Intel HEX format.

Usage:
    python bin2hex.py input.bin -o output.hex [--base 0x0100]

Intel HEX record format:
    :LLAAAATT[DD...]CC
    LL = byte count, AAAA = address, TT = type, DD = data, CC = checksum
    Type 00 = data, Type 01 = EOF
"""

import argparse
import sys


def checksum(record_bytes):
    """Compute Intel HEX checksum (two's complement of sum of bytes)."""
    return (~sum(record_bytes) + 1) & 0xFF


def bin_to_hex(data, base_addr=0, bytes_per_line=16):
    """Convert binary data to Intel HEX format lines."""
    lines = []
    offset = 0

    while offset < len(data):
        count = min(bytes_per_line, len(data) - offset)
        addr = base_addr + offset

        if addr > 0xFFFF:
            raise ValueError(f"Address 0x{addr:X} exceeds 16-bit range")

        record = [count, (addr >> 8) & 0xFF, addr & 0xFF, 0x00]
        record.extend(data[offset:offset + count])
        cs = checksum(record)
        hex_data = ''.join(f'{b:02X}' for b in record)
        lines.append(f':{hex_data}{cs:02X}')
        offset += count

    # EOF record
    lines.append(':00000001FF')
    return '\n'.join(lines) + '\n'


def main():
    parser = argparse.ArgumentParser(description='Convert binary to Intel HEX')
    parser.add_argument('input', help='Input flat binary file')
    parser.add_argument('-o', '--output', required=True, help='Output .hex file')
    parser.add_argument('--base', type=lambda x: int(x, 0), default=0x0100,
                        help='Base address (default: 0x0100)')
    args = parser.parse_args()

    with open(args.input, 'rb') as f:
        data = f.read()

    hex_str = bin_to_hex(data, args.base)

    with open(args.output, 'w') as f:
        f.write(hex_str)

    print(f"Intel HEX: {len(data)} bytes at 0x{args.base:04X}, "
          f"written to {args.output}")


if __name__ == '__main__':
    sys.exit(main() or 0)
