# 📖 Słownik pojęć (Glossary)

> **Cel:** Wyjaśnić wszystkie terminy księgowe i techniczne używane w NexusAI.

---

## A. Terminy księgowe

### A
- **Active Learning** — Metoda uczenia maszynowego, gdzie model aktywnie wybiera przypadki do nauki na podstawie korekt użytkownika. W NexusAI: każda korekta decyzji → Bayesian update Trust Score.
- **Adaptive Thresholds** — Dynamiczne progi decyzyjne (AUTO_POST/REVIEW/BLOCK), które dostosowują się Bayesiańsko per kontrahent: `threshold = base - (α-β)/(α+β) × 0.1`.
- **AEAD** — Authenticated Encryption with Associated Data. Szyfrowanie, które jednocześnie szyfruje i uwierzytelnia dane (ChaCha20-Poly1305).
- **Agent AI** — Wyspecjalizowany model AI (GGUF) odpowiedzialny za konkretną domenę (np. ekstrakcja danych, analityka, walidacja). NexusAI ma 10 agentów.
- **AgentOrchestrator** — Centralny agent koordynujący pracę wszystkich pozostałych agentów. Odpowiednik wirtualnego CFO.
- **Amortyzacja** — Stopniowe odpisywanie wartości środka trwałego w koszty. Metody: liniowa (równe odpisy), degresywna (malejące).
- **Argon2id** — Algorytm KDF (Key Derivation Function), zwycięzca Password Hashing Competition. Odporny na ataki GPU i side-channel.
- **ASK_USER** — Decyzja wymagająca użytkownika. System wyświetla 2-5 opcji do wyboru.
- **AUTO_POST** — Automatyczne księgowanie. System samodzielnie podejmuje decyzję i księguje fakturę.

### B
- **Bayesian Trust Score** — Dynamiczny wskaźnik zaufania aktualizowany po każdej decyzji: posterior Beta(α+poprawne, β+błędne). Używany przez AgentOrchestrator.
- **Biała Lista MF** — Rejestr podatników VAT czynnych, prowadzony przez Ministerstwo Finansów. Weryfikacja przez AgentVendorIntelligence.

### C
- **CIT** — Podatek dochodowy od osób prawnych. Stawka 19% (lub 9% dla małego podatnika).
- **CIT estoński** — Forma opodatkowania CIT — podatek płacony tylko od wypłaconych zysków.
- **Confidence Calibration** — Mechanizm kalibracji pewności modelu: porównanie deklarowanej pewności z rzeczywistą precyzją. Przechowywane w DuckDB (`model_calibration`).
- **Continuous Learning** — Zamknięta pętla uczenia: Decyzja → Korekta użytkownika → Bayesian update → Poprawa threshold. Aktywne uczenie (Active Learning).
- **CQRS** — Command Query Responsibility Segregation. Wzorzec architektoniczny: osobno zapis (command), osobno odczyt (query).
- **Cztery oczy (4-Eyes Principle)** — Zasada wymagająca weryfikacji krytycznych decyzji (>50k PLN) przez 2 niezależne modele AI. Obowiązkowa w NexusAI. Patrz: [`AGENTS.md#24-agentqualityvalidator`](AGENTS.md#24-agentqualityvalidator--strażnik-integralności).

### D
- **DDD** — Domain-Driven Design. Metodyka projektowania: najpierw model biznesowy (domena), potem kod.
- **Decision Engine** — Wielowarstwowy silnik decyzyjny: strefy decyzyjne (dynamiczne progi) → konsensus między agentami → eskalacja do człowieka → audit trail (Proof Chain).
- **Dekretacja** — Przypisanie operacji księgowej do konkretnych kont księgowych (np. Wn 401 "Koszty", Ma 201 "Rozrachunki").
- **DLQ (Dead Letter Queue)** — Kolejka na wiadomości, których nie udało się przetworzyć po 3 próbach. W NATS JetStream.
- **Double-entry (podwójny zapis)** — Fundamentalna zasada księgowości: każda operacja ma dwie strony — Winien (Wn/Debet) i Ma (Ma/Credit). Suma debetów = suma kredytów.

### E
- **Event Sourcing** — Wzorzec: zamiast mutować stan, zapisujemy niezmienne zdarzenia (np. "FakturaZaksięgowana").

### F
- **FIFO** — First In, First Out. Metoda wyceny zapasów: najpierw sprzedajemy najstarsze towary.

### G
- **GAAP** — Generally Accepted Accounting Principles (USA). Amerykańskie standardy rachunkowości.
- **GTU** — Grupa Towarowo-Usługowa. Kod w fakturze KSeF określający rodzaj towaru/usługi.
- **GUS BIR** — Główny Urząd Statystyczny — Baza Internetowa Rejestrów. Rejestr CEIDG.

### I
- **IBAN** — International Bank Account Number. Międzynarodowy numer rachunku bankowego (PL + 26 cyfr).
- **IFRS** — International Financial Reporting Standards (MSSF — Międzynarodowe Standardy Sprawozdawczości Finansowej).

### J
- **JDG** — Jednoosobowa Działalność Gospodarcza.
- **JPK** — Jednolity Plik Kontrolny. Cyfrowe deklaracje podatkowe w formacie XML.
- **JPK_V7** — JPK dla VAT (miesięczny V7M, kwartalny V7K).

### K
- **KSeF** — Krajowy System e-Faktur. Platforma Ministerstwa Finansów do wystawiania i odbierania faktur ustrukturyzowanych.
- **KUP** — Koszty Uzyskania Przychodów. Wydatki, które można odliczyć od przychodu.

### M
- **Memory Systems** — Cztery typy pamięci w systemie agentów: Episodic (DuckDB), Semantic (sqlite-vec), Procedural (OPA/Rego), Working (NATS KV Store).
- **MPP** — Mechanizm Podzielonej Płatności (Split Payment). Płatność za fakturę w dwóch strumieniach: netto i VAT.
- **MSSF** — Międzynarodowe Standardy Sprawozdawczości Finansowej (IFRS).

### N
- **NBP** — Narodowy Bank Polski. API do pobierania kursów walut.
- **NIP** — Numer Identyfikacji Podatkowej (10 cyfr, suma kontrolna).

### O
- **OPA** — Open Policy Agent. Silnik reguł używający języka Rego do definiowania polityk.
- **Ordynacja podatkowa** — Ustawa regulująca zasady naliczania i płatności podatków w Polsce.

### P
- **PESEL** — Powszechny Elektroniczny System Ewidencji Ludności (11 cyfr).
- **PIT** — Podatek dochodowy od osób fizycznych. Skala: 12% do 120 000 PLN, 32% powyżej; lub liniowy 19%; lub ryczałt.
- **PKWiU** — Polska Klasyfikacja Wyrobów i Usług. Kod określający rodzaj towaru/usługi.
- **Plan kont** — Zakładowy Plan Kont (ZPK). Struktura kont księgowych firmy.
- **Proof Chain** — Łańcuch skrótów SHA-256 gwarantujący niezmienność decyzji. Każdy wpis zawiera hash poprzedniego — modyfikacja psuje cały łańcuch. Używany jako dowód dla organów skarbowych.

### R
- **Rego** — Język polityk OPA. Deklaratywny, używany do definiowania reguł podatkowych.
- **RODO** — Rozporządzenie o Ochronie Danych Osobowych (GDPR).
- **Ryczałt** — Uproszczona forma opodatkowania: podatek od przychodu (stawki 2-17%).

### S
- **Split Payment** — Zobacz MPP.
- **Storno** — Korekta księgowa. Czerwone (odwrócenie zapisu) lub czarne (zapis korygujący).
- **SWIFT/BIC** — Kod identyfikacyjny banku (8 lub 11 znaków).

### T
- **TigerBeetle** — Silnik double-entry accounting. Matematycznie gwarantuje, że każda transakcja bilansuje się do zera.
- **Trust Score** — Wskaźnik zaufania (0.0-1.0) dla decyzji agenta. 4 komponenty: ai_confidence, vendor_reliability, data_consistency, context_trust. Aktualizowany Bayesiańsko po każdej korekcie.

### U
- **UoR** — Ustawa o rachunkowości (Dz.U. 1994 nr 121 poz. 591 z późn. zm.).

### V
- **VAT** — Podatek od towarów i usług. Stawki: 23%, 8%, 5%, 0%, zwolniony.
- **VAT naliczony** — VAT od zakupów (do odliczenia).
- **VAT należny** — VAT od sprzedaży (do zapłaty).
- **VAT-7** — Deklaracja VAT (miesięczna).

### Z
- **ZPK** — Zakładowy Plan Kont. Zobacz "Plan kont".

---

## B. Terminy techniczne

### A
- **ADR** — Architecture Decision Record. Dokument opisujący kluczową decyzję architektoniczną.
- **Aggregate (Agregat)** — Wzorzec DDD: klaster obiektów traktowanych jako całość. Np. InvoiceAggregate.
- **anyio** — Biblioteka Pythona dostarczająca jednolite API dla asyncio i trio.
- **ASGI** — Asynchronous Server Gateway Interface. Standard serwera webowego dla async Pythona.

### C
- **Circuit Breaker** — Wzorzec: po serii błędów, system przestaje wywoływać daną funkcję na określony czas.
- **crosshair** — Narzędzie do property-based testing z SMT solverem (Z3). Matematyczne dowody poprawności.
- **CSRF** — Cross-Site Request Forgery. Atak polegający na wykonaniu nieautoryzowanych akcji.

### D
- **Dead Letter Queue (DLQ)** — Kolejka na wiadomości, których nie udało się przetworzyć po N próbach.
- **DuckDB** — Wbudowana baza analityczna OLAP. Idealna do agregacji i symulacji.

### F
- **Flet** — Framework GUI w Pythonie. Używa silnika Flutter do renderowania natywnych interfejsów.
- **Free-threaded Python (3.13t)** — Wariant Pythona bez GIL, umożliwiający prawdziwą wielowątkowość.

### G
- **GGUF** — Format kwantyzowanych modeli LLM. Q4_K_M (4-bit), Q2_K (2-bit) — mniejsze, ale wciąż dokładne.
- **GIL** — Global Interpreter Lock. Blokada w standardowym Pythonie uniemożliwiająca równoległe wątki.
- **Granian** — Serwer ASGI napisany w Rust. 25-40% mniej RAM niż Uvicorn.

### H
- **hishel** — Inteligentny cache HTTP. Automatycznie respektuje nagłówki Cache-Control, ETag.
- **Hatchling** — Backend budowania pakietów Python (PEP 621).

### J
- **JetStream** — Warstwa strumieniowania w NATS. Gwarantuje at-least-once delivery, DLQ, retry.
- **JWT** — JSON Web Token. Standard tokenów uwierzytelniających. TTL: 15 minut.

### K
- **KV Store** — Key-Value Store. Wbudowany w NATS JetStream — zastępuje Redis.

### L
- **Litestar** — Framework API ASGI. 10-20% szybszy od FastAPI, natywne msgspec.
- **llama-cpp-python** — Biblioteka do inferencji LLM (modele GGUF) na CPU/GPU.

### M
- **maturin** — Narzędzie do budowania rozszerzeń Rust dla Pythona (PyO3).
- **mimalloc** — Alokator pamięci Microsoft. 5-15% mniej RAM, wkompilowany statycznie.
- **msgspec** — Ultraszybka biblioteka do serializacji JSON/MessagePack/TOML. 2-3× szybsza od Pydantic.
- **mypyc** — Kompilator typowanego Pythona do C. 2-5× przyspieszenie.

### N
- **NATS** — Lekki broker wiadomości (plik ~10 MB). Zastępuje RabbitMQ/Kafka.
- **Nuitka** — Kompilator Python → C → standalone .exe. Z wkompilowanym mimalloc.

### O
- **OpenTelemetry (OTel)** — Standard CNCF dla traces, metrics, logs.
- **Outbox Pattern** — Wzorzec: najpierw zapisz zdarzenie do bazy, potem opublikuj. Gwarantuje niezawodność.

### P
- **Pixi** — Menadżer środowiska w Rust. Jeden plik definiuje Python + PyPI + system deps.
- **Polars** — DataFrame w Rust dla Pythona. 5-10× szybszy od pandas.
- **Proof Chain** — Łańcuch skrótów SHA-256. Każdy wpis zawiera hash poprzedniego — modyfikacja psuje cały łańcuch.
- **PyO3** — Biblioteka do tworzenia rozszerzeń Rust dla Pythona.
- **PyArrow** — Kolumnowy format danych w pamięci. Most między DuckDB i Polars.

### R
- **RBAC** — Role-Based Access Control. System uprawnień oparty na rolach.
- **Ruff** — Linter i formatter w Rust. 10-100× szybszy od flake8/black.

### S
- **Saga** — Wzorzec koordynacji długotrwałych transakcji (np. "wyślij fakturę → czekaj na potwierdzenie → księguj").
- **SBOM** — Software Bill of Materials. Lista wszystkich składników oprogramowania.
- **schemathesis** — Narzędzie do fuzz testowania API na podstawie schematu OpenAPI.
- **SQLCipher** — Rozszerzenie SQLite dodające szyfrowanie AES-256 każdej strony bazy.
- **sqlite-vec** — Rozszerzenie SQLite dodające typ wektorowy i funkcje odległości (cosinusowa, euklidesowa).
- **SQLModel** — ORM łączący SQLAlchemy i Pydantic. Jedna definicja dla bazy i API.
- **stamina** — Biblioteka do retry i circuit breaker. Async-native.
- **structlog** — Biblioteka do strukturalnego logowania. Każdy log to słownik, nie tekst.

### T
- **Taskiq** — Framework kolejek zadań. Async-native, cron-like scheduler, retry.
- **TOML** — Tom's Obvious Minimal Language. Format konfiguracji (zastępuje YAML/JSON).

### U
- **Unit of Work** — Wzorzec: atomowa transakcja na wielu repozytoriach.
- **UNIX socket** — Mechanizm IPC (komunikacji międzyprocesowej). Szybszy i bezpieczniejszy niż TCP.

### V
- **Value Object (VO)** — Wzorzec DDD: niezmienny obiekt z walidacją (np. Money, NIP, IBAN).

---

## 🔗 Zobacz również

- [Architektura](ARCHITECTURE.md) — szczegółowe wyjaśnienie wzorców i ADR
- [Agenci AI](AGENTS.md) — pełna specyfikacja 10 agentów, Decision Engine, Trust Score
- [Moduły i logika](MODULES.md) — techniczna implementacja agentów i OCR
- [Zgodność z przepisami](COMPLIANCE.md) — kontekst prawny terminów księgowych

---

> **Data aktualizacji:** 2026-07-05 · **Autor:** NexusAI Team · **Wersja:** 3.0.0-dev
> **Status dokumentu:** Stabilny · **Ostatnia weryfikacja:** 2026-07-05 · **Weryfikator:** NexusAI Team
