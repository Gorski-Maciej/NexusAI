# 🏛️ JDG ULTIMATE GRANULARITY — 672 Reguł ENTERPRISE

> **Status:** ENTERPRISE v11.0 — Maksymalna granulacja: każdy warunek logiczny = osobna reguła
> **Data:** 2026-07-11
> **Reguł:** **672** | **Pakietów:** 28 | **Domen prawnych:** 62
> **Format:** Reguły R0001-R0015 = pełny 10-polowy format ENTERPRISE (wzorzec referencyjny). Reguły R0016-R0672 = skompresowany format tabelaryczny (wszystkie kluczowe dane decyzyjne zachowane).
> **Filozofia:** 1 artykuł ustawy = 5-10 reguł. 1 ulga = 5+ reguł. 1 próg = 1 reguła. 1 termin = 1 reguła. 1 sankcja = 1 reguła. 1 edge case = 1 reguła.
>
> **Powiązane:** `34_JDG_DEFINITIVE_REGO_PLAN.md` (plan), `33_JDG_MASSIVE_RULE_CATALOG.md` (katalog 3 055 mikro-reguł), `35_JDG_ENTERPRISE_GAP_ANALYSIS.md` (78 luk), `36_JDG_ADVANCED_GAPS.md` (174 luki)
>
> **Numeracja reguł:** R0001–R0672 (ciągła, unikalna w całym systemie JDG)
> **P-mapowanie:** R0001-R0049 → P0-P9 (risk), R0050-R0099 → P10-P19 (routing), R0100-R0199 → P20-P157 (compliance), R0200-R0399 → P40-P235 (VAT), R0400-R0549 → P500-P599 (PIT), R0550-R0619 → P600-P635 (ulgi), R0620-R0672 → P700-P1895 (ZUS, księgowość, biznes, reszta)

---

## 📐 STRUKTURA OPISU KAŻDEJ REGUŁY

Każda reguła zawiera **10 obowiązkowych pól**:

| # | Pole | Opis |
|---|------|------|
| 1 | **R-ID** | Unikalny identyfikator (R0001–R0672) |
| 2 | **Nazwa** | `pakiet.nazwa_reguly` — angielska, zgodna z konwencją Rego |
| 3 | **Cel biznesowy** | 2-4 zdania: co reguła sprawdza i dlaczego jest krytyczna |
| 4 | **Przesłanki** | Rozbite warunki logiczne (każdy w osobnej linii) |
| 5 | **Rezultat** | Co zwraca: `matched`/`allow`/`deny`, konkretna wartość, decyzja |
| 6 | **Podstawa prawna** | Dokładny artykuł, ustęp, punkt + tekst jednolity |
| 7 | **Edge cases** | Scenariusze brzegowe i jak reguła na nie reaguje |
| 8 | **Zależności** | Które reguły muszą być sprawdzone wcześniej/poźniej |
| 9 | **Thresholds** | Parametry z `input.thresholds.jdg.*` |
| 10 | **Przykład ±** | Konkretny przykład pozytywny i negatywny |

---

## ⚡ QUICK INDEX — 672 Reguły w 28 Pakietach

| Pakiet | Reguły | R-ID zakres | Priorytet |
|--------|:------:|------------|:---------:|
| `jdg.risk` | 16 | R0001-R0016 | P0-P9 |
| `jdg.routing` | 12 | R0017-R0028 | P10-P19 |
| `jdg.compliance` | 22 | R0029-R0050 | P20-P39 |
| `jdg.crossborder` | 18 | R0051-R0068 | P40-P49 |
| `jdg.vat.substantive` | 42 | R0069-R0110 | P50-P65 |
| `jdg.vat.deductions` | 28 | R0111-R0138 | P183-P192 |
| `jdg.vat.procedures` | 22 | R0139-R0160 | P64-P235 |
| `jdg.vat.gtu` | 13 | R0161-R0173 | P65-P69 |
| `jdg.vat.baddebt` | 10 | R0174-R0183 | P60,P89a-P89b |
| `jdg.vat.ksef` | 14 | R0184-R0197 | P106na-P106nq |
| `jdg.pit.forms` | 24 | R0198-R0221 | P500-P539 |
| `jdg.pit.kup` | 32 | R0222-R0253 | P560-P582 |
| `jdg.pit.advances` | 18 | R0254-R0271 | P540-P559 |
| `jdg.pit.exemptions` | 16 | R0272-R0287 | P580-P588 |
| `jdg.pit.transitions` | 12 | R0288-R0299 | P590-P599 |
| `jdg.allowances` | 38 | R0300-R0337 | P600-P635 |
| `jdg.zus` | 34 | R0338-R0371 | P700-P770 |
| `jdg.accounting` | 28 | R0372-R0399 | P800-P870 |
| `jdg.business` | 20 | R0400-R0419 | P900-P939 |
| `jdg.corrections` | 16 | R0420-R0435 | P1100-P1138 |
| `jdg.liability` | 14 | R0436-R0449 | P1150-P1174 |
| `jdg.representation` | 10 | R0450-R0459 | P1200-P1212 |
| `jdg.local_taxes` | 10 | R0460-R0469 | P1300-P1320 |
| `jdg.international` | 14 | R0470-R0483 | P100-P117 |
| `jdg.employer` | 16 | R0484-R0499 | P1200e-P1223 |
| `jdg.environmental` | 8 | R0500-R0507 | P1400-P1407 |
| `jdg.restructuring` | 8 | R0508-R0515 | P1500-P1505 |
| `jdg.temporal` | 10 | R0516-R0525 | P1600-P1612 |
| `jdg.digital` | 8 | R0526-R0533 | P630-P1895 |
| `jdg.retention` | 6 | R0534-R0539 | P990-P992 |
| `jdg.fallback` | 6 | R0540-R0545 | P1000-P1099 |
| **EDGE CASES / INTERACTIONS** | **127** | R0546-R0672 | P340-P999 |

---

## 📦 1. `jdg.risk` — Ryzyko i Fraud (R0001-R0016)

### R0001: `jdg.risk.fraud_graph_match`
- **Cel:** Natychmiastowa blokada faktury od kontrahenta w sieci fraudowej VAT. Najwyższy priorytet. Zapobiega wyłudzeniom VAT.
- **Przesłanki:** `input.vendor.fraud_flag == true` AND `input.invoice.direction == "PURCHASE"`
- **Rezultat:** `matched:true`, `_routing:"BLOCK_AND_ALERT"`, `fraud_detected:true`, `vat_deduction_blocked:true`
- **Podstawa:** Art. 86 ust. 1 VAT, Art. 55 KKS
- **Edge cases:** Jeśli fraud_flag ustawione na kontrahencie który później został wykreślony z listy → reguła NIE matchuje (fraud_flag musi być aktualne w dacie transakcji)
- **Zależności:** FraudGraphScanner musi wcześniej oznaczyć vendor.fraud_flag. Ta reguła MUSI być pierwsza w całym łańcuchu.
- **Thresholds:** brak (reguła binarna)
- **Przykład +:** Kontrahent z fraud_flag=true → BLOCK_AND_ALERT, faktura odrzucona
- **Przykład −:** Kontrahent z fraud_flag=false → reguła nie matchuje, przechodzi dalej

### R0002: `jdg.risk.kks_empty_invoice_fraud`
- **Cel:** Blokada pustej faktury bez rzeczywistej dostawy. Przestępstwo skarbowe zagrożone karą do 25 lat.
- **Przesłanki:** `vendor.fraud_flag == true` AND `invoice.delivery_confirmed == false` AND `invoice.amount_gross > 0` AND `invoice.direction == "PURCHASE"`
- **Rezultat:** `matched:true`, `_routing:"BLOCK_AND_ALERT"`, `kks_risk:"Art.62_par2"`, `max_penalty:"25_lat"`
- **Podstawa:** Art. 62 § 2 KKS
- **Edge cases:** Faktura pro forma (amount_gross=0) → NIE matchuje. Faktura zaliczkowa przed dostawą → NIE matchuje (delivery oczekiwana).
- **Zależności:** Wymaga R0001 (fraud_graph_match) jako prerequisitu do ustawienia fraud_flag
- **Thresholds:** brak
- **Przykład +:** Faktura 50k PLN od fraud-kontrahenta, brak potwierdzenia dostawy → BLOCK
- **Przykład −:** Faktura 10k PLN, fraud_flag=false → NIE matchuje

### R0003: `jdg.risk.counterparty_trust_low`
- **Cel:** Kontrahent z niskim trust score → dodatkowa weryfikacja manualna przed zaksięgowaniem
- **Przesłanki:** `vendor.trust_score < thresholds.jdg.limits.trust_auto_post` (0.92) AND `vendor.trust_score > 0`
- **Rezultat:** `matched:true`, `_routing:"TRIAGE_QUEUE"`, `vendor_trust_score:<value>`
- **Podstawa:** Art. 22 UoR (zasada ostrożności)
- **Edge cases:** Nowy kontrahent bez historii → trust_score=0.5 (neutralny, poniżej progu → TRIAGE). Kontrahent z score=0 → nieznany (nie oceniany), NIE matchuje.
- **Zależności:** TrustScoreEngine musi wcześniej obliczyć vendor.trust_score
- **Thresholds:** `jdg.limits.trust_auto_post` (0.92)
- **Przykład +:** Trust score 0.75 → TRIAGE_QUEUE
- **Przykład −:** Trust score 0.95 → reguła NIE matchuje, auto-post

### R0004: `jdg.risk.anomaly_amount`
- **Cel:** Wykrycie anomalii kwotowej >3 odchylenia standardowe od średniej kategorii
- **Przesłanki:** `invoice.amount_net > (category_avg_amount + 3 * category_stddev_amount)` AND `category_stddev_amount > 0`
- **Rezultat:** `matched:true`, `_routing:"BLOCK_AND_ALERT"`, `_anomaly_zscore:<value>`
- **Podstawa:** Art. 22 UoR
- **Edge cases:** Kategoria z ≤5 transakcjami → stddev niereprezentatywne → NIE matchuje (category_stddev_amount == 0). Pierwsza transakcja w kategorii → NIE matchuje.
- **Zależności:** StatsAggregator musi dostarczyć category_avg_amount i category_stddev_amount
- **Thresholds:** `jdg.limits.anomaly_sigma` (3.0)
- **Przykład +:** Średnia kategorii 5 000 PLN, stddev 1 000 PLN, faktura 50 000 PLN → z-score=45 → BLOCK
- **Przykład −:** Średnia 5 000 PLN, stddev 2 000 PLN, faktura 8 000 PLN → z-score=1.5 → NIE matchuje

### R0005: `jdg.risk.new_counterparty_flag`
- **Cel:** Nowy kontrahent (pierwsza transakcja) → dodatkowa weryfikacja
- **Przesłanki:** `vendor.is_new == true` AND `invoice.direction == "PURCHASE"`
- **Rezultat:** `matched:true`, `_routing:"TRIAGE_QUEUE"`, `new_counterparty:true`
- **Podstawa:** Art. 22 UoR, AML
- **Edge cases:** Kontrahent z 1 transakcją 5 lat temu → nie jest "new" (is_new=false). Sprzedaż do nowego klienta (direction=SALE) → NIE matchuje (tylko zakupy).
- **Zależności:** CRM musi ustawić vendor.is_new przed ewaluacją
- **Thresholds:** brak
- **Przykład +:** Pierwsza faktura od kontrahenta XYZ → TRIAGE
- **Przykład −:** Kontrahent z 50 fakturami → NIE matchuje

### R0006: `jdg.risk.high_risk_country`
- **Cel:** Kontrahent z kraju wysokiego ryzyka podatkowego (tax haven) → blokada + alert TP
- **Przesłanki:** `vendor.country in thresholds.jdg.tax_haven_list` AND `invoice.amount_gross >= thresholds.jdg.limits.transfer_pricing_limit`
- **Rezultat:** `matched:true`, `_routing:"BLOCK_AND_ALERT"`, `transfer_pricing_alert:true`
- **Podstawa:** Art. 11a-11q CIT
- **Edge cases:** Kraj usunięty z listy tax haven w trakcie roku → obowiązuje stan na datę transakcji. Kwota poniżej progu TP → NIE matchuje.
- **Zależności:** Wymaga aktualnej listy tax_haven_list w thresholds
- **Thresholds:** `jdg.tax_haven_list`, `jdg.limits.transfer_pricing_limit`
- **Przykład +:** Kontrahent z Kajmanów, faktura 500k PLN → BLOCK + TP alert
- **Przykład −:** Kontrahent z Niemiec → NIE matchuje

### R0007: `jdg.risk.semantic_guard_disallowed`
- **Cel:** Wydatek niezwiązany z działalnością gospodarczą JDG → NKUP + BLOCK
- **Przesłanki:** `invoice.category_code in ["ALCOHOL","ENTERTAINMENT","LUXURY","PERSONAL_EXPENSE"]` OR `invoice.semantic_guard_result == "disallowed"`
- **Rezultat:** `matched:true`, `kus_qualification:"none"`, `_routing:"BLOCK_AND_ALERT"`
- **Podstawa:** Art. 23 ust. 1 pkt 23 PIT
- **Edge cases:** Alkohol na spotkanie biznesowe z kontrahentem → może być KUP jako reprezentacja (limit 0.025% przychodu). Personal expense typu "obiad w trakcie delegacji" → może być KUP.
- **Zależności:** SemanticGuard AI musi wcześniej sklasyfikować wydatek. Reguła po R0006.
- **Thresholds:** `jdg.limits.representation_percent` (0.025%)
- **Przykład +:** Faktura za whisky 500 PLN, category=ALCOHOL, expense_type!=REPRESENTATION → NKUP
- **Przykład −:** Faktura za laptop 5 000 PLN, category=IT_OFFICE → reguła NIE matchuje

### R0008: `jdg.risk.related_party_transaction`
- **Cel:** Transakcja z podmiotem powiązanym → obowiązek dokumentacji TP
- **Przesłanki:** `vendor.is_related_party == true` AND `invoice.amount_gross >= thresholds.jdg.limits.transfer_pricing_limit`
- **Rezultat:** `matched:true`, `transfer_pricing_required:true`, `tp_documentation_deadline:"end_of_tax_year_plus_10_months"`
- **Podstawa:** Art. 11a-11q CIT
- **Edge cases:** Podmiot powiązany przez małżonka → również TP. Transakcja poniżej progu → NIE matchuje, ale dokumentacja może być wymagana przy sumie transakcji.
- **Zależności:** Wymaga poprawnego oznaczenia is_related_party w danych kontrahenta
- **Thresholds:** `jdg.limits.transfer_pricing_limit`
- **Przykład +:** Brat JDG, faktura 300k PLN → TP required
- **Przykład −:** Obcy kontrahent, faktura 5k PLN → NIE matchuje

### R0009: `jdg.risk.kks_hidden_income_flag`
- **Cel:** Rozbieżność między wpływami na konto a deklarowanymi przychodami >30% → ryzyko ukrytych dochodów
- **Przesłanki:** `abs(entrepreneur.bank_deposits - entrepreneur.declared_revenue) / max(entrepreneur.declared_revenue, 1) > 0.30`
- **Rezultat:** `matched:true`, `_routing:"TRIAGE_QUEUE"`, `kks_risk:"Art.54_KKS"`, `discrepancy_percent:<value>`
- **Podstawa:** Art. 54 KKS
- **Edge cases:** Duży przelew prywatny (np. sprzedaż samochodu prywatnego) → fałszywy alarm. Wymaga oddzielenia kont firmowych od prywatnych.
- **Zależności:** BankAggregator + RevenueAggregator
- **Thresholds:** `jdg.limits.kks_discrepancy_threshold` (0.30)
- **Przykład +:** Wpływy 500k PLN, deklarowane 200k PLN → discrepancy=60% → TRIAGE
- **Przykład −:** Wpływy 210k PLN, deklarowane 200k PLN → discrepancy=5% → NIE matchuje

### R0010: `jdg.risk.kks_unreliable_books`
- **Cel:** Nierzetelna PKPiR — luki w numeracji, brak dat, niespójności → ryzyko KKS
- **Przesłanki:** `accounting.pkpir_integrity_score < thresholds.jdg.limits.pkpir_integrity_min` (0.70) AND `accounting.pkpir_entry_count > 0`
- **Rezultat:** `matched:true`, `_routing:"BLOCK_AND_ALERT"`, `kks_risk:"Art.56_KKS"`
- **Podstawa:** Art. 56 KKS, Art. 24a PIT
- **Edge cases:** Nowa PKPiR (pusta) → NIE matchuje (entry_count=0). Pierwszy miesiąc roku → niższy próg akceptacji.
- **Zależności:** PKPiRIntegrityChecker
- **Thresholds:** `jdg.limits.pkpir_integrity_min` (0.70)
- **Przykład +:** PKPiR z 50 wpisami, 15 braków numeracji, score=0.35 → BLOCK
- **Przykład −:** PKPiR z 200 wpisami, pełna numeracja, score=0.95 → NIE matchuje

### R0011: `jdg.risk.kks_vat_evidence_gap`
- **Cel:** Niekompletna ewidencja VAT — brakujące wpisy → ryzyko sankcji
- **Przesłanki:** `vat.evidence_completeness < thresholds.jdg.limits.vat_evidence_min` (0.90) AND `vat.evidence_expected_count > 0`
- **Rezultat:** `matched:true`, `_routing:"TRIAGE_QUEUE"`, `kks_risk:"Art.57_KKS"`
- **Podstawa:** Art. 57 KKS, Art. 109 VAT
- **Edge cases:** JDG na zwolnieniu podmiotowym → NIE matchuje (brak obowiązku ewidencji VAT). Okres zawieszenia → zerowa ewidencja oczekiwana.
- **Zależności:** VATEvidenceChecker
- **Thresholds:** `jdg.limits.vat_evidence_min` (0.90)
- **Przykład +:** Oczekiwano 100 wpisów VAT, znaleziono 75 → completeness=75% → TRIAGE
- **Przykład −:** 100% kompletności → NIE matchuje

### R0012: `jdg.risk.ceidg_vendor_suspended`
- **Cel:** Kontrahent z zawieszoną działalnością w CEIDG → ryzyko fraudu, brak prawa do odliczenia VAT
- **Przesłanki:** `vendor.ceidg_status == "SUSPENDED"` AND `invoice.transaction_date > vendor.suspension_date`
- **Rezultat:** `matched:true`, `_routing:"BLOCK_AND_ALERT"`, `ceidg_risk:true`
- **Podstawa:** Art. 88 VAT, Art. 22-25 Prawa przedsiębiorców
- **Edge cases:** Faktura wystawiona przed datą zawieszenia → NIE matchuje. Wznowienie po zawieszeniu → status=="ACTIVE" → NIE matchuje.
- **Zależności:** CEIDG API check przed ewaluacją
- **Thresholds:** brak
- **Przykład +:** Kontrahent zawieszony 2026-01-15, faktura z 2026-02-01 → BLOCK
- **Przykład −:** Kontrahent aktywny → NIE matchuje

### R0013: `jdg.risk.gaar_artificial_scheme`
- **Cel:** Wykrycie sztucznych struktur unikających opodatkowania (klauzula GAAR)
- **Przesłanki:** `vendor.is_related_party == true` AND `abs(invoice.amount_net - invoice.market_price) / invoice.market_price > thresholds.jdg.limits.gaar_price_deviation` (0.50) AND `invoice.amount_gross >= thresholds.jdg.limits.gaar_materiality`
- **Rezultat:** `matched:true`, `_routing:"BLOCK_AND_ALERT"`, `gaar_risk:true`, `gaar_risk_level:"HIGH"`
- **Podstawa:** Art. 119a § 1 Ordynacji podatkowej
- **Edge cases:** Uzasadniona ekonomicznie cena promocyjna → może być broniona przed GAAR. Udokumentowana wycena rynkowa → obniża ryzyko.
- **Zależności:** MarketDataService do ustalenia market_price
- **Thresholds:** `jdg.limits.gaar_price_deviation` (0.50), `jdg.limits.gaar_materiality`
- **Przykład +:** Cena rynkowa 100k PLN, faktura 5k PLN (95% poniżej rynku), podmiot powiązany → GAAR
- **Przykład −:** Cena 95k PLN vs rynek 100k PLN (5% odchylenie) → NIE matchuje

### R0014: `jdg.risk.duplicate_invoice_suspect`
- **Cel:** Podejrzenie duplikatu faktury — ten sam numer, ten sam kontrahent, zbliżona kwota
- **Przesłanki:** Istnieje już faktura z `invoice.invoice_number == existing.invoice_number` AND `invoice.vendor_nip == existing.vendor_nip` AND data w ciągu ±7 dni
- **Rezultat:** `matched:true`, `_routing:"BLOCK_AND_ALERT"`, `duplicate_detected:true`
- **Podstawa:** Art. 22 UoR, Art. 55 KKS
- **Edge cases:** Faktura korygująca (correction_flag=true) → NIE matchuje. Ten sam numer od różnych kontrahentów → NIE matchuje.
- **Zależności:** InvoiceRegistry do wykrywania duplikatów
- **Thresholds:** `jdg.limits.duplicate_date_window_days` (7)
- **Przykład +:** Faktura FV/2026/001 od kontrahenta X na 5k PLN, już istnieje FV/2026/001 od X → BLOCK
- **Przykład −:** Pierwsza faktura o danym numerze → NIE matchuje

### R0015: `jdg.risk.nip_format_invalid`
- **Cel:** NIP kontrahenta nie przechodzi walidacji formatu → blokada
- **Przesłanki:** `vendor.nip` nie spełnia formatu: 10 cyfr, poprawna suma kontrolna (wagi 6,5,7,2,3,4,5,6,7 mod 11)
- **Rezultat:** `matched:true`, `_routing:"BLOCK_AND_ALERT"`, `nip_invalid:true`
- **Podstawa:** Art. 96b VAT, Rozp. MF ws. NIP
- **Edge cases:** NIP zagraniczny (inny format) → NIE matchuje (osobna reguła dla VAT-EU). NIP "9999999999" → niepoprawna suma kontrolna → BLOCK.
- **Zależności:** Przed R0001 (fraud_graph_match — nie można sprawdzić fraudu bez poprawnego NIP)
- **Thresholds:** brak
- **Przykład +:** NIP "1234567890" → suma kontrolna OK → NIE matchuje
- **Przykład −:** NIP "1111111111" → błędna suma → BLOCK

### R0016: `jdg.risk.aml_pep_detection`
- **Cel:** Kontrahent jest Politically Exposed Person (PEP) → wzmożona weryfikacja AML
- **Przesłanki:** `vendor.is_pep == true` AND `invoice.amount_gross >= thresholds.jdg.limits.aml_pep_threshold`
- **Rezultat:** `matched:true`, `_routing:"TRIAGE_QUEUE"`, `aml_enhanced_due_diligence:true`
- **Podstawa:** Art. 46 AML
- **Edge cases:** PEP który przestał pełnić funkcję >12 miesięcy temu → NIE jest PEP. PEP + transakcja poniżej progu → NIE matchuje.
- **Zależności:** AML screening przed ewaluacją
- **Thresholds:** `jdg.limits.aml_pep_threshold`
- **Przykład +:** PEP, faktura 200k PLN → TRIAGE + enhanced DD
- **Przykład −:** Nie-PEP → NIE matchuje

---

## 📦 2. `jdg.routing` — Field Confidence (R0017-R0028)

### R0017: `jdg.routing.fc_vat_rate_low_scale`
- **Cel:** Niska pewność stawki VAT dla JDG na skali → blokada automatycznego księgowania
- **Przesłanki:** `entrepreneur.tax_form == "PIT_SCALE"` AND `confidence.fc_vat_rate < thresholds.jdg.fc_thresholds.pit_scale_vat_rate` (0.95) AND `confidence.fc_vat_rate > 0`
- **Rezultat:** `matched:true`, `_routing:"BLOCK_AND_ALERT"`, `low_confidence_field:"vat_rate"`
- **Podstawa:** Art. 22 UoR
- **Edge cases:** fc_vat_rate == 0 → pole nie zostało ocenione → NIE matchuje. Faktura bez VAT (zwolniona) → fc_vat_rate może być niskie ale to oczekiwane → kontekstowa walidacja.
- **Zależności:** OCR engine → field confidence. Po R0016, przed regułami VAT.
- **Thresholds:** `jdg.fc_thresholds.pit_scale_vat_rate` (0.95)
- **Przykład +:** fc_vat_rate=0.60 → BLOCK
- **Przykład −:** fc_vat_rate=0.98 → NIE matchuje

### R0018: `jdg.routing.fc_total_net_low_scale`
- **Cel:** Niska pewność kwoty netto dla JDG na skali
- **Przesłanki:** `entrepreneur.tax_form == "PIT_SCALE"` AND `confidence.fc_total_net < thresholds.jdg.fc_thresholds.pit_scale_total_net` (0.90) AND `confidence.fc_total_net > 0`
- **Rezultat:** `matched:true`, `_routing:"BLOCK_AND_ALERT"`
- **Podstawa:** Art. 22 UoR
- **Thresholds:** `jdg.fc_thresholds.pit_scale_total_net` (0.90)
- **Przykład +:** fc_total_net=0.55 → BLOCK
- **Przykład −:** fc_total_net=0.93 → NIE matchuje

### R0019: `jdg.routing.fc_vendor_nip_low`
- **Cel:** Niska pewność NIP kontrahenta → ryzyko błędnej weryfikacji Białej Listy
- **Przesłanki:** `confidence.fc_vendor_nip < thresholds.jdg.fc_thresholds.vendor_nip` (0.80) AND `confidence.fc_vendor_nip > 0`
- **Rezultat:** `matched:true`, `_routing:"BLOCK_AND_ALERT"`, `low_confidence_field:"vendor_nip"`
- **Podstawa:** Art. 96b VAT, Art. 22 UoR
- **Thresholds:** `jdg.fc_thresholds.vendor_nip` (0.80)
- **Przykład +:** fc_vendor_nip=0.45 → BLOCK
- **Przykład −:** fc_vendor_nip=0.92 → NIE matchuje

### R0020-R0028: `fc_linear_minimum`, `fc_lump_sum_vat_rate`, `fc_lump_sum_total_net`, `fc_mixed_auto_minimum`, `fc_representation_minimum`, `fc_category_code_low`, `fc_global_minimum_low`, `fc_invoice_date_low`, `fc_vat_rate_low_estonian`
- **Wzorzec wspólny:** Każda reguła sprawdza `confidence.fc_<field> < thresholds.jdg.fc_thresholds.<threshold>` dla odpowiedniej formy opodatkowania
- **Priorytety:** P14-P19 (malejąco)
- **Routing:** BLOCK_AND_ALERT dla pól krytycznych (vat_rate, vendor_nip, total_net), TRIAGE_QUEUE dla pól pomocniczych (category_code, minimum)
- **Szczegóły w tabeli:**

| R-ID | Reguła | Forma | Pole | Próg | Routing |
|------|--------|-------|------|------|---------|
| R0020 | `fc_linear_minimum` | LINEAR | fc_minimum | 0.85 | TRIAGE |
| R0021 | `fc_lump_sum_vat_rate` | LUMP_SUM | fc_vat_rate | 0.90 | BLOCK |
| R0022 | `fc_lump_sum_total_net` | LUMP_SUM | fc_total_net | 0.85 | BLOCK |
| R0023 | `fc_mixed_auto_minimum` | MIXED_AUTO | fc_minimum | 0.80 | BLOCK |
| R0024 | `fc_representation_minimum` | REPRESENTATION | fc_minimum | 0.75 | BLOCK |
| R0025 | `fc_category_code_low` | universal | fc_category_code | 0.70 | TRIAGE |
| R0026 | `fc_global_minimum_low` | universal | fc_minimum | 0.60 | TRIAGE |
| R0027 | `fc_invoice_date_low` | universal | fc_invoice_date | 0.80 | BLOCK |
| R0028 | `fc_vat_rate_low_estonian` | CIT_ESTONIAN | fc_vat_rate | 0.85 | BLOCK |

---

## 📦 3. `jdg.compliance` — Zgodność (R0029-R0050)

### R0029: `jdg.compliance.whitelist_missing_over_limit`
- **Cel:** Weryfikacja Białej Listy MF — blokada gdy kontrahent nie figuruje na WL dla przelewów ≥15 000 PLN
- **Przesłanki:** `invoice.amount_gross >= thresholds.jdg.limits.mpp_limit` (15 000) AND `vendor.on_whitelist == false` AND `invoice.payment_method != "CASH"`
- **Rezultat:** `matched:true`, `_routing:"BLOCK_AND_ALERT"`, `_warnings:["Brak na Białej Liście — odpowiedzialność solidarna"]`
- **Podstawa:** Art. 96b VAT, Art. 117ba Ordynacji
- **Edge cases:** Przelew na rachunek spoza WL → odpowiedzialność solidarna do wysokości VAT. Płatność gotówkowa → NIE objęte WL. Zgłoszenie ZAW-NR w 7 dni → zwalnia z sankcji.
- **Zależności:** WL API check przed ewaluacją. Po R0028, przed PIT/VAT.
- **Thresholds:** `jdg.limits.mpp_limit` (15 000)
- **Przykład +:** Faktura 20k PLN, kontrahent nie na WL → BLOCK
- **Przykład −:** Faktura 10k PLN → poniżej progu → NIE matchuje

### R0030: `jdg.compliance.whitelist_account_mismatch`
- **Cel:** Rachunek bankowy kontrahenta niezgodny z Białą Listą
- **Przesłanki:** `invoice.amount_gross >= 15000` AND `vendor.account_on_whitelist == false` AND `vendor.on_whitelist == true`
- **Rezultat:** `matched:true`, `_routing:"BLOCK_AND_ALERT"`
- **Podstawa:** Art. 117ba § 1 Ordynacji
- **Przykład +:** Kontrahent na WL, ale przelew na inny rachunek → BLOCK
- **Przykład −:** Rachunek zgodny z WL → NIE matchuje

### R0031: `jdg.compliance.whitelist_check_expired`
- **Cel:** Weryfikacja WL starsza niż 30 dni → wymagane ponowne sprawdzenie
- **Przesłanki:** `now() - vendor.whitelist_check_date > 30 days` AND `invoice.amount_gross >= 15000`
- **Rezultat:** `matched:true`, `_routing:"TRIAGE_QUEUE"`, `whitelist_recheck_required:true`
- **Podstawa:** Art. 96b VAT
- **Thresholds:** `jdg.limits.whitelist_check_validity_days` (30)
- **Przykład +:** Ostatnia weryfikacja WL 45 dni temu → TRIAGE
- **Przykład −:** Weryfikacja 5 dni temu → NIE matchuje

### R0032: `jdg.compliance.split_payment_mandatory`
- **Cel:** Obowiązkowy MPP dla faktur ≥15k PLN brutto z towarami/usługami z załącznika nr 15
- **Przesłanki:** `invoice.amount_gross >= thresholds.jdg.limits.mpp_limit` (15 000) AND `invoice.category_code in thresholds.jdg.mpp_sensitive_categories`
- **Rezultat:** `matched:true`, `mpp_required:true`, `_warnings:["Obowiązkowy MPP"]`
- **Podstawa:** Art. 108a VAT
- **Edge cases:** Częściowa płatność <15k → nie ma obowiązku MPP. Transakcja B2C → NIE objęte MPP. Faktura w walucie obcej → przeliczenie wg kursu NBP.
- **Zależności:** Lista mpp_sensitive_categories musi być aktualna (28 kategorii z zał. 15)
- **Thresholds:** `jdg.limits.mpp_limit`, `jdg.mpp_sensitive_categories`
- **Przykład +:** Faktura 50k PLN za paliwo → MPP required
- **Przykład −:** Faktura 10k PLN za paliwo → NIE matchuje

### R0033: `jdg.compliance.split_payment_voluntary_safe_harbor`
- **Cel:** Dobrowolny MPP → zwolnienie z odpowiedzialności solidarnej
- **Przesłanki:** `invoice.voluntary_split_payment_used == true` AND `invoice.amount_gross < thresholds.jdg.limits.mpp_limit`
- **Rezultat:** `matched:true`, `joint_vat_liability_exempt:true`, `mpp_voluntary_safe_harbor:true`
- **Podstawa:** Art. 108a ust. 1d VAT
- **Przykład +:** Faktura 8k PLN, dobrowolny MPP → safe harbor
- **Przykład −:** Brak MPP → NIE matchuje

### R0034: `jdg.compliance.cash_transaction_over_limit`
- **Cel:** Płatność gotówkowa ≥15k PLN → brak KUP
- **Przesłanki:** `invoice.is_cash_payment == true` AND `invoice.amount_gross >= thresholds.jdg.limits.cash_transaction_limit` (15 000)
- **Rezultat:** `matched:true`, `kus_qualification:"none"`, `_warnings:["Brak KUP — płatność gotówkowa ≥15 000 PLN"]`
- **Podstawa:** Art. 22p PIT
- **Edge cases:** Płatność mieszana (część gotówka, część przelew) → całość traktowana jak gotówka jeśli suma ≥15k. Kilka faktur tego samego dnia do tego samego kontrahenta → agregacja!
- **Zależności:** Po R0033, przed regułami KUP
- **Thresholds:** `jdg.limits.cash_transaction_limit` (15 000)
- **Przykład +:** Faktura 20k PLN gotówką → NKUP
- **Przykład −:** Faktura 5k PLN gotówką → KUP zachowane

### R0035: `jdg.compliance.cash_daily_aggregate_15k`
- **Cel:** Łączny limit 15k PLN dziennie dla jednego kontrahenta (agregacja wielu faktur)
- **Przesłanki:** Suma wszystkich faktur gotówkowych dla kontrahenta X w dniu Y ≥ 15 000 PLN
- **Rezultat:** `matched:true`, `kus_qualification:"none"`, `aggregated_amount:<suma>`
- **Podstawa:** Art. 22p PIT
- **Edge cases:** Faktury wystawione różnymi datami ale zapłacone tego samego dnia → agregacja. Różne kontrahenty → osobne limity.
- **Thresholds:** `jdg.limits.cash_transaction_limit` (15 000)
- **Przykład +:** 3 faktury po 6k PLN do kontrahenta X, zapłacone gotówką tego samego dnia → wszystkie NKUP
- **Przykład −:** 2 faktury po 7k PLN do różnych kontrahentów → każda poniżej 15k → KUP OK

### R0036-R0050: Pozostałe compliance (cash_giif_15k_eur, cash_sanction_20pct, vat_r_registration_status, ksef_structured_mandatory_jdg, ksef_b2c_exemption, ksef_offline_recovery, cash_register_b2c_exemption_20k, cash_register_breach_mid_year_2months, cesop_cross_border_reporting, vat_simplified_receipt_450pln, platform_app_store_export, platform_upwork_import, payment_after_due_date, statute_of_limitations_approaching, vat_on_import_consent)

| # | R-ID | Reguła | P | Art. | Kluczowy warunek |
|---|------|--------|---|------|------------------|
| 36 | R0036 | `cash_reporting_giif_15k_eur` | P392 | Art. 72 AML | Transakcja >15k EUR → raport GIIF |
| 37 | R0037 | `cash_sanction_kup_loss_20pct` | P393 | Art. 22p PIT | Gotówka >15k → NKUP + sankcja 20% |
| 38 | R0038 | `vat_r_registration_mandatory` | P39 | Art. 96 VAT | VAT-R przed pierwszą czynnością |
| 39 | R0039 | `ksef_structured_mandatory_jdg` | P950 | Art. 106na VAT | Obowiązek KSeF od 01.02.2026 |
| 40 | R0040 | `ksef_b2c_exemption_jdg` | P952 | Art. 106ga VAT | B2C → zwolnienie z KSeF |
| 41 | R0041 | `ksef_offline_recovery_7days` | P953 | Art. 106ne VAT | Awaria KSeF → 7 dni na nadrobienie |
| 42 | R0042 | `cash_register_b2c_exemption_20k` | P145 | Rozp. MF kasy | Limit 20k PLN B2C → zwolnienie |
| 43 | R0043 | `cash_register_breach_mid_year` | P575 | Rozp. MF § 3 | Przekroczenie 20k → kasa w 2 mies. |
| 44 | R0044 | `cesop_cross_border_payment` | P155 | Rozp. 2020/284 | >25k EUR rocznie → CESOP |
| 45 | R0045 | `vat_simplified_receipt_450pln` | P36 | Art. 106e VAT | Paragon z NIP ≤450 PLN → faktura uproszczona |
| 46 | R0046 | `platform_app_store_b2b_export` | P143 | Art. 28b VAT | App Store → eksport usług B2B, NP |
| 47 | R0047 | `platform_upwork_import_services` | P144 | Art. 28b VAT | Upwork/Fiverr → import usług, reverse charge |
| 48 | R0048 | `payment_after_due_date_interest` | P38 | Art. 56 Ordynacji | Płatność po terminie → odsetki |
| 49 | R0049 | `statute_limitations_approaching` | P39 | Art. 70 Ordynacji | Przedawnienie za <6 mies. → alert |
| 50 | R0050 | `vat_on_import_consent_required` | P26 | Art. 33a VAT | Import → zgoda na odliczenie VAT |

---

## 📦 4. `jdg.crossborder` — Transgraniczne (R0051-R0068)

### R0051: `jdg.crossborder.eu_reverse_charge_wnt`
- **Cel:** WNT — VAT rozlicza nabywca (reverse charge), sprzedawca 0%
- **Przesłanki:** `vendor.country in EU_COUNTRIES` AND `vendor.vat_status == "active"` AND `invoice.procedure == "WNT"`
- **Rezultat:** `vat_rate:"0.00"`, `procedure:"VAT_REVERSE_CHARGE"`, `gtu_code:"GTU_12"`
- **Podstawa:** Art. 17 ust. 1 pkt 3 VAT
- **Edge cases:** Kontrahent z VAT-EU ale towar fizycznie w PL → WNT. Usługa B2B z UE → nie WNT tylko import usług.
- **Thresholds:** `jdg.eu_countries_list`
- **Przykład +:** Kontrahent z Niemiec (VAT-EU active), procedura WNT → reverse charge
- **Przykład −:** Kontrahent z PL → NIE matchuje

### R0052: `jdg.crossborder.eu_import_services_b2b`
- **Cel:** Import usług B2B z UE — VAT rozlicza nabywca (Art. 28b)
- **Przesłanki:** `vendor.country in EU_COUNTRIES` AND `invoice.category in ["SERVICES","IT","CONSULTING"]` AND `invoice.direction == "PURCHASE"`
- **Rezultat:** `vat_rate:"0.00"` (NP), `procedure:"IMPORT_SERVICES"`, `vat_reverse_charge:true`
- **Podstawa:** Art. 28b VAT
- **Przykład +:** Usługa marketingowa z Niemiec → reverse charge, JDG rozlicza VAT
- **Przykład −:** Towary z Niemiec → WNT (R0051), nie import usług

### R0053-R0068: Crossborder compact

| # | R-ID | Reguła | P | Art. | Kluczowy warunek |
|---|------|--------|---|------|------------------|
| 53 | R0053 | `wdt_intracommunity_supply_0pct` | P42 | Art. 42 VAT | Sprzedaż do UE + VAT-UE nabywcy → 0% |
| 54 | R0054 | `wdt_vat_refund_accelerated_25days` | P42b | Art. 87 VAT | WDT → przyśpieszony zwrot 25 dni |
| 55 | R0055 | `wdt_documentation_evidence_required` | P42c | Art. 42 ust. 1 VAT | Brak CMR → utrata stawki 0% |
| 56 | R0056 | `import_non_eu_goods_23pct` | P45 | Art. 17 ust. 1 pkt 1 | NON-EU towary → 23% + IMPORT |
| 57 | R0057 | `import_non_eu_services_b2b` | P450 | Art. 17 ust. 1 pkt 4 | NON-EU usługi B2B → reverse charge |
| 58 | R0058 | `import_non_eu_services_b2c` | P451 | Art. 28k VAT | NON-EU usługi B2C → VAT należny w PL |
| 59 | R0059 | `export_goods_0pct` | P48 | Art. 41 ust. 4-11 | Eksport poza UE → 0% VAT |
| 60 | R0060 | `export_services_b2b_0pct` | P141 | Art. 28b VAT | IT/consulting B2B do UE → NP |
| 61 | R0061 | `triangular_transaction_simplified` | P49b | Art. 135-138 VAT | Trójstronna uproszczona: 3× VAT-UE |
| 62 | R0062 | `triangular_transaction_standard` | P49 | Art. 135 VAT | Trójstronna standardowa |
| 63 | R0063 | `import_services_tax_point_receipt` | P452 | Art. 19a VAT | Data wykonania lub zapłaty (wcześniejsza) |
| 64 | R0064 | `import_services_fx_rate_nbp_previous` | P453 | Art. 31a VAT | Kurs NBP z dnia poprzedzającego |
| 65 | R0065 | `import_services_tax_base_net` | P454 | Art. 29a VAT | Podstawa = kwota netto należna dostawcy |
| 66 | R0066 | `vat_ue_summary_deadline_25th` | P255 | Art. 100 VAT | VAT-UE do 25. dnia miesiąca |
| 67 | R0067 | `oss_ioss_procedure_b2c_eu` | P250 | Art. 130a-130d VAT | Sprzedaż B2C UE → OSS deklaracja |
| 68 | R0068 | `ioss_import_150eur_threshold` | P68 | Art. 138a VAT | Import ≤150 EUR → IOSS |

---

## 📦 5. `jdg.vat.substantive` — Stawki VAT (R0069-R0110)

### R0069: `jdg.vat.substantive.margin_scheme`
- **Cel:** Procedura VAT-marża dla towarów używanych, dzieł sztuki, antyków
- **Przesłanki:** `invoice.procedure == "MARGIN"` AND `invoice.category in ["USED_GOODS","ARTWORKS","ANTIQUES","COLLECTORS"]`
- **Rezultat:** `vat_rate:helpers.get_rate("vat_standard")`, `procedure:"MARGIN"`, `vat_base:"MARGIN"`
- **Podstawa:** Art. 120 VAT
- **Edge cases:** Import towarów używanych → NIE można marży. Faktura VAT-marża → zakaz wykazywania VAT osobno.
- **Thresholds:** `jdg.rates.vat_standard` (0.23)
- **Przykład +:** Skup i sprzedaż używanych telefonów → VAT-marża
- **Przykład −:** Nowy towar → NIE matchuje

### R0070-R0099: Stawki VAT wg kategorii — 30 reguł

Każda kategoria towaru/usługi → osobna reguła z własną stawką, GTU i warunkami.

| # | R-ID | Reguła | Kat. | VAT | GTU | Art. | Dodatkowe warunki |
|---|------|--------|------|:---:|-----|------|-------------------|
| 70 | R0070 | `vat_rate_fuel_pl_23` | FUEL | 23% | GTU_04 | Art. 41 ust. 1 | vendor.country=="PL" |
| 71 | R0071 | `vat_rate_food_basic_5` | FOOD_BASIC | 5% | GTU_07 | Art. 41 ust. 2a | Załącznik nr 10 |
| 72 | R0072 | `vat_rate_food_luxury_23` | FOOD_LUXURY | 23% | — | Art. 41 ust. 1 | Kawiorem, homary, itp. |
| 73 | R0073 | `vat_rate_books_print_5` | BOOKS_PRINT | 5% | GTU_01 | Art. 41 ust. 2a | ISBN required |
| 74 | R0074 | `vat_rate_ebooks_digital_5` | EBOOKS | 5% | GTU_01 | Art. 41 ust. 2a | Od 01.11.2019 |
| 75 | R0075 | `vat_rate_water_sewage_8` | WATER | 8% | — | Art. 41 ust. 2 | Załącznik nr 3 |
| 76 | R0076 | `vat_rate_pharma_drugs_8` | PHARMA | 8% | GTU_09 | Art. 41 ust. 2 | Leki, wyroby medyczne |
| 77 | R0077 | `vat_rate_medical_equipment_8` | MEDICAL_EQUIP | 8% | — | Art. 41 ust. 2 | Sprzęt medyczny |
| 78 | R0078 | `vat_rate_hotel_8` | HOTEL | 8% | — | Art. 41 ust. 2 | Noclegi, hotele |
| 79 | R0079 | `vat_rate_construction_residential_8` | CONSTR_RESID | 8% | GTU_08 | Art. 41 ust. 12 | Budownictwo mieszkaniowe ≤150m² |
| 80 | R0080 | `vat_rate_construction_commercial_23` | CONSTR_COMM | 23% | GTU_08 | Art. 41 ust. 1 | Budownictwo komercyjne |
| 81 | R0081 | `vat_rate_electronics_23` | ELECTRONICS | 23% | GTU_01 | Art. 41 ust. 1 | RTV, AGD, komputery |
| 82 | R0082 | `vat_rate_it_services_23` | IT_SERVICES | 23% | GTU_01 | Art. 41 ust. 1 | Programowanie, hosting |
| 83 | R0083 | `vat_rate_consulting_23` | CONSULTING | 23% | — | Art. 41 ust. 1 | Doradztwo, prawo, księgowość |
| 84 | R0084 | `vat_rate_transport_23` | TRANSPORT | 23% | GTU_06 | Art. 41 ust. 1 | Transport, logistyka |
| 85 | R0085 | `vat_rate_vehicles_23` | VEHICLES | 23% | — | Art. 41 ust. 1 | Samochody, pojazdy |
| 86 | R0086 | `vat_rate_alcohol_tobacco_23` | ALCOHOL_TOBACCO | 23% | GTU_02 | Art. 41 ust. 1 | + akcyza |
| 87 | R0087 | `vat_rate_real_estate_new_23` | REAL_ESTATE_NEW | 23% | GTU_10 | Art. 41 ust. 1 | Przed pierwszym zasiedleniem |
| 88 | R0088 | `vat_rate_real_estate_existing_zw` | REAL_ESTATE_OLD | ZW | — | Art. 43 ust. 1 pkt 10 | Po pierwszym zasiedleniu |
| 89 | R0089 | `vat_rate_rental_residential_zw` | RENTAL_RESID | ZW | — | Art. 43 ust. 1 pkt 36 | Wynajem mieszkalny |
| 90 | R0090 | `vat_rate_rental_short_term_23` | RENTAL_SHORT | 23% | — | Art. 41 ust. 1 | Airbnb, krótki wynajem |
| 91 | R0091 | `vat_rate_clothing_23` | CLOTHING | 23% | — | Art. 41 ust. 1 | Odzież, obuwie |
| 92 | R0092 | `vat_rate_furniture_23` | FURNITURE | 23% | — | Art. 41 ust. 1 | Meble |
| 93 | R0093 | `vat_rate_advertising_23` | ADVERTISING | 23% | — | Art. 41 ust. 1 | Reklama, marketing |
| 94 | R0094 | `vat_rate_cleaning_23` | CLEANING | 23% | — | Art. 41 ust. 1 | Sprzątanie |
| 95 | R0095 | `vat_rate_security_23` | SECURITY | 23% | — | Art. 41 ust. 1 | Ochrona |
| 96 | R0096 | `vat_rate_telecom_23` | TELECOM | 23% | — | Art. 41 ust. 1 | Telekomunikacja |
| 97 | R0097 | `vat_rate_insurance_zw` | INSURANCE | ZW | — | Art. 43 ust. 1 pkt 37 | Ubezpieczenia |
| 98 | R0098 | `vat_rate_finance_zw` | FINANCE | ZW | — | Art. 43 ust. 1 pkt 38-41 | Usługi finansowe |
| 99 | R0099 | `vat_rate_postal_zw` | POSTAL | ZW | — | Art. 43 ust. 1 pkt 17 | Usługi pocztowe |

### R0100-R0110: Zwolnienia przedmiotowe VAT — 11 reguł

| # | R-ID | Reguła | Przedmiot | Art. |
|---|------|--------|-----------|------|
| 100 | R0100 | `vat_exemption_education` | Edukacja, szkoły, korepetycje | Art. 43 ust. 1 pkt 26-29 |
| 101 | R0101 | `vat_exemption_healthcare_doctors` | Lekarze, dentyści | Art. 43 ust. 1 pkt 18 |
| 102 | R0102 | `vat_exemption_healthcare_nurses` | Pielęgniarki, położne | Art. 43 ust. 1 pkt 19 |
| 103 | R0103 | `vat_exemption_healthcare_rehab` | Fizjoterapia, rehabilitacja | Art. 43 ust. 1 pkt 20 |
| 104 | R0104 | `vat_exemption_psychology` | Psychologowie, psychoterapeuci | Art. 43 ust. 1 pkt 21 |
| 105 | R0105 | `vat_exemption_social_welfare` | Opieka społeczna, żłobki | Art. 43 ust. 1 pkt 22-25 |
| 106 | R0106 | `vat_exemption_culture_noncommercial` | Muzea, teatry, biblioteki | Art. 43 ust. 1 pkt 33 |
| 107 | R0107 | `vat_exemption_sport_noncommercial` | Sport niekomercyjny (kluby) | Art. 43 ust. 1 pkt 32 |
| 108 | R0108 | `vat_exemption_dental_technicians` | Protetyka, technicy dentystyczni | Art. 43 ust. 1 pkt 14 |
| 109 | R0109 | `vat_exemption_subject_jdg_200k` | Zwolnienie podmiotowe JDG <200k | Art. 113 ust. 1 |
| 110 | R0110 | `vat_exemption_subject_proportion_new` | Proporcjonalny limit dla nowych JDG | Art. 113 ust. 9 |

---

## 📦 6. `jdg.vat.deductions` — Odliczenia VAT (R0111-R0138)

### R0111-R0138: 28 szczegółowych reguł odliczeń VAT

| # | R-ID | Reguła | Art. | Kluczowy warunek | Rezultat |
|---|------|--------|------|------------------|----------|
| 111 | R0111 | `deduction_right_general` | Art. 86 ust. 1 | Zakup związany z czynnościami opodatkowanymi | Prawo do odliczenia |
| 112 | R0112 | `deduction_vat_payer_only` | Art. 86 ust. 1 | Tylko czynny podatnik VAT | Warunek podmiotowy |
| 113 | R0113 | `deduction_invoice_possession` | Art. 86 ust. 2 | Faktura VAT w posiadaniu | Warunek formalny |
| 114 | R0114 | `deduction_invoice_incorrect_nip_block` | Art. 88 ust. 3a | Błędny NIP na fakturze | BRAK odliczenia |
| 115 | R0115 | `deduction_proportion_mixed_activity` | Art. 90 ust. 1 | Działalność mieszana | Proporcja % |
| 116 | R0116 | `deduction_proportion_estimated_previous_year` | Art. 90 ust. 4 | Proporcja wstępna z roku poprz. | Wstępna |
| 117 | R0117 | `deduction_proportion_annual_correction` | Art. 91 ust. 1 | Korekta roczna proporcji | Ostateczna |
| 118 | R0118 | `deduction_proportion_de_minimis_2pct` | Art. 90 ust. 10 | Proporcja <2% | 0% odliczenia |
| 119 | R0119 | `deduction_proportion_full_98pct` | Art. 90 ust. 10 | Proporcja >98% | 100% odliczenia |
| 120 | R0120 | `deduction_wnt_reverse_charge` | Art. 86 ust. 2 pkt 4 | WNT → VAT należny = naliczony | Odliczenie WNT |
| 121 | R0121 | `deduction_import_services_b2b` | Art. 86 ust. 2 pkt 4 | Import usług B2B | Reverse charge |
| 122 | R0122 | `deduction_blocked_hotel_services` | Art. 88 ust. 1 pkt 4 | Noclegi, hotele | BRAK odliczenia |
| 123 | R0123 | `deduction_blocked_restaurant` | Art. 88 ust. 1 pkt 4 | Gastronomia (oprócz cateringu) | BRAK odliczenia |
| 124 | R0124 | `deduction_blocked_fuel_car_mixed` | Art. 88 ust. 1 pkt 3 | Paliwo do aut mieszanych | BRAK odliczenia |
| 125 | R0125 | `deduction_blocked_personal_use` | Art. 88 ust. 1 pkt 1 | Cele osobiste JDG | BRAK odliczenia |
| 126 | R0126 | `deduction_blocked_no_invoice` | Art. 88 ust. 1 pkt 2 | Zakup bez faktury | BRAK odliczenia |
| 127 | R0127 | `deduction_blocked_gifts_over_20pln` | Art. 88 ust. 1 pkt 5 | Prezenty >20 PLN | BRAK odliczenia |
| 128 | R0128 | `car_vat_deduction_50pct_no_evidence` | Art. 86a ust. 1 | Auto mieszane bez ewidencji | 50% VAT |
| 129 | R0129 | `car_vat_deduction_100pct_evidence` | Art. 86a ust. 5 | Ewidencja → tylko firmowe | 100% VAT |
| 130 | R0130 | `car_vat_100pct_taxi_delivery` | Art. 86a ust. 4 | Taxi, przewóz, dostawa | 100% VAT |
| 131 | R0131 | `car_vat_fuel_50pct_mixed` | Art. 86a ust. 1 | Paliwo do auta mieszanego | 50% VAT |
| 132 | R0132 | `car_vat_mileage_log_mandatory_fields` | Art. 86a ust. 7 | Ewidencja: data, trasa, cel, km | Wymagane pola |
| 133 | R0133 | `deduction_deadline_3_months` | Art. 86 ust. 11 | Termin odliczenia: 3 mies. od faktury | Termin |
| 134 | R0134 | `deduction_deadline_extended_wnt` | Art. 86 ust. 11 | WNT: 3 mies. od powstania obowiązku | Termin WNT |
| 135 | R0135 | `deduction_correction_annual_5years` | Art. 91 ust. 2 | ŚT ruchome: korekta 5 lat | Korekta roczna |
| 136 | R0136 | `deduction_correction_annual_10years` | Art. 91 ust. 2 | Nieruchomości: korekta 10 lat | Korekta roczna |
| 137 | R0137 | `deduction_pre_pro_rata_calculation` | Art. 86 ust. 2a | Pre-proporcja (sposób określenia) | Pre-proporcja |
| 138 | R0138 | `deduction_blocked_entertainment` | Art. 88 ust. 1 pkt 4 | Rozrywka, reprezentacja | BRAK odliczenia |

---

## 📦 7. `jdg.vat.procedures` + `jdg.vat.gtu` + `jdg.vat.baddebt` + `jdg.vat.ksef` (R0139-R0197)

### R0139-R0160: Procedury VAT — 22 reguły

| # | R-ID | Reguła | Art. | Kluczowy warunek |
|---|------|--------|------|------------------|
| 139 | R0139 | `vat_tax_point_general_delivery` | Art. 19a ust. 1 | Data wydania towaru |
| 140 | R0140 | `vat_tax_point_service_completed` | Art. 19a ust. 1 | Data wykonania usługi |
| 141 | R0141 | `vat_tax_point_invoice_before_delivery` | Art. 19a ust. 1 | Faktura przed dostawą → data faktury |
| 142 | R0142 | `vat_tax_point_payment_before_delivery` | Art. 19a ust. 8 | Zapłata przed dostawą → data zapłaty |
| 143 | R0143 | `vat_tax_point_30days_after_delivery` | Art. 19a ust. 1 | Faktura >30 dni po → 30. dzień |
| 144 | R0144 | `vat_tax_point_continuous_service_end` | Art. 19a ust. 3 | Usługi ciągłe → koniec okresu |
| 145 | R0145 | `vat_tax_point_construction_acceptance` | Art. 19a ust. 2 | Budowlane → data protokołu |
| 146 | R0146 | `vat_tax_point_wnt_15th_day` | Art. 20 ust. 5 | WNT → 15. dzień miesiąca |
| 147 | R0147 | `vat_tax_point_wnt_invoice_before` | Art. 20 ust. 5 | Faktura WNT przed 15. dniem |
| 148 | R0148 | `vat_cash_accounting_eligibility_small` | Art. 21 ust. 1 | Mały podatnik (<2M EUR) |
| 149 | R0149 | `vat_cash_accounting_tax_point_payment` | Art. 21 ust. 1 | Metoda kasowa → data zapłaty |
| 150 | R0150 | `vat_cash_accounting_deduction_payment` | Art. 21 ust. 4 | Odliczenie w dacie zapłaty |
| 151 | R0151 | `vat_margin_scheme_used_goods` | Art. 120 ust. 4 | Towary używane → marża |
| 152 | R0152 | `vat_margin_scheme_artworks` | Art. 120 ust. 4-5 | Dzieła sztuki → marża |
| 153 | R0153 | `vat_margin_scheme_antiques` | Art. 120 ust. 4 | Antyki, kolekcjonerskie → marża |
| 154 | R0154 | `vat_margin_scheme_global_method` | Art. 120 ust. 4 | Metoda globalna per okres |
| 155 | R0155 | `vat_margin_scheme_invoice_no_vat` | Art. 106e ust. 1 pkt 18a | Faktura VAT-marża: zakaz wykazywania VAT |
| 156 | R0156 | `vat_margin_import_excluded` | Art. 120 ust. 4 | Import → NIE marża |
| 157 | R0157 | `vat_farmer_rr_purchase_invoice` | Art. 115-118 | Rolnik ryczałtowy → VAT RR 7% |
| 158 | R0158 | `vat_farmer_rr_payment_14days` | Art. 116 ust. 6 | Zapłata przelewem w 14 dni |
| 159 | R0159 | `vat_reverse_charge_construction` | Art. 17 ust. 1 pkt 8 | Podwykonawstwo budowlane |
| 160 | R0160 | `vat_reverse_charge_gas_electricity` | Art. 17 ust. 1 pkt 7 | Gaz, energia elektryczna |

### R0161-R0173: GTU — 13 reguł mapowania

| # | R-ID | Reguła | GTU | Kategoria |
|---|------|--------|-----|-----------|
| 161 | R0161 | `gtu_01_electronics_it` | GTU_01 | Elektronika, IT, oprogramowanie |
| 162 | R0162 | `gtu_02_alcohol` | GTU_02 | Alkohol ≥18% |
| 163 | R0163 | `gtu_03_alcohol_low` | GTU_03 | Alkohol <18%, piwo |
| 164 | R0164 | `gtu_04_fuel` | GTU_04 | Paliwa, oleje napędowe |
| 165 | R0165 | `gtu_05_steel_scrap` | GTU_05 | Stal, złom, metale |
| 166 | R0166 | `gtu_06_transport` | GTU_06 | Transport, logistyka |
| 167 | R0167 | `gtu_07_food` | GTU_07 | Żywność |
| 168 | R0168 | `gtu_08_construction` | GTU_08 | Budownictwo |
| 169 | R0169 | `gtu_09_pharma` | GTU_09 | Farmaceutyki, leki |
| 170 | R0170 | `gtu_10_real_estate` | GTU_10 | Nieruchomości |
| 171 | R0171 | `gtu_11_gas_energy` | GTU_11 | Gaz, energia, ciepło |
| 172 | R0172 | `gtu_12_wnt` | GTU_12 | WNT, reverse charge |
| 173 | R0173 | `gtu_13_other` | GTU_13 | Pozostałe obowiązkowe |

### R0174-R0183: Ulga na złe długi — 10 reguł

| # | R-ID | Reguła | Art. | Strona | Kluczowy warunek |
|---|------|--------|------|:------:|------------------|
| 174 | R0174 | `bad_debt_creditor_150_days` | Art. 89a ust. 1 | Wierzyciel | Niezapłacone 150 dni → korekta minus |
| 175 | R0175 | `bad_debt_creditor_debtor_not_restructuring` | Art. 89a ust. 2 | Wierzyciel | Dłużnik nie w restrukturyzacji |
| 176 | R0176 | `bad_debt_creditor_notification_obligation` | Art. 89a ust. 3 | Wierzyciel | Zawiadomienie dłużnika + US |
| 177 | R0177 | `bad_debt_creditor_reversal_on_payment` | Art. 89a ust. 4 | Wierzyciel | Zapłata po korekcie → przywrócenie |
| 178 | R0178 | `bad_debt_debtor_90_days_mandatory` | Art. 89b ust. 1 | Dłużnik | 90 dni → OBOWIĄZEK korekty VAT |
| 179 | R0179 | `bad_debt_debtor_amount_calculation` | Art. 89b ust. 1 | Dłużnik | VAT odliczony = kwota do zwrotu |
| 180 | R0180 | `bad_debt_debtor_30pct_sanction` | Art. 89b ust. 2 | Dłużnik | Brak korekty → sankcja 30% |
| 181 | R0181 | `bad_debt_debtor_notification_7days` | Art. 89b ust. 3 | Dłużnik | Powiadomienie wierzyciela w 7 dni |
| 182 | R0182 | `bad_debt_days_calculation_90_150` | Art. 89a-89b | Obie | Precyzyjne liczenie dni (z weekendami) |
| 183 | R0183 | `bad_debt_excluded_restructuring` | Art. 89a ust. 2 | Obie | Restrukturyzacja/upadłość → wyłączenie |

### R0184-R0197: KSeF — 14 reguł

| # | R-ID | Reguła | Art. | Kluczowy warunek |
|---|------|--------|------|------------------|
| 184 | R0184 | `ksef_obligation_from_2026_02_01` | Art. 106na | Faktury od 01.02.2026 → obowiązek |
| 185 | R0185 | `ksef_exemption_vat_exempt` | Art. 106na ust. 3 | Zwolnieni z VAT → wyłączeni |
| 186 | R0186 | `ksef_exemption_b2c` | Art. 106ga | B2C → wyłączone |
| 187 | R0187 | `ksef_offline_recovery_7days` | Art. 106ne | Awaria → 7 dni tryb awaryjny |
| 188 | R0188 | `ksef_upo_confirmation_mandatory` | Art. 106ng | UPO dla każdej faktury |
| 189 | R0189 | `ksef_qr_code_mandatory` | Art. 106nh | Kod QR na fakturze |
| 190 | R0190 | `ksef_sanction_100pct_vat` | Art. 106nq | Sankcja: 100% VAT (max 500k) |
| 191 | R0191 | `ksef_schema_validation_fa2` | Rozp. KSeF | Walidacja schematu FA(2) |
| 192 | R0192 | `ksef_attachment_size_limit_200mb` | Rozp. KSeF | Limit 200MB załączników |
| 193 | R0193 | `ksef_authorization_token` | Rozp. KSeF | Token autoryzacyjny KSeF |
| 194 | R0194 | `ksef_consumer_invoice_exemption` | Art. 106ga | Faktura konsumencka → wyłączona |
| 195 | R0195 | `ksef_date_of_issue_mandatory` | Art. 106e | Data wystawienia obowiązkowa |
| 196 | R0196 | `ksef_numbering_ksef_format` | Art. 106e | Numeracja KSeF (unikalna) |
| 197 | R0197 | `ksef_archiving_10years` | Art. 112a | Archiwizacja KSeF 10 lat |

---

## 📦 8. `jdg.pit.forms` — Formy opodatkowania PIT (R0198-R0221)

### R0198: `jdg.pit.forms.scale_12_32`
- **Cel:** Skala podatkowa 12%/32% — domyślna forma JDG. Dochód do 120k → 12%, nadwyżka → 32%.
- **Przesłanki:** `entrepreneur.tax_form == "PIT_SCALE"`
- **Rezultat:** `pit_form:"SCALE"`, `pit_rate_low:"0.12"`, `pit_rate_high:"0.32"`, `pit_tax_free_amount:30000`, `annual_return:"PIT-36"`
- **Podstawa:** Art. 27 ust. 1 PIT
- **Edge cases:** Dochód dokładnie 120 000 PLN → całość w I progu (12%). Małżonek → można złożyć wspólnie (podwaja próg).
- **Thresholds:** `jdg.pit.scale_threshold` (120 000), `jdg.pit.tax_free_amount` (30 000)
- **Przykład +:** JDG, dochód 80k PLN → skala 12%, PIT-36
- **Przykład −:** JDG liniowy → NIE matchuje

### R0199-R0221: Formy PIT — 23 reguły szczegółowe

| # | R-ID | Reguła | Forma | Art. | Kluczowy warunek / Rezultat |
|---|------|--------|-------|------|-----------------------------|
| 199 | R0199 | `pit_scale_bracket_determination` | SKALA | Art. 27 ust. 1 | Dochód ≤120k → LOW (12%), >120k → HIGH (32% od nadwyżki) |
| 200 | R0200 | `pit_scale_tax_free_30k` | SKALA | Art. 27 ust. 1 | Kwota wolna 30k → redukcja podatku 3 600 PLN |
| 201 | R0201 | `pit_scale_joint_filing_spouse` | SKALA | Art. 6 ust. 2 | Wspólne rozliczenie → 2× próg (240k), 2× kwota wolna |
| 202 | R0202 | `pit_scale_single_parent` | SKALA | Art. 6 ust. 4 | Samotny rodzic → podwójna kwota wolna |
| 203 | R0203 | `pit_scale_floor_zero` | SKALA | Art. 27 ust. 1 | Podatek nie może być ujemny (minimum 0 PLN) |
| 204 | R0204 | `pit_form_linear_19pct` | LINIOWY | Art. 30c | Stawka 19%, brak kwoty wolnej, PIT-36L |
| 205 | R0205 | `pit_linear_no_tax_free_amount` | LINIOWY | Art. 30c ust. 1 | BRAK kwoty wolnej (0 PLN) |
| 206 | R0206 | `pit_linear_no_joint_filing` | LINIOWY | Art. 30c | BRAK wspólnego rozliczenia z małżonkiem |
| 207 | R0207 | `pit_linear_no_child_tax_credit` | LINIOWY | Art. 27f | BRAK ulgi na dzieci |
| 208 | R0208 | `pit_linear_former_employer_restriction` | LINIOWY | Art. 9a ust. 3 | Były pracodawca w ciągu 3 lat → NIE liniowy |
| 209 | R0209 | `pit_linear_deadline_jan20` | LINIOWY | Art. 9a ust. 2 | Oświadczenie do 20 stycznia |
| 210 | R0210 | `pit_linear_health_deduction_12900` | LINIOWY | Art. 30c ust. 2 | Odliczenie zdrowotnej max 12 900 PLN |
| 211 | R0211 | `pit_form_lump_sum` | RYCZAŁT | Art. 6 ust. 1 | Podatek od przychodu, różne stawki, PIT-28 |
| 212 | R0212 | `lump_sum_rate_17pct_free_professions` | RYCZAŁT | Art. 12 ust. 1 pkt 2 | PKWiU 69-75, 77-82 → 17% |
| 213 | R0213 | `lump_sum_rate_15pct_intermediation` | RYCZAŁT | Art. 12 ust. 1 pkt 3 | PKWiU pośrednictwo → 15% |
| 214 | R0214 | `lump_sum_rate_14pct_it` | RYCZAŁT | Art. 12 ust. 1 pkt 2a | PKWiU 62.01 → 14% (IT) |
| 215 | R0215 | `lump_sum_rate_12pct_software_hosting` | RYCZAŁT | Art. 12 ust. 1 pkt 2b | PKWiU 58.2, 62.02-09, 63 → 12% |
| 216 | R0216 | `lump_sum_rate_10pct_construction` | RYCZAŁT | Art. 12 ust. 1 pkt 6 | PKWiU 41-43, 71.1 → 10% |
| 217 | R0217 | `lump_sum_rate_8_5pct_trade` | RYCZAŁT | Art. 12 ust. 1 pkt 5 | Handel, produkcja, transport → 8.5% |
| 218 | R0218 | `lump_sum_rate_5_5pct_construction_mat` | RYCZAŁT | Art. 12 ust. 1 pkt 6a | Budownictwo z materiałem → 5.5% |
| 219 | R0219 | `lump_sum_rate_3pct_food_production` | RYCZAŁT | Art. 12 ust. 1 pkt 7 | Produkcja żywności, gastronomia → 3% |
| 220 | R0220 | `lump_sum_rate_2pct_agriculture` | RYCZAŁT | Art. 12 ust. 1 pkt 8 | Produkcja rolna → 2% |
| 221 | R0221 | `pit_form_tax_card` | KARTA | Art. 21-30 ust. ryczałt | Stała kwota, brak PKPiR, brak zeznania rocznego |

---

## 📦 9. `jdg.pit.kup` — Koszty Uzyskania Przychodu (R0222-R0253)

### R0222-R0253: 32 reguły KUP

| # | R-ID | Reguła | Art. | Kluczowy warunek | Rezultat |
|---|------|--------|------|------------------|----------|
| 222 | R0222 | `kup_general_definition` | Art. 22 ust. 1 | Koszty poniesione w celu osiągnięcia przychodu | KUP 100% |
| 223 | R0223 | `kup_timing_direct_revenue_year` | Art. 22 ust. 5 | Koszty bezpośrednie → rok odpowiadającego przychodu | Rok przychodu |
| 224 | R0224 | `kup_timing_indirect_invoice_date` | Art. 22 ust. 5c | Koszty pośrednie → data faktury | Data poniesienia |
| 225 | R0225 | `kup_zus_social_paid` | Art. 22 ust. 6b | Składki ZUS społeczne opłacone → KUP | Data zapłaty |
| 226 | R0226 | `kup_zus_social_unpaid_block` | Art. 23 ust. 1 pkt 55 | Niezapłacone składki ZUS → NIE KUP | NKUP |
| 227 | R0227 | `kup_health_linear_deduction_12900` | Art. 30c ust. 2 | Zdrowotna liniowy → odliczenie max 12 900 PLN | Odliczenie |
| 228 | R0228 | `kup_unpaid_reversal_90days` | Art. 22 ust. 1a | Faktura nieopłacona >90 dni → OBOWIĄZEK wyłączenia | NKUP + korekta |
| 229 | R0229 | `kup_unpaid_reversal_on_payment` | Art. 22 ust. 1b | Zapłata po wyłączeniu → przywrócenie KUP | Przywrócenie |
| 230 | R0230 | `kup_exclusion_own_labor` | Art. 23 ust. 1 pkt 10 | Wartość własnej pracy JDG → NKUP | NKUP |
| 231 | R0231 | `kup_exclusion_spouse_no_contract` | Art. 23 ust. 1 pkt 10 | Praca małżonka bez umowy → NKUP | NKUP |
| 232 | R0232 | `kup_spouse_contract_allowed` | Art. 22 ust. 1 | Małżonek z umową cywilnoprawną → KUP (jeśli nie podwładny) | KUP OK |
| 233 | R0233 | `kup_exclusion_personal_living` | Art. 23 ust. 1 pkt 10 | Cele osobiste JDG → NKUP | NKUP |
| 234 | R0234 | `kup_exclusion_representation` | Art. 23 ust. 1 pkt 23 | Reprezentacja, gastronomia, rozrywka → NKUP | NKUP |
| 235 | R0235 | `kup_representation_limit_0_025pct` | Art. 23 ust. 1 pkt 23 | Reprezentacja → limit 0.025% przychodu | Częściowe KUP |
| 236 | R0236 | `kup_exclusion_car_over_150k` | Art. 23 ust. 1 pkt 47a | Auto >150k PLN → limit KUP 150k | Ograniczenie |
| 237 | R0237 | `kup_exclusion_car_electric_225k` | Art. 23 ust. 1 pkt 47b | Auto elektryczne → limit 225k PLN | Limit EV |
| 238 | R0238 | `kup_car_mileage_log_required` | Art. 23 ust. 1 pkt 46 | Brak ewidencji → 75% KUP | 75% KUP |
| 239 | R0239 | `kup_exclusion_tax_penalties` | Art. 23 ust. 1 pkt 19 | Kary, grzywny, mandaty → NKUP | NKUP |
| 240 | R0240 | `kup_exclusion_fines_state` | Art. 23 ust. 1 pkt 5 | Grzywny państwowe → NKUP | NKUP |
| 241 | R0241 | `kup_exclusion_capital_investment` | Art. 23 ust. 1 pkt 1 | Środki trwałe → amortyzacja (nie KUP bezpośrednio) | Amortyzacja |
| 242 | R0242 | `kup_exclusion_land_purchase` | Art. 23 ust. 1 pkt 1 | Zakup gruntu → NKUP (tylko użytkowanie wieczyste) | NKUP |
| 243 | R0243 | `kup_own_work_nkup` | Art. 23 ust. 1 pkt 10 | Własna praca → NKUP (także w formie wynagrodzenia) | NKUP |
| 244 | R0244 | `kup_self_education_related` | Art. 22 ust. 1 | Kształcenie związane z JDG → KUP | KUP |
| 245 | R0245 | `kup_self_education_unrelated` | Art. 23 ust. 1 pkt 10 | Kształcenie niezwiązane → NKUP | NKUP |
| 246 | R0246 | `kup_workwear_bhp` | Art. 22 ust. 1 | Odzież BHP wymagana przepisami → KUP | KUP |
| 247 | R0247 | `kup_workwear_rep` | Art. 23 ust. 1 pkt 23 | Garnitur, odzież reprezentacyjna → NKUP | NKUP |
| 248 | R0248 | `kup_private_mixed_home_office` | Art. 22 ust. 1 | Home office → proporcja % | Proporcja |
| 249 | R0249 | `kup_private_mixed_car` | Art. 23 ust. 1 pkt 46 | Samochód mieszany → 75% KUP | 75% |
| 250 | R0250 | `kup_professional_chamber_fees` | Art. 22 ust. 1 | Składki izb zawodowych → KUP | KUP |
| 251 | R0251 | `kup_contractual_penalties_nkup` | Art. 23 ust. 1 pkt 19 | Kary umowne → NKUP | NKUP |
| 252 | R0252 | `kup_abandoned_spoiled_goods` | Art. 22 ust. 1 | Towary przeterminowane (protokół) → KUP | KUP |
| 253 | R0253 | `kup_insurance_policies` | Art. 22 ust. 1 | Ubezpieczenia majątkowe JDG → KUP | KUP |

---

## 📦 10. `jdg.pit.advances` + `jdg.pit.exemptions` + `jdg.pit.transitions` (R0254-R0299)

### R0254-R0271: Zaliczki i zeznania — 18 reguł

| # | R-ID | Reguła | Art. | Kluczowy warunek |
|---|------|--------|------|------------------|
| 254 | R0254 | `advance_monthly_scale_20th` | Art. 44 ust. 1 | Skala → zaliczka miesięczna do 20. |
| 255 | R0255 | `advance_monthly_linear_20th` | Art. 44 ust. 1 | Liniowy → zaliczka miesięczna do 20. |
| 256 | R0256 | `advance_quarterly_small_payer` | Art. 44 ust. 3g | Mały podatnik → kwartalne |
| 257 | R0257 | `advance_calculation_progressive` | Art. 44 ust. 2 | Narastająco: dochód × stawka − zapłacone |
| 258 | R0258 | `advance_zus_social_deduction` | Art. 26 ust. 1 | Odliczenie ZUS społecznych od zaliczki |
| 259 | R0259 | `advance_zus_health_deduction_scale` | Art. 27b ust. 1 | Odliczenie zdrowotnej (skala: 7.75% podstawy) |
| 260 | R0260 | `advance_if_zero_or_negative` | Art. 44 ust. 3 | Dochód ≤ 0 → zaliczka 0 |
| 261 | R0261 | `advance_lump_sum_monthly_20th` | Art. 21 ust. 1 | Ryczałt → zaliczka do 20. |
| 262 | R0262 | `advance_lump_sum_quarterly` | Art. 21 ust. 1b | Ryczałt kwartalny (przychód poprz. roku ≤200k EUR) |
| 263 | R0263 | `advance_simplified_previous_year` | Art. 44 ust. 6b | Uproszczona: 1/12 podatku z poprzedniego roku |
| 264 | R0264 | `annual_return_pit36_deadline_april30` | Art. 45 ust. 1 | PIT-36 → 30 kwietnia |
| 265 | R0265 | `annual_return_pit36l_deadline_april30` | Art. 45 ust. 1 | PIT-36L → 30 kwietnia |
| 266 | R0266 | `annual_return_pit28_deadline_feb28` | Art. 21 ust. 1 u. ryczałt | PIT-28 → 28 lutego! |
| 267 | R0267 | `annual_return_pit38_capital_gains` | Art. 45 ust. 1a | PIT-38 → 30 kwietnia |
| 268 | R0268 | `annual_return_electronic_mandatory` | Art. 45 ust. 1c | e-Deklaracja obowiązkowa |
| 269 | R0269 | `annual_return_correction_allowed` | Art. 81 Ordynacji | Korekta po złożeniu → możliwa |
| 270 | R0270 | `annual_return_overpayment_refund_45days` | Art. 78 Ordynacji | Zwrot nadpłaty w 45 dni |
| 271 | R0271 | `annual_return_overpayment_interest` | Art. 78 § 1 Ordynacji | Po 45 dniach → odsetki od US |

### R0272-R0287: Zwolnienia PIT (PIT-0) — 16 reguł

| # | R-ID | Reguła | Ulga | Art. | Limit |
|---|------|--------|------|------|:-----:|
| 272 | R0272 | `pit_exemption_young_under_26` | Ulga dla młodych | Art. 21 ust. 1 pkt 148 | 85 528 PLN |
| 273 | R0273 | `pit_exemption_young_income_ceiling` | Młodzi — limit | Art. 21 ust. 1 pkt 148 | Przychód ≤ 85 528 PLN |
| 274 | R0274 | `pit_exemption_young_excess_taxed` | Młodzi — nadwyżka | Art. 21 ust. 1 pkt 148 | Nadwyżka → opodatkowana normalnie |
| 275 | R0275 | `pit_exemption_return_4_years` | Ulga na powrót | Art. 21 ust. 1 pkt 152 | 85 528 PLN, 4 lata |
| 276 | R0276 | `pit_exemption_return_previous_residence` | Powrót — warunek | Art. 21 ust. 1 pkt 152 | Rezydencja zagraniczna ≥3 lata |
| 277 | R0277 | `pit_exemption_family_4plus` | Ulga 4+ | Art. 21 ust. 1 pkt 153 | 85 528 PLN |
| 278 | R0278 | `pit_exemption_family_4plus_child_count` | 4+ — warunek | Art. 21 ust. 1 pkt 153 | ≥4 dzieci na utrzymaniu |
| 279 | R0279 | `pit_exemption_working_senior` | Ulga seniora | Art. 21 ust. 1 pkt 154 | 85 528 PLN |
| 280 | R0280 | `pit_exemption_senior_age_60_65` | Senior — wiek | Art. 21 ust. 1 pkt 154 | Kobieta ≥60, mężczyzna ≥65 |
| 281 | R0281 | `pit_exemption_senior_not_retired` | Senior — warunek | Art. 21 ust. 1 pkt 154 | Nie pobiera emerytury/renty |
| 282 | R0282 | `pit_zero_combined_limit_85_528` | ŁĄCZNY limit PIT-0 | Art. 21 ust. 1 pkt 148-154 | Suma ≤ 85 528 PLN |
| 283 | R0283 | `pit_zero_mutual_exclusion_detection` | Kolizja ulg PIT-0 | — | Alert gdy >1 ulga PIT-0 |
| 284 | R0284 | `pit_zero_annual_calculation` | Roczne sumowanie PIT-0 | — | Narastająco w roku |
| 285 | R0285 | `pit_zero_excess_month_taxation` | Przekroczenie w miesiącu | — | Nadwyżka opodatkowana od miesiąca przekroczenia |
| 286 | R0286 | `pit_zero_forms_allowed` | Formy dla PIT-0 | — | Skala, liniowy, ryczałt |
| 287 | R0287 | `pit_zero_documentation_required` | Dokumentacja PIT-0 | — | Oświadczenia, certyfikaty rezydencji |

### R0288-R0299: Zmiana formy opodatkowania — 12 reguł

| # | R-ID | Reguła | Art. | Kluczowy warunek |
|---|------|--------|------|------------------|
| 288 | R0288 | `mid_year_change_restriction` | Art. 9a ust. 4 | Blokada zmiany formy w trakcie roku |
| 289 | R0289 | `tax_form_change_deadline_jan20` | Art. 9a ust. 2 | Zmiana do 20 stycznia |
| 290 | R0290 | `tax_form_new_jdg_before_first_invoice` | Art. 9a ust. 5 | Nowa JDG: wybór przed 1. fakturą |
| 291 | R0291 | `dual_return_on_form_change` | Art. 9a ust. 4 | Dwa zeznania przy zmianie formy |
| 292 | R0292 | `health_recalc_on_form_change` | Art. 81 ust. 2d | Przeliczenie składki zdrowotnej |
| 293 | R0293 | `scale_to_linear_kup_reset` | Art. 22 ust. 1 | Zmiana skala→liniowy: KUP od nowa |
| 294 | R0294 | `lump_sum_to_scale_inventory` | Art. 24 ust. 2 | Ryczałt→skala: remanent na 1 stycznia |
| 295 | R0295 | `linear_to_scale_loss_carry_forward` | Art. 9 ust. 3 | Liniowy→skala: strata przechodzi |
| 296 | R0296 | `tax_card_loss_to_scale_automatic` | Art. 30 ust. 5 | Karta→skala: utrata praw, automatycznie |
| 297 | R0297 | `lump_sum_loss_to_scale_automatic` | Art. 8 ust. 2 | Ryczałt→skala: przekroczenie limitu 2M EUR |
| 298 | R0298 | `form_change_vat_proportion_reset` | Art. 90 VAT | Zmiana formy → reset proporcji VAT |
| 299 | R0299 | `form_change_notification_us_7days` | Art. 9a ust. 4 | Zawiadomienie US w 7 dni |

---

## 📦 11. `jdg.allowances` — Ulgi podatkowe (R0300-R0337)

### R0300-R0337: 38 szczegółowych reguł ulg

| # | R-ID | Reguła | Ulga | Art. | Limit / Stawka |
|---|------|--------|------|------|:--------------:|
| 300 | R0300 | `relief_rd_eligibility` | B+R | Art. 26e ust. 1 | Status B+R |
| 301 | R0301 | `relief_rd_costs_salaries` | B+R | Art. 26e ust. 2 pkt 1 | Wynagrodzenia B+R → 100% |
| 302 | R0302 | `relief_rd_costs_equipment` | B+R | Art. 26e ust. 2 pkt 2 | Sprzęt specjalistyczny → 100% |
| 303 | R0303 | `relief_rd_costs_materials` | B+R | Art. 26e ust. 2 pkt 3 | Materiały, surowce → 100% |
| 304 | R0304 | `relief_rd_costs_expertise` | B+R | Art. 26e ust. 2 pkt 4 | Ekspertyzy, badania → 100% |
| 305 | R0305 | `relief_rd_costs_patents` | B+R | Art. 26e ust. 2 pkt 5 | Koszty patentów → 100% |
| 306 | R0306 | `relief_rd_centrum_200pct` | B+R (CBR) | Art. 26e ust. 7 | Status CBR → 200% |
| 307 | R0307 | `relief_rd_evidence_required` | B+R | Art. 26e ust. 2 | Wyodrębniona ewidencja |
| 308 | R0308 | `relief_rd_capped_at_income` | B+R | Art. 26e ust. 8 | Ograniczenie do dochodu |
| 309 | R0309 | `relief_rd_carry_forward_6_years` | B+R | Art. 26e ust. 8 | Niewykorzystana → 6 lat |
| 310 | R0310 | `relief_ip_box_eligibility` | IP Box | Art. 30ca ust. 1 | Kwalifikowane IP |
| 311 | R0311 | `relief_ip_box_rate_5pct` | IP Box | Art. 30ca ust. 1 | Stawka 5% |
| 312 | R0312 | `relief_ip_box_nexus_formula` | IP Box | Art. 30ca ust. 4 | Wskaźnik Nexus |
| 313 | R0313 | `relief_ip_box_separate_books` | IP Box | Art. 30ca ust. 3 | Wyodrębniona ewidencja |
| 314 | R0314 | `relief_prototype_30pct` | Prototyp | Art. 26eb ust. 1 | 30% kosztów, max 300k |
| 315 | R0315 | `relief_robotization_50pct` | Robotyzacja | Art. 26gb ust. 1 | 50% kosztów (2022-2026) |
| 316 | R0316 | `relief_expansion_1m` | Ekspansja | Art. 26ec ust. 1 | Max 1 000 000 PLN |
| 317 | R0317 | `relief_thermo_53k` | Termomodernizacja | Art. 26h ust. 1 | Max 53 000 PLN |
| 318 | R0318 | `relief_thermo_certificate` | Termomodernizacja | Art. 26h ust. 3 | Audyt energetyczny |
| 319 | R0319 | `relief_donation_opp_6pct` | Darowizny OPP | Art. 26 ust. 1 pkt 9 | Max 6% dochodu |
| 320 | R0320 | `relief_donation_blood_130pln` | Krew | Art. 26 ust. 1 pkt 9 lit. c | 130 PLN/litr |
| 321 | R0321 | `relief_donation_church_6pct` | Kościół | Art. 26 ust. 1 pkt 9 lit. b | Max 6% dochodu |
| 322 | R0322 | `relief_donation_transfer_required` | Darowizny | Art. 26 ust. 1 pkt 9 | TYLKO przelewem |
| 323 | R0323 | `relief_rehabilitation_2280` | Rehabilitacja | Art. 26 ust. 1 pkt 6 | Max 2 280 PLN |
| 324 | R0324 | `relief_rehabilitation_disability_required` | Rehabilitacja | Art. 26 ust. 7a | Orzeczenie o niepełnosprawności |
| 325 | R0325 | `relief_internet_760` | Internet | Art. 26 ust. 1 pkt 60 | 760 PLN/rok, max 2 lata |
| 326 | R0326 | `relief_internet_2_years_limit` | Internet | Art. 26 ust. 1 pkt 60 | Tylko 2 kolejne lata |
| 327 | R0327 | `relief_child_tax_credit_first` | Dziecko 1 | Art. 27f ust. 2 | 1 112.04 PLN/rok |
| 328 | R0328 | `relief_child_tax_credit_second` | Dziecko 2 | Art. 27f ust. 2 | 1 112.04 PLN/rok |
| 329 | R0329 | `relief_child_tax_credit_third` | Dziecko 3 | Art. 27f ust. 2 | 2 000.04 PLN/rok |
| 330 | R0330 | `relief_child_tax_credit_fourth` | Dziecko 4+ | Art. 27f ust. 2 | 2 700.00 PLN/rok |
| 331 | R0331 | `relief_child_scale_only` | Dzieci — zakres | Art. 27f ust. 1 | TYLKO skala, NIE liniowy |
| 332 | R0332 | `relief_loss_carry_forward_5_years` | Strata | Art. 9 ust. 3 | 5 lat, max 50%/rok |
| 333 | R0333 | `relief_loss_one_time_5m` | Strata 5M | Art. 9 ust. 3 pkt 2 | Jednorazowo do 5M PLN |
| 334 | R0334 | `relief_loss_scale_linear_only` | Strata — zakres | Art. 9 ust. 3 | TYLKO skala i liniowy |
| 335 | R0335 | `relief_joint_allowances_cap_income` | Łączny limit | Art. 26 ust. 1 | Suma ulg ≤ dochód |
| 336 | R0336 | `relief_conflict_ipbox_vs_rd` | Konflikt IP Box vs B+R | Art. 30ca ust. 3 | NIE ten sam dochód |
| 337 | R0337 | `relief_conflict_pit0_combined_85k` | Konflikt PIT-0 | Art. 21 ust. 1 | Łączny limit 85 528 PLN |

---

## 📦 12. `jdg.zus` — Składki ZUS (R0338-R0371)

| # | R-ID | Reguła | Art. | Kluczowy warunek / Rezultat |
|---|------|--------|------|-----------------------------|
| 338 | R0338 | `zus_start_relief_6_months` | Art. 18a SUS | 6 mies. tylko zdrowotna → 0 PLN społeczne |
| 339 | R0339 | `zus_start_relief_eligibility_new_jdg` | Art. 18a ust. 1 | Nowa JDG: brak JDG w ostatnich 60 mies. |
| 340 | R0340 | `zus_start_relief_last_month_transition` | Art. 18a ust. 3 | Ostatni miesiąc → automatyczne przejście |
| 341 | R0341 | `zus_maly_plus_36_months` | Art. 18c SUS | 30% min. wynagr., 36 mies. |
| 342 | R0342 | `zus_maly_plus_income_120k_eur` | Art. 18c ust. 4 | Przychód ≤120k EUR/rok |
| 343 | R0343 | `zus_maly_plus_not_preferential` | Art. 18c ust. 5 | Nie łączy się z preferencyjnym |
| 344 | R0344 | `zus_preferential_24_months` | Art. 18a ust. 2 | 30% min. wynagr., 24 mies. |
| 345 | R0345 | `zus_standard_social_rates` | Art. 16-18 SUS | Pełne stawki: emer. 19.52%, rent. 8%, chor. 2.45%, wyp. 1.67% |
| 346 | R0346 | `zus_sickness_voluntary` | Art. 11 ust. 2 SUS | Chorobowa → DOBROWOLNA |
| 347 | R0347 | `zus_sickness_waiting_period_90_days` | Art. 4 ust. 1 pkt 2 | Zasiłek chorobowy po 90 dniach ubezpieczenia |
| 348 | R0348 | `zus_health_scale_9pct` | Art. 79 ust. 1 | Skala → 9% dochodu |
| 349 | R0349 | `zus_health_linear_4_9pct` | Art. 79 ust. 1 | Liniowy → 4.9% dochodu |
| 350 | R0350 | `zus_health_lump_sum_progressive` | Art. 81 ust. 2e | Ryczałt: 60k/300k progi (419.46/699.11/1258.39 PLN) |
| 351 | R0351 | `zus_health_scale_deduction_7_75pct` | Art. 27b ust. 1 | Skala: odliczenie 7.75% podstawy |
| 352 | R0352 | `zus_health_linear_deduction_12900` | Art. 30c ust. 2 | Liniowy: max 12 900 PLN odliczenia |
| 353 | R0353 | `zus_health_annual_reconciliation_scale` | Art. 81 ust. 2d | Skala: roczne rozliczenie (dopłata/zwrot) |
| 354 | R0354 | `zus_health_annual_reconciliation_linear` | Art. 81 ust. 2d | Liniowy: roczne rozliczenie |
| 355 | R0355 | `zus_health_annual_reconciliation_lump` | Art. 81 ust. 2f | Ryczałt: roczne rozliczenie, dopłata do 22 maja |
| 356 | R0356 | `zus_health_loss_year_minimum_base` | Art. 81 ust. 2d | Strata → podstawa minimalna |
| 357 | R0357 | `zus_concurrent_employment_only_health` | Art. 9 ust. 2a SUS | Etat+JDG (pensja ≥ min.) → tylko zdrowotna z JDG |
| 358 | R0358 | `zus_concurrent_employment_low_salary` | Art. 9 ust. 2a SUS | Etat+JDG (pensja < min.) → społeczne Z JDG |
| 359 | R0359 | `zus_sickness_benefit_jdg_90_days` | Art. 8 ustawy zasiłkowej | Zasiłek chorobowy JDG: max 90 dni |
| 360 | R0360 | `zus_maternity_benefit_jdg` | Art. 29-31 ustawy zasiłkowej | Zasiłek macierzyński 100%/80% |
| 361 | R0361 | `zus_deadline_payment_10th` | Art. 47 ust. 1 SUS | Termin płatności: 10. dzień miesiąca |
| 362 | R0362 | `zus_deadline_payment_15th_units` | Art. 47 ust. 1a SUS | Jednostki budżetowe: 15. dzień |
| 363 | R0363 | `zus_dra_declaration_monthly` | Art. 46 SUS | ZUS DRA miesięcznie |
| 364 | R0364 | `zus_rca_imienny_report` | Art. 40 SUS | ZUS RCA — raport imienny |
| 365 | R0365 | `zus_zua_registration_7days` | Art. 36 ust. 1 SUS | Zgłoszenie w 7 dni |
| 366 | R0366 | `zus_interest_late_payment` | Art. 47 ust. 3 SUS | Odsetki za zwłokę ZUS |
| 367 | R0367 | `zus_unpaid_social_nkup` | Art. 23 ust. 1 pkt 55 PIT | Niezapłacony ZUS społeczny → NKUP |
| 368 | R0368 | `zus_accident_rate_1_67pct` | Art. 16-18 SUS | Wypadkowe: 1.67% |
| 369 | R0369 | `zus_labour_fund_2_45pct` | Art. 104-107 | FP 2.45%, FGŚP 0.10% |
| 370 | R0370 | `zus_minimum_base_calculation` | Art. 18 ust. 8 SUS | Podstawa: 60% prognozowanego przeciętnego wynagrodzenia |
| 371 | R0371 | `zus_health_minimum_base_75pct` | Art. 81 ust. 2 | Zdrowotna min.: 75% przeciętnego wynagrodzenia |

---

## 📦 13. `jdg.accounting` — Księgowość (R0372-R0399)

| # | R-ID | Reguła | Art. | Kluczowy warunek |
|---|------|--------|------|------------------|
| 372 | R0372 | `pkpir_format_16_columns` | Rozp. MF PKPiR | PKPiR → 16 kolumn |
| 373 | R0373 | `pkpir_column_10_purchase_cost` | Rozp. MF PKPiR | Kol. 10: zakup towarów |
| 374 | R0374 | `pkpir_column_11_kup_side` | Rozp. MF PKPiR | Kol. 11: koszty uboczne zakupu |
| 375 | R0375 | `pkpir_column_12_other_kup` | Rozp. MF PKPiR | Kol. 12: pozostałe KUP |
| 376 | R0376 | `pkpir_column_13_zus_social` | Rozp. MF PKPiR | Kol. 13: składki ZUS społeczne |
| 377 | R0377 | `pkpir_chronological_order` | Art. 24a PIT | Chronologiczny zapis |
| 378 | R0378 | `pkpir_empty_row_number_continuity` | Art. 24a PIT | Ciągłość numeracji, brak luk |
| 379 | R0379 | `depreciation_linear_method` | Art. 22d ust. 1 PIT | Amortyzacja liniowa — standard |
| 380 | R0380 | `depreciation_degressive_2_0` | Art. 22d ust. 2 PIT | Degresywna: współczynnik 2.0 |
| 381 | R0381 | `depreciation_one_off_under_10k` | Art. 22d ust. 1 PIT | ≤10 000 PLN → jednorazowo |
| 382 | R0382 | `depreciation_de_minimis_100k` | Art. 22k ust. 7 PIT | Do 100k PLN (mały podatnik) |
| 383 | R0383 | `depreciation_kst_group_0_land` | KŚT zał. 1 | Grupa 0: grunty → BEZ amortyzacji |
| 384 | R0384 | `depreciation_kst_group_1_buildings_2_5pct` | KŚT zał. 1, gr. 1 | Budynki → 2.5%/rok |
| 385 | R0385 | `depreciation_kst_group_4_computers_30pct` | KŚT zał. 1, gr. 4 | Komputery → 30%/rok |
| 386 | R0386 | `depreciation_kst_group_7_cars_20pct` | KŚT zał. 1, gr. 7 | Samochody → 20%/rok |
| 387 | R0387 | `depreciation_improvement_over_10k` | Art. 22g ust. 17 PIT | Ulepszenie >10k → zwiększa wartość |
| 388 | R0388 | `depreciation_used_shortened_30months` | Art. 22j PIT | Używany ŚT → max 30 mies. |
| 389 | R0389 | `depreciation_sale_tax_consequences` | Art. 14 ust. 2 PIT | Sprzedaż ŚT → przychód (różnica od wartości netto) |
| 390 | R0390 | `operating_lease_full_kup` | Art. 23b PIT | Leasing operacyjny → rata = KUP |
| 391 | R0391 | `financial_lease_kup_interest` | Art. 23f PIT | Leasing finansowy → KUP = amortyzacja + odsetki |
| 392 | R0392 | `fx_difference_realized_revenue` | Art. 14c PIT | Kurs zapłaty > kurs faktury → przychód FX |
| 393 | R0393 | `fx_difference_realized_cost` | Art. 14c PIT | Kurs zapłaty < kurs faktury → KUP FX |
| 394 | R0394 | `fx_rate_nbp_previous_day` | Art. 31a PIT | Kurs NBP z dnia poprzedzającego |
| 395 | R0395 | `inventory_fifo_method` | Art. 24 ust. 2 PIT | Rozchód magazynowy → FIFO |
| 396 | R0396 | `inventory_year_end_obligation` | Art. 24 ust. 2 PIT | Remanent na 31 grudnia |
| 397 | R0397 | `rmk_prepaid_expenses_deferral` | Art. 22 ust. 5 PIT | RMK → rozliczenie kosztów w czasie |
| 398 | R0398 | `home_office_proportion_calculation` | Art. 22 ust. 1 PIT | Home office → % powierzchni |
| 399 | R0399 | `car_mileage_log_75pct` | Art. 23 ust. 1 pkt 46 PIT | Ewidencja przebiegu → 75% KUP |

---

## 📦 14. `jdg.business` — Cykl życia JDG (R0400-R0419)

| # | R-ID | Reguła | Art. | Kluczowy warunek |
|---|------|--------|------|------------------|
| 400 | R0400 | `ceidg_registration_mandatory` | Art. 5 CEIDG | Obowiązek wpisu przed rozpoczęciem |
| 401 | R0401 | `ceidg_data_change_7_days` | Art. 30 CEIDG | Aktualizacja w 7 dni |
| 402 | R0402 | `ceidg_nip_format_validation` | Art. 5 CEIDG | NIP 10 cyfr |
| 403 | R0403 | `business_suspension_valid` | Art. 22 Pr. przedsiębiorców | Zawieszenie możliwe bezterminowo |
| 404 | R0404 | `business_suspension_6_months_auto_deregister` | Art. 22 Pr. przeds. | 6 mies. bez pracowników → wykreślenie |
| 405 | R0405 | `business_suspension_kup_only_maintenance` | Art. 22 ust. 1 PIT | Tylko koszty utrzymania → KUP |
| 406 | R0406 | `business_suspension_no_zus` | Art. 36a SUS | Brak składek ZUS w zawieszeniu |
| 407 | R0407 | `business_suspension_vat_zero_returns` | Art. 99 ust. 7a VAT | Zerowe deklaracje VAT-7 |
| 408 | R0408 | `business_suspension_depreciation_ban` | Art. 22c pkt 4 PIT | NIE dokonuje się odpisów amortyzacyjnych |
| 409 | R0409 | `business_resumption_continuity` | Art. 22 Pr. przeds. | Wznowienie → ciągłość NIP, REGON |
| 410 | R0410 | `succession_administrator_appointment` | Art. 7 ustawy o zarządzie sukcesyjnym | Zarządca sukcesyjny |
| 411 | R0411 | `succession_continuity_nip` | Art. 12 ust. 1 | Ciągłość NIP po śmierci |
| 412 | R0412 | `succession_inventory_death_date` | Art. 24 ust. 2 PIT | Remanent na dzień śmierci |
| 413 | R0413 | `succession_tax_obligations_heirs` | Art. 97-100 Ordynacji | Obowiązki podatkowe spadkobierców |
| 414 | R0414 | `unregistered_activity_limit_50pct_min_wage` | Art. 5 Pr. przeds. | Limit: 50% min. wynagrodzenia miesięcznie |
| 415 | R0415 | `unregistered_activity_zus_exemption` | Art. 6 SUS | Dział. nieewidencjonowana → brak ZUS |
| 416 | R0416 | `unregistered_activity_pit_scale_only` | Art. 9a PIT | Tylko skala podatkowa |
| 417 | R0417 | `unregistered_activity_vat_exempt` | Art. 113 VAT | Brak VAT |
| 418 | R0418 | `jdg_to_company_conversion_detection` | Art. 551 KSH | Przekształcenie JDG → Sp. z o.o. |
| 419 | R0419 | `conversion_closing_inventory_obligation` | Art. 24 ust. 2 PIT | Remanent na dzień przekształcenia |

---

## 📦 15. `jdg.corrections` + `jdg.liability` + `jdg.representation` (R0420-R0459)

### R0420-R0435: Korekty — 16 reguł

| # | R-ID | Reguła | Art. | Kluczowy warunek |
|---|------|--------|------|------------------|
| 420 | R0420 | `correction_invoice_in_minus` | Art. 106j VAT | Korekta in minus → warunek: zgoda nabywcy |
| 421 | R0421 | `correction_invoice_in_plus` | Art. 106j VAT | Korekta in plus → zawsze dopuszczalna |
| 422 | R0422 | `correction_storno_red_detection` | Art. 29a ust. 13 VAT | Storno czerwone → wartości ujemne |
| 423 | R0423 | `correction_storno_black_detection` | Art. 106j VAT | Storno czarne → osobny dokument korygujący |
| 424 | R0424 | `correction_jpk_v7_declaration` | Art. 109 VAT | Korekta JPK_V7 (Cel_Zlozenia=2) |
| 425 | R0425 | `correction_jpk_v7_reason_required` | § 10 JPK_VAT | Przyczyna korekty obowiązkowa |
| 426 | R0426 | `correction_pit_declaration_allowed` | Art. 81 Ordynacji | Korekta PIT → zawsze możliwa |
| 427 | R0427 | `correction_lock_during_tax_audit` | Art. 81b § 1 Ordynacji | Blokada korekty w trakcie kontroli |
| 428 | R0428 | `correction_statute_barred_block` | Art. 70 Ordynacji | Przedawnione → brak korekty |
| 429 | R0429 | `correction_deadline_vat_3_months` | Art. 86 ust. 11 VAT | Termin korekty VAT: 3 mies. |
| 430 | R0430 | `correction_credit_note_basis` | Art. 89a ust. 2 VAT | Nota kredytowa jako podstawa |
| 431 | R0431 | `correction_zbiorcza_conditions` | Art. 106j VAT | Korekta zbiorcza → warunki |
| 432 | R0432 | `correction_right_to_correct_14days` | Art. 81 Ordynacji | 14 dni na korektę po protokole kontroli |
| 433 | R0433 | `correction_overpayment_interest_45days` | Art. 78 Ordynacji | Odsetki od nadpłaty po 45 dniach |
| 434 | R0434 | `correction_annual_vat_5_10_years` | Art. 91 VAT | Korekta roczna VAT (5/10 lat) |
| 435 | R0435 | `correction_invoice_numbering_continuity` | Art. 106e VAT | Ciągłość numeracji po korekcie |

### R0436-R0449: Odpowiedzialność — 14 reguł

| # | R-ID | Reguła | Art. | Kluczowy warunek |
|---|------|--------|------|------------------|
| 436 | R0436 | `statute_of_limitations_5_years` | Art. 70 § 1 Ordynacji | 5 lat od końca roku |
| 437 | R0437 | `statute_of_limitations_10_years` | Art. 70 § 1a Ordynacji | 10 lat (przestępstwa skarbowe) |
| 438 | R0438 | `statute_suspension_during_audit` | Art. 70 § 6 Ordynacji | Zawieszenie w trakcie kontroli |
| 439 | R0439 | `statute_interruption_execution` | Art. 70 § 4 Ordynacji | Przerwanie: środek egzekucyjny |
| 440 | R0440 | `entrepreneur_personal_liability` | Art. 29 Ordynacji | Pełna odpowiedzialność osobista |
| 441 | R0441 | `spousal_solidary_liability` | Art. 29 Ordynacji | Małżonek — majątek wspólny |
| 442 | R0442 | `late_payment_interest_basic` | Art. 56 Ordynacji | Stopa ref. + 3.5% |
| 443 | R0443 | `late_payment_interest_reduced` | Art. 56 § 1a Ordynacji | Stopa ref. + 1.5% (po korekcie) |
| 444 | R0444 | `overpayment_interest_45_days` | Art. 78 Ordynacji | Odsetki od US za zwrot >45 dni |
| 445 | R0445 | `voluntary_disclosure_active` | Art. 16 KKS | Czynny żal → brak kary |
| 446 | R0446 | `voluntary_disclosure_deadline` | Art. 16 § 1 KKS | Przed rozpoczęciem kontroli |
| 447 | R0447 | `tax_audit_notification_7_days` | Art. 282b Ordynacji | Zawiadomienie 7 dni przed kontrolą |
| 448 | R0448 | `tax_audit_appeal_14_days` | Art. 223 Ordynacji | Odwołanie w 14 dni |
| 449 | R0449 | `tax_audit_extended_inspection_30_60_days` | Art. 83 Pr. przeds. | Max 30/60 dni kontroli |

### R0450-R0459: Reprezentacja — 10 reguł

| # | R-ID | Reguła | Art. | Kluczowy warunek |
|---|------|--------|------|------------------|
| 450 | R0450 | `poa_pps1_general_tax` | Art. 138a Ordynacji | PPS-1 → pełnomocnictwo ogólne |
| 451 | R0451 | `poa_upl1_specific_case` | Art. 138c Ordynacji | UPL-1 → pełnomocnictwo szczególne |
| 452 | R0452 | `poa_certified_accountant` | Art. 138d Ordynacji | Doradca podatkowy certyfikowany |
| 453 | R0453 | `poa_revocation_opp1` | Art. 138g Ordynacji | OPP-1 → cofnięcie pełnomocnictwa |
| 454 | R0454 | `poa_change_of_data` | Art. 138h Ordynacji | Aktualizacja danych pełnomocnictwa |
| 455 | R0455 | `poa_expiry_automatic` | Art. 138i Ordynacji | Automatyczne wygaśnięcie |
| 456 | R0456 | `poa_transborder_certificate` | Art. 138l Ordynacji | Pełnomocnictwo transgraniczne |
| 457 | R0457 | `poa_delivery_ppd1` | Art. 146 Ordynacji | PPD-1 → tylko doręczenia |
| 458 | R0458 | `poa_validity_check_before_decision` | Art. 138a Ordynacji | Ważność przed decyzją |
| 459 | R0459 | `joint_procuration_required` | Art. 109⁴ KSH | Prokura łączna → dwóch prokurentów |

---

## 📦 16. Pakiety pomocnicze (R0460-R0545)

### R0460-R0469: Podatki lokalne — 10 reguł
| # | R-ID | Reguła | Podatek | Art. | Limit |
|---|------|--------|---------|------|:-----:|
| 460 | R0460 | `pcc_sale_agreement_2pct` | PCC | Art. 7 PCC | 2% od umowy sprzedaży |
| 461 | R0461 | `pcc_loan_agreement_0_5pct` | PCC | Art. 7 PCC | 0.5% od pożyczki |
| 462 | R0462 | `pcc_deadline_14_days` | PCC | Art. 10 PCC | Deklaracja PCC-3 w 14 dni |
| 463 | R0463 | `real_estate_tax_commercial` | Nieruchomości | Art. 5 UPoL | Stawka max od budynków firmowych |
| 464 | R0464 | `real_estate_tax_residential_exempt` | Nieruchomości | Art. 7 UPoL | Mieszkaniowe → zwolnione |
| 465 | R0465 | `real_estate_tax_land_business` | Nieruchomości | Art. 5 UPoL | Grunt firmowy → opodatkowany |
| 466 | R0466 | `transport_tax_above_3_5t` | Transport | Art. 8 UPoL | Pojazdy >3.5t |
| 467 | R0467 | `transport_tax_tractor_exempt` | Transport | Art. 12 UPoL | Ciągniki rolnicze → zwolnione |
| 468 | R0468 | `agricultural_tax_land` | Rolny | Art. 4 ustawy | Grunty rolne → hektary przeliczeniowe |
| 469 | R0469 | `local_tax_deadline_31_january` | Wszystkie | Art. 6 UPoL | Deklaracja DN-1 do 31 stycznia |

### R0470-R0483: Międzynarodowe — 14 reguł
| # | R-ID | Reguła | Art. | Kluczowy warunek |
|---|------|--------|------|------------------|
| 470 | R0470 | `wht_dividend_19pct` | Art. 30a ust. 1 pkt 4 PIT | Dywidendy → 19% WHT |
| 471 | R0471 | `wht_interest_20pct` | Art. 30a ust. 1 pkt 1 PIT | Odsetki → 20% WHT |
| 472 | R0472 | `wht_royalties_20pct` | Art. 30a ust. 1 pkt 2 PIT | Licencje → 20% WHT |
| 473 | R0473 | `wht_dtt_reduced_rate` | Umowy UPO | Stawka z umowy (np. 5/10/15%) |
| 474 | R0474 | `wht_certificate_of_residence` | Art. 30a ust. 2 PIT | Certyfikat rezydencji |
| 475 | R0475 | `wht_pay_and_refund_2m` | Art. 26 ust. 2e CIT | >2M PLN → pay-and-refund |
| 476 | R0476 | `wht_pit8ar_deadline_january` | Art. 42 ust. 1a PIT | PIT-8AR do końca stycznia |
| 477 | R0477 | `pe_risk_detection` | Art. 4a pkt 11 PIT | Stałe miejsce prowadzenia działalności |
| 478 | R0478 | `tp_documentation_threshold` | Art. 11k CIT | Próg dokumentacji TP |
| 479 | R0479 | `tp_local_file_obligation` | Art. 11k CIT | Local File → 10 mies. po roku |
| 480 | R0480 | `tp_master_file_obligation` | Art. 11l CIT | Master File → duże podmioty |
| 481 | R0481 | `tp_tpr_reporting_deadline` | Art. 11t CIT | TPR do 30 listopada |
| 482 | R0482 | `tp_safe_harbour_5pct_low_value` | Art. 11f CIT | Safe harbour 5% dla usług |
| 483 | R0483 | `tp_benchmark_study_required` | Art. 11d CIT | Analiza porównawcza |

### R0484-R0499: Pracodawca — 16 reguł
| # | R-ID | Reguła | Art. | Kluczowy warunek |
|---|------|--------|------|------------------|
| 484 | R0484 | `employer_obligation_detection` | — | Aktywacja trybu pracodawcy |
| 485 | R0485 | `payroll_pit4r_monthly_20th` | Art. 38 PIT | PIT-4R → zaliczki za pracowników |
| 486 | R0486 | `payroll_pit11_annual_feb28` | Art. 39 PIT | PIT-11 → do 28 lutego |
| 487 | R0487 | `payroll_pit8ar_annual_jan31` | Art. 42 PIT | PIT-8AR → do 31 stycznia |
| 488 | R0488 | `ppk_auto_enrollment` | Art. 32 ustawy PPK | Automatyczny zapis (opt-out) |
| 489 | R0489 | `ppk_employer_contribution_1_5pct` | Art. 31 ustawy PPK | Składka pracodawcy 1.5% |
| 490 | R0490 | `zua_registration_7days` | Art. 36 SUS | ZUS ZUA w 7 dni |
| 491 | R0491 | `dra_monthly_declaration` | Art. 46 SUS | ZUS DRA co miesiąc |
| 492 | R0492 | `rca_imienny_report` | Art. 40 SUS | ZUS RCA — raport imienny |
| 493 | R0493 | `peron_contribution_25_employees` | Art. 21 ustawy PFRON | ≥25 pracowników → PFRON |
| 494 | R0494 | `peron_exemption_open_market` | Art. 22 PFRON | Zakup od ZPCh → ulga |
| 495 | R0495 | `labour_fund_fgsp` | Art. 104-107 | FP 2.45% + FGŚP 0.10% |
| 496 | R0496 | `copyright_50_kup` | Art. 22 ust. 9 PIT | Twórcy → 50% KUP |
| 497 | R0497 | `copyright_50_kup_annual_cap` | Art. 22 ust. 9a PIT | Limit 50% KUP: 120 000 PLN |
| 498 | R0498 | `small_mandate_flat_tax_200pln` | Art. 30 ust. 1 pkt 5a PIT | Umowa zlecenia ≤200 PLN → ryczałt 17% |
| 499 | R0499 | `osh_training_kup_full` | Art. 237³ KP | BHP → 100% KUP |

### R0500-R0545: Środowisko, Restrukturyzacja, Temporal, Digital, Retencja, Fallback — 46 reguł

| # | R-ID | Reguła | Pakiet | Art. | Kluczowy warunek |
|---|------|--------|--------|------|------------------|
| 500 | R0500 | `bdo_registration_required` | environmental | Art. 49 BDO | Wytwarzanie odpadów → BDO |
| 501 | R0501 | `bdo_waste_ledger_obligation` | environmental | Art. 66 BDO | Ewidencja odpadów |
| 502 | R0502 | `kobize_emission_report` | environmental | Art. 7 KOBiZE | Raport emisji CO2 (≥1Mg) |
| 503 | R0503 | `packaging_recycling_fee` | environmental | Art. 13 ustawy | Opłata recyklingowa |
| 504 | R0504 | `water_permit_required` | environmental | Art. 122 PW | Pozwolenie wodnoprawne |
| 505 | R0505 | `battery_disposal_fee` | environmental | Art. 15 ustawy | Opłata za baterie |
| 506 | R0506 | `co2_certificate_trading` | environmental | EU ETS | Handel emisjami CO2 |
| 507 | R0507 | `environmental_annual_fee` | environmental | Art. 286 POŚ | Opłata środowiskowa roczna |
| 508 | R0508 | `jdg_to_spzoo_conversion` | restructuring | Art. 551 KSH | Przekształcenie JDG→Sp. z o.o. |
| 509 | R0509 | `conversion_succession_rights` | restructuring | Art. 584 KSH | Sukcesja praw i obowiązków |
| 510 | R0510 | `conversion_closing_inventory` | restructuring | Art. 24 PIT | Remanent likwidacyjny |
| 511 | R0511 | `conversion_vat_neutrality` | restructuring | Art. 6 pkt 1 VAT | Neutralność VAT przy przekształceniu |
| 512 | R0512 | `jdg_closure_tax_obligations` | restructuring | Art. 24 PIT | Podatek od remanentu likwidacyjnego 10% |
| 513 | R0513 | `conversion_zus_continuity` | restructuring | Art. 17 SUS | Ciągłość ubezpieczeń ZUS |
| 514 | R0514 | `jdg_to_partnership_conversion` | restructuring | Art. 551 KSH | Przekształcenie w spółkę osobową |
| 515 | R0515 | `conversion_employee_transfer` | restructuring | Art. 23¹ KP | Przejście zakładu pracy |
| 516 | R0516 | `temporal_effective_from_metadata` | temporal | Arch. ENTERPRISE | Metadane temporalne reguł |
| 517 | R0517 | `temporal_polski_lad_transition` | temporal | Art. 27 PIT 2022 | Okres przejściowy 01-06.2022 |
| 518 | R0518 | `temporal_historical_pit_rates` | temporal | Art. 27 PIT | Dwie stawki 2019 (17/32%), 2025 (12/32%) |
| 519 | R0519 | `temporal_rmk_vat_rate_by_year` | temporal | Art. 41 VAT | RMK: stawka z roku transakcji |
| 520 | R0520 | `temporal_minimum_wage_history` | temporal | Rozp. RM | Minimalne wynagrodzenie 2018-2026 |
| 521 | R0521 | `temporal_time_travel_opa` | temporal | — | Ewaluacja na datę historyczną |
| 522 | R0522 | `temporal_covid_legacy_deadlines` | temporal | Rozp. COVID | Przedłużone terminy 2020-2021 |
| 523 | R0523 | `temporal_ksef_delayed_2026` | temporal | Art. 106na VAT | KSeF odsunięty na 01.02.2026 |
| 524 | R0524 | `temporal_nbp_fx_date_rule` | temporal | Art. 31a PIT | Kurs NBP z dnia poprzedzającego |
| 525 | R0525 | `temporal_statute_reset_2022` | temporal | Art. 70 Ordynacji | Reset przedawnień po Polskim Ładzie |
| 526 | R0526 | `crypto_income_pit38` | digital | Art. 30b PIT | Krypto → kapitały 19%, PIT-38 |
| 527 | R0527 | `crypto_mining_business_income` | digital | Art. 14 PIT | Mining → działalność gospodarcza |
| 528 | R0528 | `ai_act_high_risk_classification` | digital | AI Act | System wysokiego ryzyka → obowiązki |
| 529 | R0529 | `mdr_cross_border_scheme` | digital | Art. 86a Ordynacji | Schemat podatkowy transgraniczny |
| 530 | R0530 | `mdr_deadline_30_days` | digital | Art. 86f Ordynacji | Zgłoszenie MDR-3 w 30 dni |
| 531 | R0531 | `dac7_platform_seller_30_transactions` | digital | Art. 39j Ordynacji | >30 transakcji lub >2k EUR → DAC7 |
| 532 | R0532 | `dac7_deadline_january_31` | digital | Art. 39n Ordynacji | Raport DAC7 do 31 stycznia |
| 533 | R0533 | `api_degradation_fallback_warning` | digital | — | Awaria API zewnętrznego → fallback |
| 534 | R0534 | `retention_tax_documents_5yr` | retention | Art. 70 Ordynacji | Dokumenty podatkowe → 5 lat |
| 535 | R0535 | `retention_vat_invoices_extended` | retention | Art. 112a VAT | Faktury VAT → do końca okresu korekty |
| 536 | R0536 | `retention_hr_documents_10yr` | retention | Art. 51u SUS | Akta osobowe → 10 lat |
| 537 | R0537 | `retention_electronic_archive_requirements` | retention | Art. 73 UoR | Archiwum elektroniczne — wymogi |
| 538 | R0538 | `retention_destruction_procedure` | retention | Art. 6 RODO | Protokół zniszczenia |
| 539 | R0539 | `retention_vat_invoices_real_estate_10yr` | retention | Art. 91 VAT | Nieruchomości → 10 lat korekty |
| 540 | R0540 | `fallback_domestic_23pct` | fallback | Art. 41 ust. 1 VAT | PL → 23% VAT domyślnie |
| 541 | R0541 | `fallback_eu_reverse_charge_default` | fallback | Art. 17 VAT | UE → reverse charge domyślnie |
| 542 | R0542 | `fallback_non_eu_import_default` | fallback | Art. 17 VAT | NON-EU → IMPORT domyślnie |
| 543 | R0543 | `fallback_scale_pit_default` | fallback | Art. 9a PIT | Brak wyboru formy → skala domyślnie |
| 544 | R0544 | `fallback_zus_standard_default` | fallback | Art. 16-18 SUS | Brak ulgi → standardowy ZUS |
| 545 | R0545 | `fallback_no_match` | fallback | — | NO_MATCHING_RULE (zawsze ostatnia) |

---

## 📦 17. EDGE CASES & INTERACTIONS — 127 reguł (R0546-R0672)

### R0546-R0559: Edge case VAT — 14 reguł
| # | R-ID | Reguła | Scenariusz |
|---|------|--------|------------|
| 546 | R0546 | `edge_vat_breach_mid_year` | Przekroczenie 200k w trakcie roku → VAT od nadwyżki |
| 547 | R0547 | `edge_vat_breach_proportion_new_jdg` | Nowa JDG → proporcjonalny limit VAT |
| 548 | R0548 | `edge_vat_first_invoice_tax_point` | Pierwsza faktura → data = data obowiązku |
| 549 | R0549 | `edge_vat_last_invoice_before_deregister` | Ostatnia faktura przed wyrejestrowaniem |
| 550 | R0550 | `edge_vat_exempt_breach_notification_7days` | Utrata zwolnienia → VAT-R w 7 dni |
| 551 | R0551 | `edge_vat_exempt_breach_retroactive` | Sprzedaż powyżej limitu → VAT retroaktywny |
| 552 | R0552 | `edge_vat_prepayment_full_vat` | Zaliczka 100% → obowiązek VAT w dacie zaliczki |
| 553 | R0553 | `edge_vat_mixed_sale_exempt_taxable` | Sprzedaż mieszana (zwolniona + opodatkowana) → proporcja |
| 554 | R0554 | `edge_vat_correction_chain_reaction` | Korekta jednej faktury → skutki dla JPK i odliczeń |
| 555 | R0555 | `edge_vat_currency_conversion_date` | Faktura walutowa → kurs z dnia obowiązku |
| 556 | R0556 | `edge_vat_self_invoice_obligation` | Samofakturowanie → obowiązek wystawienia za kontrahenta |
| 557 | R0557 | `edge_vat_non_deductible_pro_rata_temporalis` | Zmiana proporcji w trakcie roku → korekta |
| 558 | R0558 | `edge_vat_construction_acceptance_partial` | Częściowy odbiór robót → proporcjonalny VAT |
| 559 | R0559 | `edge_vat_sale_and_leaseback` | Sprzedaż + leasing zwrotny → dwie transakcje |

### R0560-R0573: Edge case PIT — 14 reguł
| # | R-ID | Reguła | Scenariusz |
|---|------|--------|------------|
| 560 | R0560 | `edge_pit_first_year_lump_sum_loss` | Pierwszy rok ryczałtu ze stratą → brak odliczenia KUP |
| 561 | R0561 | `edge_pit_last_year_before_closure` | Ostatni rok → remanent + podatek 10% |
| 562 | R0562 | `edge_pit_double_taxation_abroad` | Dochód zagraniczny + PL → metoda proporcjonalnego odliczenia |
| 563 | R0563 | `edge_pit_linear_health_underpayment` | Liniowy → niedopłata zdrowotnej → dopłata + odsetki |
| 564 | R0564 | `edge_pit_lump_sum_health_progressive` | Ryczałt → przekroczenie progu 300k → wyższa składka |
| 565 | R0565 | `edge_pit_loss_multiple_years` | Straty z kilku lat → kolejność rozliczania (FIFO) |
| 566 | R0566 | `edge_pit_inventory_valuation_method` | Wycena remanentu → cena zakupu vs cena rynkowa (niższa) |
| 567 | R0567 | `edge_pit_spouse_contract_under_authority` | Małżonek na umowie ale podwładny → NKUP |
| 568 | R0568 | `edge_pit_child_labor_under_18` | Praca dziecka → ograniczenia KUP |
| 569 | R0569 | `edge_pit_abroad_relief_abolition` | Ulga abolicyjna → limit 1 360 PLN |
| 570 | R0570 | `edge_pit_rental_income_jdg_vs_private` | Najem → JDG (skala/liniowy) vs prywatny (ryczałt 8.5%) |
| 571 | R0571 | `edge_pit_foreign_currency_loan_fx` | Pożyczka walutowa → różnice kursowe przy spłacie |
| 572 | R0572 | `edge_pit_donation_excess_loss` | Darowizna > dochodu → brak odliczenia (przepada) |
| 573 | R0573 | `edge_pit_health_contrib_scale_7_75_vs_9` | Odliczenie 7.75% od zaliczki vs 9% składki |

### R0574-R0585: Edge case ZUS — 12 reguł
| # | R-ID | Reguła | Scenariusz |
|---|------|--------|------------|
| 574 | R0574 | `edge_zus_start_relief_transition_preferential` | Koniec ulgi na start → automatycznie preferencyjny |
| 575 | R0575 | `edge_zus_maly_plus_36_months_exhaustion` | Koniec Małego ZUS+ → standardowy ZUS |
| 576 | R0576 | `edge_zus_preferential_24_months_exhaustion` | Koniec preferencyjnego → standardowy ZUS |
| 577 | R0577 | `edge_zus_concurrent_jdg_and_mandate` | JDG + umowa zlecenie → tylko zdrowotna z JDG (jeśli zlecenie ≥ min.) |
| 578 | R0578 | `edge_zus_sickness_benefit_waiting_90days` | Chorobowe JDG → dopiero po 90 dniach ubezpieczenia |
| 579 | R0579 | `edge_zus_maternity_benefit_no_health_exemption` | Macierzyński → składka zdrowotna NADAL płatna |
| 580 | R0580 | `edge_zus_health_annual_overpayment_refund` | Nadpłata zdrowotnej → zwrot na wniosek |
| 581 | R0581 | `edge_zus_health_annual_underpayment_deadline_may22` | Niedopłata → termin 22 maja |
| 582 | R0582 | `edge_zus_declaration_zero_on_suspension` | Zawieszenie → zerowe deklaracje DRA |
| 583 | R0583 | `edge_zus_multiple_titles_concurrent` | Kilka tytułów ubezpieczenia → zasada pierwszeństwa |
| 584 | R0584 | `edge_zus_retirement_while_jdg` | JDG + emerytura → tylko zdrowotna |
| 585 | R0585 | `edge_zus_student_under_26_jdg` | Student <26 + JDG → tylko zdrowotna |

### R0586-R0612: Konflikty i interakcje między regułami — 27 reguł
| # | R-ID | Reguła | Konflikt / Interakcja |
|---|------|--------|----------------------|
| 586 | R0586 | `conflict_ipbox_vs_rd_same_income` | IP Box i B+R → NIE ten sam dochód |
| 587 | R0587 | `conflict_ipbox_vs_rd_separate_books` | IP Box + B+R → możliwe jeśli osobna ewidencja |
| 588 | R0588 | `conflict_rd_vs_prototype_same_costs` | B+R i prototyp → NIE te same koszty |
| 589 | R0589 | `conflict_pit0_combined_limit_85k` | PIT-0: młody + powrót + 4+ + senior → łączny limit |
| 590 | R0590 | `conflict_pit0_vs_other_allowances` | PIT-0 → wyklucza inne ulgi od tego samego przychodu |
| 591 | R0591 | `conflict_linear_vs_joint_filing` | Liniowy → NIE wspólne rozliczenie |
| 592 | R0592 | `conflict_linear_vs_child_tax_credit` | Liniowy → NIE ulga na dzieci |
| 593 | R0593 | `conflict_lump_sum_vs_loss_carry_forward` | Ryczałt → NIE rozliczenie straty |
| 594 | R0594 | `conflict_lump_sum_vs_kup` | Ryczałt → NIE ma KUP (tylko przychód) |
| 595 | R0595 | `conflict_tax_card_vs_expansion` | Karta → sztywna kwota, limit pracowników |
| 596 | R0596 | `conflict_scale_vs_linear_former_employer` | Były pracodawca → NIE liniowy przez 3 lata |
| 597 | R0597 | `conflict_vat_exempt_vs_deduction` | Zwolniony z VAT → NIE ma odliczeń |
| 598 | R0598 | `conflict_vat_exempt_vs_ksef` | Zwolniony z VAT → NIE obowiązku KSeF |
| 599 | R0599 | `conflict_mpp_vs_cash_transaction` | MPP → NIE gotówka |
| 600 | R0600 | `conflict_whitelist_vs_foreign_transfer` | WL → tylko PL rachunki |
| 601 | R0601 | `conflict_suspension_vs_depreciation` | Zawieszenie → NIE amortyzacja |
| 602 | R0602 | `conflict_suspension_vs_income_generation` | Zawieszenie → NIE przychody z JDG |
| 603 | R0603 | `conflict_unregistered_vs_vat_deduction` | Dział. nieewidencjonowana → brak VAT |
| 604 | R0604 | `conflict_health_scale_loss_year` | Skala + strata → zdrowotna od minimalnej podstawy |
| 605 | R0605 | `conflict_zus_start_vs_preferential` | Ulga na start → NIE z preferencyjnym jednocześnie |
| 606 | R0606 | `conflict_zus_maly_plus_vs_preferential` | Mały ZUS+ → po preferencyjnym, NIE jednocześnie |
| 607 | R0607 | `conflict_car_leasing_vs_buy_kup_limit` | Auto >150k → limit KUP niezależnie od formy |
| 608 | R0608 | `conflict_home_office_vs_exclusive_business` | Home office vs wyłącznie firmowe → różne % |
| 609 | R0609 | `conflict_bad_debt_vat_vs_pit_timing` | Złe długi VAT → 150 dni; PIT → 90 dni |
| 610 | R0610 | `conflict_fx_method_podatkowa_vs_bilansowa` | Różnice kursowe → metoda podatkowa vs bilansowa |
| 611 | R0611 | `conflict_inventory_fifo_vs_weighted_average` | Wycena zapasów → FIFO (wymagane podatkowo) vs średnia ważona |
| 612 | R0612 | `conflict_donation_limit_6pct_aggregate` | Darowizny → 6% dochodu łącznie (OPP+kościół+krew) |

### R0613-R0672: Walidacje, limity, sankcje, progi — 60 reguł końcowych

| # | R-ID | Reguła | Kategoria | Warunek / Limit |
|---|------|--------|-----------|-----------------|
| 613 | R0613 | `validate_nip_checksum_pl` | Walidacja | Suma kontrolna NIP mod 11 |
| 614 | R0614 | `validate_iban_checksum_pl` | Walidacja | IBAN mod 97, PL=2521 |
| 615 | R0615 | `validate_regon_9digit` | Walidacja | REGON 9-cyfrowy checksum |
| 616 | R0616 | `validate_invoice_date_consistency` | Walidacja | Data faktury ≥ data sprzedaży |
| 617 | R0617 | `validate_date_not_future` | Walidacja | Data nie może być przyszła |
| 618 | R0618 | `validate_date_after_1990` | Walidacja | Data ≥ 1990-01-01 |
| 619 | R0619 | `validate_amount_non_negative` | Walidacja | Kwoty ≥ 0 (chyba że korekta) |
| 620 | R0620 | `validate_vat_rate_valid` | Walidacja | Stawka VAT ∈ {0, 0.05, 0.08, 0.23} |
| 621 | R0621 | `validate_pkpir_column_consistency` | Walidacja | Suma kolumn = poprawna |
| 622 | R0622 | `validate_invoice_numbering_continuity` | Walidacja | Brak luk w numeracji |
| 623 | R0623 | `limit_vat_exemption_200k` | Limit | 200 000 PLN rocznie |
| 624 | R0624 | `limit_lump_sum_2m_eur` | Limit | 2 000 000 EUR rocznie |
| 625 | R0625 | `limit_small_taxpayer_2m_eur` | Limit | 2 000 000 EUR brutto |
| 626 | R0626 | `limit_full_accounting_2m_eur` | Limit | PKPiR→Księgi: 2 000 000 EUR |
| 627 | R0627 | `limit_cash_transaction_15k` | Limit | 15 000 PLN B2B |
| 628 | R0628 | `limit_mpp_15k` | Limit | MPP obowiązkowy ≥15k PLN |
| 629 | R0629 | `limit_tax_free_amount_30k` | Limit | Kwota wolna 30 000 PLN |
| 630 | R0630 | `limit_pit_scale_threshold_120k` | Próg | Próg skali: 120 000 PLN |
| 631 | R0631 | `limit_car_depreciation_150k` | Limit | Auto osobowe → max 150k PLN |
| 632 | R0632 | `limit_car_electric_225k` | Limit | Auto elektryczne → max 225k PLN |
| 633 | R0633 | `limit_health_linear_deduction_12900` | Limit | Odliczenie zdrowotnej liniowy: 12 900 PLN |
| 634 | R0634 | `limit_rd_relief_capped_at_income` | Limit | B+R ≤ dochód |
| 635 | R0635 | `limit_donation_6pct_income` | Limit | Darowizny ≤ 6% dochodu |
| 636 | R0636 | `limit_thermo_53k` | Limit | Termomodernizacja: 53 000 PLN |
| 637 | R0637 | `limit_prototype_300k` | Limit | Prototyp: 300 000 PLN |
| 638 | R0638 | `limit_expansion_1m` | Limit | Ekspansja: 1 000 000 PLN |
| 639 | R0639 | `limit_pit0_combined_85_528` | Limit | PIT-0 łączny: 85 528 PLN |
| 640 | R0640 | `limit_loss_50pct_annual` | Limit | Strata: max 50% rocznie |
| 641 | R0641 | `limit_loss_one_time_5m` | Limit | Strata jednorazowo: 5 000 000 PLN |
| 642 | R0642 | `limit_cash_register_exemption_20k` | Limit | Kasa fiskalna: 20 000 PLN |
| 643 | R0643 | `limit_unregistered_activity_50pct` | Limit | Dział. nieewidencj.: 50% min. wynagr. |
| 644 | R0644 | `limit_giif_reporting_15k_eur` | Limit | GIIF: 15 000 EUR |
| 645 | R0645 | `limit_cesop_reporting_25k_eur` | Limit | CESOP: 25 000 EUR |
| 646 | R0646 | `sanction_jpk_error_500` | Sankcja | Błąd JPK → 500 PLN |
| 647 | R0647 | `sanction_ksef_missing_100pct` | Sankcja | Brak KSeF → 100% VAT |
| 648 | R0648 | `sanction_late_filing_vat_500_5000` | Sankcja | Nieterminowa deklaracja VAT → 500-5k PLN |
| 649 | R0649 | `sanction_unregistered_activity` | Sankcja | Brak CEIDG → KKS |
| 650 | R0650 | `sanction_mpp_violation_30pct` | Sankcja | Brak MPP → 30% VAT |
| 651 | R0651 | `sanction_whitelist_transfer` | Sankcja | Przelew poza WL → solidarna odpowiedzialność |
| 652 | R0652 | `sanction_bad_debt_debtor_30pct` | Sankcja | Brak korekty złych długów → 30% |
| 653 | R0653 | `sanction_cash_over_15k_kup_loss` | Sankcja | Gotówka >15k → NKUP + 20% |
| 654 | R0654 | `sanction_dac7_non_reporting_1m` | Sankcja | Brak DAC7 → do 1M PLN |
| 655 | R0655 | `sanction_mdr_non_reporting` | Sankcja | Brak MDR → KKS |
| 656 | R0656 | `deadline_vat_declaration_25th` | Termin | VAT → 25. dzień miesiąca |
| 657 | R0657 | `deadline_vat_quarterly_25th` | Termin | VAT kwartalny → 25. dzień po kwartale |
| 658 | R0658 | `deadline_pit_advance_20th` | Termin | Zaliczka PIT → 20. dzień miesiąca |
| 659 | R0659 | `deadline_pit_annual_april30` | Termin | PIT-36/36L → 30 kwietnia |
| 660 | R0660 | `deadline_pit28_february28` | Termin | PIT-28 → 28 lutego |
| 661 | R0661 | `deadline_zus_payment_10th` | Termin | ZUS → 10. dzień miesiąca |
| 662 | R0662 | `deadline_zus_payment_15th` | Termin | ZUS (jednostki) → 15. dzień |
| 663 | R0663 | `deadline_whitelist_verification_30days` | Termin | WL → weryfikacja co 30 dni |
| 664 | R0664 | `deadline_whitelist_3day_buffer` | Termin | WL → przelew w 3 dni od weryfikacji |
| 665 | R0665 | `deadline_correction_vat_3_months` | Termin | Korekta VAT → 3 mies. |
| 666 | R0666 | `deadline_ksef_offline_7_days` | Termin | KSeF offline → 7 dni |
| 667 | R0667 | `deadline_tax_audit_14days_correct` | Termin | Korekta po protokole → 14 dni |
| 668 | R0668 | `deadline_overpayment_refund_45days` | Termin | Zwrot nadpłaty → 45 dni |
| 669 | R0669 | `deadline_annual_health_may22` | Termin | Rozliczenie zdrowotnej → 22 maja |
| 670 | R0670 | `deadline_pit11_employee_feb28` | Termin | PIT-11 → 28 lutego |
| 671 | R0671 | `deadline_vat_r_registration_before_first` | Termin | VAT-R → przed pierwszą czynnością |
| 672 | R0672 | `deadline_statute_limitations_5yr` | Termin | Przedawnienie → 5 lat |

---

## 📊 STATYSTYKI KOŃCOWE

| Metryka | Wartość |
|---|---|
| **Łączna liczba reguł** | **672** |
| **Pakiety** | 28 |
| **Artykuły prawne** | 150+ |
| **Reguły VAT** | 129 (R0069-R0197) |
| **Reguły PIT** | 102 (R0198-R0299) |
| **Reguły ulg** | 38 (R0300-R0337) |
| **Reguły ZUS** | 34 (R0338-R0371) |
| **Reguły księgowe** | 28 (R0372-R0399) |
| **Reguły biznesowe** | 20 (R0400-R0419) |
| **Reguły korekt** | 16 (R0420-R0435) |
| **Reguły odpowiedzialności** | 14 (R0436-R0449) |
| **Reguły reprezentacji** | 10 (R0450-R0459) |
| **Reguły compliance** | 22 (R0029-R0050) |
| **Reguły crossborder** | 18 (R0051-R0068) |
| **Reguły risk/routing** | 28 (R0001-R0028) |
| **Reguły międzynarodowe** | 14 (R0470-R0483) |
| **Reguły pracodawcy** | 16 (R0484-R0499) |
| **Reguły pomocnicze** | 46 (R0500-R0545) |
| **Edge cases & interakcje** | 127 (R0546-R0672) |

---

> **🔥 Następny krok:** Wybór 127 reguł edge cases/interakcji do priorytetowej implementacji — to one zapewniają bezpieczeństwo ENTERPRISE.

---

*Wygenerowano przez NexusAI Ultra-Granularity Engine v11.0 — 672 reguły × 10 pól = 6 720 punktów decyzyjnych.*
*Data: 2026-07-11*
