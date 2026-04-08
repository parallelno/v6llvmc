#!/usr/bin/env python3
"""Extract .text section from an ELF file and print hex bytes.

Usage: python elf_text_hex.py input.o
Output: space-separated uppercase hex bytes of .text section
"""
import struct
import sys

def main():
    with open(sys.argv[1], 'rb') as f:
        data = f.read()

    if data[:4] != b'\x7fELF':
        sys.exit("Not an ELF file")

    shoff = struct.unpack_from('<I', data, 32)[0]
    shentsize = struct.unpack_from('<H', data, 46)[0]
    shnum = struct.unpack_from('<H', data, 48)[0]
    shstrndx = struct.unpack_from('<H', data, 50)[0]

    strtab_base = shoff + shstrndx * shentsize
    strtab_off = struct.unpack_from('<I', data, strtab_base + 16)[0]

    for i in range(shnum):
        base = shoff + i * shentsize
        name_idx = struct.unpack_from('<I', data, base)[0]
        sh_type = struct.unpack_from('<I', data, base + 4)[0]
        sh_offset = struct.unpack_from('<I', data, base + 16)[0]
        sh_size = struct.unpack_from('<I', data, base + 20)[0]

        name_end = data.index(b'\x00', strtab_off + name_idx)
        name = data[strtab_off + name_idx:name_end].decode('ascii')

        if name == '.text' and sh_type == 1:
            text = data[sh_offset:sh_offset + sh_size]
            print(' '.join(f'{b:02X}' for b in text))
            return

    sys.exit("No .text section found")

if __name__ == '__main__':
    main()
