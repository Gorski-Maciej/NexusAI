# P17 — KSeF + JPK + e-Deklaracje (Enterprise)

> **📌 Aktualizacja 2026-08-22:** dokument historyczny opisujący wdrożenie promptu GLM 5.2.
> Raporty źródłowe (`prompty_glm52/`, `raporty_glm52/`, `raporty_jdg_enterprise/`) zostały zarchiwizowane poza repo.
> Aktualny stan wdrożenia: [`KAMPANIA_GLM52_ETAPY_10_28.md`](KAMPANIA_GLM52_ETAPY_10_28.md) + `JDG/bundles/*audit_state.json` (certyfikacja końcowa ETAP 28 — 2026-08-22: 13/14 bramek `NIEPELNY`; domknięcie V4 2026-08-29: `WDROŻONY_100` 6/6).

Pakiet: `jdg.p17_ksef_jpk_edeklaracje_innovations`
Plik: `JDG/rules/p17_ksef_jpk_edeklaracje_innovations_v9.rego`
Raport: `raporty_jdg_enterprise/R17_KSeF_JPK_eDeklaracje.txt`
Narzędzie: `JDG/tools/ksef_jpk_edeklaracje_auditor.py`

## Zakres (7 sekcji promptu wdrożone jako reguły)

| Sekcja | Reguły | Status |
|---|---|---|
| 1. Mapa pokrycia | `ksef_jpk_coverage_report` — 7 modułów (ksef_core, ksef_enterprise, jpk, gtu, edelivery, esig, wis) z `data.jdg.p17_audit` + gap_pct | ✅ |
| 1. AUDYT KSeF (PRIORYTET) | `ksef_audit` — obowiązek od 2026-02-01 (art. 106na-106nb VAT), wyjątki B2C, schemat FA(2), UPO (1 dzień), off-line 7 dni, sankcje do 500 000 zł | ✅ |
| 1. Tracker UPO (INN-02) | `ksef_upo_tracker` — porównanie faktur z potwierdzeniami, TRIAGE przy brakach | ✅ |
| 1. Monitor sankcji (INN-03) | `ksef_sanction_monitor` — faktury poza KSeF → kara (≥5 szt. = 500 000 zł max), BLOCK_AND_ALERT | ✅ |
| 1. Retry offline (INN-04) | `ksef_offline_retry` — tryb awaryjny ≤7 dni, auto-wysyłka po przywróceniu | ✅ |
| 1. Walidator XSD (INN-06) | `ksef_xsd_validator` — pola P_1..P_8 faktury ustrukturyzowanej | ✅ |
| 1. Kalkulator sankcji (INN-13) | `ksef_sanctions_calculator` — 1000 zł/fakturę, cap 500 000 zł | ✅ |
| 2. AUDYT JPK (PRIORYTET ★) | `jpk_audit` — JPK_V7M/V7K (do 25.), JPK_PKPIR/KR/CIT, GTU_01..13, walidacja krzyżowa | ✅ |
| 2. Auto-generator JPK_V7 (INN-01) | `jpk_v7_auto_generator` — rejestry sprzedaży/zakupów → VAT należny/naliczony + struktura | ✅ |
| 2. GTU auto (INN-05) | `gtu_auto_assigner` — opis transakcji → GTU_01..GTU_13 (fallback GTU_01) | ✅ |
| 2. Walidacja krzyżowa (INN-08) | `jpk_cross_validation` — rejestry vs VAT-7, TRIAGE przy rozbieżności | ✅ |
| 2. Kalendarz (INN-14) | `jpk_deadline_calendar` — JPK_V7 do 25., VAT-7, VAT-UE, JPK na żądanie | ✅ |
| 3. AUDYT e-DORĘCZEŃ I e-PODPISU | `edelivery_esig_audit` — adres do doręczeń (od 2026-01-01), e-podpis kwalifikowany/zaufany (eIDAS) | ✅ |
| 3. e-podpis auto (INN-09) | `esig_auto_applier` — auto-aplikacja podpisu (QUALIFIED/TRUSTED) | ✅ |
| 3. Adres do doręczeń (INN-10) | `edelivery_address_manager` — adres + skrzynka, TRIAGE przy braku | ✅ |
| 4. AUDYT ePUAP, WIS, ODPORNOŚCI | `epuap_wis_resilience_audit` — e-Urząd, WIS (art. 42a VAT, 3 mies.), odporność 7 dni, sandbox | ✅ |
| 4. WIS auto (INN-11) | `wis_auto_requester` — automatyczne zapytania o WIS | ✅ |
| 4. Sandbox (INN-12) | `ksef_sandbox_harness` — środowisko testowe KSeF | ✅ |
| 4. Firewall KSeF (INN-07) | `ksef_firewall_guard` — blokada faktur z anomaliami przed wysyłką | ✅ |
| 5. OPA jako system | `ksef_pipeline_snapshot` + `ksef_schema_pipeline` (INN-15) — pipeline ingest→generate→verify→emit, KSeF 2.0, auto-aktualizacja XSD | ✅ |
| 6. Genius ideas (15) | INN-01..15: jpk_v7_auto_generator, ksef_upo_tracker, ksef_sanction_monitor, ksef_offline_retry, gtu_auto_assigner, ksef_xsd_validator, ksef_firewall_guard, jpk_cross_validation, esig_auto_applier, edelivery_address_manager, wis_auto_requester, ksef_sandbox_harness, ksef_sanctions_calculator, jpk_deadline_calendar, ksef_schema_pipeline | ✅ |
| 7. Mapa drogowa P0/P1/P2 (R17) | `ksef_api_integration`, `ksef_xsd_offline_ci`, `ksef_corrections_e2e`, `gtu_full_dictionary`, `edelivery_b2b_b2g_integration`, `ksef_dashboard_ui`, `jpk_cit_automation_2026` — wszystkie 7 pozycji wdrożone | ✅ |

## Mapa drogowa P0/P1/P2 — wdrożone (R17, 2026-08-05)

| Priorytet | Pozycja | Reguła + narzędzie |
|---|---|---|
| P0 | rzeczywista integracja API KSeF (produkcyjna wysyłka + UPO via API) | `ksef_api_integration` / `ksef_api_integration()` — endpointy prod/sandbox, token, numer KSeF, retry ×3, UPO via API |
| P0 | pełny walidator XSD offline (Java/xmllint) w CI | `ksef_xsd_offline_ci` / `ksef_xsd_offline_ci()` — 3 schematy (FA(2), FA(2)-korekta, KSeF 2.0), brama CI blokuje |
| P1 | korekty KSeF end-to-end (art. 106j VAT) + anulowanie faktur | `ksef_corrections_e2e` / `ksef_corrections_e2e()` — termin 30 dni, anulowanie, faktury korygujące |
| P1 | baza GTU z pełnym słownikiem 13 kodów + uczenie z historii | `gtu_full_dictionary` / `gtu_full_dictionary()` — słownik 13 wpisów, learning_enabled, entry_for_hint |
| P1 | integracja e-Doręczeń (skrzynka B2B/B2G + potwierdzenia) | `edelivery_b2b_b2g_integration` / `edelivery_b2b_b2g_integration()` — API edoreczenia.gov.pl, potwierdzenia doręczenia |
| P2 | dashboard KSeF (status UPO, kara, rejestry) w UI | `ksef_dashboard_ui` / `ksef_dashboard_ui()` — widgets + export JSON/CSV/PDF, BLOCK przy karze max |
| P2 | automatyzacja JPK_CIT wg szablonu MF 2026 | `jpk_cit_automation_2026` / `jpk_cit_automation_2026()` — szablon v2.0, sekcje bilans/RZiS, termin 31. I kw. |

## Progi (ADR-002 — `data.jdg.thresholds.ksef_jpk_edeklaracje`)

- KSeF obowiązkowy: od 2026-02-01 (art. 106na-106nb VAT)
- Tryb awaryjny off-line: do 7 dni; UPO: do 1 dnia
- Sankcja KSeF: do 500 000 zł; 1 000 zł za fakturę poza systemem
- JPK_V7M/V7K: do 25. dnia miesiąca (art. 82 ust. 1b VAT)
- Kody GTU: GTU_01..GTU_13
- e-Doręczenia: obowiązkowe od 2026-01-01; e-podpis: kwalifikowany (eIDAS) / zaufany (mObywatel)
- WIS: odpowiedź do 3 miesięcy (art. 42a VAT)

## Narzędzie CLI

```bash
python JDG/tools/ksef_jpk_edeklaracje_auditor.py --audit            # audyt micro (~560 rule_id)
python JDG/tools/ksef_jpk_edeklaracje_auditor.py --jpk-generator --sales-register 10000 --vat-sales 1000 --vat-purchase 700
python JDG/tools/ksef_jpk_edeklaracje_auditor.py --upo --invoice-count 10 --upo-received 8
python JDG/tools/ksef_jpk_edeklaracje_auditor.py --sanction-monitor --invoices-outside 6
python JDG/tools/ksef_jpk_edeklaracje_auditor.py --offline --offline-days 3 --offline-invoices 5
python JDG/tools/ksef_jpk_edeklaracje_auditor.py --gtu --gtu-hint paliwa
python JDG/tools/ksef_jpk_edeklaracje_auditor.py --firewall --anomaly "NIP invalid"
python JDG/tools/ksef_jpk_edeklaracje_auditor.py --jpk-cross --sales-register 10000 --vat-sales 10000
# Mapa drogowa P0/P1/P2:
python JDG/tools/ksef_jpk_edeklaracje_auditor.py --ksef-api --api-configured --ksef-number KSEF-123   # API KSeF (P0)
python JDG/tools/ksef_jpk_edeklaracje_auditor.py --xsd-ci --xsd-ci-ok                                 # walidator XSD CI (P0)
python JDG/tools/ksef_jpk_edeklaracje_auditor.py --corrections --corrections-pending 2                 # korekty 106j (P1)
python JDG/tools/ksef_jpk_edeklaracje_auditor.py --gtu-dict --gtu-hint energia                         # słownik GTU (P1)
python JDG/tools/ksef_jpk_edeklaracje_auditor.py --edelivery-b2b --mailbox-active --confirmations-ok   # e-Doręczenia (P1)
python JDG/tools/ksef_jpk_edeklaracje_auditor.py --ksef-dashboard --invoice-count 10 --upo-received 8  # dashboard (P2)
python JDG/tools/ksef_jpk_edeklaracje_auditor.py --jpk-cit --cit-blocks 4                             # JPK_CIT 2026 (P2)
```

## Testy

- Rego: `JDG/tests/rego/test_p17_ksef_jpk_edeklaracje_enterprise.rego` (45 scenariuszy: 32 bazowe + 13 nowych dla mapy drogowej P0/P1/P2)
- Pytest: `JDG/tests/auto/test_p17_ksef_jpk_edeklaracje_enterprise.py` (43 testy: 34 + 9 nowych dla mapy drogowej)

## Okablowanie

- `main_jdg.rego`: `import data.jdg.p17_ksef_jpk_edeklaracje_innovations` (PAS 18s), wpis w `_package_decisions`, `final_verdict_p17 = safe_merge(final_verdict_p16, ...)` — bez kolizji ze starym pakietem `jdg.p17_innovations` (v8 Edge Cases).
