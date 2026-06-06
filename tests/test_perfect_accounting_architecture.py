from __future__ import annotations

import sys
from pathlib import Path

sys.path.append(str(Path(__file__).resolve().parents[1]))

from architecture.perfect_accounting_architecture import (
    REQUIRED_TECHNOLOGIES,
    build_blueprint,
    validate_blueprint_coverage,
)


def test_blueprint_covers_all_required_technologies() -> None:
    blueprint = build_blueprint()
    ok, missing = validate_blueprint_coverage(blueprint)

    assert ok is True
    assert missing == set()


def test_blueprint_contains_rich_component_model() -> None:
    blueprint = build_blueprint()

    assert len(blueprint.components) >= 7
    assert REQUIRED_TECHNOLOGIES.issubset(blueprint.technology_names())
    assert len(blueprint.ocr_pipeline) >= 2
    assert len(blueprint.ml_pipeline) >= 3
