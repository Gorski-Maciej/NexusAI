#!/usr/bin/env python3
"""Tests for V3 P11 (DECISION_CERTIFICATE) — the 12 enterprise innovations.

Covers V3-P11-I01..I12 delivered by P11:
  * I01 certificate schema v1 (JSON superset of verdict + PDF mapping)
  * I02 Merkle daily tree (daily trees → monthly root → public register)
  * I03 offline verifier CLI (no-network verification + decade test)
  * I04 correction chain (supersedes-linked, backward-immutable)
  * I05 revocation manifest (signed CRL-style register, 4-eyes)
  * I06 KAS export bundle (certificates + merkle + legal snapshots + manifest)
  * I07 HSM key ceremony (real key, kid, rotation, DR, ceremony audit)
  * I08 trust UI pattern (layered explanation, status, show proof)
  * I09 tamper test suite (mutation → verification MUST fail)
  * I10 batch signing (aggregate root + latency SLO budget)
  * I11 long-term validation (timestamp, algo versioning, 50y retention)
  * I12 certificate golden link (golden verdicts have certificates)
"""
from __future__ import annotations

import json
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parents[2]
BUNDLES = BASE_DIR / "bundles"
REPORT = BASE_DIR / "raporty_glm52_v3" / "RAPORT_V3_P11_DECISION_CERTIFICATE.txt"
KONTRAKT = BASE_DIR / "docs" / "V3_P11_DECISION_CERTIFICATE_KONTRAKT.md"


def _load_bundle(name: str) -> dict:
    return json.loads((BUNDLES / name).read_text(encoding="utf-8"))


def test_report_and_kontrakt_exist():
    assert REPORT.exists()
    assert KONTRAKT.exists()
    txt = REPORT.read_text(encoding="utf-8")
    assert "WDROŻONY_100" in txt
    for marker in ("9.01 EXECUTIVE SUMMARY", "9.06 REJESTR LUK",
                   "9.07 INNOWACJE ENTERPRISE", "9.08 KONTRAKT WYJŚCIOWY",
                   "V3-P11-I01", "V3-P11-I12", "V3-P11-L01", "V3-P11-L07"):
        assert marker in txt, f"missing marker {marker}"


def test_i01_certificate_schema():
    d = _load_bundle("v3_p11_certificate_schema.json")
    assert d["innovation"] == "V3-P11-I01"
    assert d["metrics"]["certificate_count"] >= 1
    assert d["metrics"]["fields_completeness"] == 1.0  # top-level pola obecne
    assert any(f["id"] == "V3-P11-L01" for f in d["findings"])
    assert "pdf_sections" in d and len(d["pdf_sections"]) >= 6


def test_i02_merkle_daily_tree():
    d = _load_bundle("v3_p11_merkle_daily_tree.json")
    assert d["innovation"] == "V3-P11-I02"
    assert d["gate"] == "PASS"  # blockchain_audit_trail buduje drzewo Merkle
    assert d["metrics"]["audit_trail_merkle"] is True
    assert d["metrics"]["daily_period"] is True


def test_i03_offline_verifier():
    d = _load_bundle("v3_p11_offline_verifier.json")
    assert d["innovation"] == "V3-P11-I03"
    assert d["gate"] == "FAIL"
    assert d["metrics"]["decade_test"] is False  # L03 — brak testu dekady
    assert any(f["id"] == "V3-P11-L03" and f["severity"] == "P1"
               for f in d["findings"])


def test_i04_correction_chain():
    d = _load_bundle("v3_p11_correction_chain.json")
    assert d["innovation"] == "V3-P11-I04"
    assert d["gate"] == "FAIL"
    assert d["metrics"]["chain_field"] is False  # brak supersedes w kodzie
    assert d["metrics"]["linked_records"] is False
    assert any(f["id"] == "V3-P11-L04" for f in d["findings"])


def test_i05_revocation_manifest():
    d = _load_bundle("v3_p11_revocation_manifest.json")
    assert d["innovation"] == "V3-P11-I05"
    assert d["gate"] == "FAIL"
    assert d["metrics"]["revocation_mechanism"] is False  # brak revoke w narzędziach bazowych
    assert d["metrics"]["revocation_artifacts"] == []
    assert any(f["id"] == "V3-P11-L05" for f in d["findings"])


def test_i06_kas_export_bundle():
    d = _load_bundle("v3_p11_kas_export_bundle.json")
    assert d["innovation"] == "V3-P11-I06"
    assert d["gate"] == "FAIL"
    assert d["metrics"]["export_is_bundle"] is False  # tylko pojedynczy XML
    assert len(d["metrics"]["legal_snapshots"]) >= 1  # snapshoty P01 istnieją
    assert any(f["id"] == "V3-P11-L06" for f in d["findings"])


def test_i07_hsm_key_ceremony():
    d = _load_bundle("v3_p11_hsm_key_ceremony.json")
    assert d["innovation"] == "V3-P11-I07"
    assert d["gate"] == "FAIL"
    assert d["metrics"]["real_signing_key"] is False  # placeholder HSM-ECDSA-<hash>
    assert d["metrics"]["placeholder"] is True
    assert d["metrics"]["key_rotation"] is False
    # P0: placeholder podpisu zamiast prawdziwego klucza
    assert any(f["id"] == "V3-P11-L07" and f["severity"] == "P0"
               for f in d["findings"])


def test_i08_trust_ui_pattern():
    d = _load_bundle("v3_p11_trust_ui_pattern.json")
    assert d["innovation"] == "V3-P11-I08"
    assert d["gate"] == "FAIL"
    assert d["metrics"]["human_layer"] is True    # to_pdf_text istnieje
    assert d["metrics"]["layered"] is False        # ale brak wyjaśnienia warstwowego
    assert any(f["id"] == "V3-P11-L08" for f in d["findings"])


def test_i09_tamper_test_suite():
    d = _load_bundle("v3_p11_tamper_test_suite.json")
    assert d["innovation"] == "V3-P11-I09"
    assert d["gate"] == "FAIL"
    assert d["metrics"]["tamper_tests"] == []
    assert d["metrics"]["negative_assertions"] is False
    assert any(f["id"] == "V3-P11-L09" for f in d["findings"])


def test_i10_batch_signing():
    d = _load_bundle("v3_p11_batch_signing.json")
    assert d["innovation"] == "V3-P11-I10"
    assert d["gate"] == "FAIL"
    assert d["metrics"]["batch_signing"] is False  # podpis per werdykt
    assert any(f["id"] == "V3-P11-L10" for f in d["findings"])


def test_i11_long_term_validation():
    d = _load_bundle("v3_p11_long_term_validation.json")
    assert d["innovation"] == "V3-P11-I11"
    assert d["gate"] == "FAIL"
    assert d["metrics"]["timestamp"] is True
    assert d["metrics"]["retention_50y"] is False  # brak jawnej retencji 50 lat
    assert any(f["id"] == "V3-P11-L11" for f in d["findings"])


def test_i12_golden_link():
    d = _load_bundle("v3_p11_golden_link.json")
    assert d["innovation"] == "V3-P11-I12"
    assert d["gate"] == "FAIL"
    assert d["metrics"]["golden_verdicts"] >= 20
    assert d["metrics"]["certificates"] == 1
    assert d["metrics"]["coverage"] < 1.0  # golden bez certyfikatów
    assert any(f["id"] == "V3-P11-L12" and f["severity"] == "P1"
               for f in d["findings"])


def test_all_twelve_bundles_present():
    for name in ("v3_p11_certificate_schema", "v3_p11_merkle_daily_tree",
                 "v3_p11_offline_verifier", "v3_p11_correction_chain",
                 "v3_p11_revocation_manifest", "v3_p11_kas_export_bundle",
                 "v3_p11_hsm_key_ceremony", "v3_p11_trust_ui_pattern",
                 "v3_p11_tamper_test_suite", "v3_p11_batch_signing",
                 "v3_p11_long_term_validation", "v3_p11_golden_link"):
        d = _load_bundle(f"{name}.json")
        assert d["innovation"].startswith("V3-P11-I")
        assert "contract" in d and "checks" in d
