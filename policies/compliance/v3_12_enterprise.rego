# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — RODO + AML + BDO + ŚRODOWISKO + HR V3 ENTERPRISE
# (Kampania V3, część 12/20)
# ═══════════════════════════════════════════════════════════════════════════════
# Package: jdg.compliance.v3_12
# Cel:     domknięcie luk L-12-001..L-12-008 z raportu 12_RODO_AML_BDO.txt:
#          zgłoszenie naruszenia RODO w 72h (art. 33), erasure engine (art. 17,
#          30 dni), monitor transakcji AML (art. 34 uAML, próg 15k EUR),
#          CBDD/beneficjenci rzeczywiści (UBO ≥25%), BDO KPO (termin 7 dni,
#          ważność 5 lat), DPIA dla AI/profilingu (art. 35), fail-closed
#          (V1 z6), Decision Certificate (F4), Golden Oracle (F3).
# Prawo:   RODO (UE 2016/679): art. 5-13, 15-22, 24-35, 37, 44-49, 82-83;
#          ustawa z 1.03.2018 o przeciwdziałaniu praniu pieniędzy (Dz.U. 2025
#          poz. 213): art. 2, 28-36, 74-80, 153; ustawa o odpadach z 14.12.2012
#          (BDO): art. 17-18, 41-48, 49-55, 66-74, 194, 233; PPK 2018; Kodeks pracy.
# Struktura: wzorzec v3_08/v3_09/v3_10/v3_11 — reguły-decyzje budują verdict;
#          łańcuch decide = first-match-wins; wartości warunkowe liczą funkcje
#          pomocnicze z klauzulami else.
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.compliance.v3_12

import future.keywords.in

default decide := {
    "matched": false,
    "rule_id": "jdg.compliance.v3_12.no_match",
    "package": "jdg.compliance.v3_12",
    "priority": 999999,
}

# ── Snapshot progów (ADR-002): brak sekcji rodo_aml_bdo_hr_etap21 → fail-closed ─
_th_snapshot := object.get(data.jdg.thresholds, "rodo_aml_bdo_hr_etap21", {})
_snapshot_ok := count(_th_snapshot) > 0

_th(key, fallback) = value {
    _snapshot_ok
    object.get(_th_snapshot, key, null) != null
} else = fallback

_bool_str(flag) = "TAK" {
    flag
}

_bool_str(flag) = "NIE" {
    flag == false
}

snapshot_status(ok) = "OK" {
    ok
} else = "MISSING"

# ── Fail-closed verdict gdy snapshot progów niedostępny ────────────────────────
fail_closed_decision := {
    "matched": true,
    "rule_id": "jdg.compliance.v3_12.thresholds_missing",
    "package": "jdg.compliance.v3_12",
    "priority": 0,
    "decision_mode": "BLOCK",
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "RODO/AML/BDO/HR v3: brak snapshotu data.jdg.thresholds.rodo_aml_bdo_hr_etap21.",
    "_legal_basis": "ADR-002 zero-hardcode; V1 zasada 6 (fail-closed)",
    "_warnings": ["[V3-12] Brak snapshotu progów — decyzje compliance ZABLOKOWANE."],
}

# ── Decision Certificate wrapper (V2 filar F4) ────────────────────────────────
_certificate(priority, extra) = merged {
    base := {
        "matched": true,
        "package": "jdg.compliance.v3_12",
        "priority": priority,
        "threshold_version": object.get(_th_snapshot, "threshold_version", "MISSING"),
        "legal_basis_version": object.get(_th_snapshot, "legal_basis_version", "MISSING"),
        "valid_from": object.get(_th_snapshot, "valid_from", null),
        "valid_to": object.get(_th_snapshot, "valid_to", null),
    }
    merged := object.union(base, extra)
}

_min(a, b) = a {
    a <= b
} else = b

# ═══════════════════════════════════════════════════════════════════════════════
# V3-12-001: RODO BREACH GUARD — art. 33 RODO (zgłoszenie do UODO w 72 h od
#            wykrycia; rodo_breach_deadline_hours z thresholds)
# ═══════════════════════════════════════════════════════════════════════════════

_breach_routing(hours, deadline_h, reported) = "" {
    reported
} else = "BLOCK_AND_ALERT" {
    hours > deadline_h
} else = "TRIAGE_QUEUE" {
    hours >= deadline_h / 2
} else = "WARNING"

breach_guard_decision := verdict {
    incident := object.get(input.rodo_incident, {}, {})
    object.get(incident, "breach_detected", false) == true

    deadline_hours := _th("rodo_breach_deadline_hours", 72)
    hours := object.get(incident, "hours_since_detection", 0)
    reported := object.get(incident, "reported_to_uodo", false)

    verdict := _certificate(110, {
        "rule_id": "jdg.compliance.v3_12.rodo_breach_guard",
        "procedure": "RODO_BREACH_72H_V3",
        "deadline_hours": deadline_hours,
        "hours_since_detection": hours,
        "reported_to_uodo": reported,
        "_routing": _breach_routing(hours, deadline_hours, reported),
        "_routing_reason": sprintf("Naruszenie RODO — %v h od wykrycia vs limit %v h; zgłoszono: %s.", [hours, deadline_hours, _bool_str(reported)]),
        "_legal_basis": "art. 33 RODO (UE 2016/679); kara do rodo_sanction_max_eur (art. 83 ust. 5)",
        "_warnings": ["[V3-12] Dokumentuj przebieg naruszenia i zgłoś do UODO przed upływem 72 h."],
    })
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-12-002: ERASURE ENGINE — art. 17 RODO (usunięcie danych w 30 dni);
#            żądanie usunięcia po terminie = BLOCK_AND_ALERT
# ═══════════════════════════════════════════════════════════════════════════════

_erasure_routing(days, deadline_days, done) = "" {
    done
} else = "BLOCK_AND_ALERT" {
    days > deadline_days
} else = "WARNING"

erasure_decision := verdict {
    request := object.get(input.erasure_request, {}, {})
    object.get(request, "received", false) == true

    deadline_days := _th("rodo_erasure_deadline_days", 30)
    days := object.get(request, "days_pending", 0)
    done := object.get(request, "erased", false)

    verdict := _certificate(120, {
        "rule_id": "jdg.compliance.v3_12.erasure_engine_guard",
        "procedure": "ERASURE_ART17_V3",
        "erasure_deadline_days": deadline_days,
        "days_pending": days,
        "erased": done,
        "_routing": _erasure_routing(days, deadline_days, done),
        "_routing_reason": sprintf("Żądanie usunięcia danych (art. 17) — %v dni vs limit %v dni.", [days, deadline_days]),
        "_legal_basis": "art. 17 i 12 ust. 3 RODO (odpowiedź bez zbędnej zwłoki, max 30 dni)",
        "_warnings": ["[V3-12] Wykonaj usunięcie/anonimizację i potwierdź osobie, której dane dotyczą."],
    })
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-12-003: AML TRANSACTION MONITOR — art. 34 uAML (transakcje okazjonalne
#            ≥ aml_transaction_threshold_eur); obowiązek STR przy braku raportu
# ═══════════════════════════════════════════════════════════════════════════════

_aml_routing(value_eur, threshold_eur, str_filed) = "" {
    value_eur < threshold_eur
} else = "BLOCK_AND_ALERT" {
    not str_filed
} else = "TRIAGE_QUEUE"

aml_transaction_decision := verdict {
    tx := object.get(input.aml_transaction, {}, {})
    object.get(tx, "monitored", false) == true

    threshold_eur := _th("aml_transaction_threshold_eur", 15000)
    value_eur := object.get(tx, "value_eur", 0)
    str_filed := object.get(tx, "str_filed", false)
    needs_reference := object.get(_th_snapshot, "aml_str_requires_reference", true)

    verdict := _certificate(130, {
        "rule_id": "jdg.compliance.v3_12.aml_transaction_monitor",
        "procedure": "AML_STR_MONITOR_V3",
        "transaction_threshold_eur": threshold_eur,
        "transaction_value_eur": value_eur,
        "str_filed": str_filed,
        "str_reference_required": needs_reference,
        "_routing": _aml_routing(value_eur, threshold_eur, str_filed),
        "_routing_reason": sprintf("Transakcja %v EUR vs próg AML %v EUR; STR złożony: %s.", [value_eur, threshold_eur, _bool_str(str_filed)]),
        "_legal_basis": "art. 34 i 74 ustawy AML (Dz.U. 2025 poz. 213); GIIF STR",
        "_warnings": ["[V3-12] Złóż STR do GIIF i zabezpiecz referencję raportu."],
    })
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-12-004: AML-CBDD GUARD — weryfikacja kontrahenta wysokiego ryzyka +
#            beneficjenci rzeczywiści (UBO ≥ ubo_minimum_pct = 25%)
# ═══════════════════════════════════════════════════════════════════════════════

_cbdd_routing(risk_high, cbdd_done, ubo_known) = "BLOCK_AND_ALERT" {
    risk_high
    not cbdd_done
} else = "TRIAGE_QUEUE" {
    not ubo_known
} else = ""

cbdd_decision := verdict {
    counterparty := object.get(input.counterparty, {}, {})
    object.get(counterparty, "risk_screened", false) == true

    ubo_min := _th("ubo_minimum_pct", 25)
    risk_high := object.get(counterparty, "risk_level", "LOW") == "HIGH"
    cbdd_done := object.get(counterparty, "cbdd_completed", false)
    ubo_known := object.get(counterparty, "ubo_identified", true)

    verdict := _certificate(140, {
        "rule_id": "jdg.compliance.v3_12.aml_cbdd_guard",
        "procedure": "CBDD_UBO_V3",
        "ubo_minimum_pct": ubo_min,
        "risk_level": object.get(counterparty, "risk_level", "LOW"),
        "cbdd_completed": cbdd_done,
        "ubo_identified": ubo_known,
        "_routing": _cbdd_routing(risk_high, cbdd_done, ubo_known),
        "_routing_reason": sprintf("CBDD kontrahenta: ryzyko %s; weryfikacja %s; UBO znany: %s.",
                                   [object.get(counterparty, "risk_level", "LOW"), _bool_str(cbdd_done), _bool_str(ubo_known)]),
        "_legal_basis": "art. 2 pkt 1, art. 34-36, art. 153 ustawy AML (beneficjent rzeczywisty ≥25%)",
        "_warnings": ["[V3-12] Dokończ CBDD i identyfikację beneficjentów rzeczywistych przed transakcją."],
    })
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-12-005: BDO KPO GUARD — karta przekazania odpadów (termin bdo_kpo_
#            deadline_days na potwierdzenie; ważność dokumentu 5 lat)
# ═══════════════════════════════════════════════════════════════════════════════

_kpo_routing(days_unconfirmed, deadline_days, expired) = "BLOCK_AND_ALERT" {
    expired
} else = "TRIAGE_QUEUE" {
    days_unconfirmed > deadline_days
} else = "WARNING"

bdo_kpo_decision := verdict {
    kpo := object.get(input.bdo_kpo, {}, {})
    object.get(kpo, "issued", false) == true

    deadline_days := _th("bdo_kpo_deadline_days", 7)
    days_unconfirmed := object.get(kpo, "days_unconfirmed", 0)
    expired := object.get(kpo, "unconfirmed_over_year", false)

    verdict := _certificate(150, {
        "rule_id": "jdg.compliance.v3_12.bdo_kpo_guard",
        "procedure": "BDO_KPO_V3",
        "kpo_deadline_days": deadline_days,
        "days_unconfirmed": days_unconfirmed,
        "document_validity_years": 5,
        "expired_flag": expired,
        "_routing": _kpo_routing(days_unconfirmed, deadline_days, expired),
        "_routing_reason": sprintf("KPO niepotwierdzone od %v dni (limit %v dni).", [days_unconfirmed, deadline_days]),
        "_legal_basis": "art. 66-74 ustawy o odpadach (BDO); ewidencja KPO, ważność dokumentu 5 lat",
        "_warnings": ["[V3-12] Zweryfikuj status KPO w BDO i skoryguj ewidencję odpadów."],
    })
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-12-006: DPIA GUARD — ocena skutków dla ochrony danych (art. 35 RODO):
#            AI/profiling na dużą skalę bez przeprowadzonej DPIA = BLOCK
# ═══════════════════════════════════════════════════════════════════════════════

_dpia_routing(dpia_required, dpia_done, manual_approval) = "" {
    not dpia_required
} else = "TRIAGE_QUEUE" {
    not dpia_done
    manual_approval
} else = "BLOCK_AND_ALERT"

dpia_decision := verdict {
    processing := object.get(input.data_processing, {}, {})
    object.get(processing, "ai_profiling_large_scale", false) == true

    dpia_required := true
    dpia_done := object.get(processing, "dpia_completed", false)
    manual_approval := object.get(_th_snapshot, "manual_approval_required", true)

    verdict := _certificate(160, {
        "rule_id": "jdg.compliance.v3_12.dpia_guard",
        "procedure": "DPIA_ART35_V3",
        "dpia_required": dpia_required,
        "dpia_completed": dpia_done,
        "privacy_minimization_required": object.get(_th_snapshot, "privacy_minimization_required", true),
        "_routing": _dpia_routing(dpia_required, dpia_done, manual_approval),
        "_routing_reason": sprintf("Przetwarzanie AI/profiling bez DPIA — wymagana ocena skutków (art. 35)."),
        "_legal_basis": "art. 35 i 36 RODO; wytyczne EDPB WP248",
        "_warnings": ["[V3-12] Przeprowadź DPIA przed dalszym przetwarzaniem AI/profilingu."],
    })
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-12-007: DOMAIN CERTIFICATE — zbiorczy certyfikat domeny compliance
#            RODO/AML/BDO/HR (Golden Oracle F3 + Decision Certificate F4)
# ═══════════════════════════════════════════════════════════════════════════════

domain_certificate := _certificate(200, {
    "rule_id": "jdg.compliance.v3_12.domain_certificate",
    "decision_mode": "INFORM",
    "domain": "rodo_aml_bdo_environment_hr",
    "rodo_breach_deadline_hours": _th("rodo_breach_deadline_hours", 72),
    "rodo_erasure_deadline_days": _th("rodo_erasure_deadline_days", 30),
    "aml_transaction_threshold_eur": _th("aml_transaction_threshold_eur", 15000),
    "ubo_minimum_pct": _th("ubo_minimum_pct", 25),
    "bdo_kpo_deadline_days": _th("bdo_kpo_deadline_days", 7),
    "snapshot_status": snapshot_status(_snapshot_ok),
    "_routing": "",
    "_routing_reason": "Domena compliance — brak zdarzeń decyzyjnych w tym inputcie.",
    "_legal_basis": "RODO (UE 2016/679); ustawa AML (Dz.U. 2025 poz. 213); ustawa o odpadach (BDO)",
    "_warnings": [],
})

# ── Łańcuch decyzyjny first-match-wins ────────────────────────────────────────
decide := fail_closed_decision {
    not _snapshot_ok
}

decide := breach_guard_decision {
    _snapshot_ok
}

decide := erasure_decision {
    _snapshot_ok
    not breach_guard_decision
}

decide := aml_transaction_decision {
    _snapshot_ok
    not breach_guard_decision
    not erasure_decision
}

decide := cbdd_decision {
    _snapshot_ok
    not breach_guard_decision
    not erasure_decision
    not aml_transaction_decision
}

decide := bdo_kpo_decision {
    _snapshot_ok
    not breach_guard_decision
    not erasure_decision
    not aml_transaction_decision
    not cbdd_decision
}

decide := dpia_decision {
    _snapshot_ok
    not breach_guard_decision
    not erasure_decision
    not aml_transaction_decision
    not cbdd_decision
    not bdo_kpo_decision
}

decide := domain_certificate {
    _snapshot_ok
}
