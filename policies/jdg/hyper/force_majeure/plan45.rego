# Generated from Plan OPA 45 — Hyper Granularity rules
# 2026-07-13 18:15:03
# Rules: 21

package jdg.hyper.force_majeure

default decide := {"matched":false,"rule_id":"jdg.hyper.force_majeure.no_match","package":"jdg.hyper.force_majeure","priority":99999}

# jdg.hyper.force_majeure.audit.right.record_activities — Prawo JDG
decide :=   {"matched":true,"rule_id":"jdg.hyper.force_majeure.audit.right.record_activities","_legal_basis":"Art. 286 § 3 Ordynacji podatkowej (Dz.U. 2025 poz. 234, ze zm.)","_warnings":[]} {
    object.get(input.jdg_entrepreneur, "force_majeure_declared", false) == true
}

# jdg.hyper.force_majeure.audit.right.break_request — Prawo JDG
else :=   {"matched":true,"rule_id":"jdg.hyper.force_majeure.audit.right.break_request","_legal_basis":"Art. 286 Ordynacji podatkowej (Dz.U. 2025 poz. 234, ze zm.)","_warnings":["Przerwa w kontroli — max 3 dni robocze"]} {
    object.get(input.jdg_entrepreneur, "force_majeure_declared", false) == true
}

# jdg.hyper.force_majeure.audit.right.oppose_inspection — Prawo JDG
else :=   {"matched":true,"rule_id":"jdg.hyper.force_majeure.audit.right.oppose_inspection","_legal_basis":"Art. 84c ustawy z dnia 6 marca 2018 r. — Prawo przedsiębiorców (Dz.U. 2025 poz. 123)","_warnings":[]} {
    object.get(input.jdg_entrepreneur, "force_majeure_declared", false) == true
}

# jdg.hyper.force_majeure.audit.right.correction_in_minus_blocked — Prawo JDG
else :=   {"matched":true,"rule_id":"jdg.hyper.force_majeure.audit.right.correction_in_minus_blocked","_legal_basis":"Art. 81b Ordynacji podatkowej (Dz.U. 2025 poz. 234, ze zm.)","_warnings":["Korekta na korzyść blokowana podczas kontroli"]} {
    object.get(input.jdg_entrepreneur, "force_majeure_declared", false) == true
}

# jdg.hyper.force_majeure.audit.right.correction_in_plus_allowed — Prawo JDG
else :=   {"matched":true,"rule_id":"jdg.hyper.force_majeure.audit.right.correction_in_plus_allowed","_legal_basis":"Art. 81b Ordynacji podatkowej (Dz.U. 2025 poz. 234, ze zm.)","_warnings":["Korekta na korzyść blokowana podczas kontroli"]} {
    object.get(input.jdg_entrepreneur, "force_majeure_declared", false) == true
}

# jdg.hyper.force_majeure.audit.right.right_to_be_heard — Prawo JDG
else :=   {"matched":true,"rule_id":"jdg.hyper.force_majeure.audit.right.right_to_be_heard","_legal_basis":"Art. 200 Ordynacji podatkowej (Dz.U. 2025 poz. 234, ze zm.)","_warnings":["Prawo do wypowiedzenia przed decyzją"]} {
    object.get(input.jdg_entrepreneur, "force_majeure_declared", false) == true
}

# jdg.hyper.force_majeure.audit.right.appeal_14_days — Prawo JDG
else :=   {"matched":true,"rule_id":"jdg.hyper.force_majeure.audit.right.appeal_14_days","_legal_basis":"Art. 223 Ordynacji podatkowej (Dz.U. 2025 poz. 234, ze zm.)","_warnings":[]} {
    object.get(input.jdg_entrepreneur, "force_majeure_declared", false) == true
}

# jdg.hyper.force_majeure.audit.right.wsa_complaint_30_days — Prawo JDG
else :=   {"matched":true,"rule_id":"jdg.hyper.force_majeure.audit.right.wsa_complaint_30_days","_legal_basis":"Art. 220 ustawy z dnia 30 sierpnia 2002 r. — Prawo o postępowaniu przed sądami administracyjnymi (Dz.U. 2025 poz. 861, ze zm.)","_warnings":[]} {
    object.get(input.jdg_entrepreneur, "force_majeure_declared", false) == true
}

# jdg.hyper.force_majeure.audit.obligation.provide_documents — Obowiązek JDG
else :=   {"matched":true,"rule_id":"jdg.hyper.force_majeure.audit.obligation.provide_documents","_legal_basis":"Art. 281-292 Ordynacji podatkowej (Dz.U. 2025 poz. 234, ze zm.)","_warnings":[]} {
    object.get(input.jdg_entrepreneur, "force_majeure_declared", false) == true
}

# jdg.hyper.force_majeure.audit.obligation.allow_inspection — Obowiązek JDG
else :=   {"matched":true,"rule_id":"jdg.hyper.force_majeure.audit.obligation.allow_inspection","_legal_basis":"Art. 281-292 Ordynacji podatkowej (Dz.U. 2025 poz. 234, ze zm.)","_warnings":[]} {
    object.get(input.jdg_entrepreneur, "force_majeure_declared", false) == true
}

# jdg.hyper.force_majeure.audit.obligation.provide_explanations — Obowiązek JDG
else :=   {"matched":true,"rule_id":"jdg.hyper.force_majeure.audit.obligation.provide_explanations","_legal_basis":"Art. 281-292 Ordynacji podatkowej (Dz.U. 2025 poz. 234, ze zm.)","_warnings":[]} {
    object.get(input.jdg_entrepreneur, "force_majeure_declared", false) == true
}

# jdg.hyper.force_majeure.audit.obligation.sign_protocol — Obowiązek JDG
else :=   {"matched":true,"rule_id":"jdg.hyper.force_majeure.audit.obligation.sign_protocol","_legal_basis":"Art. 291 Ordynacji podatkowej (Dz.U. 2025 poz. 234, ze zm.)","_warnings":[]} {
    object.get(input.jdg_entrepreneur, "force_majeure_declared", false) == true
}

# jdg.hyper.force_majeure.audit.obligation.retain_audit_docs — Obowiązek JDG
else :=   {"matched":true,"rule_id":"jdg.hyper.force_majeure.audit.obligation.retain_audit_docs","_legal_basis":"Art. 86 Ordynacji podatkowej (Dz.U. 2025 poz. 234, ze zm.)","_warnings":[]} {
    object.get(input.jdg_entrepreneur, "force_majeure_declared", false) == true
}

# jdg.hyper.force_majeure.audit.statute.suspension_effect — Przedawnienie
else :=   {"matched":true,"rule_id":"jdg.hyper.force_majeure.audit.statute.suspension_effect","_legal_basis":"Art. 70 § 6 Ordynacji podatkowej (Dz.U. 2025 poz. 234, ze zm.)","_warnings":[]} {
    object.get(input.jdg_entrepreneur, "force_majeure_declared", false) == true
}

# jdg.hyper.force_majeure.audit.statute.suspension_duration — Przedawnienie
else :=   {"matched":true,"rule_id":"jdg.hyper.force_majeure.audit.statute.suspension_duration","_legal_basis":"Art. 70 § 6 Ordynacji podatkowej (Dz.U. 2025 poz. 234, ze zm.)","_warnings":[]} {
    object.get(input.jdg_entrepreneur, "force_majeure_declared", false) == true
}

# jdg.hyper.force_majeure.audit.statute.resume_after_close — Przedawnienie
else :=   {"matched":true,"rule_id":"jdg.hyper.force_majeure.audit.statute.resume_after_close","_legal_basis":"Art. 70 § 6 Ordynacji podatkowej (Dz.U. 2025 poz. 234, ze zm.)","_warnings":[]} {
    object.get(input.jdg_entrepreneur, "force_majeure_declared", false) == true
}

# jdg.hyper.force_majeure.audit.penalty.obstruction_fine_5000 — Sankcja
else :=   {"matched":true,"rule_id":"jdg.hyper.force_majeure.audit.penalty.obstruction_fine_5000","_legal_basis":"Art. 262 Ordynacji podatkowej (Dz.U. 2025 poz. 234, ze zm.)","_warnings":[]} {
    object.get(input.jdg_entrepreneur, "force_majeure_declared", false) == true
}

# jdg.hyper.force_majeure.audit.penalty.obstruction_kks_art69 — Sankcja
else :=   {"matched":true,"rule_id":"jdg.hyper.force_majeure.audit.penalty.obstruction_kks_art69","_legal_basis":"Art. 69 ustawy z dnia 10 września 1999 r. — Kodeks karny skarbowy (Dz.U. 2025 poz. 678, ze zm.)","_warnings":[]} {
    object.get(input.jdg_entrepreneur, "force_majeure_declared", false) == true
}

# jdg.hyper.force_majeure.audit.penalty.coercion_measures — Sankcja
else :=   {"matched":true,"rule_id":"jdg.hyper.force_majeure.audit.penalty.coercion_measures","_legal_basis":"Art. 151 Ordynacji podatkowej (Dz.U. 2025 poz. 234, ze zm.)","_warnings":[]} {
    object.get(input.jdg_entrepreneur, "force_majeure_declared", false) == true
}

# jdg.hyper.force_majeure.audit.document.seizure_receipt — Dokumenty
else :=   {"matched":true,"rule_id":"jdg.hyper.force_majeure.audit.document.seizure_receipt","_legal_basis":"Art. 288 Ordynacji podatkowej (Dz.U. 2025 poz. 234, ze zm.)","_warnings":[]} {
    object.get(input.jdg_entrepreneur, "force_majeure_declared", false) == true
}

# jdg.hyper.force_majeure.audit.document.seizure_duration — Dokumenty
else :=   {"matched":true,"rule_id":"jdg.hyper.force_majeure.audit.document.seizure_duration","_legal_basis":"Art. 288 Ordynacji podatkowej (Dz.U. 2025 poz. 234, ze zm.)","_warnings":[]} {
    object.get(input.jdg_entrepreneur, "force_majeure_declared", false) == true
}
