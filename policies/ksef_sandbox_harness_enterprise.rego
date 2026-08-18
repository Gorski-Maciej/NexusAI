# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — ENTERPRISE KSeF SANDBOX HARNESS (Bonus Module, P18 v7.0)
# ═══════════════════════════════════════════════════════════════════════════════
#
# METADATA
# title: JDG Enterprise KSeF Sandbox Harness — Safe Test Environment Wrapper
# description: |
#   ENTERPRISE v7.0 — Nakładka testowa KSeF do bezpiecznego testowania
#   wysyłki faktur bez ryzyka produkcyjnego. Rozszerza KSR-1600 (test_status).
#
#   KLUCZOWE FUNKCJE:
#   - Przełącznik PROD/TEST environment
#   - Walidacja poprawności faktur testowych
#   - Symulacja błędów API (do testów resilience)
#   - Test batch upload (do 100 faktur)
#   - Test UPO generation i retencji
#   - Test trybu offline i recovery
#
# architecture: Enterprise v7.0 First-Match-Wins
# legal_basis: Specyfikacja API KSeF v2.0 (środowisko TEST)
# package: jdg.ksef_sandbox
# deprecated: false
# priority_range: 2420-2449
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.ksef_sandbox

import data.jdg.helpers

default decide := {
    "matched": false, "rule_id": "jdg.ksef_sandbox.no_match",
    "package": "jdg.ksef_sandbox", "priority": 9999
}

# ═══════════════════════════════════════════════════════════════════════════════
# KSB-2420: SANDBOX ENVIRONMENT SWITCH — Przełącznik PROD/TEST
# ═══════════════════════════════════════════════════════════════════════════════

decide := {
    "matched": true,
    "rule_id": "jdg.ksef_sandbox.environment_switch",
    "package": "jdg.ksef_sandbox",
    "priority": 2420,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "ksef_environment": env,
    "ksef_production_warning": prod_warning,
    "ksef_environment_switch_confirmed": confirmed,
    "_routing": env_routing,
    "_routing_reason": env_reason,
    "_legal_basis": "API KSeF — środowiska TEST i PRODUKCJA; Art. 106na VAT",
    "_warnings": [
        sprintf("🔧 KSeF ENVIRONMENT: %s", [env]),
        "─────────────────────────────────────────",
        sprintf("   %s", [prod_warning]),
        "   TEST: https://ksef-test.mf.gov.pl/api",
        "   PROD: https://ksef.mf.gov.pl/api",
    ]
} {
    input.ksef_sandbox_env_check == true
    env := object.get(input, "ksef_environment", "PRODUKCJA")

    prod_warning := "⚠️ ŚRODOWISKO PRODUKCYJNE — faktury mają skutki prawne! Zachowaj ostrożność." { env == "PRODUKCJA" }
    prod_warning := "✅ Środowisko TESTOWE — faktury NIE mają skutków prawnych. Bezpieczne testy." { env == "TEST" }

    confirmed := object.get(input, "ksef_env_warning_acknowledged", false)

    env_routing := "BLOCK_AND_ALERT" { env == "PRODUKCJA"; not confirmed }
    env_routing := "" { true }
    env_reason := "PROD bez potwierdzenia — potwierdź świadomość skutków prawnych." { env == "PRODUKCJA"; not confirmed }
    env_reason := "" { true }
}

# ═══════════════════════════════════════════════════════════════════════════════
# KSB-2430: SANDBOX ERROR SIMULATOR — Symulacja błędów do testów resilience
# ═══════════════════════════════════════════════════════════════════════════════

else := {
    "matched": true,
    "rule_id": "jdg.ksef_sandbox.error_simulator",
    "package": "jdg.ksef_sandbox",
    "priority": 2430,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "ksef_sim_error_type": error_type,
    "ksef_sim_http_code": http_code,
    "ksef_sim_retry_recommended": should_retry,
    "ksef_sim_test_scenario": scenario,
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": sprintf("SYMULACJA BŁĘDU: %s (%s) — test resilience.", [error_type, http_code]),
    "_legal_basis": "Enterprise Chaos Engineering; API KSeF Error Reference",
    "_warnings": [
        sprintf("🧪 KSeF SANDBOX — SYMULACJA BŁĘDU", []),
        sprintf("   Scenariusz: %s", [scenario]),
        sprintf("   Błąd API: %s (HTTP %s)", [error_type, http_code]),
        sprintf("   Retry: %s", ["TAK — system powinien ponowić." { should_retry } else "NIE — system NIE powinien ponawiać."]),
    ]
} {
    input.ksef_sandbox_simulate_error == true
    env := object.get(input, "ksef_environment", "PRODUKCJA")
    env == "TEST"  # Symulacja tylko w TEST

    scenario_input := object.get(input, "ksef_sim_scenario", "")
    error_types := {
        "AUTH_TOKEN_EXPIRED": {"code": "401", "retry": false, "desc": "Token autoryzacyjny wygasł"},
        "INVALID_XML": {"code": "400", "retry": false, "desc": "Niepoprawny XML FA(2)"},
        "DUPLICATE_INVOICE": {"code": "409", "retry": false, "desc": "Duplikat faktury"},
        "SERVER_ERROR": {"code": "500", "retry": true, "desc": "Błąd wewnętrzny serwera KSeF"},
        "SERVICE_UNAVAILABLE": {"code": "503", "retry": true, "desc": "KSeF niedostępny"},
        "GATEWAY_TIMEOUT": {"code": "504", "retry": true, "desc": "Timeout bramy KSeF"},
        "RATE_LIMIT": {"code": "429", "retry": true, "desc": "Przekroczony limit RPM"},
    }

    error_type := object.get(input, "ksef_sim_error", "SERVER_ERROR")
    error_info := object.get(error_types, error_type, {"code": "500", "retry": true, "desc": "Nieznany błąd"})
    http_code := error_info.code
    should_retry := error_info.retry
    scenario := error_info.desc { scenario_input == "" }
    scenario := scenario_input { scenario_input != "" }
}

# ═══════════════════════════════════════════════════════════════════════════════
# KSB-2440: SANDBOX BATCH TEST — Test wysyłki zbiorczej
# ═══════════════════════════════════════════════════════════════════════════════

else := {
    "matched": true,
    "rule_id": "jdg.ksef_sandbox.batch_test",
    "package": "jdg.ksef_sandbox",
    "priority": 2440,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "ksef_batch_test_count": batch_size,
    "ksef_batch_test_success_rate_pct": success_rate,
    "ksef_batch_test_avg_response_ms": avg_response_ms,
    "ksef_batch_test_upo_generated": upo_count,
    "_routing": batch_routing,
    "_routing_reason": batch_reason,
    "_legal_basis": "API KSeF Batch (max 100 faktur)",
    "_warnings": [
        sprintf("🧪 KSeF SANDBOX — TEST BATCH (środowisko TEST)", []),
        sprintf("   Wysłanych faktur: %d", [batch_size]),
        sprintf("   Sukces: %.0f%% | Średni czas: %d ms", [success_rate, avg_response_ms]),
        sprintf("   Wygenerowanych UPO: %d", [upo_count]),
    ]
} {
    input.ksef_sandbox_batch_test == true
    env := object.get(input, "ksef_environment", "PRODUKCJA")
    env == "TEST"

    batch_size := object.get(input, "ksef_batch_test_size", 0)
    success_count := object.get(input, "ksef_batch_test_success_count", 0)
    success_rate := success_count * 100 / max([batch_size, 1])
    avg_response_ms := object.get(input, "ksef_batch_test_avg_ms", 0)
    upo_count := object.get(input, "ksef_batch_test_upo_count", 0)

    batch_routing := "TRIAGE_QUEUE" { success_rate < 100 }
    batch_routing := "" { true }
    batch_reason := sprintf("Batch test: %.0f%% sukcesu — %d błędów do analizy.", [success_rate, batch_size - success_count]) { success_rate < 100 }
    batch_reason := "Batch test: 100% sukcesu — wszystkie faktury testowe wysłane." { success_rate == 100 }
}
