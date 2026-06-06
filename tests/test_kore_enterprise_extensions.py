from __future__ import annotations

from pathlib import Path


def test_hardware_has_hot_swap() -> None:
    source = Path("Code/core/hardware.py").read_text(encoding="utf-8")
    assert "def hot_swap_model" in source
    assert "Phi-3-mini" in source


def test_ocr_consensus_exists() -> None:
    source = Path("Code/pipeline/ocr_consensus.py").read_text(encoding="utf-8")
    assert "def decide_amount_consensus" in source
    assert "confidence_conflict" in source
