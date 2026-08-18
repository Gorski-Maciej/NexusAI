# Generated from Plan OPA 45 — Hyper Granularity rules
# 2026-07-13 18:15:03
# Rules: 21

package jdg.hyper.family

default decide := {"matched":false,"rule_id":"jdg.hyper.family.no_match","package":"jdg.hyper.family","priority":99999}

# jdg.hyper.family.audit.representation.access_to_files — Pełnomocnik
decide :=   {"matched":true,"rule_id":"jdg.hyper.family.audit.representation.access_to_files","_legal_basis":"Art. 178 Ordynacji podatkowej (Dz.U. 2025 poz. 234, ze zm.)","_warnings":["Prawo wglądu w akta sprawy"]} {
    object.get(input.vendor, "relation_to_entrepreneur", "") != ""
}

# jdg.hyper.family.audit.representation.participation_rights — Pełnomocnik
else :=   {"matched":true,"rule_id":"jdg.hyper.family.audit.representation.participation_rights","_legal_basis":"Art. 138e Ordynacji podatkowej (Dz.U. 2025 poz. 234, ze zm.)","_warnings":["Udział we wszystkich czynnościach kontrolnych"]} {
    object.get(input.vendor, "relation_to_entrepreneur", "") != ""
}

# jdg.hyper.family.audit.cross_border.mutual_assistance — Transgraniczne
else :=   {"matched":true,"rule_id":"jdg.hyper.family.audit.cross_border.mutual_assistance","_legal_basis":"Art. 86-87 Ordynacji podatkowej (Dz.U. 2025 poz. 234, ze zm.), DAC","_warnings":["Współpraca z organami innych krajów UE"]} {
    object.get(input.vendor, "relation_to_entrepreneur", "") != ""
}

# jdg.hyper.family.audit.cross_border.simultaneous_audit — Transgraniczne
else :=   {"matched":true,"rule_id":"jdg.hyper.family.audit.cross_border.simultaneous_audit","_legal_basis":"Art. 86-87 Ordynacji podatkowej (Dz.U. 2025 poz. 234, ze zm.)","_warnings":["Kontrola jednoczesna w kilku krajach UE"]} {
    object.get(input.vendor, "relation_to_entrepreneur", "") != ""
}

# jdg.hyper.family.audit.cross_border.presence_foreign_officials — Transgraniczne
else :=   {"matched":true,"rule_id":"jdg.hyper.family.audit.cross_border.presence_foreign_officials","_legal_basis":"Art. 87 Ordynacji podatkowej (Dz.U. 2025 poz. 234, ze zm.)","_warnings":["Udział zagranicznych kontrolerów w kontroli w PL"]} {
    object.get(input.vendor, "relation_to_entrepreneur", "") != ""
}

# jdg.hyper.family.audit.closure.decision_issuance — Zamknięcie
else :=   {"matched":true,"rule_id":"jdg.hyper.family.audit.closure.decision_issuance","_legal_basis":"Art. 207-208 Ordynacji podatkowej (Dz.U. 2025 poz. 234, ze zm.)","_warnings":["Decyzja wymiarowa po zakończeniu kontroli"]} {
    object.get(input.vendor, "relation_to_entrepreneur", "") != ""
}

# jdg.hyper.family.audit.closure.decision_deadline — Zamknięcie
else :=   {"matched":true,"rule_id":"jdg.hyper.family.audit.closure.decision_deadline","_legal_basis":"Art. 208 Ordynacji podatkowej (Dz.U. 2025 poz. 234, ze zm.)","_warnings":["Decyzja wydawana bez zbędnej zwłoki"]} {
    object.get(input.vendor, "relation_to_entrepreneur", "") != ""
}

# jdg.hyper.family.audit.closure.correction_window — Zamknięcie
else :=   {"matched":true,"rule_id":"jdg.hyper.family.audit.closure.correction_window","_legal_basis":"Art. 81 Ordynacji podatkowej (Dz.U. 2025 poz. 234, ze zm.)","_warnings":["Możliwość korekty po zakończeniu kontroli"]} {
    object.get(input.vendor, "relation_to_entrepreneur", "") != ""
}

# jdg.hyper.family.audit.follow_up.recommendations — Post-kontrola
else :=   {"matched":true,"rule_id":"jdg.hyper.family.audit.follow_up.recommendations","_legal_basis":"Art. 291-292 Ordynacji podatkowej (Dz.U. 2025 poz. 234, ze zm.)","_warnings":["Zalecenia pokontrolne do wdrożenia"]} {
    object.get(input.vendor, "relation_to_entrepreneur", "") != ""
}

# jdg.hyper.family.audit.follow_up.deadline_monitoring — Post-kontrola
else :=   {"matched":true,"rule_id":"jdg.hyper.family.audit.follow_up.deadline_monitoring","_legal_basis":"Art. 292 Ordynacji podatkowej (Dz.U. 2025 poz. 234, ze zm.)","_warnings":["Monitoring terminów wdrożenia zaleceń"]} {
    object.get(input.vendor, "relation_to_entrepreneur", "") != ""
}

# jdg.hyper.family.audit.aggregate.risk_score_update — Agregacja
else :=   {"matched":true,"rule_id":"jdg.hyper.family.audit.aggregate.risk_score_update","_legal_basis":"Art. 119b Ordynacji podatkowej (Dz.U. 2025 poz. 234, ze zm.)","_warnings":["Aktualizacja profilu ryzyka po kontroli — profil wpływa na częstotliwość przyszłych kontroli"]} {
    object.get(input.vendor, "relation_to_entrepreneur", "") != ""
}

# jdg.hyper.family.force_majeure.event.detection — Detekcja
else :=   {"matched":true,"rule_id":"jdg.hyper.family.force_majeure.event.detection","_legal_basis":"Art. 67a Ordynacji podatkowej (Dz.U. 2025 poz. 234, ze zm.)","_warnings":["Identyfikacja zdarzenia siły wyższej: powódź, pożar, pandemia, wojna"]} {
    object.get(input.vendor, "relation_to_entrepreneur", "") != ""
}

# jdg.hyper.family.force_majeure.event.flood — Detekcja
else :=   {"matched":true,"rule_id":"jdg.hyper.family.force_majeure.event.flood","_legal_basis":"Art. 67a Ordynacji podatkowej (Dz.U. 2025 poz. 234, ze zm.)","_warnings":["Powódź → katalog ulg podatkowych i ZUS"]} {
    object.get(input.vendor, "relation_to_entrepreneur", "") != ""
}

# jdg.hyper.family.force_majeure.event.fire — Detekcja
else :=   {"matched":true,"rule_id":"jdg.hyper.family.force_majeure.event.fire","_legal_basis":"Art. 67a Ordynacji podatkowej (Dz.U. 2025 poz. 234, ze zm.)","_warnings":["Pożar → katalog ulg podatkowych"]} {
    object.get(input.vendor, "relation_to_entrepreneur", "") != ""
}

# jdg.hyper.family.force_majeure.event.pandemic — Detekcja
else :=   {"matched":true,"rule_id":"jdg.hyper.family.force_majeure.event.pandemic","_legal_basis":"Art. 67a Ordynacji podatkowej (Dz.U. 2025 poz. 234, ze zm.)","_warnings":["Pandemia/epidemia → katalog ulg"]} {
    object.get(input.vendor, "relation_to_entrepreneur", "") != ""
}

# jdg.hyper.family.force_majeure.event.war_effects — Detekcja
else :=   {"matched":true,"rule_id":"jdg.hyper.family.force_majeure.event.war_effects","_legal_basis":"Art. 67a Ordynacji podatkowej (Dz.U. 2025 poz. 234, ze zm.)","_warnings":["Skutki działań wojennych → katalog ulg"]} {
    object.get(input.vendor, "relation_to_entrepreneur", "") != ""
}

# jdg.hyper.family.force_majeure.event.natural_disaster_other — Detekcja
else :=   {"matched":true,"rule_id":"jdg.hyper.family.force_majeure.event.natural_disaster_other","_legal_basis":"Art. 67a Ordynacji podatkowej (Dz.U. 2025 poz. 234, ze zm.)","_warnings":["Inna klęska żywiołowa → katalog ulg"]} {
    object.get(input.vendor, "relation_to_entrepreneur", "") != ""
}

# jdg.hyper.family.force_majeure.relief.tax_deferral — Ulga podatkowa
else :=   {"matched":true,"rule_id":"jdg.hyper.family.force_majeure.relief.tax_deferral","_legal_basis":"Art. 67a § 1 pkt 1 Ordynacji podatkowej (Dz.U. 2025 poz. 234, ze zm.)","_warnings":["Odroczenie terminu płatności podatku"]} {
    object.get(input.vendor, "relation_to_entrepreneur", "") != ""
}

# jdg.hyper.family.force_majeure.relief.tax_installments — Ulga podatkowa
else :=   {"matched":true,"rule_id":"jdg.hyper.family.force_majeure.relief.tax_installments","_legal_basis":"Art. 67a § 1 pkt 2 Ordynacji podatkowej (Dz.U. 2025 poz. 234, ze zm.)","_warnings":["Rozłożenie na raty"]} {
    object.get(input.vendor, "relation_to_entrepreneur", "") != ""
}

# jdg.hyper.family.force_majeure.relief.tax_remission — Ulga podatkowa
else :=   {"matched":true,"rule_id":"jdg.hyper.family.force_majeure.relief.tax_remission","_legal_basis":"Art. 67a § 1 pkt 3 Ordynacji podatkowej (Dz.U. 2025 poz. 234, ze zm.)","_warnings":["Umorzenie zaległości w całości lub części"]} {
    object.get(input.vendor, "relation_to_entrepreneur", "") != ""
}

# jdg.hyper.family.force_majeure.relief.tax_suspension — Ulga podatkowa
else :=   {"matched":true,"rule_id":"jdg.hyper.family.force_majeure.relief.tax_suspension","_legal_basis":"Art. 67a § 1 Ordynacji podatkowej (Dz.U. 2025 poz. 234, ze zm.)","_warnings":["Zaniechanie poboru podatku na podstawie rozporządzenia MF"]} {
    object.get(input.vendor, "relation_to_entrepreneur", "") != ""
}
