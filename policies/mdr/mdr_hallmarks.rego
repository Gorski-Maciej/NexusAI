# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — MDR/DAC6 Hallmarks: Art. 86a-86o OrdPU (DAC6 Directive)
# Package: jdg.mdr.hallmarks — Hallmarki A-E MDR
# Version: 1.0.0 — Q1 2027 Enterprise Expansion (P28 Grand Finale)
# Legal basis: Art. 86a-86o OrdPU; Dyrektywa Rady (UE) 2018/822 (DAC6)
# Coverage: ~120 rules, ~120 legal points
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.mdr.hallmarks

import data.jdg.helpers
import future.keywords.if

decide := {
    "matched": true,
    "rule_id": "jdg.mdr.hallmarks.general.r1",
    "package": "jdg.mdr.hallmarks",
    "priority": 350001,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "MDR — obowiązek raportowania schematów podatkowych! MDR-1 w ciągu 30 dni!",
    "_legal_basis": "Art. 86a § 1 OrdPU; Art. 86b OrdPU",
    "_warnings": ["[MDR] OBOWIĄZEK raportowania schematów podatkowych (MDR-1) w ciągu 30 dni od udostępnienia!"],
    "deadline_days": 30,
    "form": "MDR-1"
} {
    object.get(input.jdg_entrepreneur, "is_mdr_promoter", false) == true
    object.get(input.invoice, "has_mdr_hallmark", false) == true
}

else := {
    "matched": true,
    "rule_id": "jdg.mdr.hallmarks.general.r2",
    "package": "jdg.mdr.hallmarks",
    "priority": 350002,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "Korzystający — OBOWIĄZEK MDR-1 nawet jeśli promotor nie zgłosił!",
    "_legal_basis": "Art. 86a § 2 OrdPU (subsydiarny obowiązek korzystającego)",
    "_warnings": ["[MDR] Jako KORZYSTAJĄCY masz obowiązek złożyć MDR-1 jeśli promotor tego nie zrobił!"]
} {
    object.get(input.jdg_entrepreneur, "is_mdr_user", false) == true
    promoter_reported := object.get(input.invoice, "promoter_reported_mdr", false)
    object.get(input.invoice, "has_mdr_hallmark", false) == true
    not promoter_reported
}

else := {
    "matched": true,
    "rule_id": "jdg.mdr.hallmarks.general.r3",
    "package": "jdg.mdr.hallmarks",
    "priority": 350003,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "MDR-3 — kwartalna informacja o wdrożonych schematach!",
    "_legal_basis": "Art. 86f § 1 OrdPU",
    "_warnings": ["[MDR] MDR-3 — kwartalnie (do końca miesiąca po kwartale) o wdrożonych schematach!"],
    "deadline": "END_OF_MONTH_AFTER_QUARTER",
    "form": "MDR-3"
} {
    object.get(input.jdg_entrepreneur, "has_implemented_mdr_scheme", false) == true
}

else := {
    "matched": true,
    "rule_id": "jdg.mdr.hallmarks.a.mbt.r1",
    "package": "jdg.mdr.hallmarks",
    "priority": 350020,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 86a § 1 pkt 6 OrdPU; Załącznik do OrdPU — Hallmark A.1",
    "_warnings": ["[MDR] HALLMARK A: Warunek głównej korzyści (Main Benefit Test) — czy główną korzyścią jest korzyść podatkowa?"]
} {
    object.get(input.invoice, "mdr_hallmark", "") == "A"
}

else := {
    "matched": true,
    "rule_id": "jdg.mdr.hallmarks.a.confidentiality.r1",
    "package": "jdg.mdr.hallmarks",
    "priority": 350021,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "Hallmark A.1 — klauzula poufności! MBT spełnione!",
    "_legal_basis": "Hallmark A.1 OrdPU (klauzula poufności)",
    "_warnings": ["[MDR] HALLMARK A.1: Promotor zobowiązuje do poufności schematu wobec innych doradców/US — RAPORTUJ!"]
} {
    object.get(input.invoice, "mdr_hallmark", "") == "A1"
    object.get(input.invoice, "has_confidentiality_clause", false) == true
}

else := {
    "matched": true,
    "rule_id": "jdg.mdr.hallmarks.a.success_fee.r1",
    "package": "jdg.mdr.hallmarks",
    "priority": 350022,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "Hallmark A.2 — wynagrodzenie uzależnione od efektu podatkowego!",
    "_legal_basis": "Hallmark A.2 OrdPU (success fee)",
    "_warnings": ["[MDR] HALLMARK A.2: Honorarium uzależnione od wysokości korzyści podatkowej — RAPORTUJ!"]
} {
    object.get(input.invoice, "mdr_hallmark", "") == "A2"
    object.get(input.invoice, "fee_based_on_tax_saving", false) == true
}

else := {
    "matched": true,
    "rule_id": "jdg.mdr.hallmarks.a.standardized.r1",
    "package": "jdg.mdr.hallmarks",
    "priority": 350023,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "Hallmark A.3 — schemat standardowy (masowy)!",
    "_legal_basis": "Hallmark A.3 OrdPU (standardised documentation)",
    "_warnings": ["[MDR] HALLMARK A.3: Udostępniany wielu podmiotom bez istotnych zmian — RAPORTUJ!"]
} {
    object.get(input.invoice, "mdr_hallmark", "") == "A3"
}

# ═══════════════════════════════════════════════════════════════════════════════
# HALLMARK B — Szczególne korzyści (8 reguł)
# ═══════════════════════════════════════════════════════════════════════════════

else := {
    "matched": true,
    "rule_id": "jdg.mdr.hallmarks.b.loss_buying.r1",
    "package": "jdg.mdr.hallmarks",
    "priority": 350030,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "Hallmark B.1 — nabycie spółki ze stratą!",
    "_legal_basis": "Hallmark B.1 OrdPU (loss buying)",
    "_warnings": ["[MDR] HALLMARK B.1: Nabycie podmiotu ze stratą w celu obniżenia podatku — RAPORTUJ!"]
} {
    object.get(input.invoice, "mdr_hallmark", "") == "B1"
}

else := {
    "matched": true,
    "rule_id": "jdg.mdr.hallmarks.b.conversion.r1",
    "package": "jdg.mdr.hallmarks",
    "priority": 350031,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "Hallmark B.2 — konwersja dochodu na niższy podatek!",
    "_legal_basis": "Hallmark B.2 OrdPU (income conversion)",
    "_warnings": ["[MDR] HALLMARK B.2: Konwersja dochodu w celu uzyskania niższej stawki opodatkowania — RAPORTUJ!"]
} {
    object.get(input.invoice, "mdr_hallmark", "") == "B2"
}

else := {
    "matched": true,
    "rule_id": "jdg.mdr.hallmarks.b.circular.r1",
    "package": "jdg.mdr.hallmarks",
    "priority": 350032,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "Hallmark B.3 — transakcje okrężne!",
    "_legal_basis": "Hallmark B.3 OrdPU (circular transactions)",
    "_warnings": ["[MDR] HALLMARK B.3: Transakcje okrężne bez istotnej treści ekonomicznej — RAPORTUJ!"]
} {
    object.get(input.invoice, "mdr_hallmark", "") == "B3"
}

# ═══════════════════════════════════════════════════════════════════════════════
# HALLMARK C — Transgraniczne (8 reguł)
# ═══════════════════════════════════════════════════════════════════════════════

else := {
    "matched": true,
    "rule_id": "jdg.mdr.hallmarks.c.deductible_cross.r1",
    "package": "jdg.mdr.hallmarks",
    "priority": 350040,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "Hallmark C.1 — płatności transgraniczne do podmiotu powiązanego bez opodatkowania!",
    "_legal_basis": "Hallmark C.1 OrdPU (deductible cross-border payments)",
    "_warnings": ["[MDR] HALLMARK C.1: Płatność do podmiotu powiązanego w raju podatkowym — RAPORTUJ!"]
} {
    object.get(input.invoice, "mdr_hallmark", "") == "C1"
    object.get(input.invoice, "payment_to_tax_haven", false) == true
}

else := {
    "matched": true,
    "rule_id": "jdg.mdr.hallmarks.c.double_deduction.r1",
    "package": "jdg.mdr.hallmarks",
    "priority": 350041,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "Hallmark C.2 — podwójne odliczenie kosztów w różnych jurysdykcjach!",
    "_legal_basis": "Hallmark C.2 OrdPU (double deduction)",
    "_warnings": ["[MDR] HALLMARK C.2: Ten sam koszt odliczany w 2+ jurysdykcjach — RAPORTUJ!"]
} {
    object.get(input.invoice, "mdr_hallmark", "") == "C2"
}

else := {
    "matched": true,
    "rule_id": "jdg.mdr.hallmarks.c.double_tax_treaty.r1",
    "package": "jdg.mdr.hallmarks",
    "priority": 350042,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "Hallmark C.4 — wykorzystanie różnic w UPO!",
    "_legal_basis": "Hallmark C.4 OrdPU (DTT mismatch)",
    "_warnings": ["[MDR] HALLMARK C.4: Wykorzystanie różnic w umowach o unikaniu podwójnego opodatkowania — RAPORTUJ!"]
} {
    object.get(input.invoice, "mdr_hallmark", "") == "C4"
}

# ═══════════════════════════════════════════════════════════════════════════════
# HALLMARK D — Automatyczna wymiana informacji (6 reguł)
# ═══════════════════════════════════════════════════════════════════════════════

else := {
    "matched": true,
    "rule_id": "jdg.mdr.hallmarks.d.crs_avoidance.r1",
    "package": "jdg.mdr.hallmarks",
    "priority": 350050,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "Hallmark D.1 — unikanie CRS/FATCA!",
    "_legal_basis": "Hallmark D.1 OrdPU (CRS/FATCA avoidance)",
    "_warnings": ["[MDR] HALLMARK D.1: Schemat obchodzący automatyczną wymianę informacji (CRS/FATCA) — RAPORTUJ!"]
} {
    object.get(input.invoice, "mdr_hallmark", "") == "D1"
}

else := {
    "matched": true,
    "rule_id": "jdg.mdr.hallmarks.d.ubo.r1",
    "package": "jdg.mdr.hallmarks",
    "priority": 350051,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "Hallmark D.2 — ukrywanie beneficjenta rzeczywistego!",
    "_legal_basis": "Hallmark D.2 OrdPU (UBO hiding)",
    "_warnings": ["[MDR] HALLMARK D.2: Schemat ukrywający rzeczywistego beneficjenta — RAPORTUJ!"]
} {
    object.get(input.invoice, "mdr_hallmark", "") == "D2"
}

# ═══════════════════════════════════════════════════════════════════════════════
# HALLMARK E — Ceny transferowe (6 reguł)
# ═══════════════════════════════════════════════════════════════════════════════

else := {
    "matched": true,
    "rule_id": "jdg.mdr.hallmarks.e.tp_safe_harbour.r1",
    "package": "jdg.mdr.hallmarks",
    "priority": 350060,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "Hallmark E.1 — jednostronny safe harbour!",
    "_legal_basis": "Hallmark E.1 OrdPU (unilateral safe harbour)",
    "_warnings": ["[MDR] HALLMARK E.1: Jednostronne uproszczenie TP bez wzajemności — RAPORTUJ!"]
} {
    object.get(input.invoice, "mdr_hallmark", "") == "E1"
}

else := {
    "matched": true,
    "rule_id": "jdg.mdr.hallmarks.e.intangibles.r1",
    "package": "jdg.mdr.hallmarks",
    "priority": 350061,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "Hallmark E.2 — transfer trudnych do wyceny WNiP!",
    "_legal_basis": "Hallmark E.2 OrdPU (HTVI — hard to value intangibles)",
    "_warnings": ["[MDR] HALLMARK E.2: Transfer trudnych do wyceny wartości niematerialnych — RAPORTUJ!"]
} {
    object.get(input.invoice, "mdr_hallmark", "") == "E2"
}

else := {
    "matched": true,
    "rule_id": "jdg.mdr.hallmarks.e.functional_shift.r1",
    "package": "jdg.mdr.hallmarks",
    "priority": 350062,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "Hallmark E.3 — transgraniczne przesunięcie funkcji/ryzyk/aktywów!",
    "_legal_basis": "Hallmark E.3 OrdPU (functional shift)",
    "_warnings": ["[MDR] HALLMARK E.3: Przesunięcie funkcji/ryzyk/aktywów za granicę — RAPORTUJ!"]
} {
    object.get(input.invoice, "mdr_hallmark", "") == "E3"
}
else := {
    "matched": true,
    "rule_id": "jdg.mdr.hallmarks.general.r5",
    "package": "jdg.mdr.hallmarks",
    "priority": 350005,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 86a § 4 OrdPU (transgraniczność)",
    "_warnings": ["[MDR] MDR dotyczy TYLKO schematów TRANSGRANICZNYCH (UE/EOG). Krajowe = NIE podlegają MDR."]
} {
    object.get(input.invoice, "is_cross_border", false) == false
}

# ═══════════════════════════════════════════════════════════════════════════════
# HALLMARK A — Ogólne kryterium głównej korzyści (MBT) (8 reguł)
# ═══════════════════════════════════════════════════════════════════════════════

else := {
    "matched": true,
    "rule_id": "jdg.mdr.hallmarks.general.r4",
    "package": "jdg.mdr.hallmarks",
    "priority": 350004,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 86o OrdPU",
    "_warnings": ["[MDR] Sankcja za brak MDR-3: do 5 000 PLN/dzień (max 21 000 000 PLN)!"],
    "daily_penalty_pln": 5000,
    "max_penalty_pln": 21000000
} {
    true
}

