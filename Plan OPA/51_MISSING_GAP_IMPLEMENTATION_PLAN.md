# 🏗️ NexusAI JDG — Plan Implementacji Pozostałych Braków
> **Data:** 2026-07-12 | **Status:** W TRAKCIE | **Plik:** Plan OPA/51_MISSING_GAP_IMPLEMENTATION_PLAN.md

---

## 0. STATUS WDROŻENIA — CO JUŻ ZREALIZOWANO

| Domena | Pliki | Reguły | Status |
|--------|-------|--------|--------|
| **KKS** | kks.rego | 43→107 | ✅ Rozbudowany (P200-P496) |
| **Accounting** | accounting.rego | 56 | ✅ PKPiR, KŚT, UoR, NBP FX, Remanent |
| **VAT Engine** | substantive.rego + deductions.rego | 41+25=66 | ✅ JPK_V7M, MPP, GTU, WNT, Reverse Charge |
| **Conflicts** | conflicts.rego + semantic_conflict_resolver.py | 28+17 | ✅ IP Box/B+R, Repr/Mkt, Auto VAT/KUP, Bad Debt |
| **MPiPS** | mpips.rego | 5 | ✅ FP, FGŚP, PFRON, ZFŚS |
| **RODO** | rodo.rego | 5 | ✅ Rejestr, retencja, breach, pracownicze |
| **ZUS Benefits** | zus.rego | +7 (P1200zs-P1206zs) | ✅ Chorobowy, macierzyński, opiekuńczy, etc. |
| **PCC Expanded** | local_taxes.rego | +4 (P1301-P1304) | ✅ Pożyczki, udziały, sprzedaż, zwolnienia |
| **P914/R0582** | business.rego | ✅ POPRAWIONE | Składka zdrowotna NADAL w zawieszeniu |
| **RAZEM** | | ~273 reguły | ~35% planu kanonicznego (779) |

---

## 1. POZOSTAŁE BRAKI KRYTYCZNE (P0)

### 1.1 VAT — Faktura uproszczona (paragon ≤450 PLN, Art. 106e ust. 5 pkt 3 VAT)
- **ID OPA:** `jdg.vat.substantive.receipt_invoice_450`
- **Brzmienie:** Dokument z NIP nabywcy o wartości ≤450 zł brutto (lub 100 EUR) stanowi fakturę uproszczoną
- **Priorytet:** 🔴 KRYTYCZNY — codzienny błąd JDG (paragon bez NIP = brak odliczenia)
- **Plik:** `policies/jdg/vat/substantive.rego`

### 1.2 Walidacja NIP/REGON + ciągłość faktur (R0613-R0622)
- R0613: NIP checksum (10 cyfr, suma kontrolna modulo 11)
- R0614: REGON checksum (9 lub 14 cyfr)
- R0615: Ciągłość numeracji faktur (brak luk)
- R0616: Data faktury ≤ data bieżąca
- R0617: Data sprzedaży ≤ data faktury + 30 dni
- R0618: Kwota netto + VAT = brutto
- R0619: NIP nabywcy ≠ NIP sprzedawcy
- R0620: KSeF UPO wymagane
- **Plik:** NOWY `policies/jdg/validation.rego`

---

## 2. POZOSTAŁE BRAKI WAŻNE (P1)

### 2.1 KKS — Sekcje P280-P339, P440-P459 (~100 reguł)
- P280-P299: Utrudnianie kontroli skarbowej (Art. 83 KKS) — 20 reguł
- P320-P339: Niszczenie dokumentów podatkowych — 20 reguł
- P440-P459: Rozszerzone sankcje + postępowanie mandatowe — 20 reguł
- **Plik:** `policies/jdg/kks.rego`

### 2.2 VAT Edge Cases z Doc 28a (R0546-R0559)
- R0546: Przekroczenie limitu 200k PLN — proporcja
- R0547: Proporcjonalny limit dla NOWYCH JDG
- R0548-R0559: Środki trwałe, VAT-UE korygowany

### 2.3 Doc 28a — Enterprise Accounting (R0372-R0399)
- R0372-R0378: Walidacja PKPiR kolumna po kolumnie (częściowo w accounting.rego)
- R0379-R0388: 10 enterprise amortyzacji szczegółowej
- R0392-R0399: Ewidencja przebiegu

### 2.4 VAT zwolnienie podmiotowe 200k — pełne (V.49-V.53)
- Art. 113 ust. 1: Zwolnienie do 200 000 PLN
- Art. 113 ust. 5: Limit proporcjonalny dla nowych firm
- Art. 113 ust. 13: Wyłączenia (prawnicy, jubilerzy, etc.)

---

## 3. HARMONOGRAM WDROŻENIA

| Sprint | Zakres | Reguł | Status |
|--------|--------|-------|--------|
| **Sprint 1 (teraz)** | VAT receipt ≤450, Validation.rego, KKS uzupełnienie | ~15 | 🔴 W TRAKCIE |
| **Sprint 2** | KKS P280-P339, P440-P459 | ~60 | ⬜ Planowany |
| **Sprint 3** | VAT edge cases + zwolnienie podmiotowe | ~25 | ⬜ Planowany |
| **Sprint 4** | Enterprise accounting + Doc 28a full | ~40 | ⬜ Planowany |

---

## 4. METRYKI DOCELOWE

| Metryka | Obecnie | Docelowo |
|---------|---------|----------|
| Reguły Rego | ~273 | ~400 |
| Pokrycie planu kanonicznego | ~35% | ~51% |
| Pakiety Rego | 29 | 30 (+validation) |
| Testy Python | 38/38 | 38/38 |
| BLOCK_AND_ALERT | ~62 | ~90 |
| TRIAGE_QUEUE | ~29 | ~50 |
