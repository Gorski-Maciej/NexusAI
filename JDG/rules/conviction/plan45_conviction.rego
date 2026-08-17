# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG Policies — jdg.conviction hyper-granularity (Doc 45: R1546-R1575)
# Atom rules: KKS conviction impacts, banking, tax office, business partners,
#   rehabilitation, enforcement
# Rules: 30 atom — each with differentiated trigger conditions
# ═══════════════════════════════════════════════════════════════════════════════
package jdg.conviction.hyper
import data.jdg.helpers

default decide := {"matched":false,"rule_id":"jdg.conviction.hyper.no_match","package":"jdg.conviction.hyper","priority":99999}

# ══ R1546-R1550: Professional Consequences ══
decide := {"matched":true,"rule_id":"jdg.conviction.hyper.business_ban_art41kk","package":"jdg.conviction.hyper","priority":1546,"_routing":"BLOCK_AND_ALERT","_routing_reason":"KKS: zakaz prowadzenia działalności","_legal_basis":"Art. 41 KK","_warnings":["Skazanie KKS z zakazem prowadzenia działalności — NIE możesz prowadzić JDG!"],"valid_from":"1998-09-01","valid_to":null,"decision_mode":"SUGGEST"} {
    object.get(input.jdg_entrepreneur, "business_ban_active", false) == true
}
else := {"matched":true,"rule_id":"jdg.conviction.hyper.license_revocation","package":"jdg.conviction.hyper","priority":1547,"_routing":"BLOCK_AND_ALERT","_routing_reason":"KKS: utrata licencji zawodowej","_legal_basis":"Art. 41 KK","_warnings":["Skazanie KKS — ryzyko utraty licencji zawodowej (doradca podatkowy, adwokat)"]} {
    object.get(input.jdg_entrepreneur, "kks_conviction_active", false) == true
    object.get(input.jdg_entrepreneur, "has_professional_license", false) == true
}
else := {"matched":true,"rule_id":"jdg.conviction.hyper.public_procurement_exclusion","package":"jdg.conviction.hyper","priority":1548,"_routing":"BLOCK_AND_ALERT","_routing_reason":"KKS: wykluczenie z zamówień publicznych","_legal_basis":"Art. 108 PZP","_warnings":["Skazanie KKS — wykluczenie z zamówień publicznych przez 5 lat od zatarcia"]} {
    object.get(input.jdg_entrepreneur, "kks_conviction_active", false) == true
    object.get(input.jdg_entrepreneur, "public_procurement_interested", false) == true
}
else := {"matched":true,"rule_id":"jdg.conviction.hyper.eu_funds_exclusion","package":"jdg.conviction.hyper","priority":1549,"_routing":"WARNING","_routing_reason":"KKS: wykluczenie z funduszy UE","_legal_basis":"Rozp. 2018/1046","_warnings":["Skazanie za oszustwa finansowe — wykluczenie z ubiegania się o środki unijne"]} {
    object.get(input.jdg_entrepreneur, "kks_conviction_active", false) == true
    object.get(input.jdg_entrepreneur, "fraud_related_conviction", false) == true
}
else := {"matched":true,"rule_id":"jdg.conviction.hyper.regulated_profession_consequences","package":"jdg.conviction.hyper","priority":1550,"_routing":"BLOCK_AND_ALERT","_routing_reason":"KKS: skutki dla zawodu regulowanego","_legal_basis":"Ustawy branżowe","_warnings":["Skazanie KKS — sprawdź konsekwencje dla Twojego zawodu regulowanego"]} {
    object.get(input.jdg_entrepreneur, "kks_conviction_active", false) == true
    object.get(input.jdg_entrepreneur, "is_regulated_profession", false) == true
}

# ══ R1551-R1555: Banking & Finance ══
else := {"matched":true,"rule_id":"jdg.conviction.hyper.bank_account_termination","package":"jdg.conviction.hyper","priority":1551,"_routing":"WARNING","_routing_reason":"KKS: ryzyko wypowiedzenia umowy banku","_legal_basis":"Art. 56 Prawo bankowe, AML","_warnings":["Skazanie KKS za przestępstwa finansowe — bank może wypowiedzieć umowę rachunku"]} {
    object.get(input.jdg_entrepreneur, "kks_conviction_active", false) == true
    object.get(input.jdg_entrepreneur, "financial_crime_conviction", false) == true
}
else := {"matched":true,"rule_id":"jdg.conviction.hyper.credit_score_impact","package":"jdg.conviction.hyper","priority":1552,"_routing":"WARNING","_routing_reason":"KKS: wpływ na zdolność kredytową","_legal_basis":"BIK","_warnings":["Skazanie KKS — negatywny wpływ na scoring kredytowy i dostęp do finansowania"]} {
    object.get(input.jdg_entrepreneur, "kks_conviction_active", false) == true
    object.get(input.jdg_entrepreneur, "credit_check_pending", false) == true
}
else := {"matched":true,"rule_id":"jdg.conviction.hyper.enhanced_aml_kyc","package":"jdg.conviction.hyper","priority":1553,"_routing":"WARNING","_routing_reason":"KKS: wzmocniona weryfikacja AML","_legal_basis":"Art. 43 AML","_warnings":["Skazanie KKS — banki/fintechy zastosują wzmocnioną weryfikację AML/KYC"]} {
    object.get(input.jdg_entrepreneur, "kks_conviction_active", false) == true
}
else := {"matched":true,"rule_id":"jdg.conviction.hyper.fintech_access_restriction","package":"jdg.conviction.hyper","priority":1554,"_routing":"WARNING","_routing_reason":"KKS: ograniczenia fintech","_legal_basis":"Polityki fintechów","_warnings":["Skazanie KKS — możliwe ograniczenia w dostępie do usług fintech"]} {
    object.get(input.jdg_entrepreneur, "fintech_account_restricted", false) == true
}
else := {"matched":true,"rule_id":"jdg.conviction.hyper.cash_monitoring_enhanced","package":"jdg.conviction.hyper","priority":1555,"_routing":"WARNING","_routing_reason":"KKS: monitoring transakcji gotówkowych","_legal_basis":"GIIF","_warnings":["Skazanie KKS — transakcje gotówkowe podlegają zaostrzonemu monitoringowi GIIF"]} {
    object.get(input.jdg_entrepreneur, "kks_conviction_active", false) == true
}

# ══ R1556-R1560: Tax Office Relations ══
else := {"matched":true,"rule_id":"jdg.conviction.hyper.enhanced_audit_scrutiny","package":"jdg.conviction.hyper","priority":1556,"_routing":"WARNING","_routing_reason":"KKS: zaostrzony nadzór US","_legal_basis":"Art. 119b ustawy z dnia 29 sierpnia 1997 r. — Ordynacja podatkowa (Dz.U. 2025 poz. 234, ze zm.)","_warnings":["Skazanie KKS — częstsze kontrole podatkowe, zaostrzony nadzór"]} {
    object.get(input.jdg_entrepreneur, "kks_conviction_active", false) == true
}
else := {"matched":true,"rule_id":"jdg.conviction.hyper.risk_profile_high","package":"jdg.conviction.hyper","priority":1557,"_routing":"WARNING","_routing_reason":"KKS: profil ryzyka HIGH","_legal_basis":"Art. 119b ustawy z dnia 29 sierpnia 1997 r. — Ordynacja podatkowa (Dz.U. 2025 poz. 234, ze zm.)","_warnings":["Skazanie KKS — automatyczne przeklasyfikowanie profilu ryzyka na HIGH"]} {
    object.get(input.jdg_entrepreneur, "risk_profile_changed_to_high", false) == true
}
else := {"matched":true,"rule_id":"jdg.conviction.hyper.public_warning_list","package":"jdg.conviction.hyper","priority":1558,"_routing":"BLOCK_AND_ALERT","_routing_reason":"KKS: lista ostrzeżeń publicznych","_legal_basis":"Art. 119b ustawy z dnia 29 sierpnia 1997 r. — Ordynacja podatkowa (Dz.U. 2025 poz. 234, ze zm.)","_warnings":["Skazanie KKS + zaległości — wpis na listę ostrzeżeń publicznych MF!"]} {
    object.get(input.jdg_entrepreneur, "public_warning_list_entry", false) == true
}
else := {"matched":true,"rule_id":"jdg.conviction.hyper.statute_interruption","package":"jdg.conviction.hyper","priority":1559,"_routing":"WARNING","_routing_reason":"KKS: przerwanie przedawnienia","_legal_basis":"Art. 70 § 4 ustawy z dnia 29 sierpnia 1997 r. — Ordynacja podatkowa (Dz.U. 2025 poz. 234, ze zm.)","_warnings":["Skazanie KKS przerywa bieg przedawnienia zobowiązania podatkowego"]} {
    object.get(input.jdg_entrepreneur, "kks_conviction_caused_statute_interruption", false) == true
}
else := {"matched":true,"rule_id":"jdg.conviction.hyper.extended_audit_period","package":"jdg.conviction.hyper","priority":1560,"_routing":"WARNING","_routing_reason":"KKS: przedłużona kontrola 60 dni","_legal_basis":"Art. 83 ustawy z dnia 6 marca 2018 r. — Prawo przedsiębiorców (Dz.U. 2025 poz. 226, ze zm.)","_warnings":["Skazanie KKS — kontrola podatkowa może trwać 60 dni (zamiast 30)"]} {
    object.get(input.jdg_entrepreneur, "audit_in_progress", false) == true
    object.get(input.jdg_entrepreneur, "kks_conviction_active", false) == true
}

# ══ R1561-R1565: Business Partners ══
else := {"matched":true,"rule_id":"jdg.conviction.hyper.business_partner_trust_loss","package":"jdg.conviction.hyper","priority":1561,"_routing":"WARNING","_routing_reason":"KKS: utrata zaufania kontrahentów","_legal_basis":"—","_warnings":["Skazanie KKS jawne — ryzyko utraty zaufania kontrahentów"]} {
    object.get(input.jdg_entrepreneur, "kks_conviction_active", false) == true
    object.get(input.jdg_entrepreneur, "conviction_public", false) == true
}
else := {"matched":true,"rule_id":"jdg.conviction.hyper.joint_vat_liability_partners","package":"jdg.conviction.hyper","priority":1562,"_routing":"WARNING","_routing_reason":"KKS: ryzyko solidarnej odp. kontrahentów","_legal_basis":"Art. 105a VAT","_warnings":["Skazanie za VAT — kontrahenci mogą odpowiadać solidarnie → zerwą współpracę"]} {
    object.get(input.jdg_entrepreneur, "vat_fraud_conviction", false) == true
}
else := {"matched":true,"rule_id":"jdg.conviction.hyper.supply_chain_due_diligence","package":"jdg.conviction.hyper","priority":1563,"_routing":"WARNING","_routing_reason":"KKS: wzmożona należyta staranność","_legal_basis":"Art. 105a VAT","_warnings":["Skazanie KKS — kontrahenci zastosują wzmożoną należytą staranność"]} {
    object.get(input.jdg_entrepreneur, "kks_conviction_active", false) == true
}
else := {"matched":true,"rule_id":"jdg.conviction.hyper.contract_termination_clauses","package":"jdg.conviction.hyper","priority":1564,"_routing":"WARNING","_routing_reason":"KKS: klauzule rozwiązania umów","_legal_basis":"KC","_warnings":["Skazanie KKS — kontrahenci mogą rozwiązać umowy na podstawie klauzul moralnych"]} {
    object.get(input.jdg_entrepreneur, "contracts_have_moral_clause", false) == true
    object.get(input.jdg_entrepreneur, "kks_conviction_active", false) == true
}
else := {"matched":true,"rule_id":"jdg.conviction.hyper.network_isolation","package":"jdg.conviction.hyper","priority":1565,"_routing":"WARNING","_routing_reason":"KKS: izolacja od sieci biznesowych","_legal_basis":"—","_warnings":["Skazanie KKS — ryzyko izolacji od sieci biznesowych i izb gospodarczych"]} {
    object.get(input.jdg_entrepreneur, "network_isolation_risk", false) == true
}

# ══ R1566-R1570: Rehabilitation ══
else := {"matched":true,"rule_id":"jdg.conviction.hyper.rehabilitation_misdemeanor_3y","package":"jdg.conviction.hyper","priority":1566,"_routing":"","_routing_reason":"Zatarcie: wykroczenie skarbowe 3 lata","_legal_basis":"Art. 19 ustawy z dnia 10 września 1999 r. — Kodeks karny skarbowy (Dz.U. 2025 poz. 678, ze zm.)","_warnings":["Wykroczenie skarbowe — zatarcie skazania po 3 latach od wykonania kary (v7.0 FIX K19-1: Art. 19 KKS, nie Art. 21)"]} {
    object.get(input.jdg_entrepreneur, "kks_offense_type", "") == "MISDEMEANOR"
}
else := {"matched":true,"rule_id":"jdg.conviction.hyper.rehabilitation_crime_5y","package":"jdg.conviction.hyper","priority":1567,"_routing":"","_routing_reason":"Zatarcie: przestępstwo skarbowe 5 lat","_legal_basis":"Art. 19 ustawy z dnia 10 września 1999 r. — Kodeks karny skarbowy (Dz.U. 2025 poz. 678, ze zm.)","_warnings":["Przestępstwo skarbowe — zatarcie skazania po 5 latach od wykonania kary (v7.0 FIX K19-1: Art. 19 KKS, nie Art. 21)"]} {
    object.get(input.jdg_entrepreneur, "kks_offense_type", "") == "CRIME"
}
else := {"matched":true,"rule_id":"jdg.conviction.hyper.rehabilitation_clean_record","package":"jdg.conviction.hyper","priority":1568,"_routing":"","_routing_reason":"Skutek zatarcia — czysta karta","_legal_basis":"Art. 106 KK","_warnings":["Zatarcie skazania = powrót do stanu sprzed skazania, wszystkie ograniczenia uchylone"]} {
    object.get(input.jdg_entrepreneur, "conviction_spent", false) == true
}
else := {"matched":true,"rule_id":"jdg.conviction.hyper.rehabilitation_business_ban_lift","package":"jdg.conviction.hyper","priority":1569,"_routing":"","_routing_reason":"Zatarcie: zniesienie zakazu","_legal_basis":"Art. 41 KK","_warnings":["Zatarcie skazania — automatyczne zniesienie zakazu prowadzenia działalności"]} {
    object.get(input.jdg_entrepreneur, "conviction_spent", false) == true
    object.get(input.jdg_entrepreneur, "business_ban_active", false) == true
}
else := {"matched":true,"rule_id":"jdg.conviction.hyper.rehabilitation_us_notification","package":"jdg.conviction.hyper","priority":1570,"_routing":"","_routing_reason":"Powiadom US o zatarciu","_legal_basis":"Praktyka","_warnings":["Zatarcie skazania — poinformuj US dla przywrócenia normalnego trybu nadzoru"]} {
    object.get(input.jdg_entrepreneur, "conviction_spent", false) == true
    object.get(input.jdg_entrepreneur, "us_notified_of_rehabilitation", false) == false
}

# ══ R1571-R1575: Enforcement ══
else := {"matched":true,"rule_id":"jdg.conviction.hyper.full_asset_enforcement","package":"jdg.conviction.hyper","priority":1571,"_routing":"BLOCK_AND_ALERT","_routing_reason":"Egzekucja z całego majątku","_legal_basis":"Art. 26 ustawy z dnia 29 sierpnia 1997 r. — Ordynacja podatkowa (Dz.U. 2025 poz. 234, ze zm.)","_warnings":["Egzekucja zaległości podatkowych — odpowiedzialność całym majątkiem osobistym!"]} {
    object.get(input.jdg_entrepreneur, "tax_arrears", 0) > 0
    object.get(input.jdg_entrepreneur, "enforcement_active", false) == true
}
else := {"matched":true,"rule_id":"jdg.conviction.hyper.no_asset_concealment","package":"jdg.conviction.hyper","priority":1572,"_routing":"BLOCK_AND_ALERT","_routing_reason":"Zakaz ukrywania majątku","_legal_basis":"Art. 36 OP, Art. 61 KKS","_warnings":["Zakaz ukrywania majątku przed egzekucją — grozi odpowiedzialność KKS!"]} {
    object.get(input.jdg_entrepreneur, "enforcement_active", false) == true
}
else := {"matched":true,"rule_id":"jdg.conviction.hyper.bank_account_seizure","package":"jdg.conviction.hyper","priority":1573,"_routing":"BLOCK_AND_ALERT","_routing_reason":"Zajęcie rachunków bankowych","_legal_basis":"Art. 75-89 Ustawa o post. egz.","_warnings":["Zajęcie rachunków bankowych — egzekucja zaległości podatkowych"]} {
    object.get(input.jdg_entrepreneur, "bank_account_seized", false) == true
}
else := {"matched":true,"rule_id":"jdg.conviction.hyper.collateral_required","package":"jdg.conviction.hyper","priority":1574,"_routing":"BLOCK_AND_ALERT","_routing_reason":"Zabezpieczenie majątkowe","_legal_basis":"Art. 33 ustawy z dnia 29 sierpnia 1997 r. — Ordynacja podatkowa (Dz.U. 2025 poz. 234, ze zm.)","_warnings":["Wymóg złożenia zabezpieczenia majątkowego na poczet przyszłych zaległości"]} {
    object.get(input.jdg_entrepreneur, "collateral_required_by_us", false) == true
}
else := {"matched":true,"rule_id":"jdg.conviction.hyper.insolvency_filing_obligation","package":"jdg.conviction.hyper","priority":1575,"_routing":"BLOCK_AND_ALERT","_routing_reason":"Obowiązek wniosku o upadłość","_legal_basis":"Art. 21 Prawa upadłościowego","_warnings":["Niewypłacalność — obowiązek złożenia wniosku o upadłość w ciągu 30 dni!"]} {
    object.get(input.jdg_entrepreneur, "insolvent", false) == true
    object.get(input.jdg_entrepreneur, "insolvency_filed", false) == false
}
