from pathlib import Path


def test_outbox_dead_letter_replayer_contract() -> None:
    source = Path('Code/scripts/outbox_dead_letter_replayer.py').read_text(encoding='utf-8')
    assert "--status-from" in source
    assert "--status-to" in source
    assert "--event-type" in source
    assert "--ids-file" in source
    assert "SET status=?" in source
    assert "--dry-run" in source
