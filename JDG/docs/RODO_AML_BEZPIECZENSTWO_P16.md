# P16 — RODO + AML + Compliance + Bezpieczeństwo + Audyt (Enterprise)

> **📌 Aktualizacja 2026-08-22:** dokument historyczny opisujący wdrożenie promptu GLM 5.2.
> Raporty źródłowe (`prompty_glm52/`, `raporty_glm52/`, `raporty_jdg_enterprise/`) zostały zarchiwizowane poza repo.
> Aktualny stan wdrożenia: [`KAMPANIA_GLM52_ETAPY_10_28.md`](KAMPANIA_GLM52_ETAPY_10_28.md) + `JDG/bundles/*audit_state.json` (certyfikacja końcowa ETAP 28 — 2026-08-22: 13/14 bramek `NIEPELNY`; domknięcie V4 2026-08-29: `WDROŻONY_100` 6/6).

Pakiet: `jdg.p16_rodo_aml_security_innovations`
Plik: `JDG/rules/p16_rodo_aml_security_innovations_v9.rego`
Raport: `raporty_glm52/raport_enterprise_P16.txt`
Narzędzie: `JDG/tools/rodo_aml_security_auditor.py`
Wersja: v9.7 (2026-08-09) — INN-15..19

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
| 6. Genius ideas (19) | INN-01..19: rejestr auto, breach 72h, scoring klient, scoring transakcja, forteca, proof-chain, self-audit, panel AML, asystent naruszeń, decision chain, HMAC reguł, kalkulator sankcji, UBO, scorecard, **aml_obligation_detector (15), rodo_by_design_anonymizer (16), rodo_request_workflow (17), penalty_simulator (18), dead_data_monitor (19)** | ✅ |
| 7. Mapa drogowa P0/P1/P2 (R16) | `crbr_registry_api`, `str_gijf_auto_submission`, `subprocessor_saas_map`, `rodo_deadline_calendar`, `aml_sanctions_screening`, `amlr_2027_implementation`, `compliance_dashboard_ui` — wszystkie 7 pozycji wdrożone | ✅ |

## Mapa drogowa P0/P1/P2 — wdrożone (R16, 2026-08-05)

| Priorytet | Pozycja | Reguła + narzędzie |
|---|---|---|
| P0 | integracja z rejestrem BDO/CRBR (beneficjenci rzeczywiści) via API | `crbr_registry_api` / `crbr_registry_check()` — endpoint CRBR, termin 7 dni od wpisu CEIDG/KRS, kara do 1 mln PLN |
| P0 | automatyczna wysyłka zgłoszeń STR do GIIF (API) + potwierdzenia | `str_gijf_auto_submission` / `str_gijf_submission()` — 1 dzień roboczy, UPO GIIF wymagane |
| P1 | pełna mapa podprocesorów SaaS (umowy Art. 28 + podpowierzenie) | `subprocessor_saas_map` / `subprocessor_saas_map()` — katalog 8 kategorii SaaS, score 0-100 |
| P1 | kalendarz terminów RODO (przeglądy, DPIA, umowy powierzenia) | `rodo_deadline_calendar` / `rodo_deadline_calendar()` — 6 pozycji cyklu rocznego |
| P1 | scoring AML z danymi rzeczywistymi (listy sankcyjne UE/ONZ) | `aml_sanctions_screening` / `aml_sanctions_screening()` — 5 list (EU/UN/OFAC/UK/PEP), wagi 20-50, BLOCK ≥50 |
| P2 | implementacja AMLR (UE 2024/1624) — progi CBDD od 2027 | `amlr_2027_implementation` / `amlr_2027_check()` — gotówka >10k EUR / krypto >1k EUR, od 2027-07-10 |
| P2 | UI panelu ryzyka AML + dashboard naruszeń RODO 72h | `compliance_dashboard_ui` / `compliance_dashboard()` — widgets + export JSON/CSV/PDF |

### Sekcja 8 — innowacje INN-15..19 (2026-08-09)

| Innowacja | Reguła | Efekt |
|---|---|---|
| INN-15 auto-wykrycie obowiązku AML wg PKD | `aml_obligation_detector` | kantory/faktoring/nieruchomości/doradcy/prawnicy/notariusze/kasyna/metale/dzieła → instytucja obowiązana (art. 2 ust. 1 u.AML) + 5 środków: CBDD, rejestr >15k EUR, CRBR 7 dni, polityka AML, STR |
| INN-16 RODO-by-design | `rodo_by_design_anonymizer` | werdykty bez PII (NIP/PESEL/name/email... wykrywane) — Decision Certificate bez danych osobowych, art. 5 ust. 1 lit. c |
| INN-17 auto-odpowiedzi na żądania RODO | `rodo_request_workflow` | szablony DOSTĘP/USUNIĘCIE/PRZENOSZALNOŚĆ/SPRZECIW + termin 30 dni + countdown + alert overdue |
| INN-18 symulator kar RODO/AML | `penalty_simulator` | co by było gdyby: RODO 20 mln EUR (art. 83) + AML 1 mln zł (art. 153) wg scenariusza |
| INN-19 monitor martwych danych | `dead_data_monitor` | retencja: księgowe 5 lat, pracownicze 50 lat, umowy 3-10 lat; alert DATA_RETENTION_ALERT przy wygasłych |

## Progi (ADR-002 — `data.jdg.thresholds.compliance_aml_rodo`)

- Sankcje RODO: 20 mln EUR / 4% obrotu (Art. 83 ust. 5) oraz 10 mln EUR / 2% (ust. 4)
- Zgłoszenie naruszenia: 72h (Art. 33 RODO)
- Erasure: 30 dni (Art. 17 RODO); retencja księgowa: 5 lat (Art. 74 UoR)
- AML: próg transakcyjny 15 000 EUR (Art. 34 u.AML); STR do GIIF — 1 dzień roboczy
- UBO: beneficjent rzeczywisty ≥ 25% udziałów; rejestracja CRBR w 7 dni od wpisu
- Kara AML: do 1 mln zł (art. 153 u.AML)
- Screening sankcyjny: 5 list (EU/UN/OFAC/UK/PEP), próg BLOCK 50 pkt
- AMLR 2027: gotówka > 10 000 EUR / krypto > 1 000 EUR — CBDD obowiązkowy od 2027-07-10

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
# Mapa drogowa P0/P1/P2:
python JDG/tools/rodo_aml_security_auditor.py --crbr --nip 7777777777                  # CRBR via API (P0)
python JDG/tools/rodo_aml_security_auditor.py --str-gijf --days-since 3                # STR do GIIF (P0)
python JDG/tools/rodo_aml_security_auditor.py --saas-map                              # podprocesorzy SaaS (P1)
python JDG/tools/rodo_aml_security_auditor.py --rodo-calendar --current-month 12      # kalendarz RODO (P1)
python JDG/tools/rodo_aml_security_auditor.py --sanctions-screen --entity-name "X" --matched-list eu_consolidated
python JDG/tools/rodo_aml_security_auditor.py --amlr --cash-eur 12000                 # AMLR 2027 (P2)
python JDG/tools/rodo_aml_security_auditor.py --dashboard --str-pending 1             # dashboard 72h (P2)

# ── SEKCJA 8: innowacje INN-15..19 ──
python JDG/tools/rodo_aml_security_auditor.py --aml-obligation --activity-desc "doradca podatkowy"  # INN-15 obowiązek AML wg PKD
python JDG/tools/rodo_aml_security_auditor.py --rodo-by-design --verdict-fields NIP --verdict-fields kwota  # INN-16 RODO-by-design
python JDG/tools/rodo_aml_security_auditor.py --rodo-request --request-type USUNIECIE --request-days 5    # INN-17 żądania RODO (30 dni)
python JDG/tools/rodo_aml_security_auditor.py --penalty-sim --scenario NO_STR                                # INN-18 symulator kar
python JDG/tools/rodo_aml_security_auditor.py --dead-data --expiring-30d 5 --expired 0                      # INN-19 monitor martwych danych
```

## Program insider threat (P59 doprecyzowanie)

- **Podwójna kontrola (dual control / 4-eyes)**: zmiany reguł krytycznych wymagają akceptacji dwóch ról (techniczna + prawna) — zasada `four_eyes_review` w kontrakcie operating.
- **Rotacja obowiązków**: zadania wrażliwe (deploy produkcyjny, zarządzanie sekretami, wyłączanie bramek) rotowane kwartalnie między co najmniej dwiema osobami; brak osoby zapasowej = NEEDS_ADVICE w P59.
- **Kanał zgłoszeń**: podejrzenie manipulacji/naruszenia → incydent wg playbooka (RODO art. 33–34, 72 h do UODO); rejestr zdarzeń w WORM.
- **Audyt nietypowych dostępów**: powiązany z hash chain WORM (P42) i telemetrią decyzji (P58); sygnał podejrzany = MANUAL_REVIEW.

## Testy

- Rego: `JDG/tests/rego/test_p16_rodo_aml_security_enterprise.rego` (**54** scenariusze: 43 + 11 INN-15..19)
- Pytest: `JDG/tests/auto/test_p16_rodo_aml_security_enterprise.py` (**47** testów: 40 + 7 INN-15..19 + parser import check)

## Okablowanie

- `main_jdg.rego`: `import data.jdg.p16_rodo_aml_security_innovations` (PAS 18r), wpis w `_package_decisions`, `final_verdict_p16 = safe_merge(final_verdict_p15, ...)` — bez kolizji ze starym pakietem `jdg.p16_innovations` (v8 Business Lifecycle).
