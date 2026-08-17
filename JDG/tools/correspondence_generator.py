#!/usr/bin/env python3
# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — CORRESPONDENCE GENERATOR (GLM52 P11)
# Generator pism do US/KAS: wyjaśnienia, zastrzeżenia do protokołu kontroli,
# odwołanie od decyzji, czynny żal (art. 16 KKS), wniosek o nadpłatę
# (art. 72-80 OP), wniosek o ulgę w spłacie (art. 67a OP).
# Każde pismo: nagłówek, podstawy prawne, treść z danymi, podpis.
# ═══════════════════════════════════════════════════════════════════════════════
from __future__ import annotations

import argparse
import json
from datetime import date
from typing import Any

DOC_TYPES = {
    "wyjasnienia": "Wyjaśnienia w sprawie",
    "zastrzezenia_protokol": "Zastrzeżenia do protokołu kontroli",
    "odwolanie": "Odwołanie od decyzji",
    "czynny_zal": "Czynny żal (art. 16 KKS)",
    "nadplata": "Wniosek o stwierdzenie nadpłaty",
    "ulga_splata": "Wniosek o ulgę w spłacie zobowiązania",
}

LEGAL_BASIS = {
    "wyjasnienia": "Art. 178 i 282b ustawy z dnia 29 sierpnia 1997 r. — Ordynacja podatkowa (Dz.U. 2025 poz. 234, ze zm.)",
    "zastrzezenia_protokol": "Art. 291 ustawy z dnia 29 sierpnia 1997 r. — Ordynacja podatkowa (Dz.U. 2025 poz. 234, ze zm.)",
    "odwolanie": "Art. 220-223 ustawy z dnia 29 sierpnia 1997 r. — Ordynacja podatkowa (Dz.U. 2025 poz. 234, ze zm.)",
    "czynny_zal": "Art. 16 ustawy z dnia 10 września 1999 r. — Kodeks karny skarbowy (Dz.U. 2025 poz. 678, ze zm.)",
    "nadplata": "Art. 72-80 ustawy z dnia 29 sierpnia 1997 r. — Ordynacja podatkowa (Dz.U. 2025 poz. 234, ze zm.)",
    "ulga_splata": "Art. 67a ustawy z dnia 29 sierpnia 1997 r. — Ordynacja podatkowa (Dz.U. 2025 poz. 234, ze zm.)",
}


def _templates() -> dict[str, str]:
    return {
        "wyjasnienia": (
            "W związku z wezwaniem z dnia {date} (sygn. {ref}) składam niniejsze wyjaśnienia "
            "w sprawie: {subject}.\n\nStan faktyczny: {facts}\n\n"
            "Ponownie podkreślam, że wszystkie dokumenty zostały przekazane w terminie "
            "i zgodnie ze stanem faktycznym."
        ),
        "zastrzezenia_protokol": (
            "Działając na podstawie art. 291 Ordynacji podatkowej, wnoszę następujące "
            "zastrzeżenia do protokołu kontroli z dnia {date} (sygn. {ref}):\n\n{facts}\n\n"
            "Zastrzeżenia składam w ustawowym terminie 14 dni od doręczenia protokołu."
        ),
        "odwolanie": (
            "Działając na podstawie art. 220-223 Ordynacji podatkowej, odwołuję się od "
            "decyzji z dnia {date} (sygn. {ref}) w całości.\n\n"
            "Zaskarżonej decyzji zarzucam: {facts}\n\n"
            "Wnoszę o uchylenie zaskarżonej decyzji w całości."
        ),
        "czynny_zal": (
            "Działając na podstawie art. 16 Kodeksu karnego skarbowego, zawiadamiam o "
            "popełnieniu czynu zabronionego polegającego na: {facts}.\n\n"
            "Zawiadomienie składam przed rozpoczęciem jakiegokolwiek postępowania "
            "w tej sprawie (czynny żal — znikoma szkodliwość społeczna czynu)."
        ),
        "nadplata": (
            "Działając na podstawie art. 72-80 Ordynacji podatkowej, wnoszę o stwierdzenie "
            "i zwrot nadpłaty w podatku: {subject}, w wysokości {facts} zł."
        ),
        "ulga_splata": (
            "Działając na podstawie art. 67a Ordynacji podatkowej, wnoszę o rozłożenie "
            "na raty / odroczenie terminu zapłaty zobowiązania w wysokości {facts} zł.\n\n"
            "Uzasadnienie: {subject}"
        ),
    }


def generate(
    doc_type: str,
    name: str,
    address: str,
    nip: str,
    date_str: str = "",
    ref: str = "",
    subject: str = "",
    facts: str = "",
    authority: str = "Naczelnik Urzędu Skarbowego",
) -> dict[str, Any]:
    """Generuje pismo z nagłówkiem, podstawą prawną i treścią."""
    date_str = date_str or date.today().isoformat()
    template = _templates().get(doc_type, _templates()["wyjasnienia"])
    body = template.format(date=date_str, ref=ref or "(brak sygn.)",
                           subject=subject or "(temat)", facts=facts or "(opis)")
    ref = ref or f"P{date_str.replace('-', '')}-{doc_type[:4].upper()}"

    return {
        "doc_type": doc_type,
        "title": DOC_TYPES[doc_type],
        "header": {
            "authority": authority,
            "sender": {"name": name, "address": address, "nip": nip},
            "date": date_str,
            "reference": ref,
        },
        "legal_basis": LEGAL_BASIS[doc_type],
        "body": body,
        "closing": "Z poważaniem,\n" + name,
        "signature_required": True,
    }


def generate_bundle(
    name: str, address: str, nip: str, audit_date: str, decision_ref: str,
) -> dict[str, Any]:
    """Komplet pism obrony na kontrolę: wyjaśnienia + zastrzeżenia + odwołanie."""
    return {
        "wyjasnienia": generate("wyjasnienia", name, address, nip,
                                date_str=audit_date, ref=decision_ref,
                                subject="kontrola podatkowa",
                                facts="Przekazuję komplet dokumentów i wyjaśnienia do stanu faktycznego."),
        "zastrzezenia_protokol": generate("zastrzezenia_protokol", name, address, nip,
                                          date_str=audit_date, ref=decision_ref,
                                          subject="protokół kontroli",
                                          facts="Ustalenia protokołu są niezgodne ze stanem faktycznym — wnoszę o ich korektę."),
        "odwolanie": generate("odwolanie", name, address, nip,
                              date_str=audit_date, ref=decision_ref,
                              subject="decyzja podatkowa",
                              facts="Decyzja narusza przepisy prawa materialnego i przepisy postępowania."),
        "czynny_zal": generate("czynny_zal", name, address, nip,
                               date_str=audit_date, ref=decision_ref,
                               subject="czynny żal",
                               facts="Nieprawidłowości w rozliczeniach — zawiadamiam przed wykryciem."),
    }


def self_test() -> list[str]:
    failures: list[str] = []
    p = generate("czynny_zal", "Jan Kowalski", "ul. Testowa 1", "1234567890",
                 date_str="2026-03-01", subject="nieprawidłowości VAT",
                 facts="zanizenie podatku należnego")
    if "art. 16" not in p["legal_basis"].lower():
        failures.append("czynny żal: podstawa art. 16 KKS")
    if "Kodeks karny skarbowy" not in p["legal_basis"]:
        failures.append("czynny żal: brak pełnej nazwy KKS")
    if not p["body"] or not p["header"]["sender"]["name"]:
        failures.append("pismo niekompletne")
    if "Dz.U. 2025 poz. 678" not in p["legal_basis"]:
        failures.append("czynny żal: niekanoniczne Dz.U.")
    bundle = generate_bundle("Jan Kowalski", "ul. Testowa 1", "1234567890",
                             "2026-03-01", "DEC/2026/01")
    if len(bundle) != 4:
        failures.append("bundle powinien zawierać 4 pisma")
    return failures


def main(argv: list[str] | None = None) -> int:
    ap = argparse.ArgumentParser(description="Correspondence Generator (GLM52 P11)")
    ap.add_argument("--type", choices=sorted(DOC_TYPES), default="czynny_zal")
    ap.add_argument("--name", default="Jan Kowalski")
    ap.add_argument("--address", default="ul. Przykładowa 1, 00-001 Warszawa")
    ap.add_argument("--nip", default="1234567890")
    ap.add_argument("--date", default="")
    ap.add_argument("--ref", default="")
    ap.add_argument("--subject", default="")
    ap.add_argument("--facts", default="")
    ap.add_argument("--bundle", action="store_true", help="komplet pism obrony")
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

    if args.bundle:
        out = generate_bundle(args.name, args.address, args.nip, args.date or date.today().isoformat(), args.ref)
    else:
        out = generate(args.type, args.name, args.address, args.nip,
                       date_str=args.date, ref=args.ref, subject=args.subject, facts=args.facts)
    print(json.dumps(out, ensure_ascii=False, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
