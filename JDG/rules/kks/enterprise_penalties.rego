# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — Enterprise KKS Penalties & Defense Intelligence (Art. 54-83)
# ═══════════════════════════════════════════════════════════════════════════════
#
# METADATA
# title: KKS Enterprise Penalties — Complete Fiscal Penal Code Intelligence
# description: |
#   ENTERPRISE v5.0 — Wypełnia ostatnią lukę ~30 punktów KKS (Art. 54-83).
#   Szczegółowe reguły kar karno-skarbowych dla JDG z kalkulacją stawek,
#   progami materialności, okresami przedawnienia, czynnym żalem.
#   - K100-K109: Art. 54 — Uchylanie się od opodatkowania (przestępstwo)
#   - K110-K119: Art. 56-57 — Nierzetelne księgi / ewidencja VAT
#   - K120-K129: Art. 60-62 — Niszczenie dokumentów, puste faktury, fałszerstwa
#   - K130-K139: Art. 64-69 — Błędna stawka VAT, utrudnianie kontroli
#   - K140-K149: Art. 76-79 — Nienależny zwrot, niezłożenie deklaracji, brak zapłaty
#   - K150-K159: Art. 23-25 — Kalkulacja grzywny, stawki dzienne, kara zastępcza
#   - K160-K169: Art. 16 — Czynny żal — praktyczny przewodnik
#   - K170-K179: Art. 20-21, 44 — Przedawnienie, przerwanie, zatarcie skazania
# architecture: Enterprise Multi-Pass (ADR-001), First-Match-Wins else-chain
# legal_basis: Kodeks Karny Skarbowy (Dz.U. 2025 poz. 678, ze zm.)
# package: jdg.kks.enterprise_penalties
# deprecated: false

# ═══════════════════════════════════════════════════════════════════════════════

package jdg.kks.enterprise_penalties

import data.jdg.helpers
import future.keywords.if

# Conditional values are helpers rather than guarded assignments inside rule bodies.
# This preserves the legacy first-match semantics while remaining valid Rego 0.68.
evasion_severity_for(loss) := "WYKROCZENIE" if { loss <= 100000 } else := "PRZESTĘPSTWO (mała wartość)" if { loss <= 500000 } else := "PRZESTĘPSTWO (duża wartość)" if { loss <= 5000000 } else := "PRZESTĘPSTWO (wielka wartość)"
evasion_max_rates_for(loss) := 180 if { loss <= 100000 } else := 720 if { loss <= 500000 } else := 1080
evasion_label_for(loss) := "MEDIUM" if { loss <= 100000 } else := "HIGH" if { loss <= 500000 } else := "CRITICAL"
evasion_defense_for(loss) := "Czynny żal (Art.16 KKS) = BEZKARNOŚĆ! Złóż zawiadomienie + wpłać zaległość przed kontrolą." if { loss <= 500000 } else := "KONIECZNY ADWOKAT! Duża wartość — ryzyko pozbawienia wolności."

pkpir_rates_for(score) := 180 if { score >= 60 } else := 360 if { score >= 40 } else := 540 if { score >= 25 } else := 720
pkpir_class_for(score) := "WYKROCZENIE — drobne nieprawidłowości" if { score >= 60 } else := "PRZESTĘPSTWO — systematyczna nierzetelność" if { score >= 25 } else := "PRZESTĘPSTWO — rażąca nierzetelność (fikcyjne wpisy)"
pkpir_severity_for(score) := "LOW" if { score >= 60 } else := "MEDIUM" if { score >= 40 } else := "HIGH" if { score >= 25 } else := "CRITICAL"
pkpir_guidance_for(score) := "Skoryguj PKPiR + złóż czynny żal — unikniesz kary" if { score >= 40 } else := "KONIECZNA KOREKTA + czynny żal + ADWOKAT"

empty_scale_for(count, amount) := "POJEDYNCZA — jedna faktura" if { count == 1 } else := sprintf("SYSTEMATYCZNA — %d faktur na %.0f PLN", [count, amount]) if { amount <= 5000000 } else := sprintf("KARUZELA VAT — %d faktur na %.0f PLN!", [count, amount])
empty_max_rates_for(amount) := 720 if { amount <= 5000000 } else := 1080
empty_max_years_for(amount) := 8 if { amount <= 5000000 } else := 15

wrong_rate_severity_for(intentional, underpaid) := "HIGH" if { intentional } else := "LOW" if { underpaid <= 1000 } else := "MEDIUM"
wrong_rate_max_rates_for(underpaid) := 180 if { underpaid <= 1000 } else := 360 if { underpaid <= 15000 } else := 540
wrong_rate_penalty_for(intentional) := "Dodatkowe zobowiązanie 30% VAT" if { intentional } else := "Bez dodatkowej sankcji — tylko odsetki"

obstruction_description_for(kind) := "Brak dokumentów w siedzibie — udostępnij natychmiast" if { kind == "BRAK_DOKUMENTOW" } else := "Niedostępność systemu księgowego — przywróć dostęp" if { kind == "SYSTEM" } else := "Odmowa udzielenia wyjaśnień — obowiązek współpracy!" if { kind == "REFUSAL" } else := "Celowe opóźnianie — natychmiast zaprzestań" if { kind == "DELAY" } else := sprintf("Inne: %s", [kind])

refund_max_rates_for(fraudulent) := 360 if { not fraudulent } else := 720
refund_severity_for(fraudulent) := "MEDIUM" if { not fraudulent } else := "CRITICAL"
refund_penalty_for(fraudulent) := "Tylko sankcja administracyjna" if { not fraudulent } else := "Przestępstwo — ryzyko pozbawienia wolności!"

nonfiling_max_rates_for(persistent) := 180 if { not persistent } else := 360
nonfiling_offense_for(persistent) := "WYKROCZENIE — pojedyncza deklaracja" if { not persistent } else := "PRZESTĘPSTWO — uporczywe niezłożenie!"
nonfiling_severity_for(days) := "LOW" if { days <= 30 } else := "MEDIUM" if { days <= 90 } else := "HIGH"
nonfiling_route_for(persistent) := "BLOCK_AND_ALERT" if { persistent } else := "TRIAGE_QUEUE"

nonpayment_severity_for(days) := "LOW" if { days <= 30 } else := "MEDIUM" if { days <= 90 } else := "HIGH"
nonpayment_route_for(days) := "BLOCK_AND_ALERT" if { days > 90 } else := "TRIAGE_QUEUE"
nonpayment_note_for(days) := "Zapłać + złóż czynny żal = unikniesz kary" if { days <= 90 } else := "RYZYKO EGZEKUCJI! Natychmiast wpłać zaległość!"

vd_howto_for(pre_audit) := "Złóż zawiadomienie + wpłać w 7 dni = CAŁKOWITA BEZKARNOŚĆ" if { pre_audit } else := "ZBYT PÓŹNO — kontrola już wszczęta. Czynny żal NIESKUTECZNY!"
vd_timing_for(pre_audit) := "ZŁÓŻ ZANIM US WYKRYJE — po wszczęciu kontroli = ZA PÓŹNO!" if { pre_audit } else := "Kontrola już trwa — czynny żal NIE chroni. Szukaj adwokata."
vd_urgency_for(days) := "WPŁAĆ NATYCHMIAST — termin mija!" if { days <= 2 } else := sprintf("Zostało %d dni — nie zwlekaj!", [days])
vd_deadline_severity_for(days) := "CRITICAL" if { days <= 2 } else := "HIGH"
vd_deadline_route_for(days) := "BLOCK_AND_ALERT" if { days <= 2 } else := "TRIAGE_QUEUE"

statute_base_years_for(kind) := 3 if { kind == "WYKROCZENIE" } else := 5
statute_extension_years_for(applied) := 5 if { applied } else := 0
statute_expired_note_for(expired, total) := "PRZEDAWNIONE! Brak odpowiedzialności." if { expired } else := sprintf("NIE przedawnione — pozostało ~%d lat.", [2023 + total - 2026])
statute_route_for(expired) := "" if { expired } else := "BLOCK_AND_ALERT"
rehab_years_for(kind) := 3 if { kind == "WYKROCZENIE" } else := 5
rehab_status_for(rehabilitated, years) := "ZATARTE — skazanie niebyłe" if { rehabilitated } else := sprintf("NIE zatarte — pozostało ~%d lat.", [2023 + years - 2026])


default decide := {
    "matched": false, "rule_id": "jdg.kks.enterprise.no_match",
    "package": "jdg.kks.enterprise_penalties", "priority": 899
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  K100-K109: Art. 54 KKS — UCHYLANIE SIĘ OD OPODATKOWANIA                ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# ── K100: tax_evasion_classification — Klasyfikacja uchylania się ──
decide := {
    "matched": true, "rule_id": "jdg.kks.tax_evasion_classification",
    "package": "jdg.kks.enterprise_penalties", "priority": 100,
    "kks_offense_type": "TAX_EVASION",
    "kks_article": "54",
    "kks_severity": evasion_severity,
    "kks_max_daily_rates": max_rates,
    "kks_materiality_threshold_pln": materiality_threshold,
    "kks_estimated_penalty_pln": estimated_penalty,
    "sanction_type": "KKS", "sanction_severity": severity_label,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": sprintf("Uchylanie od podatku Art.54 — %s: %.0f PLN, ryzyko do %d stawek", [evasion_type, tax_loss, max_rates]),
    "_legal_basis": "Art. 54 § 1-3 ustawy z dnia 10 września 1999 r. — Kodeks karny skarbowy (Dz.U. 2025 poz. 678, ze zm.)",
    "_warnings": [sprintf("ART.54 KKS — UCHYLANIE SIĘ OD OPODATKOWANIA. Typ: %s. Uszczuplenie: %.2f PLN. Klasyfikacja: %s (próg: %.0f PLN). Max kara: do %d stawek dziennych (~%.0f PLN). Szacowana grzywna: %.0f PLN. %s", [evasion_type, tax_loss, evasion_severity, materiality_threshold, max_rates, max_penalty_pln, estimated_penalty, defense_note])]
} {
    input.kks.tax_evasion_detected == true
    tax_loss := object.get(input.kks, "tax_loss_pln", 0)
    tax_loss > 0
    evasion_type := object.get(input.kks, "evasion_type", "UNKNOWN")
    # Progi materialności 2026
    small_value := 100000    # mała wartość
    large_value := 500000    # duża wartość
    great_value := 5000000   # wielka wartość
    evasion_severity := evasion_severity_for(tax_loss)
    materiality_threshold := small_value
    max_rates := evasion_max_rates_for(tax_loss)
    severity_label := evasion_label_for(tax_loss)
    daily_rate := object.get(input.jdg_entrepreneur, "kks_daily_rate_pln", 150)
    max_penalty_pln := max_rates * daily_rate
    estimated_penalty := floor(tax_loss * 0.30 * 100) / 100
    defense_note := evasion_defense_for(tax_loss)
}

# ── K101: tax_evasion_concealed_business — Całkowicie ukryta DG ──
else := {
    "matched": true, "rule_id": "jdg.kks.concealed_business_art54p3",
    "package": "jdg.kks.enterprise_penalties", "priority": 101,
    "kks_offense_type": "CONCEALED_BUSINESS",
    "kks_article": "54", "kks_paragraph": "3",
    "kks_severity": "PRZESTĘPSTWO",
    "kks_max_daily_rates": 720,
    "sanction_type": "KKS", "sanction_severity": "CRITICAL",
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "Całkowicie ukryta działalność — Art. 54 § 3 KKS",
    "_legal_basis": "Art. 54 § 3 ustawy z dnia 10 września 1999 r. — Kodeks karny skarbowy (Dz.U. 2025 poz. 678, ze zm.)",
    "_warnings": [sprintf("UKRYTA DZIAŁALNOŚĆ GOSPODARCZA — Art. 54 § 3 KKS. Przychód: %.2f PLN/rok bez CEIDG i deklaracji. KARA: grzywna do 720 stawek dziennych + do 5 lat pozbawienia wolności! Zarejestruj CEIDG + złóż czynny żal NATYCHMIAST.", [concealed_revenue])]
} {
    object.get(input.kks, "concealed_business", false) == true
    concealed_revenue := object.get(input.kks, "concealed_revenue_pln", 0)
}

# ── K102: tax_evasion_fictitious_costs — Fikcyjne koszty uzyskania ──
else := {
    "matched": true, "rule_id": "jdg.kks.fictitious_costs_art54",
    "package": "jdg.kks.enterprise_penalties", "priority": 102,
    "kks_offense_type": "FICTITIOUS_COSTS",
    "kks_article": "54", "kks_paragraph": "1",
    "kks_severity": "PRZESTĘPSTWO",
    "kks_max_daily_rates": 720,
    "sanction_type": "KKS", "sanction_severity": "HIGH",
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": sprintf("Fikcyjne koszty %.2f PLN — Art. 54 § 1 KKS", [fictitious_amount]),
    "_legal_basis": "Art. 54 § 1 ustawy z dnia 10 września 1999 r. — Kodeks karny skarbowy (Dz.U. 2025 poz. 678, ze zm.)",
    "_warnings": [sprintf("FIKCYJNE KOSZTY UZYSKANIA — %.2f PLN. Art. 54 § 1 KKS. Faktury od nieistniejących/nierzetelnych podmiotów = PRZESTĘPSTWO SKARBOWE. Konsekwencje: (1) Grzywna do 720 stawek dziennych, (2) Odpowiedzialność solidarna za VAT (Art. 105a VAT), (3) Utrata prawa do odliczenia VAT + KUP. Zweryfikuj kontrahenta na Białej Liście VAT!", [fictitious_amount])]
} {
    object.get(input.kks, "fictitious_costs_detected", false) == true
    fictitious_amount := object.get(input.kks, "fictitious_costs_amount", 0)
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  K110-K119: Art. 56-57 — NIERZETELNE KSIĘGI / EWIDENCJA                  ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# ── K110: unreliable_pkpir_detailed — Nierzetelna PKPiR — szczegóły ──
else := {
    "matched": true, "rule_id": "jdg.kks.unreliable_pkpir_detailed",
    "package": "jdg.kks.enterprise_penalties", "priority": 110,
    "kks_offense_type": "UNRELIABLE_BOOKS",
    "kks_article": "56", "kks_paragraph": "1-4",
    "kks_max_daily_rates": max_rates,
    "kks_integrity_score_pct": integrity_score,
    "sanction_type": "KKS", "sanction_severity": severity,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": sprintf("Nierzetelna PKPiR — integrity %.0f%% — Art. 56 KKS", [integrity_score]),
    "_legal_basis": "Art. 56 § 1-4 ustawy z dnia 10 września 1999 r. — Kodeks karny skarbowy (Dz.U. 2025 poz. 678, ze zm.)",
    "_warnings": [sprintf("NIERZETELNA PKPiR — Art. 56 KKS. Integrity score: %.0f%%. Klasyfikacja: %s. Max kara: %d stawek dziennych. Konsekwencje: (1) Szacunkowe określenie dochodu przez US (zwykle 2-3x zawyżone!), (2) Grzywna KKS + odsetki, (3) Wzmożone kontrole przez 5 lat. %s", [integrity_score, offense_class, max_rates, fix_guidance])]
} {
    object.get(input.jdg_entrepreneur, "pkpir_integrity_score", 1.0) < 0.85
    integrity_score := object.get(input.jdg_entrepreneur, "pkpir_integrity_score", 1.0) * 100
    max_rates := pkpir_rates_for(integrity_score)
    offense_class := pkpir_class_for(integrity_score)
    severity := pkpir_severity_for(integrity_score)
    fix_guidance := pkpir_guidance_for(integrity_score)
}

# ── K111: unreliable_vat_evidence — Nierzetelna ewidencja VAT ──
else := {
    "matched": true, "rule_id": "jdg.kks.unreliable_vat_evidence_detailed",
    "package": "jdg.kks.enterprise_penalties", "priority": 111,
    "kks_offense_type": "UNRELIABLE_VAT",
    "kks_article": "57", "kks_paragraph": "1",
    "kks_max_daily_rates": 360,
    "sanction_type": "KKS", "sanction_severity": "HIGH",
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": sprintf("Nierzetelna ewidencja VAT — %.2f PLN rozbieżność JPK", [vat_discrepancy]),
    "_legal_basis": "Art. 57 § 1 ustawy z dnia 10 września 1999 r. — Kodeks karny skarbowy (Dz.U. 2025 poz. 678, ze zm.)",
    "_warnings": [sprintf("NIERZETELNA EWIDENCJA VAT — Art. 57 KKS. Rozbieżność JPK vs rejestry: %.2f PLN. Konsekwencje: (1) Grzywna do 360 stawek dziennych, (2) Dodatkowe zobowiązanie 30%% (Art. 112b VAT), (3) Sankcja za nierzetelny JPK. Skoryguj JPK_V7 przed kontrolą!", [vat_discrepancy])]
} {
    object.get(input.kks, "vat_evidence_unreliable", false) == true
    vat_discrepancy := object.get(input.kks, "vat_jpk_discrepancy_pln", 0)
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  K120-K129: Art. 60-62 — DOKUMENTY / FAKTURY / FAŁSZERSTWA               ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# ── K120: document_destruction — Zniszczenie/ukrycie dokumentów ──
else := {
    "matched": true, "rule_id": "jdg.kks.document_destruction_art60",
    "package": "jdg.kks.enterprise_penalties", "priority": 120,
    "kks_offense_type": "DOCUMENT_DESTRUCTION",
    "kks_article": "60", "kks_paragraph": "1",
    "kks_max_daily_rates": 720,
    "kks_imprisonment_risk": true,
    "sanction_type": "KKS", "sanction_severity": "CRITICAL",
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "Zniszczenie/ukrycie dokumentów — Art. 60 KKS",
    "_legal_basis": "Art. 60 § 1-3 ustawy z dnia 10 września 1999 r. — Kodeks karny skarbowy (Dz.U. 2025 poz. 678, ze zm.)",
    "_warnings": ["ZNISZCZENIE/UKRYCIE DOKUMENTÓW — Art. 60 KKS. PRZESTĘPSTWO SKARBOWE! Kary: (1) Grzywna do 720 stawek dziennych, (2) Do 5 lat pozbawienia wolności przy wielkiej wartości, (3) Odpowiedzialność za dokumenty przez 5 lat. NISZCZENIE PO TERMINIE PRZEDAWNIENIA = DOZWOLONE (Art. 86 OrdPU)."]
} {
    object.get(input.kks, "documents_destroyed_intentionally", false) == true
}

# ── K121: empty_invoice_chain — Pusta faktura / karuzela VAT ──
else := {
    "matched": true, "rule_id": "jdg.kks.enterprise.empty_invoice_art62",
    "package": "jdg.kks.enterprise_penalties", "priority": 121,
    "kks_offense_type": "EMPTY_INVOICE",
    "kks_article": "62", "kks_paragraph": "2",
    "kks_max_daily_rates": max_rates,
    "kks_imprisonment_risk": true,
    "kks_imprisonment_max_years": max_years,
    "sanction_type": "KKS", "sanction_severity": "CRITICAL",
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": sprintf("Pusta faktura — Art. 62 § 2 KKS (%s, ryzyko %d lat)", [offense_scale, max_years]),
    "_legal_basis": "Art. 62 § 1-2 ustawy z dnia 10 września 1999 r. — Kodeks karny skarbowy (Dz.U. 2025 poz. 678, ze zm.)",
    "_warnings": [sprintf("PUSTA FAKTURA — Art. 62 § 2 KKS. %s. Konsekwencje: (1) Grzywna do %d stawek dziennych, (2) DO %d LAT pozbawienia wolności (obowiązkowo powyżej 5 mln PLN!), (3) Przepadek korzyści majątkowej, (4) Odpowiedzialność solidarna za VAT (Art. 105a VAT). NIE wystawiaj/nabywaj faktur bez realnej transakcji!", [offense_desc, max_rates, max_years])]
} {
    object.get(input.kks, "empty_invoice_detected", false) == true
    invoice_amount := object.get(input.kks, "empty_invoice_total", 0)
    invoice_count := object.get(input.kks, "empty_invoice_count", 1)
    offense_scale := empty_scale_for(invoice_count, invoice_amount)
    offense_desc := sprintf("%d faktur, %.0f PLN", [invoice_count, invoice_amount])
    max_rates := empty_max_rates_for(invoice_amount)
    max_years := empty_max_years_for(invoice_amount)
}

# ── K122: invoice_counterfeiting — Fałszowanie faktur ──
else := {
    "matched": true, "rule_id": "jdg.kks.invoice_counterfeiting_art62p1",
    "package": "jdg.kks.enterprise_penalties", "priority": 122,
    "kks_offense_type": "INVOICE_FORGERY",
    "kks_article": "62", "kks_paragraph": "1",
    "kks_max_daily_rates": 720,
    "kks_imprisonment_risk": true,
    "sanction_type": "KKS", "sanction_severity": "CRITICAL",
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "Podrobiona/przerobiona faktura — Art. 62 § 1 KKS",
    "_legal_basis": "Art. 62 § 1 ustawy z dnia 10 września 1999 r. — Kodeks karny skarbowy (Dz.U. 2025 poz. 678, ze zm.)",
    "_warnings": ["PODROBIONA/PRZEROBIONA FAKTURA — Art. 62 § 1 KKS. Fałszerstwo dokumentu = przestępstwo! Konsekwencje: grzywna do 720 stawek + do 5 lat pozbawienia wolności. Natychmiast zgłoś do US przez czynny żal!"]
} {
    object.get(input.kks, "invoice_counterfeited", false) == true
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  K130-K139: Art. 64-69 — STAWKA VAT / UTRUDNIANIE / NIEREJESTRACJA      ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# ── K130: wrong_vat_rate — Niewłaściwa stawka VAT ──
else := {
    "matched": true, "rule_id": "jdg.kks.enterprise.wrong_vat_rate_art64",
    "package": "jdg.kks.enterprise_penalties", "priority": 130,
    "kks_offense_type": "WRONG_VAT_RATE",
    "kks_article": "64",
    "kks_severity": severity,
    "kks_max_daily_rates": max_rates,
    "kks_vat_underpaid_pln": vat_underpaid,
    "sanction_type": "KKS", "sanction_severity": severity,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": sprintf("Błędna stawka VAT — zaniżono %.2f PLN — Art. 64 KKS", [vat_underpaid]),
    "_legal_basis": "Art. 64 ustawy z dnia 10 września 1999 r. — Kodeks karny skarbowy (Dz.U. 2025 poz. 678, ze zm.)",
    "_warnings": [sprintf("NIEWŁAŚCIWA STAWKA VAT — Art. 64 KKS. Zastosowano %s zamiast %s. Zaniżono VAT o %.2f PLN. Konsekwencje: (1) Grzywna do %d stawek dziennych, (2) Dopłata VAT + odsetki 14.5%%, (3) %s. Skoryguj fakturę korygującą + JPK_V7.", [applied_rate, correct_rate, vat_underpaid, max_rates, penalty_note])]
} {
    object.get(input.kks, "wrong_vat_rate_applied", false) == true
    vat_underpaid := object.get(input.kks, "vat_underpaid_pln", 0)
    applied_rate := object.get(input.kks, "applied_vat_rate", "ZW")
    correct_rate := object.get(input.kks, "correct_vat_rate", "0.23")
    is_intentional := object.get(input.kks, "is_intentional_rate_evasion", false)
    severity := wrong_rate_severity_for(is_intentional, vat_underpaid)
    max_rates := wrong_rate_max_rates_for(vat_underpaid)
    penalty_note := wrong_rate_penalty_for(is_intentional)
}

# ── K131: obstruction_of_audit — Utrudnianie kontroli ──
else := {
    "matched": true, "rule_id": "jdg.kks.obstruction_audit_art69",
    "package": "jdg.kks.enterprise_penalties", "priority": 131,
    "kks_offense_type": "OBSTRUCTION",
    "kks_article": "69", "kks_paragraph": "1-3",
    "kks_max_daily_rates": 360,
    "kks_penalty_fixed_pln": 5000,
    "sanction_type": "KKS", "sanction_severity": "HIGH",
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": sprintf("Utrudnianie kontroli — %s — Art. 69 KKS", [obstruction_type]),
    "_legal_basis": "Art. 69 § 1-3 ustawy z dnia 10 września 1999 r. — Kodeks karny skarbowy (Dz.U. 2025 poz. 678, ze zm.)",
    "_warnings": [sprintf("UTRUDNIANIE KONTROLI SKARBOWEJ — Art. 69 KKS. %s. Konsekwencje: (1) Kara grzywny do 360 stawek dziennych, (2) Dodatkowa kara porządkowa 5 000 PLN (Art. 262 OrdPU), (3) Możliwość przymusowego doprowadzenia świadków, (4) Możliwość oszacowania podstawy opodatkowania (zwykle zawyżonej!). %s", [obstruction_desc, fix_instruction])]
} {
    object.get(input.kks, "obstruction_detected", false) == true
    obstruction_type := object.get(input.kks, "obstruction_type", "BRAK_DOKUMENTOW")
    obstruction_desc := obstruction_description_for(obstruction_type)
    fix_instruction := "UDOSTĘPNIJ dokumenty — unikniesz dodatkowej kary 5000 PLN."
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  K140-K149: Art. 76-79 — NIENALEŻNY ZWROT / NIEZŁOŻENIE / BRAK ZAPŁATY ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# ── K140: unjustified_vat_refund — Nienależny zwrot VAT ──
else := {
    "matched": true, "rule_id": "jdg.kks.unjustified_refund_art76",
    "package": "jdg.kks.enterprise_penalties", "priority": 140,
    "kks_offense_type": "UNJUSTIFIED_REFUND",
    "kks_article": "76",
    "kks_max_daily_rates": max_rates,
    "kks_refund_amount_pln": refund_amount,
    "kks_repayment_duty": refund_amount * 1.30,
    "sanction_type": "KKS", "sanction_severity": severity,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": sprintf("Nienależny zwrot VAT %.2f PLN — Art. 76 KKS", [refund_amount]),
    "_legal_basis": "Art. 76 § 1-2 ustawy z dnia 10 września 1999 r. — Kodeks karny skarbowy (Dz.U. 2025 poz. 678, ze zm.)",
    "_warnings": [sprintf("NIENALEŻNY ZWROT VAT — Art. 76 KKS. Kwota: %.2f PLN. Konsekwencje: (1) Zwrot VAT + 30%% dodatkowego zobowiązania (%.2f PLN), (2) Grzywna do %d stawek, (3) %s. Natychmiast skoryguj JPK i zwróć VAT z odsetkami!", [refund_amount, refund_amount * 1.30, max_rates, penalty_add])]
} {
    object.get(input.kks, "unjustified_vat_refund", false) == true
    refund_amount := object.get(input.kks, "refund_amount_pln", 0)
    is_fraudulent := object.get(input.kks, "is_fraudulent_refund", false)
    max_rates := refund_max_rates_for(is_fraudulent)
    severity := refund_severity_for(is_fraudulent)
    penalty_add := refund_penalty_for(is_fraudulent)
}

# ── K141: tax_declaration_non_filing — Niezłożenie deklaracji ──
else := {
    "matched": true, "rule_id": "jdg.kks.non_filing_declaration_art77",
    "package": "jdg.kks.enterprise_penalties", "priority": 141,
    "kks_offense_type": "NON_FILING",
    "kks_article": "77",
    "kks_days_overdue": days_overdue,
    "kks_max_daily_rates": max_rates,
    "kks_declaration_type": declaration_type,
    "sanction_type": "KKS", "sanction_severity": severity,
    "_routing": filing_rt,
    "_routing_reason": sprintf("Niezłożona deklaracja %s — %d dni opóźnienia", [declaration_type, days_overdue]),
    "_legal_basis": "Art. 77 § 1-3 ustawy z dnia 10 września 1999 r. — Kodeks karny skarbowy (Dz.U. 2025 poz. 678, ze zm.)",
    "_warnings": [sprintf("NIEZŁOŻONA DEKLARACJA — %s. Opóźnienie: %d dni. Konsekwencje: (1) Grzywna do %d stawek dziennych (%s), (2) US może sam oszacować podatek (zwykle NIekorzystnie!), (3) Odsetki 14.5%% od zaległości. ZŁÓŻ DEKLARACJĘ NATYCHMIAST + czynny żal!", [declaration_type, days_overdue, max_rates, offense_type])]
} {
    object.get(input.kks, "declaration_missing", false) == true
    declaration_type := object.get(input.kks, "declaration_type", "VAT-7")
    days_overdue := object.get(input.kks, "days_overdue", 1)
    is_persistent := days_overdue > 90
    max_rates := nonfiling_max_rates_for(is_persistent)
    offense_type := nonfiling_offense_for(is_persistent)
    severity := nonfiling_severity_for(days_overdue)
    filing_rt := nonfiling_route_for(is_persistent)
}

# ── K142: tax_non_payment — Niezapłacenie podatku ──
else := {
    "matched": true, "rule_id": "jdg.kks.tax_non_payment_art79",
    "package": "jdg.kks.enterprise_penalties", "priority": 142,
    "kks_offense_type": "TAX_UNPAID",
    "kks_article": "79",
    "kks_tax_unpaid_pln": tax_unpaid,
    "kks_interest_rate_pct": 14.5,
    "kks_interest_daily_pln": floor(tax_unpaid * 0.145 / 365 * 100) / 100,
    "kks_max_daily_rates": 180,
    "sanction_type": "KKS", "sanction_severity": severity,
    "_routing": payment_rt,
    "_routing_reason": sprintf("Niezapłacony podatek %.2f PLN — Art. 79 KKS", [tax_unpaid]),
    "_legal_basis": "Art. 79 ustawy z dnia 10 września 1999 r. — Kodeks karny skarbowy (Dz.U. 2025 poz. 678, ze zm.)",
    "_warnings": [sprintf("NIEZAPŁACONY PODATEK — %.2f PLN zaległości. Odsetki: %.2f PLN/dzień (14.5%%/rok). Konsekwencje: (1) Grzywna KKS do 180 stawek, (2) Egzekucja komornicza (zajęcie konta!), (3) %s. WPŁAĆ PODATEK + czynny żal!", [tax_unpaid, daily_interest, escalation_note])]
} {
    object.get(input.kks, "tax_unpaid_detected", false) == true
    tax_unpaid := object.get(input.kks, "tax_unpaid_pln", 0)
    days_unpaid := object.get(input.kks, "tax_unpaid_days", 0)
    daily_interest := floor(tax_unpaid * 0.145 / 365 * 100) / 100
    severity := nonpayment_severity_for(days_unpaid)
    payment_rt := nonpayment_route_for(days_unpaid)
    escalation_note := nonpayment_note_for(days_unpaid)
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  K150-K159: Art. 23-25 — KALKULACJA GRZYWNY / STAWKI DZIENNE / KARA Z. ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# ── K150: daily_rate_calculation — Stawka dzienna grzywny KKS ──
else := {
    "matched": true, "rule_id": "jdg.kks.enterprise.daily_rate_calculation",
    "package": "jdg.kks.enterprise_penalties", "priority": 150,
    "kks_daily_rate_min_pln": 56.00,
    "kks_daily_rate_max_pln": 56000.00,
    "kks_daily_rate_calculated_pln": daily_rate,
    "kks_min_penalty_pln": 10 * daily_rate,
    "kks_max_penalty_pln": 720 * daily_rate,
    "_routing": "",
    "_routing_reason": sprintf("Stawka dzienna KKS: %.2f PLN (od %.2f do %.2f)", [daily_rate, 56.00, 56000.00]),
    "_legal_basis": "Art. 23 § 1-4 ustawy z dnia 10 września 1999 r. — Kodeks karny skarbowy (Dz.U. 2025 poz. 678, ze zm.)",
    "_warnings": [sprintf("STAWKA DZIENNA GRZYWNY KKS — %.2f PLN. Zasada: (1) Min. 1/40 min. wynagrodzenia (56 PLN), (2) Max. 400× min. wynagrodzenia (56 000 PLN), (3) 10-720 stawek = grzywna %.0f–%.0f PLN, (4) US oblicza na podstawie: dochodu, sytuacji majątkowej, możliwości zarobkowych. Miesięczny dochód JDG: %.2f PLN → stawka ~%.2f PLN.", [daily_rate, 10 * daily_rate, 720 * daily_rate, monthly_income, daily_rate])]
} {
    input.kks.penalty_calculation_requested == true
    monthly_income := object.get(input.jdg_entrepreneur, "monthly_income_net", 7000)
    dependents := object.get(input.jdg_entrepreneur, "dependents_count", 0)
    # Stawka dzienna: ~1/30 × (dochód miesięczny - 500 PLN/osoba na utrzymaniu)
    disposable := max([500, monthly_income - dependents * 500])
    daily_rate_raw := floor(disposable / 30 * 100) / 100
    daily_rate := min([max([daily_rate_raw, 56]), 56000])
}

# ── K151: fine_range_table — Tabela zakresów grzywien ──
else := {
    "matched": true, "rule_id": "jdg.kks.fine_range_table",
    "package": "jdg.kks.enterprise_penalties", "priority": 151,
    "kks_fine_MISDEMEANOR_min_stawki": 10,
    "kks_fine_MISDEMEANOR_max_stawki": 180,
    "kks_fine_CRIME_STANDARD_max_stawki": 360,
    "kks_fine_CRIME_GRAVE_max_stawki": 720,
    "kks_fine_CRIME_SEVERE_max_stawki": 1080,
    "kks_imprisonment_MISDEMEANOR": false,
    "kks_imprisonment_CRIME_max_years": 10,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 23, 26-28 ustawy z dnia 10 września 1999 r. — Kodeks karny skarbowy (Dz.U. 2025 poz. 678, ze zm.)",
    "_warnings": ["TABELA KAR KKS: (1) Wykroczenia: 10-180 stawek + max 30 dni aresztu, (2) Przestępstwa standardowe: 10-360 stawek + do 3 lat więzienia, (3) Przestępstwa ciężkie (art.54 §2, art.62 §2): 10-720 stawek + do 5 lat, (4) Wielka wartość/fakturowa: 10-1080 stawek + do 10 lat. Stawka dzienna: 56-56 000 PLN."]
} {
    input.kks.penalty_calculation_requested == true
}

# ── K152: imprisonment_substitute — Kara zastępcza pozbawienia wolności ──
else := {
    "matched": true, "rule_id": "jdg.kks.imprisonment_substitute",
    "package": "jdg.kks.enterprise_penalties", "priority": 152,
    "kks_unpaid_fine_pln": unpaid_fine,
    "kks_substitute_days_max": substitute_days,
    "sanction_type": "KKS", "sanction_severity": "CRITICAL",
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": sprintf("Niezapłacona grzywna %.2f PLN — ryzyko %d dni aresztu zastępczego", [unpaid_fine, substitute_days]),
    "_legal_basis": "Art. 25 § 1-3 ustawy z dnia 10 września 1999 r. — Kodeks karny skarbowy (Dz.U. 2025 poz. 678, ze zm.)",
    "_warnings": [sprintf("NIEZAPŁACONA GRZYWNA KKS — %.2f PLN. GROZI KARA ZASTĘPCZA! 1 dzień zastępczy = min. 2 stawki dzienne. Maksymalnie: %d dni aresztu. TWOJA SYTUACJA: %d dni aresztu przy obecnej stawce. WPŁAĆ GRZYWNĘ NATYCHMIAST — unikniesz aresztu!", [unpaid_fine, 360, substitute_days])]
} {
    object.get(input.kks, "unpaid_fine_detected", false) == true
    unpaid_fine := object.get(input.kks, "unpaid_fine_pln", 0)
    daily_rate := object.get(input.jdg_entrepreneur, "kks_daily_rate_pln", 150)
    substitute_days_raw := floor(unpaid_fine / max([daily_rate * 2, 112]))  # min 2 stawki na dzień = 112 PLN
    substitute_days := min([substitute_days_raw, 360])  # max 360 dni
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  K160-K169: Art. 16 KKS — CZYNNY ŻAL (VOLUNTARY DISCLOSURE)             ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# ── K160: voluntary_disclosure_guide — Praktyczny przewodnik czynnego żalu ──
else := {
    "matched": true, "rule_id": "jdg.kks.voluntary_disclosure_guide",
    "package": "jdg.kks.enterprise_penalties", "priority": 160,
    "kks_vd_available": true,
    "kks_vd_conditions": ["ZŁÓŻ_ZANIM_US_WYKRYJE", "WPŁAĆ_ZALEGŁOŚĆ_W_7_DNI", "WSKAŻ_ISTOTNE_OKOLICZNOŚCI"],
    "kks_vd_effect": "CAŁKOWITA_BEZKARNOŚĆ",
    "kks_vd_how_to": vd_howto,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 16 § 1-8 ustawy z dnia 10 września 1999 r. — Kodeks karny skarbowy (Dz.U. 2025 poz. 678, ze zm.)",
    "_warnings": [sprintf("CZYNNY ŻAL (Art. 16 KKS) — TWOJA NAJLEPSZA OBRONA! Skutek: CAŁKOWITA BEZKARNOŚĆ za przestępstwo/wykroczenie skarbowe. JAK ZŁOŻYĆ: (1) Złóż pisemne zawiadomienie do US właściwego dla opodatkowania (osobiście/listem poleconym/PUE), (2) WSKAŻ istotne okoliczności czynu (co, kiedy, ile), (3) WPŁAĆ całą zaległość + odsetki w 7 DNI od złożenia zawiadomienia, (4) %s. UWAGA: czynny żal NIESKUTECZNY jeśli US już wykryło naruszenie lub wszczęto kontrolę!", [vd_timing])]
} {
    object.get(input.kks, "voluntary_disclosure_eligible", false) == true
    is_pre_audit := object.get(input.kks, "is_before_audit_start", true)
    can_use_vd := is_pre_audit
    vd_howto := vd_howto_for(can_use_vd)
    vd_timing := vd_timing_for(can_use_vd)
}

# ── K161: voluntary_disclosure_deadline — Czynny żal — termin 7 dni na wpłatę ──
else := {
    "matched": true, "rule_id": "jdg.kks.voluntary_disclosure_deadline",
    "package": "jdg.kks.enterprise_penalties", "priority": 161,
    "kks_vd_payment_deadline_days": 7,
    "kks_vd_amount_due_pln": amount_due,
    "kks_vd_days_remaining": days_remaining,
    "sanction_type": "KKS", "sanction_severity": severity,
    "_routing": vd_rt,
    "_routing_reason": sprintf("Czynny żal — wpłać %.2f PLN w ciągu %d dni (pozostało %d)", [amount_due, 7, days_remaining]),
    "_legal_basis": "Art. 16 § 2 ustawy z dnia 10 września 1999 r. — Kodeks karny skarbowy (Dz.U. 2025 poz. 678, ze zm.)",
    "_warnings": [sprintf("CZYNNY ŻAL — TERMIN WPŁATY. Złozono: %s. Kwota do wpłaty: %.2f PLN. Termin 7 dni od złożenia zawiadomienia. %s. Przekroczenie terminu = NIESKUTECZNY czynny żal = PEŁNA ODPOWIEDZIALNOŚĆ KKS!", [filing_date, amount_due, vd_urgency])]
} {
    object.get(input.kks, "voluntary_disclosure_filed", false) == true
    object.get(input.kks, "voluntary_disclosure_paid", false) == false
    amount_due := object.get(input.kks, "vd_amount_due", 0)
    days_since := object.get(input.kks, "vd_days_since_filing", 0)
    days_remaining := max([0, 7 - days_since])
    filing_date := object.get(input.kks, "vd_filing_date", "nieznana")
    vd_urgency := vd_urgency_for(days_remaining)
    severity := vd_deadline_severity_for(days_remaining)
    vd_rt := vd_deadline_route_for(days_remaining)
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  K170-K179: PRZEDAWNIENIE / PRZERWANIE / ZATARCIE (Art. 20-21, 44 KKS)  ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# ── K170: statute_of_limitations_table — Tabela przedawnień KKS ──
else := {
    "matched": true, "rule_id": "jdg.kks.statute_of_limitations_table",
    "package": "jdg.kks.enterprise_penalties", "priority": 170,
    "kks_statute_misdemeanor_years": 3,
    "kks_statute_crime_years": 5,
    "kks_statute_max_extension_years": 10,
    "kks_offense_date": offense_date,
    "kks_statute_expiry_date": expiry_date,
    "kks_is_expired": is_expired,
    "_routing": statute_rt,
    "_routing_reason": sprintf("Przedawnienie KKS: %s — termin %s", [offense_type, expiry_date]),
    "_legal_basis": "Art. 20 § 1-3, Art. 44 § 1-5 KKS",
    "_warnings": [sprintf("PRZEDAWNIENIE KARALNOŚCI KKS — %s. Czyn z %s. Przedawnienie: %s. Status: %s. Zasady: (1) Wykroczenia = 3 lata, (2) Przestępstwa = 5 lat, (3) Maksymalne przedłużenie = +5 lat (łącznie 10), (4) Przerwanie biegu przez każdą czynność organu (postanowienie, przesłuchanie), (5) Zatarcie skazania: 3 lata od wykonania kary dla wykroczeń, 5 lat dla przestępstw.", [offense_type, offense_date, expiry_date, expired_note])]
} {
    object.get(input.kks, "statute_check_requested", false) == true
    offense_type := object.get(input.kks, "offense_classification", "WYKROCZENIE")
    offense_date := object.get(input.kks, "offense_date", "2023-01-01")
    base_years := statute_base_years_for(offense_type)
    has_extension := object.get(input.kks, "statute_extension_applied", false)
    extension_years := statute_extension_years_for(has_extension)
    total_years := base_years + extension_years
    expiry_date := sprintf("202%d-01-01", [2023 + total_years])
    is_expired := 2026 >= 2023 + total_years
    expired_note := statute_expired_note_for(is_expired, total_years)
    statute_rt := statute_route_for(is_expired)
}

# ── K171: rehabilitation_period — Okres zatarcia skazania KKS ──
else := {
    "matched": true, "rule_id": "jdg.kks.rehabilitation_period",
    "package": "jdg.kks.enterprise_penalties", "priority": 171,
    "kks_conviction_date": conviction_date,
    "kks_rehabilitation_years": rehab_years,
    "kks_rehabilitation_date": rehab_date,
    "kks_is_rehabilitated": is_rehab,
    "_routing": "",
    "_routing_reason": sprintf("Zatarcie skazania: %s — %d lat od wykonania kary", [rehab_status, rehab_years]),
    "_legal_basis": "Art. 21 § 1-4 ustawy z dnia 10 września 1999 r. — Kodeks karny skarbowy (Dz.U. 2025 poz. 678, ze zm.)",
    "_warnings": [sprintf("ZATARCIE SKAZANIA KKS — %s. Skazanie z %s. Okres zatarcia: %d lat od wykonania/wykonania kary. Data zatarcia: %s. Po zatarciu: (1) Skazanie uważa się za niebyłe, (2) Można legalnie oświadczać o niekaralności, (3) Nie ma wpływu na zamówienia publiczne po okresie.", [rehab_status, conviction_date, rehab_years, rehab_date])]
} {
    object.get(input.kks, "rehabilitation_check_requested", false) == true
    conviction_type := object.get(input.kks, "conviction_type", "WYKROCZENIE")
    conviction_date := object.get(input.kks, "conviction_date", "2023-01-01")
    penalty_completed := object.get(input.kks, "penalty_completed_date", "2023-06-01")
    rehab_years := rehab_years_for(conviction_type)
    rehab_date := sprintf("202%d-06-01", [2023 + rehab_years])
    is_rehab := 2026 >= 2023 + rehab_years
    rehab_status := rehab_status_for(is_rehab, rehab_years)
}

# ═══════════════════════════════════════════════════════════════════════════════
# FALLBACK
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true, "rule_id": "jdg.kks.enterprise.fallback",
    "package": "jdg.kks.enterprise_penalties", "priority": 999,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Kodeks Karny Skarbowy",
    "_warnings": ["KKS — brak wykrytych naruszeń. Prowadź dokumentację rzetelnie, składaj deklaracje terminowo, płać podatki w terminie."]
} {
    true
}
