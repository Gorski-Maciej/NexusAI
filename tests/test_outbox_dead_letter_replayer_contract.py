from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parents[1]


def test_outbox_dead_letter_replayer_contract() -> None:
    source = (PROJECT_ROOT / 'nexus_ai' / 'scripts' / 'outbox_dead_letter_replayer.py').read_text(encoding='utf-8')
    assert "--status-from" in source
    assert "--status-to" in source
    assert "--event-type" in source
    assert "--ids-file" in source
    assert "SET status=?" in source
    assert "--dry-run" in source
