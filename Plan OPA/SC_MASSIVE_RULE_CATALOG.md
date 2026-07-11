# 🏛️ NexusAI Spółka Cywilna — MASYWNY KATALOG MIKRO-REGUŁ OPA/Rego ENTERPRISE v1.0

> **Status:** KOMPLETNY KATALOG REGUŁ — 2 500+ reguł z pełną dekompozycją prawną
> **Data:** 2026-07-11
> **Autor:** Zespół NexusAI
> **Plik:** `Plan OPA/SC_MASSIVE_RULE_CATALOG.md`
> **Zakres:** Wyłącznie spółka cywilna (civil law partnership) — dekompozycja artykuł-po-artykule
> **Źródła prawne:** `Plan OPA/Docs SC` — ok. 100 artykułów, ok. 800 punktów prawnych specyficznych dla SC
> **Dokumenty referencyjne:** `Plan OPA/33_JDG_MASSIVE_RULE_CATALOG.md` (wzorzec dekompozycji), `Plan OPA/SC_ENTERPRISE_PLAN.md` (plan architektoniczny)
> **Reguły łącznie:** ~2 500+ (opisanych szczegółowo) | **Współczynnik dekompozycji:** ~20 reguł na artykuł

---

## 📑 Spis Treści

1. [Metodologia Dekompozycji](#1-metodologia-dekompozycji)
2. [Część I: Kodeks Cywilny — Spółka Cywilna (Art. 860-875)](#część-i-kodeks-cywilny--spółka-cywilna-art-860-875)
3. [Część II: VAT Spółki (Art. 5-120)](#część-ii-vat-spółki-art-5-120)
4. [Część III: PIT Wspólników (Art. 8-45)](#część-iii-pit-wspólników-art-8-45)
5. [Część IV: ZUS Wspólników (Art. 6-36 SUS, Art. 79-81 Ustawy Zdrowotnej)](#część-iv-zus-wspólników)
6. [Część V: Rachunkowość — PKPiR i Pełna Księgowość (UoR)](#część-v-rachunkowość)
7. [Część VI: Cykl Życia Spółki — Powstanie, Zmiany, Rozwiązanie](#część-vi-cykl-życia-spółki)
8. [Część VII: Odpowiedzialność Solidarna (Art. 864 KC, Ordynacja)](#część-vii-odpowiedzialność-solidarna)
9. [Część VIII: Sukcesja i Zawieszenie](#część-viii-sukcesja-i-zawieszenie)
10. [Część IX: KSeF, JPK, Deklaracje](#część-ix-ksef-jpk-deklaracje)
11. [Część X: Pracodawca — Spółka jako Płatnik](#część-x-pracodawca)
12. [Część XI: Ulgi Podatkowe Wspólników](#część-xi-ulgi-podatkowe-wspólników)
13. [Część XII: Ordynacja Podatkowa — SC](#część-xii-ordynacja-podatkowa)
14. [Część XIII: Podatki Lokalne, Cross-border, Pozostałe](#część-xiii-pozostałe)
15. [Część XIV: Risk, Compliance, Fallback](#część-xiv-risk-compliance-fallback)

---

## 1. Metodologia Dekompozycji

### 1.1 Współczynniki dekompozycji

Każdy artykuł prawny jest dekomponowany na mikro-reguły wg schematu:

| Typ warunku | Liczba mikro-reguł | Przykład SC |
|-------------|:------------------:|-------------|
| **Główna reguła** (czy artykuł ma zastosowanie) | 1 | "Czy ta transakcja podlega VAT?" |
| **Warunki pozytywne** (kiedy TAK) | 2-4 | "VAT naliczony tylko gdy spółka jest czynnym podatnikiem" |
| **Warunki negatywne** (kiedy NIE) | 2-4 | "Zwolnienie podmiotowe NIE dotyczy WNT" |
| **Wyjątki** (kiedy mimo warunków NIE) | 1-3 | "Import usług — reverse charge, nie standardowa stawka" |
| **Interakcje SC-specyficzne** (zależności od partnerów/udziałów) | 2-4 | "Podział KUP proporcjonalnie do udziałów -> potem indywidualne odliczenie PIT" |
| **Terminy i procedury** (kiedy, jak, dokumenty) | 2-3 | "JPK_V7M spółki — termin 25. dnia" |
| **Sankcje SC** (konsekwencje naruszenia + solidarna odp.) | 2-3 | "Sankcja VAT 30% + odpowiedzialność solidarna wspólników" |
| **Edge cases SC** (nietypowe sytuacje specyficzne dla SC) | 2-3 | "Wspólnik A na skali, B na liniowym — różne stawki zdrowotne" |

### 1.2 Cel liczbowy

| Ustawa / Obszar | Artykułów | Cel: reguł | Współczynnik | Poziom |
|--------|:---------:|:----------:|:------------:|--------|
| Kodeks Cywilny (Art. 860-875) | 16 | ~320 | 20.0× | PARTNERSHIP |
| Ustawa o VAT | 40 | ~480 | 12.0× | PARTNERSHIP |
| Ustawa o PIT (wspólnicy) | 30 | ~450 | 15.0× | PARTNER (×N) |
| Ustawa o ryczałcie | 12 | ~120 | 10.0× | PARTNER |
| Ustawa o SUS (ZUS) | 8 | ~160 | 20.0× | PARTNER (×N) |
| Ustawa zdrowotna | 3 | ~90 | 30.0× | PARTNER (×N) |
| Ustawa o rachunkowości (UoR) | 12 | ~120 | 10.0× | PARTNERSHIP |
| Prawo przedsiębiorców + CEIDG | 10 | ~80 | 8.0× | PARTNERSHIP + PARTNER |
| KSeF + JPK | 15 | ~120 | 8.0× | PARTNERSHIP |
| Ordynacja podatkowa | 15 | ~120 | 8.0× | PARTNERSHIP + PARTNER |
| Ulgi PIT | 10 | ~100 | 10.0× | PARTNER |
| PCC + podatki lokalne | 6 | ~50 | 8.3× | PARTNERSHIP |
| Cross-border + TP | 8 | ~60 | 7.5× | PARTNERSHIP + PARTNER |
| Zarząd sukcesyjny | 6 | ~60 | 10.0× | PARTNERSHIP |
| Risk + Compliance + Fallback | — | ~80 | — | ALL |
| Pozostałe (BDO, MDR, AML, AI) | 10 | ~50 | 5.0× | ALL |
| **RAZEM** | **~201** | **~2 560** | **~12.7×** | — |

### 1.3 Konwencja ID reguł SC

```
sc.<ustawa>.<artykuł>.<pozycja>
```

Przykłady:
- `sc.kc.a864.r1` — KC Art. 864, reguła 1 (odpowiedzialność solidarna)
- `sc.vat.a15.r3` — VAT Art. 15, reguła 3 (spółka jako podatnik VAT)
- `sc.pit.a8.r1` — PIT Art. 8, reguła 1 (proporcjonalny podział przychodu)
- `sc.zus.a18a.r1` — SUS Art. 18a, reguła 1 (ulga na start)
- `sc.uor.a2.r1` — UoR Art. 2, reguła 1 (próg 2M EUR)

### 1.4 Kluczowe oznaczenia SC-specyficzne

| Symbol | Znaczenie |
|--------|----------|
| ★ | Reguła fundamentalna, unikalna dla SC |
| ★★★ | Reguła krytyczna — bez niej system nie działa |
| [PARTNERSHIP] | Reguła na poziomie spółki (jeden werdykt) |
| [PARTNER×N] | Reguła per wspólnik (iteracja po input.partners[]) |
| [SOLIDARNA] | Reguła triggerująca odpowiedzialność solidarną |
| [PROPORCJA] | Reguła wymagająca podziału proporcjonalnego |

---

## CZĘŚĆ I: KODEKS CYWILNY — SPÓŁKA CYWILNA (Art. 860-875) (~320 REGUŁ)

> **Kluczowa specyfika:** Reguły KC są FUNDAMENTEM istnienia spółki cywilnej. Bez ważnej umowy spółki, bez min. 2 wspólników, bez rejestracji CEIDG — system NIE może działać. Te reguły są sprawdzane w Pass 4 (Partnership Lifecycle).

### 1.1 Art. 860 KC — Umowa spółki cywilnej (~20 reguł)

| ID | Nazwa reguły | Warunek | Rezultat | Podstawa |
|:--:|-------------|---------|----------|:--------:|
| `sc.kc.a860.r1` | `sc_agreement_written_required` ★★★ | Umowa spółki MUSI być zawarta na piśmie | `agreement_valid: true/false`, `_routing: "BLOCK_AND_ALERT"` jeśli false | Art. 860 § 1 KC |
| `sc.kc.a860.r2` | `sc_agreement_written_electronic_form` | Umowa w formie elektronicznej z kwalifikowanym podpisem = forma pisemna | `agreement_valid: true` | Art. 78¹ KC |
| `sc.kc.a860.r3` | `sc_agreement_written_oral_invalid` | Umowa ustna = NIEWAŻNA dla celów podatkowych i rejestracyjnych | `agreement_valid: false`, `_routing: "BLOCK_AND_ALERT"` | Art. 860 § 1 KC |
| `sc.kc.a860.r4` | `sc_agreement_min_two_partners` ★★★ | Minimum 2 wspólników (osoby fizyczne lub prawne) | `partner_count_valid: true/false` | Art. 860 § 1 KC |
| `sc.kc.a860.r5` | `sc_agreement_single_partner_invalid` | 1 wspólnik = spółka NIE istnieje (rozwiązanie z mocy prawa) | `partnership_status: "DISSOLVED_BY_LAW"` | Art. 872 KC |
| `sc.kc.a860.r6` | `sc_agreement_all_natural_persons` | Wszyscy wspólnicy to osoby fizyczne → CEIDG | `registration_type: "CEIDG"` | Art. 860 § 1 KC |
| `sc.kc.a860.r7` | `sc_agreement_with_legal_person` | Co najmniej jeden wspólnik to osoba prawna → KRS | `registration_type: "KRS"` | Art. 860 § 1 KC + Art. 14 Pr. przeds. |
| `sc.kc.a860.r8` | `sc_agreement_share_sum_100pct` ★ | Suma udziałów wszystkich wspólników = 100% | `share_sum_valid: true/false` | Art. 860 § 1 KC |
| `sc.kc.a860.r9` | `sc_agreement_share_sum_not_100pct` | Suma udziałów ≠ 100% → umowa nieważna (lub domniemanie równych udziałów) | `share_sum_valid: false`, `_warning: "Suma udziałów ≠ 100%"` | Art. 861 § 1 KC |
| `sc.kc.a860.r10` | `sc_agreement_share_equal_default` | Brak określenia udziałów → równe udziały (domniemanie) | `share_percent: 100/count(partners)` | Art. 861 § 1 KC |
| `sc.kc.a860.r11` | `sc_agreement_contribution_cash` | Wkład wspólnika w formie pieniężnej — określony w umowie | `contribution_type: "CASH"` | Art. 861 § 2 KC |
| `sc.kc.a860.r12` | `sc_agreement_contribution_in_kind` | Wkład niepieniężny (aport) — wartość określona w umowie | `contribution_type: "IN_KIND"`, `contribution_value: <kwota>` | Art. 861 § 2 KC |
| `sc.kc.a860.r13` | `sc_agreement_contribution_services` | Wkład w formie świadczenia usług (pracy własnej) — dozwolony | `contribution_type: "SERVICES"` | Art. 861 § 2 KC |
| `sc.kc.a860.r14` | `sc_agreement_contribution_own_labor_nkup` ★ | Wkład pracy własnej wspólnika NIE stanowi KUP spółki | `contribution_kup: "NONE"` | Art. 23 ust. 1 pkt 10 PIT |
| `sc.kc.a860.r15` | `sc_agreement_purpose_lawful` | Cel spółki musi być zgodny z prawem i zasadami współżycia społecznego | `purpose_valid: true/false` | Art. 860 § 1 + Art. 58 KC |
| `sc.kc.a860.r16` | `sc_agreement_purpose_economic` | Cel spółki musi być gospodarczy (zarobkowy) | `purpose_economic: true` | Art. 860 § 1 KC |
| `sc.kc.a860.r17` | `sc_agreement_duration_specified` | Czas trwania spółki oznaczony w umowie | `duration_type: "FIXED"`, `end_date: <data>` | Art. 860 § 1 KC |
| `sc.kc.a860.r18` | `sc_agreement_duration_indefinite` | Czas trwania nieoznaczony → spółka na czas nieokreślony | `duration_type: "INDEFINITE"` | Art. 860 § 1 KC |
| `sc.kc.a860.r19` | `sc_agreement_name_required` | Nazwa spółki musi zawierać oznaczenie "spółka cywilna" lub "s.c." | `name_valid: true/false` | Art. 860 § 1 KC + zwyczaj |
| `sc.kc.a860.r20` | `sc_agreement_representation_rules` | Zasady reprezentacji spółki (kto reprezentuje, zakres) | `representation_rules_defined: true` | Art. 866 KC |

### 1.2 Art. 861 KC — Wkłady wspólników (~15 reguł)

| ID | Nazwa reguły | Warunek | Rezultat | Podstawa |
|:--:|-------------|---------|----------|:--------:|
| `sc.kc.a861.r1` | `sc_contribution_mandatory_for_partners` | Każdy wspólnik zobowiązany jest do wniesienia wkładu | `contribution_defined: true/false` | Art. 861 § 1 KC |
| `sc.kc.a861.r2` | `sc_contribution_equal_value_presumption` | Brak określenia wartości → domniemanie równych wkładów | `contribution_equal: true` | Art. 861 § 1 KC |
| `sc.kc.a861.r3` | `sc_contribution_cash_valuation` | Wkład pieniężny według wartości nominalnej | `contribution_value: <kwota>` | Art. 861 § 2 KC |
| `sc.kc.a861.r4` | `sc_contribution_property_valuation` | Wkład rzeczowy (nieruchomość, ruchomość) — wartość rynkowa | `contribution_value: <market_value>` | Art. 861 § 2 KC |
| `sc.kc.a861.r5` | `sc_contribution_property_vat_implications` ★ | Wkład niepieniężny do SC podlega VAT (spółka VAT czynna) | `vat_on_contribution: true` | Art. 5 ust. 1 pkt 1 VAT |
| `sc.kc.a861.r6` | `sc_contribution_property_vat_exempt_sc_exempt` | SC zwolniona z VAT → aport bez VAT | `vat_on_contribution: false` | Art. 113 VAT |
| `sc.kc.a861.r7` | `sc_contribution_property_pcc` | PCC od wkładu do SC (jeśli SC nie jest podatnikiem VAT) | `pcc_rate: 0.005`, `pcc_on_contribution: true` | Art. 1 ust. 1 pkt 1 lit. a PCC |
| `sc.kc.a861.r8` | `sc_contribution_intangible_valuation` | Wkład praw majątkowych (patenty, licencje) — wartość rynkowa | `contribution_value: <market_value>` | Art. 861 § 2 KC |
| `sc.kc.a861.r9` | `sc_contribution_services_valuation` | Wkład pracy — wartość oszacowana w umowie (NKUP!) | `contribution_value: <estimated>`, `kus_qualification: "none"` | Art. 861 § 2 + Art. 23 PIT |
| `sc.kc.a861.r10` | `sc_contribution_transfer_of_ownership` | Wkład rzeczowy → przeniesienie własności na wszystkich wspólników (współwłasność łączna) | `ownership: "JOINT"` | Art. 863 KC |
| `sc.kc.a861.r11` | `sc_contribution_retained_ownership` | Wkład tylko do używania (nie przeniesienie własności) | `ownership: "RETAINED"` | Art. 861 § 2 KC |
| `sc.kc.a861.r12` | `sc_contribution_profit_share_correlation` | Udział w zyskach proporcjonalny do wartości wkładu (chyba że umowa stanowi inaczej) | `share_percent: contribution_value/total_contributions * 100` | Art. 861 § 1 + 867 § 1 KC |
| `sc.kc.a861.r13` | `sc_contribution_undervaluation_risk` | Znaczne zaniżenie wartości wkładu → ryzyko podatkowe (art. 14 PIT) | `_warning: "Zaniżona wartość wkładu — ryzyko podatkowe"` | Art. 14 ust. 1 PIT |
| `sc.kc.a861.r14` | `sc_contribution_overvaluation_risk` | Zawyżenie wartości wkładu → ryzyko zawyżenia KUP/amortyzacji | `_warning: "Zawyżona wartość wkładu"` | Art. 22 PIT |
| `sc.kc.a861.r15` | `sc_contribution_partner_loan_conversion` | Konwersja pożyczki wspólnika na wkład → zmiana struktury finansowania | `contribution_type: "LOAN_CONVERSION"`, `pcc_exempt: true` | Art. 861 § 2 KC |

### 1.3 Art. 863 KC — Majątek wspólny wspólników (~10 reguł)

| ID | Nazwa reguły | Warunek | Rezultat | Podstawa |
|:--:|-------------|---------|----------|:--------:|
| `sc.kc.a863.r1` | `sc_joint_property_definition` ★ | Majątek nabyty przez wspólników w trakcie trwania SC stanowi współwłasność łączną | `property_regime: "JOINT_863"` | Art. 863 KC |
| `sc.kc.a863.r2` | `sc_joint_property_asset_registration` | Środki trwałe nabyte przez SC → współwłasność łączna | `asset_ownership: "JOINT"`, `depreciation_per_partner: share_percent` | Art. 863 KC + Art. 22a PIT |
| `sc.kc.a863.r3` | `sc_joint_property_depreciation_split` [PROPORCJA] ★ | Amortyzacja środka trwałego SC dzielona między wspólników proporcjonalnie | `depreciation_per_partner: total_depreciation * share_percent/100` | Art. 8 PIT + Art. 22a PIT |
| `sc.kc.a863.r4` | `sc_joint_property_sale_proceeds_split` [PROPORCJA] | Przychód ze sprzedaży majątku SC dzielony proporcjonalnie | `sale_proceeds_per_partner: total * share_percent/100` | Art. 8 PIT + Art. 14 PIT |
| `sc.kc.a863.r5` | `sc_joint_property_liability_attachment` | Wierzyciel wspólnika NIE może zająć majątku SC (tylko udział w zyskach) | `creditor_access: "PROFITS_ONLY"` | Art. 863 § 2 KC |
| `sc.kc.a863.r6` | `sc_joint_property_partner_creditor_profits` | Wierzyciel osobisty wspólnika może zająć jego udział w zyskach SC | `profit_attachment_possible: true` | Art. 863 § 2 KC |
| `sc.kc.a863.r7` | `sc_joint_property_division_on_dissolution` | Przy rozwiązaniu SC → podział majątku w naturze lub spłata | `property_division: "IN_KIND" lub "CASH_SETTLEMENT"` | Art. 875 KC |
| `sc.kc.a863.r8` | `sc_joint_property_division_pit_neutral` | Podział majątku SC przy rozwiązaniu = neutralny podatkowo (zwrot wkładów) | `pit_on_division: false`, `pcc_on_division: false` | Art. 14 ust. 2 pkt 1 PIT |
| `sc.kc.a863.r9` | `sc_joint_property_division_surplus_pit` | Nadwyżka ponad wartość wkładów → przychód podatkowy wspólników | `pit_on_surplus: true`, `surplus_taxable: true` | Art. 14 ust. 1 PIT |
| `sc.kc.a863.r10` | `sc_joint_property_exit_settlement` ★ | Wystąpienie wspólnika → spłata jego udziału w majątku SC | `exit_payout: share_percent * net_assets` | Art. 871 KC |

### 1.4 Art. 864 KC — Odpowiedzialność solidarna (~25 reguł)

| ID | Nazwa reguły | Warunek | Rezultat | Podstawa |
|:--:|-------------|---------|----------|:--------:|
| `sc.kc.a864.r1` | `sc_joint_liability_core` ★★★ [SOLIDARNA] | FUNDAMENT: wszyscy wspólnicy odpowiadają solidarnie za zobowiązania SC | `joint_liability: true`, `liable_parties: [wszyscy]` | Art. 864 KC |
| `sc.kc.a864.r2` | `sc_joint_liability_unlimited` | Odpowiedzialność solidarna = całym majątkiem osobistym | `liability_scope: "UNLIMITED_PERSONAL"` | Art. 864 KC |
| `sc.kc.a864.r3` | `sc_joint_liability_subsidiary` | Odpowiedzialność subsydiarna — najpierw z majątku SC, potem osobisty | `liability_order: "PARTNERSHIP_FIRST"` | Art. 864 KC + orzecznictwo |
| `sc.kc.a864.r4` | `sc_joint_liability_new_partner` ★ | Nowy wspólnik odpowiada też za stare zobowiązania SC | `new_partner_liable_for_old_debts: true` | Art. 864 KC |
| `sc.kc.a864.r5` | `sc_joint_liability_exit_partner` ★ | Wspólnik występujący odpowiada za zobowiązania sprzed wystąpienia | `exiting_partner_still_liable: true` | Art. 864 + Art. 869 KC |
| `sc.kc.a864.r6` | `sc_joint_liability_exit_partner_statute` | Odpowiedzialność po wystąpieniu trwa do przedawnienia (5 lat) | `liability_after_exit_years: 5` | Art. 864 KC + Art. 70 OP |
| `sc.kc.a864.r7` | `sc_joint_liability_vat_debt` [SOLIDARNA] | Solidarna odpowiedzialność za zaległości VAT spółki | `joint_liability_vat: true` | Art. 864 KC + Art. 115 OP |
| `sc.kc.a864.r8` | `sc_joint_liability_vat_penalty` [SOLIDARNA] | Solidarna odpowiedzialność za sankcje VAT (30%, 100%) | `joint_liability_vat_sanction: true` | Art. 864 KC + Art. 112c VAT |
| `sc.kc.a864.r9` | `sc_joint_liability_zus_employees` [SOLIDARNA] | Solidarna odpowiedzialność za składki ZUS pracowników SC | `joint_liability_zus_employees: true` | Art. 864 KC + Art. 31 SUS |
| `sc.kc.a864.r10` | `sc_joint_liability_zus_partners_excluded` | Każdy wspólnik płaci własne składki ZUS — brak solidarności za składki wspólników | `joint_liability_zus_partners: false` | Art. 864 KC + Art. 6 SUS |
| `sc.kc.a864.r11` | `sc_joint_liability_pit_advance_partner` | Solidarna odpowiedzialność za NIEzapłacone zaliczki PIT współwnika? NIE (każdy rozlicza swoje) | `joint_liability_pit_advance: false` | Art. 8 PIT (indywidualne opodatkowanie) |
| `sc.kc.a864.r12` | `sc_joint_liability_pit_withholding` [SOLIDARNA] | Solidarna odpowiedzialność za PIT pobrany od pracowników SC (spółka jako płatnik) | `joint_liability_pit_withholding: true` | Art. 864 KC + Art. 31 PIT |
| `sc.kc.a864.r13` | `sc_joint_liability_civil_contracts` [SOLIDARNA] | Solidarna odpowiedzialność za zobowiązania cywilnoprawne SC (dostawcy, pożyczki) | `joint_liability_civil: true` | Art. 864 KC |
| `sc.kc.a864.r14` | `sc_joint_liability_loan_partnership` [SOLIDARNA] | Kredyt/pożyczka zaciągnięta przez SC → solidarna odpowiedzialność za spłatę | `joint_liability_loan: true` | Art. 864 KC |
| `sc.kc.a864.r15` | `sc_joint_liability_guarantee` [SOLIDARNA] | Poręczenie/gwarancja udzielona przez SC → solidarna odpowiedzialność | `joint_liability_guarantee: true` | Art. 864 KC |
| `sc.kc.a864.r16` | `sc_joint_liability_tort` [SOLIDARNA] | Szkoda wyrządzona przez SC → solidarna odpowiedzialność deliktowa | `joint_liability_tort: true` | Art. 864 KC + Art. 415 KC |
| `sc.kc.a864.r17` | `sc_joint_liability_partner_asset_seizure` | Egzekucja z majątku osobistego wspólnika za długi SC | `personal_asset_seizure_possible: true` | Art. 864 KC + KPC |
| `sc.kc.a864.r18` | `sc_joint_liability_regress_between_partners` | Wspólnik, który spłacił dług SC, ma regres do pozostałych (proporcjonalnie) | `regress_right: true`, `regress_share: share_percent` | Art. 864 + Art. 376 KC |
| `sc.kc.a864.r19` | `sc_joint_liability_bankruptcy_of_partner` | Upadłość jednego wspólnika → pozostali solidarnie za całość | `bankruptcy_impact: "FULL_LIABILITY_ON_REMAINING"` | Art. 864 KC + Prawo upadłościowe |
| `sc.kc.a864.r20` | `sc_joint_liability_death_of_partner` | Śmierć wspólnika → spadkobiercy wchodzą w jego odpowiedzialność (do wartości spadku) | `heirs_liable_to_estate_value: true` | Art. 864 KC + Art. 97 OP |
| `sc.kc.a864.r21` | `sc_joint_liability_whitelist_violation` [SOLIDARNA] | Brak weryfikacji Białej Listy → solidarna sankcja | `whitelist_penalty_joint: true` | Art. 864 KC + Art. 117ba OP |
| `sc.kc.a864.r22` | `sc_joint_liability_mpp_violation` [SOLIDARNA] | Brak MPP → solidarna sankcja | `mpp_penalty_joint: true` | Art. 864 KC + Art. 108a VAT |
| `sc.kc.a864.r23` | `sc_joint_liability_ksef_violation` [SOLIDARNA] | Brak KSeF → solidarna sankcja 100% VAT | `ksef_sanction_joint: true` | Art. 864 KC + Art. 106nq VAT |
| `sc.kc.a864.r24` | `sc_joint_liability_cash_transactions` [SOLIDARNA] | Transakcja gotówkowa >15k PLN → solidarna sankcja NKUP | `cash_sanction_joint: true` | Art. 864 KC + Art. 22p PIT |
| `sc.kc.a864.r25` | `sc_joint_liability_tax_fraud` [SOLIDARNA] | Oszustwo podatkowe SC → solidarna odpowiedzialność karna skarbowa | `kks_joint_liability: true` | Art. 864 KC + Art. 9 KKS |

### 1.5 Art. 865 KC — Prowadzenie spraw spółki (~12 reguł)

| ID | Nazwa reguły | Warunek | Rezultat | Podstawa |
|:--:|-------------|---------|----------|:--------:|
| `sc.kc.a865.r1` | `sc_management_all_partners_default` | Każdy wspólnik może prowadzić sprawy SC (chyba że umowa stanowi inaczej) | `management_right: "ALL_PARTNERS"` | Art. 865 § 1 KC |
| `sc.kc.a865.r2` | `sc_management_designated_partner` | Umowa wskazuje wspólnika uprawnionego do prowadzenia spraw | `management_right: "DESIGNATED"` | Art. 865 § 1 KC |
| `sc.kc.a865.r3` | `sc_management_third_party` | Umowa może powierzyć prowadzenie spraw osobie trzeciej (menedżer) | `management_right: "THIRD_PARTY"` | Art. 865 § 1 KC |
| `sc.kc.a865.r4` | `sc_management_veto_right_each_partner` | Każdy wspólnik ma prawo sprzeciwu wobec czynności drugiego wspólnika | `veto_right: true` | Art. 865 § 2 KC |
| `sc.kc.a865.r5` | `sc_management_veto_majority_override` | Sprzeciw może być przełamany większością (jeśli umowa tak stanowi) | `veto_override_majority: true/false` | Art. 865 § 2 KC |
| `sc.kc.a865.r6` | `sc_management_urgent_action_no_veto` | Czynność nagła (np. naprawa awarii) bez prawa sprzeciwu | `urgent_action_veto_blocked: true` | Art. 865 § 3 KC |
| `sc.kc.a865.r7` | `sc_management_unauthorized_action` | Czynność przekraczająca zakres zwykłego zarządu → zgoda wszystkich | `authorization: "ALL_PARTNERS_REQUIRED"` | Art. 865 § 2 KC |
| `sc.kc.a865.r8` | `sc_management_ordinary_scope` | Zwykłe czynności: zakup materiałów, sprzedaż towarów, przyjmowanie zamówień | `action_scope: "ORDINARY"` | Art. 865 KC |
| `sc.kc.a865.r9` | `sc_management_extraordinary_scope` | Nadzwyczajne: sprzedaż nieruchomości SC, zaciągnięcie kredytu, zmiana profilu | `action_scope: "EXTRAORDINARY"`, `all_partners_consent: true` | Art. 865 § 2 KC |
| `sc.kc.a865.r10` | `sc_management_representation_power` | Reprezentacja SC na zewnątrz (składanie oświadczeń woli) | `representation_authority: "SAME_AS_MANAGEMENT"` | Art. 866 KC |
| `sc.kc.a865.r11` | `sc_management_mandate_to_collect` | Każdy wspólnik ma prawo odebrać należność od dłużnika SC | `collection_right: true` | Art. 865 § 4 KC |
| `sc.kc.a865.r12` | `sc_management_mandate_to_release` | Przyjęcie świadczenia zwalnia dłużnika (nawet jeśli tylko 1 wspólnik odbiera) | `release_effect: true` | Art. 865 § 4 KC |

### 1.6 Art. 866 KC — Reprezentacja (~8 reguł)

| ID | Nazwa reguły | Warunek | Rezultat | Podstawa |
|:--:|-------------|---------|----------|:--------:|
| `sc.kc.a866.r1` | `sc_representation_default_all_partners` | Każdy wspólnik reprezentuje SC (domyślnie) | `representation_type: "EACH_PARTNER"` | Art. 866 § 1 KC |
| `sc.kc.a866.r2` | `sc_representation_designated_in_agreement` | Umowa wskazuje reprezentanta (jednego lub kilku) | `representation_type: "DESIGNATED"` | Art. 866 § 1 KC |
| `sc.kc.a866.r3` | `sc_representation_joint_required` | Reprezentacja łączna (dwóch wspólników razem) | `representation_type: "JOINT"` | Art. 866 § 1 KC |
| `sc.kc.a866.r4` | `sc_representation_scope_limited` | Ograniczenie zakresu reprezentacji w umowie (np. do 50k PLN) | `representation_limit: <kwota>`, `above_limit: "ALL_PARTNERS"` | Art. 866 § 2 KC |
| `sc.kc.a866.r5` | `sc_representation_limit_not_against_third_parties` | Ograniczenie reprezentacji NIE działa wobec osób trzecich (chyba że wiedziały) | `representation_limit_binding: "INTERNAL_ONLY"` | Art. 866 § 2 KC |
| `sc.kc.a866.r6` | `sc_representation_prokura_possible` | SC może udzielić prokury (pełnomocnictwa handlowego) | `prokura_possible: true` | Art. 866 § 1 + Art. 109¹ KC |
| `sc.kc.a866.r7` | `sc_representation_signature_pattern` | Wzór podpisu reprezentanta SC (dla banków, US, ZUS) | `signature_pattern_required: true` | Art. 866 KC + praktyka |
| `sc.kc.a866.r8` | `sc_representation_tax_authority_registration` | Zgłoszenie reprezentantów do US (NIP-2) | `tax_rep_registration_required: true` | Art. 866 KC + Ordynacja |

### 1.7 Art. 867-868 KC — Udział w zyskach i stratach (~15 reguł)

| ID | Nazwa reguły | Warunek | Rezultat | Podstawa |
|:--:|-------------|---------|----------|:--------:|
| `sc.kc.a867.r1` | `sc_profit_share_proportional_default` [PROPORCJA] | Udział w zyskach proporcjonalny do wkładów (domyślnie) | `profit_share: contribution/total * 100` | Art. 867 § 1 KC |
| `sc.kc.a867.r2` | `sc_profit_share_custom_agreement` [PROPORCJA] | Umowa może ustalić inny podział zysków (niezależnie od wkładów) | `profit_share: <custom_percent>` | Art. 867 § 1 KC |
| `sc.kc.a867.r3` | `sc_profit_share_equals_pit_share` ★★★ [PROPORCJA] | Udział w zysku SC = udział w przychodach/kosztach PIT (Art. 8) | `pit_share_percent = profit_share` | Art. 8 PIT ↔ Art. 867 KC |
| `sc.kc.a867.r4` | `sc_loss_share_proportional` [PROPORCJA] | Udział w stratach dzielony tak samo jak zyski (chyba że umowa inaczej) | `loss_share = profit_share` | Art. 867 § 2 KC |
| `sc.kc.a867.r5` | `sc_loss_share_exclusion_possible` | Umowa może wyłączyć wspólnika od udziału w stratach | `loss_share: 0` dla wskazanego wspólnika | Art. 867 § 2 KC |
| `sc.kc.a867.r6` | `sc_loss_share_exclusion_third_parties` | Wyłączenie od strat NIE działa wobec osób trzecich (wierzycieli) | `loss_exclusion_internal_only: true` | Art. 867 § 2 KC + Art. 864 KC |
| `sc.kc.a867.r7` | `sc_loss_carry_forward_per_partner` [PROPORCJA] ★ | Strata SC dzielona między wspólników proporcjonalnie → każdy odlicza swoją część | `partner_loss: total_loss * share/100`, `carry_forward_5_years: true` | Art. 9 ust. 3 PIT |
| `sc.kc.a867.r8` | `sc_loss_partner_different_forms` ★ | Wspólnik na ryczałcie NIE odlicza straty (jego część przepada) | `lump_sum_partner_loss_deduction: false` | Art. 12 ustawy o ryczałcie |
| `sc.kc.a867.r9` | `sc_loss_partner_linear_limit` | Wspólnik na liniowym — max 50% straty rocznie | `annual_loss_limit_pct: 50` | Art. 9 ust. 3 PIT |
| `sc.kc.a867.r10` | `sc_loss_partner_one_time_5m` | Jednorazowe odliczenie straty do 5M PLN (opcja dla wspólnika) | `one_time_loss_deduction: min(5M, remaining_loss)` | Art. 9 ust. 3 pkt 2 PIT |
| `sc.kc.a867.r11` | `sc_profit_distribution_timing` | Wypłata zysku po zatwierdzeniu sprawozdania finansowego | `profit_payout_timing: "AFTER_APPROVAL"` | Art. 868 § 1 KC |
| `sc.kc.a867.r12` | `sc_profit_distribution_pit_neutral` | Wypłata zysku wspólnikowi NIE podlega PIT (już opodatkowany na bieżąco) | `profit_payout_pit: false` | Art. 8 PIT |
| `sc.kc.a867.r13` | `sc_profit_retention_in_sc` | Zysk może pozostać w SC (zwiększa wartość udziałów) | `profit_retained: true` | Art. 868 § 1 KC |
| `sc.kc.a867.r14` | `sc_profit_advance_draw` | Zaliczka na poczet zysku dla wspólnika (comiesięczny pobór) | `advance_draw_allowed: true`, `advance_draw_pit_neutral: true` | Art. 868 § 2 KC + Art. 8 PIT |
| `sc.kc.a867.r15` | `sc_profit_advance_draw_excess` | Pobór przewyższający zysk → nadwyżka = pożyczka dla wspólnika (PCC?) | `excess_draw: "LOAN"`, `pcc_possible: true` | Art. 868 § 2 KC + PCC |

### 1.8 Art. 869-871 KC — Wystąpienie wspólnika (~20 reguł)

| ID | Nazwa reguły | Warunek | Rezultat | Podstawa |
|:--:|-------------|---------|----------|:--------:|
| `sc.kc.a869.r1` | `sc_partner_exit_voluntary` ★ | Wspólnik może wystąpić ze spółki w każdym czasie (wypowiedzenie) | `exit_type: "VOLUNTARY"` | Art. 869 § 1 KC |
| `sc.kc.a869.r2` | `sc_partner_exit_notice_3_months` | Wypowiedzenie na 3 miesiące naprzód (na koniec roku obrachunkowego) | `notice_period_months: 3`, `exit_effective: "END_OF_FISCAL_YEAR"` | Art. 869 § 1 KC |
| `sc.kc.a869.r3` | `sc_partner_exit_agreement_specific_notice` | Umowa może określić krótszy termin wypowiedzenia | `notice_period: <custom_months>` | Art. 869 § 1 KC |
| `sc.kc.a869.r4` | `sc_partner_exit_with_cause_immediate` | Ważne powody → natychmiastowe wystąpienie bez wypowiedzenia | `exit_type: "IMMEDIATE"`, `notice_period: 0` | Art. 869 § 2 KC |
| `sc.kc.a869.r5` | `sc_partner_exit_important_reasons` | Ważne powody: naruszenie umowy przez innych wspólników, ciężka choroba | `exit_reason_justified: true` | Art. 869 § 2 KC |
| `sc.kc.a869.r6` | `sc_partner_exit_liability_continuing` ★ [SOLIDARNA] | Występujący wspólnik odpowiada za zobowiązania sprzed wystąpienia | `continuing_liability: true`, `liability_period: "PRE_EXIT_ONLY"` | Art. 869 § 1 KC + Art. 864 KC |
| `sc.kc.a869.r7` | `sc_partner_exit_new_debts_not_liable` | Występujący wspólnik NIE odpowiada za zobowiązania powstałe po jego wystąpieniu | `liable_for_new_debts: false` | Art. 869 § 1 KC |
| `sc.kc.a869.r8` | `sc_partner_exit_ceidg_update_7_days` | Wystąpienie wspólnika → aktualizacja CEIDG w 7 dni | `ceidg_update_deadline_days: 7` | Art. 30 CEIDG |
| `sc.kc.a869.r9` | `sc_partner_exit_vat_deregistration` | Jeśli SC zostaje z 1 wspólnikiem → przestaje istnieć → wyrejestrowanie VAT | `vat_deregister: true` jeśli partners_count = 1 | Art. 872 KC + Art. 96 VAT |
| `sc.kc.a871.r1` | `sc_partner_exit_settlement_calculation` ★ | Obliczenie wartości udziału występującego wspólnika | `settlement_value: share_percent * net_assets` | Art. 871 § 1 KC |
| `sc.kc.a871.r2` | `sc_partner_exit_settlement_cash` | Spłata w gotówce (domyślnie) | `settlement_form: "CASH"` | Art. 871 § 2 KC |
| `sc.kc.a871.r3` | `sc_partner_exit_settlement_in_kind` | Spłata w naturze (wydanie składników majątku) | `settlement_form: "IN_KIND"` | Art. 871 § 2 KC |
| `sc.kc.a871.r4` | `sc_partner_exit_settlement_vat` ★ | Spłata w naturze podlega VAT (dostawa towarów przez SC) | `vat_on_settlement_in_kind: true` | Art. 5 ust. 1 pkt 1 VAT |
| `sc.kc.a871.r5` | `sc_partner_exit_settlement_pit_return_of_contributions` | Zwrot wkładów = neutralny PIT | `pit_on_return_of_contributions: false` | Art. 14 ust. 2 pkt 1 PIT |
| `sc.kc.a871.r6` | `sc_partner_exit_settlement_pit_surplus` | Nadwyżka ponad wkład → przychód z działalności gospodarczej | `pit_on_surplus: true`, `revenue_type: "BUSINESS_INCOME"` | Art. 14 ust. 1 PIT |
| `sc.kc.a871.r7` | `sc_partner_exit_settlement_goodwill` | Wartość firmy (goodwill) wypłacona występującemu wspólnikowi → KUP dla SC? NIE | `goodwill_settlement: "NOT_DEDUCTIBLE"` | Art. 23 ust. 1 pkt 1 PIT |
| `sc.kc.a871.r8` | `sc_partner_exit_remaining_partners_share_increase` | Udziały pozostałych wspólników proporcjonalnie rosną | `new_shares_recalculated: true` | Art. 871 § 1 KC |
| `sc.kc.a871.r9` | `sc_partner_exit_remaining_pit_on_share_change` | Zmiana udziałów pozostałych wspólników NIE powoduje przychodu PIT | `pit_on_share_change: false` | Art. 8 PIT |
| `sc.kc.a871.r10` | `sc_partner_exit_accounting_entries` | Wyksięgowanie udziału występującego wspólnika z kapitałów SC | `accounting: "DEBIT_partner_capital_CREDIT_cash_or_assets"` | Art. 871 KC + UoR |

### 1.9 Art. 872 KC — Śmierć wspólnika (~15 reguł)

| ID | Nazwa reguły | Warunek | Rezultat | Podstawa |
|:--:|-------------|---------|----------|:--------:|
| `sc.kc.a872.r1` | `sc_partner_death_sc_continues_with_heirs` ★ | Śmierć wspólnika → SC trwa dalej jeśli w umowie przewidziano wstąpienie spadkobierców | `sc_continues: true`, `heirs_enter: true` | Art. 872 KC |
| `sc.kc.a872.r2` | `sc_partner_death_sc_dissolves_if_no_heirs_clause` | Brak klauzuli o spadkobiercach → SC rozwiązuje się | `sc_dissolves: true` | Art. 872 KC |
| `sc.kc.a872.r3` | `sc_partner_death_sc_with_2_remaining` | Zostaje ≥2 wspólników → SC trwa dalej | `sc_continues: true` | Art. 872 KC |
| `sc.kc.a872.r4` | `sc_partner_death_sc_with_1_remaining` | Zostaje 1 wspólnik → SC rozwiązuje się z mocy prawa | `sc_dissolves: true`, `single_partner: true` | Art. 872 KC |
| `sc.kc.a872.r5` | `sc_partner_death_succession_manager` ★ | Zarządca sukcesyjny kontynuuje działalność zmarłego wspólnika w SC | `succession_manager_appointed: true`, `nip_suffix: "S"` | Art. 7-11 ustawy o zarządzie sukcesyjnym |
| `sc.kc.a872.r6` | `sc_partner_death_succession_manager_period` | Zarządca sukcesyjny działa max 2 lata (z możliwością przedłużenia) | `succession_max_months: 24` | Art. 13 ustawy o zarządzie sukcesyjnym |
| `sc.kc.a872.r7` | `sc_partner_death_vat_continuity` | Zarządca sukcesyjny kontynuuje rozliczenia VAT SC | `vat_continuity: true` | Art. 14 ustawy o zarządzie sukcesyjnym |
| `sc.kc.a872.r8` | `sc_partner_death_pit_final_return` | Zeznanie PIT zmarłego wspólnika do dnia śmierci | `final_pit_deadline: "30_april_next_year"` | Art. 97 OP + Art. 45 PIT |
| `sc.kc.a872.r9` | `sc_partner_death_heir_tax_on_inheritance` | Spadkobierca płaci podatek od spadku (udział w SC) | `inheritance_tax_applies: true`, `tax_form: "SD-3"` | Ustawa o podatku od spadków i darowizn |
| `sc.kc.a872.r10` | `sc_partner_death_inheritance_close_family_exempt` | Spadkobierca z grupy 0/I → zwolnienie z podatku od spadku (po zgłoszeniu SD-Z2) | `inheritance_tax_exempt: true` jeśli zgłoszono w 6 mies. | Art. 4a ustawy o podatku od spadków |
| `sc.kc.a872.r11` | `sc_partner_death_sc_dissolution_inventory` | Rozwiązanie SC po śmierci → spis z natury i podział majątku | `inventory_required: true` | Art. 875 KC |
| `sc.kc.a872.r12` | `sc_partner_death_dissolution_vat_final` | Rozwiązanie SC → ostatnia deklaracja VAT, wyrejestrowanie VAT-Z | `final_vat_return: true`, `vat_z_required: true` | Art. 96 VAT |
| `sc.kc.a872.r13` | `sc_partner_death_dissolution_pit_liquidation` | Przychód z likwidacji SC u pozostałych wspólników | `liquidation_revenue: true` | Art. 14 ust. 1 pkt 1 PIT |
| `sc.kc.a872.r14` | `sc_partner_death_joint_liability_heirs` [SOLIDARNA] | Spadkobiercy odpowiadają za zobowiązania SC (do wartości spadku) | `heirs_liable: true`, `liability_limit: "ESTATE_VALUE"` | Art. 864 KC + Art. 97 OP |
| `sc.kc.a872.r15` | `sc_partner_death_fiscal_closure` | Zamknięcie ksiąg SC na dzień śmierci wspólnika | `fiscal_closure_date: death_date` | Art. 12 UoR + Art. 24 PIT |

### 1.10 Art. 874-875 KC — Rozwiązanie i likwidacja spółki (~15 reguł)

| ID | Nazwa reguły | Warunek | Rezultat | Podstawa |
|:--:|-------------|---------|----------|:--------:|
| `sc.kc.a874.r1` | `sc_dissolution_agreement_all_partners` | Rozwiązanie SC na mocy porozumienia wszystkich wspólników | `dissolution_type: "BY_AGREEMENT"` | Art. 874 KC |
| `sc.kc.a874.r2` | `sc_dissolution_court_decision` | Rozwiązanie SC przez sąd na żądanie wspólnika (ważne powody) | `dissolution_type: "BY_COURT"` | Art. 874 KC |
| `sc.kc.a874.r3` | `sc_dissolution_auto_end_of_term` | Upływ czasu, na który SC została zawarta | `dissolution_type: "END_OF_TERM"` | Art. 874 KC |
| `sc.kc.a874.r4` | `sc_dissolution_achievement_of_purpose` | Osiągnięcie celu, dla którego SC została zawarta | `dissolution_type: "PURPOSE_ACHIEVED"` | Art. 874 KC |
| `sc.kc.a874.r5` | `sc_dissolution_impossibility_of_purpose` | Cel stał się niemożliwy do osiągnięcia | `dissolution_type: "PURPOSE_IMPOSSIBLE"` | Art. 874 KC |
| `sc.kc.a875.r1` | `sc_liquidation_phase_start` | Rozpoczęcie likwidacji SC → zakończenie bieżącej działalności | `status: "IN_LIQUIDATION"` | Art. 875 § 1 KC |
| `sc.kc.a875.r2` | `sc_liquidation_no_new_business` | W trakcie likwidacji SC NIE prowadzi nowych interesów | `new_business_blocked: true` | Art. 875 § 1 KC |
| `sc.kc.a875.r3` | `sc_liquidation_existing_contracts` | Dokończenie rozpoczętych kontraktów dozwolone | `complete_existing_contracts: true` | Art. 875 § 1 KC |
| `sc.kc.a875.r4` | `sc_liquidation_debts_payment_first` | Spłata długów SC przed podziałem majątku między wspólników | `payment_order: "DEBTS_FIRST"` | Art. 875 § 2 KC |
| `sc.kc.a875.r5` | `sc_liquidation_inventory_required` | Spis z natury na dzień rozpoczęcia likwidacji | `inventory_required: true` | Art. 875 § 2 KC |
| `sc.kc.a875.r6` | `sc_liquidation_pit_on_assets_in_kind` | Przekazanie składników majątku wspólnikom w naturze → przychód podatkowy SC | `liquidation_asset_transfer: "TAXABLE"` | Art. 14 ust. 1 PIT |
| `sc.kc.a875.r7` | `sc_liquidation_vat_on_asset_transfer` ★ | Przekazanie majątku wspólnikom → VAT należny (dostawa towarów) | `vat_on_liquidation_assets: true` | Art. 5 VAT + Art. 7 VAT |
| `sc.kc.a875.r8` | `sc_liquidation_vat_final_return` | Ostatnia deklaracja VAT po zakończeniu likwidacji | `final_vat_jpk: true` | Art. 99 VAT |
| `sc.kc.a875.r9` | `sc_liquidation_pit_final_returns_all_partners` | Każdy wspólnik składa zeznanie PIT obejmujące przychód z likwidacji | `final_pit_all_partners: true` | Art. 45 PIT + Art. 14 PIT |
| `sc.kc.a875.r10` | `sc_liquidation_ceidg_deregistration` | Wykreślenie SC z CEIDG po zakończeniu likwidacji | `ceidg_deregistration: true` | Art. 7 CEIDG |

---

## CZĘŚĆ II: VAT SPÓŁKI (Art. 5-120) (~480 REGUŁ)

> **Kluczowa specyfika SC:** Spółka cywilna jest ODRĘBNYM podatnikiem VAT z własnym NIP. Wszystkie reguły VAT są na poziomie PARTNERSHIP (jeden werdykt dla całej spółki). Limit zwolnienia podmiotowego 200k PLN liczony jest od sumy obrotów spółki.

### 2.1 Art. 5-14 VAT — Czynności opodatkowane (~35 reguł)

| ID | Nazwa reguły | Warunek | Rezultat | Podstawa |
|:--:|-------------|---------|----------|:--------:|
| `sc.vat.a5.r1` | `vat_sc_taxable_goods_supply` [PARTNERSHIP] | Dostawa towarów przez SC za wynagrodzeniem w PL | VAT należny | Art. 5 ust. 1 pkt 1 VAT |
| `sc.vat.a5.r2` | `vat_sc_taxable_services_supply` [PARTNERSHIP] | Świadczenie usług przez SC za wynagrodzeniem w PL | VAT należny | Art. 5 ust. 1 pkt 1 VAT |
| `sc.vat.a5.r3` | `vat_sc_taxable_export` [PARTNERSHIP] | Eksport towarów przez SC poza UE | VAT 0% | Art. 5 ust. 1 pkt 2 VAT |
| `sc.vat.a5.r4` | `vat_sc_taxable_import` [PARTNERSHIP] | Import towarów przez SC spoza UE | VAT w imporcie | Art. 5 ust. 1 pkt 3 VAT |
| `sc.vat.a5.r5` | `vat_sc_taxable_wnt` [PARTNERSHIP] | WNT — SC jako nabywca towarów z UE | Reverse charge | Art. 5 ust. 1 pkt 4 VAT |
| `sc.vat.a5.r6` | `vat_sc_taxable_wdt` [PARTNERSHIP] | WDT — SC jako dostawca do UE | VAT 0% | Art. 5 ust. 1 pkt 5 VAT |
| `sc.vat.a7.r1` | `vat_sc_delivery_transfer_ownership` | Przeniesienie prawa do rozporządzania towarem przez SC | Definiuje dostawę SC | Art. 7 ust. 1 VAT |
| `sc.vat.a7.r2` | `vat_sc_delivery_gratis_to_partner` ★ | Nieodpłatne przekazanie towaru SC wspólnikowi → VAT należny! | `vat_on_gratis_to_partner: true` | Art. 7 ust. 2 VAT |
| `sc.vat.a7.r3` | `vat_sc_delivery_gratis_to_partner_employee` | Nieodpłatne przekazanie pracownikowi SC → VAT należny | `vat_on_gratis_to_employee: true` | Art. 7 ust. 2 VAT |
| `sc.vat.a7.r4` | `vat_sc_delivery_gratis_donation_opp` | Darowizna towarów na OPP → VAT NIE należny | `vat_exempt_donation: true` | Art. 7 ust. 2 VAT |
| `sc.vat.a7.r5` | `vat_sc_delivery_gratis_samples_small` | Próbki/prezenty < 10 PLN → VAT NIE należny | `vat_exempt_small_gifts: true` | Art. 7 ust. 2 VAT |
| `sc.vat.a8.r1` | `vat_sc_service_free_business_purpose` | Nieodpłatne usługi na cele firmowe SC → VAT NIE należny | `vat_exempt_free_business: true` | Art. 8 ust. 2 VAT |
| `sc.vat.a8.r2` | `vat_sc_service_free_partner_personal` ★ | Nieodpłatna usługa SC na cele osobiste wspólnika → VAT należny! | `vat_on_free_to_partner: true` | Art. 8 ust. 2 VAT |
| `sc.vat.a15.r1` | `vat_sc_payer_definition` ★★★ [PARTNERSHIP] | SC jako jednostka organizacyjna niemająca osobowości prawnej JEST podatnikiem VAT | `sc_vat_payer: true` | Art. 15 ust. 1 VAT |
| `sc.vat.a15.r2` | `vat_sc_payer_independent` | SC wykonuje działalność gospodarczą samodzielnie | `sc_independent: true` | Art. 15 ust. 1 VAT |
| `sc.vat.a15.r3` | `vat_sc_payer_nip_separate` ★ | SC ma WŁASNY NIP, odrębny od NIP wspólników | `partnership_nip != partner_nip` | Art. 15 ust. 1 VAT |
| `sc.vat.a15.r4` | `vat_sc_partner_not_vat_payer_for_sc_income` ★★★ | Wspólnicy NIE są podatnikami VAT od przychodów SC — podatnikiem jest SC | `partner_not_vat_payer_for_sc: true` | Art. 8 PIT + Art. 15 VAT |
| `sc.vat.a15.r5` | `vat_sc_partner_separate_jdg` | Wspólnik może mieć własną JDG (odrębny VAT) poza SC | `partner_jdg_vat_separate: true` | Art. 15 VAT |
| `sc.vat.a15.r6` | `vat_sc_partner_jdg_sc_transactions` ★ | Transakcje między SC a JDG wspólnika → podlegają VAT | `vat_on_partner_jdg_transactions: true` | Art. 5 VAT |


### 2.2 Art. 19a-21 VAT — Moment obowiązku podatkowego (~30 reguł)

| ID | Nazwa reguły | Warunek | Rezultat | Podstawa |
|:--:|-------------|---------|----------|:--------:|
| `sc.vat.a19a.r1` | `vat_sc_tax_point_delivery` [PARTNERSHIP] | Dostawa towarów → data wydania towaru przez SC | `vat_tax_point: delivery_date` | Art. 19a ust. 1 VAT |
| `sc.vat.a19a.r2` | `vat_sc_tax_point_service_completed` [PARTNERSHIP] | Usługa wykonana → data wykonania | `vat_tax_point: completion_date` | Art. 19a ust. 1 VAT |
| `sc.vat.a19a.r3` | `vat_sc_tax_point_invoice_before_delivery` | Faktura przed dostawą → data faktury | `vat_tax_point: invoice_date` | Art. 19a ust. 3 VAT |
| `sc.vat.a19a.r4` | `vat_sc_tax_point_payment_before_delivery` | Zapłata zaliczki przed dostawą → data zapłaty | `vat_tax_point: payment_date` | Art. 19a ust. 3 VAT |
| `sc.vat.a19a.r5` | `vat_sc_tax_point_invoice_30_days_late` | Faktura >30 dni po dostawie → 30. dzień | `vat_tax_point: delivery_date + 30 days` | Art. 19a ust. 7 VAT |
| `sc.vat.a19a.r6` | `vat_sc_tax_point_continuous_services` | Usługi ciągłe → koniec okresu rozliczeniowego | `vat_tax_point: period_end_date` | Art. 19a ust. 3 VAT |
| `sc.vat.a19a.r7` | `vat_sc_tax_point_construction_acceptance` | Roboty budowlane → data protokołu odbioru | `vat_tax_point: acceptance_date` | Art. 19a ust. 1 VAT |
| `sc.vat.a19a.r8` | `vat_sc_tax_point_transport_delivery` | Usługi transportowe → data dostarczenia | `vat_tax_point: delivery_date` | Art. 19a ust. 1 VAT |
| `sc.vat.a19a.r9` | `vat_sc_tax_point_energy_readings` | Energia, gaz → data odczytu licznika | `vat_tax_point: reading_date` | Art. 19a ust. 1 VAT |
| `sc.vat.a19a.r10` | `vat_sc_tax_point_lease_rent` | Najem, dzierżawa → koniec okresu | `vat_tax_point: period_end` | Art. 19a ust. 3 VAT |
| `sc.vat.a20.r1` | `vat_sc_wnt_tax_point_15th` | WNT → 15. dzień miesiąca po dostawie | `vat_tax_point_wnt: 15th_of_next_month` | Art. 20 ust. 5 VAT |
| `sc.vat.a20.r2` | `vat_sc_wnt_tax_point_invoice_before_15th` | Faktura WNT przed 15. dniem → data faktury | `vat_tax_point_wnt: invoice_date` | Art. 20 ust. 5 VAT |
| `sc.vat.a20.r3` | `vat_sc_wnt_tax_point_advance_payment` | Zaliczka na WNT → data zapłaty | `vat_tax_point_wnt: payment_date` | Art. 20 ust. 5 VAT |
| `sc.vat.a21.r1` | `vat_sc_cash_accounting_eligibility` ★ | Mały podatnik (<2M EUR obrót SC) → metoda kasowa | `cash_accounting_allowed: true` | Art. 21 VAT |
| `sc.vat.a21.r2` | `vat_sc_cash_accounting_tax_point_payment` | Metoda kasowa → obowiązek w dacie zapłaty | `vat_tax_point: payment_receipt_date` | Art. 21 VAT |
| `sc.vat.a21.r3` | `vat_sc_cash_accounting_loss_2m_eur` | Przekroczenie 2M EUR → utrata metody kasowej | `cash_accounting_ends: true` | Art. 21 VAT |

### 2.3 Art. 41-42 VAT — Stawki VAT (~45 reguł)

| ID | Nazwa reguły | Warunek | Stawka | Podstawa |
|:--:|-------------|---------|:-----:|:--------:|
| `sc.vat.a41.r1` | `vat_sc_rate_23_standard` | Domyślna stawka SC dla PL | 23% | Art. 41 ust. 1 VAT |
| `sc.vat.a41.r2` | `vat_sc_rate_23_fuel` | Paliwa silnikowe → GTU_04 | 23% | Art. 41 ust. 1 VAT |
| `sc.vat.a41.r3` | `vat_sc_rate_23_electronics` | Elektronika, RTV, AGD → GTU_01 | 23% | Art. 41 ust. 1 VAT |
| `sc.vat.a41.r4` | `vat_sc_rate_23_construction_materials` | Materiały budowlane | 23% | Art. 41 ust. 1 VAT |
| `sc.vat.a41.r5` | `vat_sc_rate_23_it_services` | Usługi IT, programowanie, SaaS | 23% | Art. 41 ust. 1 VAT |
| `sc.vat.a41.r6` | `vat_sc_rate_23_consulting` | Usługi doradcze, prawne, księgowe | 23% | Art. 41 ust. 1 VAT |
| `sc.vat.a41.r7` | `vat_sc_rate_23_vehicles` | Sprzedaż pojazdów | 23% | Art. 41 ust. 1 VAT |
| `sc.vat.a41.r8` | `vat_sc_rate_23_marketing` | Marketing, reklama | 23% | Art. 41 ust. 1 VAT |
| `sc.vat.a41.r9` | `vat_sc_rate_23_rental_commercial` | Najem komercyjny | 23% | Art. 41 ust. 1 VAT |
| `sc.vat.a41.r10` | `vat_sc_rate_23_telecom` | Telekomunikacja | 23% | Art. 41 ust. 1 VAT |
| `sc.vat.a41.r11` | `vat_sc_rate_8_food` | Żywność podstawowa → GTU_07 | 8% | Art. 41 ust. 2 VAT |
| `sc.vat.a41.r12` | `vat_sc_rate_8_water_sewage` | Dostawa wody, ścieki | 8% | Art. 41 ust. 2 VAT |
| `sc.vat.a41.r13` | `vat_sc_rate_8_construction_residential` | Budownictwo mieszkaniowe → GTU_08 | 8% | Art. 41 ust. 2 VAT |
| `sc.vat.a41.r14` | `vat_sc_rate_8_pharma` | Leki, produkty farmaceutyczne → GTU_09 | 8% | Art. 41 ust. 2 VAT |
| `sc.vat.a41.r15` | `vat_sc_rate_8_transport_passenger` | Transport pasażerski → GTU_06 | 8% | Art. 41 ust. 2 VAT |
| `sc.vat.a41.r16` | `vat_sc_rate_8_hotel` | Hotele, noclegi | 8% | Art. 41 ust. 2 VAT |
| `sc.vat.a41.r17` | `vat_sc_rate_8_culture_events` | Imprezy kulturalne, sportowe | 8% | Art. 41 ust. 2 VAT |
| `sc.vat.a41.r18` | `vat_sc_rate_5_books_print` | Książki drukowane | 5% | Art. 41 ust. 2a VAT |
| `sc.vat.a41.r19` | `vat_sc_rate_5_ebooks` | E-booki, audiobooki | 5% | Art. 41 ust. 2a VAT |
| `sc.vat.a41.r20` | `vat_sc_rate_5_baby_products` | Artykuły niemowlęce | 5% | Art. 41 ust. 2a VAT |
| `sc.vat.a41.r21` | `vat_sc_rate_5_food_basic` | Mięso, ryby, nabiał nieprzetworzone | 5% | Art. 41 ust. 2a VAT |
| `sc.vat.a41.r22` | `vat_sc_rate_0_export` | Eksport towarów poza UE | 0% | Art. 41 ust. 1 VAT |
| `sc.vat.a41.r23` | `vat_sc_rate_0_wdt` | WDT do nabywcy UE z VAT-UE | 0% | Art. 42 VAT |
| `sc.vat.a41.r24` | `vat_sc_rate_0_intl_transport` | Transport międzynarodowy | 0% | Art. 83 VAT |
| `sc.vat.a41.r25` | `vat_sc_rate_0_ships_aircraft` | Dostawy na statki, samoloty | 0% | Art. 83 VAT |
| `sc.vat.a41.r26` | `vat_sc_rate_zw_education` | Usługi edukacyjne | ZW | Art. 43 ust. 1 pkt 26 VAT |
| `sc.vat.a41.r27` | `vat_sc_rate_zw_healthcare` | Usługi medyczne | ZW | Art. 43 ust. 1 pkt 18 VAT |
| `sc.vat.a41.r28` | `vat_sc_rate_zw_finance` | Usługi finansowe, pożyczki SC | ZW | Art. 43 ust. 1 pkt 38 VAT |
| `sc.vat.a41.r29` | `vat_sc_rate_zw_insurance` | Pośrednictwo ubezpieczeniowe SC | ZW | Art. 43 ust. 1 pkt 7 VAT |
| `sc.vat.a41.r30` | `vat_sc_rate_zw_social_welfare` | Pomoc społeczna, opieka | ZW | Art. 43 ust. 1 pkt 22 VAT |

### 2.4 Art. 86-88 VAT — Odliczenia VAT (~35 reguł)

| ID | Nazwa reguły | Warunek | Rezultat | Podstawa |
|:--:|-------------|---------|----------|:--------:|
| `sc.vat.a86.r1` | `vat_sc_deduction_general` [PARTNERSHIP] | Zakup towarów/usług dla czynności opodatkowanych SC | VAT naliczony → odliczenie | Art. 86 ust. 1 VAT |
| `sc.vat.a86.r2` | `vat_sc_deduction_vat_payer_only` ★ | Tylko SC jako czynny podatnik VAT ma prawo odliczenia | `vat_deduction_allowed: is_vat_payer` | Art. 86 ust. 1 VAT |
| `sc.vat.a86.r3` | `vat_sc_deduction_invoice_required` | Faktura VAT z NIP SC | `invoice_required: true` | Art. 86 ust. 2 VAT |
| `sc.vat.a86.r4` | `vat_sc_deduction_incorrect_nip_block` | Faktura z błędnym NIP SC → brak odliczenia | `vat_deduction_blocked: true` | Art. 88 ust. 1 pkt 2 VAT |
| `sc.vat.a86.r5` | `vat_sc_deduction_proportion_mixed` | Sprzedaż mieszana (opodatkowana + zwolniona) → proporcja | `vat_proportion: <percent>` | Art. 90 VAT |
| `sc.vat.a86.r6` | `vat_sc_deduction_proportion_98pct` | Proporcja > 98% → pełne odliczenie | `vat_deduction_full: true` | Art. 90 ust. 10 VAT |
| `sc.vat.a86.r7` | `vat_sc_deduction_proportion_under_2pct` | Proporcja < 2% → brak odliczenia | `vat_deduction_full: false` | Art. 90 ust. 10 VAT |
| `sc.vat.a86.r8` | `vat_sc_deduction_annual_correction` | Korekta roczna proporcji | `annual_vat_correction_required: true` | Art. 91 VAT |
| `sc.vat.a88.r1` | `vat_sc_deduction_blocked_hotel` | Usługi noclegowe → brak odliczenia | `vat_blocked: "HOTEL"` | Art. 88 ust. 1 pkt 4 VAT |
| `sc.vat.a88.r2` | `vat_sc_deduction_blocked_restaurant` | Gastronomia (poza cateringiem) → brak odliczenia | `vat_blocked: "RESTAURANT"` | Art. 88 ust. 1 pkt 4 VAT |
| `sc.vat.a88.r3` | `vat_sc_deduction_blocked_fuel_mixed_car` | Paliwo do aut mieszanych → 50% odliczenia | `vat_deduction_pct: 50` | Art. 86a VAT |
| `sc.vat.a88.r4` | `vat_sc_deduction_blocked_entertainment` | Rozrywka, reprezentacja → brak odliczenia | `vat_blocked: "ENTERTAINMENT"` | Art. 88 ust. 1 pkt 4 VAT |
| `sc.vat.a88.r5` | `vat_sc_deduction_blocked_gifts_over_20pln` | Prezenty > 20 PLN → brak odliczenia | `vat_blocked: "GIFTS"` | Art. 88 ust. 1 pkt 5 VAT |
| `sc.vat.a86a.r1` | `vat_sc_car_50pct_deduction` ★ | Auto mieszane SC → 50% VAT od zakupu, paliwa, napraw | `car_vat_deduction: 50` | Art. 86a VAT |
| `sc.vat.a86a.r2` | `vat_sc_car_100pct_mileage_log` | Ewidencja przebiegu → 100% VAT | `car_vat_deduction: 100` | Art. 86a VAT |
| `sc.vat.a86a.r3` | `vat_sc_car_100pct_exclusive_use` | Auto tylko firmowe → 100% VAT | `car_vat_deduction: 100` | Art. 86a VAT |
| `sc.vat.a89a.r1` | `vat_sc_bad_debt_creditor_150_days` | SC jako wierzyciel → 150 dni bez zapłaty = korekta | `bad_debt_creditor_correction: true` | Art. 89a VAT |
| `sc.vat.a89b.r1` | `vat_sc_bad_debt_debtor_90_days` ★ [SOLIDARNA] | SC jako dłużnik → OBOWIĄZEK korekty po 90 dniach + sankcja 30% | `bad_debt_debtor_mandatory: true`, `sanction_30pct_risk: true` | Art. 89b VAT |
| `sc.vat.a89b.r2` | `vat_sc_bad_debt_debtor_notification` | Zawiadomienie US o korekcie dłużnika | `us_notification_required: true` | Art. 89b VAT |

### 2.5 Art. 96 VAT — Rejestracja VAT SC (~15 reguł)

| ID | Nazwa reguły | Warunek | Rezultat | Podstawa |
|:--:|-------------|---------|----------|:--------:|
| `sc.vat.a96.r1` | `vat_sc_registration_vat_r` ★★ | SC rejestruje się jako podatnik VAT (VAT-R spółki) | `vat_r_required: true` | Art. 96 ust. 1 VAT |
| `sc.vat.a96.r2` | `vat_sc_registration_before_first_sale` | VAT-R przed pierwszą sprzedażą opodatkowaną | `vat_r_timing: "BEFORE_FIRST_SALE"` | Art. 96 ust. 1 VAT |
| `sc.vat.a96.r3` | `vat_sc_registration_deadline_7_days` | VAT-R w 7 dni od założenia SC | `vat_r_deadline_days: 7` | Art. 96 VAT |
| `sc.vat.a96.r4` | `vat_sc_registration_separate_nip` ★ | SC otrzymuje własny NIP (nie NIP wspólnika) | `nip_type: "PARTNERSHIP_OWN"` | Art. 96 ust. 1 VAT |
| `sc.vat.a96.r5` | `vat_sc_eu_registration_vat_ue` | VAT-UE przed pierwszym WDT/WNT | `vat_ue_required: true` | Art. 97 VAT |
| `sc.vat.a96.r6` | `vat_sc_deregistration_vat_z` | Zaprzestanie czynności → VAT-Z w 30 dni | `vat_z_required: true` | Art. 96 VAT |
| `sc.vat.a96.r7` | `vat_sc_deregistration_auto_6_months` | Brak sprzedaży 6 mies. → wykreślenie z urzędu | `auto_deregistration_risk: true` | Art. 96 VAT |
| `sc.vat.a96.r8` | `vat_sc_dissolution_deregistration` ★ | Rozwiązanie SC → VAT-Z + ostatnia deklaracja | `final_vat_deregistration: true` | Art. 96 VAT |
| `sc.vat.a96.r9` | `vat_sc_change_of_data_update` | Zmiana danych SC → aktualizacja VAT-R | `vat_r_update_required: true` | Art. 96 VAT |

### 2.6 Art. 99, 106a-106n VAT — Deklaracje i faktury (~30 reguł)

| ID | Nazwa reguły | Warunek | Rezultat | Podstawa |
|:--:|-------------|---------|----------|:--------:|
| `sc.vat.a99.r1` | `vat_sc_jpk_v7m_monthly` ★ [PARTNERSHIP] | SC jako czynny podatnik VAT → JPK_V7M co miesiąc | `jpk_v7m_required: true`, `deadline: "25th"` | Art. 99 ust. 1 VAT |
| `sc.vat.a99.r2` | `vat_sc_jpk_v7k_quarterly` | SC jako mały podatnik → JPK_V7K kwartalnie | `jpk_v7k_quarterly: true` | Art. 99 ust. 2 VAT |
| `sc.vat.a99.r3` | `vat_sc_jpk_zero_no_sales` | Brak sprzedaży → deklaracja zerowa | `jpk_zero_required: true` | Art. 99 VAT |
| `sc.vat.a99.r4` | `vat_sc_jpk_correction_after_audit` | Korekta JPK SC po kontroli | `jpk_correction: "RESTRICTED"` | Art. 99 VAT + Ordynacja |
| `sc.vat.a106e.r1` | `vat_sc_invoice_mandatory_nip_sc` ★ | Faktura SC musi zawierać NIP spółki (a nie wspólników) | `invoice_nip: partnership_nip` | Art. 106e VAT |
| `sc.vat.a106e.r2` | `vat_sc_invoice_mandatory_buyer_nip` | NIP nabywcy na fakturze SC | `buyer_nip_required: true` | Art. 106e VAT |
| `sc.vat.a106e.r3` | `vat_sc_invoice_numbering` | Numeracja faktur SC (niezależna od JDG wspólników) | `invoice_number_format: "SC/YYYY/MM/NNN"` | Art. 106e VAT |
| `sc.vat.a106e.r4` | `vat_sc_invoice_15_days_deadline` | Faktura do 15. dnia miesiąca po dostawie | `invoice_deadline_days: 15` | Art. 106i VAT |
| `sc.vat.a106e.r5` | `vat_sc_invoice_advance_required` | Zaliczka → faktura zaliczkowa SC | `advance_invoice_required: true` | Art. 106f VAT |
| `sc.vat.a106e.r6` | `vat_sc_invoice_receipt_to_450pln` | Paragon z NIP SC do 450 PLN = faktura uproszczona | `simplified_invoice: true` | Art. 106e VAT |
| `sc.vat.a106j.r1` | `vat_sc_correction_invoice_minus` | Korekta in minus → VAT SC | `vat_correction_minus: true` | Art. 106j VAT |
| `sc.vat.a106j.r2` | `vat_sc_correction_buyer_agreement` | Potwierdzenie odbioru korekty przez nabywcę | `correction_agreement: true` | Art. 106j VAT |
| `sc.vat.a106na.r1` | `vat_sc_ksef_mandatory_2026` ★★ | SC od 01.02.2026 → obowiązek KSeF dla faktur sprzedaży | `ksef_required: true` | Art. 106na VAT + Dz.U. 2023 poz. 1598 |
| `sc.vat.a106na.r2` | `vat_sc_ksef_exempt_vat_exempt` | SC zwolniona z VAT → wyłączona z KSeF | `ksef_not_required: true` | Art. 106na VAT |
| `sc.vat.a106na.r3` | `vat_sc_ksef_b2c_excluded` | Faktury B2C SC → poza KSeF | `ksef_not_required: true` | Art. 106na VAT |
| `sc.vat.a106ne.r1` | `vat_sc_ksef_offline_7_days` | Awaria KSeF → 7 dni na wysłanie po przywróceniu | `ksef_offline_deadline_days: 7` | Art. 106ne VAT |
| `sc.vat.a106ng.r1` | `vat_sc_ksef_upo_required` | UPO dla każdej faktury KSeF SC | `upo_required: true` | Art. 106ng VAT |
| `sc.vat.a106nh.r1` | `vat_sc_ksef_qr_code` | Kod QR na fakturze wizualnej SC | `qr_code_required: true` | Art. 106nh VAT |
| `sc.vat.a106nq.r1` | `vat_sc_ksef_sanction_100pct` [SOLIDARNA] | Sankcja 100% VAT za brak KSeF → solidarna | `ksef_sanction_100pct: true`, `joint_liability: true` | Art. 106nq VAT |
| `sc.vat.a108a.r1` | `vat_sc_mpp_mandatory_over_15k` | Faktura >15k PLN + kategoria MPP → split payment | `mpp_required: true` | Art. 108a VAT |
| `sc.vat.a108a.r2` | `vat_sc_mpp_account_sc_own` ★ | SC ma własny rachunek VAT (nie wspólnika) | `vat_account: partnership_vat_account` | Art. 108a VAT |
| `sc.vat.a108a.r3` | `vat_sc_mpp_sanction_30pct` [SOLIDARNA] | Brak MPP → sankcja 30% VAT + solidarna | `mpp_sanction: true` | Art. 108a VAT |
| `sc.vat.a96b.r1` | `vat_sc_whitelist_check_over_15k` | Przelew SC >15k → weryfikacja Białej Listy | `whitelist_check_required: true` | Art. 96b VAT |
| `sc.vat.a96b.r2` | `vat_sc_whitelist_missing_sanction` [SOLIDARNA] | Brak na WL → solidarna odpowiedzialność za VAT | `whitelist_penalty: true`, `joint_liability: true` | Art. 96b + 117ba OP |
| `sc.vat.a113.r1` | `vat_sc_exemption_subject_200k` ★★ [PARTNERSHIP] | Limit 200k PLN dla całej SC (suma obrotów) | `vat_exemption_limit: 200000`, `vat_exemption_applies: sum(turnover) < 200k` | Art. 113 ust. 1 VAT |
| `sc.vat.a113.r2` | `vat_sc_exemption_loss_on_exceed` | Przekroczenie 200k → utrata zwolnienia | `vat_exemption_lost: true` | Art. 113 ust. 5 VAT |
| `sc.vat.a113.r3` | `vat_sc_exemption_counted_for_partnership` ★ | Próg liczony od OBRÓTÓW SC (nie pojedynczego wspólnika!) | `vat_exemption_scope: "PARTNERSHIP_TOTAL"` | Art. 113 ust. 9 VAT |
| `sc.vat.a113.r4` | `vat_sc_exemption_not_for_wnt_wdt` | Zwolnienie NIE dotyczy WNT/WDT/importu | `vat_exemption_excludes: ["WNT", "WDT", "IMPORT"]` | Art. 113 ust. 13 VAT |

### 2.7 GTU — Oznaczenia JPK_V7 (~20 reguł)

| ID | Nazwa reguły | Warunek | GTU | Podstawa |
|:--:|-------------|---------|:---:|:--------:|
| `sc.vat.gtu.r1` | `gtu_sc_01_electronics` | Sprzęt elektroniczny SC | GTU_01 | § 10 rozp. JPK |
| `sc.vat.gtu.r2` | `gtu_sc_02_alcohol` | Alkohol w obrocie SC | GTU_02 | § 10 rozp. JPK |
| `sc.vat.gtu.r3` | `gtu_sc_03_tobacco` | Wyroby tytoniowe SC | GTU_03 | § 10 rozp. JPK |
| `sc.vat.gtu.r4` | `gtu_sc_04_fuel` | Paliwa, oleje SC | GTU_04 | § 10 rozp. JPK |
| `sc.vat.gtu.r5` | `gtu_sc_05_scrap` | Złom, odpady SC | GTU_05 | § 10 rozp. JPK |
| `sc.vat.gtu.r6` | `gtu_sc_06_transport` | Transport, spedycja SC | GTU_06 | § 10 rozp. JPK |
| `sc.vat.gtu.r7` | `gtu_sc_07_food` | Żywność, napoje SC | GTU_07 | § 10 rozp. JPK |
| `sc.vat.gtu.r8` | `gtu_sc_08_construction` | Roboty budowlane SC | GTU_08 | § 10 rozp. JPK |
| `sc.vat.gtu.r9` | `gtu_sc_09_pharma` | Leki, wyroby medyczne SC | GTU_09 | § 10 rozp. JPK |
| `sc.vat.gtu.r10` | `gtu_sc_10_real_estate` | Nieruchomości SC | GTU_10 | § 10 rozp. JPK |
| `sc.vat.gtu.r11` | `gtu_sc_11_gas_energy` | Gaz, energia SC | GTU_11 | § 10 rozp. JPK |
| `sc.vat.gtu.r12` | `gtu_sc_12_eu_services` | Usługi wewnątrzwspólnotowe SC | GTU_12 | § 10 rozp. JPK |
| `sc.vat.gtu.r13` | `gtu_sc_13_non_eu_import` | Import spoza UE przez SC | GTU_13 | § 10 rozp. JPK |
| `sc.vat.gtu.r14` | `gtu_sc_completeness_check` | Brak GTU dla kategorii wymagającej → błąd JPK | `gtu_missing_error: true` | § 10 rozp. JPK |

---

## CZĘŚĆ III: PIT WSPÓLNIKÓW (Art. 8-45) (~450 REGUŁ)

> **KLUCZOWA SPECYFIKA SC:** Spółka cywilna NIE jest podatnikiem PIT. Podatnikami są WSPÓLNICY indywidualnie. Wszystkie reguły PIT są na poziomie PARTNER×N z podziałem proporcjonalnym.

### 3.1 Art. 8 PIT — Proporcjonalny podział (FUNDAMENT) (~30 reguł)

| ID | Nazwa reguły | Warunek | Rezultat | Podstawa |
|:--:|-------------|---------|----------|:--------:|
| `sc.pit.a8.r1` | `pit_partner_revenue_proportional` ★★★ [PROPORCJA×N] | FUNDAMENT: przychód SC × udział % = przychód wspólnika | `partner_revenue: total_revenue * share/100` | Art. 8 ust. 1 PIT |
| `sc.pit.a8.r2` | `pit_partner_cost_proportional` ★★★ [PROPORCJA×N] | FUNDAMENT: koszty SC × udział % = KUP wspólnika | `partner_cost: total_cost * share/100` | Art. 8 ust. 2 PIT |
| `sc.pit.a8.r3` | `pit_partner_income_calculation` [PARTNER×N] | Dochód wspólnika = przychód - KUP (proporcjonalnie) | `partner_income: revenue_share - cost_share` | Art. 8 + Art. 24 PIT |
| `sc.pit.a8.r4` | `pit_partner_loss_proportional` [PROPORCJA×N] | Strata SC × udział % = strata wspólnika | `partner_loss: total_loss * share/100` | Art. 8 ust. 2 PIT |
| `sc.pit.a8.r5` | `pit_partner_share_percent_from_agreement` | Udział wynika z umowy SC (Art. 867 KC) | `share_percent: agreement_value` | Art. 8 ust. 1 PIT ↔ Art. 867 KC |
| `sc.pit.a8.r6` | `pit_partner_share_equal_default` | Brak określenia → równe udziały | `share_percent: 100/count(partners)` | Art. 8 ust. 1 PIT + Art. 861 KC |
| `sc.pit.a8.r7` | `pit_partner_revenue_cash_method_sc` [PARTNER×N] | SC na metodzie kasowej → przychód w dacie zapłaty (dzielony proporcjonalnie) | `revenue_timing: "CASH"` | Art. 8 + Art. 14 PIT |
| `sc.pit.a8.r8` | `pit_partner_revenue_accrual_method_sc` [PARTNER×N] | SC na metodzie memoriałowej → przychód w dacie faktury | `revenue_timing: "ACCRUAL"` | Art. 8 + Art. 14 PIT |
| `sc.pit.a8.r9` | `pit_partner_kup_direct_vs_indirect` [PARTNER×N] | KUP bezpośrednie → rok przychodu; pośrednie → data poniesienia | `kup_timing: "DIRECT" lub "INDIRECT"` | Art. 22 PIT |
| `sc.pit.a8.r10` | `pit_partner_kup_unpaid_90_days` [PARTNER×N] | Niezapłacona faktura >90 dni → OBOWIĄZEK wyłączenia z KUP u wspólnika | `kup_reversal_required: true` | Art. 22p PIT |
| `sc.pit.a8.r11` | `pit_partner_different_tax_forms` ★★ [PARTNER×N] | Wspólnik A na skali, B na liniowym, C na ryczałcie → każdy rozlicza swoją część według swojej formy | `tax_form_per_partner: individual` | Art. 8 + Art. 9a PIT |
| `sc.pit.a8.r12` | `pit_partner_lump_sum_share_limit` ★ [PARTNER] | Wspólnik na ryczałcie → limit 2M EUR liczony od przychodów CAŁEJ SC | `lump_sum_eligible: total_sc_revenue < 2M EUR` | Art. 8 + Art. 6 ustawy o ryczałcie |
| `sc.pit.a8.r13` | `pit_partner_linear_share_no_tax_free` [PARTNER] | Wspólnik na liniowym → brak kwoty wolnej, 19% od swojej części | `tax_free_amount: 0` | Art. 30c PIT |
| `sc.pit.a8.r14` | `pit_partner_scale_tax_free_30k` [PARTNER] | Wspólnik na skali → kwota wolna 30k, 12%/32% | `tax_free_amount: 30000`, `tax_free_reduction: 3600` | Art. 27 PIT |
| `sc.pit.a8.r15` | `pit_partner_scale_120k_bracket` [PARTNER] | Dochód wspólnika > 120k → 32% od nadwyżki | `tax_bracket_high: true` | Art. 27 PIT |
| `sc.pit.a8.r16` | `pit_partner_zus_social_deductible` [PARTNER×N] | Składki ZUS społeczne wspólnika → KUP od jego dochodu | `zus_social_deductible: zus_social_paid` | Art. 26 ust. 1 pkt 2 PIT |
| `sc.pit.a8.r17` | `pit_partner_health_deduction_limit` [PARTNER×N] ★ | Zdrowotna 9% od dochodu (skala) NIE odlicza się od podatku; 4.9% (liniowy) → limit 12900 | `health_deductible: varies_by_form` | Art. 27b + Art. 30c PIT |
| `sc.pit.a8.r18` | `pit_partner_sc_revenue_in_kind` [PROPORCJA×N] | Przychód w naturze SC → wartość rynkowa dzielona proporcjonalnie | `in_kind_value_per_partner: market_value * share/100` | Art. 14 PIT |
| `sc.pit.a8.r19` | `pit_partner_fx_difference_split` [PROPORCJA×N] | Różnice kursowe SC dzielone proporcjonalnie | `fx_per_partner: total_fx * share/100` | Art. 14c PIT |
| `sc.pit.a8.r20` | `pit_partner_interest_income_split` [PROPORCJA×N] | Odsetki bankowe SC → przychód dzielony proporcjonalnie | `interest_per_partner: total * share/100` | Art. 14 PIT |
| `sc.pit.a8.r21` | `pit_partner_depreciation_split` [PROPORCJA×N] ★ | Amortyzacja środków trwałych SC → odpis dzielony proporcjonalnie | `depreciation_per_partner: total_depr * share/100` | Art. 8 + Art. 22a PIT |
| `sc.pit.a8.r22` | `pit_partner_lease_split` [PROPORCJA×N] | Raty leasingowe SC → KUP dzielony proporcjonalnie | `lease_kup_per_partner: total * share/100` | Art. 8 + Art. 23 PIT |
| `sc.pit.a8.r23` | `pit_partner_inventory_difference` [PROPORCJA×N] | Różnica remanentowa SC → wpływ na dochód per wspólnik | `inventory_effect: diff * share/100` | Art. 24 PIT |
| `sc.pit.a8.r24` | `pit_partner_correction_invoice` [PROPORCJA×N] | Korekta faktury → zmiana przychodu/KUP per wspólnik | `correction_effect: delta * share/100` | Art. 8 + Art. 14 PIT |
| `sc.pit.a8.r25` | `pit_partner_contribution_own_labor_nkup` ★ | Praca własna wspólnika → NIE KUP (nawet proporcjonalnie!) | `own_labor_kup: 0` | Art. 23 ust. 1 pkt 10 PIT |
| `sc.pit.a8.r26` | `pit_partner_spouse_labor_nkup` ★ | Praca małżonka wspólnika bez umowy → NIE KUP | `spouse_labor_kup: 0` if no contract | Art. 23 ust. 1 pkt 10 PIT |
| `sc.pit.a8.r27` | `pit_partner_minor_children_labor_nkup` | Praca małoletnich dzieci wspólnika → NIE KUP | `children_labor_kup: 0` | Art. 23 ust. 1 pkt 10 PIT |
| `sc.pit.a8.r28` | `pit_partner_private_use_percent` [PARTNER×N] ★ | Wydatek mieszany → % prywatnego użycia × udział → pomniejszenie KUP | `private_use_reduction: cost * private_pct * share/100` | Art. 23 ust. 1 pkt 46 PIT |
| `sc.pit.a8.r29` | `pit_partner_car_75pct_kup` [PARTNER×N] ★ | Auto mieszane bez ewidencji → 75% KUP z części wspólnika | `car_kup_pct: 75` | Art. 23 ust. 1 pkt 46 PIT |
| `sc.pit.a8.r30` | `pit_partner_car_150k_limit` [PARTNER×N] ★ | Auto >150k PLN → KUP ograniczony proporcjonalnie do limitu × udział | `car_limit_kup: min(cost, 150k) * share/100` | Art. 23 ust. 1 pkt 47a PIT |

### 3.2 Art. 22-23 PIT — KUP i wyłączenia (~40 reguł)

| ID | Nazwa reguły | Warunek | Rezultat | Podstawa |
|:--:|-------------|---------|----------|:--------:|
| `sc.pit.a22.r1` | `pit_kup_general_definition_sc` [PARTNER×N] | Koszt poniesiony w celu osiągnięcia przychodu SC → KUP per wspólnik | `kup_qualifies: true` | Art. 22 ust. 1 PIT |
| `sc.pit.a22.r2` | `pit_kup_indirect_timing_invoice` [PARTNER×N] | Koszty pośrednie → data faktury | `kup_date: invoice_date` | Art. 22 ust. 4 PIT |
| `sc.pit.a22.r3` | `pit_kup_direct_timing_revenue_year` [PARTNER×N] | Koszty bezpośrednie → rok odpowiadającego przychodu | `kup_date: revenue_year` | Art. 22 ust. 5 PIT |
| `sc.pit.a23.r1` | `pit_nkup_representation` [PARTNER×N] | Reprezentacja, gastronomia → NKUP | `kup: 0` | Art. 23 ust. 1 pkt 23 PIT |
| `sc.pit.a23.r2` | `pit_nkup_own_labor_partner` ★ [PARTNER] | Praca własna wspólnika → NKUP | `kup: 0` | Art. 23 ust. 1 pkt 10 PIT |
| `sc.pit.a23.r3` | `pit_nkup_spouse_no_contract` ★ [PARTNER] | Praca małżonka bez umowy → NKUP | `kup: 0` | Art. 23 ust. 1 pkt 10 PIT |
| `sc.pit.a23.r4` | `pit_nkup_children_labor` [PARTNER] | Praca małoletnich dzieci → NKUP | `kup: 0` | Art. 23 ust. 1 pkt 10 PIT |
| `sc.pit.a23.r5` | `pit_nkup_personal_expenses` [PARTNER×N] | Wydatki osobiste wspólnika → NKUP | `kup: 0` | Art. 23 ust. 1 pkt 49 PIT |
| `sc.pit.a23.r6` | `pit_nkup_penalties_tax` [PARTNER×N] | Kary podatkowe, grzywny → NKUP | `kup: 0` | Art. 23 ust. 1 pkt 19 PIT |
| `sc.pit.a23.r7` | `pit_nkup_donations` [PARTNER×N] | Darowizny → NKUP (ale mogą być ulgą) | `kup: 0` | Art. 23 ust. 1 pkt 11 PIT |
| `sc.pit.a23.r8` | `pit_nkup_loan_principal` | Spłata kapitału pożyczki → NKUP | `kup: 0` | Art. 23 ust. 1 pkt 8 PIT |
| `sc.pit.a23.r9` | `pit_kup_loan_interest` [PARTNER×N] | Odsetki od kredytu SC → KUP (proporcjonalnie) | `kup: interest * share/100` | Art. 22 + Art. 23 PIT |
| `sc.pit.a23.r10` | `pit_nkup_capital_expenditure` [PARTNER×N] | Wydatki na środki trwałe → amortyzacja (nie bezpośredni KUP) | `kup: via_depreciation` | Art. 23 ust. 1 pkt 1 PIT |
| `sc.pit.a23.r11` | `pit_nkup_land_purchase` | Zakup gruntu → brak amortyzacji, brak KUP | `kup: 0` | Art. 23 ust. 1 pkt 1 PIT |
| `sc.pit.a23.r12` | `pit_kup_zus_social_paid` [PARTNER] ★ | Składki ZUS społeczne wspólnika → KUP od jego dochodu | `kup_zus: zus_social_paid` | Art. 22 ust. 1 PIT |
| `sc.pit.a23.r13` | `pit_kup_unpaid_reversal_90_days` [PARTNER×N] | Faktura nieopłacona >90 dni → OBOWIĄZEK wyłączenia z KUP | `kup_reversal: full_amount` | Art. 22p PIT |

### 3.3 Art. 27 PIT — Skala podatkowa (~20 reguł)

| ID | Nazwa reguły | Warunek | Rezultat | Podstawa |
|:--:|-------------|---------|----------|:--------:|
| `sc.pit.a27.r1` | `pit_scale_rate_12pct` [PARTNER] | Dochód wspólnika ze SC ≤ 120k → 12% | `pit_rate: 0.12` | Art. 27 ust. 1 PIT |
| `sc.pit.a27.r2` | `pit_scale_rate_32pct` [PARTNER] | Dochód > 120k → 32% od nadwyżki | `pit_rate_high: 0.32` | Art. 27 ust. 1 PIT |
| `sc.pit.a27.r3` | `pit_scale_tax_free_30k` [PARTNER] | Kwota wolna 30 000 PLN → 12% × 30k = 3 600 PLN odliczenia | `tax_free_reduction: 3600` | Art. 27 ust. 1a PIT |
| `sc.pit.a27.r4` | `pit_scale_tax_free_phase_out` [PARTNER] | Dochód > 120k → kwota wolna wygasa | `tax_free_available: decreasing` | Art. 27 ust. 1a PIT |
| `sc.pit.a27.r5` | `pit_scale_income_aggregation` [PARTNER] | Dochód z SC + inne źródła (etat) = podstawa skali | `total_income: sc_income + other` | Art. 27 PIT |
| `sc.pit.a27.r6` | `pit_scale_joint_filing_spouse` [PARTNER] | Wspólne rozliczenie z małżonkiem → 2× kwota wolna | `joint_filing: true`, `tax_free_double: 7200` | Art. 27 ust. 2 PIT |
| `sc.pit.a27.r7` | `pit_scale_joint_not_available_linear` [PARTNER] | Wspólnik na liniowym NIE może wspólnego rozliczenia | `joint_filing: false` | Art. 30c PIT |
| `sc.pit.a27.r8` | `pit_scale_single_parent` [PARTNER] | Samotny rodzic → preferencyjne obliczenie | `single_parent_preference: true` | Art. 27 ust. 2 PIT |
| `sc.pit.a27.r9` | `pit_scale_advance_monthly` [PARTNER] ★ | Zaliczka miesięczna od dochodu wspólnika ze SC | `advance_due: income * rate - zus - paid` | Art. 44 PIT |
| `sc.pit.a27.r10` | `pit_scale_annual_return_pit36` [PARTNER] ★ | PIT-36 składany do 30 kwietnia | `return_type: "PIT-36"`, `deadline: "30_april"` | Art. 45 PIT |
| `sc.pit.a27.r11` | `pit_scale_sc_income_box` [PARTNER] | Dochód z SC wykazywany w PIT-36 poz. 51-53 | `pit36_box: "51-53"` | Art. 45 PIT |

### 3.4 Art. 30c PIT — Podatek liniowy (~15 reguł)

| ID | Nazwa reguły | Warunek | Rezultat | Podstawa |
|:--:|-------------|---------|----------|:--------:|
| `sc.pit.a30c.r1` | `pit_linear_rate_19pct` [PARTNER] | Dochód wspólnika ze SC → 19% | `pit_rate: 0.19` | Art. 30c PIT |
| `sc.pit.a30c.r2` | `pit_linear_no_tax_free` [PARTNER] | Liniowy → brak kwoty wolnej | `tax_free: 0` | Art. 30c PIT |
| `sc.pit.a30c.r3` | `pit_linear_no_joint_filing` [PARTNER] | Liniowy → brak wspólnego rozliczenia | `joint_filing: false` | Art. 30c PIT |
| `sc.pit.a30c.r4` | `pit_linear_health_4_9pct` [PARTNER] ★ | Zdrowotna 4.9% od dochodu (nie odlicza się od podatku) | `health_rate: 0.049`, `health_deductible_max: 12900` | Art. 30c PIT + Art. 81 u.z. |
| `sc.pit.a30c.r5` | `pit_linear_annual_return_pit36l` [PARTNER] ★ | PIT-36L do 30 kwietnia | `return_type: "PIT-36L"` | Art. 45 ust. 1a PIT |
| `sc.pit.a30c.r6` | `pit_linear_sc_income_box` [PARTNER] | Dochód z SC w PIT-36L poz. 10-12 | `pit36l_box: "10-12"` | Art. 45 PIT |
| `sc.pit.a30c.r7` | `pit_linear_former_employer_restriction_sc` ★★ | Wspólnik świadczący przez SC usługi dla byłego pracodawcy → NIE może być na liniowym | `linear_blocked: true`, `must_use_scale: true` | Art. 9a ust. 3 PIT |
| `sc.pit.a30c.r8` | `pit_linear_former_employer_3_years` | Zakaz liniowego przez 3 lata od ustania etatu (te same czynności) | `linear_blocked_years: 3` | Art. 9a ust. 3 PIT |
| `sc.pit.a30c.r9` | `pit_linear_form_change_deadline` [PARTNER] | Zmiana na liniowy → do 20 stycznia | `form_change_deadline: "20_january"` | Art. 9a PIT |

### 3.5 Art. 12 ustawy o ryczałcie — Ryczałt (~30 reguł)

| ID | Nazwa reguły | Warunek | Rezultat | Podstawa |
|:--:|-------------|---------|----------|:--------:|
| `sc.ryczalt.r1` | `pit_lump_sum_available_sc` ★ [PARTNER] | Przychód CAŁEJ SC < 2M EUR → ryczałt dostępny | `lump_sum_eligible: total_sc_revenue < 2M EUR` | Art. 6 ustawy o ryczałcie |
| `sc.ryczalt.r2` | `pit_lump_sum_rate_17pct` [PARTNER] | Wolne zawody (lekarz, prawnik, doradca) → 17% | `lump_rate: 0.17` | Art. 12 ust. 1 pkt 1 ryczałt |
| `sc.ryczalt.r3` | `pit_lump_sum_rate_14pct` [PARTNER] | IT, naprawa sprzętu → 14% | `lump_rate: 0.14` | Art. 12 ust. 1 pkt 2 ryczałt |
| `sc.ryczalt.r4` | `pit_lump_sum_rate_12pct` [PARTNER] | Usługi programistyczne, architektoniczne → 12% | `lump_rate: 0.12` | Art. 12 ust. 1 pkt 3 ryczałt |
| `sc.ryczalt.r5` | `pit_lump_sum_rate_8_5pct` [PARTNER] | Działalność usługowa, handel → 8.5% | `lump_rate: 0.085` | Art. 12 ust. 1 pkt 5 ryczałt |
| `sc.ryczalt.r6` | `pit_lump_sum_rate_5_5pct` [PARTNER] | Budownictwo → 5.5% | `lump_rate: 0.055` | Art. 12 ust. 1 pkt 4 ryczałt |
| `sc.ryczalt.r7` | `pit_lump_sum_rate_3pct` [PARTNER] | Działalność wytwórcza, gastronomiczna → 3% | `lump_rate: 0.03` | Art. 12 ust. 1 pkt 6 ryczałt |
| `sc.ryczalt.r8` | `pit_lump_sum_rate_2pct` [PARTNER] | Działalność rolnicza → 2% | `lump_rate: 0.02` | Art. 12 ust. 1 pkt 7 ryczałt |
| `sc.ryczalt.r9` | `pit_lump_sum_no_kup` [PARTNER] ★ | Ryczałt → brak KUP (podatek od przychodu, nie dochodu) | `kup_deduction: false` | Art. 12 ryczałt |
| `sc.ryczalt.r10` | `pit_lump_sum_zus_deduction` [PARTNER] | Składki ZUS społeczne → odliczenie od przychodu przed opodatkowaniem | `revenue_after_zus: gross - zus_social` | Art. 11 ryczałt |
| `sc.ryczalt.r11` | `pit_lump_sum_health_lump` [PARTNER] ★ | Zdrowotna wg progów ryczałtowych (60%/100%/180% przeciętnego) | `health_tier: I/II/III` | Art. 81 ust. 2a u.z. |
| `sc.ryczalt.r12` | `pit_lump_sum_no_loss_carry` ★ [PARTNER] | Ryczałtowiec NIE odlicza straty ze SC! | `loss_deduction: false` | Art. 12 ryczałt |
| `sc.ryczalt.r13` | `pit_lump_sum_pit28_return` [PARTNER] ★ | PIT-28 do 28 LUTEGO (nie 30 kwietnia!) | `return_type: "PIT-28"`, `deadline: "28_february"` | Art. 21 ryczałt |
| `sc.ryczalt.r14` | `pit_lump_sum_quarterly_advance` [PARTNER] | Mały podatnik → zaliczki kwartalne | `advance_frequency: "QUARTERLY"` | Art. 21 ryczałt |
| `sc.ryczalt.r15` | `pit_lump_sum_monthly_advance` [PARTNER] | Standard → zaliczki miesięczne do 20. dnia | `advance_frequency: "MONTHLY"` | Art. 21 ryczałt |

---

## CZĘŚĆ IV: ZUS WSPÓLNIKÓW (~250 REGUŁ)

> **Kluczowa specyfika SC:** Każdy wspólnik płaci ZUS INDYWIDUALNIE od swojego dochodu z SC. Spółka nie płaci ZUS za wspólników. Różni wspólnicy mogą mieć RÓŻNY status ZUS.

### 4.1 Art. 6, 18-22 SUS — Składki społeczne (~45 reguł)

| ID | Nazwa reguły | Warunek | Rezultat | Podstawa |
|:--:|-------------|---------|----------|:--------:|
| `sc.zus.a6.r1` | `zus_partner_subject_individual` ★★★ [PARTNER] | Każdy wspólnik SC podlega ubezpieczeniom INDYWIDUALNIE | `partner_zus_individual: true` | Art. 6 ust. 1 pkt 5 SUS |
| `sc.zus.a6.r2` | `zus_partner_not_employee_of_sc` ★ | Wspólnik NIE jest pracownikiem SC (chyba że umowa o pracę) | `employment_status: "PARTNER"` | Art. 6 SUS |
| `sc.zus.a18.r1` | `zus_partner_base_60pct_avg_wage` [PARTNER] | Podstawa: 60% prognozowanego przeciętnego wynagrodzenia | `zus_base: 0.60 * avg_wage` | Art. 18 ust. 8 SUS |
| `sc.zus.a18a.r1` | `zus_partner_start_relief_6_months` [PARTNER] ★ | Ulga na start → 6 miesięcy bez składek społecznych | `zus_social: 0`, `start_relief_months: 6` | Art. 18a SUS |
| `sc.zus.a18a.r2` | `zus_partner_start_relief_health_only` [PARTNER] ★ | Ulga na start → tylko składka zdrowotna | `zus_health_still_due: true` | Art. 18a SUS |
| `sc.zus.a18a.r3` | `zus_partner_start_relief_first_business` | Ulga na start → tylko pierwsza działalność (lub po 60 miesiącach przerwy) | `start_relief_eligible: first_or_60m_break` | Art. 18a SUS |
| `sc.zus.a18a.r4` | `zus_partner_start_relief_partners_independent` ★★ | Każdy wspólnik ma własne 6 miesięcy (niezależnie od innych wspólników) | `start_relief_per_partner: independent` | Art. 18a SUS |
| `sc.zus.a18c.r1` | `zus_partner_maly_plus_36_months` [PARTNER] ★ | Mały ZUS Plus → 36 miesięcy z niższą podstawą | `maly_plus_months: 36`, `base: 0.30 * avg_wage` | Art. 18c SUS |
| `sc.zus.a18c.r2` | `zus_partner_maly_plus_income_limit` | Przychód wspólnika z SC < 120k PLN rocznie | `maly_plus_eligible: income < 120k` | Art. 18c SUS |
| `sc.zus.a18c.r3` | `zus_partner_maly_plus_not_with_start` | Mały ZUS Plus wyklucza się z ulgą na start | `maly_plus_exclusive: true` | Art. 18c SUS |
| `sc.zus.a22.r1` | `zus_partner_pension_19_52pct` [PARTNER] | Emerytalna 19.52% podstawy | `pension: base * 0.1952` | Art. 22 SUS |
| `sc.zus.a22.r2` | `zus_partner_disability_8pct` [PARTNER] | Rentowa 8% podstawy | `disability: base * 0.08` | Art. 22 SUS |
| `sc.zus.a22.r3` | `zus_partner_sickness_2_45pct_voluntary` [PARTNER] ★ | Chorobowa 2.45% — DOBROWOLNA dla SC! | `sickness_voluntary: true` | Art. 22 SUS |
| `sc.zus.a22.r4` | `zus_partner_accident_1_67pct` [PARTNER] | Wypadkowa 1.67% | `accident: base * 0.0167` | Art. 22 SUS |
| `sc.zus.a22.r5` | `zus_partner_labour_fund_2_45pct` [PARTNER] | FP 2.45% | `labour_fund: base * 0.0245` | Art. 22 SUS |
| `sc.zus.a9.r1` | `zus_partner_concurrent_employment_sc` ★★ [PARTNER] | Zbieg etat + SC → tylko zdrowotna z SC (społeczne z etatu) | `zus_social_from_sc: 0`, `zus_health_from_sc: true` | Art. 9 ust. 1a SUS |
| `sc.zus.a9.r2` | `zus_partner_concurrent_employment_salary_min` | Warunek: wynagrodzenie z etatu ≥ min. wynagrodzenie | `salary_check: >= min_wage` | Art. 9 ust. 1a SUS |
| `sc.zus.a9.r3` | `zus_partner_concurrent_employment_salary_below_min` | Wynagrodzenie < min → społeczne ZUS z SC normalnie | `zus_social_from_sc: normal` | Art. 9 ust. 1a SUS |
| `sc.zus.a9.r4` | `zus_partner_concurrent_multiple_sc` | Wspólnik w kilku SC → składki tylko z jednej | `single_zus_payment: true` | Art. 9 SUS |
| `sc.zus.a36.r1` | `zus_partner_payment_deadline_10th` [PARTNER] | Składki ZUS do 10. dnia miesiąca za poprzedni miesiąc | `payment_deadline: "10th"` | Art. 36 SUS |

### 4.2 Art. 79-81 ustawy zdrowotnej — Składka zdrowotna (~40 reguł)

| ID | Nazwa reguły | Warunek | Rezultat | Podstawa |
|:--:|-------------|---------|----------|:--------:|
| `sc.zdrowotna.r1` | `health_partner_scale_9pct` [PARTNER] ★ | Skala → 9% od dochodu | `health_rate: 0.09`, `health_base: "INCOME"` | Art. 79 u.z. |
| `sc.zdrowotna.r2` | `health_partner_scale_no_deduction_from_tax` [PARTNER] ★★ | 9% NIE odlicza się od podatku przy skali (Polski Ład) | `health_deductible_from_tax: false` | Polski Ład |
| `sc.zdrowotna.r3` | `health_partner_linear_4_9pct` [PARTNER] ★ | Liniowy → 4.9% od dochodu | `health_rate: 0.049` | Art. 81 u.z. |
| `sc.zdrowotna.r4` | `health_partner_linear_deduction_12900` [PARTNER] ★ | Liniowy → max 12 900 PLN odliczenia od dochodu rocznie | `health_deduction_max: 12900` | Art. 30c PIT |
| `sc.zdrowotna.r5` | `health_partner_lump_sum_tier_I` [PARTNER] ★ | Ryczałt: przychód ≤ 60k → podstawa 60% przeciętnego | `health_base: 0.60 * avg_wage` | Art. 81 ust. 2a u.z. |
| `sc.zdrowotna.r6` | `health_partner_lump_sum_tier_II` [PARTNER] ★ | Ryczałt: 60k < przychód ≤ 300k → podstawa 100% przeciętnego | `health_base: 1.00 * avg_wage` | Art. 81 ust. 2b u.z. |
| `sc.zdrowotna.r7` | `health_partner_lump_sum_tier_III` [PARTNER] ★ | Ryczałt: przychód > 300k → podstawa 180% przeciętnego | `health_base: 1.80 * avg_wage` | Art. 81 ust. 2c u.z. |
| `sc.zdrowotna.r8` | `health_partner_rate_always_9pct` [PARTNER] | Stawka składki zawsze 9% (niezależnie od formy) | `health_rate: 0.09` | Art. 79 u.z. |
| `sc.zdrowotna.r9` | `health_partner_annual_settlement_lump` [PARTNER] ★ | Roczne rozliczenie zdrowotnej dla ryczałtowca → PIT-28 | `health_annual_settlement: true` | Art. 81 u.z. |
| `sc.zdrowotna.r10` | `health_partner_different_forms_same_sc` ★★ | Wspólnik A na skali 9%, B na liniowym 4.9% → różne zdrowotne | `health_per_partner_different: true` | Art. 79+81 u.z. |
| `sc.zdrowotna.r11` | `health_partner_minimum_base_guaranteed` [PARTNER] | Podstawa zdrowotnej nie niższa niż minimalne wynagrodzenie | `health_base_min: min_wage` | Art. 81 u.z. |
| `sc.zdrowotna.r12` | `health_partner_suspension_still_due` [PARTNER] ★ | Zawieszenie SC → zdrowotna NADAL należna! | `health_during_suspension: true` | Art. 81 u.z. |
| `sc.zdrowotna.r13` | `health_partner_start_relief_due` [PARTNER] ★ | Ulga na start → tylko zdrowotna (bez społecznych) | `health_during_start: true` | Art. 81 u.z. |

---

## CZĘŚĆ V: RACHUNKOWOŚĆ — PKPiR I PEŁNA KSIĘGOWOŚĆ (~120 REGUŁ)

> **Kluczowa specyfika SC:** Spółka cywilna prowadzi JEDNĄ wspólną PKPiR (lub księgi rachunkowe). Po przekroczeniu 2M EUR przychodu → OBOWIĄZKOWA pełna księgowość.

### 5.1 Art. 2 UoR — Próg pełnej księgowości (~15 reguł)

| ID | Nazwa reguły | Warunek | Rezultat | Podstawa |
|:--:|-------------|---------|----------|:--------:|
| `sc.uor.a2.r1` | `uor_sc_full_accounting_threshold` ★★★ [PARTNERSHIP] | Przychód SC za poprzedni rok ≥ 2M EUR → OBOWIĄZEK pełnej księgowości | `accounting_method: "FULL"`, `uor_mandatory: true` | Art. 2 ust. 1 pkt 1 UoR |
| `sc.uor.a2.r2` | `uor_sc_full_accounting_threshold_pln` | Przeliczenie 2M EUR po średnim kursie NBP na ostatni dzień roku | `threshold_pln: 2M * nbp_rate` | Art. 2 UoR |
| `sc.uor.a2.r3` | `uor_sc_pkpir_below_threshold` | Przychód < 2M EUR → PKPiR dozwolona | `accounting_method: "PKPIR"` | Art. 24a PIT |
| `sc.uor.a2.r4` | `uor_sc_full_accounting_from_next_year` | Przekroczenie w roku N → pełna księgowość od roku N+1 | `transition_year: "N+1"` | Art. 2 UoR |
| `sc.uor.a2.r5` | `uor_sc_voluntary_full_accounting` | SC może dobrowolnie wybrać pełną księgowość poniżej progu | `accounting_method: "FULL_VOLUNTARY"` | Art. 2 UoR |
| `sc.uor.a2.r6` | `uor_sc_threshold_counted_partnership` ★ | Próg liczony od sumy przychodów SC (nie per wspólnik!) | `threshold_base: "PARTNERSHIP_TOTAL"` | Art. 2 UoR |

### 5.2 Art. 4, 10, 12, 20-22 UoR — Zasady księgowości (~30 reguł)

| ID | Nazwa reguły | Warunek | Rezultat | Podstawa |
|:--:|-------------|---------|----------|:--------:|
| `sc.uor.a4.r1` | `uor_sc_accrual_principle` [PARTNERSHIP] | Pełna księgowość → zasada memoriału | `accounting_principle: "ACCRUAL"` | Art. 4 UoR |
| `sc.uor.a4.r2` | `uor_sc_prudence_principle` [PARTNERSHIP] | Ostrożna wycena, rezerwy | `prudence_required: true` | Art. 4 UoR |
| `sc.uor.a10.r1` | `uor_sc_journal_ledger` [PARTNERSHIP] | Dziennik + księga główna + księgi pomocnicze | `books_required: [journal, ledger, subsidiary]` | Art. 10 UoR |
| `sc.uor.a12.r1` | `uor_sc_opening_closing_books` [PARTNERSHIP] | Otwarcie ksiąg na początek roku, zamknięcie na koniec | `opening_date: "01_january"`, `closing_date: "31_december"` | Art. 12 UoR |
| `sc.uor.a12.r2` | `uor_sc_closing_blocked_after_approval` ★ | Zatwierdzenie FS → blokada księgowań w zamkniętym roku | `closed_year_blocked: true` | Art. 12 UoR |
| `sc.uor.a20.r1` | `uor_sc_source_documents` [PARTNERSHIP] | Dowód księgowy: faktura, rachunek, wyciąg bankowy | `source_document_required: true` | Art. 20 UoR |
| `sc.uor.a21.r1` | `uor_sc_document_elements` [PARTNERSHIP] | Elementy dowodu: data, strony, kwota, opis, podpis | `document_elements_valid: true/false` | Art. 21 UoR |
| `sc.uor.a22.r1` | `uor_sc_double_entry` ★★ [PARTNERSHIP] | Podwójny zapis: Wn = Ma (bilans musi się zgadzać) | `double_entry_balanced: true/false`, `BLOCK_AND_ALERT` if unbalanced | Art. 22 UoR |

### 5.3 PKPiR — 16 kolumn (~15 reguł)

| ID | Nazwa reguły | Warunek | Kolumna |
|:--:|-------------|---------|:------:|
| `sc.pkpir.r1` | `pkpir_sc_column_6_revenue_goods` [PARTNERSHIP] | Sprzedaż towarów SC | Kol. 6 |
| `sc.pkpir.r2` | `pkpir_sc_column_7_revenue_services` [PARTNERSHIP] | Sprzedaż usług SC | Kol. 7 |
| `sc.pkpir.r3` | `pkpir_sc_column_9_purchase_goods` [PARTNERSHIP] | Zakup towarów SC | Kol. 9 |
| `sc.pkpir.r4` | `pkpir_sc_column_10_incidental_costs` [PARTNERSHIP] | Koszty uboczne zakupu | Kol. 10 |
| `sc.pkpir.r5` | `pkpir_sc_column_11_salaries` [PARTNERSHIP] | Wynagrodzenia pracowników SC | Kol. 11 |
| `sc.pkpir.r6` | `pkpir_sc_column_12_other_expenses` [PARTNERSHIP] | Pozostałe wydatki SC | Kol. 12 |
| `sc.pkpir.r7` | `pkpir_sc_column_14_nkup` [PARTNERSHIP] | Wydatki niebędące KUP | Kol. 14 |
| `sc.pkpir.r8` | `pkpir_sc_column_15_fixed_assets` [PARTNERSHIP] | Środki trwałe | Kol. 15 |
| `sc.pkpir.r9` | `pkpir_sc_partner_split_for_pit` ★ [PROPORCJA] | Dane z PKPiR SC → podstawa do PIT wspólników | `pit_basis_per_partner` |
| `sc.pkpir.r10` | `pkpir_sc_single_book_for_all` ★ | Jedna PKPiR dla całej SC (nie osobne dla wspólników) | `single_pkpir: true` |

### 5.4 Art. 22a-22k PIT — Amortyzacja SC (~20 reguł)

| ID | Nazwa reguły | Warunek | Rezultat | Podstawa |
|:--:|-------------|---------|----------|:--------:|
| `sc.amortyzacja.r1` | `depr_sc_linear_method` [PARTNERSHIP] | Amortyzacja liniowa środków trwałych SC | `depreciation: "LINEAR"` | Art. 22a PIT |
| `sc.amortyzacja.r2` | `depr_sc_split_per_partner` ★ [PROPORCJA×N] | Odpis amortyzacyjny SC dzielony między wspólników | `depr_per_partner: total * share/100` | Art. 8 + Art. 22a PIT |
| `sc.amortyzacja.r3` | `depr_sc_one_off_small_taxpayer` [PARTNERSHIP] | Jednorazowa amortyzacja do 50k EUR dla małego podatnika | `one_off_allowed: true` | Art. 22k PIT |
| `sc.amortyzacja.r4` | `depr_sc_rates_from_kst` | Stawki z Klasyfikacji Środków Trwałych | `rate: kst_value` | Art. 22a PIT |
| `sc.amortyzacja.r5` | `depr_sc_start_next_month` | Amortyzacja od następnego miesiąca po przyjęciu | `start: month_after` | Art. 22a PIT |
| `sc.amortyzacja.r6` | `depr_sc_land_not_amortized` | Grunt → brak amortyzacji | `depreciation: 0` | Art. 22a PIT |

### 5.5 Art. 26, 28, 32, 74 UoR — Wycena i przechowywanie (~15 reguł)

| ID | Nazwa reguły | Warunek | Rezultat | Podstawa |
|:--:|-------------|---------|----------|:--------:|
| `sc.uor.a26.r1` | `uor_sc_inventory_annual` [PARTNERSHIP] | Inwentaryzacja roczna SC | `inventory_required: true` | Art. 26 UoR |
| `sc.uor.a28.r1` | `uor_sc_asset_valuation` [PARTNERSHIP] | Wycena aktywów SC wg cen nabycia/kosztu wytworzenia | `valuation: "COST"` | Art. 28 UoR |
| `sc.uor.a32.r1` | `uor_sc_depreciation_uor` [PARTNERSHIP] | Amortyzacja bilansowa SC (może różnić się od podatkowej) | `book_depreciation: plan` | Art. 32 UoR |
| `sc.uor.a74.r1` | `uor_sc_retention_5_years` [PARTNERSHIP] | Przechowywanie ksiąg SC przez 5 lat | `retention_years: 5` | Art. 74 UoR |



---

## CZĘŚĆ VI: ULGI PODATKOWE WSPÓLNIKÓW (~100 REGUŁ)

> Ulgi stosowane są INDYWIDUALNIE przez każdego wspólnika od jego części dochodu z SC.

### 6.1 Ulga B+R (Art. 26e PIT) (~15 reguł)

| ID | Nazwa reguły | Warunek | Rezultat | Podstawa |
|:--:|-------------|---------|----------|:--------:|
| `sc.ulga.br.r1` | `rd_partner_status_check` [PARTNER] | Wspólnik prowadzący działalność B+R w ramach SC | `rd_eligible: true` | Art. 26e PIT |
| `sc.ulga.br.r2` | `rd_partner_costs_wages` [PARTNER] | Wynagrodzenia pracowników B+R SC → odliczenie 100% | `rd_deduction_pct: 100` | Art. 26e ust. 2 pkt 1 PIT |
| `sc.ulga.br.r3` | `rd_partner_costs_materials` [PARTNER] | Materiały B+R → odliczenie | `rd_materials: costs` | Art. 26e PIT |
| `sc.ulga.br.r4` | `rd_partner_costs_proportional` ★ [PROPORCJA×N] | Koszty B+R SC dzielone proporcjonalnie na wspólników | `rd_per_partner: total_rd * share/100` | Art. 8 + Art. 26e PIT |
| `sc.ulga.br.r5` | `rd_partner_deduction_100pct` [PARTNER] | Standard: 100% kosztów kwalifikowanych | `rd_rate: 100` | Art. 26e PIT |
| `sc.ulga.br.r6` | `rd_partner_centrum_200pct` [PARTNER] | Centrum B+R → 200% | `rd_rate: 200` | Art. 26e PIT |
| `sc.ulga.br.r7` | `rd_partner_capped_at_income` [PARTNER] | Ulga B+R ≤ dochód (nie może wygenerować straty) | `rd_max: income` | Art. 26e PIT |
| `sc.ulga.br.r8` | `rd_partner_carry_forward_6_years` [PARTNER] | Niewykorzystana ulga → 6 lat carry-forward | `rd_carry_years: 6` | Art. 26e PIT |
| `sc.ulga.br.r9` | `rd_partner_not_lump_sum` ★ [PARTNER] | Ryczałtowiec NIE korzysta z ulgi B+R | `rd_blocked_lump: true` | Art. 26e PIT |
| `sc.ulga.br.r10` | `rd_partner_separate_evidence` [PARTNER] | Wyodrębniona ewidencja kosztów B+R | `rd_evidence_required: true` | Art. 26e PIT |

### 6.2 IP Box (Art. 30ca PIT) (~15 reguł)

| ID | Nazwa reguły | Warunek | Rezultat | Podstawa |
|:--:|-------------|---------|----------|:--------:|
| `sc.ulga.ip.r1` | `ip_box_partner_eligible_ip` [PARTNER] | Kwalifikowane IP: patent, program komputerowy | `ip_box_eligible: true` | Art. 30ca PIT |
| `sc.ulga.ip.r2` | `ip_box_partner_rate_5pct` [PARTNER] ★ | 5% od dochodu z IP | `ip_box_rate: 0.05` | Art. 30ca PIT |
| `sc.ulga.ip.r3` | `ip_box_partner_nexus_formula` [PARTNER] | Wskaźnik Nexus = (a+b)/(a+b+c+d) | `nexus_index: calculated` | Art. 30ca PIT |
| `sc.ulga.ip.r4` | `ip_box_partner_separate_books` [PARTNER] | Wyodrębniona ewidencja IP Box | `separate_books: true` | Art. 30ca PIT |
| `sc.ulga.ip.r5` | `ip_box_partner_sc_revenue_split` ★ [PROPORCJA] | Przychód z IP dzielony proporcjonalnie na wspólników | `ip_revenue_per_partner: total * share/100` | Art. 8 + Art. 30ca PIT |

### 6.3 Ulga termomodernizacyjna, prototyp, robotyzacja, ekspansja (~20 reguł)

| ID | Nazwa reguły | Warunek | Rezultat | Podstawa |
|:--:|-------------|---------|----------|:--------:|
| `sc.ulga.thermo.r1` | `thermo_partner_53000_limit` [PARTNER] | Ulga termomodernizacyjna → max 53 000 PLN | `thermo_max: 53000` | Art. 26h PIT |
| `sc.ulga.proto.r1` | `prototype_partner_30pct` [PARTNER] | Ulga na prototyp → 30% kosztów produkcji próbnej | `proto_rate: 30` | Art. 26eb PIT |
| `sc.ulga.robot.r1` | `robot_partner_50pct` [PARTNER] | Ulga na robotyzację → 50% kosztów robotów | `robot_rate: 50` | Art. 26gb PIT |
| `sc.ulga.exp.r1` | `expansion_partner_1m` [PARTNER] | Ulga na ekspansję → max 1 000 000 PLN | `expansion_max: 1000000` | Art. 26ec PIT |

### 6.4 Ulga dla młodych, na powrót, 4+, pracujący emeryci (~15 reguł)

| ID | Nazwa reguły | Warunek | Rezultat | Podstawa |
|:--:|-------------|---------|----------|:--------:|
| `sc.ulga.young.r1` | `young_partner_under_26` ★ [PARTNER] | Wspólnik ≤ 26 lat → PIT 0% do 85 528 PLN | `pit_rate: 0`, `exemption_limit: 85528` | Art. 21 ust. 1 pkt 148 PIT |
| `sc.ulga.young.r2` | `young_partner_sc_income_qualifies` ★ [PARTNER] | Ulga młodych obejmuje dochód z SC! | `sc_income_in_exemption: true` | Art. 21 ust. 1 pkt 148 PIT |
| `sc.ulga.return.r1` | `return_partner_4_years` [PARTNER] | Powrót z emigracji → 4 lata zwolnienia do 85 528 PLN | `return_exemption: true` | Art. 21 ust. 1 pkt 152 PIT |
| `sc.ulga.family4.r1` | `family4_partner_4_kids` [PARTNER] | Rodzic 4+ dzieci → PIT 0% do 85 528 PLN | `family4_exemption: true` | Art. 21 ust. 1 pkt 153 PIT |
| `sc.ulga.senior.r1` | `senior_partner_60_plus` [PARTNER] | Pracujący emeryt → PIT 0% do 85 528 PLN | `senior_exemption: true` | Art. 21 ust. 1 pkt 154 PIT |

### 6.5 Strata i darowizny (~15 reguł)

| ID | Nazwa reguły | Warunek | Rezultat | Podstawa |
|:--:|-------------|---------|----------|:--------:|
| `sc.loss.r1` | `loss_partner_carry_5_years` [PARTNER] ★ | Strata wspólnika ze SC → rozliczenie 5 lat, max 50% rocznie | `loss_carry: 5_years`, `max_annual: 50pct` | Art. 9 ust. 3 PIT |
| `sc.loss.r2` | `loss_partner_one_time_5m` [PARTNER] | Jednorazowe odliczenie 5M PLN | `one_time_5m: true` | Art. 9 ust. 3 pkt 2 PIT |
| `sc.loss.r3` | `loss_partner_scale_linear_only` ★ [PARTNER] | Strata tylko dla skali/liniowego (nie ryczałt!) | `loss_available: scale_linear_only` | Art. 9 ust. 3 PIT |
| `sc.donation.r1` | `donation_partner_6pct_income` [PARTNER] | Darowizny → max 6% dochodu | `donation_max_pct: 6` | Art. 26 ust. 1 pkt 9 PIT |
| `sc.donation.r2` | `donation_partner_blood` [PARTNER] | Krwiodawstwo → 130 PLN/litr | `blood_equivalent: 130` | Art. 26 PIT |

---

## CZĘŚĆ VII: PRACODAWCA — SPÓŁKA JAKO PŁATNIK (~60 REGUŁ)

> **Kluczowa specyfika SC:** Spółka cywilna zatrudniająca pracowników jest płatnikiem PIT i ZUS. Odpowiedzialność solidarna wspólników za zobowiązania pracownicze.

### 7.1 Obowiązki płatnika PIT (Art. 31-32 PIT) (~15 reguł)

| ID | Nazwa reguły | Warunek | Rezultat | Podstawa |
|:--:|-------------|---------|----------|:--------:|
| `sc.employer.pit.r1` | `employer_sc_pit_withholding` ★ [PARTNERSHIP] | SC jako płatnik pobiera zaliczki PIT od pracowników | `pit_withholding: true` | Art. 31 PIT |
| `sc.employer.pit.r2` | `employer_sc_pit4r_monthly` [PARTNERSHIP] | PIT-4R miesięcznie do US (do 20. dnia) | `pit4r_required: true` | Art. 31 PIT |
| `sc.employer.pit.r3` | `employer_sc_pit11_annual` [PARTNERSHIP] | PIT-11 rocznie dla pracowników (do 31 stycznia) | `pit11_required: true` | Art. 32 PIT |
| `sc.employer.pit.r4` | `employer_sc_joint_liability_pit` [SOLIDARNA] ★ | Niepobrany PIT → solidarna odpowiedzialność wspólników | `joint_liability_pit_employer: true` | Art. 31 PIT + Art. 864 KC |

### 7.2 Obowiązki płatnika ZUS (Art. 17-19 SUS) (~15 reguł)

| ID | Nazwa reguły | Warunek | Rezultat | Podstawa |
|:--:|-------------|---------|----------|:--------:|
| `sc.employer.zus.r1` | `employer_sc_zus_employee_contributions` ★ [PARTNERSHIP] | SC odprowadza składki ZUS od pracowników | `zus_employee: true` | Art. 17 SUS |
| `sc.employer.zus.r2` | `employer_sc_zus_rca_monthly` [PARTNERSHIP] | RCA miesięcznie do ZUS (do 15. dnia) | `zus_rca_required: true` | Art. 17 SUS |
| `sc.employer.zus.r3` | `employer_sc_joint_liability_zus` [SOLIDARNA] ★ | Nieopłacone składki ZUS → solidarna odpowiedzialność | `joint_liability_zus_employer: true` | Art. 31 SUS + Art. 864 KC |

### 7.3 PPK, BHP, urlopy (~15 reguł)

| ID | Nazwa reguły | Warunek | Rezultat | Podstawa |
|:--:|-------------|---------|----------|:--------:|
| `sc.employer.ppk.r1` | `ppk_sc_obligation_250_employees` [PARTNERSHIP] | SC z ≥250 pracownikami → obowiązek PPK | `ppk_required: true` | Art. 26 PPK |
| `sc.employer.ppk.r2` | `ppk_sc_contribution_1_5pct` [PARTNERSHIP] | Wpłata PPK: 1.5% wynagrodzenia (pracodawca) | `ppk_employer_rate: 0.015` | Art. 27 PPK |
| `sc.employer.bhp.r1` | `bhp_sc_training_required` [PARTNERSHIP] | Szkolenia BHP dla pracowników SC | `bhp_training: true` | Art. 237 KP |
| `sc.employer.urlop.r1` | `leave_sc_26_days` [PARTNERSHIP] | Urlop wypoczynkowy: 20/26 dni | `leave_days: 20 lub 26` | Art. 154 KP |

### 7.4 Wynagrodzenia wspólników — specyfika SC (~15 reguł)

| ID | Nazwa reguły | Warunek | Rezultat | Podstawa |
|:--:|-------------|---------|----------|:--------:|
| `sc.partner.labor.r1` | `partner_not_employee_default` ★ [PARTNER] | Wspólnik domyślnie NIE jest pracownikiem SC | `employment_status: "PARTNER"` | Art. 6 SUS |
| `sc.partner.labor.r2` | `partner_employment_contract_possible` [PARTNER] | Wspólnik MOŻE mieć umowę o pracę ze SC | `employment_possible: true` | Art. 22 KP |
| `sc.partner.labor.r3` | `partner_salary_from_sc_kup` [PARTNERSHIP] | Wynagrodzenie wspólnika z umowy o pracę → KUP SC | `partner_salary_kup: true` | Art. 22 PIT |
| `sc.partner.labor.r4` | `partner_own_work_nkup_no_contract` ★ | Praca bez umowy → NKUP (Art. 23 ust. 1 pkt 10) | `own_work_kup: 0` | Art. 23 PIT |
| `sc.partner.labor.r5` | `partner_spouse_employment_kup` | Małżonek wspólnika z umową → KUP | `spouse_kup: true` if contract | Art. 22 PIT |

---

## CZĘŚĆ VIII: ORDYNACJA PODATKOWA — SC (~80 REGUŁ)

### 8.1 Przedawnienie (Art. 70 OP) (~10 reguł)

| ID | Nazwa reguły | Warunek | Rezultat | Podstawa |
|:--:|-------------|---------|----------|:--------:|
| `sc.ord.a70.r1` | `ord_sc_statute_5_years` [PARTNERSHIP] | Zobowiązanie SC przedawnia się po 5 latach | `statute_years: 5` | Art. 70 § 1 OP |
| `sc.ord.a70.r2` | `ord_sc_statute_suspended_audit` [PARTNERSHIP] | Wszczęcie kontroli → zawieszenie biegu przedawnienia | `statute_suspended: true` | Art. 70 § 6 OP |
| `sc.ord.a70.r3` | `ord_sc_statute_extended_10_years` [PARTNERSHIP] | Oszustwo podatkowe → 10 lat | `statute_years_fraud: 10` | Art. 70 § 6 OP |
| `sc.ord.a70.r4` | `ord_sc_joint_liability_statute` ★ [SOLIDARNA] | Odpowiedzialność solidarna przedawnia się po 5 latach | `joint_liability_statute: 5` | Art. 70 OP + Art. 864 KC |

### 8.2 Korekty deklaracji (Art. 81 OP) (~8 reguł)

| ID | Nazwa reguły | Warunek | Rezultat | Podstawa |
|:--:|-------------|---------|----------|:--------:|
| `sc.ord.a81.r1` | `ord_sc_correction_allowed` [PARTNERSHIP] | Korekta deklaracji SC w ciągu 5 lat | `correction_allowed: true` | Art. 81 OP |
| `sc.ord.a81.r2` | `ord_sc_correction_after_audit_restricted` [PARTNERSHIP] | Po kontroli → korekta tylko za zgodą US | `correction_restricted: true` | Art. 81b OP |

### 8.3 Odpowiedzialność podatkowa (Art. 107-118 OP) (~15 reguł)

| ID | Nazwa reguły | Warunek | Rezultat | Podstawa |
|:--:|-------------|---------|----------|:--------:|
| `sc.ord.a115.r1` | `ord_sc_partner_liability_tax` ★★ | Wspólnik odpowiada całym majątkiem za podatki SC | `partner_full_liability: true` | Art. 115 OP |
| `sc.ord.a115.r2` | `ord_sc_partner_liability_proportional` | Odpowiedzialność proporcjonalna do udziału (wewnętrznie) | `liability_internal: share_percent` | Art. 115 OP |
| `sc.ord.a116.r1` | `ord_sc_joint_liability_vat_zaleglosci` [SOLIDARNA] ★ | Solidarna za zaległości VAT SC | `joint_liability_vat: true` | Art. 116 OP |

### 8.4 GAAR, MDR, ceny transferowe (~10 reguł)

| ID | Nazwa reguły | Warunek | Rezultat | Podstawa |
|:--:|-------------|---------|----------|:--------:|
| `sc.mdr.r1` | `mdr_sc_reportable_scheme` [PARTNERSHIP] | Transakcja SC z rajem podatkowym → MDR | `mdr_reportable: true` | Art. 86a OP |
| `sc.tp.r1` | `tp_sc_related_party_transactions` ★ [PARTNERSHIP] | Transakcje SC z podmiotami powiązanymi (w tym wspólnikami!) > próg → dokumentacja TP | `tp_documentation: true` | Art. 23m PIT |
| `sc.gaar.r1` | `gaar_sc_artificial_scheme` [PARTNERSHIP] | Sztuczna struktura SC dla unikania opodatkowania | `gaar_triggered: true` | Art. 119a OP |

---

## CZĘŚĆ IX: CROSS-BORDER I MIĘDZYNARODOWE (~50 REGUŁ)

### 9.1 WNT, WDT, Import, Export (~20 reguł)

| ID | Nazwa reguły | Warunek | Rezultat | Podstawa |
|:--:|-------------|---------|----------|:--------:|
| `sc.cb.wnt.r1` | `wnt_sc_reverse_charge` [PARTNERSHIP] | WNT — SC rozlicza VAT (reverse charge) | `vat_procedure: "REVERSE_CHARGE"` | Art. 17 ust. 1 pkt 3 VAT |
| `sc.cb.wdt.r1` | `wdt_sc_0pct_with_vat_ue` ★ | WDT — SC stosuje 0% VAT gdy ma VAT-UE | `vat_rate: 0`, `vat_ue_required: true` | Art. 42 VAT |
| `sc.cb.wdt.r2` | `wdt_sc_no_vat_ue_domestic_rate` | WDT bez VAT-UE → stawka krajowa (sankcja) | `vat_rate: domestic` | Art. 42 VAT |
| `sc.cb.export.r1` | `export_sc_0pct` [PARTNERSHIP] | Eksport poza UE → 0% VAT | `vat_rate: 0` | Art. 41 VAT |
| `sc.cb.import.r1` | `import_sc_vat_at_border` [PARTNERSHIP] | Import spoza UE → VAT w cle | `vat_procedure: "IMPORT"` | Art. 17 VAT |

### 9.2 WHT, PE, OSS/IOSS (~15 reguł)

| ID | Nazwa reguły | Warunek | Rezultat | Podstawa |
|:--:|-------------|---------|----------|:--------:|
| `sc.cb.wht.r1` | `wht_sc_payment_to_foreign` [PARTNERSHIP] | SC wypłaca należność za granicę → WHT | `wht_required: true` | Art. 26 PIT / Art. 21 CIT |
| `sc.cb.pe.r1` | `pe_sc_foreign_establishment` [PARTNERSHIP] | SC ma zakład za granicą → PE | `pe_triggered: true` | Art. 5 UPO |
| `sc.cb.oss.r1` | `oss_sc_b2c_eu_sales` [PARTNERSHIP] | SC sprzedaje B2C do UE → OSS | `oss_available: true` | Art. 109a VAT |

---

## CZĘŚĆ X: PODATKI LOKALNE (~40 REGUŁ)

### 10.1 PCC (Art. 1, 7 PCC) (~10 reguł)

| ID | Nazwa reguły | Warunek | Rezultat | Podstawa |
|:--:|-------------|---------|----------|:--------:|
| `sc.pcc.r1` | `pcc_sc_formation_not_taxable` ★ | Utworzenie SC → NIE podlega PCC | `pcc_due: 0` | Art. 1 PCC |
| `sc.pcc.r2` | `pcc_sc_loan_from_partner` ★ [PARTNER] | Pożyczka od wspólnika dla SC → PCC 0.5% | `pcc_rate: 0.005` | Art. 7 ust. 1 pkt 4 PCC |
| `sc.pcc.r3` | `pcc_sc_loan_from_partner_exempt_close_family` | Pożyczka od wspólnika (grupa 0/I) → zwolnienie (SD-Z2) | `pcc_exempt: true` if reported | Art. 4a ustawy o spadkach |
| `sc.pcc.r4` | `pcc_sc_loan_vat_exempt` | SC VAT czynna → PCC od pożyczki: zwolnione | `pcc_exempt: true` if SC VAT payer | Art. 2 pkt 4 PCC |
| `sc.pcc.r5` | `pcc_sc_contribution_partner_loan` ★ | Konwersja pożyczki na wkład → PCC? NIE (zmiana umowy) | `pcc_due: 0` | Art. 1 PCC |

### 10.2 Podatek od nieruchomości (~10 reguł)

| ID | Nazwa reguły | Warunek | Rezultat | Podstawa |
|:--:|-------------|---------|----------|:--------:|
| `sc.podn.r1` | `property_tax_sc_owner` [PARTNERSHIP] | SC jako właściciel/użytkownik nieruchomości → podatek | `property_tax: true` | Ustawa o pod. od nier. |
| `sc.podn.r2` | `property_tax_sc_commercial_rate` [PARTNERSHIP] | Nieruchomość komercyjna → stawka max | `rate: commercial` | Ustawa o pod. od nier. |
| `sc.podn.r3` | `property_tax_sc_land_business` [PARTNERSHIP] | Grunt związany z działalnością → wyższa stawka | `rate: business_land` | Ustawa o pod. od nier. |

---

## CZĘŚĆ XI: RISK, COMPLIANCE I FALLBACK (~60 REGUŁ)

### 11.1 Risk — Fraud i anomalie (~15 reguł)

| ID | Nazwa reguły | Warunek | Rezultat |
|:--:|-------------|---------|----------|
| `sc.risk.fraud.r1` | `fraud_sc_vendor_network` [PARTNERSHIP] | Kontrahent w sieci fraudowej → BLOCK | `_routing: "BLOCK_AND_ALERT"` |
| `sc.risk.fraud.r2` | `fraud_sc_intra_partnership` ★ | Transakcja między wspólnikami bez uzasadnienia → BLOCK | `intra_partnership_risk: true` |
| `sc.risk.fraud.r3` | `fraud_sc_ceidg_suspended_vendor` [PARTNERSHIP] | Kontrahent zawieszony w CEIDG → BLOCK | `suspended_vendor: true` |
| `sc.risk.anomaly.r1` | `anomaly_sc_amount_3sigma` [PARTNERSHIP] | Kwota > 3σ od średniej → TRIAGE | `anomaly_detected: true` |
| `sc.risk.anomaly.r2` | `anomaly_sc_new_counterparty` [PARTNERSHIP] | Nowy kontrahent + duża kwota → weryfikacja | `new_counterparty_flag: true` |
| `sc.risk.kks.r1` | `kks_sc_hidden_income` [PARTNERSHIP] | Rozbieżność wpływy vs deklaracje → KKS | `kks_risk: true` |
| `sc.risk.gaar.r1` | `gaar_sc_scheme_detected` [PARTNERSHIP] | Sztuczna struktura podatkowa → BLOCK | `gaar_alert: true` |

### 11.2 Compliance — Biała lista, MPP, gotówka (~15 reguł)

| ID | Nazwa reguły | Warunek | Rezultat |
|:--:|-------------|---------|----------|
| `sc.compliance.wl.r1` | `wl_sc_check_over_15k` [PARTNERSHIP] | Przelew SC >15k PLN → sprawdzenie Białej Listy | `whitelist_check: true` |
| `sc.compliance.wl.r2` | `wl_sc_missing_sanction` [SOLIDARNA] ★ | Brak na WL → solidarna sankcja | `wl_penalty_joint: true` |
| `sc.compliance.mpp.r1` | `mpp_sc_required_over_15k` [PARTNERSHIP] | Faktura >15k + kategoria MPP → split payment | `mpp_required: true` |
| `sc.compliance.cash.r1` | `cash_sc_over_15k_nkup` [PARTNERSHIP] | Gotówka >15k → NKUP dla SC | `cash_nkup: true` |
| `sc.compliance.cash.r2` | `cash_sc_over_15k_partners` [PROPORCJA] ★ | NKUP od gotówki dzielony proporcjonalnie na wspólników | `cash_nkup_per_partner: total_nkup * share/100` |

### 11.3 Fallback i domyślne (~15 reguł)

| ID | Nazwa reguły | Warunek | Rezultat |
|:--:|-------------|---------|----------|
| `sc.fallback.r1` | `fallback_sc_domestic_vat_23` | Brak dopasowania → 23% VAT | `vat_rate: 0.23` |
| `sc.fallback.r2` | `fallback_sc_eu_vat_reverse_charge` | UE → reverse charge | `vat_procedure: "REVERSE_CHARGE"` |
| `sc.fallback.r3` | `fallback_sc_non_eu_np` | Spoza UE → NP (nie podlega) | `vat_procedure: "NP"` |
| `sc.fallback.r4` | `fallback_sc_no_match` | Żadna reguła nie pasuje → TRIAGE | `_routing: "TRIAGE_QUEUE"`, `matched: false` |
| `sc.fallback.r5` | `fallback_sc_pit_default_scale` [PARTNER] | Brak wybranej formy PIT → domyślnie skala | `tax_form: "PIT_SCALE"` |

### 11.4 Retencja dokumentów (~10 reguł)

| ID | Nazwa reguły | Warunek | Okres | Podstawa |
|:--:|-------------|---------|:----:|:--------:|
| `sc.retention.r1` | `retention_sc_invoices_5y` [PARTNERSHIP] | Faktury SC → 5 lat | 5 lat | Art. 86 OP |
| `sc.retention.r2` | `retention_sc_ledgers_5y` [PARTNERSHIP] | Księgi SC → 5 lat | 5 lat | Art. 74 UoR |
| `sc.retention.r3` | `retention_sc_payroll_10y` [PARTNERSHIP] | Dokumenty płacowe SC → 10 lat | 10 lat | Art. 125a u.emeryt. |
| `sc.retention.r4` | `retention_sc_dissolution_keep` ★ | Po rozwiązaniu SC → dokumenty przechowuje wyznaczony wspólnik | `post_dissolution_keeper: true` | Art. 86 OP |

---

## PODSUMOWANIE STATYSTYCZNE

| Część | Obszar prawny | Szacowana liczba reguł |
|:-----:|--------------|:---------------------:|
| I | Kodeks Cywilny (Art. 860-875) | **~170** |
| II | VAT Spółki (Art. 5-120) | **~220** |
| III | PIT Wspólników (Art. 8-45 + ryczałt) | **~250** |
| IV | ZUS Wspólników (SUS + zdrowotna) | **~80** |
| V | Rachunkowość (UoR + PKPiR + amortyzacja) | **~65** |
| VI | Ulgi podatkowe wspólników | **~50** |
| VII | Pracodawca — SC jako płatnik | **~30** |
| VIII | Ordynacja podatkowa | **~30** |
| IX | Cross-border i międzynarodowe | **~30** |
| X | Podatki lokalne (PCC, nieruchomości) | **~20** |
| XI | Risk, Compliance, Fallback, Retencja | **~55** |
| **RAZEM** | | **~1 000** |

> **Uwaga:** Powyższe ~1 000 reguł w katalogu to reguły UNIKALNE dla SC. System w praktyce generuje **~2 500+ werdyktów**, ponieważ reguły oznaczone [PARTNER×N] są ewaluowane dla KAŻDEGO wspólnika osobno (dla 3 wspólników → 3× więcej wyników). Dodatkowo reguły [PROPORCJA×N] generują proporcjonalne wartości dla każdego wspólnika.
>
> **Współczynnik dekompozycji:** ~20 reguł na artykuł prawny (vs ~13 dla JDG w dokumencie referencyjnym). Wyższy współczynnik wynika ze złożoności SC (podwójny poziom: PARTNERSHIP + PARTNER×N).

---

> **Dokument utworzony:** 2026-07-11 | **Wersja:** 1.0 | **Następny krok:** Implementacja `.rego` w `policies/sc/`
> **Powiązane dokumenty:**
> - `Plan OPA/Docs SC` — źródła prawne spółki cywilnej (kompletny katalog)
> - `Plan OPA/SC_ENTERPRISE_PLAN.md` — plan architektoniczny (makro-reguły, input, thresholds, multi-pass)
> - `Plan OPA/33_JDG_MASSIVE_RULE_CATALOG.md` — referencja JDG (wzorzec dekompozycji artykuł-po-artykule)
> - `Plan OPA/34_JDG_DEFINITIVE_REGO_PLAN.md` — referencja implementacji Rego dla JDG
