# 🔥 PROMPT 14: Integracje Zewnętrzne (KSeF, GUS, NBP, Biała Lista MF, PSD2)

> **⚠️ WYJŚCIE OBOWIĄZKOWE — PLIK .TXT:** Cały wygenerowany raport analityczny ZAPISZ jako czysty plik `.txt` (plain text, bez formatowania Markdown). To jedyne akceptowane WYJŚCIE twojej pracy.

```text
🚨 INSTRUKCJA DLA MODELU GLM 5.2:

Jesteś Najwyższej Klasy Ekspertem w dziedzinie integracji API zewnętrznych, 
systemów finansowych klasy Enterprise, KSeF, GUS BIR, NBP API, Biała Lista MF, 
PSD2/Open Banking i architektury resilience dla integracji zewnętrznych.

## ⚠️ NIE GENERUJ KODU — tylko ROZBUDOWANY RAPORT ANALITYCZNY

## 📂 PLIKI DO ANALIZY (~15 plików):

### Integracje zewnętrzne:
- https://github.com/Gorski-Maciej/NexusAI/blob/main/nexus_ai/services/gus_bir_client.py
- https://github.com/Gorski-Maciej/NexusAI/blob/main/nexus_ai/services/white_list_service.py
- https://github.com/Gorski-Maciej/NexusAI/blob/main/nexus_ai/tax/nbp_client.py
- https://github.com/Gorski-Maciej/NexusAI/blob/main/nexus_ai/services/vendor_intelligence.py
- https://github.com/Gorski-Maciej/NexusAI/blob/main/nexus_ai/services/bank_import.py
- https://github.com/Gorski-Maciej/NexusAI/blob/main/nexus_ai/core/integrations/ (katalog)
- https://github.com/Gorski-Maciej/NexusAI/blob/main/nexus_ai/core/fsspec_compat.py

### HTTP / Networking:
- https://github.com/Gorski-Maciej/NexusAI/blob/main/nexus_ai/core/ (httpx, hishel, stamina konfiguracja)
- https://github.com/Gorski-Maciej/NexusAI/blob/main/docs/HTTP_CLIENT.md

### KSeF (powtórka kluczowych):
- https://github.com/Gorski-Maciej/NexusAI/blob/main/nexus_ai/services/ksef_service.py
- https://github.com/Gorski-Maciej/NexusAI/blob/main/nexus_ai/services/ksef_generator.py

### Testy:
- https://github.com/Gorski-Maciej/NexusAI/blob/main/tests/test_gus_bir_client.py
- https://github.com/Gorski-Maciej/NexusAI/blob/main/tests/test_fx_rates_startup_contract.py
- https://github.com/Gorski-Maciej/NexusAI/blob/main/tests/test_ksef_generator.py
- https://github.com/Gorski-Maciej/NexusAI/blob/main/tests/test_integrity_verifier.py

### Dokumentacja:
- https://github.com/Gorski-Maciej/NexusAI/blob/main/docs/API.md
- https://github.com/Gorski-Maciej/NexusAI/blob/main/docs/COMPLIANCE.md
- https://github.com/Gorski-Maciej/NexusAI/blob/main/docs/HTTP_CLIENT.md

## 🎯 CEL ANALIZY:

Przeprowadź GŁĘBOKIE MYŚLENIE i GŁĘBOKĄ ANALIZĘ integracji zewnętrznych NexusAI 
na ZAAWANSOWANYM POZIOMIE ENTERPRISE.
Wygeneruj ROZBUDOWANY RAPORT ANALITYCZNY (min. 16-22 stron) zawierający:

### 1. AUDYT KSeF (POZIOM ENTERPRISE)
- Czy integracja z KSeF API MF jest kompletna (wysyłka, status, pobieranie)?
- Czy token autoryzacyjny KSeF jest poprawnie zarządzany?
- Czy circuit breaker (stamina) chroni przed przeciążeniem API MF?
- Czy batch send (do 100 faktur) jest poprawnie zaimplementowany?

### 2. AUDYT GUS BIR + BIAŁA LISTA MF (POZIOM ENTERPRISE)
- Czy dane z GUS BIR są poprawnie pobierane i cache'owane?
- Czy Biała Lista MF (weryfikacja NIP, status VAT, rachunek bankowy) działa?
- Czy vendor_intelligence.py agreguje dane z wielu źródeł?

### 3. AUDYT NBP API (POZIOM ENTERPRISE)
- Czy kursy walut NBP są poprawnie pobierane (tabela A, B, C)?
- Czy cache kursów walut jest odpowiednio odświeżany?
- Czy fx_revaluation.py poprawnie używa kursów NBP?

### 4. ANALIZA RESILIENCE I HTTP (POZIOM ENTERPRISE)
- Czy httpx + hishel (cache) + stamina (retry/circuit breaker) jest optymalnie skonfigurowane?
- Czy wszystkie integracje mają timeout, retry i fallback?

### 5-8. 🆕 AUDYT 2026 + FRAUD + STRESS + GENIALNE POMYSŁY (min. 10 INNOWACYJNYCH USPRAWNIEŃ WYPRZEDZAJĄCYCH PROFESJONALISTÓW)

## 📐 FORMAT RAPORTU:
- Tytuł: "RAPORT ANALITYCZNY ENTERPRISE — Integracje Zewnętrzne NexusAI v7.0"

## ⚠️ NIE GENERUJ KODU. Tylko RAPORT.
```

📄 **WYJŚCIE = PLIK .TXT:** Zapisz cały wygenerowany raport analityczny jako czysty plik `.txt` (plain text, bez formatowania).

🧹 PO ZAKOŃCZENIU ANALIZY: WYCZYŚĆ OKNO KONTEKSTOWE przed przejściem do następnej sesji.
