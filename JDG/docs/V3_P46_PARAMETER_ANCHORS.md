# V3-P46-I12 — Anchory dokumentacyjne parametrów

Każdy parametr thresholds_data ma anchor: co znaczy, skąd się wziął, kiedy wygasa (P41). Generowane narzędziem; treść merytoryczną potwierdza człowiek (4-eyes). Statusy ISAP [NIEZWERYFIKOWANE] → weryfikacja P47.

### `vat.exemption_housing_area_m2_max`
- **Znaczenie:** Parametr vat.exemption_housing_area_m2_max (generowane przez I12 — do uzupełnienia człowieka).
- **Źródło (akt):** Art. 43 ust. 1 pkt 7-8 ustawy o VAT (zwolnienie budownictwo mieszkaniowe, powierzchnia do 80 m2) [NIEZWERYFIKOWANE]
- **Okno temporalne:** 2026-01-01 → otwarte
- **Właściciel:** v3_p12_exemption_matrix

### `vat.exemption_suspended_years`
- **Znaczenie:** Parametr vat.exemption_suspended_years (generowane przez I12 — do uzupełnienia człowieka).
- **Źródło (akt):** Art. 113 ust. 14 ustawy o VAT (zakaz ponownego zwolnienia po utracie) [uwaga: raport V3_P12 Q01 - ust. 11 vs ust. 14 do weryfikacji ISAP] [NIEZWERYFIKOWANE]
- **Okno temporalne:** 2026-01-01 → otwarte
- **Właściciel:** v3_p12_waiver_tracker

### `vat.limit_113`
- **Znaczenie:** Parametr vat.limit_113 (generowane przez I12 — do uzupełnienia człowieka).
- **Źródło (akt):** Art. 113 ust. 1 ustawy o VAT (zwolnienie podmiotowe 200 000 PLN) [NIEZWERYFIKOWANE]
- **Okno temporalne:** 2026-01-01 → otwarte
- **Właściciel:** v3_p12_limit113_sentinel

### `vat.np_rate`
- **Znaczenie:** Parametr vat.np_rate (generowane przez I12 — do uzupełnienia człowieka).
- **Źródło (akt):** Art. 41 ust. 1 ustawy o VAT (nie podlega opodatkowaniu); JPK_V7 pole P_NP [NIEZWERYFIKOWANE]
- **Okno temporalne:** 2026-01-01 → otwarte
- **Właściciel:** v3_p12_rates_as_data

### `vat.reduced_rate_5`
- **Znaczenie:** Parametr vat.reduced_rate_5 (generowane przez I12 — do uzupełnienia człowieka).
- **Źródło (akt):** Art. 41 ust. 10 ustawy o VAT w zw. z zal. 10 (wykaz towarow/uslug 5%) [NIEZWERYFIKOWANE]
- **Okno temporalne:** 2026-01-01 → otwarte
- **Właściciel:** v3_p12_rates_as_data

### `vat.reduced_rate_8`
- **Znaczenie:** Parametr vat.reduced_rate_8 (generowane przez I12 — do uzupełnienia człowieka).
- **Źródło (akt):** Art. 41 ust. 2 ustawy o VAT w zw. z zal. 10 (wykaz towarow/uslug 8%) [NIEZWERYFIKOWANE]
- **Okno temporalne:** 2026-01-01 → otwarte
- **Właściciel:** v3_p12_rates_as_data

### `vat.standard_rate`
- **Znaczenie:** Parametr vat.standard_rate (generowane przez I12 — do uzupełnienia człowieka).
- **Źródło (akt):** Art. 41 ustawy o VAT [NIEZWERYFIKOWANE]
- **Okno temporalne:** 2026-01-01 → otwarte
- **Właściciel:** system

### `vat.zero_rate`
- **Znaczenie:** Parametr vat.zero_rate (generowane przez I12 — do uzupełnienia człowieka).
- **Źródło (akt):** Art. 41 ust. 2-13 ustawy o VAT (przypadki stawki 0%) [NIEZWERYFIKOWANE]
- **Okno temporalne:** 2026-01-01 → otwarte
- **Właściciel:** v3_p12_rates_as_data
