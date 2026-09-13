# KONWENCJA DOKUMENTACJI V3-P60 — DOKUMENT MÓWI PRAWDĘ O KODZIE

<!--
artifacts: [docs/DOC_STANDARD_P60.md, rules/v3_p60_documentation_closure.rego, rules/thresholds_jdg.rego, tools/v3_p60_engines.py]
status: ACTIVE
owner: docs
verified: 2026-09-13
verify_cmd: python3 tools/v3_p60_engines.py I03 && python3 tools/v3_p60_engines.py I01
-->

Ten dokument JEST kontraktem wyjściowym P60 dla części P61–P68 (format front-matter,
statusy, eksport audytowy). Honoruje kontrakty: P34 (siec walidacji L4),
P36 (generatory), P41 (docs-as-code, bramka 6b), P47 (konwencja cytowań),
P50 (jedno źródło prawdy), P59 (security), P68 (re-certyfikacja).

## 1. Front-matter — binding dokument↔kod (I03)

Każdy dokument rdzenia rozpoczyna się blokiem:

```
<!--
artifacts: [docs/PRZYKLAD.md, tools/przyklad.py]
status: ACTIVE | ARCHIVAL | SUPERSEDED
owner: docs | core | security | legal
verify_cmd: python3 tools/... (dowód prawdy, uruchamiany w CI)
-->
```

Bramka I03 (`v3_p60_frontmatter_required_fields`) blokuje dokument rdzenia bez
tych pól. `verify_cmd` spełnia jednocześnie I09 (example-as-test): polecenie
musi się dać uruchomić i musieć wyjść z kodem 0.

## 2. Statusy dokumentów

| Status | Znaczenie | Bramka |
|--------|-----------|--------|
| ACTIVE | opisuje dzisiejszy kod; liczby z rejestrów | I01/I03/I07 |
| ARCHIVAL | opisuje przeszłość kampanii (dryf czasowy 5.1) | nie może być cytowany jako stan |
| SUPERSEDED | zastąpiony; widmo po korekcie (I04) | referencje przechodzą na następcę |

## 3. Zero ręcznych liczb (I01/I02)

Każda liczba w dokumencie rdzenia pochodzi z rejestru: `rule_registry.json`,
`manifest_v2.json`, `v3_campaign_ledger.json`. Snippety generuje
`tools/v3_p60_engines.py` (I02) do `bundles/v3_p60_*.json`; dokumenty
odwołują się do bundli zamiast wklejać wartości. Rozjazd dokument↔rejestr =
BLOCK (I01), zgodnie z P34-L4.

## 4. Dokumenty święte (I08)

`docs/ARCHITEKTURA_OPA_ENTERPRISE_TARGET.md` (V1) i `docs/WIZJA_OPA_ENTERPRISE_V2.md`
(V2) są nadrzędne: zmiana tylko z ADR + review prawne (CODEOWNERS — decyzja
właściciela repo, patrz raport P60 Q02). Status ochrony mierzy I08.

## 5. PL/EN parity (I11)

`ARCHITEKTURA.md` (PL) i `ARCHITECTURE.md` (EN) są porównywane semantycznie
(nagłówki sekcji + pojęcia kluczowe). Dryf poniżej
`v3_p60_plen_parity_min_pct=80` = BLOCK. Kolejność prawdy: PL jest źródłem,
EN tłumaczeniem [ZAŁOŻENIE].

## 6. Eksport audytowy (I06)

Jedna komenda: `python3 tools/v3_p60_engines.py I06` →
`bundles/v3_p60_audit_export.json` (dokumenty + rejestry + checksumy sha256 +
retencja 1825 dni — kontekst UoR art. 74/75 [NIEZWERYFIKOWANE — ISAP]).

## 7. Glosariusz (I10)

Terminy prawne wyłącznie wg `docs/SLOWNIK_REFERENCJI_PRAWNYCH.md`
(podstawa P47). Lint terminologiczny: I10 (`v3_p60_glossary_terms_min=12`).

## 8. Mapy rolowe (I05/I12)

`docs/ROLE_MAPS.md` — ścieżki czytania dla developer/operator/auditor/
entrepreneur; pokrycie 100% egzekwowane bramką I12.

## Glosariusz aktów (I10 — lint terminologiczny P60)

Kanoniczne nazwy aktów z [SLOWNIK_REFERENCJI_PRAWNYCH.md](SLOWNIK_REFERENCJI_PRAWNYCH.md) (jedno źródło prawdy, konwencja cytowań P47). Każdy dokument P60 używa WYŁĄCZNIE tych form:

- `ustawa o VAT`
- `ustawa o PIT`
- `ustawa o CIT`
- `ustawa o ryczałcie`
- `Ordynacja podatkowa`
- `Kodeks karny skarbowy`
- `ustawa o SUS`
- `ustawa o świadczeniach opieki zdrowotnej`
- `ustawa o zasiłku pieniężnym`
- `ustawa o rachunkowości`
- `rozporządzenie PKPiR`
- `Prawo przedsiębiorców`
- `ustawa o CEIDG`
- `ustawa o zarządzie sukcesyjnym`
- `ustawa o PCC`
- `ustawa o podatkach i opłatach lokalnych`
- `ustawa o podatku akcyzowym`
- `ustawa o podatku rolnym`
- `ustawa o podatkach i opłatach lokalnych (środki transportowe)`
- `ustawa o BDO`
- `RODO`
- `ustawa o AML`
- `ustawa o KSeF`
- `ustawa o e-Doręczeniach`
- `Kodeks pracy`
- `ustawa o rehabilitacji zawodowej`
- `Prawo budowlane`
- `ustawa o transporcie drogowym`
- `Prawo dewizowe`
- `ustawa o energii elektrycznej`

*Sekcja generowana z rejestru (I02 — zero ręcznych liczb); walidacja: `python3 tools/v3_p60_engines.py I10`.*
