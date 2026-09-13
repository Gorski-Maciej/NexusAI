# MAPY ROLWE V3-P60 — ścieżki czytania per rola (I05/I12)

<!--
artifacts: [docs/ROLE_MAPS.md, docs/SLOWNIK_REFERENCJI_PRAWNYCH.md, rules/v3_p60_documentation_closure.rego]
status: ACTIVE
owner: docs
verified: 2026-09-13
verify_cmd: python3 tools/v3_p60_engines.py I05 && python3 tools/v3_p60_engines.py I12
-->

Cztery role wymagane progiem `v3_p60_roles_required` (ADR-002, blok `v3_p60`
w `rules/thresholds_jdg.rego`): **developer, operator, auditor, entrepreneur**.
Pokrycie 100% egzekwuje bramka I12 (`v3_p60_role_coverage_min_pct=100`).
Ścieżka czytania = onboarding w minuty, nie w dni.

## DEVELOPER — ścieżka A→B→C
| Krok | Dokument | Co daje |
|------|----------|---------|
| A | docs/ARCHITEKTURA.md + docs/ARCHITECTURE.md | architektura (PL/EN, paroliść I11) |
| B | docs/DEVELOPER_GUIDE.md + docs/OPA_REGO_DEVELOPER_GUIDE.md | pisanie reguł wg konwencji P51–P59 |
| C | docs/KATALOG_REGUL.md (generowany z rule_registry, I02) | istniejące rule_id — rozszerzaj, nie dubluj |
| D | docs/SLOWNIK_REFERENCJI_PRAWNYCH.md | spójność terminologiczna (I10) |
| E | tests/rego/ + tests/auto/ | wzorce testów (natywne Rego + pytest) |

## OPERATOR — ścieżka RUN
| Krok | Dokument | Co daje |
|------|----------|---------|
| A | docs/API_REFERENCJA.md | integracja z silnikiem |
| B | docs/KATALOG_NARZEDZI.md | narzędzia walidacji i bramki |
| C | bundles/v3_p37_status_page.json + SLO (P37/P58) | zdrowie systemu, error budget |
| D | docs/CONTROL_PLANE_RULE_LIFECYCLE.md | cykl życia reguł (SHADOW→ACTIVE) |

## AUDITOR — ścieżka dowodowa
| Krok | Dokument | Co daje |
|------|----------|---------|
| A | docs/LEGAL_TWIN_TRACEABILITY.md | reguła→akt→test→bundle (proweniencja) |
| B | docs/LEGAL_REFERENCE_ACTS.md + docs/LEGAL_SOURCE_REGISTRY.md | akty i status weryfikacji ISAP |
| C | bundles/v3_p11_* (Decision Certificate, P11) | certyfikaty decyzji |
| D | docs/MANIFEST_2_0.md | metryki z jednego źródła (rejestry, I01/I02) |
| E | `python3 tools/v3_p60_engines.py I06` | eksport audytowy z checksumami (I06) |

## ENTREPRENEUR — podręcznik
| Krok | Dokument | Co daje |
|------|----------|---------|
| A | docs/FAQ.md | odpowiedzi praktyczne JDG |
| B | docs/LOGIKA_BIZNESOWA.md | jak silnik podejmuje decyzje (fail-closed) |
| C | docs/KALENDARZ_ZMIAN_PRAWNYCH.md | terminy i nowelizacje (P25) |

## Zasada bindingu (I03)
Każdy dokument rdzenia ma front-matter z polami: `artifacts`, `status`, `owner`,
`verify_cmd`. Bramka I03 blokuje dokument bez bindingu; `verify_cmd` to
polecenie, które dowodzi, że dokument mówi prawdę (przykład-as-test, I09).

Powiązane analizy P60: I05 (mapy rolowe), I12 (pokrycie ról 100%),
I03 (front-matter), I09 (przykłady-as-test), I10 (glosariusz).

## ACCOUNTANT — ścieżka księgowa (P63-I12)
| Krok | Dokument | Co daje |
|------|----------|---------|
| A | docs/LOGIKA_BIZNESOWA.md | jak silnik podejmuje decyzje (fail-closed) |
| B | docs/API_REFERENCJA.md | pola werdyktu widoczne dla roli accountant (RBAC P40-I04) |
| C | docs/AUTOMATYZACJA_KSIEGOWOSCI_P18.md | pipeline faktury → ewidencje → deklaracje |

## ADMIN — ścieżka operacyjna platformy (P63-I12)
| Krok | Dokument/narzędzie | Co daje |
|------|--------------------|---------|
| A | docs/ARCHITEKTURA.md | architektura i wiring (main_jdg) |
| B | docs/ROLE_MAPS.md | własna rola i granice (this document) |
| C | bundles/v3_p40_rbac_minimization.json | dowód mapowania rola→pola (SoD P63-I02) |

Onboarding roli (P63-I12): przydział roli = pakiet (dostępy z RBAC as data,
ścieżka czytania z tej mapy, obowiązki audytowe P63-I05). Zero ról bez
dokumentu i testu — bramka `python3 tools/v3_p63_engines.py I12`.
