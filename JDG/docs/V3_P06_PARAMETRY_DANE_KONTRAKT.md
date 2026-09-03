# V3-P06 KONTRAKT PARAMETRÓW I DANYCH (WIĄŻĄCY DLA P07–P68)

Kontrakt wyjściowy części P06 (PARAMETRY_DANE). Wiąże: P07 (rule lifecycle),
P08 (Law Radar), P09 (declarative change), P10 (golden oracle), P12–P36 (części
domenowe — migracja wartości), P37 (obserwowalność), P38 (deployment), P39
(testy/CI). Źródło: prompty_v3/V3_PROMPT_P06_PARAMETRY_DANE.txt §11.2 +
wnioski RAPORT_V3_P06_PARAMETRY_DANE.txt (12 innowacji; bramki 5 PASS / 7 FAIL;
luki L01–L19).

---

## K1. Schemat parametru v2 (I01) — wiąże P07–P36
- Każdy parametr w JSON store (`bundles/thresholds_data.json`) ma pełny rekord:
  `key`, `value`, `unit`, `valid_from`, `valid_to`, `source_act`, `article`,
  `changed_by`, `changed_at`, `scope` (global/domain/context).
- Walidacja przy zapisie: typ value zgodny z schema; zakres min/max **typu
  number** (naprawa TypeError z data_service.validate — L05); okno temporalne
  spójne (P05: zero luk/nakładek); `source_act`+`article`+`valid_from`
  obowiązkowe (odrzucenie zapisu bez nich).
- Konwencja jednostek **jednolita i jawna** (L19): pole `unit` obowiązkowe —
  ułamek (0.23) vs procent całościowy (9.76) vs kwota (PLN) — konwersja przy
  migracji z warstwy danych kodu.
- Pokrycie: migracja wartości z `thresholds_jdg.rego` (617 liści w 63 mapach)
  do JSON store wg priorytetów I12 (mapy używane przez decyzje) — L01 (P0).

## K2. Zero-Hardcode Gate (I02) — wiąże P39
- Klasyfikacja wartości w regułach: `DEFAULT_LITERAL` (fallback object.get),
  `DOMAIN_VALUE` (logika decyzyjna — do migracji), `STRUCTURAL`, `METADATA`.
- Bramka CI: linie z logiką (=> := < > object.get sprintf count) bez tokenów
  w stringach; licznik = kandydaci DOMAIN_VALUE (dziś 2 503 w 225 plikach);
  limit allowlisty: 200 legacy → każda nowa wartość = FAIL [BM].
- JEDNO źródło prawdy audytu: unifikacja trzech rozjazdów (docs 265 /
  hardcoded_audit_gate 13 595 / hardcoded_audit KPI 26 373) na klasyfikacji I02
  — L04 (P1).

## K3. Lineage dwukierunkowe (I03) — wiąże P08/P07/P10
- Graf: reguła→mapa parametrów oraz mapa→reguły (parser data.thresholds.jdg.*);
  top użycia: depreciation (49), automatyzacja_ksiegowosci (23), pit (11)...
- Każda zmiana parametru = lista dotkniętych reguł (lineage) + testy [BM] +
  wpis analizy wpływu (P08 Law Radar).
- ORPHAN (53 mapy / brak konsumenta) — przegląd przed migracją; GHOST — 0 dziś;
  ciche fallbacki object.get (84) → fail-closed: brak parametru = NEEDS_ADVICE
  dla pól krytycznych (L03/L07).

## K4. Golden Data Dataset (I04) — wiąże P10/P39
- Dataset certyfikowany: wszystkie liściowe wartości (617) + wiersze graniczne
  (±0.01, zero) + checksum sha256-canonical-json-v1 (P05/P03 kanon).
- Zmiana danych bez zielonego golden datasetu = blokada merge [BM];
  zmiana danych = sygnał do re-ewaluacji golden verdicts dotkniętych map (I03).
- Procedura certyfikacji 4-eyes (właściciel, cykl, podpis) do ustanowienia —
  L09 (P2).

## K5. Hot-Reload SLO (I05) — wiąże P38/P09
- SLO: zatwierdzenie → aktywność < 1 min (twarde < 15 min); kroki:
  approve → write_json → validate → export → data_api_push → eval_active.
- Wymagane artefakty: `thresholds_export.json` (eksport OPA Data API) w CI —
  dziś BRAK (L10); walidacja zielona (L05); pomiar z zegara wstrzykiwanego
  (P05-I08) w runtime.

## K6. Feedery zewnętrzne (I06) — wiąże P08/P37/P12–P36
- Parametry ze źródeł zewnętrznych: `minimum_wage_gross` (4800), `eur_pln`/
  `eur_pln_rate_default` (4.5), kursy NBP, limit 30-krotności ZUS — bez
  mechanizmu feedu (L11 P2); wartość ręczna, ryzyko dezaktualizacji.
- Feeder: NBP (codziennie), MRPiPS (corocznie), ZUS (corocznie) — walidacja
  zakresu + wpis audytowy; brak wpisu = odrzucenie (fail-closed).
- Status źródeł: [NIEZWERYFIKOWANE] do mediacji ISAP/RCL/MF/ZUS.

## K7. Mapy kontekstowe (I07) — wiąże P12–P36
- Przestrzeń nazw `namespace.context.code` (pl.teryt.XXXXXX / pl.pkd.A.BB.C /
  domain.param); klucz bez rekordu w rejestrze kodów = odrzucenie.
- Stawki gminne (UPOL art. 5) jako parametry z walidacją zakresu ustawowego —
  schema v2 z wymiarem scope=context (L12 P2).

## K8. Rollback parametru (I08) — wiąże P38/P09/P10
- Zmiana append-only + snapshot poprzedniej wersji; rollback: 4-eyes + zielony
  golden dataset (I04) + nowy snapshot_id (P05-I02) + dowód w golden replay.
- Dziś vat.standard_rate ma 1 wersję — brak głębi historii (L13 P1): każda
  zmiana musi zachowywać wersję poprzednią.

## K9. Dashboard świeżości (I09) — wiąże P37
- Metryki: `parameter_count`, `parameter_age_max_days`,
  `parameter_source_verified_pct`, `parameter_feed_freshness_days`;
  alert na wiek > 365 dni / brak wersji; status verified per parametr
  (dziś 0% — L16 P3).
- Rejestr mediacji źródeł (ISAP/RCL/MF/ZUS) jako część raportu (9.05).

## K10. Formularz deklaratywny V2/F6 (I10) — wiąże P09
- Pipeline: opis ludzki → walidacja zbioru ustawowego → wersja payload →
  PR/4-eyes → hot-reload (I05) → golden dataset (I04).
- Walidacja zbiorami ustawowymi: VAT {0,5,8,23%} (art. 41/146a), ryczałt
  {3..17%} (art. 12), PIT skala {12,32%} (art. 27(1)); wartość poza zbiorem =
  odrzucenie (dowód I10: 0.25 VAT odrzucony, 0.08 przyjęty).

---

## Rejestr luk wiążących

| ID | Priorytet | Właściciel domknięcia |
|---|---|---|
| V3-P06-L01 | P0 | Migracja 617 wartości do JSON store wg lineage (K1/K3) — P07–P36 |
| V3-P06-L02 | P1 | 2 503 kandydatów DOMAIN_VALUE — zero-hardcode gate [BM] (K2) |
| V3-P06-L03 | P1 | 53 mapy ORPHAN (dane bez konsumenta) — przegląd (K3) |
| V3-P06-L04 | P1 | Rozjazd 3 audytów hardcode — unifikacja (K2) |
| V3-P06-L05 | P1 | TypeError data_service.validate (schema string vs float) — naprawa (K1) |
| V3-P06-L07 | P2 | 84 ciche fallbacki object.get — fail-closed (K3) |
| V3-P06-L09 | P2 | Procedura certyfikacji golden datasetu (K4) |
| V3-P06-L10 | P1 | thresholds_export.json brak — eksport w CI (K5) |
| V3-P06-L11 | P2 | Feedery zewnętrzne (minimum_wage, EUR/PLN) — (K6) |
| V3-P06-L12 | P2 | Kontekst (TERYT/PKD) poza schema — (K7) |
| V3-P06-L13 | P1 | Historia wersji (1 wersja) — rollback niemożliwy (K8) |
| V3-P06-L16 | P3 | verified=0% źródeł — mediacja ISAP (K9) |
| V3-P06-L18 | P3 | Telemetria runtime (P37) pierwsza emisja (I12) |
| V3-P06-L19 | P2 | Niejednolita jednostka (ułamek vs pct vs kwota) — unit w schema (K1) |

Konflikty kontraktowe z wcześniejszymi częściami: brak KONFLIKTÓW — P06 realizuje
ADR-002 (parametry-as-data), rozszerza schema temporalną P05 (okna w store),
honoruje snapshot_id (P05-I02) i kanon hashowania sha256-canonical-json-v1.
