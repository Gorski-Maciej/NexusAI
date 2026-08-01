#!/usr/bin/env python3
"""Analyze TRX firmware images (Asus RT-AC750).

TRX header layout (Broadcom):
  magic    : u32  = 0x30524448 ("HDR0")
  length   : u32  total length incl header
  crc32    : u32  CRC-32 of whole image
  flags    : u16
  version  : u16
  offsets  : u32[3]  partition offsets (kernel/rootfs)
"""
import struct, sys, zlib, os

def parse_trx(path):
    data = open(path, 'rb').read()
    print(f"=== {os.path.basename(path)} ===")
    print(f"size: {len(data)} bytes")
    magic, length, crc, flags, version = struct.unpack_from('<IIIIH', data, 0)
    ver_hi, flags16 = struct.unpack_from('<HH', data, 12)
    offs = struct.unpack_from('<III', data, 16)
    print(f"magic:      {magic:#010x} ({data[:4]!r})")
    print(f"length:     {length} (file size {len(data)})")
    print(f"crc32:      {crc:#010x}")
    print(f"flags:      {flags:#06x}  version: {version:#06x}")
    print(f"offsets:    kernel={offs[0]} rootfs={offs[1]} {offs[2]}")
    # CRC check: Asus trx crc covers entire file
    stored = crc
    # try standard: crc of whole file
    calc_whole = zlib.crc32(data) & 0xffffffff
    # OpenWrt trx: crc covers from offset 0 (excluding first 12 bytes? Actually covers whole image)
    # Asus bootloader checks crc over entire trx
    calc_from12 = zlib.crc32(data[12:]) & 0xffffffff if len(data) > 12 else 0
    print(f"crc whole file:  {calc_whole:#010x}  match={calc_whole==stored}")
    print(f"crc from byte12: {calc_from12:#010x}  match={calc_from12==stored}")
    return data

def analyze_uimage(data, offset):
    # uImage header: magic 0x27051956
    if offset + 64 > len(data):
        print(f"  no room for uImage at {offset}")
        return
    magic = struct.unpack_from('>I', data, offset)[0]
    if magic != 0x27051956:
        print(f"  @{offset}: no uImage magic ({magic:#010x})")
        return
    hcrc, ts, size, load, ep, dcrc = struct.unpack_from('>IIIIII', data, offset+4)
    name = data[offset+32:offset+64].split(b'\x00')[0]
    print(f"  uImage @{offset}: name={name!r} size={size} load={load:#x} ep={ep:#x}")
    print(f"    header crc: {hcrc:#010x}  data crc: {dcrc:#010x}")
    # verify header crc (hcrc covers first 64 bytes with hcrc zeroed)
    hdr = bytearray(data[offset:offset+64])
    hdr[4:8] = b'\x00\x00\x00\x00'
    calc_hcrc = zlib.crc32(bytes(hdr)) & 0xffffffff
    print(f"    calc hdr crc: {calc_hcrc:#010x}  match={calc_hcrc==hcrc}")
    # verify data crc
    if offset + 64 + size <= len(data):
        calc_dcrc = zlib.crc32(data[offset+64:offset+64+size]) & 0xffffffff
        print(f"    calc data crc: {calc_dcrc:#010x}  match={calc_dcrc==dcrc}")
    else:
        print(f"    data crc: cannot verify (data exceeds file)")
    return offset + 64 + size

for f in sys.argv[1:]:
    data = parse_trx(f)
    # find uImage right after trx header (28 bytes) or at offset[0]
    magic = struct.unpack_from('>I', data, 28)[0] if len(data) > 32 else 0
    print(f"  bytes 28..32 magic (BE): {magic:#010x}")
    for off in (28, 32):
        analyze_uimage(data, off)
    print()
