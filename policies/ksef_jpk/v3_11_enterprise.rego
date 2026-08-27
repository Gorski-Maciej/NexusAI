# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — KSEF + BIAŁA LISTA + E-DORĘCZENIA + ePUAP + WIS + ESIG V3
# ENTERPRISE (Kampania V3, część 11/20)
# ═══════════════════════════════════════════════════════════════════════════════
# Package: jdg.ksef_jpk.v3_11
# Cel:     domknięcie luk L-11-001..L-11-008 z raportu 11_KSEF_JPK.txt:
#          obowiązek KSeF od 2026-02-01 (art. 106na VAT), okno offline 7 dni,
#          walidacja UPO, monitor sankcji do 500 tys. PLN (100%/70%/50%),
#          obsługa B2C bez NIP, weryfikacja adresu e-Doręczeń (od 2026-01-01),
#          reconcile JPK↔KSeF, WIS watcher, fail-closed (V1 z6),
#          Decision Certificate (F4), Golden Oracle (F3).
# Prawo:   ustawa o VAT: art. 106na-106nq (KSeF), art. 106e (elementy faktury),
#          art. 42a-42h (WIS); ustawa z 16.06.2023 o e-Doręczeniu
#          (Dz.U. 2023 poz. 1598; art. 8-9); Prawo informatyzacji (ePUAP);
#          rozporządzenie (UE) 910/2014 eIDAS; struktury JPK_V7M / JPK_KR.
# Struktura: wzorzec v3_08/v3_09/v3_10 — reguły-decyzje budują verdict w ciele;
#          łańcuch decide = first-match-wins (Rego bez operatora ternary;
#          wartości warunkowe liczą funkcje pomocnicze z klauzulami else).
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.ksef_jpk.v3_11

import future.keywords.in

default decide := {
    "matched": false,
    "rule_id": "jdg.ksef_jpk.v3_11.no_match",
    "package": "jdg.ksef_jpk.v3_11",
    "priority": 999999,
}

# ── Snapshot progów (ADR-002): brak sekcji ksef_jpk_edeklaracje → fail-closed ──
_th_snapshot := object.get(data.jdg.thresholds, "ksef_jpk_edeklaracje", {})
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

_ksef_mandatory_from := object.get(_th_snapshot, "ksef_mandatory_from", "2026-02-01")

# ── Fail-closed verdict gdy snapshot progów niedostępny ────────────────────────
fail_closed_decision := {
    "matched": true,
    "rule_id": "jdg.ksef_jpk.v3_11.thresholds_missing",
    "package": "jdg.ksef_jpk.v3_11",
    "priority": 0,
    "decision_mode": "BLOCK",
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "KSeF/JPK/e-Doręczenia v3: brak snapshotu data.jdg.thresholds.ksef_jpk_edeklaracje.",
    "_legal_basis": "ADR-002 zero-hardcode; V1 zasada 6 (fail-closed)",
    "_warnings": ["[V3-11] Brak snapshotu progów — decyzje KSeF/JPK/e-Doręczenia ZABLOKOWANE."],
}

# ── Decision Certificate wrapper (V2 filar F4) ────────────────────────────────
_certificate(priority, extra) = merged {
    base := {
        "matched": true,
        "package": "jdg.ksef_jpk.v3_11",
        "priority": priority,
        "threshold_version": object.get(_th_snapshot, "threshold_version", "MISSING"),
        "valid_from": _ksef_mandatory_from,
    }
    merged := object.union(base, extra)
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-11-001: KSEF MANDATORY GATE + SANCTION MONITOR — art. 106na-106nb ustawy o
#            VAT (obowiązek od ksef_mandatory_from); ekspozycja sankcyjna wg
#            tierów 100% (max ksef_sanction_max_pln) / 70% (cap 300k) / 50%
#            czynny żal (cap 250k) — wszystko z thresholds (zero hardcode)
# ═══════════════════════════════════════════════════════════════════════════════

_sanction_tier(vat_pln, apology, delay24h) = tier {
    apology == false
    delay24h == false
    tier := {
        "tier": "FULL",
        "exposure_pln": _min(vat_pln, _th("ksef_sanction_max_pln", 500000)),
        "note": "brak czynnego żalu",
    }
} else = tier {
    apology == true
    tier := {
        "tier": "APOLOGY_50",
        "exposure_pln": _min(floor(vat_pln * 50) / 100, _th("ksef_sanction_50_cap_pln", 250000)),
        "note": "czynny żal złożony",
    }
} else = tier {
    tier := {
        "tier": "DELAY_70",
        "exposure_pln": _min(floor(vat_pln * 70) / 100, _th("ksef_sanction_70_cap_pln", 300000)),
        "note": "opóźnienie >24h bez czynnego żalu",
    }
}

_min(a, b) = a {
    a <= b
} else = b

ksef_mandatory_decision := verdict {
    invoice := object.get(input.invoice, {}, {})
    profile := object.get(input.jdg_entrepreneur, {}, {})
    object.get(invoice, "issue_date", "") >= _ksef_mandatory_from
    object.get(invoice, "b2b_with_vat", true)
    object.get(invoice, "ksef_submitted", false) == false
    object.get(invoice, "buyer_nip", "") != ""

    vat_pln := object.get(invoice, "vat_amount_pln", 0)
    apology := object.get(profile, "active_apology_filed", false)
    delay24h := object.get(profile, "delay_over_24h", false)

    verdict := _certificate(110, {
        "rule_id": "jdg.ksef_jpk.v3_11.ksef_mandatory_gate",
        "procedure": "KSEF_MANDATORY_V3",
        "ksef_required": true,
        "ksef_submitted": false,
        "mandatory_from": _ksef_mandatory_from,
        "sanction_exposure": _sanction_tier(vat_pln, apology, delay24h),
        "_routing": "BLOCK_AND_ALERT",
        "_routing_reason": sprintf("Faktura B2B po dacie obowiązku KSeF (%s) nie została wysłana — ekspozycja sankcyjna %d PLN.", [_ksef_mandatory_from, _sanction_tier(vat_pln, apology, delay24h).exposure_pln]),
        "_legal_basis": "art. 106na-106nb ustawy o VAT; sankcja do ksef_sanction_max_pln (thresholds)",
        "_warnings": ["[V3-11] Wyślij fakturę do KSeF natychmiast — rośnie ekspozycja na sankcję."],
    })
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-11-002: OFFLINE QUEUE GUARD — okno awaryjne ksef_offline_grace_days=7 dni;
#            alert przy ksef_queue_warning_hours przed końcem okna 168h
# ═══════════════════════════════════════════════════════════════════════════════

_queue_routing(age_h, grace_days, warn_h) = "BLOCK_AND_ALERT" {
    age_h > grace_days * 24
} else = "TRIAGE_QUEUE" {
    age_h >= warn_h
} else = ""

_queue_warning(age_h, grace_days) = msg {
    age_h > grace_days * 24
    msg := sprintf("[V3-11] Okno offline PRZEKROCZONE (%v h > %v dni) — natychmiastowa wysyłka + notatka o awarii.", [age_h, grace_days])
} else = msg {
    msg := "[V3-11] Zbliżanie się do końca okna offline — zaplanuj wysyłkę."
}

offline_queue_decision := verdict {
    invoice := object.get(input.invoice, {}, {})
    object.get(invoice, "in_offline_queue", false) == true

    grace_days := _th("ksef_offline_grace_days", 7)
    warn_hours := _th("ksef_queue_warning_hours", 120)
    age_h := object.get(invoice, "queue_age_hours", 0)

    verdict := _certificate(120, {
        "rule_id": "jdg.ksef_jpk.v3_11.offline_queue_guard",
        "procedure": "OFFLINE_QUEUE_V3",
        "queue_age_hours": age_h,
        "grace_days": grace_days,
        "warning_hours": warn_hours,
        "window_exceeded": age_h > grace_days * 24,
        "_routing": _queue_routing(age_h, grace_days, warn_hours),
        "_routing_reason": sprintf("Kolejka offline KSeF — wiek %v h vs okno %v dni (alert od %v h).", [age_h, grace_days, warn_hours]),
        "_legal_basis": "tryb awaryjny KSeF; okno ksef_offline_grace_days dni (thresholds)",
        "_warnings": [_queue_warning(age_h, grace_days)],
    })
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-11-003: UPO TRACKER — walidacja potwierdzenia UPO w oknie
#            ksef_upo_deadline_days (data wystawienia = data potwierdzenia)
# ═══════════════════════════════════════════════════════════════════════════════

_upo_routing(hours, deadline_days) = "TRIAGE_QUEUE" {
    hours > deadline_days * 24
} else = "WARNING"

upo_decision := verdict {
    invoice := object.get(input.invoice, {}, {})
    object.get(invoice, "ksef_submitted", false) == true
    object.get(invoice, "upo_received", false) == false

    deadline_days := _th("ksef_upo_deadline_days", 1)
    hours := object.get(invoice, "hours_since_submission", 0)

    verdict := _certificate(130, {
        "rule_id": "jdg.ksef_jpk.v3_11.upo_validation_guard",
        "procedure": "UPO_TRACKER_V3",
        "upo_deadline_days": deadline_days,
        "hours_since_submission": hours,
        "_routing": _upo_routing(hours, deadline_days),
        "_routing_reason": sprintf("Brak UPO dla faktury wysłanej do KSeF — %v h od wysyłki (okno %v dni).", [hours, deadline_days]),
        "_legal_basis": "art. 106nb ustawy o VAT (data wystawienia = data potwierdzenia); UPO tracker",
        "_warnings": ["[V3-11] Brak UPO — sprawdź sesję KSeF i status weryfikacji pliku."],
    })
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-11-004: E-DORĘCZENIA ADDRESS GUARD — obowiązek adresowy od
#            edelivery_mandatory_from (ustawa z 16.06.2023, art. 8-9);
#            podmiot publiczny bez zweryfikowanego adresu = BLOCK_AND_ALERT
# ═══════════════════════════════════════════════════════════════════════════════

edelivery_decision := verdict {
    counterparty := object.get(input.counterparty, {}, {})
    object.get(counterparty, "is_public_entity_b2g", false) == true
    object.get(counterparty, "edelivery_address_verified", false) == false

    verdict := _certificate(140, {
        "rule_id": "jdg.ksef_jpk.v3_11.edelivery_address_guard",
        "procedure": "EDELIVERY_ADDRESS_V3",
        "mandatory_from": _th("edelivery_mandatory_from", "2026-01-01"),
        "address_on_file": false,
        "_routing": "BLOCK_AND_ALERT",
        "_routing_reason": "Podmiot publiczny bez zweryfikowanego adresu do doręczeń elektronicznych.",
        "_legal_basis": "ustawa z 16.06.2023 o e-Doręczeniu (Dz.U. 2023 poz. 1598), art. 8-9",
        "_warnings": ["[V3-11] Zweryfikuj adres do doręczeń elektronicznych kontrahenta B2G."],
    })
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-11-005: B2C BEZ NIP — faktura konsumencka po dacie obowiązku KSeF bez NIP
#            nabywcy: dozwolona, ale wymaga trybu B2C_NO_NIP i oznaczenia
# ═══════════════════════════════════════════════════════════════════════════════

b2c_decision := verdict {
    invoice := object.get(input.invoice, {}, {})
    object.get(invoice, "buyer_nip", "") == ""
    object.get(invoice, "ksef_submitted", false) == false
    object.get(invoice, "issue_date", "") >= _ksef_mandatory_from

    verdict := _certificate(150, {
        "rule_id": "jdg.ksef_jpk.v3_11.b2c_without_nip_handler",
        "procedure": "B2C_NO_NIP_V3",
        "buyer_nip_present": false,
        "ksef_mode": "B2C_NO_NIP",
        "_routing": "WARNING",
        "_routing_reason": "Faktura B2C bez NIP nabywcy — wymagane oznaczenie trybu w KSeF.",
        "_legal_basis": "art. 106na ust. 2-3 ustawy o VAT; art. 106e (elementy faktury)",
        "_warnings": ["[V3-11] Faktura konsumencka: wyślij do KSeF z trybem B2C bez NIP."],
    })
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-11-006: RECONCILE JPK ↔ KSEF — liczba faktur w rejestrze JPK vs liczba
#            wysłanych do KSeF; rozbieżność = TRIAGE (przed złożeniem deklaracji)
# ═══════════════════════════════════════════════════════════════════════════════

reconcile_decision := verdict {
    jpk_register := object.get(input.jpk_register, {}, {})
    ksef_summary := object.get(input.ksef_summary, {}, {})
    object.get(jpk_register, "enabled", false) == true
    object.get(jpk_register, "invoice_count", 0) != object.get(ksef_summary, "submitted_count", -1)

    verdict := _certificate(160, {
        "rule_id": "jdg.ksef_jpk.v3_11.jpk_ksef_reconcile",
        "procedure": "JPK_KSEF_RECONCILE_V3",
        "jpk_invoice_count": object.get(jpk_register, "invoice_count", 0),
        "ksef_submitted_count": object.get(ksef_summary, "submitted_count", -1),
        "discrepancy_alert_pln": _th("jpk_kr_discrepancy_alert_pln", 10000),
        "_routing": "TRIAGE_QUEUE",
        "_routing_reason": "Rozbieżność JPK ↔ KSeF — możliwe brakujące lub zdublowane faktury.",
        "_legal_basis": "struktura JPK_V7M; art. 109 ust. 3 ustawy o VAT (ewidencja)",
        "_warnings": ["[V3-11] Uzgodnij rejestry JPK z wysyłką KSeF przed złożeniem deklaracji."],
    })
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-11-007: WIS EXPIRY WATCHER — alert ostrzegawczy/krytyczny przed wygaśnięciem
#            zaświadczenia WIS (wis_expiry_warning/critical_days z thresholds)
# ═══════════════════════════════════════════════════════════════════════════════

_wis_routing(days, critical_days) = "TRIAGE_QUEUE" {
    days <= critical_days
} else = "WARNING"

_wis_warning(days, critical_days) = msg {
    days <= critical_days
    msg := "[V3-11] WIS wygasa krytycznie (<90 dni) — złóż wniosek teraz (opłata z thresholds)."
} else = msg {
    msg := "[V3-11] WIS wygasa (<180 dni) — zaplanuj odnowienie."
}

wis_expiry_decision := verdict {
    wis_certificate := object.get(input.wis_certificate, {}, {})
    object.get(wis_certificate, "held", false) == true

    warning_days := _th("wis_expiry_warning_days", 180)
    critical_days := _th("wis_expiry_critical_days", 90)
    # Brak pola days_to_expiry = certyfikat ważny (wartość spoza okna alertu).
    days := object.get(wis_certificate, "days_to_expiry", warning_days + 1)
    days <= warning_days

    verdict := _certificate(170, {
        "rule_id": "jdg.ksef_jpk.v3_11.wis_expiry_watcher",
        "procedure": "WIS_WATCHER_V3",
        "days_to_expiry": days,
        "warning_days": _th("wis_expiry_warning_days", 180),
        "critical_days": critical_days,
        "application_fee_pln": _th("wis_application_fee_pln", 40),
        "_routing": _wis_routing(days, critical_days),
        "_routing_reason": sprintf("Zaświadczenie WIS wygasa za %v dni — planuj wniosek o nowe.", [days]),
        "_legal_basis": "art. 42a-42h ustawy o VAT; opłata wis_application_fee_pln (thresholds)",
        "_warnings": [_wis_warning(days, critical_days)],
    })
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-11-008: DOMAIN CERTIFICATE — zbiorczy certyfikat domeny KSeF/JPK/
#            e-Doręczenia/ePUAP/WIS/ESIG (Golden Oracle F3 + Decision Cert. F4)
# ═══════════════════════════════════════════════════════════════════════════════

domain_certificate := _certificate(200, {
    "rule_id": "jdg.ksef_jpk.v3_11.domain_certificate",
    "decision_mode": "INFORM",
    "domain": "ksef_jpk_edeliveries_epuap_wis_esig",
    "ksef_mandatory_from": _ksef_mandatory_from,
    "offline_grace_days": _th("ksef_offline_grace_days", 7),
    "sandbox_enabled": object.get(_th_snapshot, "ksef_sandbox", false),
    "edelivery_mandatory_from": _th("edelivery_mandatory_from", "2026-01-01"),
    "snapshot_status": snapshot_status(_snapshot_ok),
    "_routing": "",
    "_routing_reason": "Domena KSeF/JPK/e-Doręczenia — brak zdarzeń decyzyjnych w tym inputcie.",
    "_legal_basis": "ustawa o VAT (art. 106na-106nq, 42a-42h); e-Doręczenia 2023; eIDAS 910/2014",
    "_warnings": [],
})

# ── Łańcuch decyzyjny first-match-wins ────────────────────────────────────────
decide := fail_closed_decision {
    not _snapshot_ok
}

decide := ksef_mandatory_decision {
    _snapshot_ok
}

decide := b2c_decision {
    _snapshot_ok
    not ksef_mandatory_decision
}

decide := offline_queue_decision {
    _snapshot_ok
    not ksef_mandatory_decision
    not b2c_decision
}

decide := upo_decision {
    _snapshot_ok
    not ksef_mandatory_decision
    not b2c_decision
    not offline_queue_decision
}

decide := edelivery_decision {
    _snapshot_ok
    not ksef_mandatory_decision
    not b2c_decision
    not offline_queue_decision
    not upo_decision
}

decide := reconcile_decision {
    _snapshot_ok
    not ksef_mandatory_decision
    not b2c_decision
    not offline_queue_decision
    not upo_decision
    not edelivery_decision
}

decide := wis_expiry_decision {
    _snapshot_ok
    not ksef_mandatory_decision
    not b2c_decision
    not offline_queue_decision
    not upo_decision
    not edelivery_decision
    not reconcile_decision
}

decide := domain_certificate {
    _snapshot_ok
}
