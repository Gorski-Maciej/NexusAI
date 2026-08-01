#!/usr/bin/env python3
"""Deep analysis of the 3 firmware images: squashfs superblock, section layout, padding."""
import struct

FILES = [
    'RT-AC750_3.0.0.4_380_8591-ga8dd632 (1).trx',
    'RT-AC750_MODIFIED.trx',
    'RT-AC750_NEXUSAI.trx',
]

for f in FILES:
    d = open(f, 'rb').read()
    print('=' * 70)
    print(f, 'len', len(d), hex(len(d)))
    # uImage header
    magic, hcrc, ts, size, load, ep, dcrc = struct.unpack_from('>IIIIIII', d, 0)
    name_raw = d[32:64]
    print(f'uImage: size={size} ts={ts:#x} name_raw={name_raw!r}')
    # find squashfs magic "hsqs" anywhere
    idx = d.find(b'hsqs')
    print(f'first "hsqs" at file offset {idx} (0x{idx:x})')
    if idx >= 0:
        sb = d[idx:idx+96]
        vals = struct.unpack_from('<IIIIIHHHHHHQQQQQQQQ', sb, 0)
        magic2, inode_cnt, modtime, blocksize, fragcnt, comp_id, blklg, flags, idcnt, ver_maj, ver_min, root_inode, bytes_used, id_table, xattr_table, inode_table, dir_table, frag_table, export_table = vals
        print(f'squashfs @0x{idx:x}: inodes={inode_cnt} modtime={modtime} blocksize={blocksize} '
              f'comp={comp_id} blklg={blklg} flags={flags:#x} idcnt={idcnt} ver={ver_maj}.{ver_min} '
              f'root_inode={root_inode} bytes_used={bytes_used}')
        print(f'  squashfs logical end = 0x{idx + bytes_used:x} ; file end = 0x{len(d):x} ; '
              f'trailing = {len(d) - (idx + bytes_used)} bytes')
        # check what is between squashfs end and file end: all zeros?
        tail = d[idx + bytes_used:]
        nz = sum(1 for b in tail if b != 0)
        print(f'  trailing bytes total={len(tail)} nonzero={nz}')
    # find where "hsqs" occurs: also check if there are multiple
    starts = []
    pos = 0
    while True:
        pos = d.find(b'hsqs', pos)
        if pos < 0:
            break
        starts.append(pos)
        pos += 4
    print('all hsqs occurrences:', [hex(s) for s in starts])
