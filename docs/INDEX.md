# 📚 Spis treści dokumentacji NexusAI

> **Żywy dokument** — daty aktualizacji w stopce każdej sekcji. Zmiany publikowane przez `git commit` i opisane w [`CHANGELOG.md`](CHANGELOG.md).

---

## 🗺️ Nawigacja po modułach

Dokumentacja podzielona jest na **6 logicznych bloków** (modułów iteracyjnych):

```
M1 Fundament        → README, INTRODUCTION, QUICKSTART, PROJECT_STRUCTURE
M2 Architektura     → ARCHITECTURE, DATABASE, MODULES
M3 API              → API
M4 Operacje         → INSTALLATION, TESTING, DEPLOYMENT, TROUBLESHOOTING
M5 Bezpieczeństwo   → SECURITY, COMPLIANCE
M6 Ludzie i proces  → CONTRIBUTING, USER_GUIDE, GLOSSARY, FAQ, CHANGELOG
```

---

## 📋 Kompletna lista sekcji

### Sekcja 0 — Strona tytułowa / Meta
- Plik: [`README.md`](../README.md)
- Zawartość: Misja, status (Beta), kluczowe funkcje, szybki start, licencja, zespół.

### Sekcja 2 — Spis treści
- Plik: **ten plik** [`docs/INDEX.md`](INDEX.md)
- Zawartość: Nawigacja po wszystkich 20 sekcjach.

### Sekcja 3 — Wprowadzenie
- Plik: [`docs/INTRODUCTION.md`](INTRODUCTION.md)
- Zawartość: Cel, problem (PWE), propozycja wartości, użytkownicy, scenariusze użycia, słownik.
- **Kiedy czytać:** Zanim zaczniesz pracę z NexusAI — aby zrozumieć *dlaczego* tak, a nie inaczej.

### Sekcja 4 — Szybki start (Quick Start)
- Plik: [`docs/QUICKSTART.md`](QUICKSTART.md)
- Zawartość: 15-minutowa instrukcja pierwszego uruchomienia, komendy do skopiowania.
- **Kiedy czytać:** Przed pierwszym uruchomieniem projektu lokalnie.

### Sekcja 5 — Architektura systemu
- Plik: [`docs/ARCHITECTURE.md`](ARCHITECTURE.md)
- Zawartość: Diagramy C4 (Context, Container, Component), warstwy (DDD), wzorce (CQRS, ES), ADRs (7 decyzji), sekwencje dla kluczowych procesów, model domeny (agregaty, value objects), racjonalne uzasadnienie tech-stacku.
- **Kiedy czytać:** Przed jakąkolwiek poważną zmianą w kodzie; przed review'ami.

### Sekcja 6 — Struktura projektu
- Plik: [`docs/PROJECT_STRUCTURE.md`](PROJECT_STRUCTURE.md)
- Zawartość: Drzewo `nexus_ai/`, konwencje nazewnicze, lokalizacja kluczowych plików.
- **Kiedy czytać:** Gdy szukasz *gdzie* coś jest w kodzie.

### Sekcja 7 — Instalacja i konfiguracja
- Plik: [`docs/INSTALLATION.md`](INSTALLATION.md)
- Zawartość: Szczegółowa instalacja (klonowanie, pixi, env vars, profile), `.env.example`, różnice dev/staging/prod.
- **Kiedy czytać:** Przy konfiguracji nowego środowiska (developer/serwer/CI).

### Sekcja 8 — Baza danych
- Plik: [`docs/DATABASE.md`](DATABASE.md)
- Zawartość: Diagram ERD, opis każdej tabeli/kolekcji (pola, typy, indeksy), strategia migracji i seedowania, backup i odtwarzanie.
- **Kiedy czytać:** Przed pracą ze schematem DB; przed migracjami.

### Sekcja 9 — API / Komunikacja
- Plik: [`docs/API.md`](API.md)
- Zawartość: Pełna specyfikacja REST (autentykacja JWT, endpointy pogrupowane tematycznie, kody błędów, rate limiting, wersjonowanie).
- **Kiedy czytać:** Przed integracją z NexusAI z zewnątrz; przed testami E2E.

### Sekcja 10 — Moduły / Logika biznesowa
- Plik: [`docs/MODULES.md`](MODULES.md)
- Zawartość: Opis 60+ serwisów, 5 agentów AI, pipeline OCR (4 silniki), sekwencje dla księgowania i Rady Agentów.
- **Kiedy czytać:** Gdy pracujesz na konkretnym serwisie lub planujesz nowy.

### Sekcja 11 — Testowanie
- Plik: [`docs/TESTING.md`](TESTING.md)
- Zawartość: Strategia (jednostkowe, integracyjne, property-based, fuzz, wydajnościowe), szablon testów, specyfika księgowa.
- **Kiedy czytać:** Przed pisaniem pierwszego testu; przed wdrożeniem.

### Sekcja 12 — Wdrożenie / Deployment
- Plik: [`docs/DEPLOYMENT.md`](DEPLOYMENT.md)
- Zawartość: Środowiska (dev/staging/prod), budowanie binarki (Nuitka+Inno Setup), instalator Windows, aktualizacje OTA, CI/CD.
- **Kiedy czytać:** Przed release'em; przy konfiguracji CI/CD.

### Sekcja 13 — Rozwiązywanie problemów
- Plik: [`docs/TROUBLESHOOTING.md`](TROUBLESHOOTING.md)
- Zawartość: Lista częstych błędów + rozwiązania, poradnik debugowania.
- **Kiedy czytać:** Gdy coś nie działa — przed otwarciem issue.

### Sekcja 14 — Bezpieczeństwo
- Plik: [`docs/SECURITY.md`](SECURITY.md)
- Zawartość: Threat model, szyfrowanie (AEAD, Argon2id), RBAC, JWT, OWASP Top 10, RODO, zależności (Dependabot, Scorecard, CodeQL, SBOM, SLSA).
- **Kiedy czytać:** Przed audytem bezpieczeństwa; przed zgłoszeniem podatności.

### Sekcja 15 — Zgodność z przepisami
- Plik: [`docs/COMPLIANCE.md`](COMPLIANCE.md)
- Zawartość: Zgodność z UoR/IFRS/GAAP, KSeF, JPK, deklaracje VAT/CIT/PIT, ścieżka audytu, retencja.
- **Kiedy czytać:** Przed audytem księgowym; przed wdrożeniem produkcyjnym.

### Sekcja 16 — Proces rozwoju / Contributing
- Plik: [`docs/CONTRIBUTING.md`](CONTRIBUTING.md)
- Zawartość: Setup dev, standardy kodowania (ruff, mypy strict), konwencje commitów, code review, jak dodać agenta/regułę.
- **Kiedy czytać:** Przed pierwszym PR; przy onboardingu do zespołu.

### Sekcja 17 — Podręcznik użytkownika
- Plik: [`docs/USER_GUIDE.md`](USER_GUIDE.md)
- Zawartość: Pierwsze uruchomienie, role, codzienny workflow, centrum decyzji, raporty, konfiguracja, integracje, backup.
- **Kiedy czytać:** Jako instrukcja dla przedsiębiorcy-końcowego użytkownika.

### Sekcja 18 — Słownik pojęć
- Plik: [`docs/GLOSSARY.md`](GLOSSARY.md)
- Zawartość: Terminy księgowe (UoR, KSeF, JPK, NIP, IBAN, BIL, RMK) + techniczne (CQRS, ES, GGUF, NATS, JetStream, JetStream KV, OPA, Rego).
- **Kiedy czytać:** W razie wątpliwości co do terminu.

### Sekcja 19 — FAQ
- Plik: [`docs/FAQ.md`](FAQ.md)
- Zawartość: Najczęściej zadawane pytania wstępne, techniczne i biznesowe.
- **Kiedy czytać:** Przed zadaniem pytania maintainerom.

### Sekcja 20 — Dodatki
- Plik: [`docs/CHANGELOG.md`](CHANGELOG.md)
- Zawartość: Wersje, daty, autorzy, linki do GitHub Releases.
- **Kiedy czytać:** Przed aktualizacją; przy ocenie wpływu zmiany.

---

## 🔎 Szybkie wyszukiwanie

| Szukam… | Idź do… |
|---|---|
| Jak uruchomić? | [`QUICKSTART.md`](QUICKSTART.md) |
| Jakie mamy endpointy? | [`API.md`](API.md) |
| Jak działa księgowanie? | [`MODULES.md`](MODULES.md#moduł-księgowania) |
| Gdzie jest model Invoice? | `nexus_ai/db/models.py` — patrz [`PROJECT_STRUCTURE.md`](PROJECT_STRUCTURE.md) |
| Jak rotować klucze? | [`SECURITY.md`](SECURITY.md#rotacja-kluczy) |
| Co nowego w 2.3.0? | [`CHANGELOG.md`](CHANGELOG.md) |

---

> **Data aktualizacji:** 2026-07-04 · **Autor:** NexusAI Team · **Wersja:** 2.3.0
