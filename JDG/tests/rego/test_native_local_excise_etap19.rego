# ETAP 19 — native tests for PCC/local/excise evidence contract.
package test_jdg_local_excise_etap19

import future.keywords.if

base := {
    "jdg_entrepreneur": {"local_excise_etap19_check": true},
    "local_excise_etap19": {
        "domain": "REAL_ESTATE",
        "gmina": "Warszawa",
        "territory_code": "PL143",
        "evaluation_date": "2026-08-21",
        "facts_version": "facts-1",
        "threshold_version": "local-excise-2026.08",
        "source_refs": ["uchwala-warszawa-2026", "MF-2026"],
        "legal_nodes": {"local": "u.p.l. art. 2-6"},
        "owner_approval": true,
        "document": {"document_id": "DN1-1", "document_type": "UCHWALA_PLUS_DN1", "document_hash": "sha256:abc"},
        "local_rate_registry": [{
            "gmina": "Warszawa",
            "territory_code": "PL143",
            "resolution_id": "UCH-2026-1",
            "resolution_date": "2025-12-20",
            "valid_from": "2026-01-01",
            "valid_to": "2026-12-31",
            "source_ref": "bip.warszawa.pl/uchwala/1",
            "unit": "PLN_PER_M2",
            "land_business": 1.43,
            "building_business": 33.10
        }],
        "property": {"property_type": "land_business", "area_m2": 100, "unit": "PLN_PER_M2", "dn1_filed": true}
    }
}

test_no_match_without_stage_flag if {
    result := data.jdg.local_excise_etap19.decide with input as {"jdg_entrepreneur": {}}
    result.rule_id == "jdg.local_excise_etap19.no_match"
}

test_missing_evidence_blocks if {
    result := data.jdg.local_excise_etap19.decide with input as {
        "jdg_entrepreneur": {"local_excise_etap19_check": true},
        "local_excise_etap19": {"domain": "REAL_ESTATE", "gmina": "Warszawa", "territory_code": "PL143"}
    }
    result._routing == "BLOCK_AND_ALERT"
    result.manual_review_required == true
}

test_wrong_gmina_or_territory_blocks if {
    bad := object.union(base, {"local_excise_etap19": object.union(base.local_excise_etap19, {
        "gmina": "Krakow"
    })})
    result := data.jdg.local_excise_etap19.decide with input as bad
    result._routing == "BLOCK_AND_ALERT"
    result.registry_certificate.scope_match == false
    result.ambiguities[_] == "GMINA_OR_TERRITORY_MISMATCH"
}

test_valid_local_rate_is_scoped_and_suggest_only if {
    result := data.jdg.local_excise_etap19.decide with input as base
    result.registry_certificate.scope_match == true
    result.registry_certificate.gmina == "Warszawa"
    result.local_certificate.property_tax_due == 143
    result.decision_mode == "SUGGEST"
    result.no_auto_post == true
}

test_vat_excludes_pcc_but_routes_to_manual_review if {
    inp := object.union(base, {"local_excise_etap19": object.union(base.local_excise_etap19, {
        "domain": "PCC",
        "pcc": {"transaction_type": "SALE", "amount": 100000, "vat_applies": true, "subject_verified": true},
        "document": {"document_id": "SALE-1", "document_type": "UMOWA_SPRZEDAZY", "document_hash": "sha256:pcc"}
    })})
    result := data.jdg.local_excise_etap19.decide with input as inp
    result.pcc_certificate.pcc_excluded_by_vat == true
    result.pcc_certificate.tax_due == 0
    result._routing == "TRIAGE_QUEUE"
}

test_unverified_excise_classification_blocks_and_requires_evidence if {
    inp := object.union(base, {"local_excise_etap19": object.union(base.local_excise_etap19, {
        "domain": "EXCISE",
        "excise": {"product_type": "UNKNOWN", "quantity": 100, "unit": "L", "classification_verified": false}
    })})
    result := data.jdg.local_excise_etap19.decide with input as inp
    result._routing == "BLOCK_AND_ALERT"
    result.excise_certificate.classification_verified == false
    result.ambiguities[_] == "EXCISE_CLASSIFICATION_UNVERIFIED"
}
