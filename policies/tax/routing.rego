# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI Tax Policies — Field Confidence & Routing Rules (P10-P19)
# ═══════════════════════════════════════════════════════════════════════════════
#
# Reguły sprawdzające pewność pól OCR (field confidence).
# Niska pewność → routing BLOCK_AND_ALERT lub TRIAGE_QUEUE.
# Priorytet po risk, przed compliance/merytorycznymi.
#
# Wzorzec: FINOS OpenEAGO — Composite Risk Scoring + hard-stop thresholds.
#
# package: tax.routing
# rule:     decide (first-match-wins else chain)
# ═══════════════════════════════════════════════════════════════════════════════

package tax.routing

import data.tax.helpers

# ── Default: no match ─────────────────────────────────────────────────────────
default decide := {
    "matched": false,
    "rule_id": "tax.routing.no_match",
    "package": "tax.routing",
    "priority": 19
}

# ═══════════════════════════════════════════════════════════════════════════════
# P10: fc_vat_rate_low — CIT_STANDARD (Priority 10)
# ═══════════════════════════════════════════════════════════════════════════════
# Cel biznesowy: Niska pewność stawki VAT → blokada automatycznego księgowania
# Przesłanki: CIT_STANDARD + fc_vat_rate < próg + fc_vat_rate > 0
# Podstawa prawna: Art. 22 UoR (rzetelność ksiąg)

# ── P10: fc_vat_rate_low ──────────────────────────────────────────────────────
# Cel biznesowy: Niska pewność stawki VAT dla CIT_STANDARD → BLOCK_AND_ALERT
# Przesłanki: tax_form == CIT_STANDARD AND fc_vat_rate < threshold
# Podstawa prawna: Art. 22 UoR (rzetelność ksiąg)
# Priorytet: 10
# ────────────────────────────────────────────────────────────────────────────────
decide := {
    "matched": true,
    "rule_id": "tax.routing.fc_vat_rate_low",
    "package": "tax.routing",
    "priority": 10,
    "vat_rate": "",
    "rounding_level": "",
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": helpers.build_routing_reason(
        input.company.tax_form,
        "VAT rate",
        input.confidence.fc_vat_rate,
        object.get(input.thresholds.fc_thresholds, "cit_standard_vat_rate", 0.98)
    ),
    "_legal_basis": "Art. 22 UoR (rzetelność ksiąg)"
} {
    input.company.tax_form == "CIT_STANDARD"
    input.confidence.fc_vat_rate < object.get(input.thresholds.fc_thresholds, "cit_standard_vat_rate", 0.98)
    input.confidence.fc_vat_rate > 0
}

# ═══════════════════════════════════════════════════════════════════════════════
# P12: fc_vendor_nip_low — Universal (Priority 12)
# ═══════════════════════════════════════════════════════════════════════════════
# Cel biznesowy: Niska pewność NIP kontrahenta → problem z Białą Listą
# Przesłanki: fc_vendor_nip < próg uniwersalny + fc_vendor_nip > 0
# Podstawa prawna: Art. 96b VAT (Biała Lista), Art. 22 UoR

# ── P12: fc_vendor_nip_low ────────────────────────────────────────────────────
# Cel biznesowy: Niska pewność NIP → BLOCK_AND_ALERT
# Przesłanki: fc_vendor_nip < vendor_nip threshold AND fc_vendor_nip > 0
# Podstawa prawna: Art. 96b VAT (Biała Lista), Art. 22 UoR
# Priorytet: 12
# ────────────────────────────────────────────────────────────────────────────────
else := {
    "matched": true,
    "rule_id": "tax.routing.fc_vendor_nip_low",
    "package": "tax.routing",
    "priority": 12,
    "vat_rate": "",
    "rounding_level": "",
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": helpers.build_routing_reason(
        "UNIVERSAL",
        "Vendor NIP",
        input.confidence.fc_vendor_nip,
        object.get(input.thresholds.fc_thresholds, "vendor_nip", 0.80)
    ),
    "_legal_basis": "Art. 96b VAT (Biała Lista), Art. 22 UoR"
} {
    input.confidence.fc_vendor_nip < object.get(input.thresholds.fc_thresholds, "vendor_nip", 0.80)
    input.confidence.fc_vendor_nip > 0
}
