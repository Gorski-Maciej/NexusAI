# V3 ID CANON — KANON IDENTYFIKATORÓW SERII V3 (P00-I07)

> **Status:** WDROŻONY_100 (P00-I07) · Kontrakt wiążący P01–P68
> **Narzędzie:** `JDG/tools/v3_id_canon.py` · Dane: `JDG/bundles/v3_id_canon.json`

## 1. Format identyfikatorów

| Typ | Format | Zakres | Znaczenie |
|-----|--------|--------|-----------|
| Luka | `V3-<KOD>-Lxx` | L01..L99 | luka z dowodem; P0 (BLOCKER) > P1 > P2 > P3 |
| Innowacja | `V3-<KOD>-Ixx` | I01..I99 | kompletny projekt Enterprise (min. 12/część) |
| Konflikt | `V3-<KOD>-Cxx` | C01..C99 | dokument↔kod, mirror↔canonical, kontrakt↔kontrakt |
| Pytanie do człowieka | `V3-<KOD>-Qxx` | Q01..Q99 | rozstrzygnięcie zarezerwowane dla człowieka |
| Pytanie krzyżowe | `V3-<KOD>-Xxx` | X01..X10 | odpowiedź na pytanie systemowe (Sekcja 7.4) |

`<KOD>` = P00..P68 (69 części serii V3).

## 2. Zasady

1. Identyfikator nadaje część, w której luka/innowacja została WYKRYTA.
2. Ten sam identyfikator NIE może być użyty w dwóch różnych raportach
   (detekcja kolizji w `v3_id_canon.py --check` — bramka CI).
3. Odwołania międzyczęściowe: `V3-P12-L03` (patrz raport P12) — nigdy
   nie re-używa się identyfikatora z innej części.
4. Luki P0 (BLOCKER) muszą być rozstrzygnięte przed startem części
   domenowych (P10+), chyba że decyzja właściciela stanowi inaczej.
5. Innowacje: szkielet 6-punktowy (problem, mechanizm, wpływ, ryzyko,
   kryterium akceptacji, zależności) z Sekcji 10 promptu.

## 3. Nazewnictwo plików

| Artefakt | Konwencja |
|----------|-----------|
| Raport | `RAPORT_V3_<KOD>_<SLUG>.txt` (JDG/raporty_glm52_v3/) |
| Prompt | `V3_PROMPT_<KOD>_<SLUG>.txt` (JDG/prompty_v3/) |
| Rego package | `jdg/<pakiet>/...` |
| rule_id | `jdg.<pakiet>.<reguła>` |
| Parametry | `data.thresholds.*` (ADR-002) + `valid_from/valid_to` (P05) |

## 4. Rejestr rezerwacji

Pełny rejestr maszynowy: `JDG/bundles/v3_id_canon.json` — zawiera kanon,
użycie (per raport) i listę problemów (kolizje). Aktualizacja:
`python JDG/tools/v3_id_canon.py --write`.