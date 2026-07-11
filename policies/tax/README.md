# 🏛️ NexusAI SC — Policy-as-Code (OPA/Rego) — Spółka Cywilna

> **Status:** ENTERPRISE READY — 28 plików Rego, 31 reguł decyzyjnych, 15 testów  
> **Wersja:** 2026.07.11  
> **Plany referencyjne:** `Plan OPA/SC_DEFINITIVE_REGO_PLAN.md` (~550 reguł), `Plan OPA/37_SPOLKA_CYWILNA_ULTIMATE_GRANULARITY.md` (~435 reguł)  
> **Analiza strategiczna:** `Plan OPA/38_SPOLKA_CYWILNA_STRATEGIC_IMPROVEMENTS.md`  
> **Pliki Rego:** 28 | **Reguły decyzyjne:** 31 | **Testy:** 15

---

## 📁 Struktura pakietów SC

```
policies/tax/
├── README.md                          — Ten plik
├── main_sc.rego               149 L   — Orchestrator Multi-Pass SC (22 pakiety)
├── _helpers_sc.rego           230 L   — SC-specific helpery (partners[], Art. 8 PIT)
├── _helpers.rego              234 L   — Wspólne helpery tax
├── _metadata.rego             230+ L  — Metadane 23+ reguł SC
│
│  ╔══════════════════════════════════════════════════════════════╗
│  ║  💚 STRATEGICZNE ULEPSZENIA (9/9 wdrożone)                 ║
│  ╚══════════════════════════════════════════════════════════════╝
│
├── temporal.rego              192 L   — ScTemporalSandbox — temporalne thresholds
├── anomaly.rego               167 L   — ScAnomalyGuard — 5 reguł detekcji anomalii
├── what_if.rego               113 L   — ScWhatIf Engine — tryb symulacyjny
├── partner_mirror.rego        179 L   — ScPartnerMirror — RODO/solidarność split
│
│  ╔══════════════════════════════════════════════════════════════╗
│  ║  💚 MECHANIZMY INTEGRACYJNE SC (8/8 wdrożone)              ║
│  ╚══════════════════════════════════════════════════════════════╝
│
├── sc_fallback.rego           199 L   — SC-specific fallback (6 stanów życia)
├── sc_partnership.rego        165 L   — Cykl życia SC (7 reguł)
├── sc_liability.rego          157 L   — Odpowiedzialność solidarna (5 reguł)
├── sc_ksef_jpk.rego           160 L   — KSeF, JPK_V7, Biała Lista (6 reguł)
│
│  ╔══════════════════════════════════════════════════════════════╗
│  ║  🟡 ISTNIEJĄCE PAKIETY TAX (rozszerzone o SC)              ║
│  ╚══════════════════════════════════════════════════════════════╝
│
├── risk.rego                  100+ L  — Fraud, anomalie, GAAR
├── routing.rego               100+ L  — Field confidence
├── compliance.rego            100+ L  — Biała Lista, MPP, kasy
├── crossborder.rego           100+ L  — WNT, WDT, eksport
├── fallback.rego               80 L   — Domyślny fallback 23% VAT
├── allowances.rego            450+ L  — Ulgi podatkowe
├── zus.rego                   250+ L  — Składki, ulgi ZUS
├── accounting.rego            200+ L  — PKPiR, amortyzacja
├── uor_books.rego             200+ L  — Pełna księgowość
├── uor_valuation.rego          90 L   — Wycena bilansowa
├── uor_reports.rego            80 L   — Sprawozdania finansowe
├── vat_registration.rego       80 L   — Rejestracja VAT
├── labor_extended.rego         80 L   — Pracodawca
├── ordynacja_extended.rego     80 L   — Procedury podatkowe
├── cit_deductions.rego         80 L   — Odliczenia CIT
├── pit_withholding.rego        80 L   — Pobór PIT
│
├── vat/
│   ├── substantive.rego       100+ L  — Stawki VAT, GTU
│   ├── deductions.rego         20 L   — Odliczenia VAT (stub)
│   ├── procedures.rego         20 L   — Procedury VAT (stub)
│   └── gtu.rego                50 L   — Mapowania GTU
│
└── data/
    └── thresholds_sc.rego     164 L   — ScThresholdPrecompute — prekompilowane progi
```

**Narzędzia Python:**

```
tools/
├── sc_context_enricher.py     382 L   — Pre-processor walidacji input SC
├── sc_legal_graph.py          421 L   — Analizator grafu zależności reguł
├── regulatory_radar.py        309 L   — Monitor zmian legislacyjnych
└── sc_verdict_streaming.py    283 L   — Batch processing faktur
```

**Testy:**

```
policies/tests/
└── sc_main_test.rego          293 L   — 15 testów integracyjnych SC
```

---

## 🔗 Architektura Multi-Pass dla SC

```
INPUT ──► PASS 0: RISK ───────► PASS 1: ROUTING ────► PASS 2: COMPLIANCE ──►
              │ (BLOCK→abort)      │ (BLOCK→abort)       │
              ▼                    ▼                     ▼
         risk_verdict          routing_verdict       compliance_verdict

         PASS 3: CROSSBORDER ─► PASS 4: TEMPORAL ────► PASS 5: VAT (spółka) ─►
              │                    │                      │
              ▼                    ▼                      ▼
         cross_verdict         temporal_verdict       vat_verdict

         PASS 6: ANOMALY ─────► PASS 7: MIRROR ───────► PASS 8: WHAT_IF ────►
              │                    │                      │
              ▼                    ▼                      ▼
         anomaly_verdict       mirror_verdict         simulation_verdict

         PASS 9: SC_FALLBACK ─► FINAL_VERDICT + SC_CONTEXT
              │
              ▼
         sc_fallback_verdict (zawsze pasuje — gwarantuje werdykt)
```

**Kluczowa różnica vs JDG:** VAT jest spółki (pojedynczy werdykt), PIT jest KAŻDEGO wspólnika osobno (Art. 8 PIT — podział proporcjonalny). Odpowiedzialność solidarna (Art. 864 KC) — wierzyciel może egzekwować od dowolnego wspólnika.

---

## 📊 Mapa priorytetów SC

| Priorytet | Pakiet | Plik | Odpowiedzialność | Status |
|:---------:|--------|------|-------------------|:------:|
| 0 | `tax.risk` | `risk.rego` | Fraud graph, trust score, anomalie | 💚 |
| 3 | `tax.what_if` | `what_if.rego` | Tryb symulacyjny | 💚 |
| 5 | `tax.temporal` | `temporal.rego` | Temporalne thresholds | 💚 |
| 8 | `tax.anomaly` | `anomaly.rego` | 5 reguł anomalii | 💚 |
| 10-12 | `tax.routing` | `routing.rego` | Field confidence | 💚 |
| 20-22 | `tax.compliance` | `compliance.rego` | Biała Lista, MPP, kasy | 💚 |
| 40-49 | `tax.crossborder` | `crossborder.rego` | WNT, WDT, import/eksport | 💚 |
| 50-65 | `tax.vat.substantive` | `vat/substantive.rego` | Stawki VAT, GTU | 🟡 |
| 75 | `tax.partner_mirror` | `partner_mirror.rego` | RODO/solidarność split | 💚 |
| 100 | `tax.fallback` | `fallback.rego` | Domyślny 23% VAT | 💚 |
| 120-140 | `tax.vat.deductions/procedures` | `vat/*.rego` | Odliczenia i procedury VAT | 🟡 stub |
| 330-345 | `tax.sc_partnership` | `sc_partnership.rego` | Powstanie, zmiany składu | 💚 |
| 385-430 | `tax.sc_partnership` | `sc_partnership.rego` | Rozwiązanie, sukcesja, zawieszenie | 💚 |
| 500-530 | `tax.sc_liability` | `sc_liability.rego` | Solidarna, regres, egzekucja | 💚 |
| 600-625 | `tax.sc_ksef_jpk` | `sc_ksef_jpk.rego` | KSeF, JPK_V7, limity gotówkowe | 💚 |
| 900-912 | `tax.sc_fallback` | `sc_fallback.rego` | Fallback SC (6 stanów) | 💚 |
| 999 | `tax.sc_fallback` | `sc_fallback.rego` | NO_MATCH ostateczny | 💚 |

---

## 📐 Standardowy werdykt SC

Każda reguła zwraca ustandaryzowany obiekt z kontekstem SC:

```json
{
    "matched": true,
    "rule_id": "tax.sc_fallback.domestic_sc",
    "package": "tax.sc_fallback",
    "priority": 900,
    "vat_rate": "0.23",
    "rounding_level": "position",
    "gtu_code": "",
    "procedure": "",
    "income_tax_qualification": "deductible_full",
    "entity_type": "SPOLKA_CYWILNA",
    "partnership_nip": "9876543210",
    "partner_count": 2,
    "partner_tax_forms": {"P1": "PIT_SCALE", "P2": "LINEAR"},
    "joint_liability_total": 0,
    "liable_partners": ["1111111111", "2222222222"],
    "_routing": "",
    "_routing_reason": "[SC] Domyślna stawka VAT 23% PL",
    "_legal_basis": "Art. 41 ust. 1 VAT, Art. 8 PIT",
    "_warnings": []
}
```

Pola specyficzne dla SC (vs JDG):
- `entity_type`: zawsze `"SPOLKA_CYWILNA"`
- `partner_count`, `partner_tax_forms`: dane wspólników
- `joint_liability_total`, `liable_partners`: odpowiedzialność solidarna
- `_routing_reason` prefix `[SC]`

---

## 💚 Postęp implementacji SC

| Kategoria | Zaimplementowano | Szkielety/stub | Plany |
|-----------|:---:|:---:|:---:|
| Strategic Improvements | 💚 4 | — | — |
| SC Integration (partnership, liability, KSeF) | 💚 4 | — | — |
| SC Fallback + Orchestrator | 💚 2 | — | — |
| SC Helpers + Metadata | 💚 2 | — | — |
| Risk + Routing + Compliance | 💚 3 | — | — |
| VAT | — | 🟡 2 stub | 📋 1 |
| PIT (wspólnicy — Art. 8) | — | — | 📋 7 |
| ZUS (per wspólnik) | — | — | 📋 2 |
| Accounting (SC) | — | — | 📋 3 |
| Employer, Sanctions, Interactions | — | — | 📋 3 |
| Data (thresholds) | 💚 1 | — | — |
| Python Tools | 💚 4 | — | — |
| Tests | 💚 1 (15 testów) | — | — |
| **RAZEM** | **21** | **2** | **16** |

---

## 🔗 Powiązane dokumenty

| Dokument | Opis |
|----------|------|
| `Plan OPA/SC_DEFINITIVE_REGO_PLAN.md` | Plan definitywny — ~550 reguł, architektura |
| `Plan OPA/37_SPOLKA_CYWILNA_ULTIMATE_GRANULARITY.md` | Mikro-dekompozycja GR — ~435 reguł |
| `Plan OPA/38_SPOLKA_CYWILNA_STRATEGIC_IMPROVEMENTS.md` | Analiza strategiczna 7 wymiarów + 3×3 ulepszeń |
| `Plan OPA/35_SPOLKA_CYWILNA_ADVANCED_GAPS.md` | 15 zaawansowanych luk |
| `Plan OPA/36_SPOLKA_CYWILNA_ULTIMATE_GAPS.md` | 17 ultimate pod-obszarów |
| `docs/canonical_rules_index.md` | Kanoniczny indeks ~1,255 reguł |
| `docs/package_fusion_strategy.md` | Strategia fuzji 33→12 pakietów |
| `policies/jdg/README.md` | JDG Policy-as-Code (wzorzec architektoniczny) |

---

> **Built with ❤️ by NexusAI SC Team** | OPA/Rego | Multi-Pass | First-Match-Wins | Art. 8 PIT | Art. 864 KC
