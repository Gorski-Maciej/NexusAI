# V3 BLOCKER TRIAGE MATRIX (P00-I09)

> **Status:** WDROŻONY_100 (P00-I09) · Kontrakt serii V3: P00 → P68
> **Źródło:** `JDG/prompty_v3/V3_PROMPT_P00_MAPA_KANONICZNA.txt` (Sekcja 4.1, 11.5, 12)

Macierz rozstrzygania konfliktów BLOCKER w kampanii V3 FORTRESS. Każdy
konflikt oznaczony jako BLOCKER (P0) MUSI przejść przez tę procedurę —
nigdy nie jest rozstrzygany po cichu.

## 1. Hierarchia źródeł (od najwyższej rangi)

| Ranga | Źródło | Komentarz |
|-------|--------|-----------|
| 1 | Dokumenty święte (V1 + V2) | `JDG/docs/ARCHITEKTURA_OPA_ENTERPRISE_TARGET.md`, `JDG/docs/WIZJA_OPA_ENTERPRISE_V2.md` — architektura docelowa, prawo konfliktu |
| 2 | Prawo polskie (ISAP/RCL/MF) | Teksty ujednolicone; `JDG/docs/Bbb` = katalog twierdzeń do weryfikacji |
| 3 | Kontrakt P00 (ten dokument + ID Canon + snapshot) | Baseline liczbowy i standardy nazewnicze serii |
| 4 | Kontrakty wyjściowe wcześniejszych części V3 | Sekcja KONTRAKT WYJŚCIOWY każdego raportu |
| 5 | Dokumenty opisowe / README / MANIFEST / stare raporty | Najniższa ranga — deklaracje, nie dowód |

## 2. Typy konfliktów i właściciel decyzji

| Typ | Kod | Przykład | Właściciel | SLA |
|-----|-----|----------|------------|-----|
| Dokument święty vs kod | V3-Pxx-C01..C19 | reguła łamie invariant P04 | Architekt (4-eyes z właścicielem) | 5 dni roboczych |
| Prawo vs twierdzenie | V3-Pxx-C20..C39 | podstawa prawna bez Dz.U. | Weryfikator prawny (ISAP) | 10 dni roboczych |
| Mirror vs canonical | V3-Pxx-C40..C59 | ta sama reguła, inna treść | CI + architekt | 2 dni robocze |
| Kontrakt vs kontrakt | V3-Pxx-C60..C79 | P03 zmienia kontrakt P02 | Rada kontraktów V3 | 5 dni roboczych |
| Dokument vs dokument | V3-Pxx-C80..C99 | MANIFEST vs README | Właściciel dokumentacji | 3 dni robocze |

## 3. Procedura eskalacji BLOCKER

1. **Wykrycie** — w raporcie części (rejestr konfliktów T12) albo w CI
   (bramka `v3_contract_schema.py --check`).
2. **Dokumentacja** — identyfikator `V3-<KOD>-Cxx`, cytaty OBU stron
   (dokument→cytat, kod→cytat), proponowane rozstrzygnięcie.
3. **Klasyfikacja** — P0 (złamanie dokumentu świętego / temporalności /
   fail-closed), P1 (wysokie ryzyko błędnej decyzji), P2, P3.
4. **Eskalacja** — P0 trafia do właściciela projektu (4-eyes) w sekcji
   PYTAŃ DO CZŁOWIEKA; nie może być rozstrzygnięty przez AI.
5. **Rozstrzygnięcie** — decyzja zapada zgodnie z hierarchią źródeł;
   wynik wpisywany do rejestru konfliktów i do Campaign Ledger.
6. **Regresja** — każda zmiana wynikająca z rozstrzygnięcia wskazuje:
   testy do zmiany, bundle do przebudowy, ścieżkę rollback.

## 4. Zasada rozstrzygania

> Konflikt dokumentu świętego z czymkolwiek = **dokument święty wygrywa**,
> chyba że rozstrzygnięcie wymaga decyzji biznesowej właściciela —
> wtedy NIE ZGADYWAJ: oznacz BLOCKER i eskaluj.

## 5. Rejestr konfliktów P00 (otwarte do rozstrzygnięcia)

Zobacz `JDG/raporty_glm52_v3/RAPORT_V3_P00_MAPA_KANONICZNA.txt` sekcja
9.06/9.16 (T12) oraz `bundles/v3_drift_watchdog.json` i
`bundles/v3_registry_of_registries.json` — maszynowe dowody konfliktów
dokumentacyjnych i rejestrowych wykrytych w P00.