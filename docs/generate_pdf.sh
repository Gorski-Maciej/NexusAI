#!/bin/bash
# docs/generate_pdf.sh — Generowanie kompletnej dokumentacji NexusAI jako PDF
# Wymagania: pandoc, texlive (lub wkhtmltopdf jako alternatywa)
#
# Instalacja:
#   Ubuntu/Debian: sudo apt install pandoc texlive-latex-base texlive-latex-recommended texlive-latex-extra texlive-fonts-recommended texlive-xetex
#   macOS: brew install pandoc basictex
#   Windows: choco install pandoc miktex

set -euo pipefail

DOCS_DIR="$(cd "$(dirname "$0")" && pwd)"
OUTPUT="${DOCS_DIR}/NexusAI_Dokumentacja_Techniczna.pdf"
TEMP_DIR="$(mktemp -d)"

echo "📄 Generowanie dokumentacji NexusAI → PDF"
echo "   Katalog: $DOCS_DIR"
echo "   Wyjście: $OUTPUT"

# Lista plików w kolejności (zgodnie ze strukturą dokumentacji)
FILES=(
    "00_META.md"
    "../README.md"
    "INTRODUCTION.md"
    "QUICKSTART.md"
    "PROJECT_STRUCTURE.md"
    "SCRIPTS.md"
    "INSTALLER.md"
    "FRONTEND.md"
    "EVENTS.md"
    "PIPELINE.md"
    "INFERENCE.md"
    "MONITORING.md"
    "HTTP_CLIENT.md"
    "CONFIG.md"
    "DOMAIN.md"
    "WORKFLOWS.md"
    "PDFIUM.md"
    "DECISIONS.md"
    "BUILD_CONFIG.md"
    "ARCHITECTURE.md"
    "FOUNDATION.md"
    "INSTALLATION.md"
    "DATABASE.md"
    "API.md"
    "MODULES.md"
    "TESTING.md"
    "DEPLOYMENT.md"
    "TROUBLESHOOTING.md"
    "SECURITY.md"
    "COMPLIANCE.md"
    "CONTRIBUTING.md"
    "USER_GUIDE.md"
    "GLOSSARY.md"
    "FAQ.md"
    "RUST_MODULE.md"
    "MODELS_MANIFEST.md"
    "BIBLIOGRAPHY.md"
    "RELATED.md"
    "CHANGELOG.md"
    "INDEX.md"
)

# Sprawdź, czy pliki istnieją
MISSING=()
for f in "${FILES[@]}"; do
    if [ ! -f "${DOCS_DIR}/${f}" ]; then
        MISSING+=("$f")
    fi
done

if [ ${#MISSING[@]} -gt 0 ]; then
    echo "❌ Brakujące pliki: ${MISSING[*]}"
    exit 1
fi

# Wybierz silnik PDF
if command -v pandoc &>/dev/null; then
    echo "✅ pandoc znaleziony"
    
    # Sprawdź dostępność silnika PDF
    ENGINE="pdflatex"
    if command -v xelatex &>/dev/null; then
        ENGINE="xelatex"  # Lepsze wsparcie Unicode
    fi
    
    # Generuj PDF
    echo "🔨 Generowanie PDF (silnik: $ENGINE)..."
    pandoc \
        --from=markdown \
        --to=pdf \
        --pdf-engine="$ENGINE" \
        --toc \
        --toc-depth=3 \
        --number-sections \
        --metadata title="NexusAI — Dokumentacja Techniczna" \
        --metadata author="NexusAI Team" \
        --metadata date="2026-07-04" \
        --metadata version="2.3.0" \
        --metadata lang="pl-PL" \
        -V geometry:margin=2.5cm \
        -V fontsize=11pt \
        -V documentclass=report \
        -V titlepage=true \
        -V colorlinks=true \
        -V linkcolor=blue \
        -V urlcolor=blue \
        "$(for f in "${FILES[@]}"; do echo "${DOCS_DIR}/${f}"; done)" \
        -o "$OUTPUT"
    
    if [ -f "$OUTPUT" ]; then
        SIZE=$(du -h "$OUTPUT" | cut -f1)
        echo "✅ PDF wygenerowany: $OUTPUT ($SIZE)"
    else
        echo "❌ Błąd generowania PDF"
        exit 1
    fi

elif command -v wkhtmltopdf &>/dev/null; then
    # Alternatywa: konwersja HTML → PDF (bez LaTeX)
    echo "⚠️ pandoc nie znaleziony, używam wkhtmltopdf..."
    
    # Wygeneruj HTML tymczasowo
    HTML_TEMP="${TEMP_DIR}/nexus_docs.html"
    pandoc \
        --from=markdown \
        --to=html5 \
        --toc \
        --toc-depth=3 \
        --metadata title="NexusAI — Dokumentacja Techniczna" \
        "$(for f in "${FILES[@]}"; do echo "${DOCS_DIR}/${f}"; done)" \
        -o "$HTML_TEMP"
    
    wkhtmltopdf \
        --enable-toc-back-links \
        --footer-center "Strona [page] / [topage]" \
        "$HTML_TEMP" \
        "$OUTPUT"
    
    echo "✅ PDF wygenerowany: $OUTPUT"

else
    echo "❌ Ani pandoc, ani wkhtmltopdf nie są zainstalowane."
    echo ""
    echo "Zainstaluj jedno z tych narzędzi:"
    echo "  Ubuntu/Debian: sudo apt install pandoc texlive-latex-base texlive-latex-extra texlive-fonts-recommended"
    echo "  macOS: brew install pandoc basictex"
    echo "  Windows: choco install pandoc"
    echo ""
    echo "Lub użyj pip do instalacji alternatyw:"
    echo "  pip install mkdocs-with-pdf"
    echo "  pip install grip && grip docs/README.md  # podgląd HTML w przeglądarce"
    exit 1
fi

# Sprzątanie
rm -rf "$TEMP_DIR"

echo ""
echo "📋 Podsumowanie:"
echo "   Pliki źródłowe: ${#FILES[@]}"
echo "   Plik wynikowy:  $OUTPUT"
echo ""
echo "Aby otworzyć PDF:"
echo "   xdg-open $OUTPUT   # Linux"
echo "   open $OUTPUT       # macOS"
echo "   start $OUTPUT      # Windows"
