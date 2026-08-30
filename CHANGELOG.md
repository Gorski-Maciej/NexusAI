# CHANGELOG — NexusAI v8.0 (JDG OPA Enterprise + GLM 5.2)

## [v8.0.1 Dokumentacja zsynchronizowana] — 2026-08-30

### 📚 Synchronizacja dokumentacji ze stanem faktycznym reguł

- Ponowna regeneracja `JDG/MANIFEST.md` — aktualny stan: **490 plików Rego / 11 855 unikalnych `rule_id` / 444 plików z `matched:true` / 0 duplikatów / Completeness Score 91/100**.
- Zaktualizowano nieaktualne metryki (472 → 490 plików, 11 808 → 11 855 rule_id, 88/100 → 91/100) w `README.md`, `CHANGELOG.md`, `JDG/README.md`, `JDG/COVERAGE_REPORT.md`, `docs/INDEX.md`, `docs/CHANGELOG.md`, `policies/jdg/README.md` oraz dokumentacji `JDG/docs/`.

## [v8.0 JDG OPA Enterprise] — 2026-08-22

### 🎯 Kampania GLM 5.2 — ETAP 06–28 (29/29 raportów WDROZONY_100)

Silnik reguł podatkowych JDG osiągnął **certyfikację końcową ETAP 28/29**
(2026-08-22): 14/14 bramek PASSED, **18 domen — 13 CERTIFIED / 5 CONDITIONAL /
0 BLOCKED**, 29/29 raportów kampanii zakończonych statusem WDROZONY_100.

#### 📦 Artefakty (stan na 2026-08-22)

- **472 pliki Rego** (`JDG/rules/`), **11 808 unikalnych `rule_id`** (426 plików z `matched:true`, 11 811 bloków, 3 duplikaty) — Completeness Score 88/100 *(stan 2026-08-22; po 2026-08-30: 490 plików / 11 855 rule_id / 91/100 — patrz MANIFEST.md)*
- **298 narzędzi Python** (`JDG/tools/`), **198 testów pytest + 207 testów natywnych Rego**
- **13 migracji** DuckDB RuleStore (001–013), **22 audit-state** (`JDG/bundles/*audit_state.json`)
- **policies/ mirror zsynchronizowany** (ETAP 26: hash-parity 0% drift) + overlays v2026/v2027

#### 🏗️ ETAPY 06–09 (silnik rdzeniowy)

- **ETAP 06 Core Guards Temporal Thresholds** — 42 niezmienniki (INV-001..042), algebra interwałów temporalnych (zero luk/nakładek), propagacja pewności (CERTAIN/CONDITIONAL/NEEDS_ADVICE), twardy audyt hardcoded (ADR-002)
- **ETAP 07 VAT Macro** — stawki/zwolnienia (art. 41–43/113), MPP (art. 108a–108f), odliczenia (art. 86–95), fraud (FD-01..06), pokrycie artykułowe COMPLETE
- **ETAP 08 VAT Micro Core** — 1423 reguły, 29 artykułów, dual-layer binding (micro↔macro), detekcja stubów
- **ETAP 09 VAT Micro Special** — KSeF, marża, POS, proporcja, WDT/WNT

#### 🏗️ ETAPY 10–28 (kampania GLM 5.2 — pełna lista)

| ETAP | Domeny | Status |
|------|--------|--------|
| 10 | PIT Macro (innowacje) | ✅ WDROZONY_100 |
| 11 | PIT Micro Reliefs | ✅ WDROZONY_100 |
| 12 | ZUS Core | ✅ WDROZONY_100 |
| 13 | ZUS Micro | ✅ WDROZONY_100 |
| 14 | PKPiR | ✅ WDROZONY_100 |
| 15 | UoR / Amortyzacja | ✅ WDROZONY_100 |
| 16 | KKS + Ordynacja | ✅ WDROZONY_100 |
| 17 | Cross-border / TP / MDR | ✅ WDROZONY_100 |
| 18 | Cykl życia JDG | ✅ WDROZONY_100 |
| 19 | PCC / podatki lokalne / akcyza | ✅ WDROZONY_100 |
| 20 | KSeF / JPK / e-Deklaracje | ✅ WDROZONY_100 |
| 21 | RODO / AML-CBDD / BDO / HR | ✅ WDROZONY_100 |
| 22 | Hyper Enterprise Contexts (Plan45) | ✅ WDROZONY_100 |
| 23 | Enterprise AI / Neural Mesh | ✅ WDROZONY_100 |
| 24 | Testy + CI/CD jakość | ✅ WDROZONY_100 |
| 25 | Narzędzia / API / RuleStore / Bundle | ✅ WDROZONY_100 |
| 26 | policies mirror sync | ✅ WDROZONY_100 |
| 27 | Cross-domain red team / chaos | ✅ WDROZONY_100 |
| 28 | **Certyfikacja końcowa** | ✅ WDROZONY_100 |

#### 🔐 Architektura i kontrolki (v8.2–v8.3)

- **Legal Twin / Legal Knowledge Graph** (ADR-016) — podstawa prawna jako referencja do węzła LKG (`_legal_basis_refs`), LCI ≥ 99%
- **Warstwa konstytucyjna runtime invariants** (ADR-017/022) — INV-001..042 egzekwowane na każdym werdykcie (`evaluate`/`enforce`)
- **Golden Oracle + ewaluacja różnicowa** (ADR-018) — golden_verdicts, UVR=0, decision_hash
- **Decision Certificate F4** (ADR-019) — klasy pewności, pieczęć SHA-256→Merkle→HSM, eksport PDF/XML dla KAS
- **Law Radar + Declarative Change** (ADR-020/021) — proaktywna adaptacja legislacyjna (lead ≥ 30 dni)
- **Control Plane Rule Lifecycle** (ETAP 04) — fail-closed koordynacja zmian reguł (PENDING_REVIEW → ACTIVE → ROLLBACK)
- **Orchestrator Data Contract** (ETAP 05) — 25-polowy werdykt, PASS 0–8, safe_merge, provenance tree
- **Multi-Pass PASS 0–8 + Sharded Router O(1)** — p95 < 5 ms na shard, early abort, POST-MERGE invariants

#### 🔧 Poprawki i porządki

- Deduplikacja rule_id: 369 → **3** duplikaty; stub detector 487 → 25 (2026-08-12)
- MANIFEST.md zaktualizowany (2026-08-22): 472 pliki / 11 808 rule_id / 88/100 — **ponownie zregenerowany 2026-08-30: 490 pliki / 11 855 rule_id / 91/100**
- Dokumenty INWENTARYZACJA_PLIKOW.md / KATALOG_REGUL.md / KATALOG_NARZEDZI.md zsynchronizowane ze stanem faktycznym

---

## [v7.0 Enterprise Audit] — 2026-07-25

### 🎯 Raport źródłowy
RAPORT_ANALITYCZNY_ENTERPRISE_SQLITE_MIGRACJE_VECTOR_v7.0.txt

---

## ✅ Faza 1 — Szybkie poprawki (6 zmian)

### Bezpieczeństwo i integralność
- **STRICT na `audit_logs`** — Tabela audytu dostała STRICT mode, eliminując silent type coercion. Dodano również `fraud_entity_registry`, `category_codes`, `payment_methods` do `_STRICT_TABLES`.
- **AES-256-GCM support** — `database.py` próbuje najpierw GCM (szybsze, AES-NI), z fallbackiem do CBC dla starszych wersji SQLCipher.
- **Indeksy `tenant_id`** — Dodano indeksy na `tenant_id` dla `AuditLog`, `OutboxEvent`, `SecurityAlert` dla szybszego filtrowania multi-tenant.

### Wydajność
- **Auto-ANALYZE po migracjach** — `run_migrations.py` wykonuje `PRAGMA analysis_limit=1000; ANALYZE;` po każdej migracji i po wszystkich.
- **dim=768 dla invoice_vectors** — Vector store używa teraz 768-dim embeddingów (zamiast 384), dla lepszej jakości RAG z LLM.

### Migracje
- **Checksum SHA-256** — Każda migracja ma teraz checksum SHA-256 zapisywane w `_migrations_version`.
- **Nowa migracja 007** — CHECK constraints (przez triggery), tabele słownikowe (`category_codes`, `payment_methods`), covering index, `db_query_metrics`.

---

## ✅ Faza 2 — Nowe moduły (3 pliki)

### `nexus_ai/db/firewall.py` (INNOWACJA #5)
- Database Firewall z detekcją SQL injection (15 patternów)
- Rate limiting per query type (SELECT/INSERT/UPDATE/DELETE/DDL)
- Prepared statements enforcement
- Query profiling z auto-block dla wolnych zapytań
- Globalna instancja: `get_firewall()`

### `nexus_ai/db/wal_archiver.py` (INNOWACJA #6)
- Ciągłe archiwizowanie WAL co 60s (konfigurowalne)
- Point-in-Time Recovery z granularnością do transakcji
- Manifest-based tracking archiwów
- Pruning starych segmentów
- WAL size monitoring z alertami

### `nexus_ai/db/index_advisor.py` (INNOWACJA #9)
- Analiza EXPLAIN QUERY PLAN dla rekomendacji indeksów
- Detekcja nieużywanych indeksów przez `sqlite_stat`
- Rekomendacje composite, partial, covering indexów
- Auto-approve dla wysokiego estimated improvement (>50%)

---

## ✅ Faza 3 — Transformacje strategiczne (4 pliki)

### `nexus_ai/services/db_observability.py` (INNOWACJA #10)
- Histogramy latency z p50/p95/p99
- Connection pool metrics (utilization, checkouts, blocked)
- WAL size monitoring z alertami
- Slow query log (>100ms default)
- Auto-EXPLAIN ANALYZE dla wolnych zapytań

### `nexus_ai/db/tenant_mesh.py` (INNOWACJA #1)
- TenantSaltKMS — per-tenant key derivation (HKDF/PBKDF2)
- Per-tenant SQLCipher z osobnymi kluczami AES-256
- mlock protection dla master key
- GDPR right to erasure (`delete_tenant_db`)
- Key rotation (`rotate_tenant_key`)

### `nexus_ai/db/blue_green_migration.py` (INNOWACJA #3)
- Zero-downtime schema migration (6 faz)
- Dual-write triggery INSERT/UPDATE/DELETE
- Backfill istniejących danych
- Atomic switchover (ALTER TABLE RENAME)
- Rollback capability

### `nexus_ai/db/query_utils.py`
- Współdzielona funkcja `classify_query()` — wyeliminowana duplikacja między `firewall.py` i `db_observability.py`

### `nexus_ai/api/routes/db_observability.py`
- API endpointy:
  - `GET /api/v2/db/observability` — pełny dashboard
  - `GET /api/v2/db/firewall/stats` — statystyki firewalla
  - `GET /api/v2/db/index-advisor` — rekomendacje indeksów
  - `GET /api/v2/db/wal-archive/stats` — status WAL archivera
  - `GET /api/v2/db/tenant-mesh/stats` — statystyki tenant mesh

---

## 🔧 Poprawki błędów

- **006_fraud_temporal.sql** — Usunięto zbędne ALTER TABLE ADD COLUMN (kolumny już w CREATE TABLE)
- **007_v7_audit_enhancements.sql** — RAISE(ABORT) używa teraz string literałów (nie || konkatenacji)
- **007_v7_audit_enhancements.sql** — INCLUDE zastąpione zwykłym composite indexem (kompatybilność z SQLite <3.45)
- **models.py** — Usunięto podwójne indeksy na `tenant_id` (index=True + explicit Index)
- **firewall.py** — Wyeliminowana duplikacja `_classify_query` przez shared `query_utils.py`
- **tenant_mesh.py** — Usunięty dead code w `_create_tenant_db`
- **db_observability.py** — Usunięty nieużywany `import anyio`

## 📊 Statystyki

- **15 zmian** (6 w istniejących + 7 nowych plików + 2 migracje)
- **~3000 linii** nowego kodu produkcyjnego
- **11/11 testów** migracji przechodzi ✅
- **12/12 plików** przechodzi walidację składni ✅
- **6 z 10 INNOWACJI** z raportu wdrożonych w całości
