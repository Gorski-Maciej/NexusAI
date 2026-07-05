# 🔗 Powiązane dokumenty i źródła (Related)

> **Cel:** Szybki indeks linków do źródeł zewnętrznych, white papers, konferencji i porównywalnych systemów. Uzupełnia [`BIBLIOGRAPHY.md`](BIBLIOGRAPHY.md) (który jest formalną bibliografią).

---

## 1. Podobne/porównywalne systemy (kontekst rynkowy)

| System | Typ | Wspólne z NexusAI | Różnice | Link |
|---|---|---|---|---|
| **Subiekt GT** | Księgowość (pol. desktop) | Reguły KSeF, JPK | Model SaaS/local-first, brak AI | https://www.insert.com.pl |
| **Sage Symfonia** | ERP (desktop) | Polski plan kont, UoR | Cięższy stack, brak agentów AI | https://www.sage.com/pl |
| **Fakturownia.pl** | SaaS fakturowanie | Integracja KSeF | Tylko fakturowanie, chmura | https://fakturownia.pl |
| **inFakt** | SaaS księgowość | UI desktop-like, integracje | Brak self-host/offline-first | https://www.infakt.pl |
| **QuickBooks (US)** | SaaS accounting | AI categorisation | Inne przepisy, brak KSeF | https://quickbooks.intuit.com |
| **Xero (UK)** | SaaS accounting | Double-entry UI | Inne przepisy, chmura | https://xero.com |
| **Bench (US)** | SaaS + AI bookkeeping | AI-powered categorisation | Cloud-only | https://bench.co |

> NexusAI wyróżnia się: **offline-first** + **lokalne AI (GGUF)** + **pełna zgodność z polską specyfiką (KSeF/JPK/Biała Lista)** + **open-source'owy stack** + **niska bariera (6 GB RAM)**.

---

## 2. Komponenty, na których opiera się NexusAI

### 2.1 Silniki i frameworki

| Komponent | Rola w NexusAI | Link do materiałów |
|---|---|---|
| **Litestar** | Framework API ASGI | https://docs.litestar.dev |
| **Granian** | Serwer HTTP w Rust | https://github.com/emmett-framework/granian |
| **TigerBeetle** | Księga główna (double-entry) | https://docs.tigerbeetle.com |
| **NATS JetStream** | Event bus + KV Store | https://docs.nats.io/nats-concepts/jetstream |
| **DuckDB** | OLAP + symulacje podatkowe | https://duckdb.org |
| **Polars** | DataFrame (analityka) | https://pola-rs.github.io/polars |
| **llama.cpp** | LLM inference (GGUF, CPU) | https://github.com/ggerganov/llama.cpp |
| **SQLCipher** | Szyfrowanie AES-256 SQLite | https://www.zetetic.net/sqlcipher |
| **OPA** | Silnik reguł (Rego) | https://www.openpolicyagent.org |
| **Flet** | UI desktopowy (Flutter) | https://flet.dev |

### 2.2 Algorytmy (white papers)

| Algorytm | Zastosowanie | Link |
|---|---|---|
| **Argon2id** | Hashowanie haseł (RODO bezpieczeństwo) | https://datatracker.ietf.org/doc/html/rfc9106 |
| **ChaCha20-Poly1305** | AEAD szyfrowanie backupów | https://datatracker.ietf.org/doc/html/rfc8439 |
| **SHA-256** | Proof Chain (łańcuch audytowy) | https://datatracker.ietf.org/doc/html/rfc6234 |
| **PBKDF2 (legacy fallback)** | Kompatybilność | https://datatracker.ietf.org/doc/html/rfc8018 |
| **Levenshtein distance** | Konsensus OCR (4 silniki) | https://en.wikipedia.org/wiki/Levenshtein_distance |
| **Tiger hash tree** | TigerBeetle integrality | https://docs.tigerbeetle.com |

---

## 3. Materiały konferencyjne i prelekcje

| Konferencja | Tytuł/wystąpienie | Rok | Materiały |
|---|---|---|---|
| **PyCon US 2024** | "Free-threaded Python: A New Era for Multi-threading" | 2024 | confhub.io/PyConUS2024 |
| **EuroPython 2024** | "Building high-performance APIs with msgspec + Litestar" | 2024 | youtube.com/@EuroPythonConference |
| **GopherCon 2023** | "Why TigerBeetle chose Zig" (Joran Dirk Greef) | 2023 | gophercon.com |
| **OWASP Global AppSec** | "Threat Modeling Desktop Applications" | 2024 | owasp.org |
| **DevConf 2024** | "Documentation as Code: C4 + Mermaid + ADR" | 2024 | devconf.info |

---

## 4. White papers i badania

| Tytuł | Autor/źródło | Temat | Rok |
|---|---|---|---|
| **TigerBeetle Whitepaper** | Joran Dirk Greef | Append-only ledger z gwarancjami | 2022 |
| **Drop the GIL: Just Say No** | Itamar Turner-Trauring | Free-threaded Python performance | 2024 |
| **Property-Based Testing with SMT** | Joe Dodson (crosshair) | Matematyczne dowody poprawności | 2023 |
| **Event Sourcing Patterns** | Chris Richardson (Microservices.io) | Saga, Outbox | 2023 |
| **Domain-Driven Design** | Eric Evans | Agregaty, Value Objects | 2003 (klasyka) |

---

## 5. Strategie i dokumenty operacyjne

| Zasób | URL | Zastosowanie |
|---|---|---|
| **NIST SSDF (Secure Software Development Framework)** | https://csrc.nist.gov/Projects/ssdf | Bezpieczeństwo łańcucha dostaw |
| **OpenSSF Scorecard** | https://scorecard.dev | Audyt repozytoriów |
| **OWASP SAMM v2** | https://owaspsamm.org | Maturity model dla security |
| **NCSC Cyber Assessment Framework** | https://www.ncsc.gov.uk/caf | UK government |
| **AGILE Manifesto** | https://agilemanifesto.org | Proces rozwoju |

---

## 6. Specyfikacje i protokoły (techniczne)

| RFC / Specyfikacja | Tytuł | Zastosowanie |
|---|---|---|
| **RFC 7519** | JSON Web Token (JWT) | Autentykacja |
| **RFC 9106** | Argon2 Memory-Hard Function | KDF haseł |
| **RFC 8439** | ChaCha20-Poly1305 AEAD | Szyfrowanie backupów |
| **RFC 6234** | US Secure Hash Algorithms (SHA) | Proof Chain |
| **RFC 9457** | Problem Details for HTTP APIs | Format błędów |
| **OpenAPI 3.1** | Specyfikacja API | Auto-generowany schema |
| **OGC Standard** | KSeF FA_VAT(2) XSD | Struktura faktury |

---

## 7. Zasoby polskie (przepisy, praktyka)

| Źródło | URL | Zastosowanie |
|---|---|---|
| **e-Urząd Skarbowy** | https://www.podatki.gov.pl | Wszystkie deklaracje |
| **Biała Lista — wyszukiwarka** | https://www.podatki.gov.pl/wykaz-podatnikow-vat-wyszukiwarka | Weryfikacja kontrahentów |
| **KSeF Sandbox** | https://ksef-test.mf.gov.pl | Testy integracji |
| **NBP API** | http://api.nbp.pl | Kursy walut |
| **GUS BIR** | https://wyszukiwarka.ceidg.gov.pl/CEIDG | Wyszukiwanie przedsiębiorców |
| **KRS** | https://ekrs.ms.gov.pl | Rejestr spółek |
| **SKwP (Stowarzyszenie Księgowych w Polsce)** | https://skwp.pl | Zasady wykonywania zawodu |
| **KIDP (Krajowa Izba Doradców Podatkowych)** | https://kidp.pl | Doradztwo podatkowe |
| **PIIT (Polska Izba Informatyki i Telekomunikacji)** | https://www.piit.org.pl | Standardy IT |
| **Rzecznik Praw Przedsiębiorców** | https://www.rzecznikmsp.pl | Wsparcie MŚP |

---

## 8. Polskie grupy dyskusyjne / społeczność

| Grupa | URL |
|---|---|
| **r/ksiegowosc** (Reddit) | https://reddit.com/r/ksiegowosc |
| **Księgowość w praktyce** (LinkedIn grupa) | linkedin.com |
| **Python w finansach PL** (Discord) | discord.com |
| **Forum OCAD** (OpenCartoCommunity Polska) | forum.opencart.pl |

---

## 9. Narzędzia deweloperskie (do dokumentowania)

| Narzędzie | Zastosowanie | URL |
|---|---|---|
| **Mermaid** | Diagramy w Markdown | https://mermaid.js.org |
| **C4-PlantUML** | Diagramy C4 alternatywa | https://github.com/plantuml-stdlib/C4-PlantUML |
| **draw.io / diagrams.net** | Diagramy architektoniczne | https://app.diagrams.net |
| **Excalidraw** | Szkice architektury | https://excalidraw.com |
| **ASCIIFlow** | ASCII diagramy | https://asciiflow.com |
| **Markdown Preview** | VSCode extension | marketplace.visualstudio.com |

---

## 10. Przydatne identyfikatory (standardy przemysłowe)

| Standard | Wartość |
|---|---|
| **Warsaw time zone** | Europe/Warsaw (CET/CEST) |
| **Waluta bazowa** | PLN (ISO 4217) |
| **Format daty** | ISO 8601 (YYYY-MM-DD) |
| **Separator dziesiętny** | `.` (wewnętrznie) / `,` (UI dla PL locale) |
| **Sortowanie string** | Unicode CLDR dla pl_PL |
| **Charakter dla NIP** | 10 cyfr dziesiętnych |
| **Charakter dla PESEL** | 11 cyfr dziesiętnych |
| **Charakter dla REGON** | 9 lub 14 cyfr dziesiętnych |
| **Charakter dla IBAN (PL)** | PL + 2 cyfry check + 24 cyfry |
| **Kod pocztowy** | `^\d{2}-\d{3}$` |

---

## 🔗 Zobacz również

- [00_META](00_META.md) — strona tytułowa z zespołem i PWE
- [Bibliografia](BIBLIOGRAPHY.md) — formalna bibliografia
- [Compliance](COMPLIANCE.md) — implementacja zgodności
- [Security](SECURITY.md) — bezpieczeństwo

---

> **Data aktualizacji:** 2026-07-05 · **Autor:** NexusAI Team · **Wersja:** 3.0.0-dev
> **Status dokumentu:** Stabilny · **Ostatnia weryfikacja:** 2026-07-05 · **Weryfikator:** Technical Lead
