# VAT MACRO — P03 Enterprise (Warstwa Makro VAT)

> **📌 Aktualizacja 2026-08-22:** dokument historyczny opisujący wdrożenie promptu GLM 5.2.
> Raporty źródłowe (`prompty_glm52/`, `raporty_glm52/`, `raporty_jdg_enterprise/`) zostały zarchiwizowane poza repo.
> Aktualny stan wdrożenia: [`KAMPANIA_GLM52_ETAPY_10_28.md`](KAMPANIA_GLM52_ETAPY_10_28.md) + `JDG/bundles/*audit_state.json` (certyfikacja końcowa ETAP 28 — 2026-08-22: 13/14 bramek `NIEPELNY`; domknięcie V4 2026-08-29: `WDROŻONY_100` 6/6).

> NexusAI JDG — wdrożenie promptu `prompts_glm52/P03_VAT_Macro.txt` (v9.0, 2026-08-02)
> Raport: `raporty_jdg_enterprise/R03_VAT_Macro.txt` · Status: ✅ WDROŻONY

## Zakres (9 sekcji promptu → działający kod)

| Sekcja | Temat | Pakiet rego |
|---|---|---|
| 1 | Stawki i zwolnienia (23/8/5/0/NP, art. 43/113, limit 200k mid-year) | `jdg.vat_rates_audit` |
| 2 | Miejsce świadczenia (art. 28a-28o, OSS/IOSS) | `jdg.p03_vat_macro_innovations` |
| 3 | Odliczenia i korekty (art. 86-95, proporcja, korekta roczna, złe długi) | `jdg.vat_deductions_audit` |
| 4 | **MPP / split payment (PRIORYTET)** — art. 108a-108f, Załącznik 15 | `jdg.vat_mpp_split_payment` |
| 5 | VAT 2026 + KSeF (obowiązkowy od 2026-02-01) | `jdg.p03_vat_macro_innovations` |
| 6 | Fraud detection VAT (puste faktury, karuzele, znikający podatnik) | `jdg.vat_fraud_detection` |
| 7 | OPA jako system — pipeline auto-aktualizacji progów VAT | `jdg.p03_vat_macro_innovations` |
| 8 | 15+ genialnych pomysłów Enterprise | `jdg.p03_vat_macro_innovations` |
| 9 | Mapa drogowa P0/P1/P2 | raport R03 |

## Architektura

```
final_verdict_p03 = safe_merge(final_verdict_p02,
    safe_merge(vat_rates_audit.decide,
    safe_merge(vat_deductions_audit.decide,
    safe_merge(vat_mpp_split_payment.decide,
    safe_merge(vat_fraud_detection.decide,
    safe_merge(p03_vat_macro_innovations.decide, fallback.decide))))))
```

Wszystkie pakiety P03 są **REPORT-owe** — aktywowane flagami:
- `input.jdg_entrepreneur.vat_rates_check`
- `input.jdg_entrepreneur.vat_deductions_check`
- `input.jdg_entrepreneur.vat_mpp_check`
- `input.jdg_entrepreneur.vat_fraud_check`
- `input.jdg_entrepreneur.p03_vat_macro_check`

W normalnym ruchu zwracają `no_match` (`matched:false`). Krytyczne sygnały
(BLOCK_AND_ALERT): `midyear_breach`, `deduction_blocked`, `mpp_violation`,
`solidary_liability_risk`, `empty_invoice_detection`, `carousel_detection`,
`vanishing_trader_detection`, `ksef_readiness`.

## Kluczowe reguły

### Sekcja 1 — Stawki i zwolnienia (`vat_rates_exemptions_audit_enterprise.rego`)
- `rate_map` — mapa stawek per kategoria (fallback: CN → PKWiU → kategoria)
- `rate_mismatch` — stawka faktury ≠ stawka wg mapy → TRIAGE_QUEUE
- `midyear_breach` — przekroczenie 200k mid-year → BLOCK (art. 113 ust. 5)
- `startup_proportional_limit` — proporcja startowa (art. 113 ust. 9)

### Sekcja 3 — Odliczenia i korekty (`vat_deductions_corrections_enterprise.rego`)
- `deduction_blocked` — blokady art. 88 (gastronomia, paliwo, bez dokumentu)
- `preproportion_report` — pre-proporcja i korekta roczna (art. 90-91)
- `multi_year_correction` — korekta wieloletnia środków trwałych (5/10 lat)
- `bad_debt_creditor_correction` / `bad_debt_debtor_correction` — SLIM VAT 3 (89a/89b)

### Sekcja 4 — MPP / split payment (`vat_mpp_split_payment_enterprise.rego`) ★ PRIORYTET
- `mp_auto_mark` — **auto-oznaczanie semantyczne** (CN Załącznika 15 + opis)
- `mpp_violation` — brak MPP przy obowiązku → BLOCK + sankcja 30% VAT
- `solidary_liability_risk` — zapłata poza białą listą (art. 108b)

### Sekcja 6 — Fraud (`vat_fraud_detection_enterprise.rego`)
- `counterparty_risk_score` / `transaction_risk_score` — scoring 0-100
- `empty_invoice_detection` / `carousel_detection` / `vanishing_trader_detection`
- `solidary_fraud_liability` — art. 105a-105c

### Sekcje 2/5/7/8 — POS/KSeF/pipeline/ideas (`p03_vat_macro_innovations_v9.rego`)
- `oss_analysis` — próg OSS 10 000 EUR (art. 28m-28o)
- `ksef_readiness` — **KSeF obowiązkowy od 2026-02-01** (BLOCK przy braku e-faktury)
- `vat_thresholds_snapshot` — progi z `data.jdg.thresholds.vat` (ADR-002, zero hardcode)
- `refund_forecast` — predyktor zwrotu VAT 25/60/180 dni (art. 87)
- `auto_gtu` — GTU z analizy opisu (13 kodów)
- `vat_obligations_calendar` — kalendarz obowiązków (JPK, VAT-7, KSeF, VIES, Intrastat)

## Narzędzia

- **`JDG/tools/vat_mpp_auto_detector.py`** — auto-oznaczanie MPP (detect / annex15 / batch).
  Wyjście: `bundles/mpp_auto_marked.jsonl`, kod wyjścia 2 przy naruszeniach (CI).
- Pipeline progów VAT (Sekcja 7): rego czyta `data.jdg.vat.rate_map`,
  `data.jdg.vat.mpp_annex15`, `data.jdg.thresholds.vat` — hot-reload, ADR-002.

## Walidacja

- `pytest JDG/tests/auto/test_p03_vat_macro_enterprise.py` — testy automatyczne
- `JDG/tests/rego/test_p03_vat_macro_enterprise.rego` — testy rego (CI `opa test`)
- Kody sankcji: MPP 30% VAT, solidarna odpowiedzialność, KSeF — BLOCK_AND_ALERT
