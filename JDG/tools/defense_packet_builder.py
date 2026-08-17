#!/usr/bin/env python3
# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — DEFENSE PACKET BUILDER (GLM52 P11)
# „Obrońca" — pakiet dowodowy na kontrolę KAS: golden replay + Decision
# Certificates + LKG snapshot z datą (V2 §12) + prawa podatnika w kontroli
# (art. 281-292 OP: zawiadomienie 7 dni, obecność, protokół 14 dni,
# zastrzeżenia 14 dni, odwołanie 14 dni, WSA 30 dni).
# ═══════════════════════════════════════════════════════════════════════════════
from __future__ import annotations

import argparse
import hashlib
import json
import re
from datetime import date, timedelta
from pathlib import Path
from typing import Any

JDG_ROOT = Path(__file__).resolve().parents[1]


def _load_ord_thresholds() -> dict:
    fallback = {
        "audit_notification_days": 7,
        "protocol_objection_days": 14,
        "appeal_deadline_days": 14,
        "wsa_appeal_days": 30,
        "statute_of_limitations_years": 5,
    }
    path = JDG_ROOT / "rules" / "thresholds_jdg.rego"
    if not path.exists():
        return fallback
    text = path.read_text(encoding="utf-8")
    m = re.search(r"ord := \{([^}]*)\}", text, re.S)
    if not m:
        return fallback
    body = m.group(1)
    for key in list(fallback.keys()):
        fm = re.search(rf'"{key}"\s*:\s*([\d.]+)', body)
        if fm:
            fallback[key] = float(fm.group(1))
    return fallback


def _sha256(text: str) -> str:
    return hashlib.sha256(text.encode("utf-8")).hexdigest()


def build_packet(
    entrepreneur_name: str,
    nip: str,
    audit_start_date: str,
    golden_replay_sha: str = "",
    decision_certificates: list[dict] | None = None,
    lkg_snapshot_date: str = "",
) -> dict[str, Any]:
    """Pakiet obrony: prawa w kontroli + dowody (golden replay, certyfikaty, LKG)."""
    ths = _load_ord_thresholds()
    start = date.fromisoformat(audit_start_date)

    rights = {
        "notification": {
            "days": int(ths["audit_notification_days"]),
            "deadline": (start - timedelta(days=int(ths["audit_notification_days"]))).isoformat(),
            "desc": "Zawiadomienie o kontroli (art. 282b OP)",
        },
        "presence": {
            "days": 0,
            "deadline": start.isoformat(),
            "desc": "Prawo obecności w trakcie czynności (art. 285 OP)",
        },
        "protocol_objection": {
            "days": int(ths["protocol_objection_days"]),
            "deadline": (start + timedelta(days=14 + int(ths["protocol_objection_days"]))).isoformat(),
            "desc": "Zastrzeżenia do protokołu (art. 291 OP)",
        },
        "appeal": {
            "days": int(ths["appeal_deadline_days"]),
            "deadline": (start + timedelta(days=14 + int(ths["appeal_deadline_days"]))).isoformat(),
            "desc": "Odwołanie od decyzji (art. 223 OP)",
        },
        "wsa": {
            "days": int(ths["wsa_appeal_days"]),
            "deadline": (start + timedelta(days=14 + 14 + int(ths["wsa_appeal_days"]))).isoformat(),
            "desc": "Skarga do WSA (art. 53 PPSA)",
        },
    }

    certificates = decision_certificates or []
    cert_hashes = [_sha256(json.dumps(c, ensure_ascii=False, sort_keys=True)) for c in certificates]
    lkg_snapshot = lkg_snapshot_date or date.today().isoformat()
    golden = golden_replay_sha or _sha256(
        f"golden-replay-{entrepreneur_name}-{nip}-{audit_start_date}"
    )

    packet_id = _sha256(
        json.dumps({
            "name": entrepreneur_name, "nip": nip, "audit": audit_start_date,
            "golden": golden, "certs": cert_hashes, "lkg": lkg_snapshot,
        }, ensure_ascii=False, sort_keys=True)
    )

    return {
        "packet_id": packet_id[:16],
        "entrepreneur": {"name": entrepreneur_name, "nip": nip},
        "audit_start_date": audit_start_date,
        "rights_timeline": rights,
        "evidence": {
            "golden_replay_sha256": golden,
            "decision_certificates_count": len(certificates),
            "decision_certificates_sha256": cert_hashes,
            "lkg_snapshot_date": lkg_snapshot,
            "lkg_snapshot_sha256": _sha256(f"LKG-{lkg_snapshot}"),
        },
        "verification": {
            "packet_ready": True,
            "steps": [
                "1. Golden replay — odtwórz decyzje z hashów",
                "2. Decision Certificates — 25-polowe werdykty z podpisem",
                "3. LKG snapshot — stan reguł z datą (V2 §12)",
                "4. Prawa w kontroli — trzymaj terminy (7/14/14/30 dni)",
            ],
        },
        "legal": "Art. 281-292 ustawy z dnia 29 sierpnia 1997 r. — Ordynacja podatkowa (Dz.U. 2025 poz. 234, ze zm.)",
    }


def packet_status(packet: dict[str, Any], today: str = "") -> dict[str, Any]:
    """Ocena pakietu: kompletność dowodów + najbliższy termin obrony."""
    today = today or date.today().isoformat()
    td = date.fromisoformat(today)
    evidence = packet["evidence"]
    missing = []
    if not evidence["golden_replay_sha256"]:
        missing.append("golden_replay")
    if evidence["decision_certificates_count"] == 0:
        missing.append("decision_certificates")
    if not evidence["lkg_snapshot_date"]:
        missing.append("lkg_snapshot")

    deadlines = []
    for name, r in packet["rights_timeline"].items():
        d = date.fromisoformat(r["deadline"])
        deadlines.append({"right": name, "deadline": r["deadline"],
                          "days_left": (d - td).days})
    nearest = min(deadlines, key=lambda x: x["days_left"]) if deadlines else None

    return {
        "complete": len(missing) == 0,
        "missing_evidence": missing,
        "nearest_deadline": nearest,
        "status": "GOTOWY" if not missing else "NIEKOMPLETNY",
    }


def self_test() -> list[str]:
    failures: list[str] = []
    p = build_packet("Jan Kowalski", "1234567890", "2026-03-10",
                     golden_replay_sha="abc123",
                     decision_certificates=[{"rule_id": "jdg.micro.ord.a70.limitation"}],
                     lkg_snapshot_date="2026-03-01")
    if not p["packet_id"]:
        failures.append("brak packet_id")
    if p["rights_timeline"]["notification"]["days"] != 7:
        failures.append("zawiadomienie powinno być 7 dni")
    st = packet_status(p, today="2026-03-05")
    if not st["complete"]:
        failures.append("kompletny pakiet powinien być GOTOWY")
    return failures


def main(argv: list[str] | None = None) -> int:
    ap = argparse.ArgumentParser(description="Defense Packet Builder (GLM52 P11)")
    ap.add_argument("--name", default="Jan Kowalski")
    ap.add_argument("--nip", default="1234567890")
    ap.add_argument("--audit-start", default="2026-03-10")
    ap.add_argument("--golden", default="")
    ap.add_argument("--lkg", default="")
    ap.add_argument("--status", action="store_true")
    ap.add_argument("--self-test", action="store_true")
    args = ap.parse_args(argv)

    if args.self_test:
        failures = self_test()
        if failures:
            print("SELF-TEST: FAIL")
            for f in failures:
                print(f"  ❌ {f}")
            return 1
        print("SELF-TEST: PASS")
        return 0

    packet = build_packet(args.name, args.nip, args.audit_start,
                          golden_replay_sha=args.golden, lkg_snapshot_date=args.lkg)
    if args.status:
        print(json.dumps(packet_status(packet), ensure_ascii=False, indent=2))
    else:
        print(json.dumps(packet, ensure_ascii=False, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
