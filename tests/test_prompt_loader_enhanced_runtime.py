from __future__ import annotations

import importlib.util
import sys
from pathlib import Path


def _load_module():
    path = Path('nexus_ai/CORE/prompts.py').resolve()
    spec = importlib.util.spec_from_file_location('prompts_mod', path)
    assert spec and spec.loader
    mod = importlib.util.module_from_spec(spec)
    sys.modules[spec.name] = mod
    spec.loader.exec_module(mod)
    return mod


def test_render_prompt_accepts_context() -> None:
    mod = _load_module()
    out = mod.render_prompt(mod.PromptTemplate.CLASSIFIER, 'sample', lang='en', context={'company': 'Nexus'})
    assert 'Document content' in out


def test_missing_context_key_raises_value_error() -> None:
    mod = _load_module()
    try:
        mod._render_with_context('Hello {missing}', {'other': 'x'})
    except ValueError as exc:
        assert 'Missing prompt context key' in str(exc)
    else:
        raise AssertionError('Expected ValueError')


def test_prompt_pack_has_all_templates() -> None:
    mod = _load_module()
    pack = mod._load_prompt_pack('pl')
    for template in mod.PromptTemplate:
        assert template in pack
