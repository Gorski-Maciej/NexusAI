from pathlib import Path

ROOT = Path('.')
OUT = ROOT / 'all_python_code.pdf'
py_files = sorted(p for p in ROOT.rglob('*.py') if '.git' not in p.parts)

content_lines = []
for p in py_files:
    rel = p.as_posix()
    content_lines.append(f"===== {rel} =====")
    try:
        text = p.read_text(encoding='utf-8')
    except UnicodeDecodeError:
        text = p.read_text(encoding='latin-1')
    content_lines.extend(text.splitlines())
    content_lines.append('')

# Very simple PDF writer using base14 Courier font
page_w, page_h = 612, 792
left, top, bottom = 40, 760, 40
font_size = 9
line_h = 11
max_lines = (top - bottom) // line_h

# escape PDF string chars

def esc(s: str) -> str:
    return s.replace('\\', '\\\\').replace('(', '\\(').replace(')', '\\)')

pages = []
for i in range(0, len(content_lines), max_lines):
    chunk = content_lines[i:i+max_lines]
    y = top
    cmds = ['BT', f'/F1 {font_size} Tf']
    for line in chunk:
        cmds.append(f'1 0 0 1 {left} {y} Tm ({esc(line)[:180]}) Tj')
        y -= line_h
    cmds.append('ET')
    pages.append('\n'.join(cmds).encode('latin-1', errors='replace'))

objects = []

# 1: Catalog, 2: Pages, 3.. page objs + streams + font
font_obj_num = 3 + len(pages)*2

objects.append(b'<< /Type /Catalog /Pages 2 0 R >>')

kids = ' '.join(f'{3+i*2} 0 R' for i in range(len(pages)))
objects.append(f'<< /Type /Pages /Count {len(pages)} /Kids [{kids}] >>'.encode())

for idx, stream in enumerate(pages):
    page_obj = f'<< /Type /Page /Parent 2 0 R /MediaBox [0 0 {page_w} {page_h}] /Resources << /Font << /F1 {font_obj_num} 0 R >> >> /Contents {4+idx*2} 0 R >>'
    objects.append(page_obj.encode())
    cont = b'<< /Length ' + str(len(stream)).encode() + b' >>\nstream\n' + stream + b'\nendstream'
    objects.append(cont)

objects.append(b'<< /Type /Font /Subtype /Type1 /BaseFont /Courier >>')

pdf = bytearray(b'%PDF-1.4\n')
offsets = [0]
for i, obj in enumerate(objects, start=1):
    offsets.append(len(pdf))
    pdf.extend(f'{i} 0 obj\n'.encode())
    pdf.extend(obj)
    pdf.extend(b'\nendobj\n')

xref_pos = len(pdf)
pdf.extend(f'xref\n0 {len(objects)+1}\n'.encode())
pdf.extend(b'0000000000 65535 f \n')
for off in offsets[1:]:
    pdf.extend(f'{off:010d} 00000 n \n'.encode())
pdf.extend(f'trailer\n<< /Size {len(objects)+1} /Root 1 0 R >>\nstartxref\n{xref_pos}\n%%EOF\n'.encode())

OUT.write_bytes(pdf)
print(f'Wrote {OUT} with {len(py_files)} files and {len(pages)} pages')
