# 🏗️ NexusAI JDG — Plan Implementacji Pozostałych Braków
> **Data:** 2026-07-12 (v3.0 — FINALNY) | **Status:** ✅ ZAKTUALIZOWANY | **Plik:** Plan OPA/51_MISSING_GAP_IMPLEMENTATION_PLAN.md

---

## 0. STATUS WDROŻENIA — CO JUŻ ZREALIZOWANO

| Domena | Pliki | Reguł | Status |
|--------|-------|--------|--------|
| **KKS** | kks.rego | **152** | ✅ Rozbudowany (P200-P499, włącznie z P497-P499: kara łączna, raty, egzekucja) |
| **Accounting** | accounting.rego | 56 | ✅ PKPiR, KŚT, UoR, NBP FX, Remanent |
| **VAT Engine** | substantive.rego + deductions.rego | 41+24=65 | ✅ JPK_V7M, MPP, GTU, WNT, Reverse Charge |
| **Edge Cases** | edge_cases.rego | **90** | ✅ VAT/PIT/ZUS edge cases + Grupa F limitów (R0546-R0645) |
| **Conflicts** | conflicts.rego + semantic_conflict_resolver.py | 27+17 | ✅ IP Box/B+R, Repr/Mkt, Auto VAT/KUP, Bad Debt |
| **MPiPS** | mpips.rego | 4 | ✅ FP, FGŚP, PFRON, ZFŚS |
| **RODO** | rodo.rego | 4 | ✅ Rejestr, retencja, breach, pracownicze |
| **ZUS Benefits** | zus.rego | 15 | ✅ Chorobowy, macierzyński, opiekuńczy, ulgi, standard |
| **PCC Expanded** | local_taxes.rego | 4 | ✅ Pożyczki, udziały, sprzedaż, zwolnienia |
| **Validation** | validation.rego | 8 | ✅ NIP checksum, REGON, ciągłość faktur (R0613-R0622) |
| **VAT receipt ≤450** | vat/substantive.rego | **P140** ✅ | Art. 106e ust. 5 pkt 3 — faktura uproszczona |
| **P914→R0582** | business.rego | ✅ POPRAWIONE | Składka zdrowotna NADAL w zawieszeniu |
| **Phase 5 Python** | 9 modułów | ✅ **100%** | wasm_gc, nbp_client, aml_compliance, rot_guard, r0582_migration, ip_box_heuristic, proxy_router, bundle_manager, immutable_audit |
| **Phase 5 Rego** | main_jdg.rego, zus.rego | ✅ **100%** | safe_merge, immutable_verdict, R0582 |
| **RAZEM** | | **~435 reguł** | **~56% planu kanonicznego (~779)** |

> **Porównanie z poprzednią wersją:** KKS ze 107 → **152** (+45 reguł). Edge Cases z 37 → **90** (+53 reguły). VAT receipt ≤450 z "do zrobienia" → **P140 JUŻ ISTNIEJE**. Phase 5 z 79% → **100%**. Dodano P497-P499 (kara łączna, raty, egzekucja KKS) oraz Grupę F — 23 reguły limitów (R0623-R0645).

---

## 1. POZOSTAŁE BRAKI KRYTYCZNE (P0)

### 1.1 KKS — Sekcje P440-P459 (~78 reguł)

KKS ma już 152 reguły z planowanych 230. Pozostałe ~78 reguł to głównie:
- **P440-P449:** Środki zabezpieczające (Art. 22 § 2 pkt 4 KKS) — 10 reguł
- **P450-P459:** Odpowiedzialność posiłkowa + postępowanie mandatowe (Art. 24, 47-52 KKS) — 10 reguł
- **Dodatkowe sankcje szczegółowe:** ~58 reguł z pełnej dekompozycji Art. 54-83 KKS

**Priorytet:** 🔴 KRYTYCZNY — KKS to fundament odpowiedzialności karnej skarbowej JDG
**Plik:** `policies/jdg/kks.rego`
**Dokument referencyjny:** `Plan OPA/43_JDG_KKS_MASSIVE_DECOMPOSITION.md`

### 1.2 Edge Cases — Doc 28a (~110 edge cases)

Mamy 90 edge cases z planowanych ~200. Pozostałe ~110 obejmują:
- VAT: proporcja limitu 200k, VAT-UE korygowany, odwrotne obciążenie niuanse
- PIT: ulgi graniczne, przejścia między formami
- ZUS: zbieg tytułów, podwójne ubezpieczenia
- PKPiR: ewidencja przebiegu pojazdu, remanent szczegółowy

**Priorytet:** 🔴 KRYTYCZNY — edge cases to najczęstsze błędy JDG
**Plik:** `policies/jdg/edge_cases.rego`
**Dokument referencyjny:** `Plan OPA/28a_JDG_EDGE_CASES_FULL.md`

---

## 2. POZOSTAŁE BRAKI WAŻNE (P1)

### 2.1 Migracja accounting.rego na matched:true

`accounting.rego` ma 1340 linii i 56 reguł, ale używa `matched: false` jako default pass-through. Należy zmigrować na `matched: true` z pełnymi werdyktami:
- 56 reguł PKPiR (kolumna po kolumnie)
- 5 reguł KŚT (amortyzacja szczegółowa)
- 5 reguł UoR (inwentaryzacja, wycena)

### 2.2 VAT zwolnienie podmiotowe 200k — rozszerzenie (V.50-V.53)
- Art. 113 ust. 5: Limit proporcjonalny dla nowych firm (pro-rata w roku rozpoczęcia)
- Art. 113 ust. 13: Wyłączenia (prawnicy, jubilerzy, doradcy podatkowi — NIE mogą korzystać)
- Art. 113 ust. 2: Utrata prawa po przekroczeniu
- Art. 113 ust. 11: Ponowne nabycie prawa po 12 miesiącach

### 2.3 Doc 28a — Enterprise Accounting (R0372-R0399)
- R0372-R0378: Walidacja PKPiR kolumna po kolumnie (częściowo w accounting.rego)
- R0379-R0388: 10 enterprise amortyzacji szczegółowej
- R0392-R0399: Ewidencja przebiegu pojazdu

---

## 3. HARMONOGRAM WDROŻENIA (ZAKTUALIZOWANY)

| Sprint | Zakres | Reguł | Status |
|--------|--------|-------|--------|
| **Sprint 1 (ZREALIZOWANY)** | KKS 107→152, Edge Cases 37→90, VAT P140, Validation (8), Phase 5 (14/14), P497-P499, Grupa F | +96 | ✅ **GOTOWE** |
| **Sprint 2** | KKS sankcje szczegółowe Art. 54-83 | ~78 | ⬜ Planowany |
| **Sprint 3** | Edge cases Doc 28a + VAT zwolnienie 200k rozszerzenie | ~122 | ⬜ Planowany |
| **Sprint 4** | Migracja accounting.rego → matched:true + Enterprise accounting | ~70 | ⬜ Planowany |

---

## 4. METRYKI DOCELOWE

| Metryka | Obecnie | Po Sprincie 2 | Po Sprincie 4 |
|---------|---------|---------------|---------------|
| Reguły Rego | **435** | ~513 | ~705 |
| Pokrycie planu kanonicznego (~779) | **56%** | ~66% | **~90%** |
| Pakiety Rego z regułami | **38** | 38 | 38 |
| BLOCK_AND_ALERT | **187** | ~240 | ~320 |
| TRIAGE_QUEUE | **114** | ~145 | ~210 |

---

## 5. CO JUŻ NIE JEST BRAKIEM (USUNIĘTE Z POPRZEDNIEJ WERSJI)

| Brak z poprzedniej wersji | Dlaczego usunięty |
|---------------------------|-------------------|
| ❌ VAT receipt ≤450 (P140) | ✅ **JUŻ ISTNIEJE** w `vat/substantive.rego` (linia 899+) |
| ❌ Validation.rego (R0613-R0622) | ✅ **JUŻ ISTNIEJE** — 8 reguł w `validation.rego` |
| ❌ KKS P280-P339 (utrudnianie kontroli) | ✅ **JUŻ ISTNIEJE** w `kks.rego` — pokryte w rozbudowie do 152 |
| ❌ Phase 5 Python: ip_box_heuristic | ✅ **JUŻ ISTNIEJE** — `nexus_ai/tax/ip_box_heuristic_guard.py` (181 linii) |
| ❌ Phase 5 Python: proxy_router | ✅ **JUŻ ISTNIEJE** — `nexus_ai/services/infrastructure/proxy_router.py` (251 linii) |
| ❌ Phase 5 Python: bundle_manager | ✅ **JUŻ ISTNIEJE** — `nexus_ai/services/infrastructure/bundle_manager.py` (326 linii) |

---

*Wygenerowano przez NexusAI Implementation Plan Engine v3.0*
*Data: 2026-07-12 | Poprzednia wersja: 2026-07-12 (v2.0)*
