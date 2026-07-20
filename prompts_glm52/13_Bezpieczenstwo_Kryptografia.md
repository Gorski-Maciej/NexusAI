# 🔥 PROMPT 13: Bezpieczeństwo + Kryptografia (nexus-crypto, JWT, RBAC)

> **⚠️ WYJŚCIE OBOWIĄZKOWE — PLIK .TXT:** Cały wygenerowany raport analityczny ZAPISZ jako czysty plik `.txt` (plain text, bez formatowania Markdown). To jedyne akceptowane WYJŚCIE twojej pracy.

```text
🚨 INSTRUKCJA DLA MODELU GLM 5.2:

Jesteś Najwyższej Klasy Ekspertem w dziedzinie bezpieczeństwa aplikacji klasy Enterprise, 
kryptografii (AEAD, Argon2id, SHA-256), JWT, RBAC, SQLCipher, OWASP Top 10, 
bezpieczeństwa danych finansowych i audytu bezpieczeństwa.

## ⚠️ NIE GENERUJ KODU — tylko ROZBUDOWANY RAPORT ANALITYCZNY

## 📂 PLIKI DO ANALIZY (~20 plików):

### Kryptografia — Core:
- https://github.com/Gorski-Maciej/NexusAI/blob/main/nexus_ai/rust/nexus_crypto/ (cały katalog)
- https://github.com/Gorski-Maciej/NexusAI/blob/main/nexus_ai/core/crypto.py
- https://github.com/Gorski-Maciej/NexusAI/blob/main/docs/RUST_MODULE.md
- https://github.com/Gorski-Maciej/NexusAI/blob/main/docs/SECURITY.md

### Bezpieczeństwo API:
- https://github.com/Gorski-Maciej/NexusAI/blob/main/nexus_ai/api/ (katalog API)
- https://github.com/Gorski-Maciej/NexusAI/blob/main/nexus_ai/core/tenant.py
- https://github.com/Gorski-Maciej/NexusAI/blob/main/nexus_ai/core/secrets.py

### Bezpieczeństwo danych:
- https://github.com/Gorski-Maciej/NexusAI/blob/main/nexus_ai/db/security.py
- https://github.com/Gorski-Maciej/NexusAI/blob/main/nexus_ai/services/proof_chain.py
- https://github.com/Gorski-Maciej/NexusAI/blob/main/nexus_ai/services/log_pii_monitor.py
- https://github.com/Gorski-Maciej/NexusAI/blob/main/nexus_ai/services/risk_guard.py
- https://github.com/Gorski-Maciej/NexusAI/blob/main/nexus_ai/services/fraud_graph_scanner.py

### CI/CD Security:
- https://github.com/Gorski-Maciej/NexusAI/blob/main/.github/workflows/ (katalog)
- https://github.com/Gorski-Maciej/NexusAI/blob/main/.pre-commit-config.yaml

### Testy bezpieczeństwa:
- https://github.com/Gorski-Maciej/NexusAI/blob/main/tests/test_security_ci_workflow_contract.py
- https://github.com/Gorski-Maciej/NexusAI/blob/main/tests/test_security_posture_endpoint_contract.py
- https://github.com/Gorski-Maciej/NexusAI/blob/main/tests/test_security_scan_severity_runtime.py
- https://github.com/Gorski-Maciej/NexusAI/blob/main/tests/test_local_secrets_cache_contract.py
- https://github.com/Gorski-Maciej/NexusAI/blob/main/tests/test_local_secrets_cache_encryption_runtime.py
- https://github.com/Gorski-Maciej/NexusAI/blob/main/tests/test_startup_offline_secret_contract.py
- https://github.com/Gorski-Maciej/NexusAI/blob/main/tests/test_privacy_endpoint_contract.py
- https://github.com/Gorski-Maciej/NexusAI/blob/main/tests/test_log_pii_scanner_validation_runtime.py
- https://github.com/Gorski-Maciej/NexusAI/blob/main/tests/test_upload_guard_contract.py
- https://github.com/Gorski-Maciej/NexusAI/blob/main/tests/test_risk_guard.py
- https://github.com/Gorski-Maciej/NexusAI/blob/main/tests/test_risk_guard_integration.py
- https://github.com/Gorski-Maciej/NexusAI/blob/main/tests/test_fraud_graph_scanner.py

### Dokumentacja:
- https://github.com/Gorski-Maciej/NexusAI/blob/main/docs/SECURITY.md
- https://github.com/Gorski-Maciej/NexusAI/blob/main/docs/COMPLIANCE.md
- https://github.com/Gorski-Maciej/NexusAI/blob/main/docs/RUST_MODULE.md
- https://github.com/Gorski-Maciej/NexusAI/blob/main/docs/DECISIONS.md

## 🎯 CEL ANALIZY:

Przeprowadź GŁĘBOKIE MYŚLENIE i GŁĘBOKĄ ANALIZĘ bezpieczeństwa NexusAI 
na ZAAWANSOWANYM POZIOMIE ENTERPRISE.
Wygeneruj ROZBUDOWANY RAPORT ANALITYCZNY (min. 22-30 stron) zawierający:

### 1. AUDYT KRYPTOGRAFII (POZIOM ENTERPRISE)
- nexus-crypto (Rust+PyO3 → pure-Python fallback): czy AEAD ChaCha20-Poly1305 jest poprawnie zaimplementowane?
- Czy Argon2id KDF używa bezpiecznych parametrów (memory, iterations, parallelism)?
- Czy SHA-256 jest używany prawidłowo w Proof Chain?
- Czy mlock() chroni sekrety w pamięci?
- Czy pure-Python fallback jest bezpieczny?

### 2. AUDYT JWT I RBAC (POZIOM ENTERPRISE)
- Czy JWT (Litestar) używa RS256/HS256 z odpowiednim czasem wygaśnięcia?
- Czy refresh tokeny są bezpiecznie rotowane?
- Czy RBAC (role/permissions) jest granularny i zgodny z least privilege?

### 3. ANALIZA SQLCipher (POZIOM ENTERPRISE)
- Czy AES-256 szyfrowanie każdej strony SQLite jest bezpieczne?
- Czy key derivation jest poprawny?
- Czy WAL mode współpracuje z szyfrowaniem?

### 4. ANALIZA PROOF CHAIN (POZIOM ENTERPRISE)
- Czy łańcuch SHA-256 gwarantuje niezmienność logów?
- Czy audyt jest weryfikowalny przez stronę trzecią?

### 5-10. 🆕 OWASP + FRAUD + STRESS + TEMPORAL + GENIALNE POMYSŁY (min. 12 INNOWACYJNYCH USPRAWNIEŃ WYPRZEDZAJĄCYCH PROFESJONALISTÓW)

## 📐 FORMAT RAPORTU:
- Tytuł: "RAPORT ANALITYCZNY ENTERPRISE — Bezpieczeństwo i Kryptografia NexusAI v7.0"

## ⚠️ NIE GENERUJ KODU. Tylko RAPORT.
```

📄 **WYJŚCIE = PLIK .TXT:** Zapisz cały wygenerowany raport analityczny jako czysty plik `.txt` (plain text, bez formatowania).

🧹 PO ZAKOŃCZENIU ANALIZY: WYCZYŚĆ OKNO KONTEKSTOWE przed przejściem do następnej sesji.
