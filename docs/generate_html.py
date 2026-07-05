#!/usr/bin/env python3
"""generate_html.py — Generuje pojedynczy plik HTML z dokumentacji NexusAI.

Użycie:
    python docs/generate_html.py              # Standardowy HTML (light mode default)
    python docs/generate_html.py --dark        # Wariant dark mode
    python docs/generate_html.py --offline     # Pobiera Mermaid.js lokalnie (offline)
    python docs/generate_html.py --pdf         # Próbuje wygenerować PDF (weasyprint)
    python docs/generate_html.py --dark --offline  # Wariant dark + offline

Wynik:
    docs/nexusai_dokumentacja.html            # Light mode (domyślnie)
    docs/nexusai_dokumentacja_dark.html       # Dark mode (z --dark)

Wymagania: Python ≥3.9 (tylko biblioteka standardowa)
    Opcjonalnie: weasyprint (dla --pdf), requests (dla --offline)
"""

from __future__ import annotations

import argparse
import base64
import os
import re
import time
from pathlib import Path
from datetime import datetime

DOCS_DIR = Path(__file__).resolve().parent
PROJECT_ROOT = DOCS_DIR.parent
OUTPUT_FILE = DOCS_DIR / "nexusai_dokumentacja.html"
OUTPUT_FILE_DARK = DOCS_DIR / "nexusai_dokumentacja_dark.html"
LOGO_PATH = PROJECT_ROOT / "assets" / "nexus.png"
MERMAID_LOCAL = DOCS_DIR / "mermaid.min.js"
MERMAID_CDN = "https://cdn.jsdelivr.net/npm/mermaid@11/dist/mermaid.min.js"

CHAPTERS = [
    ("Strona tytułowa", "00_META.md"),
    ("README", "../README.md"),
    ("Wprowadzenie", "INTRODUCTION.md"),
    ("Szybki start", "QUICKSTART.md"),
    ("Struktura projektu", "PROJECT_STRUCTURE.md"),
    ("Skrypty CLI", "SCRIPTS.md"),
    ("Instalator Windows / OTA", "INSTALLER.md"),
    ("Frontend (Flet UI)", "FRONTEND.md"),
    ("Event Sourcing / CQRS", "EVENTS.md"),
    ("Pipeline OCR", "PIPELINE.md"),
    ("AI Inference", "INFERENCE.md"),
    ("Monitoring systemu", "MONITORING.md"),
    ("HTTP Client", "HTTP_CLIENT.md"),
    ("Konfiguracja systemu", "CONFIG.md"),
    ("Warstwa Domenowa (DDD)", "DOMAIN.md"),
    ("CI/CD Workflows", "WORKFLOWS.md"),
    ("Engine PDF (PDFium)", "PDFIUM.md"),
    ("System Decyzyjny", "DECISIONS.md"),
    ("Konfiguracja Build", "BUILD_CONFIG.md"),
    ("Architektura systemu", "ARCHITECTURE.md"),
    ("Warstwa Foundation", "FOUNDATION.md"),
    ("Baza danych", "DATABASE.md"),
    ("API / Komunikacja", "API.md"),
    ("Moduły / Logika biznesowa", "MODULES.md"),
    ("Testowanie", "TESTING.md"),
    ("Instalacja i konfiguracja", "INSTALLATION.md"),
    ("Wdrożenie / Deployment", "DEPLOYMENT.md"),
    ("Rozwiązywanie problemów", "TROUBLESHOOTING.md"),
    ("Bezpieczeństwo", "SECURITY.md"),
    ("Zgodność z przepisami", "COMPLIANCE.md"),
    ("Proces rozwoju / Contributing", "CONTRIBUTING.md"),
    ("Podręcznik użytkownika", "USER_GUIDE.md"),
    ("Słownik pojęć", "GLOSSARY.md"),
    ("FAQ", "FAQ.md"),
    ("Moduł Rust", "RUST_MODULE.md"),
    ("Manifest modeli AI", "MODELS_MANIFEST.md"),
    ("Bibliografia", "BIBLIOGRAPHY.md"),
    ("Powiązane zasoby", "RELATED.md"),
    ("Changelog", "CHANGELOG.md"),
    ("Spis treści / Indeks", "INDEX.md"),
]


def _escape_html(text: str) -> str:
    return text.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")


def _load_logo_base64() -> str:
    if LOGO_PATH.exists() and LOGO_PATH.stat().st_size < 100_000:
        try:
            with open(LOGO_PATH, "rb") as f:
                encoded = base64.b64encode(f.read()).decode("ascii")
            return f"data:image/png;base64,{encoded}"
        except (OSError, IOError, ValueError):
            pass
    return ""


def _download_mermaid() -> bool:
    """Pobiera Mermaid.js z CDN do lokalnego pliku. Zwraca True jeśli sukces."""
    if MERMAID_LOCAL.exists():
        print(f"  📦 Mermaid.js już pobrany ({MERMAID_LOCAL.stat().st_size / 1024:.0f} KB)")
        return True

    try:
        from urllib.request import urlopen
    except ImportError:
        print("  ⚠️  Brak urllib — nie można pobrać Mermaid.js")
        return False

    print(f"  📥 Pobieranie Mermaid.js ({MERMAID_CDN})...")
    try:
        with urlopen(MERMAID_CDN, timeout=30) as resp:
            data = resp.read()
        MERMAID_LOCAL.write_bytes(data)
        print(f"  ✅ Pobrano: {len(data) / 1024:.0f} KB → {MERMAID_LOCAL}")
        return True
    except (OSError, IOError, ValueError) as e:
        print(f"  ⚠️  Nie udało się pobrać Mermaid.js: {e}")
        return False


def _get_mermaid_script(offline: bool) -> str:
    """Zwraca tag <script> dla Mermaid.js — lokalny (offline) lub CDN."""
    if offline and _download_mermaid():
        return '<script src="mermaid.min.js"></script>'
    else:
        return f'<script src="{MERMAID_CDN}"></script>'


def _convert_to_pdf(html_path: Path) -> bool:
    """Próbuje przekonwertować HTML → PDF używając dostępnych bibliotek."""
    # Próbuj weasyprint
    try:
        from weasyprint import HTML
        pdf_path = html_path.with_suffix(".pdf")
        HTML(filename=str(html_path)).write_pdf(str(pdf_path))
        print(f"  ✅ PDF wygenerowany (weasyprint): {pdf_path} ({pdf_path.stat().st_size / 1024:.0f} KB)")
        return True
    except ImportError:
        pass

    # Próbuj playwright
    try:
        from playwright.sync_api import sync_playwright
        pdf_path = html_path.with_suffix(".pdf")
        with sync_playwright() as p:
            browser = p.chromium.launch()
            page = browser.new_page()
            page.goto(f"file://{html_path.absolute()}")
            page.pdf(path=str(pdf_path), format="A4", print_background=True)
            browser.close()
        print(f"  ✅ PDF wygenerowany (playwright): {pdf_path} ({pdf_path.stat().st_size / 1024:.0f} KB)")
        return True
    except ImportError:
        pass

    print("  ❌ Nie znaleziono biblioteki PDF.")
    print("     Zainstaluj jedną z:")
    print("       pip install weasyprint")
    print("       pip install playwright && playwright install chromium")
    print(f"     Następnie otwórz HTML w przeglądarce i użyj Ctrl+P.")
    return False


def md_to_html(markdown_text: str) -> str:
    lines = markdown_text.split("\n")
    result = []
    in_code_block = False
    in_table = False
    in_list = False
    list_type = None

    i = 0
    while i < len(lines):
        line = lines[i]

        if line.startswith("```"):
            if in_code_block:
                result.append("</code></pre>")
                in_code_block = False
            else:
                code_lang = line[3:].strip()
                lang_attr = f' class="language-{_escape_html(code_lang)}"' if code_lang else ""
                result.append(f"<pre><code{lang_attr}>")
                in_code_block = True
                i += 1
                code_lines = []
                while i < len(lines) and not lines[i].startswith("```"):
                    code_lines.append(_escape_html(lines[i]))
                    i += 1
                result.append("\n".join(code_lines))
                if i < len(lines) and lines[i].startswith("```"):
                    result.append("</code></pre>")
                    in_code_block = False
                i += 1
                continue
            i += 1
            continue

        if in_code_block:
            result.append(_escape_html(line))
            i += 1
            continue

        if "|" in line and line.strip().startswith("|"):
            if not in_table:
                result.append('<table class="table">')
                in_table = True
                cells = [c.strip() for c in line.split("|")[1:-1]]
                result.append("<thead><tr>" + "".join(f"<th>{_escape_html(c)}</th>" for c in cells) + "</tr></thead><tbody>")
                i += 1
                if i < len(lines) and re.match(r"^\|[\s\-:|]+\|$", lines[i]):
                    i += 1
                continue
            elif re.match(r"^\|[\s\-:|]+\|$", line):
                i += 1
                continue
            elif line.strip().startswith("|"):
                cells = [c.strip() for c in line.split("|")[1:-1]]
                result.append("<tr>" + "".join(f"<td>{md_to_html_inline(c)}</td>" for c in cells) + "</tr>")
                i += 1
                continue
            else:
                result.append("</tbody></table>")
                in_table = False
                continue

        if in_table and (not line.strip() or not line.strip().startswith("|")):
            result.append("</tbody></table>")
            in_table = False

        list_match = re.match(r"^(\s*)([-*+]|\d+\.)\s+(.*)", line)
        if list_match:
            marker = list_match.group(2)
            content = list_match.group(3)
            is_ordered = marker[0].isdigit()

            if not in_list:
                list_type = "ol" if is_ordered else "ul"
                result.append(f"<{list_type}>")
                in_list = True
            elif (is_ordered and list_type == "ul") or (not is_ordered and list_type == "ol"):
                result.append(f"</{list_type}>")
                list_type = "ol" if is_ordered else "ul"
                result.append(f"<{list_type}>")

            result.append(f"<li>{md_to_html_inline(content)}</li>")
            i += 1
            continue
        elif in_list and not line.strip():
            result.append(f"</{list_type}>")
            in_list = False
            i += 1
            continue
        elif in_list:
            result.append(f"</{list_type}>")
            in_list = False

        if line.startswith("> "):
            full_quote = [line[2:]]
            i += 1
            while i < len(lines) and lines[i].startswith("> "):
                full_quote.append(lines[i][2:])
                i += 1
            quote_text = "<br>".join(md_to_html_inline(l) for l in full_quote)
            result.append(f"<blockquote>{quote_text}</blockquote>")
            continue

        header_match = re.match(r"^(#{1,6})\s+(.*)", line)
        if header_match:
            level = len(header_match.group(1))
            text = header_match.group(2)
            tag = f"h{level}"
            anchor = re.sub(r"[^\w-]", "", text.lower().replace(" ", "-"))
            result.append(f'<{tag} id="{anchor}">{md_to_html_inline(text)}</{tag}>')
            i += 1
            continue

        if line.strip() in ("---", "***", "___"):
            result.append("<hr>")
            i += 1
            continue

        if not line.strip():
            result.append("")
            i += 1
            continue

        result.append(f"<p>{md_to_html_inline(line)}</p>")
        i += 1

    if in_table:
        result.append("</tbody></table>")
    if in_list:
        result.append(f"</{list_type}>")

    return "\n".join(result)


def md_to_html_inline(text: str) -> str:
    text = re.sub(r"\*\*\*(.+?)\*\*\*", r"<strong><em>\1</em></strong>", text)
    text = re.sub(r"\*\*(.+?)\*\*", r"<strong>\1</strong>", text)
    text = re.sub(r"\*(.+?)\*", r"<em>\1</em>", text)
    text = re.sub(r"`([^`]+)`", r"<code>\1</code>", text)
    text = re.sub(r"\[([^\]]+)\]\(([^)]+)\)", r'<a href="\2">\1</a>', text)
    text = re.sub(r"!\[([^\]]*)\]\(([^)]+)\)", r'<img src="\2" alt="\1">', text)
    return text


def _theme_css(dark_default: bool) -> str:
    """Zwraca style CSS z odpowiednim domyślnym motywem (light/dark)."""
    dark_vars = """--bg: #0f172a; --text: #e2e8f0; --muted: #94a3b8; --accent: #818cf8; --accent-light: #1e1b4b; --border: #334155; --code-bg: #1e293b; --table-stripe: #1e293b;"""
    light_vars = """--bg: #ffffff; --text: #1a1a2e; --muted: #6b7280; --accent: #4f46e5; --accent-light: #eef2ff; --border: #e5e7eb; --code-bg: #f8fafc; --table-stripe: #f9fafb;"""
    root = dark_vars if dark_default else light_vars
    override = light_vars if dark_default else dark_vars
    override_query = "light" if dark_default else "dark"
    return f"""    <style>
        :root {{ {root} }}
        @media (prefers-color-scheme: {override_query}) {{
            :root {{ {override} }}
        }}
    </style>"""


def _build_html_content(
    dark_mode: bool = False,
    offline: bool = False,
    logo_data_uri: str = "",
) -> str:
    """Buduje kompletny dokument HTML z dokumentacji."""
    if logo_data_uri:
        logo_html = f'<img src="{logo_data_uri}" alt="NexusAI Logo" class="logo-img" width="200" height="200" />'
    else:
        logo_html = """<pre class="logo-ascii">
╔═══════════════════════════════════════════╗
║   ███╗   ██╗███████╗██╗  ██╗██╗   ██╗   ║
║   ████╗  ██║██╔════╝╚██╗██╔╝██║   ██║   ║
║   ██╔██╗ ██║█████╗   ╚███╔╝ ██║   ██║   ║
║   ██║╚██╗██║██╔══╝   ██╔██╗ ██║   ██║   ║
║   ██║ ╚████║███████╗██╔╝ ██╗╚██████╔╝   ║
║   ╚═╝  ╚═══╝╚══════╝╚═╝  ╚═╝ ╚═════╝    ║
║        W I R T U A L N Y   K S I Ę G O W Y║
╚═══════════════════════════════════════════╝</pre>"""

    body_parts = []
    chapter_count = 0

    for i, (title, filename) in enumerate(CHAPTERS, 1):
        filepath = DOCS_DIR / filename
        if not filepath.exists():
            print(f"  ⚠️  Pominięto (brak pliku): {filename}")
            continue

        with open(filepath, encoding="utf-8") as f:
            md_content = f.read()

        md_content = re.sub(
            r"\n---\n\n> \*\*Data aktualizacji:.*(\n> \*\*Status dokumentu:.*)?",
            "",
            md_content,
            flags=re.MULTILINE,
        )

        html_section = md_to_html(md_content)
        chapter_count += 1

        body_parts.append(f"""
        <!-- ===== {i:02d}. {title} ===== -->
        <section class="chapter" id="chapter-{i:02d}">
            <div class="chapter-header">
                <span class="chapter-number">Rozdział {i}</span>
                <h2 class="chapter-title">{_escape_html(title)}</h2>
                <span class="chapter-source">📄 {_escape_html(filename)}</span>
            </div>
            {html_section}
        </section>
        """)

    toc_items = []
    for i, (title, filename) in enumerate(CHAPTERS, 1):
        toc_items.append(f'<li><a href="#chapter-{i:02d}">{i:02d}. {_escape_html(title)}</a> <small>({_escape_html(filename)})</small></li>')

    mode_css = _theme_css(dark_mode)
    mermaid_script = _get_mermaid_script(offline)
    mode_label = "Dark Mode" if dark_mode else "Light Mode"
    dark_badge = " 🌙 Dark" if dark_mode else ""

    return f"""<!DOCTYPE html>
<html lang="pl">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>NexusAI{dark_badge} — Kompletna dokumentacja techniczna v2.3.0</title>
    <meta name="description" content="Kompletna dokumentacja techniczna NexusAI — wirtualnego księgowego. Architektura, API, bezpieczeństwo, zgodność, deployment. Python 3.13t + Rust + 5 agentów AI.">
    <meta name="author" content="NexusAI Team">
    <meta name="generator" content="generate_html.py">
    <meta name="robots" content="index, follow">
    <meta name="color-scheme" content="{'dark' if dark_mode else 'light'}">

    <meta property="og:type" content="website">
    <meta property="og:url" content="https://github.com/Gorski-Maciej/NexusAI">
    <meta property="og:title" content="NexusAI{dark_badge} — Kompletna dokumentacja techniczna v2.3.1-dev">
    <meta property="og:description" content="Wirtualny księgowy dla MŚP w Polsce. Architektura offline-first, 5 agentów AI, double-entry ledger, zgodność z KSeF i UoR.">
    <meta property="og:site_name" content="NexusAI Docs">
    <meta property="og:locale" content="pl_PL">
    <meta property="og:image" content="https://raw.githubusercontent.com/Gorski-Maciej/NexusAI/main/assets/nexus.png">
    <meta property="og:image:width" content="200">
    <meta property="og:image:height" content="200">

    <meta name="twitter:card" content="summary">
    <meta name="twitter:site" content="@NexusAI">
    <meta name="twitter:title" content="NexusAI{dark_badge} — Dokumentacja techniczna v2.3.0">
    <meta name="twitter:description" content="Wirtualny księgowy dla MŚP. Python 3.13t, Rust, 5 agentów AI, TigerBeetle, KSeF.">
    <meta name="twitter:creator" content="@NexusAI">
    <meta name="twitter:image" content="https://raw.githubusercontent.com/Gorski-Maciej/NexusAI/main/assets/nexus.png">

{mode_css}
    <style>
        * {{ box-sizing: border-box; margin: 0; padding: 0; }}
        body {{
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif;
            font-size: 15px;
            line-height: 1.7;
            color: var(--text);
            background: var(--bg);
            max-width: 900px;
            margin: 0 auto;
            padding: 40px 24px;
        }}
        @media print {{
            @page {{
                size: A4;
                margin: 2cm 1.8cm 2.5cm 1.8cm;
                @bottom-center {{
                    content: "— Strona " counter(page) " z " counter(pages) " —";
                    font-size: 9px;
                    color: #94a3b8;
                    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
                }}
                @top-right {{
                    content: "NexusAI v2.3.0 — Dokumentacja techniczna";
                    font-size: 8px;
                    color: #cbd5e1;
                    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
                }}
            }}
            @page :first {{
                @top-right {{ content: none; }}
                @bottom-center {{ content: none; }}
            }}
            body {{ max-width: 100%; padding: 0; font-size: 11px; }}
            .chapter {{ page-break-before: always; }}
            .chapter:first-of-type {{ page-break-before: avoid; }}
            .title-page {{ page-break-after: always; }}
            nav {{ page-break-after: always; }}
            .no-print {{ display: none; }}
            .print-only {{ display: block; }}
            .logo-ascii {{ font-size: 9px; }}
            .logo-img {{ max-width: 180px; }}
        }}
        nav {{ margin-bottom: 48px; padding: 24px; border: 2px solid var(--accent); border-radius: 12px; background: var(--accent-light); }}
        nav h2 {{ margin: 0 0 12px 0; color: var(--accent); }}
        nav ol {{ padding-left: 24px; }}
        nav li {{ margin: 4px 0; }}
        nav a {{ color: var(--accent); text-decoration: none; }}
        nav a:hover {{ text-decoration: underline; }}
        nav small {{ color: var(--muted); font-size: 0.85em; }}

        .chapter {{ margin: 48px 0; padding-top: 24px; border-top: 2px solid var(--border); }}
        .chapter-header {{ margin-bottom: 20px; }}
        .chapter-number {{ font-size: 12px; font-weight: 600; color: var(--accent); text-transform: uppercase; letter-spacing: 0.05em; }}
        .chapter-title {{ font-size: 24px; font-weight: 700; margin: 4px 0; }}
        .chapter-source {{ font-size: 13px; color: var(--muted); }}

        h1 {{ font-size: 28px; margin: 24px 0 16px; }}
        h2 {{ font-size: 22px; margin: 28px 0 14px; padding-bottom: 6px; border-bottom: 1px solid var(--border); }}
        h3 {{ font-size: 18px; margin: 20px 0 10px; }}
        h4 {{ font-size: 16px; margin: 16px 0 8px; }}
        h5, h6 {{ font-size: 14px; margin: 12px 0 6px; color: var(--muted); }}

        p {{ margin: 8px 0; }}
        a {{ color: var(--accent); }}
        blockquote {{ margin: 16px 0; padding: 12px 20px; border-left: 4px solid var(--accent); background: var(--accent-light); border-radius: 0 8px 8px 0; }}
        blockquote p {{ margin: 4px 0; }}

        code {{ font-family: 'Fira Code', 'Cascadia Code', 'Consolas', monospace; font-size: 0.9em; background: var(--code-bg); padding: 2px 6px; border-radius: 4px; }}
        pre {{ margin: 12px 0; padding: 16px; background: var(--code-bg); border-radius: 8px; overflow-x: auto; font-size: 13px; line-height: 1.5; }}
        pre code {{ background: none; padding: 0; }}

        .table {{ width: 100%; border-collapse: collapse; margin: 16px 0; font-size: 14px; }}
        .table th, .table td {{ padding: 10px 14px; text-align: left; border: 1px solid var(--border); }}
        .table th {{ background: var(--accent-light); font-weight: 600; }}
        .table tr:nth-child(even) td {{ background: var(--table-stripe); }}

        ul, ol {{ margin: 8px 0; padding-left: 28px; }}
        li {{ margin: 3px 0; }}

        hr {{ margin: 24px 0; border: none; border-top: 1px solid var(--border); }}

        img {{ max-width: 100%; height: auto; border-radius: 8px; }}

        .title-page {{ text-align: center; padding: 60px 0 40px; page-break-after: always; }}
        .title-page h1 {{ font-size: 28px; border: none; margin-top: 32px; }}
        .title-page .subtitle {{ font-size: 20px; color: var(--muted); margin: 12px 0 32px; }}
        .title-page .title-meta {{ margin: 24px 0; }}
        .title-page .title-meta p {{ margin: 4px 0; font-size: 15px; }}
        .logo-box {{ margin-bottom: 24px; }}
        .logo-img {{ display: block; margin: 0 auto; border-radius: 24px; box-shadow: 0 4px 24px rgba(79,70,229,0.15); image-rendering: auto; }}
        .logo-ascii {{ font-size: 8px; line-height: 1.2; color: var(--accent); background: none; display: inline-block; text-align: left; }}
        .mission-quote {{ margin: 32px auto 0; max-width: 600px; text-align: center; font-size: 16px; padding: 20px 32px; }}

        .print-only {{ display: none; }}
        .no-print {{ }}
    </style>
</head>
<body>

    <div class="title-page" id="chapter-00">
        <div class="logo-box">
            {logo_html}
        </div>
        <h1>Kompletna dokumentacja techniczna</h1>
        <div class="title-meta">
            <p><strong>Wersja:</strong> 2.3.0 „Free-Threaded Phoenix"</p>
            <p><strong>Wariant:</strong> {mode_label}</p>
            <p><strong>Data generacji:</strong> {datetime.now().strftime('%Y-%m-%d %H:%M')}</p>
            <p><strong>Język:</strong> Polski · <strong>Licencja:</strong> Proprietary</p>
            <p><strong>Zespół:</strong> NexusAI Team</p>
            <p><strong>Repozytorium:</strong> github.com/Gorski-Maciej/NexusAI</p>
        </div>
        <blockquote class="mission-quote">
            <p>NexusAI to nie aplikacja — to <strong>wirtualny księgowy</strong>.</p>
            <p>Przejmuje 90% pracy księgowej. Zostawia 10% Tobie.</p>
        </blockquote>
    </div>

    <nav>
        <h2>📋 Spis treści</h2>
        <ol>
            {chr(10).join(toc_items)}
        </ol>
    </nav>

    {"".join(body_parts)}

    <footer class="no-print">
        <p>NexusAI v2.3.0 · {mode_label} · Wygenerowano {datetime.now().strftime('%Y-%m-%d')}</p>
        <p>© 2025–2026 NexusAI Team. Wszelkie prawa zastrzeżone.</p>
    </footer>

    <div class="print-only" style="text-align:center;padding:20px 0;color:var(--muted);font-size:10px;border-top:1px solid var(--border);">
        <p>NexusAI v2.3.0 „Free-Threaded Phoenix" · github.com/Gorski-Maciej/NexusAI</p>
        <p>Dokument wygenerowany {datetime.now().strftime('%Y-%m-%d')} · Licencja: Proprietary · {mode_label}</p>
    </div>

    {mermaid_script}
    <script>
        mermaid.initialize({{
            startOnLoad: true,
            theme: '{"dark" if dark_mode else "default"}',
            securityLevel: 'loose',
            flowchart: {{ useMaxWidth: true, htmlLabels: true }},
            sequence: {{ useMaxWidth: true }},
        }});
    </script>
</body>
</html>"""


def generate_html(dark_mode: bool = False, offline: bool = False, to_pdf: bool = False) -> None:
    """Generuje plik HTML z dokumentacją."""
    mode_label = "Dark Mode" if dark_mode else "Light Mode"
    output_file = OUTPUT_FILE_DARK if dark_mode else OUTPUT_FILE
    print(f"📚 Generowanie dokumentacji HTML ({mode_label})...\n")

    if logo_data_uri := _load_logo_base64():
        print(f"  🖼️  Logo załadowane (base64, {len(logo_data_uri)} znaków)")
    else:
        print(f"  ⚠️  Logo nie znalezione — używam ASCII fallback")

    if offline:
        print(f"  📡 Tryb offline — pobieranie Mermaid.js lokalnie...")

    html_content = _build_html_content(dark_mode=dark_mode, offline=offline, logo_data_uri=logo_data_uri)

    with open(output_file, "w", encoding="utf-8") as f:
        f.write(html_content)

    size_kb = output_file.stat().st_size / 1024
    print(f"  ✅ Wygenerowano: {output_file}")
    print(f"     Rozmiar: {size_kb:.0f} KB")
    print(f"     Rozdziałów: {len(CHAPTERS)}")
    print(f"     Wariant: {mode_label}")
    if offline and MERMAID_LOCAL.exists():
        print(f"     Mermaid.js: lokalny ({MERMAID_LOCAL})")
    else:
        print(f"     Mermaid.js: CDN ({MERMAID_CDN})")

    if to_pdf:
        print()
        _convert_to_pdf(output_file)
    elif not dark_mode:
        print(f"\n💡 Otwórz plik w przeglądarce i użyj Ctrl+P → 'Zapisz jako PDF' aby wygenerować PDF.")
        print(f"   Uruchom z flagą --pdf aby spróbować automatycznej konwersji (wymaga weasyprint).")
        print(f"   Uruchom z flagą --dark aby wygenerować wariant ciemny.")
        print(f"   Uruchom z flagą --offline aby pobrać Mermaid.js lokalnie.")
    else:
        print(f"\n💡 Wariant dark mode gotowy. Otwórz w przeglądarce.")
        print(f"   Aby wygenerować oba warianty: python docs/generate_html.py && python docs/generate_html.py --dark")


def _watch_and_regenerate(args: argparse.Namespace) -> None:
    """Monitoruje pliki .md i auto-regeneruje HTML przy zmianach."""
    interval = args.watch
    print(f"👁️  Tryb watch — monitorowanie co {interval}s (Ctrl+C aby zatrzymać)\n")

    # Zbierz wszystkie pliki źródłowe
    source_files: dict[str, float] = {}
    for _, filename in CHAPTERS:
        filepath = DOCS_DIR / filename
        if filepath.exists():
            source_files[str(filepath)] = filepath.stat().st_mtime

    # Dodaj README.md i assets
    readme = PROJECT_ROOT / "README.md"
    if readme.exists():
        source_files[str(readme)] = readme.stat().st_mtime

    # Pierwsza generacja (pdf wyłączone w watch mode)
    if args.pdf:
        print(f"  ⚠️  --pdf ignorowane w watch mode (zbyt wolne przy każdej zmianie)")
    generate_html(dark_mode=args.dark, offline=args.offline, to_pdf=False)
    print(f"\n👁️  Oczekiwanie na zmiany...\n")

    try:
        while True:
            time.sleep(interval)
            changed = False

            for filepath_str, old_mtime in list(source_files.items()):
                try:
                    new_mtime = os.path.getmtime(filepath_str)
                except OSError:
                    continue

                if new_mtime != old_mtime:
                    changed = True
                    source_files[filepath_str] = new_mtime
                    rel_path = Path(filepath_str).relative_to(PROJECT_ROOT)
                    print(f"  🔄 Zmiana: {rel_path}  [{datetime.now().strftime('%H:%M:%S')}]")

            # Sprawdź nowe pliki (poza pętlą mtime — raz na interwał)
            for _, filename in CHAPTERS:
                filepath = DOCS_DIR / filename
                fp_str = str(filepath)
                if fp_str not in source_files and filepath.exists():
                    changed = True
                    source_files[fp_str] = filepath.stat().st_mtime
                    print(f"  🆕 Nowy plik: {filename}  [{datetime.now().strftime('%H:%M:%S')}]")

            if changed:
                print(f"  📚 Regeneracja HTML...")
                try:
                    generate_html(dark_mode=args.dark, offline=args.offline, to_pdf=False)
                except Exception as e:
                    print(f"  ❌ Błąd regeneracji: {e}  (watch kontynuuje)")
                print(f"\n👁️  Oczekiwanie na zmiany...\n")

    except KeyboardInterrupt:
        print(f"\n\n👋 Zatrzymano watch mode.")


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Generuje dokumentację NexusAI jako pojedynczy plik HTML.",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Przykłady:
  python docs/generate_html.py                    # Light mode
  python docs/generate_html.py --dark              # Dark mode
  python docs/generate_html.py --offline           # Light + offline Mermaid.js
  python docs/generate_html.py --dark --offline    # Dark + offline
  python docs/generate_html.py --pdf               # Light + próba PDF
  python docs/generate_html.py --watch             # Monitoruj zmiany (co 3s)
  python docs/generate_html.py --watch 5 --dark    # Monitoruj co 5s, dark mode
        """,
    )
    parser.add_argument("--dark", action="store_true", help="Wygeneruj wariant dark mode (ciemne tło jako domyślne)")
    parser.add_argument("--offline", action="store_true", help="Pobierz Mermaid.js lokalnie (działa bez internetu)")
    parser.add_argument("--pdf", action="store_true", help="Spróbuj automatycznej konwersji HTML → PDF (wymaga weasyprint lub playwright)")
    parser.add_argument("--watch", type=int, nargs="?", const=3, metavar="SEC", help="Monitoruj zmiany w plikach .md i auto-regeneruj HTML co SEC sekund (domyślnie: 3)")

    args = parser.parse_args()

    if args.watch:
        _watch_and_regenerate(args)
    else:
        generate_html(dark_mode=args.dark, offline=args.offline, to_pdf=args.pdf)


if __name__ == "__main__":
    main()
