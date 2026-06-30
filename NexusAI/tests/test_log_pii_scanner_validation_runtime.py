from __future__ import annotations

from pathlib import Path

from nexus_ai.scripts.log_pii_scanner import scan_path, scan_text


def test_nip_checksum_reduces_false_positives() -> None:
    bad = scan_text('NIP: 123-456-78-90')
    good = scan_text('NIP: 8567346215')
    assert bad == []
    assert any(item.pattern == 'NIP' for item in good)


def test_scan_path_directory_support(tmp_path: Path) -> None:
    (tmp_path / 'a.log').write_text('PESEL 44051401458', encoding='utf-8')
    (tmp_path / 'b.txt').write_text('SAFE', encoding='utf-8')
    out = scan_path(tmp_path)
    assert str(tmp_path / 'a.log') in out
    assert len(out[str(tmp_path / 'a.log')]) == 1
