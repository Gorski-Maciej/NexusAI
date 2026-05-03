from pathlib import Path


def test_prompt_loader_and_renderer_exist() -> None:
    source = Path("Code/CORE/prompts.py").read_text(encoding="utf-8")
    assert "def _load_prompt_pack" in source
    assert "def render_prompt" in source
    assert "PromptTemplate" in source


def test_prompt_packs_present() -> None:
    pl = Path("Code/CORE/prompts/pl.json").read_text(encoding="utf-8")
    en = Path("Code/CORE/prompts/en.json").read_text(encoding="utf-8")
    assert "invoice_extractor" in pl
    assert "classifier" in en
