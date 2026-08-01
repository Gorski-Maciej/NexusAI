#!/usr/bin/env python3
"""Rebuild RT-AC750_NEXUSAI.trx with the correct structure so the router accepts it.

Root cause of rejection (identical for MODIFIED and NEXUSAI):
  The original Asus image ends EXACTLY at the squashfs end (trailing = 0 bytes)
  and its uImage `size` field equals kernel_len + squashfs bytes_used (MATCH=True).
  The modified files padded the image with trailing zeros and set the uImage
  size field to the padded length (kernel+squashfs != size => MATCH=False).
  The Asus web updater / CFE validates this consistency and rejects the file
  with "The file format or path is not available".

Fix (minimal): reuse the already-built squashfs (it already contains the 3
injected files), truncate the trailing zero padding so the file ends exactly
at the squashfs end like the original, set uImage size = kernel+squashfs,
and recompute the uImage header CRC (hcrc) and data CRC (dcrc).
"""
import struct, zlib, sys, os

SRC = 'RT-AC750_NEXUSAI.trx'
DST = 'RT-AC750_NEXUSAI_v2.trx'
SQUASHFS_OFF = 0x11ee00   # file offset where "hsqs" magic starts (fallback)

def be32(b): return struct.unpack('>I', b)[0]
def crc(b):  return zlib.crc32(b) & 0xffffffff

d = bytearray(open(SRC, 'rb').read())
orig_len = len(d)
print(f'source: {SRC} len={orig_len} (0x{orig_len:x})')

# --- 1. locate squashfs superblock dynamically, read bytes_used (offset 40, LE u64) ---
SQUASHFS_OFF = d.find(b'hsqs')
assert SQUASHFS_OFF > 0, 'squashfs magic "hsqs" not found'
assert d[SQUASHFS_OFF:SQUASHFS_OFF+4] == b'hsqs', 'squashfs magic missing'
bytes_used = struct.unpack_from('<Q', d, SQUASHFS_OFF + 40)[0]
sq_end = SQUASHFS_OFF + bytes_used
kernel_len = SQUASHFS_OFF - 64
print(f'squashfs: start=0x{SQUASHFS_OFF:x} bytes_used={bytes_used} end=0x{sq_end:x}')
print(f'kernel len (64..0x{SQUASHFS_OFF:x}) = {kernel_len}')

# safety: never drop meaningful data - all removed bytes must be zeros
assert sq_end <= orig_len, 'squashfs end beyond file?!'
assert all(b == 0 for b in d[sq_end:]), (
    f'non-zero data after squashfs at 0x{sq_end:x}; refusing to truncate')

# trailing bytes in current file
trailing = orig_len - sq_end
print(f'current trailing zeros after squashfs = {trailing} bytes')

# --- 2. truncate to squashfs end ---
new_len = sq_end
data_len = new_len - 64                       # uImage data size field
print(f'new file len = {new_len} (0x{new_len:x})  uImage size field = {data_len}')

# --- 3. fix uImage header: size @12 (BE) ---
hdr = bytearray(d[:64])
struct.pack_into('>I', hdr, 12, data_len)

# --- 4. compute data CRC over [64 : 64+data_len], write dcrc @24 ---
data = bytes(d[64:64+data_len])
new_dcrc = crc(data)
struct.pack_into('>I', hdr, 24, new_dcrc)

# --- 4b. compute header CRC LAST (hcrc covers first 64 bytes incl. dcrc/size) ---
hcrc_zeroed = bytearray(hdr)
struct.pack_into('>I', hcrc_zeroed, 4, 0)
new_hcrc = crc(bytes(hcrc_zeroed))
struct.pack_into('>I', hdr, 4, new_hcrc)

# --- 5. assemble ---
out = bytes(hdr) + data
assert len(out) == new_len, (len(out), new_len)

open(DST, 'wb').write(out)
print(f'wrote: {DST} len={len(out)} (0x{len(out):x})')

# --- 6. verify ---
magic, hcrc, ts, size, load, ep, dcrc = struct.unpack_from('>IIIIIII', out, 0)
h = bytearray(out[:64]); struct.pack_into('>I', h, 4, 0)
ok_hcrc = crc(bytes(h)) == hcrc
ok_dcrc = crc(out[64:64+size]) == dcrc
ok_size = size == (SQUASHFS_OFF - 64) + struct.unpack_from('<Q', out, SQUASHFS_OFF + 40)[0]
ok_trailing = (len(out) - (SQUASHFS_OFF + struct.unpack_from('<Q', out, SQUASHFS_OFF + 40)[0])) == 0
print(f'verify: magic={magic:#x} hcrc_ok={ok_hcrc} dcrc_ok={ok_dcrc} '
      f'size==kernel+squashfs={ok_size} trailing==0={ok_trailing}')
print(f'verify: file size {len(out)} vs original {orig_len} '
      f'(delta {len(out)-orig_len:+d})')
print('ALL OK' if all([ok_hcrc, ok_dcrc, ok_size, ok_trailing]) else 'FAILED')
