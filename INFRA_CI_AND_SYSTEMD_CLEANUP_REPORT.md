# Infra CI & Systemd Cleanup Report

**Data:** 24 czerwca 2026
**Operacja:** Usunięcie 8 szczegółowych workflowów CI/CD i 1 detalu wdrożeniowego (systemd) z głównej listy architektury

---

## Usunięte pozycje

### A. Szczegółowe workflowy i narzędzia CI ([D])

| Poz. | Nazwa | Powód usunięcia |
|------|-------|-----------------|
| 153 | CI workflow (`ci.yml`) | Szczegół implementacyjny CI, nie technologia |
| 154 | Hatch Matrix (3.13 + 3.13t) | Konfiguracja testów – detal CI |
| 155 | Performance Locust | `locust` jest już w sekcji Testowanie (poz. 217) |
| 156 | Profiling CI (`py-spy`) | Profilowanie – detal CI, opisy były ogólne |
| 157 | OpenSSF Scorecard | Narzędzie do audytu bezpieczeństwa – detal CI |
| 158 | Dependabot | Automatyczne aktualizacje – detal CI |
| 159 | Stale Issue & PR Manager | Zarządzanie repozytorium – detal CI |
| 160 | Auto Label PR | Etykietowanie PR – detal CI |

### B. Detal wdrożeniowy ([A])

| Poz. | Nazwa | Powód usunięcia |
|------|-------|-----------------|
| 161 | systemd (usługi) | Menedżer usług Linuxa – detal wdrożeniowy, nie architektura |

## Zmodyfikowany plik

| Plik | Zmiana |
|------|--------|
| `RAPORT_TECHNOLOGII_NEXUSAI.txt` | Usunięto całą sekcję **2.18 INFRASTRUKTURA / DEVOPS** (9 pozycji + 2 podsekcje CI/CD i Systemd). Przenumerowano sekcje 2.19→2.25 na 2.18→2.25. Przenumerowano pozycje ≥162 (dekrementacja o 9). |

## Scalenie locust i py-spy

- **`locust`** — już występuje w sekcji 2.21 (Testowanie), poz. 217. Opis w usuniętej sekcji był ogólny (`Testy wydajności (Locust)`), brak unikalnych informacji do scalenia.
- **`py-spy`** — nie występuje jako osobna pozycja w sekcji Testowanie. Opis w usuniętej sekcji był ogólny (`Profilowanie wydajności (z użyciem py-spy)`), brak unikalnych informacji do scalenia. W RAPORT występuje jedynie jako część skryptu `profiler.py` (poz. 170), co jest wystarczające.

## systemd

- Nie usunięto żadnych fizycznych plików systemd (jednostki `.service` pozostają w repozytorium).
- Usunięto jedynie wpis z listy technologii jako samodzielnej pozycji architektonicznej.
- README.md nie zawierało wzmianek o systemd jako technologii — brak zmian.

## Weryfikacja

- **grep:** Zero pozostałości 9 pozycji w `RAPORT_TECHNOLOGII_NEXUSAI.txt` i `README.md`.
- **Sekcje:** 2.1 → 2.25, numeracja ciągła bez luk.
- **Pozycje:** Numeracja ciągła (140→159).
- **Fizyczne pliki CI** (`.github/workflows/`) — nietknięte.
