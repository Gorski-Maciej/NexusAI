# 🏰 KAMPANIA GLM 5.2 — FORTYFIKACJA MODUŁU JDG DO POZIOMU ENTERPRISE
## Manifest master — 19 Promptów + protokół pracy (jeden Prompt = jeden plik .txt)

> **Cel kampanii:** wzmocnić silnik reguł podatkowych OPA w katalogu `JDG/` do najwyższego
> zaawansowanego poziomu Enterprise — ufortyfikowana forteca niechybnej Śmierci dla błędów,
> z pełnym pokryciem prawnym, zero-defect, niezniszczalną niezawodnością i błyskawiczną
> adaptacją do zmian prawa (OPA jako rozbudowany SYSTEM — wg dokumentów świętych V1+V2).
> **Katalog docelowy (repo):** https://github.com/Gorski-Maciej/NexusAI/tree/main/JDG

---

## 1. Dlaczego 19 Promptów? (budżet kontekstu GLM 5.2)

- GLM 5.2 ma okno kontekstowe **1 000 000 tokenów** (opcjonalnie; domyślnie ~200K).
- **Twarda zasada:** dane i informacje dostarczone do modelu (przeczytane pliki + treść promptu)
  mogą zająć **maksymalnie 50% okna kontekstowego (~500K tokenów)** — reszta musi zostać
  wolna na głębokie myślenie, głęboką analizę i wygenerowanie ogromnego raportu.
- Katalog JDG to ~74 MB ≈ **5–6 mln tokenów** (469 plików Rego ~3,5 mln; Python ~1 mln;
  dokumentacja/testy/dane ~1 mln+). **Nie mieści się w jednym oknie — dlatego kampania
  dzieli go na 19 części**, a każda część jest analizowana w osobnej sesji GLM.
- Każdy Prompt jest **samowystarczalny** (linki do plików + święte dokumenty + kontrakty
  spójności) i kończy się poleceniem **WYCZYŚĆ OKNO KONTEKSTOWE** przed przejściem do następnego.

## 1a. Pełne pokrycie katalogu linkami (zweryfikowane: 1108/1108 plików)

- **1108 realnych plików katalogu JDG** (rules/ · tools/ · docs/ · tests/ · bundles/ · api/ ·
  migrations/ · reports/ + pliki główne) ma **bezpośredni link GitHub w co najmniej jednym
  Prompcie** — każdy plik jest przypisany do swojej części tematycznej (sekcja
  „🔗 SUPLEMENT LINKÓW — PEŁNE POKRYCIE KATALOGU JDG” w każdym Prompcie).
- Wyłączone z pokrycia są wyłącznie artefakty generowane (backupy `*.bak`/`*.p03backup`,
  paczki `*.tar.gz`, `*.sbom.json`, `*.signature`, `.tmp.json`, katalogi `.benchmarks`/`.hypothesis`).
- **Kombinacje odnośników:** każdy Prompt zawiera sekcję „🔗 KOMBINACJE LINKÓW KRZYŻOWYCH”
  z 7–8 linkami do plików **innych części** (punkty styku: rule_id, werdykt 25-polowy,
  temporalność, thresholds) — GLM analizuje każdą część **z każdej strony OPA**: reguły ↔
  narzędzia ↔ testy ↔ dokumenty ↔ dane pokrycia ↔ inne domeny.
- Martwe linki: **0** (weryfikacja automatyczna: każdy link wskazuje istniejący plik;
  linki `tree/…/tests/auto` i `tree/…/tests/rego` to celowe linki do katalogów).

## 2. Kolejność wykonywania (sekwencyjna — zależności)

| # | Prompt | Część katalogu JDG | Zależny od |
|---|---|---|---|
| 01 | PROMPT_01_ORKIESTRATOR_FUNDAMENT.txt | Orkiestrator, rdzeń, control plane, raporty pokrycia | — (start) |
| 02 | PROMPT_02_VAT_MAKRO.txt | VAT Macro + MPP/Split Payment + stawki | 01 |
| 03 | PROMPT_03_VAT_MIKRO_JPK.txt | VAT Micro atomowe + JPK | 01, 02 |
| 04 | PROMPT_04_KSEF_JPK_EDEKLARACJE.txt | KSeF, JPK, e-Deklaracje, GTU, WIS, e-Doręczenia | 01, 03 |
| 05 | PROMPT_05_PIT_MAKRO.txt | PIT Macro: formy, KUP, zaliczki, zeznania | 01 |
| 06 | PROMPT_06_PIT_MIKRO_AMORTYZACJA.txt | PIT Micro atomowe + amortyzacja + NKUP | 01, 05 |
| 07 | PROMPT_07_ULGI_OPTYMALIZACJA.txt | Ulgi PIT (B+R, IP Box, termo…) + optymalizacja | 05, 06 |
| 08 | PROMPT_08_ZUS_MAKRO_ZDROWOTNA.txt | ZUS Macro: składki, zdrowotna, zasiłki, PPK/PFRON | 01 |
| 09 | PROMPT_09_ZUS_MIKRO_ZASILKI.txt | ZUS Micro: SUS a6–a47, zdrowotna a79–a82, zasiłkowa | 08 |
| 10 | PROMPT_10_KSIEGOWOSC_PKPIR_UOR.txt | PKPiR, UoR, amortyzacja księgowa, leasing, transformacja | 05, 06 |
| 11 | PROMPT_11_KKS_ORDYNACJA_AUDYT.txt | KKS, Ordynacja podatkowa, audyt, kontrole, obrona | 01 |
| 12 | PROMPT_12_CROSSBORDER_MDR.txt | Cross-border, TP, CFC, MDR/DAC6, ViDA, CBAM | 02, 05 |
| 13 | PROMPT_13_RYCZALT_CYKL_ZYCIE.txt | Ryczałt, CEIDG, Prawo przedsiębiorców, sukcesja | 05, 01 |
| 14 | PROMPT_14_PCC_LOKALNE_AKCYZA.txt | PCC, podatki lokalne, akcyza, transport, rolnictwo | 01 |
| 15 | PROMPT_15_RODO_AML_BDO.txt | RODO, AML/CBDD, BDO/środowisko, budownictwo, security | 01 |
| 16 | PROMPT_16_HYPER_PLAN45_KONTEKSTY.txt | Hyper Plan45 (14 pakietów) + kalendarz/esig/rodzina… | 01–15 |
| 17 | PROMPT_17_ENTERPRISE_AI_SYSTEM_OPA.txt | Enterprise AI (S1–S24, R16/R17), narzędzia, bundle, API, migracje | 01–16 |
| 18 | PROMPT_18_TESTY_CI_JAKOSC.txt | Testy (pytest+Rego+auto), bramki CI, golden, chaos | 17 |
| 19 | PROMPT_19_POLICIES_MIRROR.txt | `policies/` (mirror + overlays v2026/v2027) | 01–18 |

**Zasada wykonania:** Prompty wykonuj **po kolei, jeden na jedną sesję GLM**.
Każdy raport zapisz jako plik `.txt` (np. `RAPORT_GLM52_P04_KSEF_JPK_EDEKLARACJE.txt`),
wdroż jego rekomendacje do kodu JDG **przed** uruchomieniem następnego promptu
(regeneruj przy tym `MANIFEST.md`, bundle i testy — patrz §4).

## 3. Protokół sesji GLM (powtarzany w każdym Prompcie)

1. **Czytanie:** model czyta linki GitHub podane w Prompcie (święte dokumenty → pliki części →
   sąsiednie części tylko w zakresie kontraktów). Budżet: ≤ 50% okna.
2. **Myślenie:** głębokie myślenie + głęboka analiza (min. 25–40 stron raportu).
3. **Raport:** ogromny, rozbudowany raport `.txt` — analiza + **inteligentny kod gotowy do
   wdrożenia** (Rego / Python / YAML / JSON / SQL), zero-defect, rozwiązania klasy ENTERPRISE.
4. **Wdrożenie (poza GLM):** człowiek/agent stosuje kod z raportu do katalogu JDG, uruchamia
   walidacje (`validate_rules.py --strict`, `lint_rego_rules.py --check --strict`, `opa check`,
   pytest), regeneruje MANIFEST i bundle.
5. **Koniec sesji:** model wykonuje polecenie **„WYCZYŚĆ OKNO KONTEKSTOWE”** — podsumowuje
   najważniejsze ustalenia w 10 linijkach (do skopiowania do `NOTATKI_KAMPANII.txt`), po czym
   użytkownik wkleja następny Prompt.

## 4. Kontrakty spójności międzyczęściowej (identyczne we wszystkich Promptach)

Każda część musi być **spójnie połączona** z pozostałymi przez te niezmienne kontrakty:

1. **Werdykt 25-polowy** (ADR-004): `matched, rule_id, package, priority, vat_rate, rounding_level,
   gtu_code, procedure, vat_exemption, pit_form, pit_rate, pit_bracket, pit_annual_return_type,
   kus_qualification, kus_percent, zus_social_base_type, zus_health_rate, business_status,
   ceidg_registration_required, _routing, _routing_reason, _legal_basis, _warnings` + `_provenance_tree`.
2. **rule_id:** `jdg.<domena>.<kategoria>.<identyfikator>` — globalnie unikalne, zero duplikatów.
3. **`_legal_basis` kanoniczne:** „Art. X ust. Y pkt Z <ustawa> (Dz.U. <rok> poz. <nr> ze zm.)”
   — zgodne ze słownikiem `bundles/legal_reference_canon.json` (RV → 100%).
4. **Zero hardcode:** stawki/progi/limity wyłącznie przez `data.thresholds.jdg.*` (ADR-002).
5. **Orkiestrator:** nowa reguła = `import` w `rules/main_jdg.rego` + wpis w łańcuchu `safe_merge`
   (sharded sale/purchase/full/gated) + flaga aktywacji + `default decide no_match`.
6. **Temporalność:** `valid_from`/`valid_to` — werdykt wg prawa z dnia transakcji (ADR-003).
7. **LKG (V2 F1):** każda reguła dwukierunkowo powiązana z węzłem prawa (`legal_graph`,
   migracja 003); LCI ≥ 99%, TCL 100%, RV 100% (metryki z `PEWNOSC_DASHBOARD.md`).
8. **Runtime invariants (V2 F2):** katalog INV (np. „stawka ∈ {0,5,8,23}”, „suma odliczeń ≤
   dochód”) — sprawdzany na każdym werdykcie; naruszenie = BLOCK + auto-revert.
9. **Klasy pewności (V2 F4):** `CERTAIN` / `CONDITIONAL` / `NEEDS_ADVICE` + Decision Certificate.
10. **Golden Oracle (V2 F3):** zmiana reguły nie może zmienić historycznych werdyktów bez
    uzasadnienia w diffie prawnym (`golden_verdicts.json`, `golden_replay.py`).
11. **OPA jako SYSTEM (V1):** zmiana parametru < 1 min (Data API hot-reload), zmiana reguły
    przez cykl SHADOW→CANDIDATE→ACTIVE→ROLLED_BACK, canary 5%→100%, auto-rollback ≤ 5 min,
    podpis HSM bundle, Law Radar (projekty ustaw), Declarative Change (F6).
12. **Regeneracja po wdrożeniu:** `python JDG/tools/generate_manifest.py` oraz
    `python JDG/tools/generate_coverage_report.py` — liczby muszą być spójne we wszystkich
    dokumentach (blokada CI przy rozbieżności).

## 5. Źródła prawne (są spisane w każdym Prompcie jako linki)

- **Bbb (akty prawne):** https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/docs/Bbb
- **LEGAL_REFERENCE_ACTS.md:** https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/docs/LEGAL_REFERENCE_ACTS.md
- **LEGAL_COVERAGE.md:** https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/docs/LEGAL_COVERAGE.md

## 6. Dokumenty święte (w każdym Prompcie jako linki)

- **V1 (docelowa architektura):** https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/docs/ARCHITEKTURA_OPA_ENTERPRISE_TARGET.md
- **V2 (wizja — kontynuacja V1):** https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/docs/WIZJA_OPA_ENTERPRISE_V2.md
- **Stan obecny:** https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/docs/ARCHITEKTURA.md
- **Powiązane:** ANALIZA_STANU_OPA_JAKO_SYSTEM.md · MANIFEST_2_0.md · RULE_LIFECYCLE.md

## 7. Wymagane zwroty (każdy Prompt zawiera każdy z nich ≥ 4 razy)

`Przeprowadź głębokie myślenie` · `przeprowadź głęboką analizę` ·
`zaawansowany poziom Enterprise` · `poziom ENTERPRISE` ·
`innowacyjne ulepszenia wyprzedzające profesjonalistów`

## 8. Pliki NOTATKI (twórz w miarę kampanii)

- `JDG/prompty_glm52_enterprise/NOTATKI_KAMPANII.txt` — 10-linijkowe podsumowania z końca
  każdej sesji GLM (co wdrożono, co dalej, ostrzeżenia).
- `JDG/prompty_glm52_enterprise/STATUS_KAMPANII.md` — checkbox: który Prompt wykonany,
  który raport wdrożony, które metryki (LCI/RV/TCL) po wdrożeniu.

## 9. Kryterium sukcesu kampanii

Po wdrożeniu wszystkich 19 raportów silnik musi osiągnąć: **LCI ≥ 99%, RV = 100%, TCL = 100%,
UVR = 0, zero duplikatów i stubów, zero hardcode, 100% pakietów krytycznych z testami natywnymi
+ mutation ≥ 75%, golden replay bez nieuzasadnionych zmian, podpisane bundle, wdrożenie
nowelizacji ≤ 24 h (P0 ≤ 4 h), zmiana parametru < 1 min, auto-rollback ≤ 5 min** — czyli
**ufortyfikowana forteca niechybnej Śmierci dla wszystkich braków, błędów i niedopatrzeń**.

---
*Kampania: GLM 5.2 · moduł JDG · silnik reguł podatkowych OPA · klasy ENTERPRISE · 2026*
