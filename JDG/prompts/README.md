# JDG — prompty audytowe GLM 5.2

Każdy plik `PXX_*.txt` jest samodzielnym promptem do wklejenia do GLM 5.2. Prompty są celowo ograniczone do zakresu jednej części, aby materiały wejściowe zajmowały najwyżej około 50% okna kontekstowego; model ma pozostałe miejsce na analizę i raport.

## Kolejność

1. `P00_ORCHESTRATOR.txt` — kontrakt wspólny i sposób pracy.
2. `P01`–`P28` — części domenowe i systemowe.
3. `P29_SYNTHESIS.txt` — integracja raportów bez ponownego czytania całego JDG.

## Zasada pracy

GLM ma wygenerować raport TXT, a nie dokonywać nieuzgodnionych zmian w repozytorium. Implementację wykonujemy dopiero po przeglądzie raportu. Każdy raport musi zawierać: luki, ryzyka, mapę zależności, proponowane pliki, pseudokod/kod Rego lub Python, testy, migracje, kryteria akceptacji, plan rollbacku i pytania otwarte.

## Wspólny artefakt integracyjny

Na końcu każdego raportu GLM musi dodać sekcję `CONTRACT_DELTA` w formacie:

- `new_contracts`
- `changed_contracts`
- `consumers_to_update`
- `legal_refs`
- `rule_ids_or_namespaces`
- `schemas_and_fields`
- `tests_and_gates`
- `open_risks`

Kolejny prompt otrzymuje poprzednie `CONTRACT_DELTA` oraz raporty, ale nie musi ponownie wczytywać całego JDG.

> To narzędzie analityczno-programistyczne. Żaden raport nie zastępuje weryfikacji przez uprawnionego doradcę podatkowego lub prawnika.
