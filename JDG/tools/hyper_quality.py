#!/usr/bin/env python3
# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — HYPER PLAN45 / KONTEKSTY / KALENDARZ — Quality Gate (GLM52 P16)
# Linter + kanonizacja _legal_basis (naprawa UNKNOWN_ACT — ~100 reguł hyper
# z podstawami „Art. X OP" / placeholderami R-XXXX / „Przepisy prawa podatkowego")
# + wykrywanie martwych fallbacków {true} (INV-018) + konfliktów pakietów
# + duplikatów rule_id. Kanony (LEGAL_REFERENCE_CANON / kampania GLM52):
# PIT Dz.U. 2024 poz. 1760 · VAT 2024 poz. 1557 · OP 2025 poz. 234 ·
# KKS 2025 poz. 678 · SUS 2025 poz. 345 · u.ś.o.z. 2025 poz. 890 ·
# PP 2025 poz. 123 · CEIDG 2025 poz. 456 · UoR 2025 poz. 567 ·
# akcyza 2025 poz. 1220 · AML 2025 poz. 213 · ryczałt 2025 poz. 234 ·
# KAS 2025 poz. 108 · sukcesja 2025 poz. 1234 · PPSA 2025 poz. 861.
# ═══════════════════════════════════════════════════════════════════════════════
import argparse
import re
from collections import Counter
from pathlib import Path

JDG_ROOT = Path(__file__).resolve().parents[1]

FILES = [
    "rules/jdg/hyper/general/plan45.rego",
    "rules/jdg/hyper/deadlines/plan45.rego",
    "rules/jdg/hyper/limits/plan45.rego",
    "rules/jdg/hyper/sanctions/plan45.rego",
    "rules/jdg/hyper/audit/plan45.rego",
    "rules/jdg/hyper/edelivery/plan45.rego",
    "rules/jdg/hyper/family/plan45.rego",
    "rules/jdg/hyper/force_majeure/plan45.rego",
    "rules/jdg/hyper/fx/plan45.rego",
    "rules/jdg/hyper/mdr/plan45.rego",
    "rules/jdg/hyper/procurement/plan45.rego",
    "rules/jdg/hyper/solidarity/plan45.rego",
    "rules/jdg/hyper/wis/plan45.rego",
    "rules/jdg/hyper/misc/plan45.rego",
    "rules/hyper_plan45_meta_enterprise.rego",
    "rules/deadline_monitor_enterprise.rego",
    "rules/calendar_notifier_enterprise.rego",
    "rules/calendar/plan45_calendar.rego",
    "rules/r13_hyper_konteksty_innovations_v9.rego",
]

# ── Kanoniczne nazwy aktów (repo-confirmed) ──────────────────────────────────
PIT24 = "ustawy z dnia 26 lipca 1991 r. o podatku dochodowym od osób fizycznych (Dz.U. 2024 poz. 1760 ze zm.)"
VAT24 = "ustawy z dnia 11 marca 2004 r. o podatku od towarów i usług (Dz.U. 2024 poz. 1557 ze zm.)"
OP25 = "Ordynacji podatkowej (Dz.U. 2025 poz. 234, ze zm.)"
KKS25 = "ustawy z dnia 10 września 1999 r. — Kodeks karny skarbowy (Dz.U. 2025 poz. 678, ze zm.)"
SUS25 = "ustawy z dnia 13 października 1998 r. o systemie ubezpieczeń społecznych (Dz.U. 2025 poz. 345, ze zm.)"
ZDR25 = "ustawy z dnia 27 sierpnia 2004 r. o świadczeniach opieki zdrowotnej finansowanych ze środków publicznych (Dz.U. 2025 poz. 890)"
PP25 = "ustawy z dnia 6 marca 2018 r. — Prawo przedsiębiorców (Dz.U. 2025 poz. 123)"
CEIDG25 = "ustawy z dnia 6 marca 2018 r. o Centralnej Ewidencji i Informacji o Działalności Gospodarczej i Punkcie Informacji dla Przedsiębiorcy (Dz.U. 2025 poz. 456)"
UoR25 = "ustawy z dnia 29 września 1994 r. o rachunkowości (Dz.U. 2025 poz. 567, ze zm.)"
AKC25 = "ustawy z dnia 6 grudnia 2008 r. o podatku akcyzowym (Dz.U. 2025 poz. 1220)"
AML25 = "ustawy z dnia 1 marca 2018 r. o przeciwdziałaniu praniu pieniędzy oraz finansowaniu terroryzmu (Dz.U. 2025 poz. 213)"
RYC25 = "ustawy z dnia 20 listopada 1998 r. o zryczałtowanym podatku dochodowym od niektórych przychodów osiąganych przez osoby fizyczne (Dz.U. 2025 poz. 234 ze zm.)"
KAS25 = "ustawy z dnia 16 listopada 2016 r. o Krajowej Administracji Skarbowej (Dz.U. 2025 poz. 108, ze zm.)"
SUK25 = "ustawy z dnia 5 lipca 2018 r. o zarządzie sukcesyjnym przedsiębiorstwem osoby fizycznej (Dz.U. 2025 poz. 1234)"
PPSA25 = "ustawy z dnia 30 sierpnia 2002 r. — Prawo o postępowaniu przed sądami administracyjnymi (Dz.U. 2025 poz. 861, ze zm.)"
RODO = "rozporządzenia Parlamentu Europejskiego i Rady (UE) 2016/679 (RODO)"
EIDAS = "rozporządzenia Parlamentu Europejskiego i Rady (UE) nr 910/2014 z dnia 23 lipca 2014 r. w sprawie identyfikacji elektronicznej i usług zaufania (eIDAS)"
# Akty bez potwierdzonego w repo Dz.U. — pełna nazwa aktu (kanon v1.0 bez numeru)
KC = "ustawy z dnia 23 kwietnia 1964 r. — Kodeks cywilny"
KK = "ustawy z dnia 6 czerwca 1997 r. — Kodeks karny"
SD = "ustawy z dnia 28 lipca 1983 r. o podatku od spadków i darowizn"
UDE = "ustawy z dnia 18 listopada 2020 r. o doręczeniach elektronicznych"
UUP = "ustawy z dnia 19 sierpnia 2011 r. o usługach płatniczych"
UTD = "ustawy z dnia 6 września 2001 r. o transporcie drogowym"
UDP = "ustawy z dnia 5 lipca 1996 r. o doradztwie podatkowym"
UZL = "ustawy z dnia 5 grudnia 1996 r. o zawodach lekarza i lekarza dentysty"
UWIP = "ustawy z dnia 9 marca 2017 r. o wymianie informacji podatkowych z innymi państwami"
UOB = "ustawy z dnia 22 maja 2003 r. o ubezpieczeniach obowiązkowych, Ubezpieczeniowym Funduszu Gwarancyjnym i Polskim Biurze Ubezpieczycieli Komunikacyjnych"
PEA = "ustawy z dnia 17 czerwca 1966 r. o postępowaniu egzekucyjnym w administracji"
PU = "ustawy z dnia 28 lutego 2003 r. — Prawo upadłościowe"
PB = "ustawy z dnia 29 sierpnia 1997 r. — Prawo bankowe"
PZP = "ustawy z dnia 11 września 2019 r. — Prawo zamówień publicznych"
UJP = "ustawy z dnia 7 października 1999 r. o języku polskim"
UINF = "ustawy z dnia 17 lutego 2005 r. o informatyzacji działalności podmiotów realizujących zadania publiczne"
UZAW = "ustaw regulujących wykonywanie zawodów regulowanych"

# ── Skróty → kanon (kolejność: pełne frazy przed skrótami) ───────────────────
_LIT = [
    ("OrdPU", OP25),
    ("u.s.u.s.", SUS25),
    ("u.ś.o.z.", ZDR25),
    ("u.z.p.d.", RYC25),
    ("ustawy zdrowotnej", ZDR25),
    ("ustawy o akcyzie", AKC25),
    ("Ustawa o podatku akcyzowym", AKC25),
    ("ustawy o zarządzie sukcesyjnym", SUK25),
    ("Ustawa o doręczeniach elektronicznych", UDE),
    ("Ustawa o doręczeniach el.", UDE),
    ("Ustawa o usługach płatniczych", UUP),
    ("Ustawa o transporcie drogowym", UTD),
    ("Ustawa o doradztwie podatkowym", UDP),
    ("Ustawa o zawodzie lekarza", UZL),
    ("Ustawa o wymianie informacji podatkowych", UWIP),
    ("Ustawy o post. egz.", PEA),
    ("Prawa upadłościowego", PU),
    ("Prawa bankowego", PB),
    ("ustawy o języku polskim", UJP),
    ("Ustawy o SD, Art. 4a", f"Art. 4a {SD}"),
    ("Ustawy o SD", SD),
    ("ustawy o SD", SD),
    ("ustawy o podatku od spadków i darowizn", SD),
]
_ABBR = [
    ("KKS", KKS25),
    ("PIT", PIT24),
    ("VAT", VAT24),
    ("SUS", SUS25),
    ("CEIDG", CEIDG25),
    ("UoR", UoR25),
    ("AML", AML25),
    ("KAS", KAS25),
    ("PZP", PZP),
    ("PPSA", PPSA25),
    ("PCC", "ustawy z dnia 9 września 2000 r. o podatku od czynności cywilnoprawnych (Dz.U. 2025 poz. 789)"),
    ("CIT", "ustawy z dnia 15 lutego 1992 r. o podatku dochodowym od osób prawnych"),
    ("OP", OP25),
    ("PP", PP25),
    ("KC", KC),
    ("KK", KK),
]

# ── Reguły specjalne: rule_id → kanoniczna podstawa (naprawa UNKNOWN_ACT) ────
R23_10 = f"Art. 23 ust. 1 pkt 10 {PIT24}"
R14_1 = f"Art. 14 ust. 1 {PIT24}"
R144b = f"Art. 144b {OP25}"
R281_292 = f"Art. 281-292 {OP25}"

RULE_BASIS = {
    # ── audit / WIA (akcyza) ──
    "jdg.hyper.audit.wia.eligibility.excise_goods": f"Art. 7d {AKC25}",
    "jdg.hyper.audit.wia.validity.3_years": f"Art. 7d {AKC25}",
    "jdg.hyper.audit.wia.cost.250_pln": f"Art. 7d {AKC25}",
    # ── deadlines / insurance ──
    "jdg.hyper.deadlines.insurance.mandatory.detection_construction": f"Art. 4 {UOB}",
    "jdg.hyper.deadlines.insurance.mandatory.detection_transport": UTD,
    "jdg.hyper.deadlines.insurance.mandatory.detection_tax_advisor": UDP,
    "jdg.hyper.deadlines.insurance.gap.detection_mandatory_missing": UOB,
    "jdg.hyper.deadlines.insurance.gap.detection_sum_insufficient": UOB,
    "jdg.hyper.deadlines.insurance.gap.detection_policy_expiring": UOB,
    # ── deadlines / payment ──
    "jdg.hyper.deadlines.payment.crypto.volatility_risk_warning": AML25,
    "jdg.hyper.deadlines.payment.offset.when_recognized": f"Art. 498 {KC}, Art. 14 ust. 1 {PIT24}",
    "jdg.hyper.deadlines.payment.offset.mutual_agreement_required": f"Art. 498-499 {KC}",
    "jdg.hyper.deadlines.tax.edelivery_pickup_14days": R144b,
    # ── edelivery / force_majeure ──
    "jdg.hyper.edelivery.force_majeure.documents.electronic_preservation": f"Art. 86 § 2 {OP25}",
    "jdg.hyper.edelivery.force_majeure.insurance.cover_check": R14_1,
    "jdg.hyper.edelivery.force_majeure.insurance.claim_procedure": R14_1,
    "jdg.hyper.edelivery.force_majeure.suspension.automatic": f"Art. 22 {PP25}",
    "jdg.hyper.edelivery.force_majeure.suspension.tax_consequences": f"Art. 44 ust. 6b {PIT24}",
    "jdg.hyper.edelivery.force_majeure.suspension.zus_consequences": f"Art. 36a {SUS25}",
    "jdg.hyper.edelivery.force_majeure.loss.enhanced_deduction": f"Art. 9 ust. 3 {PIT24}",
    "jdg.hyper.edelivery.force_majeure.loss.carry_back": f"Art. 9 ust. 3 {PIT24}",
    "jdg.hyper.edelivery.force_majeure.aggregate.impact_assessment": f"Art. 67a {OP25}",
    # ── edelivery / family.spouse ──
    "jdg.hyper.edelivery.family.spouse.employment.kup_conditions": R23_10,
    "jdg.hyper.edelivery.family.spouse.qualifications_check": R23_10,
    "jdg.hyper.edelivery.family.spouse.salary_above_market_red_flag": R23_10,
    "jdg.hyper.edelivery.family.spouse.no_work_evidence_nkup": R23_10,
    "jdg.hyper.edelivery.family.spouse.market_benchmark_test": R23_10,
    "jdg.hyper.edelivery.family.spouse.work_evidence_required": R23_10,
    "jdg.hyper.edelivery.family.spouse.no_qualifications_red_flag": R23_10,
    # ── force_majeure / audit ──
    "jdg.hyper.force_majeure.audit.right.record_activities": f"Art. 286 § 3 {OP25}",
    "jdg.hyper.force_majeure.audit.right.oppose_inspection": f"Art. 84c {PP25}",
    "jdg.hyper.force_majeure.audit.right.appeal_14_days": f"Art. 223 {OP25}",
    "jdg.hyper.force_majeure.audit.right.wsa_complaint_30_days": f"Art. 220 {PPSA25}",
    "jdg.hyper.force_majeure.audit.obligation.provide_documents": R281_292,
    "jdg.hyper.force_majeure.audit.obligation.provide_explanations": R281_292,
    "jdg.hyper.force_majeure.audit.obligation.retain_audit_docs": f"Art. 86 {OP25}",
    "jdg.hyper.force_majeure.audit.obligation.allow_inspection": R281_292,
    "jdg.hyper.force_majeure.audit.obligation.sign_protocol": f"Art. 291 {OP25}",
    "jdg.hyper.force_majeure.audit.statute.suspension_effect": f"Art. 70 § 6 {OP25}",
    "jdg.hyper.force_majeure.audit.statute.suspension_duration": f"Art. 70 § 6 {OP25}",
    "jdg.hyper.force_majeure.audit.statute.resume_after_close": f"Art. 70 § 6 {OP25}",
    "jdg.hyper.force_majeure.audit.penalty.obstruction_fine_5000": f"Art. 262 {OP25}",
    "jdg.hyper.force_majeure.audit.penalty.obstruction_kks_art69": f"Art. 69 {KKS25}",
    "jdg.hyper.force_majeure.audit.penalty.coercion_measures": f"Art. 151 {OP25}",
    "jdg.hyper.force_majeure.audit.document.seizure_receipt": f"Art. 288 {OP25}",
    "jdg.hyper.force_majeure.audit.document.seizure_duration": f"Art. 288 {OP25}",
    # ── fx / e-US / ePUAP / e-Doręczenia ──
    "jdg.hyper.fx.edelivery.monitoring.alert_3_days": R144b,
    "jdg.hyper.fx.eus.platform.required": KAS25,
    "jdg.hyper.fx.eus.platform.declarations_status": KAS25,
    "jdg.hyper.fx.eus.platform.mandates_management": f"Art. 138a-138o {OP25}",
    "jdg.hyper.fx.eus.platform.incoming_letters_check": R144b,
    "jdg.hyper.fx.eus.platform.payment_history": f"Art. 51-56 {OP25}",
    "jdg.hyper.fx.eus.platform.certificates": f"Art. 306g {OP25}",
    "jdg.hyper.fx.epuap.profile.required": f"Art. 20a {UINF}",
    "jdg.hyper.fx.epuap.submission.confirmation_upo": f"Art. 20d {UINF}",
    "jdg.hyper.fx.epuap.signature.profile_zaufany": f"Art. 20a {UINF}",
    "jdg.hyper.fx.epuap.submission.timestamp": f"Art. 20d {UINF}",
    "jdg.hyper.fx.electronic.delivery.address.update_obligation": R144b,
    "jdg.hyper.fx.electronic.delivery.sanction.outdated_address": R144b,
    "jdg.hyper.fx.electronic.communication.retention.5_years": f"Art. 86 § 1 {OP25}",
    "jdg.hyper.fx.electronic.communication.encryption_requirements": f"Art. 193a {OP25}",
    "jdg.hyper.fx.electronic.communication.evidence_value": f"Art. 193a {OP25}",
    "jdg.hyper.fx.electronic.communication.data_breach_notification": f"Art. 33 {RODO}",
    # ── general / procurement / family.SD / calendar ──
    "jdg.hyper.general.family.succession.sd_z2_deadline_6months": f"Art. 4a {SD}",
    "jdg.hyper.procurement.family.asset.transfer.gift_to_spouse": f"Art. 4a {SD}",
    "jdg.hyper.procurement.family.asset.transfer.gift_to_children": f"Art. 4a {SD}",
    "jdg.calendar.hyper.forecast_annual_tax": f"Art. 44-45 {PIT24}, Art. 46 {SUS25}",
    "jdg.calendar.hyper.forecast_history_trend": f"Art. 44-45 {PIT24}, Art. 46 {SUS25}",
    "jdg.calendar.hyper.forecast_cash_flow_warning": f"Art. 44-45 {PIT24}, Art. 46 {SUS25}",
    "jdg.calendar.hyper.forecast_next_quarter": f"Art. 44-45 {PIT24}, Art. 46 {SUS25}",
    # ── general / cross-border / kks.conviction / regulated ──
    "jdg.hyper.general.cross_border.eidas.recognition": EIDAS,
    "jdg.hyper.general.cross_border.crs.fatca.reporting": UWIP,
    "jdg.hyper.general.cross_border.dac.directives.compliance": "Dyrektyw Rady 2011/16/UE (DAC1-DAC8) w sprawie współpracy administracyjnej w dziedzinie opodatkowania",
    "jdg.hyper.general.kks.conviction.credit_score_impact": f"Art. 105 {PB}",
    "jdg.hyper.general.kks.conviction.fintech_access_restriction": AML25,
    "jdg.hyper.general.kks.conviction.cash_transaction_monitoring": AML25,
    "jdg.hyper.general.kks.conviction.tax_office_scrutiny_increased": f"Art. 119b {OP25}",
    "jdg.hyper.general.regulated.cross_border.non_eu_qualifications": UZAW,
    "jdg.hyper.general.regulated.cross_border.double_taxation_specialist": "umów o unikaniu podwójnego opodatkowania (UPO)",
    "jdg.hyper.general.regulated.aggregate.profession_specific_risk_profile": f"Art. 119b {OP25}",
    "jdg.hyper.general.regulated.aggregate.annual_compliance_checklist": UZAW,
    "jdg.hyper.general.insurance.mandatory.detection_medical": UZL,
    # ── limits / seasonal / kks.conviction ──
    "jdg.hyper.limits.seasonal.aggregate.annual_summary_pit_zus": f"Art. 44 {PIT24}, Art. 46 {SUS25}",
    "jdg.hyper.limits.seasonal.aggregate.comparison_normal_vs_seasonal": f"Art. 44 {PIT24}",
    "jdg.hyper.limits.seasonal.aggregate.optimal_strategy": f"Art. 44 {PIT24}",
    "jdg.hyper.limits.kks.conviction.regulated_profession_consequences": UZAW,
    # ── misc / payment ──
    "jdg.hyper.misc.payment.foreign.swift_sepa_authorization": "ustawy z dnia 27 lipca 2002 r. — Prawo dewizowe",
    "jdg.hyper.misc.payment.terminal.obligation_20k_eur_turnover": UUP,
    "jdg.hyper.misc.payment.terminal.sanction_no_terminal_5000": UUP,
    # ── procurement / family ──
    "jdg.hyper.procurement.family.cooperation.pit_treatment": R23_10,
    "jdg.hyper.procurement.family.car.usage.mileage_log_family": f"Art. 23 ust. 1 pkt 46 {PIT24}",
    "jdg.hyper.procurement.family.asset.transfer.sale_arm_length": R14_1,
    "jdg.hyper.procurement.family.asset.transfer.pcc_exemption": f"Art. 4a {SD}",
    "jdg.hyper.procurement.family.joint_filing.conditions": f"Art. 6 ust. 2 {PIT24}",
    "jdg.hyper.procurement.family.joint_filing.benefit_calculation": f"Art. 6 ust. 2 {PIT24}",
    "jdg.hyper.procurement.family.joint_filing.exclusions": f"Art. 6 ust. 2 {PIT24}",
    "jdg.hyper.procurement.family.joint_filing.deadline_april30": f"Art. 45 ust. 1 {PIT24}",
    "jdg.hyper.procurement.family.single_parent.child_custody_required": f"Art. 6 ust. 4 {PIT24}",
    "jdg.hyper.procurement.family.single_parent.preferential_calculation": f"Art. 6 ust. 4 {PIT24}",
    "jdg.hyper.procurement.family.health_insurance.kup_deduction": f"Art. 23 ust. 1 pkt 58 {PIT24}",
    "jdg.hyper.procurement.family.health_insurance.family_members": f"Art. 66 {ZDR25}",
    "jdg.hyper.procurement.family.pit11.deadline_feb28": f"Art. 39 ust. 1 {PIT24}",
    "jdg.hyper.procurement.family.pit4r.obligation": f"Art. 38 ust. 1a {PIT24}",
    "jdg.hyper.procurement.family.succession.planning_inheritance": f"Art. 4a {SD}",
    # ── sanctions ──
    "jdg.hyper.sanctions.kks.conviction.business_partner_trust_loss": f"Art. 105a {VAT24}",
    "jdg.hyper.sanctions.kks.conviction.contract_termination_clauses": KC,
    "jdg.hyper.sanctions.kks.rehabilitation.tax_office_notification": f"Art. 119b {OP25}",
    "jdg.hyper.sanctions.regulated.chamber.membership_mandatory": UZAW,
    "jdg.hyper.sanctions.regulated.chamber.disciplinary_proceedings": UZAW,
    "jdg.hyper.sanctions.regulated.chamber.license_suspension_consequences": UZAW,
    "jdg.hyper.sanctions.regulated.chamber.practice_certificate_renewal": UZAW,
    "jdg.hyper.sanctions.aggregate_sanction_risk_score": f"Art. 54-56 {KKS25}, Art. 112b-112c {VAT24}",
    # ── solidarity ──
    "jdg.hyper.solidarity.solidarity.levy.zus.health.no_exclusion": f"Art. 30h ust. 2 {PIT24}",
    "jdg.hyper.solidarity.solidarity.levy.payment.no_advances": f"Art. 30h ust. 6 {PIT24}",
}

# ── Wzorce niekanoniczne (bramka) ────────────────────────────────────────────
BAD_RE = [
    re.compile(r"^Przepisy prawa podatkowego"),
    re.compile(r"^—$"),
    re.compile(r"^Ustawy branżowe$"),
    re.compile(r"^Ustawy korporacyjne$"),
    re.compile(r"^Praktyka$"),
    re.compile(r"^Praktyka US$"),
    re.compile(r"^BIK,"),
    re.compile(r"^GIIF$"),
    re.compile(r"^Polityki fintechów$"),
    re.compile(r"^Umowy UPO$"),
    re.compile(r"^Dyrektywy DAC"),
    re.compile(r"^Rozp\. eIDAS"),
    re.compile(r"^KC —"),
    re.compile(r"^R\d+$"),
    re.compile(r"^P\d+$"),
    re.compile(r"^Ustawa o (SD|podatku od spadków|podatku akcyzowym|doradztwie podatkowym|transporcie drogowym|doręczeniach el\.|usługach płatniczych|wymianie informacji podatkowych|zawodzie lekarza)"),
    re.compile(r"^Art\. \d+ PIT, KC$"),
    re.compile(r"^Art\. 498 KC \+"),
    re.compile(r"^Art\. 498-499 KC$"),
    re.compile(r"^Art\. 648 KC$"),
    re.compile(r"^Art\. 14 PIT, KC$"),
    re.compile(r"^Sprzedaż majątku"),
    re.compile(r"^Brak dowodów"),
    re.compile(r"^Nagrywanie czynności"),
    re.compile(r"^Sprzeciw wobec kontroli"),
    re.compile(r"^Odwołanie od decyzji"),
    re.compile(r"^Wszczęcie kontroli"),
    re.compile(r"^Utrudnianie"),
    re.compile(r"^Środki przymusu"),
    re.compile(r"^Zatrzymanie dokumentów"),
    re.compile(r"^[A-Za-z]+\d+$"),
]

DEAD_FALLBACK_RE = re.compile(r"\}\s*\{\s*true\s*\}\s*$")
TRUE_END_RE = re.compile(r"\}\s*\{\s*true\s*\}\s*$")
FALLBACK_COMMENT_RE = re.compile(r"^#\s*── Fallback ──")
ELSE_START_RE = re.compile(r"^else\s*:?=\s*\{")


def _desc_basis(value: str) -> str:
    """„opis (Art. X ABBR)" → „Art. X <kanon ABBR>"."""
    m = re.search(r"\(Art\. ([^)]+)\)\s*$", value)
    if m:
        return "Art. " + m.group(1)
    return value


def canonicalize_basis(value: str, rule_id: str) -> str:
    if rule_id in RULE_BASIS:
        return RULE_BASIS[rule_id]
    v = _desc_basis(value.strip())
    for old, new in _LIT:
        v = v.replace(old, new)
    for abbr, canon in _ABBR:
        v = re.sub(r"(?<![A-Za-z0-9_])" + re.escape(abbr) + r"(?![A-Za-z0-9_])", canon, v)
    return v


def analyze_file(rel: str) -> dict:
    path = JDG_ROOT / rel
    if not path.exists():
        return {"file": rel, "error": "missing"}
    text = path.read_text(encoding="utf-8")
    lines = text.split("\n")
    rids = re.findall(r'"rule_id"\s*:\s*"([^"]+)"', text)
    lbs = re.findall(r'"_legal_basis"\s*:\s*"([^"]*)"', text)
    matched_true = len(re.findall(r'"matched"\s*:\s*true', text))
    dead = [(i, "fallback {true} — martwa reguła (INV-018)") for i, ln in enumerate(lines, 1)
            if DEAD_FALLBACK_RE.search(ln) and "if {" not in ln]
    bad = [lb for lb in set(lbs) if any(p.match(lb.strip()) for p in BAD_RE)]
    return {
        "file": rel,
        "rule_count": len(rids),
        "unique_rule_ids": len(set(rids)),
        "matched_true": matched_true,
        "legal_basis_count": len(lbs),
        "legal_basis_bad": bad,
        "dead": dead,
    }


def fix_file(rel: str) -> int:
    path = JDG_ROOT / rel
    if not path.exists():
        return 0
    text = path.read_text(encoding="utf-8")
    orig = text
    n = 0

    def _repl(m: re.Match) -> str:
        nonlocal n
        rid = m.group(1)
        lb = m.group(2)
        canon = canonicalize_basis(lb, rid)
        if canon != lb:
            n += 1
        return f'"rule_id":"{rid}","_legal_basis":"{canon}"'

    # Pass 1: rule_id przed _legal_basis (także w werdyktach wielolinijkowych — re.S;
    # tolerancja na spację po dwukropku: "_legal_basis": "...")
    text = re.sub(r'"rule_id":"([^"]+)"[^}]*?"_legal_basis"\s*:\s*"([^"]*)"', _repl, text, flags=re.S)
    # Pass 2: rule_id PO _legal_basis (wielolinijkowe werdykty — wzorzec calendar/plan45)
    for rid in sorted(RULE_BASIS, key=len, reverse=True):
        canon = RULE_BASIS[rid]
        text = re.sub(
            r'"_legal_basis"\s*:\s*"[^"]*"(?=[^}]*"' + re.escape(rid) + r'")',
            f'"_legal_basis":"{canon}"',
            text,
            flags=re.S,
        )
    if text != orig:
        path.write_text(text, encoding="utf-8")
    return n


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--fix", action="store_true")
    ap.add_argument("--gate", action="store_true")
    ap.add_argument("--json", action="store_true")
    args = ap.parse_args()

    if args.fix:
        for rel in FILES:
            n = fix_file(rel)
            if n:
                print(f"[FIX] {rel}: {n} podstaw skanonizowanych")

    errors, warnings = [], []
    all_ids = Counter()
    reports = []
    for rel in FILES:
        rep = analyze_file(rel)
        reports.append(rep)
        if rep.get("error"):
            errors.append(f"{rel}: {rep['error']}")
            continue
        path = JDG_ROOT / rel
        for rid in re.findall(r'"rule_id"\s*:\s*"([^"]+)"', path.read_text(encoding="utf-8")):
            all_ids[rid] += 1
        for lb in rep["legal_basis_bad"]:
            errors.append(f"{rel}: niekanoniczny _legal_basis: {lb[:80]}")
        for i, d in rep["dead"]:
            errors.append(f"{rel}:{i}: {d}")

    pkg_defaults: dict[str, list[str]] = {}
    for rel in FILES:
        path = JDG_ROOT / rel
        if not path.exists():
            continue
        text = path.read_text(encoding="utf-8")
        m = re.search(r"^package\s+([\w.]+)", text, re.M)
        if m and re.search(r"^default\s+decide", text, re.M):
            pkg_defaults.setdefault(m.group(1), []).append(rel)
    for pkg, files in sorted(pkg_defaults.items()):
        if len(files) > 1:
            errors.append(f"KONFLIKT PAKIETU {pkg}: 2× default decide w {', '.join(files)}")

    dups = [rid for rid, c in all_ids.items() if c > 1 and not rid.endswith(".no_match")]
    for rid in dups:
        errors.append(f"zdublowany rule_id: {rid}")

    if args.gate or args.json:
        import json
        out = {
            "status": "PASS" if not errors else "FAIL",
            "errors": errors[:60],
            "warnings": warnings[:60],
            "duplicates": len(dups),
            "files": len([r for r in reports if not r.get("error")]),
            "rules_total": sum(r.get("rule_count", 0) for r in reports),
            "rules_unique": len(all_ids),
            "legal_basis_total": sum(r.get("legal_basis_count", 0) for r in reports),
        }
        if args.json:
            print(json.dumps(out, ensure_ascii=False, indent=1))
        if args.gate:
            for r in reports:
                if r.get("error"):
                    print(f"  {r['file']}: MISSING")
                    continue
                print(f"  {r['file']}: reguł={r['rule_count']} (uniq {r['unique_rule_ids']}) "
                      f"matched={r['matched_true']} legal_basis={r['legal_basis_count']} "
                      f"bad={len(r['legal_basis_bad'])} dead={len(r['dead'])}")
            print(f"BRAMKA: {'PASS' if not errors else 'FAIL'}")
            print(f"  błędów: {len(errors)} · duplikatów: {len(dups)} · "
                  f"reguł: {sum(r.get('rule_count', 0) for r in reports)}")
            return 0 if not errors else 1


if __name__ == "__main__":
    raise SystemExit(main())
