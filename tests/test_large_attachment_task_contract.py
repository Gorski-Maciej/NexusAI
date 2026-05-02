from pathlib import Path


def test_large_attachment_outbox_dispatch_contract() -> None:
    source = Path('Code/API/tasks.py').read_text(encoding='utf-8')
    assert 'if event_type == "attachment_large_uploaded"' in source
    assert 'await broker.kick("process_large_attachment"' in source
    assert '@broker.task(task_name="process_large_attachment")' in source
