# 🤖 System Agentów AI NexusAI — Specyfikacja Enterprise (v4.0)

> **"Autonomiczne Biuro Księgowe — 5 Agentów, 13 Modeli, Zero Błędów"**
>
> **Cel:** Umożliwić developerowi zrozumienie pełnego systemu agentów AI w 15 minut.
> **Kiedy czytać:** Przed implementacją nowego agenta, debugowaniem decyzji, lub dodawaniem modelu AI.
> **Podstawa:** `docs/aa3fvcx.txt` + `RAPORT_TECHNOLOGII_NEXUSAI.txt`

---

## 1. Wizja systemu — Autonomiczne Biuro Księgowe

### 1.1 Filozofia architektury

System agentów AI został zaprojektowany jako **AUTONOMICZNE BIURO KSIĘGOWE** — zestaw **5 wyspecjalizowanych agentów**, które:

- **DZIAŁAJĄ W TLE** — użytkownik nie musi wiedzieć, który agent przetwarza fakturę
- **PODEJMUJĄ DECYZJE** — w zielonej strefie (Trust Score ≥ 0.92) agenci samodzielnie księgują
- **UCZĄ SIĘ** — każda korekta użytkownika jest natychmiast wykorzystywana do poprawy przyszłych decyzji (Cognitive Audit Trail)
- **KOORDYNUJĄ APLIKACJĘ** — sterują UI (Flet), kolejką zadań (Taskiq), NATS i bazami danych
- **SĄ ODPORNE** — każda decyzja przechodzi przez minimum 2 niezależne modele (architektura "zero trust to a single model")

### 1.2 JEDEN poziom automatyzacji

| Tryb | Zachowanie | Trust Score |
|---|---|---|
| **AUTO_POST** | Agent samodzielnie księguje, użytkownik informowany | ≥ 0.92 |
| **SUGGEST** | Agent proponuje decyzję z ostrzeżeniem, użytkownik zatwierdza | ≥ 0.75 |
| **ASK_USER** | Agent pyta użytkownika o decyzję | < 0.75 |

**Człowiek ZAWSZE jest decydentem.** Agent wykonuje pracę i przedstawia opcje.

### 1.3 GENIALNY POMYSŁ #1: Cognitive Audit Trail (warstwa deterministyczna)

Każda korekta użytkownika tworzy blok poznawczy w łańcuchu dowodowym:
- Embedding korekty → sqlite-vec (768d)
- Podobna faktura → k-NN → automatyczna korekta
- Po 10 korektach tego samego typu → auto-naprawa reguły OPA
- Łańcuch SHA-256 staje się AKTYWNYM systemem uczącym się, nie tylko pasywnym rejestrem

### 1.4 GENIALNY POMYSŁ #2: Dynamiczny Podręcznik Błędów (warstwa probabilistyczna)

Online few-shot learning — model Granite 3.2 uczy się z każdej korekty BEZ fine-tuningu:
- Każda korekta użytkownika → zapisana jako przykład few-shot w DuckDB (`error_handbook`)
- Przed inferencją → kwerenda DuckDB: najbardziej podobne przykłady (ten sam NIP, kategoria, kwota)
- Przykłady wstrzykiwane do promptu jako "Podręcznik Błędów z Przeszłości"
- Model widzi: ❌ co AI zdecydowało błędnie → ✅ co było poprawne
- Im więcej korekt, tym mądrzejszy model — incremental learning

```
KOREKTA UŻYTKOWNIKA → DuckDB error_handbook → kwerenda przed inferencją →
→ "Podręcznik Błędów" w prompcie → Granite 3.2 uczy się z przykładów
```

### 1.5 Architektura komunikacji

```
U[Użytkownik / Flet UI] -->|REST| API[Litestar API]
API -->|NATS JetStream| O[AgentOrchestrator]
O -->|NATS| E[AgentDataExtraction — OCR + KSeF]
O -->|NATS| A[AgentAnalytics — cashflow + vendor intel]
O -->|NATS| Q[AgentQualityValidator — tax + fraud + ESG]
O -->|NATS| FA[AgentFixedAssets — amortyzacja]
E -->|DuckDB + SQLite| DB[(Bazy danych)]
Q -->|OPA/Rego| OPA[Silnik reguł]
O -->|TigerBeetle| TB[Księga główna]
```

### 1.6 Stos technologiczny agentów

| Technologia | Rola |
|---|---|
| **llama-cpp-python** | Inferencja modeli GGUF (CPU/GPU) |
| **NATS JetStream + Taskiq** | Komunikacja między agentami |
| **DuckDB** | Pamięć episodyczna i analityka |
| **SQLite + sqlite-vec** | Pamięć semantyczna (wektory) + Cognitive Audit Trail |
| **TigerBeetle** | Księga główna (double-entry) |
| **msgspec** | Wszystkie struktury danych |
| **stamina** | Circuit breaker i retry |
| **nexus-crypto** | Proof chain kryptograficzny (SHA-256) |
| **OPA + Rego** | Deterministyczny silnik reguł (auto-naprawiany) |

---

## 2. Pięciu agentów AI — katalog

### 2.1 AgentOrchestrator — Centralny Mózg i Wirtualny CFO

**Rola:** Naczelny dyrektor finansowy. Koordynuje 4 agentów, podejmuje ostateczne decyzje, komunikuje się z użytkownikiem.

| Parametr | Wartość |
|---|---|
| **Model główny** | Granite 3.2 3B (GGUF, IQ4_XS) |
| **Model strażnika** | Granite Guardian 0.5B (GGUF, Q4_K_M) |
| **Model komunikatora** | Qwen3-Nano 0.5B (GGUF, Q4_K_M) |
| **RAM stały** | ~2.98 GB |
| **Plik** | `nexus_ai/agents/orchestrator.py` |

**Kluczowe mechanizmy:**
- **Dynamiczny Trust Score** — aktualizowany Bayesiańsko po każdej decyzji
- **Decision Cache** — każda decyzja wektoryzowana w sqlite-vec, k-NN (k=5)
- **Cognitive Audit Trail** — korekty → embeddingi → auto-naprawa reguł OPA
- **Adaptive Thresholds** — progi AUTO_POST/SUGGEST dynamiczne per kontrahent
- **Proof Chain SHA-256** — niepodważalny dowód dla organów skarbowych
- **4-Eyes Principle** — obowiązkowy dla kwot > 50k PLN

**Proces decyzyjny (7 kroków):**
1. Decision Cache: k-NN w podobnych decyzjach
2. AgentDataExtraction → ekstrakcja (4 silniki OCR)
3. Actor (Granite 3.2) + Guardian (Granite Guardian) → ocena
4. AgentQualityValidator → walidacja (tax + fraud + ESG + forecast)
5. Weighted Voting → konsensus
6. Cognitive Audit Trail → sprawdź podobne korekty
7. Ostateczna decyzja: AUTO_POST / SUGGEST / ASK_USER

### 2.2 AgentDataExtraction — Forteca Precyzji

**Rola:** Ekstrakcja danych z dokumentów + obsługa KSeF. Precyzja przewyższająca profesjonalnego księgowego.

| Parametr | Wartość |
|---|---|
| **Silniki OCR** | Tesseract 5.3 + PaddleOCR + Surya OCR |
| **Model walidacji** | Granite Vision Guardian 0.3B + ModernBERT-NER-Finance 0.3B |
| **Klasyfikacja** | ParagonDetect 0.1B (CNN, ONNX) |
| **RAM stały** | ~100 MB |
| **RAM doraźny** | ~500 MB (OCR) |
| **Plik** | `nexus_ai/agents/extraction.py` |

**Kluczowe mechanizmy:**
- **Cross-Validation Matrix (4×4)** — każde pole z 4 silników niezależnie
- **OCR Online Learning** — korekty → embeddingi → k-NN
- **Invoice Template Matching** — wzorce per kontrahent
- **KSeF Integration** — automatyczna wysyłka/odbiór FA(1)/FA(2)
- **Semantyczna walidacja** — NIP, IBAN, kwoty, daty

### 2.3 AgentAnalytics — Sztab Analityczny

**Rola:** Analiza kondycji finansowej, prognozy cash flow, wywiad gospodarczy.

| Parametr | Wartość |
|---|---|
| **Model SQL** | Hrida-T2SQL-128k (GGUF, IQ3_M) |
| **Model analityczny** | Granite 3.2 3B (GGUF, IQ4_XS) |
| **Model detekcji** | Fin-RWKV-169M (GGUF, Q4_K_M) |
| **Model prognozy** | Lag-Llama 0.3B (GGUF, Q4_K_M) |
| **RAM stały** | ~100 MB |
| **RAM doraźny** | ~1.0 GB (T2SQL) |
| **Plik** | `nexus_ai/agents/analytics.py` |

**Kluczowe mechanizmy:**
- **Cash Flow Forecast (90 dni)** — 3 scenariusze
- **Vendor Intelligence** — Biała Lista MF, GUS BIR, risk score 0-100
- **Anomaly Detection** — Z-score, IQR, Mahalanobis, Isolation Forest
- **Daily Brief** — codzienne podsumowanie NL
- **Automatyczne raporty** — dzienne/tygodniowe/miesięczne

### 2.4 AgentQualityValidator — Trójwarstwowa Tarcza

**Rola:** Niezależny audytor. Weryfikuje KAŻDĄ decyzję przed wykonaniem.

| Parametr | Wartość |
|---|---|
| **Model podatkowy** | Granite Guardian 0.5B (GGUF, Q4_K_M) |
| **Model fraud** | GraphSAGE-Encoder 0.1B (ONNX) |
| **Model ryzyka** | FinBERT-ESG 0.1B (GGUF, Q4_K_M) |
| **Model płynności** | Lag-Llama 0.3B (GGUF, Q4_K_M) |
| **RAM stały** | ~670 MB |
| **RAM doraźny** | ~350 MB (Lag-Llama) |
| **Plik** | `nexus_ai/agents/quality_validator.py` |

**Kluczowe mechanizmy:**
- **Tax Compliance** — VAT, PIT, CIT, split payment (OPA/Rego — auto-naprawiany)
- **Fraud Graph Scanner** — grafy powiązań (GraphSAGE): karuzele VAT, słupy
- **ESG Risk Analysis** — ocena ryzyka kontrahenta
- **Liquidity Stress Test** — Monte Carlo 1000 scenariuszy
- **4-Eyes Principle** — obowiązkowy dla kwot > 50k PLN
- **Weighted Voting** — Tax: 0.35, Fraud: 0.30, ESG: 0.20, Forecast: 0.15

### 2.5 AgentFixedAssets — Zarządca Majątku

**Rola:** Automatyczna klasyfikacja, amortyzacja i ewidencja środków trwałych.

| Parametr | Wartość |
|---|---|
| **Model** | Amortyzator-KŚT 0.2B (deterministyczny + AI) |
| **RAM doraźny** | ~200 MB |
| **Plik** | `nexus_ai/services/fixed_assets.py` |

**Kluczowe mechanizmy:**
- **Auto-Classification** — ŚT vs materiał vs usługa (>10k PLN, >1 rok)
- **Depreciation Engine** — liniowa, degresywna, jednorazowa
- **TigerBeetle** — miesięczne odpisy w księdze głównej

---

## 3. Decision Engine — Silnik Decyzyjny

### 3.1 Dynamiczne progi decyzyjne

```
auto_post_threshold = 0.92 - adjustment
adjustment = (α_vendor - β_vendor) / (α_vendor + β_vendor) × 0.1
```

| Kontrahent | auto_post_threshold |
|---|---|
| Znany (100 faktur) | 0.824 |
| Nowy (5 faktur) | 0.86 |
| Podejrzany (10 faktur) | 0.90 |

### 3.2 Konsensus między agentami

| Agent | Waga |
|---|---|
| AgentOrchestrator | 0.40 |
| AgentQualityValidator | 0.60 (niezależny audytor) |

### 3.3 Cognitive Audit Trail

```
DECYZJA → KOREKTA → EMBEDDING (sqlite-vec) → k-NN → AUTO-NAPRAWA OPA
```

Po 10 korektach tego samego typu → automatyczna aktualizacja reguł OPA/Rego.

---

## 4. Modele AI — tabela (13 modeli, 5 agentów)

| Agent | Modele | RAM stały | RAM doraźny |
|---|---|---|---|
| **Orkiestrator** | Granite 3.2 3B, Guardian 0.5B, Qwen3-Nano 0.5B | ~2.98 GB | — |
| **Ekstrakcji** | ParagonDetect 0.1B, Vision Guardian 0.3B, ModernBERT 0.3B | ~100 MB | ~500 MB |
| **Analityczny** | Fin-RWKV-169M | ~100 MB | ~1.0 GB |
| **Walidator** | Guardian 0.5B, GraphSAGE 0.1B, FinBERT-ESG 0.1B | ~670 MB | ~350 MB |
| **Środki Trwałe** | Amortyzator-KŚT 0.2B | — | ~200 MB |

**Łącznie:** ~3.85 GB stałego RAM, peak ~5.9 GB (w budżecie 6 GB).

---

## 🔗 Zobacz również

- [Architektura systemu](ARCHITECTURE.md) — C4, ADR, wzorce projektowe
- [Moduły i logika](MODULES.md) — serwisy biznesowe, pipeline OCR
- [Bezpieczeństwo](SECURITY.md) — model zagrożeń, szyfrowanie, RBAC
- [aa3fvcx.txt](aa3fvcx.txt) — blueprint architektury agentów (źródło)

---

> **Data aktualizacji:** 2026-07-05 · **Wersja:** 4.0.0 — "Cognitive Audit Trail"
> **Podstawa:** `docs/aa3fvcx.txt` + `RAPORT_TECHNOLOGII_NEXUSAI.txt`
