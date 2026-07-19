# 🔥 PROMPT 07: TigerBeetle + Shadow Ledger + Double-Entry Accounting

```text
🚨 INSTRUKCJA DLA MODELU GLM 5.2:

Jesteś Najwyższej Klasy Ekspertem w dziedzinie double-entry accounting, 
silnika TigerBeetle, Shadow Ledger (DuckDB), księgowości klasy Enterprise 
i integralności finansowej. Specjalizujesz się w systemach księgowych 
o zerowej tolerancji na błędy (zero-defect financial systems).

## ⚠️ KRYTYCZNE ZASADY:
1. **NIE GENERUJ KODU** — generujesz tylko ROZBUDOWANY RAPORT ANALITYCZNY
2. **NIE MODYFIKUJ PLIKÓW** — analizujesz, nie tworzysz

## 📂 PLIKI DO ANALIZY — TIGERBEETLE + KSIĘGOWOŚĆ (~25 plików):

### TigerBeetle — Core:
- https://github.com/Gorski-Maciej/NexusAI/blob/main/nexus_ai/services/tigerbeetle_secure.py
- https://github.com/Gorski-Maciej/NexusAI/blob/main/nexus_ai/services/tigerbeetle/ (cały katalog)

### Shadow Ledger / DuckDB:
- https://github.com/Gorski-Maciej/NexusAI/blob/main/nexus_ai/services/shadow_simulator.py
- https://github.com/Gorski-Maciej/NexusAI/blob/main/nexus_ai/services/shadow_resource_correlation.py
- https://github.com/Gorski-Maciej/NexusAI/blob/main/duckdb_tmp/ (katalog)

### Księgowość / Double-Entry:
- https://github.com/Gorski-Maciej/NexusAI/blob/main/nexus_ai/services/accountant_logic.py
- https://github.com/Gorski-Maciej/NexusAI/blob/main/nexus_ai/services/fixed_assets.py
- https://github.com/Gorski-Maciej/NexusAI/blob/main/nexus_ai/services/inventory_fifo.py
- https://github.com/Gorski-Maciej/NexusAI/blob/main/nexus_ai/services/fx_revaluation.py
- https://github.com/Gorski-Maciej/NexusAI/blob/main/nexus_ai/services/vat_reconciliation.py
- https://github.com/Gorski-Maciej/NexusAI/blob/main/nexus_ai/services/period_closer.py
- https://github.com/Gorski-Maciej/NexusAI/blob/main/nexus_ai/services/dunning_engine.py
- https://github.com/Gorski-Maciej/NexusAI/blob/main/nexus_ai/services/liquidity_oracle.py
- https://github.com/Gorski-Maciej/NexusAI/blob/main/nexus_ai/services/billing_estimator.py
- https://github.com/Gorski-Maciej/NexusAI/blob/main/nexus_ai/services/budget_control.py
- https://github.com/Gorski-Maciej/NexusAI/blob/main/nexus_ai/services/cashflow_projection.py (jeśli istnieje)

### Audyt i integralność:
- https://github.com/Gorski-Maciej/NexusAI/blob/main/nexus_ai/services/proof_chain.py
- https://github.com/Gorski-Maciej/NexusAI/blob/main/nexus_ai/services/integrity_verifier.py
- https://github.com/Gorski-Maciej/NexusAI/blob/main/nexus_ai/services/audit_service.py
- https://github.com/Gorski-Maciej/NexusAI/blob/main/nexus_ai/services/audit_storno.py
- https://github.com/Gorski-Maciej/NexusAI/blob/main/nexus_ai/services/replay_engine.py

### Integracja JDG ↔ TigerBeetle:
- https://github.com/Gorski-Maciej/NexusAI/blob/main/nexus_ai/tax/dynamic_dag.py
- https://github.com/Gorski-Maciej/NexusAI/blob/main/nexus_ai/tax/semantic_conflict_resolver.py

### Testy:
- https://github.com/Gorski-Maciej/NexusAI/blob/main/tests/test_shadow_ledger_contract.py
- https://github.com/Gorski-Maciej/NexusAI/blob/main/tests/test_fixed_assets_depreciation.py
- https://github.com/Gorski-Maciej/NexusAI/blob/main/tests/test_inventory_fifo.py
- https://github.com/Gorski-Maciej/NexusAI/blob/main/tests/test_reconciliation_engine.py

### Dokumentacja:
- https://github.com/Gorski-Maciej/NexusAI/blob/main/docs/DATABASE.md
- https://github.com/Gorski-Maciej/NexusAI/blob/main/docs/DOMAIN.md
- https://github.com/Gorski-Maciej/NexusAI/blob/main/docs/DECISIONS.md
- https://github.com/Gorski-Maciej/NexusAI/blob/main/RAPORT_TECHNOLOGII_NEXUSAI.txt

## 🎯 CEL ANALIZY:

Przeprowadź GŁĘBOKIE MYŚLENIE i GŁĘBOKĄ ANALIZĘ integracji TigerBeetle, Shadow Ledger 
i całego systemu księgowego NexusAI na ZAAWANSOWANYM POZIOMIE ENTERPRISE.
Wygeneruj ROZBUDOWANY RAPORT ANALITYCZNY (min. 22-30 stron) zawierający:

### 1. AUDYT ARCHITEKTURY TIGERBEETLE (POZIOM ENTERPRISE — 🔴 NAJWYŻSZY PRIORYTET)
- Oceń konfigurację TigerBeetle (cluster ID, repliki, partycje)
- Czy wszystkie operacje double-entry (debit/credit) są atomowe?
- Czy transfery między kontami są poprawnie realizowane (two-phase transfer)?
- Czy TigerBeetle jest poprawnie zintegrowany z resztą systemu przez NATS?
- Zaproponuj INNOWACYJNE USPRAWNIENIA WYPRZEDZAJĄCE PROFESJONALISTÓW

### 2. ANALIZA SHADOW LEDGER (POZIOM ENTERPRISE)
- Czy DuckDB Shadow Ledger poprawnie replikuje księgę główną?
- Czy symulacje "what-if" są poprawne i nie wpływają na produkcyjną księgę?
- Czy synchronizacja TigerBeetle ↔ DuckDB jest spójna?
- Zaproponuj INNOWACYJNY MECHANIZM real-time shadow reconciliation

### 3. ANALIZA INTEGRALNOŚCI KSIĘGOWEJ (POZIOM ENTERPRISE)
- Czy Proof Chain SHA-256 gwarantuje niezmienność zapisów księgowych?
- Czy system spełnia wymogi UoR Art. 24 (rzetelność, bezbłędność, sprawdzalność)?
- Czy mechanizm storna (audit_storno.py) jest zgodny z UoR?
- Czy wszystkie operacje mają pełną ścieżkę audytu (immutable audit trail)?

### 4. ANALIZA KSIĘGOWAŃ SPECJALISTYCZNYCH (POZIOM ENTERPRISE)
- **Środki trwałe:** amortyzacja liniowa/degresywna, MIDM, ulepszenia, likwidacja
- **FIFO:** wycena rozchodu zapasów, korekty
- **FX Revaluation:** przeliczanie walut, różnice kursowe
- **VAT Reconciliation:** uzgadnianie VAT należnego i naliczonego
- **Period Closer:** zamknięcie miesiąca/roku

### 5. ANALIZA PŁYNNOŚCI I BUDŻETOWANIA (POZIOM ENTERPRISE)
- Liquidity Oracle — czy predykcje cash flow są dokładne?
- Billing Estimator — czy estymacje faktur są poprawne?
- Budget Control — czy alerty budżetowe działają?

### 6. 🆕 AUDYT ZGODNOŚCI Z NAJNOWSZYM STANEM PRAWNYM 2026 (POZIOM ENTERPRISE)
- Czy system księgowy spełnia wymogi UoR 2026?
- Czy amortyzacja uwzględnia zmiany stawek 2026?
- Czy limity FIFO i wyceny są zgodne z KSR 2026?

### 7. 🆕 FRAUD DETECTION W KSIĘGOWOŚCI (POZIOM ENTERPRISE)
- Czy system wykrywa nieautoryzowane modyfikacje księgi głównej?
- Czy double-entry uniemożliwia manipulację saldem?
- Zaproponuj INNOWACYJNY SYSTEM real-time fraud detection w księdze głównej

### 8. 🆕 STRESS TESTY KSIĘGOWE (POZIOM ENTERPRISE)
- 1 000 000 transakcji w TigerBeetle — czy system wytrzymuje?
- Jednoczesne zamknięcie roku + FX revaluation + FIFO — czy nie ma deadlocków?
- Awaria DuckDB podczas synchronizacji Shadow Ledger

### 9. 🆕 TEMPORAL RESILIENCE (POZIOM ENTERPRISE)
- Czy system obsługuje wsteczne księgowania (backdated entries)?
- Czy zmiana planu kont w trakcie roku jest obsłużona?
- Czy amortyzacja wsteczna (korekta) jest poprawna?

### 10. GENIALNE POMYSŁY ENTERPRISE — TIGERBEETLE
- Zaproponuj co najmniej 10 INNOWACYJNYCH USPRAWNIEŃ WYPRZEDZAJĄCYCH PROFESJONALISTÓW:
  - System "continuous audit" — nieprzerwany audyt księgi głównej w czasie rzeczywistym
  - Mechanizm "what-if" symulacji na Shadow Ledger z ML predykcją cash flow
  - Auto-healing ledger — automatyczna naprawa niespójności
  - Distributed TigerBeetle cluster z geo-replikacją

### 11. REKOMENDACJE — MAPA DROGOWA zero-defect accounting

## 📐 FORMAT RAPORTU:
- Tytuł: "RAPORT ANALITYCZNY ENTERPRISE — TigerBeetle, Shadow Ledger i Double-Entry Accounting v7.0"
- Executive Summary z TOP 10, diagramy Mermaid (TigerBeetle flow, Shadow Ledger sync)
- Macierz ryzyka dla operacji księgowych

## ⚠️ NIE GENERUJ KODU. Tylko RAPORT.
```
🧹 PO ZAKOŃCZENIU ANALIZY: WYCZYŚĆ OKNO KONTEKSTOWE przed przejściem do następnej sesji.
