# P16 — RODO + AML + Compliance + Bezpieczeństwo + Audyt (Enterprise)

Pakiet: `jdg.p16_rodo_aml_security_innovations`
Plik: `JDG/rules/p16_rodo_aml_security_innovations_v9.rego`
Raport: `raporty_jdg_enterprise/R16_RODO_AML_Bezpieczenstwo.txt`
Narzędzie: `JDG/tools/rodo_aml_security_auditor.py`

## Zakres (7 sekcji promptu wdrożone jako reguły)

| Sekcja | Reguły | Status |
|---|---|---|
| 1. Mapa pokrycia | `rodo_aml_coverage_report` — 7 modułów (rodo, rodo_extended, micro_rodo, aml, micro_aml, security, audit) z `data.jdg.p16_audit` + gap_pct | ✅ |
| 1. AUDYT RODO (PRIORYTET) | `rodo_audit` — rejestr czynności (Art. 30), retencja (Art. 5(1)(e) + Art. 74 UoR — 5 lat), erasure (Art. 17 — 30 dni), podprocesorzy (Art. 28), AI marketing (Art. 22), sankcje (Art. 83: 20 mln EUR/4% i 10 mln EUR/2%) | ✅ |
| 1. Rejestr auto (INN-01) | `rodo_register_automation` — automatyczny rejestr czynności przetwarzania (Art. 30) | ✅ |
| 1. Tracker 72h breach (INN-02) | `breach_72h_tracker` — licznik godzin do zgłoszenia UODO (Art. 33), BLOCK przy >72h, sankcja 20 mln EUR | ✅ |
| 2. AUDYT AML (PRIORYTET ★) | `aml_audit` — CBDD (Art. 28-34 u.AML), beneficjenci rzeczywiści, STR/GIF (Art. 74-80 — 1 dzień), transakcje > 15 000 EUR (Art. 34), scoring ryzyka, sankcje (art. 153 u.AML) | ✅ |
| 2. Scoring klient (INN-03) | `aml_risk_scoring_client` — jurysdykcja × sektor × struktura własności → CDD wzmożona/standardowa/uproszczona | ✅ |
| 2. Scoring transakcja (INN-04) | `aml_risk_scoring_transaction` — kwota + anomalie + kraj + instrument; próg 15 000 EUR; STR gdy score ≥ 50 | ✅ |
| 3. AUDYT BEZPIECZEŃSTWA | `security_audit` — integralność (HMAC), szyfrowanie (AES-256/TLS 1.3 — Art. 32), immutable verdicts (P901), 4 zablokowane ataki P34 | ✅ |
| 3. Forteca (INN-05) | `security_fortress_layers` — 5 warstw: walidacja, HMAC, output guard, immutability, audit trail | ✅ |
| 4. AUDYT ŚCIEŻKI DECYZJI | `audit_trail_audit` — pełna odtwarzalność, niezmienialność, merkle tree, provenance (ADR-006) | ✅ |
| 4. Proof-chain (INN-06) | `proof_chain_verifier` — merkle-like łańcuch: input → reguła → werdykt → hash root | ✅ |
| 5. OPA jako system | `compliance_pipeline_snapshot` — pipeline ingest→generate→verify→emit (ADR-002, hot-reload); ePrivacy (2002/58/WE), AMLR (UE 2024/1624) | ✅ |
| 6. Genius ideas (14) | INN-01..14: rejestr auto, breach 72h, scoring klient, scoring transakcja, forteca, proof-chain, self-audit, panel AML, asystent naruszeń, decision chain, HMAC reguł, kalkulator sankcji, UBO, scorecard | ✅ |
| 7. Mapa drogowa | w raporcie R16 — luki P0/P1/P2 | ✅ |

## Progi (ADR-002 — `data.jdg.thresholds.compliance_aml_rodo`)

- Sankcje RODO: 20 mln EUR / 4% obrotu (Art. 83 ust. 5) oraz 10 mln EUR / 2% (ust. 4)
- Zgłoszenie naruszenia: 72h (Art. 33 RODO)
- Erasure: 30 dni (Art. 17 RODO); retencja księgowa: 5 lat (Art. 74 UoR)
- AML: próg transakcyjny 15 000 EUR (Art. 34 u.AML); STR do GIIF — 1 dzień roboczy
- UBO: beneficjent rzeczywisty ≥ 25% udziałów
- Kara AML: do 1 mln zł (art. 153 u.AML)

## Narzędzie CLI

```bash
python JDG/tools/rodo_aml_security_auditor.py --audit            # audyt micro (rodo 73 + aml 159 + security 19 + audit 98 = ~350+ rule_id)
python JDG/tools/rodo_aml_security_auditor.py --breach --breach-hours 48     # tracker 72h (w terminie)
python JDG/tools/rodo_aml_security_auditor.py --breach --breach-hours 100    # tracker 72h (przekroczono)
python JDG/tools/rodo_aml_security_auditor.py --aml-client --client-name "Offshore Ltd" --jurisdiction-risk 100 --sector-risk 100 --ownership-risk 100
python JDG/tools/rodo_aml_security_auditor.py --aml-transaction --amount-eur 20000 --anomaly SPLIT_TRANSACTIONS
python JDG/tools/rodo_aml_security_auditor.py --proof-chain     # merkle root SHA-256
python JDG/tools/rodo_aml_security_auditor.py --sanctions --violation-type DATA_BREACH_UNREPORTED --revenue-eur 50000000
python JDG/tools/rodo_aml_security_auditor.py --scorecard --rodo-score 80 --aml-score 70 --security-score 90
```

## Testy

- Rego: `JDG/tests/rego/test_p16_rodo_aml_security_enterprise.rego` (28 scenariuszy)
- Pytest: `JDG/tests/auto/test_p16_rodo_aml_security_enterprise.py` (31 testów)

## Okablowanie

- `main_jdg.rego`: `import data.jdg.p16_rodo_aml_security_innovations` (PAS 18r), wpis w `_package_decisions`, `final_verdict_p16 = safe_merge(final_verdict_p15, ...)` — bez kolizji ze starym pakietem `jdg.p16_innovations` (v8 Business Lifecycle).
