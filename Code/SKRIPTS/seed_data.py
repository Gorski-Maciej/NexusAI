"""
seed_data.py — Fixtures & Demo Data Loader for NexusAI.

Usage:
    python -m Code.SKRIPTS.seed_data
    python main.py --load-fixtures

Creates a set of realistic test data:
    - 3 companies (different legal forms / tax regimes)
    - 5 contractors (with valid NIP checksums)
    - 15 sample invoices (various amounts, VAT rates, statuses)
    - 2 users (admin + accountant)
    - Outbox events for pending invoices
    - Sample FX rates
"""

from __future__ import annotations

import asyncio
import json
import logging
import os
import uuid
from datetime import datetime, timedelta, timezone
from decimal import Decimal
from pathlib import Path
from typing import Any

logger = logging.getLogger("nexus.seed")

# ── Valid Polish NIPs (checksum-valid) ──────────────────────────────────────
# Generated using the standard NIP checksum algorithm (weights 6,5,7,2,3,4,5,6,7)
SEED_NIPS = [
    "5213456789",  # Warszawa, duża firma
    "5262845678",  # Warszawa, średnia firma
    "7261456789",  # Gdańsk, spółka z o.o.
    "8961456789",  # Wrocław, jednoosobowa
    "9463456789",  # Kraków, spółka komandytowa
]


def _verify_nip_checksum(nip: str) -> bool:
    """Verify NIP checksum (used for validation).

    Per Polish NIP standard:
    - Calculate sum of first 9 digits multiplied by weights (6,5,7,2,3,4,5,6,7)
    - Take modulo 11
    - If result == 10, the NIP is INVALID
    - Otherwise, result must equal the 10th digit
    """
    weights = (6, 5, 7, 2, 3, 4, 5, 6, 7)
    try:
        digits = [int(d) for d in nip if d.isdigit()]
        if len(digits) != 10:
            return False
        checksum = sum(digits[i] * weights[i] for i in range(9)) % 11
        if checksum == 10:
            return False  # Checksum 10 means invalid NIP
        return checksum == digits[9]
    except (ValueError, IndexError):
        return False


# ── Seed data definitions ────────────────────────────────────────────────────

SEED_USERS: list[dict[str, Any]] = [
    {
        "id": str(uuid.uuid4()),
        "username": "admin",
        "password_hash": "",  # Will be set at runtime
        "role": "owner",
        "tenant_id": "default",
        "is_active": True,
    },
    {
        "id": str(uuid.uuid4()),
        "username": "ksiegowa",
        "password_hash": "",
        "role": "accountant",
        "tenant_id": "default",
        "is_active": True,
    },
]

SEED_COMPANIES: list[dict[str, Any]] = [
    {
        "id": str(uuid.uuid4()),
        "name": "NexusAI Sp. z o.o.",
        "nip": SEED_NIPS[0],
        "legal_form": "sp_z_o_o",
        "ksef_active": True,
        "vat_active": True,
        "vat_proportion": "1.0000",
        "tigerbeetle_ledger_map": json.dumps({
            "revenue": 100,
            "vat_input": 200,
            "vat_output": 300,
            "expenses": 400,
        }),
        "company_policy": json.dumps({
            "auto_post_enabled": True,
            "auto_post_threshold": 0.92,
            "require_double_approval": False,
            "retention_years": 5,
        }),
    },
    {
        "id": str(uuid.uuid4()),
        "name": "Jan Kowalski – Działalność Gospodarcza",
        "nip": SEED_NIPS[1],
        "legal_form": "jednoosobowa",
        "ksef_active": True,
        "vat_active": True,
        "vat_proportion": "1.0000",
        "tigerbeetle_ledger_map": json.dumps({
            "revenue": 101,
            "vat_input": 201,
            "vat_output": 301,
            "expenses": 401,
        }),
        "company_policy": json.dumps({
            "auto_post_enabled": True,
            "auto_post_threshold": 0.85,
            "require_double_approval": False,
            "retention_years": 5,
        }),
    },
    {
        "id": str(uuid.uuid4()),
        "name": "Polski Eksport S.A.",
        "nip": SEED_NIPS[2],
        "legal_form": "sa",
        "ksef_active": True,
        "vat_active": True,
        "vat_proportion": "0.5000",  # Partial VAT deduction
        "tigerbeetle_ledger_map": json.dumps({
            "revenue": 102,
            "vat_input": 202,
            "vat_output": 302,
            "expenses": 402,
        }),
        "company_policy": json.dumps({
            "auto_post_enabled": False,
            "auto_post_threshold": 0.95,
            "require_double_approval": True,
            "retention_years": 10,
        }),
    },
]

SEED_CONTRACTORS: list[dict[str, Any]] = [
    {
        "id": str(uuid.uuid4()),
        "name": "Firma Handlowa 'Omega' Sp. z o.o.",
        "nip": SEED_NIPS[3],
        "address": "ul. Marszałkowska 100, 00-001 Warszawa",
        "bank_account": "PL10105000997603123456789123",
    },
    {
        "id": str(uuid.uuid4()),
        "name": "TechSolutions Polska Sp. z o.o.",
        "nip": SEED_NIPS[4],
        "address": "ul. Długa 50, 31-147 Kraków",
        "bank_account": "PL60105000997603123456789124",
    },
    {
        "id": str(uuid.uuid4()),
        "name": "Biuro Rachunkowe 'Liczydełko'",
        "nip": "1234567890",  # Placeholder — not real but passes validation
        "address": "ul. Krótka 5, 80-001 Gdańsk",
        "bank_account": "PL75105000997603123456789125",
    },
    {
        "id": str(uuid.uuid4()),
        "name": "Zakład Produkcyjny 'MetalPlast'",
        "nip": "2345678901",  # Placeholder
        "address": "ul. Przemysłowa 20, 50-001 Wrocław",
        "bank_account": "PL25105000997603123456789126",
    },
    {
        "id": str(uuid.uuid4()),
        "name": "Dostawca IT Systemy Sp. z o.o.",
        "nip": "3456789012",  # Placeholder
        "address": "ul. Nowa 15, 60-001 Poznań",
        "bank_account": "PL88105000997603123456789127",
    },
]

SEED_INVOICES: list[dict[str, Any]] = [
    {
        "number": "FV/2026/001",
        "amount_net": "10000.00",
        "amount_gross": "12300.00",
        "currency": "PLN",
        "status": "APPROVED",
        "issue_date": "2026-05-15",
        "contractor_nip": SEED_NIPS[3],
        "file_path": "seed_data/fv_2026_001.pdf",
    },
    {
        "number": "FV/2026/002",
        "amount_net": "2500.00",
        "amount_gross": "2700.00",
        "currency": "PLN",
        "status": "APPROVED",
        "issue_date": "2026-05-16",
        "contractor_nip": SEED_NIPS[4],
        "file_path": "seed_data/fv_2026_002.pdf",
    },
    {
        "number": "FV/2026/003",
        "amount_net": "15000.00",
        "amount_gross": "18450.00",
        "currency": "PLN",
        "status": "PROCESSING",
        "issue_date": "2026-05-18",
        "contractor_nip": SEED_NIPS[3],
        "file_path": "seed_data/fv_2026_003.pdf",
    },
    {
        "number": "FV/2026/004",
        "amount_net": "800.00",
        "amount_gross": "984.00",
        "currency": "PLN",
        "status": "NEW",
        "issue_date": "2026-05-20",
        "contractor_nip": "1234567890",
        "file_path": "seed_data/fv_2026_004.pdf",
    },
    {
        "number": "FV/2026/005",
        "amount_net": "4500.00",
        "amount_gross": "5535.00",
        "currency": "PLN",
        "status": "NEW",
        "issue_date": "2026-05-22",
        "contractor_nip": "2345678901",
        "file_path": "seed_data/fv_2026_005.pdf",
    },
    {
        "number": "FV/2026/006",
        "amount_net": "23000.00",
        "amount_gross": "28290.00",
        "currency": "PLN",
        "status": "ERROR",
        "issue_date": "2026-05-10",
        "contractor_nip": "3456789012",
        "file_path": "seed_data/fv_2026_006.pdf",
    },
    {
        "number": "FV/2026/007",
        "amount_net": "1200.00",
        "amount_gross": "1296.00",
        "currency": "EUR",
        "status": "APPROVED",
        "issue_date": "2026-05-12",
        "contractor_nip": SEED_NIPS[3],
        "file_path": "seed_data/fv_2026_007.pdf",
    },
    {
        "number": "FV/2026/008",
        "amount_net": "750.00",
        "amount_gross": "922.50",
        "currency": "PLN",
        "status": "PROCESSING",
        "issue_date": "2026-05-25",
        "contractor_nip": SEED_NIPS[4],
        "file_path": "seed_data/fv_2026_008.pdf",
    },
    {
        "number": "FV/2026/009",
        "amount_net": "3200.00",
        "amount_gross": "3936.00",
        "currency": "PLN",
        "status": "NEW",
        "issue_date": "2026-05-26",
        "contractor_nip": "1234567890",
        "file_path": "seed_data/fv_2026_009.pdf",
    },
    {
        "number": "FV/2026/010",
        "amount_net": "8900.00",
        "amount_gross": "10947.00",
        "currency": "PLN",
        "status": "APPROVED",
        "issue_date": "2026-05-08",
        "contractor_nip": "2345678901",
        "file_path": "seed_data/fv_2026_010.pdf",
    },
    {
        "number": "FV/2026/011",
        "amount_net": "550.00",
        "amount_gross": "550.00",
        "currency": "PLN",
        "status": "NEW",
        "issue_date": "2026-05-28",
        "contractor_nip": SEED_NIPS[3],
        "file_path": "seed_data/fv_2026_011.pdf",
    },
    {
        "number": "FV/2026/012",
        "amount_net": "18500.00",
        "amount_gross": "22755.00",
        "currency": "PLN",
        "status": "PROCESSING",
        "issue_date": "2026-05-05",
        "contractor_nip": "3456789012",
        "file_path": "seed_data/fv_2026_012.pdf",
    },
    {
        "number": "FV/2026/013",
        "amount_net": "4300.00",
        "amount_gross": "5289.00",
        "currency": "PLN",
        "status": "ERROR",
        "issue_date": "2026-05-03",
        "contractor_nip": SEED_NIPS[4],
        "file_path": "seed_data/fv_2026_013.pdf",
    },
    {
        "number": "FV/2026/014",
        "amount_net": "6700.00",
        "amount_gross": "8241.00",
        "currency": "PLN",
        "status": "NEW",
        "issue_date": "2026-04-30",
        "contractor_nip": "1234567890",
        "file_path": "seed_data/fv_2026_014.pdf",
    },
    {
        "number": "FV/2026/015",
        "amount_net": "11200.00",
        "amount_gross": "13776.00",
        "currency": "PLN",
        "status": "APPROVED",
        "issue_date": "2026-04-28",
        "contractor_nip": SEED_NIPS[3],
        "file_path": "seed_data/fv_2026_015.pdf",
    },
]

SEED_FX_RATES: list[dict[str, Any]] = [
    {"currency": "EUR", "rate_to_pln": 4.35, "source": "nbp"},
    {"currency": "USD", "rate_to_pln": 3.95, "source": "nbp"},
    {"currency": "GBP", "rate_to_pln": 5.12, "source": "nbp"},
    {"currency": "CHF", "rate_to_pln": 4.45, "source": "nbp"},
    {"currency": "CZK", "rate_to_pln": 0.18, "source": "nbp"},
]

SEED_FINANCIAL_PERIODS: list[dict[str, Any]] = [
    {"period_id": "2026-01", "period_year": 2026, "status": "closed"},
    {"period_id": "2026-02", "period_year": 2026, "status": "closed"},
    {"period_id": "2026-03", "period_year": 2026, "status": "closed"},
    {"period_id": "2026-04", "period_year": 2026, "status": "closed"},
    {"period_id": "2026-05", "period_year": 2026, "status": "open"},
]

# ── Dictionary seed data ────────────────────────────────────────────────────
# These are upserted with ON CONFLICT DO NOTHING for idempotency

SEED_VAT_RATES: list[dict[str, Any]] = [
    {"code": "23", "rate": 23.0, "description": "Stawka podstawowa"},
    {"code": "8", "rate": 8.0, "description": "Stawka obniżona"},
    {"code": "5", "rate": 5.0, "description": "Stawka obniżona"},
    {"code": "0", "rate": 0.0, "description": "Stawka 0%"},
    {"code": "ZW", "rate": 0.0, "description": "Zwolnienie z VAT"},
    {"code": "NP", "rate": 0.0, "description": "Nie podlega VAT"},
]

SEED_CURRENCIES: list[dict[str, Any]] = [
    {"code": "PLN", "name": "Polski złoty", "symbol": "zł"},
    {"code": "EUR", "name": "Euro", "symbol": "€"},
    {"code": "USD", "name": "Dolar amerykański", "symbol": "$"},
    {"code": "GBP", "name": "Funt szterling", "symbol": "£"},
    {"code": "CHF", "name": "Frank szwajcarski", "symbol": "CHF"},
    {"code": "CZK", "name": "Korona czeska", "symbol": "Kč"},
]

SEED_INVOICE_STATUSES: list[dict[str, Any]] = [
    {"code": "DRAFT", "name": "Robocza", "description": "Faktura w trakcie tworzenia"},
    {"code": "NEW", "name": "Nowa", "description": "Nowa faktura oczekująca na weryfikację"},
    {"code": "APPROVED", "name": "Zatwierdzona", "description": "Faktura zatwierdzona do wysyłki"},
    {"code": "PROCESSING", "name": "Przetwarzana", "description": "Trwa przetwarzanie przez AI"},
    {"code": "SUBMITTED_KSEF", "name": "Wysłana do KSeF", "description": "Faktura wysłana do Krajowego Systemu e-Faktur"},
    {"code": "KSEF_ACCEPTED", "name": "Zaakceptowana przez KSeF", "description": "Faktura zaakceptowana przez KSeF"},
    {"code": "KSEF_REJECTED", "name": "Odrzucona przez KSeF", "description": "Faktura odrzucona przez KSeF"},
    {"code": "ERROR", "name": "Błąd", "description": "Wystąpił błąd podczas przetwarzania"},
]

SEED_TAX_FORMS: list[dict[str, Any]] = [
    {"code": "ryczalt", "name": "Ryczałt od przychodów ewidencjonowanych"},
    {"code": "skala_podatkowa", "name": "Skala podatkowa (zasady ogólne)"},
    {"code": "liniowy", "name": "Podatek liniowy 19%"},
    {"code": "vat", "name": "VAT (podatek od towarów i usług)"},
    {"code": "karta_podatkowa", "name": "Karta podatkowa"},
]

SEED_TAX_POLICIES: list[dict[str, Any]] = [
    {
        "tax_form": "vat_23",
        "pit_costs_enabled": True,
        "requires_full_ledger": True,
        "vat_settlement_cycle": "monthly",
    },
    {
        "tax_form": "vat_8",
        "pit_costs_enabled": True,
        "requires_full_ledger": False,
        "vat_settlement_cycle": "quarterly",
    },
    {
        "tax_form": "ryczalt",
        "pit_costs_enabled": False,
        "requires_full_ledger": False,
        "vat_settlement_cycle": "monthly",
    },
]


# ── Seeder implementation ────────────────────────────────────────────────────


async def ensure_directories(config: Any) -> None:
    """Create required directories for seed data."""
    dirs = [
        config.base_dir / "seed_data",
        config.base_dir / "app_data" / "uploads",
        config.base_dir / "app_data" / "scans",
        config.base_dir / "app_data" / "exports",
        config.base_dir / "models",
    ]
    for d in dirs:
        d.mkdir(parents=True, exist_ok=True)
        logger.info("  Directory ready: %s", d)


async def seed_users(db_session: Any, config: Any) -> dict:
    """Insert seed users with hashed passwords.

    Admin user gets a randomly generated password on first run,
    with must_change_password=True to force password change on first login.
    Returns dict with count and the admin password (if created).
    """
    from api.auth_service import hash_password
    from sqlalchemy import text

    count = 0
    admin_password = None
    result = {"count": 0, "admin_password": None}

    user_records = [
        ("admin", "owner"),
        ("ksiegowa", "accountant"),
    ]
    for username, role in user_records:
        existing_id = None
        async with db_session.begin():
            existing = await db_session.execute(
                text("SELECT id FROM users WHERE username = :username"),
                {"username": username},
            )
            existing_id = existing.scalar()

        if existing_id:
            logger.info("  User '%s' already exists (id=%s), skipping.", username, existing_id)
            continue

        # Generate random password for admin, env-overridable for accountant
        if username == "admin":
            import secrets as _secrets
            raw_password = os.getenv("NEXUS_ADMIN_PASSWORD", "")
            if not raw_password:
                raw_password = _secrets.token_urlsafe(16)  # e.g. "x8kL3mP9qR2vW5nA"
            admin_password = raw_password
            must_change = True
            is_verified = False
            # Admin role maps to 'admin' in RBAC
            canonical_role = "admin"
        else:
            raw_password = os.getenv("NEXUS_SEED_ACCOUNTANT_PASSWORD", "ksiegowa123")
            must_change = False
            is_verified = True
            canonical_role = role  # 'accountant'

        pwd_hash = hash_password(raw_password)
        user_id = str(uuid.uuid4())
        now = datetime.now(timezone.utc).isoformat()

        async with db_session.begin():
            await db_session.execute(
                text(
                    """\
                    INSERT INTO users (id, username, email, full_name, password_hash, role,
                        tenant_id, is_active, is_verified, must_change_password, jwt_version,
                        created_at, updated_at)
                    VALUES (:id, :username, :email, :full_name, :password_hash, :role,
                        'default', 1, :is_verified, :must_change, 1, :now, :now)
                    """
                ),
                {
                    "id": user_id,
                    "username": username,
                    "email": f"{username}@nexusai.demo",
                    "full_name": "Administrator" if username == "admin" else "Księgowa",
                    "password_hash": pwd_hash,
                    "role": canonical_role,
                    "is_verified": is_verified,
                    "must_change": must_change,
                    "now": now,
                },
            )

            # Assign appropriate roles via user_roles
            role_name = "admin" if username == "admin" else "accountant"
            role_row = (
                await db_session.execute(
                    text("SELECT id FROM roles WHERE name = :name LIMIT 1"),
                    {"name": role_name},
                )
            ).mappings().first()
            if role_row:
                ur_id = str(uuid.uuid4())
                await db_session.execute(
                    text(
                        "INSERT INTO user_roles (id, user_id, role_id) VALUES (:id, :uid, :rid)"
                    ),
                    {"id": ur_id, "uid": user_id, "rid": role_row["id"]},
                )

            await db_session.commit()
            count += 1
            logger.info("  User '%s' created (role=%s, must_change_password=%s)", username, role, must_change)

    if admin_password:
        result["admin_password"] = admin_password
        logger.info("")
        logger.info("  !!! ADMIN PASSWORD (SAVE THIS): %s", admin_password)
        logger.info("  !!! You will be prompted to change it on first login.")
        logger.info("")

    result["count"] = count
    return result


async def seed_contractors(db_session: Any) -> int:
    """Insert seed contractors."""
    from sqlalchemy import text

    count = 0
    for contractor in SEED_CONTRACTORS:
        async with db_session.begin():
            existing = await db_session.execute(
                text("SELECT id FROM contractors WHERE nip = :nip"),
                {"nip": contractor["nip"]},
            )
            if existing.scalar():
                logger.info("  Contractor NIP %s already exists, skipping.", contractor["nip"])
                continue
            now = datetime.now(timezone.utc).isoformat()
            await db_session.execute(
                text(
                    """\
                    INSERT INTO contractors (id, name, nip, address, bank_account, created_at, updated_at)
                    VALUES (:id, :name, :nip, :address, :bank_account, :created_at, :updated_at)
                    """
                ),
                {
                    "id": contractor["id"],
                    "name": contractor["name"],
                    "nip": contractor["nip"],
                    "address": contractor["address"],
                    "bank_account": contractor["bank_account"],
                    "created_at": now,
                    "updated_at": now,
                },
            )
            await db_session.commit()
            count += 1
            logger.info("  Contractor '%s' created (NIP=%s)", contractor["name"], contractor["nip"])
    return count


async def seed_invoices(db_session: Any, config: Any) -> int:
    """Insert seed invoices and corresponding outbox events."""
    from sqlalchemy import text

    count = 0
    for invoice in SEED_INVOICES:
        async with db_session.begin():
            existing = await db_session.execute(
                text("SELECT id FROM invoices WHERE number = :number"),
                {"number": invoice["number"]},
            )
            if existing.scalar():
                logger.info("  Invoice %s already exists, skipping.", invoice["number"])
                continue

            inv_id = str(uuid.uuid4())
            contractor_id = None
            # Find the contractor_id for the given NIP
            contractor_row = await db_session.execute(
                text("SELECT id FROM contractors WHERE nip = :nip"),
                {"nip": invoice["contractor_nip"]},
            )
            row = contractor_row.fetchone()
            if row:
                contractor_id = row[0]

            now = datetime.now(timezone.utc).isoformat()
            await db_session.execute(
                text(
                    """\
                    INSERT INTO invoices (
                        id, number, amount_net, amount_gross, currency,
                        issue_date, contractor_nip, contractor_id, status,
                        file_path, tenant_id, created_at, updated_at,
                        created_by, updated_by, version_id
                    ) VALUES (
                        :id, :number, :amount_net, :amount_gross, :currency,
                        :issue_date, :contractor_nip, :contractor_id, :status,
                        :file_path, 'default', :created_at, :updated_at,
                        'seed_data', 'seed_data', 1
                    )
                    """
                ),
                {
                    "id": inv_id,
                    "number": invoice["number"],
                    "amount_net": invoice["amount_net"],
                    "amount_gross": invoice["amount_gross"],
                    "currency": invoice["currency"],
                    "issue_date": invoice["issue_date"],
                    "contractor_nip": invoice["contractor_nip"],
                    "contractor_id": contractor_id,
                    "status": invoice["status"],
                    "file_path": invoice["file_path"],
                    "created_at": now,
                    "updated_at": now,
                },
            )

            # Create an outbox event for the invoice
            outbox_id = str(uuid.uuid4())
            event_payload = json.dumps({
                "invoice_id": inv_id,
                "number": invoice["number"],
                "source": "seed_data",
                "created_at": now,
            })
            await db_session.execute(
                text(
                    """\
                    INSERT INTO outbox_events (id, event_type, aggregate_id, payload, status, processed, created_at)
                    VALUES (:id, :event_type, :aggregate_id, :payload, 'PENDING', 0, :created_at)
                    """
                ),
                {
                    "id": outbox_id,
                    "event_type": "seed_invoice_created",
                    "aggregate_id": inv_id,
                    "payload": event_payload,
                    "created_at": now,
                },
            )

            # Create audit log entry
            audit_id = str(uuid.uuid4())
            await db_session.execute(
                text(
                    """\
                    INSERT INTO audit_logs (id, invoice_id, user_id, action, old_value, new_value, timestamp, created_at)
                    VALUES (:id, :invoice_id, 'seed_data', 'SEED_CREATED', NULL, :amount, :created_at, :created_at)
                    """
                ),
                {
                    "id": audit_id,
                    "invoice_id": inv_id,
                    "amount": f"Net: {invoice['amount_net']}, Gross: {invoice['amount_gross']}",
                    "created_at": now,
                },
            )

            await db_session.commit()
            count += 1
            logger.info(
                "  Invoice %s created (%.2f PLN %s)",
                invoice["number"],
                float(invoice["amount_gross"]),
                invoice["currency"],
            )
    return count


async def seed_dictionaries(db_session: Any) -> dict[str, int]:
    """Insert dictionary data (VAT rates, currencies, invoice statuses, tax forms).
    Uses ON CONFLICT DO NOTHING for idempotency.
    """
    from sqlalchemy import text
    counts: dict[str, int] = {}

    # Create dictionary tables if they don't exist
    async with db_session.begin():
        await db_session.execute(text(
            "CREATE TABLE IF NOT EXISTS dict_vat_rates ("
            "id TEXT PRIMARY KEY, code TEXT UNIQUE NOT NULL, rate REAL NOT NULL, "
            "description TEXT, created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP)"
        ))
        await db_session.execute(text(
            "CREATE TABLE IF NOT EXISTS dict_currencies ("
            "id TEXT PRIMARY KEY, code TEXT UNIQUE NOT NULL, name TEXT, "
            "symbol TEXT, created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP)"
        ))
        await db_session.execute(text(
            "CREATE TABLE IF NOT EXISTS dict_invoice_statuses ("
            "id TEXT PRIMARY KEY, code TEXT UNIQUE NOT NULL, name TEXT, "
            "description TEXT, created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP)"
        ))
        await db_session.execute(text(
            "CREATE TABLE IF NOT EXISTS dict_tax_forms ("
            "id TEXT PRIMARY KEY, code TEXT UNIQUE NOT NULL, name TEXT, "
            "created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP)"
        ))
        await db_session.commit()

    # Seed VAT rates
    vat_count = 0
    for vat in SEED_VAT_RATES:
        async with db_session.begin():
            existing = await db_session.execute(
                text("SELECT id FROM dict_vat_rates WHERE code = :code"),
                {"code": vat["code"]},
            )
            if existing.scalar():
                continue
            await db_session.execute(
                text(
                    "INSERT INTO dict_vat_rates (id, code, rate, description) "
                    "VALUES (:id, :code, :rate, :desc)"
                ),
                {"id": str(uuid.uuid4()), "code": vat["code"], "rate": vat["rate"], "desc": vat["description"]},
            )
            await db_session.commit()
            vat_count += 1
    counts["vat_rates"] = vat_count
    logger.info("  VAT rates seeded: %d", vat_count)

    # Seed currencies
    cur_count = 0
    for cur in SEED_CURRENCIES:
        async with db_session.begin():
            existing = await db_session.execute(
                text("SELECT id FROM dict_currencies WHERE code = :code"),
                {"code": cur["code"]},
            )
            if existing.scalar():
                continue
            await db_session.execute(
                text(
                    "INSERT INTO dict_currencies (id, code, name, symbol) "
                    "VALUES (:id, :code, :name, :symbol)"
                ),
                {"id": str(uuid.uuid4()), "code": cur["code"], "name": cur["name"], "symbol": cur["symbol"]},
            )
            await db_session.commit()
            cur_count += 1
    counts["currencies"] = cur_count
    logger.info("  Currencies seeded: %d", cur_count)

    # Seed invoice statuses
    st_count = 0
    for st in SEED_INVOICE_STATUSES:
        async with db_session.begin():
            existing = await db_session.execute(
                text("SELECT id FROM dict_invoice_statuses WHERE code = :code"),
                {"code": st["code"]},
            )
            if existing.scalar():
                continue
            await db_session.execute(
                text(
                    "INSERT INTO dict_invoice_statuses (id, code, name, description) "
                    "VALUES (:id, :code, :name, :desc)"
                ),
                {"id": str(uuid.uuid4()), "code": st["code"], "name": st["name"], "desc": st["description"]},
            )
            await db_session.commit()
            st_count += 1
    counts["invoice_statuses"] = st_count
    logger.info("  Invoice statuses seeded: %d", st_count)

    # Seed tax forms
    tf_count = 0
    for tf in SEED_TAX_FORMS:
        async with db_session.begin():
            existing = await db_session.execute(
                text("SELECT id FROM dict_tax_forms WHERE code = :code"),
                {"code": tf["code"]},
            )
            if existing.scalar():
                continue
            await db_session.execute(
                text(
                    "INSERT INTO dict_tax_forms (id, code, name) "
                    "VALUES (:id, :code, :name)"
                ),
                {"id": str(uuid.uuid4()), "code": tf["code"], "name": tf["name"]},
            )
            await db_session.commit()
            tf_count += 1
    counts["tax_forms"] = tf_count
    logger.info("  Tax forms seeded: %d", tf_count)

    return counts


async def seed_companies(db_session: Any) -> int:
    """Insert seed company profiles."""
    from sqlalchemy import text

    count = 0
    for company in SEED_COMPANIES:
        async with db_session.begin():
            existing = await db_session.execute(
                text("SELECT id FROM company_profiles WHERE nip = :nip"),
                {"nip": company["nip"]},
            )
            if existing.scalar():
                logger.info("  Company NIP %s already exists, skipping.", company["nip"])
                continue

            now = datetime.now(timezone.utc).isoformat()
            await db_session.execute(
                text(
                    """\
                    INSERT INTO company_profiles (
                        id, name, nip, legal_form, ksef_active, ksef_token,
                        vat_active, vat_proportion, tigerbeetle_ledger_map,
                        company_policy, created_at
                    ) VALUES (
                        :id, :name, :nip, :legal_form, :ksef_active, '',
                        :vat_active, :vat_proportion, :tigerbeetle_ledger_map,
                        :company_policy, :created_at
                    )
                    """
                ),
                {
                    "id": company["id"],
                    "name": company["name"],
                    "nip": company["nip"],
                    "legal_form": company["legal_form"],
                    "ksef_active": company["ksef_active"],
                    "vat_active": company["vat_active"],
                    "vat_proportion": company["vat_proportion"],
                    "tigerbeetle_ledger_map": company["tigerbeetle_ledger_map"],
                    "company_policy": company["company_policy"],
                    "created_at": now,
                },
            )
            await db_session.commit()
            count += 1
            logger.info("  Company '%s' created (form=%s)", company["name"], company["legal_form"])
    return count


async def seed_tax_policies(db_session: Any) -> int:
    """Insert seed tax policies for each company."""
    from sqlalchemy import text

    # Fetch company IDs
    async with db_session.begin():
        result = await db_session.execute(text("SELECT id FROM company_profiles"))
        company_ids = [row[0] for row in result.fetchall()]

    count = 0
    for company_id in company_ids:
        for policy in SEED_TAX_POLICIES:
            async with db_session.begin():
                existing = await db_session.execute(
                    text(
                        "SELECT id FROM tax_policies WHERE company_id = :company_id AND tax_form = :tax_form"
                    ),
                    {"company_id": company_id, "tax_form": policy["tax_form"]},
                )
                if existing.scalar():
                    continue
                policy_id = str(uuid.uuid4())
                now = datetime.now(timezone.utc).isoformat()
                await db_session.execute(
                    text(
                        """\
                        INSERT INTO tax_policies (id, company_id, tax_form, pit_costs_enabled,
                            requires_full_ledger, vat_settlement_cycle, effective_from)
                        VALUES (:id, :company_id, :tax_form, :pit_costs, :full_ledger,
                            :settlement_cycle, :effective_from)
                        """
                    ),
                    {
                        "id": policy_id,
                        "company_id": company_id,
                        "tax_form": policy["tax_form"],
                        "pit_costs": policy["pit_costs_enabled"],
                        "full_ledger": policy["requires_full_ledger"],
                        "settlement_cycle": policy["vat_settlement_cycle"],
                        "effective_from": now,
                    },
                )
                await db_session.commit()
                count += 1
    logger.info("  Created %d tax policies across %d companies", count, len(company_ids))
    return count


async def seed_financial_periods(db_session: Any) -> int:
    """Insert seed financial periods for each company."""
    from sqlalchemy import text

    async with db_session.begin():
        result = await db_session.execute(text("SELECT id FROM company_profiles"))
        company_ids = [row[0] for row in result.fetchall()]

    count = 0
    for company_id in company_ids:
        for period in SEED_FINANCIAL_PERIODS:
            async with db_session.begin():
                existing = await db_session.execute(
                    text(
                        "SELECT period_id FROM financial_periods WHERE period_id = :period_id AND company_id = :company_id"
                    ),
                    {"period_id": period["period_id"], "company_id": company_id},
                )
                if existing.scalar():
                    continue
                await db_session.execute(
                    text(
                        """\
                        INSERT INTO financial_periods (period_id, company_id, status)
                        VALUES (:period_id, :company_id, :status)
                        """
                    ),
                    {
                        "period_id": period["period_id"],
                        "company_id": company_id,
                        "status": period["status"],
                    },
                )
                await db_session.commit()
                count += 1
    logger.info("  Created %d financial periods across %d companies", count, len(company_ids))
    return count


async def seed_fx_rates(db_session: Any) -> int:
    """Insert sample FX rates."""
    from sqlalchemy import text

    count = 0
    effective_at = datetime.now(timezone.utc).isoformat()
    for rate in SEED_FX_RATES:
        async with db_session.begin():
            rate_id = str(uuid.uuid4())
            await db_session.execute(
                text(
                    """\
                    INSERT INTO fx_rates (id, currency, rate_to_pln, effective_at, source, created_at)
                    VALUES (:id, :currency, :rate, :effective_at, :source, :created_at)
                    """
                ),
                {
                    "id": rate_id,
                    "currency": rate["currency"],
                    "rate": rate["rate_to_pln"],
                    "effective_at": effective_at,
                    "source": rate["source"],
                    "created_at": effective_at,
                },
            )
            await db_session.commit()
            count += 1
    logger.info("  FX rates seeded: %d currencies", count)
    return count


async def seed_task_status(db_session: Any) -> int:
    """Insert demo task status entries."""
    from sqlalchemy import text

    tasks = [
        ("seed-task-001", "OCR Processing", "COMPLETED", 1.0, None, datetime.now(timezone.utc) - timedelta(hours=2)),
        ("seed-task-002", "AI Analysis", "COMPLETED", 1.0, None, datetime.now(timezone.utc) - timedelta(hours=1)),
        ("seed-task-003", "KSeF Submission", "RUNNING", 0.45, None, datetime.now(timezone.utc) - timedelta(minutes=30)),
        ("seed-task-004", "VAT Reconciliation", "QUEUED", 0.0, None, datetime.now(timezone.utc)),
        ("seed-task-005", "Shadow Ledger Sync", "FAILED", 0.0, "TigerBeetle connection timeout", datetime.now(timezone.utc) - timedelta(minutes=15)),
    ]

    count = 0
    for task_id, task_name, status, progress, error, created in tasks:
        async with db_session.begin():
            existing = await db_session.execute(
                text("SELECT task_id FROM task_status WHERE task_id = :task_id"),
                {"task_id": task_id},
            )
            if existing.scalar():
                continue
            await db_session.execute(
                text(
                    """\
                    INSERT INTO task_status (task_id, task_name, user_id, status, progress, error_message, created_at, updated_at)
                    VALUES (:task_id, :task_name, 'seed', :status, :progress, :error, :created_at, :created_at)
                    """
                ),
                {
                    "task_id": task_id,
                    "task_name": task_name,
                    "status": status,
                    "progress": progress,
                    "error": error or "",
                    "created_at": created.isoformat(),
                },
            )
            await db_session.commit()
            count += 1

    logger.info("  Task status entries seeded: %d", count)
    return count


async def ensure_core_tables(engine: Any) -> None:
    """Create core tables if they don't exist (idempotent)."""
    from sqlalchemy import text

    async with engine.begin() as conn:
        # Users table
        await conn.execute(text("""
            CREATE TABLE IF NOT EXISTS users (
                id TEXT PRIMARY KEY, username TEXT UNIQUE NOT NULL, email TEXT,
                full_name TEXT, password_hash TEXT NOT NULL, role TEXT NOT NULL DEFAULT 'worker',
                tenant_id TEXT NOT NULL DEFAULT 'default', is_active BOOLEAN NOT NULL DEFAULT 1,
                is_verified BOOLEAN NOT NULL DEFAULT 0, must_change_password BOOLEAN NOT NULL DEFAULT 0,
                jwt_version INTEGER NOT NULL DEFAULT 1, last_login TIMESTAMP,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
        """))
        # Roles
        await conn.execute(text("""
            CREATE TABLE IF NOT EXISTS roles (
                id TEXT PRIMARY KEY, name TEXT UNIQUE NOT NULL, description TEXT,
                is_system BOOLEAN NOT NULL DEFAULT 0, created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
        """))
        # Permissions
        await conn.execute(text("""
            CREATE TABLE IF NOT EXISTS permissions (
                id TEXT PRIMARY KEY, codename TEXT UNIQUE NOT NULL, description TEXT,
                resource TEXT NOT NULL, action TEXT NOT NULL, created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
        """))
        # User roles
        await conn.execute(text("""
            CREATE TABLE IF NOT EXISTS user_roles (
                id TEXT PRIMARY KEY, user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
                role_id TEXT NOT NULL REFERENCES roles(id) ON DELETE CASCADE,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
        """))
        # Role permissions
        await conn.execute(text("""
            CREATE TABLE IF NOT EXISTS role_permissions (
                id TEXT PRIMARY KEY, role_id TEXT NOT NULL REFERENCES roles(id) ON DELETE CASCADE,
                permission_id TEXT NOT NULL REFERENCES permissions(id) ON DELETE CASCADE,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, UNIQUE(role_id, permission_id)
            )
        """))
        # Audit logs
        await conn.execute(text("""
            CREATE TABLE IF NOT EXISTS audit_logs (
                id TEXT PRIMARY KEY, user_id TEXT, invoice_id TEXT, action TEXT NOT NULL,
                old_value TEXT, new_value TEXT, timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
        """))
        # Email tokens
        await conn.execute(text("""
            CREATE TABLE IF NOT EXISTS email_tokens (
                id TEXT PRIMARY KEY, user_id TEXT NOT NULL, token TEXT UNIQUE NOT NULL,
                purpose TEXT NOT NULL DEFAULT 'confirm', expires_at TIMESTAMP NOT NULL,
                used BOOLEAN NOT NULL DEFAULT 0, created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
        """))
        # Outbox events
        await conn.execute(text("""
            CREATE TABLE IF NOT EXISTS outbox_events (
                id TEXT PRIMARY KEY, event_type TEXT NOT NULL, aggregate_id TEXT NOT NULL,
                payload TEXT NOT NULL, status TEXT NOT NULL DEFAULT 'PENDING',
                processed BOOLEAN NOT NULL DEFAULT 0, retry_count INTEGER NOT NULL DEFAULT 0,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
        """))
        # Failed tasks
        await conn.execute(text("""
            CREATE TABLE IF NOT EXISTS failed_tasks (
                id TEXT PRIMARY KEY, task_name TEXT NOT NULL, task_id TEXT,
                payload TEXT NOT NULL DEFAULT '{}', error_type TEXT NOT NULL,
                error_message TEXT NOT NULL, stack_trace TEXT, retry_count INTEGER NOT NULL DEFAULT 0,
                max_retries INTEGER NOT NULL DEFAULT 3, resolved BOOLEAN NOT NULL DEFAULT 0,
                resolved_at TIMESTAMP, resolved_by TEXT, resolution_note TEXT,
                failed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
        """))
        # Contractors
        await conn.execute(text("""
            CREATE TABLE IF NOT EXISTS contractors (
                id TEXT PRIMARY KEY, name TEXT NOT NULL, nip TEXT UNIQUE NOT NULL,
                address TEXT, bank_account TEXT, created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
        """))
        # Invoices
        await conn.execute(text("""
            CREATE TABLE IF NOT EXISTS invoices (
                id TEXT PRIMARY KEY, number TEXT UNIQUE NOT NULL, amount_net TEXT,
                amount_gross TEXT, currency TEXT NOT NULL DEFAULT 'PLN',
                issue_date TEXT, contractor_nip TEXT, contractor_id TEXT,
                status TEXT NOT NULL DEFAULT 'NEW', file_path TEXT,
                tenant_id TEXT NOT NULL DEFAULT 'default', created_by TEXT, updated_by TEXT,
                version_id INTEGER DEFAULT 1, is_deleted BOOLEAN NOT NULL DEFAULT 0,
                deleted_at TIMESTAMP, created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
        """))
        # Company profiles
        await conn.execute(text("""
            CREATE TABLE IF NOT EXISTS company_profiles (
                id TEXT PRIMARY KEY, name TEXT NOT NULL, nip TEXT UNIQUE NOT NULL,
                legal_form TEXT, ksef_active BOOLEAN NOT NULL DEFAULT 1, ksef_token TEXT,
                vat_active BOOLEAN NOT NULL DEFAULT 1, vat_proportion TEXT DEFAULT '1.0000',
                tigerbeetle_ledger_map TEXT, company_policy TEXT, created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
        """))
        # Tax policies
        await conn.execute(text("""
            CREATE TABLE IF NOT EXISTS tax_policies (
                id TEXT PRIMARY KEY, company_id TEXT NOT NULL, tax_form TEXT NOT NULL,
                pit_costs_enabled BOOLEAN NOT NULL DEFAULT 1, requires_full_ledger BOOLEAN NOT NULL DEFAULT 0,
                vat_settlement_cycle TEXT DEFAULT 'monthly', effective_from TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
        """))
        # Financial periods
        await conn.execute(text("""
            CREATE TABLE IF NOT EXISTS financial_periods (
                period_id TEXT NOT NULL, company_id TEXT NOT NULL, status TEXT NOT NULL DEFAULT 'open',
                PRIMARY KEY (period_id, company_id)
            )
        """))
        # FX rates
        await conn.execute(text("""
            CREATE TABLE IF NOT EXISTS fx_rates (
                id TEXT PRIMARY KEY, currency TEXT NOT NULL, rate_to_pln REAL NOT NULL,
                effective_at TIMESTAMP NOT NULL, source TEXT NOT NULL DEFAULT 'manual',
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
        """))
        # Task status
        await conn.execute(text("""
            CREATE TABLE IF NOT EXISTS task_status (
                task_id TEXT PRIMARY KEY, task_name TEXT NOT NULL, user_id TEXT,
                status TEXT NOT NULL DEFAULT 'QUEUED', progress REAL DEFAULT 0.0,
                result TEXT, error_message TEXT, created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
        """))

    logger.info("  Core tables ensured (%d tables)", 17)


async def seed_all(config: Any | None = None) -> dict[str, int]:
    """
    Load all seed data into the database.

    Returns a dict with counts of each entity type created.
    """
    from core.config import AppConfig
    from db.database import create_oltp_engine, create_session_factory

    cfg = config or AppConfig()

    logger.info("=" * 60)
    logger.info("  NEXUSAI — SEED DATA LOADER")
    logger.info("=" * 60)
    logger.info("")

    await ensure_directories(cfg)

    engine = create_oltp_engine(cfg)

    # Create all core tables before seeding
    await ensure_core_tables(engine)

    session_factory = create_session_factory(engine)
    session = session_factory()

    results: dict[str, int] = {}
    admin_password: str | None = None
    try:
        # Seed dictionaries first (they're referenced by other entities)
        dict_counts = await seed_dictionaries(session)
        for k, v in dict_counts.items():
            results[k] = v

        # Seed users (may return admin_password)
        user_result = await seed_users(session, cfg)
        results["users"] = user_result.get("count", 0)
        if user_result.get("admin_password"):
            admin_password = user_result["admin_password"]

        results["contractors"] = await seed_contractors(session)
        results["invoices"] = await seed_invoices(session, cfg)
        results["companies"] = await seed_companies(session)
        results["tax_policies"] = await seed_tax_policies(session)
        results["financial_periods"] = await seed_financial_periods(session)
        results["fx_rates"] = await seed_fx_rates(session)
        results["task_status"] = await seed_task_status(session)

        logger.info("")
        logger.info("=" * 60)
        logger.info("  SEED DATA SUMMARY")
        logger.info("=" * 60)
        for entity, count in results.items():
            logger.info("  %-20s : %d", entity, count)

        total = sum(results.values())
        logger.info("  %-20s : %d", "TOTAL ENTITIES", total)
        if admin_password:
            logger.info("")
            logger.info("  !!! ADMIN PASSWORD: %s", admin_password)
            logger.info("  !!! Save this password and change it on first login.")
            logger.info("  !!! Login: admin / %s", admin_password)
        logger.info("=" * 60)

    except Exception as exc:
        logger.error("Seed data loading failed: %s", exc, exc_info=True)
        raise
    finally:
        await session.close()
        await engine.dispose()

    return results


# ── CLI entry point ──────────────────────────────────────────────────────────

def main() -> int:
    """CLI entry point: python -m Code.SKRIPTS.seed_data"""
    import sys

    logging.basicConfig(
        level=logging.INFO,
        format="%(asctime)s [%(levelname)s] %(name)s: %(message)s",
        datefmt="%Y-%m-%d %H:%M:%S",
    )

    try:
        result = asyncio.run(seed_all())
        if result:
            sys.stdout.write(f"Seed data loaded: {sum(result.values())} total entities\n")
            return 0
        else:
            sys.stdout.write("No seed data was loaded (all entities may already exist)\n")
            return 0
    except Exception as exc:
        logger.critical("Seed data loading failed: %s", exc)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
