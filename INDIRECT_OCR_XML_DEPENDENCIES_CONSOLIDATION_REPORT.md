# INDIRECT OCR/XML DEPENDENCIES CONSOLIDATION REPORT

**Data:** 23 czerwca 2026
**Autor:** Buffy (AI Agent)

## Cel

Usunięcie `Leptonica`, `PaddlePaddle`, `libxml2` oraz `libxslt` jako samodzielnych pozycji technologicznych z dokumentacji projektu NexusAI. Są to zależności pośrednie, a nie świadomie wybrane technologie.

## Zmodyfikowane pliki (2)

| Plik | Zmiany |
|------|--------|
| `RAPORT_TECHNOLOGII_NEXUSAI.txt` | Usunięto Leptonica, PaddlePaddle jako osobne wpisy; libxml2/libxslt przeniesione do [Z] z adnotacją transitive dep lxml; dodano adnotacje przy technologiach nadrzędnych |
| `README.md` | Dodano adnotacje przy lxml, Tesseract OCR, PaddleOCR o wewnętrznych zależnościach |

## Usunięte pozycje z raportów

| Pozycja | Typ | Technologia nadrzędna |
|---------|-----|----------------------|
| `Leptonica >=1.84.0` [Z] | Zależność pośrednia | Tesseract OCR |
| `PaddlePaddle >=3.0.0` [Z] | Zależność pośrednia | PaddleOCR |
| `libxml2 >=2.12.0` [Z] | Zależność pośrednia | lxml (pozostawiono w sekcji 2.24 jako transitive dep) |
| `libxslt >=1.1.39` [Z] | Zależność pośrednia | lxml (pozostawiono w sekcji 2.24 jako transitive dep) |

## Bezpośrednie importy w kodzie

**Wynik: ZERO.** Nie znaleziono żadnych bezpośrednich importów:
- `import leptonica` / `from leptonica` — 0
- `import paddle` (bez `paddleocr`) / `from paddle` — 0
- `import libxml2` / `from libxml2` — 0
- `import libxslt` / `from libxslt` — 0

## Adnotacje dodane

- **lxml**: *(wewnętrznie używa libxml2 i libxslt)*
- **Tesseract OCR**: *(wewnętrznie używa Leptonica)*
- **PaddleOCR**: *(wewnętrznie używa PaddlePaddle)*

## Status

✅ Leptonica, PaddlePaddle, libxml2, libxslt nie figurują już jako samodzielne technologie.
✅ Adnotacje przy technologiach nadrzędnych dodane.
✅ Zero bezpośrednich importów w kodzie Python.
✅ Zależności pozostają w środowisku (przez Tesseract, PaddleOCR, lxml).
