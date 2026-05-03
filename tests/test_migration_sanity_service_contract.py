from pathlib import Path


def test_migration_sanity_service_checksum_contract() -> None:
    source = Path('Code/SERVICES/migration_sanity.py').read_text(encoding='utf-8')
    assert 'def verify_migration_checksums' in source
    assert 'checksum_drift' in source
    assert 'def capture_table_checksums' in source
