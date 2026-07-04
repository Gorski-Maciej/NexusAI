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
- Zawartość: Diagramy C4 (Context, Container, Component), warstwy (DDD), wzorce (CQRS, ES), ADRs (8 decyzji — patrz [lista poniżej](#lista-decyzji-architektonicznych-adr)), sekwencje dla kluczowych procesów, model domeny (agregaty, value objects), racjonalne uzasadnienie tech-stacku.
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
- Zawartość: Opis 60+ serwisów, agenci AI (konfigurowalne modele GGUF), pipeline OCR (4 silniki), sekwencje dla księgowania i Rady Agentów.
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

## 🏷️ Indeks tagów / słów kluczowych (Ctrl+F friendly)

> Kliknij dowolny tag, aby przejść do odpowiedniej sekcji. Używaj Ctrl+F w przeglądarce.

### #A

| Tag | Sekcja | Plik |
|---|---|---|
| `#ADR` `#decyzje-architektoniczne` | [Lista ADR](#lista-decyzji-architektonicznych-adr), [ADR-001–008](ARCHITECTURE.md#5-kluczowe-decyzje-architektoniczne-adr) | INDEX, ARCHITECTURE |
| `#AEAD` `#szyfrowanie` `#ChaCha20` | [Szyfrowanie danych w spoczynku](SECURITY.md#21-dane-w-spoczynku-data-at-rest), [Backup AEAD](DEPLOYMENT.md#62-proces-backupu) | SECURITY, DEPLOYMENT |
| `#AES-256` `#SQLCipher` | [SQLCipher](DATABASE.md#1-architektura-wielobazowa), [Szyfrowanie bazy](SECURITY.md#21-dane-w-spoczynku-data-at-rest) | DATABASE, SECURITY |
| `#agenci-AI` `#modele-GGUF` | [Przegląd agentów](MODULES.md#1-przegląd-agentów-ai-konfigurowalne-modele-gguf), [Bezpieczeństwo AI](SECURITY.md#6-bezpieczeństwo-ai) | MODULES, SECURITY |
| `#amortyzacja` `#środki-trwałe` | [Środki trwałe](MODULES.md#41-księgowość-accounting), [Amortyzacja liniowa](TESTING.md#55-amortyzacja-liniowa) | MODULES, TESTING |
| `#API` `#REST` `#endpointy` | [Pełna specyfikacja API](API.md), [Autentykacja JWT](API.md#1-autentykacja) | API |
| `#Argon2id` `#hash-haseł` | [nexus-crypto](SECURITY.md#23-własny-moduł-kryptograficzny-nexus-crypto), [Autentykacja](SECURITY.md#3-autentykacja) | SECURITY |
| `#ASK_USER` `#centrum-decyzji` | [Poziomy decyzji](MODULES.md#22-poziomy-decyzji-trust-score), [Codzienny workflow](USER_GUIDE.md#3-codzienny-workflow) | MODULES, USER_GUIDE |
| `#audyt` `#ścieżka-audytu` | [Ścieżka audytu](COMPLIANCE.md#5-ścieżka-audytu), [Audit Logs](SECURITY.md#52-audit-logs) | COMPLIANCE, SECURITY |
| `#AUTO_POST` `#automatyczne-księgowanie` | [Poziomy decyzji](MODULES.md#22-poziomy-decyzji-trust-score), [Codzienny workflow](USER_GUIDE.md#3-codzienny-workflow) | MODULES, USER_GUIDE |

### #B

| Tag | Sekcja | Plik |
|---|---|---|
| `#backup` `#przywracanie` | [Backup i przywracanie](DATABASE.md#6-backup-i-przywracanie), [BackupManager](DEPLOYMENT.md#6-backup-i-przywracanie), [Backup użytkownika](USER_GUIDE.md#8-backup) | DATABASE, DEPLOYMENT, USER_GUIDE |
| `#Biała-Lista-MF` `#white-list` | [White List](COMPLIANCE.md#7-white-list--biała-lista-mf), [Integracje](USER_GUIDE.md#72-biała-lista-mf) | COMPLIANCE, USER_GUIDE |
| `#build` `#Nuitka` `#kompilacja` | [Budowanie binarki](DEPLOYMENT.md#2-budowanie-finalnej-binarki), [CI/CD](DEPLOYMENT.md#8-proces-cicd) | DEPLOYMENT |

### #C

| Tag | Sekcja | Plik |
|---|---|---|
| `#CI/CD` `#GitHub-Actions` | [Pipeline CI/CD](DEPLOYMENT.md#8-proces-cicd), [Testy w CI](TESTING.md#7-cicd--testy-w-pipeline) | DEPLOYMENT, TESTING |
| `#CIT` `#CIT-8` | [CIT-8](COMPLIANCE.md#42-cit-8), [Deklaracje podatkowe](USER_GUIDE.md#5-raporty) | COMPLIANCE, USER_GUIDE |
| `#CQRS` `#Event-Sourcing` | [Wzorce projektowe](ARCHITECTURE.md#3-wzorce-projektowe), [Warstwy DDD](ARCHITECTURE.md#2-warstwy-architektoniczne-ddd) | ARCHITECTURE |
| `#crosshair` `#property-based-testing` | [Property-based testing](TESTING.md#32-crosshair-property-based-testing-z-smt-solverem) | TESTING |

### #D

| Tag | Sekcja | Plik |
|---|---|---|
| `#debug` `#logi` | [Logi i debugowanie](TROUBLESHOOTING.md#8-logi-i-debugowanie), [Gdzie są logi](DEPLOYMENT.md#91-gdzie-są-logi) | TROUBLESHOOTING, DEPLOYMENT |
| `#DuckDB` `#OLAP` | [Architektura wielobazowa](DATABASE.md#1-architektura-wielobazowa), [Stos technologiczny](ARCHITECTURE.md#7-stos-technologiczny--pełne-uzasadnienie) | DATABASE, ARCHITECTURE |
| `#domena` `#DDD` `#agregaty` | [Model domeny](ARCHITECTURE.md#6-model-domeny), [Value Objects](ARCHITECTURE.md#62-value-objects-wszystkie-immutable--frozentrue) | ARCHITECTURE |

### #F

| Tag | Sekcja | Plik |
|---|---|---|
| `#FIFO` `#zapasy` | [Inventory FIFO](MODULES.md#41-księgowość-accounting), [IAS 2](COMPLIANCE.md#12-miedzynarodowe-standardy-ifrs--mssf) | MODULES, COMPLIANCE |
| `#Flet` `#UI` `#Flutter` | [ADR-008](ARCHITECTURE.md#adr-008-flet-flutter-zamiast-electronreact-dla-interfejsu-desktopowego), [Presentation Layer](ARCHITECTURE.md#24-presentation-layer-nexus_aifrontend) | ARCHITECTURE |

### #G

| Tag | Sekcja | Plik |
|---|---|---|
| `#GGUF` `#kwantyzacja` | [Modele GGUF](MODULES.md#1-przegląd-agentów-ai-5-modeli-gguf), [Słownik](GLOSSARY.md#b-terminy-techniczne) | MODULES, GLOSSARY |
| `#Granian` `#ASGI` | [Stos technologiczny](ARCHITECTURE.md#7-stos-technologiczny--pełne-uzasadnienie), [Konfiguracja](INSTALLATION.md#31-plik-env-opcjonalny-pixi-ustawia-własne) | ARCHITECTURE, INSTALLATION |

### #I

| Tag | Sekcja | Plik |
|---|---|---|
| `#IFRS` `#MSSF` | [Zgodność IFRS/MSSF](COMPLIANCE.md#12-miedzynarodowe-standardy-ifrs--mssf) | COMPLIANCE |
| `#instalacja` `#setup` | [Instrukcja 6 kroków](INSTALLATION.md#2-instalacja-krok-po-kroku), [Szybki start](QUICKSTART.md) | INSTALLATION, QUICKSTART |

### #J

| Tag | Sekcja | Plik |
|---|---|---|
| `#JPK` `#JPK_V7` | [Struktury JPK](COMPLIANCE.md#3-jpk-jednolity-plik-kontrolny), [Eksport JPK](API.md#32-faktury-apiv1invoices) | COMPLIANCE, API |
| `#JWT` `#autentykacja` | [JWT Token Flow](API.md#1-autentykacja), [JWT w bezpieczeństwie](SECURITY.md#31-jwt-json-web-tokens) | API, SECURITY |

### #K

| Tag | Sekcja | Plik |
|---|---|---|
| `#KSeF` `#e-faktury` | [KSeF — pełna dokumentacja](COMPLIANCE.md#2-ksef-krajowy-system-e-faktur), [Endpointy KSeF](API.md#36-ksef-apiv1ksef), [Integracja KSeF](USER_GUIDE.md#71-ksef-krajowy-system-e-faktur) | COMPLIANCE, API, USER_GUIDE |
| `#konfiguracja` `#env` | [Zmienne środowiskowe](INSTALLATION.md#3-zmienne-środowiskowe), [Profile konfiguracyjne](INSTALLATION.md#32-profile-konfiguracyjne) | INSTALLATION |
| `#konwencje` `#nazewnictwo` | [Konwencje nazewnicze](PROJECT_STRUCTURE.md#3-konwencje-nazewnicze), [Standardy kodu](CONTRIBUTING.md#2-standardy-kodowania) | PROJECT_STRUCTURE, CONTRIBUTING |

### #M

| Tag | Sekcja | Plik |
|---|---|---|
| `#migracje` `#SQL` | [Strategia migracji](DATABASE.md#4-strategia-migracji), [Migracje w kodzie](CONTRIBUTING.md#64-nowa-migracja-bazy-danych) | DATABASE, CONTRIBUTING |
| `#mimalloc` `#pamięć` | [Stos technologiczny](ARCHITECTURE.md#7-stos-technologiczny--pełne-uzasadnienie), [Budżet RAM](DEPLOYMENT.md#4-wymagania-systemowe-produkcja) | ARCHITECTURE, DEPLOYMENT |
| `#monitoring` `#OTel` | [Monitorowanie produkcyjne](DEPLOYMENT.md#9-monitorowanie-i-logowanie-produkcja), [OpenTelemetry](ARCHITECTURE.md#7-stos-technologiczny--pełne-uzasadnienie) | DEPLOYMENT, ARCHITECTURE |

### #N

| Tag | Sekcja | Plik |
|---|---|---|
| `#NATS` `#JetStream` | [ADR-003](ARCHITECTURE.md#adr-003-nats-zamiast-rabbitmq), [Komunikacja NATS](MODULES.md#8-komunikacja-wewnętrzna-nats-jetstream) | ARCHITECTURE, MODULES |
| `#NBP` `#kursy-walut` | [Integracja NBP](USER_GUIDE.md#73-nbp-kursy-walut), [Rewaluacja FX](MODULES.md#41-księgowość-accounting) | USER_GUIDE, MODULES |
| `#NIP` `#walidacja` | [Value Object NIP](ARCHITECTURE.md#62-value-objects-wszystkie-immutable--frozentrue), [Weryfikacja kontrahenta](API.md#33-kontrahenci-apiv1contractors) | ARCHITECTURE, API |

### #O

| Tag | Sekcja | Plik |
|---|---|---|
| `#OCR` `#pipeline` | [Pipeline OCR](MODULES.md#3-pipeline-ocr--architektura-warstwowa), [Component OCR](ARCHITECTURE.md#13-component-poziom-3--pipeline-ocr) | MODULES, ARCHITECTURE |
| `#OPA` `#Rego` | [Reguły Rego](MODULES.md#54-reguły-rego-opa), [Dodawanie reguły](CONTRIBUTING.md#61-nowa-reguła-podatkowa-oparego) | MODULES, CONTRIBUTING |
| `#OWASP` `#bezpieczeństwo-aplikacji` | [OWASP Top 10](SECURITY.md#7-owasp-top-10) | SECURITY |

### #P

| Tag | Sekcja | Plik |
|---|---|---|
| `#PIT` `#PIT-36` `#PIT-36L` | [PIT-36/PIT-36L](COMPLIANCE.md#43-pit-36--pit-36l), [Symulacje podatkowe](MODULES.md#43-podatki-tax) | COMPLIANCE, MODULES |
| `#pixi` `#środowisko` | [Instalacja pixi](INSTALLATION.md#krok-1-instalacja-pixi), [Cheat-sheet](QUICKSTART.md#4-skrócony-cheat-sheet) | INSTALLATION, QUICKSTART |
| `#Proof-Chain` `#SHA-256` | [Proof Chain](COMPLIANCE.md#5-ścieżka-audytu), [Integrity Verifier](MODULES.md#42-decyzje-i-triage) | COMPLIANCE, MODULES |

### #R

| Tag | Sekcja | Plik |
|---|---|---|
| `#RBAC` `#role` | [Role i uprawnienia](SECURITY.md#4-rbac-role-based-access-control), [Role użytkowników](USER_GUIDE.md#2-role-użytkowników-rbac) | SECURITY, USER_GUIDE |
| `#REST-API` `#endpointy` | [Pełna specyfikacja](API.md#3-endpointy--pogrupowane-tematycznie) | API |
| `#RODO` `#GDPR` | [RODO/GDPR](SECURITY.md#9-rodo--gdpr), [Retencja](COMPLIANCE.md#6-przechowywanie-danych) | SECURITY, COMPLIANCE |
| `#Rust` `#PyO3` `#nexus-crypto` | [ADR-007](ARCHITECTURE.md#adr-007-własny-moduł-kryptograficzny-w-rust-nexus-crypto), [Moduł Rust](SECURITY.md#23-własny-moduł-kryptograficzny-nexus-crypto) | ARCHITECTURE, SECURITY |

### #S

| Tag | Sekcja | Plik |
|---|---|---|
| `#Split-Payment` `#MPP` | [Split Payment](COMPLIANCE.md#8-split-payment-mpp) | COMPLIANCE |
| `#SQLite` `#OLTP` | [ADR-001](ARCHITECTURE.md#adr-001-sqlite-zamiast-postgresql), [Architektura DB](DATABASE.md#1-architektura-wielobazowa) | ARCHITECTURE, DATABASE |
| `#struktura-projektu` `#katalogi` | [Drzewo katalogów](PROJECT_STRUCTURE.md#1-top-level--widok-z-lotu-ptaka), [Szczegółowe drzewo](PROJECT_STRUCTURE.md#2-szczegółowe-drzewo-nexus_ai) | PROJECT_STRUCTURE |

### #T

| Tag | Sekcja | Plik |
|---|---|---|
| `#TigerBeetle` `#ledger` | [ADR-002](ARCHITECTURE.md#adr-002-tigerbeetle-do-księgi-głównej), [TigerBeetle secure](ARCHITECTURE.md#7-stos-technologiczny--pełne-uzasadnienie) | ARCHITECTURE |
| `#testy` `#testowanie` | [Strategia testów](TESTING.md#1-strategia-testów), [Jak pisać testy](TESTING.md#4-szablon-testu--jak-pisać-nowe-testy) | TESTING |
| `#triage` `#decyzje` | [Centrum Decyzji](USER_GUIDE.md#4-centrum-decyzji), [Endpointy triage](API.md#34-decyzje--triage-apiv1triage) | USER_GUIDE, API |

### #U

| Tag | Sekcja | Plik |
|---|---|---|
| `#UoR` `#ustawa-o-rachunkowości` | [Zgodność z UoR](COMPLIANCE.md#11-ustawa-o-rachunkowości-uor) | COMPLIANCE |
| `#uruchomienie` `#quickstart` | [Szybki start](QUICKSTART.md) | QUICKSTART |

### #V

| Tag | Sekcja | Plik |
|---|---|---|
| `#VAT` `#stawki` | [Deklaracje VAT](COMPLIANCE.md#41-vat-7--vat-7k), [Stawki VAT](USER_GUIDE.md#61-stawki-vat), [VAT Reconciliation](MODULES.md#41-księgowość-accounting) | COMPLIANCE, USER_GUIDE, MODULES |

### #W

| Tag | Sekcja | Plik |
|---|---|---|
| `#wdrożenie` `#deploy` | [Deployment](DEPLOYMENT.md), [Środowiska](DEPLOYMENT.md#1-środowiska) | DEPLOYMENT |
| `#wzorce-projektowe` `#design-patterns` | [14 wzorców](ARCHITECTURE.md#3-wzorce-projektowe) | ARCHITECTURE |

---

## 📋 Lista decyzji architektonicznych (ADR)

Wszystkie ADR znajdują się w [`ARCHITECTURE.md`](ARCHITECTURE.md#5-kluczowe-decyzje-architektoniczne-adr):

| ADR | Decyzja | Data |
|---|---|---|
| [ADR-001](ARCHITECTURE.md#adr-001-sqlite-zamiast-postgresql) | SQLite zamiast PostgreSQL | 2025-02-01 |
| [ADR-002](ARCHITECTURE.md#adr-002-tigerbeetle-do-księgi-głównej) | TigerBeetle do księgi głównej | 2025-03-15 |
| [ADR-003](ARCHITECTURE.md#adr-003-nats-zamiast-rabbitmq) | NATS zamiast RabbitMQ | 2025-01-10 |
| [ADR-004](ARCHITECTURE.md#adr-004-4-silniki-ocr-zamiast-jednego-vlm) | 4 silniki OCR zamiast jednego VLM | 2025-04-20 |
| [ADR-005](ARCHITECTURE.md#adr-005-python-313-free-threaded-bez-gil) | Python 3.13 free-threaded (bez GIL) | 2025-06-01 |
| [ADR-006](ARCHITECTURE.md#adr-006-modularny-monolit-zamiast-mikrousług) | Modularny Monolit zamiast mikrousług | 2025-02-15 |
| [ADR-007](ARCHITECTURE.md#adr-007-własny-moduł-kryptograficzny-w-rust-nexus-crypto) | Własny moduł kryptograficzny w Rust (nexus-crypto) | 2025-03-01 |
| [ADR-008](ARCHITECTURE.md#adr-008-flet-flutter-zamiast-electronreact-dla-interfejsu-desktopowego) | Flet (Flutter) zamiast Electron/React dla interfejsu desktopowego | 2025-07-15 |

---

> **Data aktualizacji:** 2026-07-04 · **Autor:** NexusAI Team · **Wersja:** 2.3.0
> **Status dokumentu:** Stabilny · **Ostatnia weryfikacja:** 2026-07-04 · **Weryfikator:** NexusAI Team
