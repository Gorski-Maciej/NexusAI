# 📚 Bibliografia (Bibliography)

> **Cel:** Pełny wykaz źródeł prawnych i technicznych, na które powołuje się dokumentacja NexusAI.  \n> **Kiedy czytać:** Przed audytem, przed kontrolą skarbową, przy wątpliwościach interpretacyjnych.

---

## 1. Akty prawne (Polska)

| # | Tytuł | Sygnatura | Data | Kluczowe artykuły |
|---|---|---|---|---|
| 1 | **Ustawa o rachunkowości** | Dz.U. 1994 nr 121 poz. 591 (tekst jednolity 2023) | 1994-09-29 | Art. 4, 6, 7, 13, 20, 22, 24, 28, 74 |
| 2 | **Ordynacja podatkowa** | Dz.U. 1997 nr 137 poz. 926 (tekst jednolity 2023) | 1997-08-29 | Art. 70 § 1 (deklaracje), 86 § 1 (faktury VAT) |
| 3 | **Ustawa o VAT** | Dz.U. 2004 nr 54 poz. 535 (tekst jednolity 2023) | 2004-03-11 | Art. 41, 146a (MPP), załącznik 15 (towary MPP) |
| 4 | **Ustawa o CIT** | Dz.U. 1992 nr 21 poz. 86 (tekst jednolity 2023) | 1992-02-15 | Art. 7, 9, 15, 19 (stawka 19%, 9% mały podatnik) |
| 5 | **Ustawa o PIT** | Dz.U. 1991 nr 80 poz. 350 (tekst jednolity 2022) | 1991-07-26 | Art. 27 (skala), 30c (liniowy 19%) |
| 6 | **Ustawa o ryczałcie** | Dz.U. 1998 nr 144 poz. 930 (tekst jednolity 2022) | 1998-09-20 | Art. 12 (stawki ryczałtu 2-17%) |
| 7 | **Ustawa o KSeF** | Dz.U. 2021 poz. 1621 (nowelizacja z 2023) | 2021-08-26 | Art. 106 (obowiązek e-faktur) |
| 8 | **RODO** | Rozporządzenie UE 2016/679 | 2016-04-27 | Art. 5, 17, 25, 32 |
| 9 | **Ustawa o JPK** | Dz.U. 2018 poz. 2194 | 2018-11-30 | Struktury JPK_V7 |

> Pełne polskie teksty jednolite: https://isap.sejm.gov.pl

---

## 2. Komunikaty i objaśnienia MF

| Temat | Dokument | Data |
|---|---|---|
| Struktury JPK_V7 | Komunikat MF z 24.06.2020 | 2020-06-24 |
| Struktury KSeF (FA_VAT) | Komunikat MF z 25.03.2021 | 2021-03-25 |
| Wariant 2 KSeF (FA_VAT(2)) | Komunikat MF z 30.06.2022 | 2022-06-30 |
| Biała Lista MF — zakres | Komunikat MF z 16.09.2019 | 2019-09-16 |
| Stawki ryczałtu (tabela) | Komunikat MF z 25.07.2022 | 2022-07-25 |

---

## 3. Standardy rachunkowości międzynarodowej

| Standard | Tytuł | Wydawca |
|---|---|---|
| **IFRS 15** | Revenue from Contracts with Customers | IASB |
| **IFRS 16** | Leases | IASB |
| **IAS 2** | Inventories | IASB |
| **IAS 12** | Income Taxes | IASB |
| **IAS 16** | Property, Plant and Equipment | IASB |
| **IAS 21** | The Effects of Changes in Foreign Exchange Rates | IASB |
| **IAS 32** | Financial Instruments: Presentation | IASB |
| **IFRS for SMEs** | International Financial Reporting Standard for Small and Medium-sized Entities | IASB |

> Pełne teksty standardów: https://www.ifrs.org/issued-standards/

---

## 4. Dokumentacja techniczna (stack)

### 4.1 Języki i runtime

| Tech | Dokumentacja |
|---|---|
| Python 3.13 (free-threaded) | https://docs.python.org/3.13/ + PEP 703 (no-GIL) |
| Rust (nightly → stable) | https://doc.rust-lang.org/book/ + https://rust-lang.github.io/rustup/ |
| PyO3 | https://pyo3.rs/ |
| Maturin | https://www.maturin.rs/ |

### 4.2 Framework API

| Tech | Dokumentacja |
|---|---|
| Litestar 2.12 | https://docs.litestar.dev/ |
| Granian 1.5 | https://github.com/emmett-framework/granian |
| msgspec | https://jcristharif.com/msgspec/ |
| SQLModel | https://sqlmodel.tiangolo.com/ |
| anyio | https://anyio.readthedocs.io/ |

### 4.3 Bazy danych

| Tech | Dokumentacja |
|---|---|
| SQLite (core) | https://www.sqlite.org/docs.html |
| SQLCipher | https://www.zetetic.net/sqlcipher/ |
| sqlite-vec | https://github.com/asg017/sqlite-vec |
| DuckDB | https://duckdb.org/docs/ |
| Polars | https://pola-rs.github.io/polars/ |
| TigerBeetle | https://docs.tigerbeetle.com/ |
| PyArrow | https://arrow.apache.org/docs/python/ |

### 4.4 Messaging i async

| Tech | Dokumentacja |
|---|---|
| NATS Server | https://docs.nats.io/ |
| NATS JetStream | https://docs.nats.io/nats-concepts/jetstream |
| nats-py | https://github.com/nats-io/nats.py |
| Taskiq | https://taskiq-python.readthedocs.io/ |

### 4.5 AI / OCR

| Tech | Dokumentacja |
|---|---|
| llama.cpp | https://github.com/ggerganov/llama.cpp |
| llama-cpp-python | https://llama-cpp-python.readthedocs.io/ |
| GGUF (format modeli) | https://github.com/ggerganov/ggml/blob/master/docs/gguf.md |
| Tesseract OCR | https://tesseract-ocr.github.io/tessdoc/ |
| PaddleOCR | https://github.com/PaddlePaddle/PaddleOCR |
| docTR | https://github.com/mindee/doctr |
| EasyOCR | https://github.com/JaidedAI/EasyOCR |

### 4.6 Bezpieczeństwo

| Tech | Dokumentacja |
|---|---|
| Open Policy Agent (OPA) | https://www.openpolicyagent.org/docs/ |
| Rego (język polityk) | https://www.openpolicyagent.org/docs/latest/policy-language/ |
| Argon2id (RFC 9106) | https://datatracker.ietf.org/doc/html/rfc9106 |
| ChaCha20-Poly1305 (RFC 8439) | https://datatracker.ietf.org/doc/html/rfc8439 |
| OpenTelemetry | https://opentelemetry.io/docs/ |
| JWT (RFC 7519) | https://datatracker.ietf.org/doc/html/rfc7519 |

### 4.7 Build i instalacja

| Tech | Dokumentacja |
|---|---|
| pixi | https://pixi.prefix.dev/latest/ |
| Hatchling | https://hatch.pypa.io/latest/ |
| Nuitka | https://nuitka.net/doc/user-manual.html |
| InnoSetup | https://jrsoftware.org/isinfo.php |
| UPX | https://upx.github.io/ |

### 4.8 UI

| Tech | Dokumentacja |
|---|---|
| Flet | https://flet.dev/docs/ |
| Material Design 3 | https://m3.material.io/ |
| Flutter (engine Flet) | https://docs.flutter.dev/ |

---

## 5. White papers i artykuły naukowe

| Tytuł | Autor/Źródło | Rok | Zastosowanie w NexusAI |
|---|---|---|---|
| **TigerBeetle: A Scalable Cloud Native Ledger Database** | Joran Dirk Greef, TigerBeetle Inc. | 2022 | Appendix: dwelling on `double-entry` invariants |
| **Time, Clocks, and the Ordering of Events in a Distributed System** | Leslie Lamport | 1978 | Event Sourcing — Ordering decyzji |
| **Property-Based Testing with SMT Solvers (crosshair)** | Joe Dodson | 2022 | Zastąpienie losowego fuzzingu analizą symboliczną |
| **Cryptographic Extraction and Key Derivation** | NIST SP 800-108 | 2009 | Argon2id KDF |
| **Argon2: Password Hashing** | Biryukov, Dinu, Khovratovich (PHC) | 2016 | Specyfikacja Argon2id |
| **PxIS Architecture for ML Inference on CPU** | Meta AI Research | 2024 | Referencje dla `llama.cpp` |

---

## 6. Konferencje i wystąpienia (referencje dla prezentacji)

| Konferencja | Temat | Rok | Materiały |
|---|---|---|---|
| **PyCon DE 2024** | "Drop the GIL: Free-threaded Python in production" | 2024 | youtube.com/@PyConDE |
| **EuroPython 2024** | "Building financial systems with msgspec + crosshair" | 2024 | europython.eu |
| **RustConf 2023** | "Cross-platform Rust + Python with PyO3" | 2023 | rustconf.com |
| **DevConf 2024** | "TigerBeetle as your double-entry engine" | 2024 | devconf.info |

---

## 7. Repozytoria i narzędzia (referencje)

| Repozytorium | Opis | Licencja |
|---|---|---|
| github.com/Gorski-Maciej/NexusAI | Główne repo projektu | Proprietary |
| github.com/litestar-org/litestar | Framework API | MIT |
| github.com/emmett-framework/granian | Serwer ASGI Rust | BSD-3 |
| github.com/tigerbeetle/tigerbeetle | Ledger engine | Apache 2.0 |
| github.com/jcristharif/msgspec | Serializacja | BSD-3 |
| github.com/nats-io/nats-server | Broker wiadomości | Apache 2.0 |
| github.com/ggerganov/llama.cpp | LLM inference | MIT |
| openpolicyagent.org | Silnik polityk | Apache 2.0 |

---

## 8. Zbiory danych (AI)

| Zbiór | Typ | Użycie |
|---|---|---|
| KSeF generowane wzory faktur | Synthetic | Trening + testy OCR |
| Polish invoices (anonymizowane) | Real | Walidacja modeli (po RODO processing) |
| GUS BIR publiczne dane | Real | Context enrichment |

> ⚠️ Wszystkie dane treningowe i testowe używane w NexusAI przechodzą procedurę anonimizacji zgodną z RODO Art. 5 i 32.

---

## 9. Narzędzia walidacji i audytu

| Narzędzie | URL |
|---|---|
| **ISAP** (Internetowy System Aktów Prawnych) | https://isap.sejm.gov.pl |
| **e-Justice EU** (orzecznictwo UE) | https://e-justice.europa.eu |
| **Komisja Europejska — dokumenty VAT** | https://ec.europa.eu/taxation_customs/business/vat |
| **KSeF API Sandbox** | https://ksef-test.mf.gov.pl |
| **Biała Lista — wyszukiwarka** | https://www.podatki.gov.pl/wykaz-podatnikow-vat-wyszukiwarka |

---

## 10. Konwencje dokumentowania

| Konwencja | URL |
|---|---|
| **Keep a Changelog** | https://keepachangelog.com/ |
| **Semantic Versioning** | https://semver.org/ |
| **Conventional Commits** | https://www.conventionalcommits.org/ |
| **Mermaid (diagramy w Markdown)** | https://mermaid.js.org/ |
| **Markdown Guide** | https://www.markdownguide.org/ |
| **C4 Model dla architektury** | https://c4model.com/ |
| **MADR (Markdown ADR)** | https://adr.github.io/madr/ |
| **Arc42 (szablon architektury)** | https://arc42.org/ |

---

## 🔗 Zobacz również

- [00_META](00_META.md) — strona tytułowa
- [Spis treści](INDEX.md) — nawigacja po dokumentacji
- [Compliance](COMPLIANCE.md) — szczegóły implementacji zgodności
- [Security](SECURITY.md) — środki bezpieczeństwa i OWASP

---

> **Data aktualizacji:** 2026-07-05 · **Autor:** NexusAI Team · **Wersja:** 3.0.0-dev
> **Status dokumentu:** Stabilny · **Ostatnia weryfikacja:** 2026-07-05 · **Weryfikator:** Technical Lead
