# SYSTEM DEPS CLEANUP REPORT

**Data:** 25 czerwca 2026
**Autor:** Buffy (AI Agent)

## Cel

Usunięcie 10 zależności systemowych, narzędzi budowania i pakietów NVIDIA z list technologii w dokumentacji architektonicznej NexusAI oraz — w stosownych przypadkach — z konfiguracji środowiska.

## Status: WSZYSTKIE 10 POZYCJI JUŻ WCZEŚNIEJ USUNIĘTE Z LIST TECHNOLOGII

Po dokładnym skanowaniu dokumentacji (`RAPORT_TECHNOLOGII_NEXUSAI.txt`, `README.md`, `docs/*.txt`, `docs/*.md`, wszystkie `.md` w katalogu głównym) okazało się, że **wszystkie 10 zależności zostało już usuniętych jako osobne pozycje technologiczne** podczas wcześniejszych prac porządkowych (udokumentowanych w `INDIRECT_OCR_XML_DEPENDENCIES_CONSOLIDATION_REPORT.md` oraz innych raportach).

## Lista 10 pozycji i ich aktualny status w dokumentacji

| # w raporcie | Nazwa | Typ | Status w dokumentacji |
|---|---|---|---|
| 256 | `leptonica >=1.84.0` | [Z] | ✅ Tylko jako adnotacja przy Tesseract: *"(wewnętrznie używa Leptonica)"* — README l.144, RAPORT l.180 |
| 260 | `libxml2 >=2.12.0` | [Z] | ✅ Tylko jako adnotacja przy lxml: *"(wewnętrznie używa libxml2 i libxslt)"* — README l.142, RAPORT l.177 |
| 261 | `libxslt >=1.1.39` | [Z] | ✅ J.w. |
| 262 | `cmake >=3.28.0` | [D] | ✅ Nie występuje w dokumentacji jako technologia — tylko w `pixi.toml` (feature.dev) jako narzędzie budowania |
| 263 | `pkg-config >=0.29.2` | [Z] | ✅ Nie występuje w dokumentacji jako technologia — tylko w `pixi.toml` jako zależność systemowa |
| 264 | `CUDA Toolkit (v13.0.2)` | [Z] | ✅ Nie występuje w dokumentacji jako technologia |
| 265 | `nvidia-cuda-runtime (cu12)` | [Z] | ✅ Nie występuje w dokumentacji jako technologia |
| 266 | `nvidia-cudnn (cu13)` | [Z] | ✅ Nie występuje w dokumentacji jako technologia |
| 267 | `nvidia-nccl` | [Z] | ✅ Nie występuje w dokumentacji jako technologia |
| 268 | `nvidia-cublas` | [Z] | ✅ Nie występuje w dokumentacji jako technologia |

## Zmodyfikowane pliki (1)

| Plik | Zmiana |
|------|--------|
| `pixi.toml` l.660 | Poprawiono komentarz przy `cmake`: usunięto wzmiankę o CUDA, która była myląca (aplikacja celuje w CPU) |

## Pakiety NVIDIA — ocena fizycznego usunięcia ze środowiska

1. **`pixi.toml`** — Żaden z pakietów NVIDIA (cuda-toolkit, nvidia-cuda-runtime, nvidia-cudnn, nvidia-nccl, nvidia-cublas) **nie figuruje jako bezpośrednia zależność** w `pixi.toml`.
2. **`pixi.lock`** — Pakiety CUDA występują wyłącznie jako **zależności przechodnie** w obrębie definicji pakietu `cuda-toolkit` (opcjonalne/extra zależności).
3. **`pixi list`** — `pixi list | grep -i 'cuda\|nvidia'` zwraca **pusty wynik** — żaden pakiet CUDA nie jest faktycznie zainstalowany w środowisku.
4. **Wniosek:** Nie ma potrzeby fizycznego usuwania CUDA ze środowiska, ponieważ **nie są one obecne** — ani jako bezpośrednie, ani jako faktycznie zainstalowane zależności.

## Weryfikacja

```bash
# Sprawdzenie dokumentacji — żadna z 10 nazw nie figuruje jako osobna technologia
grep -rn -i 'leptonica\|libxml2\|libxslt\|cmake\|pkg-config\|cuda-toolkit\|nvidia-cuda\|nvidia-cudnn\|nvidia-nccl\|nvidia-cublas' \
  RAPORT_TECHNOLOGII_NEXUSAI.txt README.md docs/*.txt

# Wynik: Tylko adnotacje przy lxml i Tesseract — brak osobnych wpisów technologicznych
```

## Podsumowanie

- ✅ **10 z 10** zależności nie figuruje już jako osobne technologie w dokumentacji
- ✅ Adnotacje przy lxml i Tesseract poprawnie informują o wewnętrznych zależnościach
- ✅ `cmake` i `pkg-config` pozostają w `pixi.toml` jako narzędzia budowania (bez statusu technologii)
- ✅ Pakiety CUDA nie występują w `pixi.toml` i nie są instalowane — brak akcji
- ✅ Poprawiono mylący komentarz CUDA w `pixi.toml`
- 🔄 Testy OCR i XML — nie były wymagane, ponieważ nie modyfikowano zależności runtime'owych
