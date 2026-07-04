"""Seed data loader for NexusAI -- loads fixtures from seed_data.toml.

Usage:
    python -m nexus_ai.scripts.seed_data
    python main.py --load-fixtures
"""

from __future__ import annotations

import logging
import os
import tomllib
import uuid
from pathlib import Path
from typing import Any

import anyio
import pendulum
from structlog import get_logger

from nexus_ai.core.msgspec_utils import msgspec_dumps
from nexus_ai.db.models import InvoiceStatus, OutboxStatus

logger = get_logger("nexus.seed")
_FIXTURE_PATH = Path(__file__).parent / "seed_data.toml"


def _load_fixtures() -> dict[str, Any]:
    """Load seed data from TOML fixture file."""
    with open(_FIXTURE_PATH, "rb") as f:
        data = tomllib.load(f)
    nips = data["nips"]
    all_nips = nips["valid"] + nips["placeholder"]
    # Build lookup maps (operate on copies to avoid mutating cached data)
    contracts = [{**c, "nip": all_nips[c["nip_idx"]]} for c in data.get("contractors", [])]
    invs = [{**inv, "contractor_nip": all_nips[inv["contractor_nip_idx"]]} for inv in data.get("invoices", [])]
    data["invoices"] = invs
    data["contractors"] = contracts
    data["all_nips"] = all_nips
    return data


_FIXTURES: dict[str, Any] | None = None


def _fixtures() -> dict[str, Any]:
    global _FIXTURES
    if _FIXTURES is None:
        _FIXTURES = _load_fixtures()
    return _FIXTURES


async def ensure_directories(config: Any) -> None:
    for d in [
        config.base_dir / "seed_data",
        config.base_dir / "app_data" / "uploads",
        config.base_dir / "app_data" / "scans",
        config.base_dir / "app_data" / "exports",
        config.base_dir / "models",
    ]:
        d.mkdir(parents=True, exist_ok=True)
        logger.info("  Directory ready: %s", d)


async def seed_users(db_session: Any, config: Any) -> dict:
    from sqlmodel import text
    from nexus_ai.api.security import hash_password
    import secrets as _secrets

    count = 0
    admin_password = None
    fx = _fixtures()
    for user in fx["users"]:
        username, role = user["username"], user["role"]
        existing = (await db_session.execute(
            text("SELECT id FROM users WHERE username = :username"), {"username": username}
        )).scalar()
        if existing:
            logger.info("  User '%s' already exists, skipping.", username)
            continue
        canonical_role = "admin" if role == "owner" else role
        if username == "admin":
            raw_password = os.getenv("NEXUS_ADMIN_PASSWORD", "") or _secrets.token_urlsafe(16)
            admin_password = raw_password
            must_change, is_verified = True, False
        else:
            raw_password = os.getenv("NEXUS_SEED_ACCOUNTANT_PASSWORD", "ksiegowa123")
            must_change, is_verified = False, True
        pwd_hash = hash_password(raw_password)
        user_id = uuid.uuid4().hex
        now = pendulum.now("UTC").isoformat()
        async with db_session.begin():
            await db_session.execute(text(
                """INSERT INTO users (id, username, email, full_name, password_hash, role,
                    tenant_id, is_active, is_verified, must_change_password, jwt_version,
                    created_at, updated_at)
                VALUES (:id, :username, :email, :full_name, :password_hash, :role,
                    'default', 1, :is_verified, :must_change, 1, :now, :now)"""
            ), {
                "id": user_id, "username": username,
                "email": f"{username}@nexusai.demo",
                "full_name": "Administrator" if username == "admin" else "Księgowa",
                "password_hash": pwd_hash, "role": canonical_role,
                "is_verified": is_verified, "must_change": must_change, "now": now,
            })
            role_name = "admin" if username == "admin" else "accountant"
            role_row = (await db_session.execute(
                text("SELECT id FROM roles WHERE name = :name LIMIT 1"), {"name": role_name}
            )).mappings().first()
            if role_row:
                await db_session.execute(
                    text("INSERT INTO user_roles (id, user_id, role_id) VALUES (:id, :uid, :rid)"),
                    {"id": uuid.uuid4().hex, "uid": user_id, "rid": role_row["id"]},
                )
            await db_session.commit()
            count += 1
            logger.info("  User '%s' created (role=%s, must_change_password=%s)", username, role, must_change)
    if admin_password:
        logger.info("  !!! ADMIN PASSWORD (SAVE THIS): %s", admin_password)
    return {"count": count, "admin_password": admin_password}


async def seed_rbac(engine: Any) -> dict[str, int]:
    from sqlmodel import text
    from nexus_ai.api.security import hash_password
    import os as _os

    fx = _fixtures()
    admin_username = _os.getenv("NEXUS_ADMIN_USERNAME", "admin")
    admin_password = _os.getenv("NEXUS_ADMIN_PASSWORD", "admin")
    admin_password_hash = hash_password(admin_password)
    role_ids: dict[str, str] = {}
    perm_ids: dict[str, str] = {}

    async with engine.begin() as conn:
        for role_name, role_desc in fx["roles"].items():
            await conn.execute(text(
                "INSERT INTO roles (id, name, description, is_system) "
                "VALUES (:id, :name, :desc, 1) ON CONFLICT(name) DO NOTHING"
            ), {"id": uuid.uuid4().hex, "name": role_name, "desc": role_desc})
        for role_row in (await conn.execute(text("SELECT id, name FROM roles"))).mappings().all():
            role_ids[role_row["name"]] = role_row["id"]

        for codename, info in fx["permissions"].items():
            await conn.execute(text(
                "INSERT INTO permissions (id, codename, resource, action, description) "
                "VALUES (:id, :codename, :resource, :action, :desc) ON CONFLICT(codename) DO NOTHING"
            ), {"id": uuid.uuid4().hex, "codename": codename, "resource": info["resource"],
                "action": info["action"], "desc": info["description"]})
        for perm_row in (await conn.execute(text("SELECT id, codename FROM permissions"))).mappings().all():
            perm_ids[perm_row["codename"]] = perm_row["id"]

        all_perms = list(perm_ids.keys())
        rp_count = 0
        for role_name, codenames in fx["role_permissions"].items():
            rid = role_ids.get(role_name)
            if not rid: continue
            perms = all_perms if codenames == "all" else codenames
            for cn in perms:
                pid = perm_ids.get(cn)
                if not pid: continue
                await conn.execute(text(
                    "INSERT INTO role_permissions (id, role_id, permission_id) "
                    "VALUES (:id, :rid, :pid) ON CONFLICT DO NOTHING"
                ), {"id": uuid.uuid4().hex, "rid": rid, "pid": pid})
                rp_count += 1

        await conn.execute(text("""
            INSERT INTO users (id, username, password_hash, role, tenant_id, is_active)
            VALUES (:id, :username, :password_hash, :role, :tenant_id, :is_active)
            ON CONFLICT(username) DO NOTHING
        """), {"id": "admin", "username": admin_username, "password_hash": admin_password_hash,
               "role": "admin", "tenant_id": "default", "is_active": True})

        admin_role_id = role_ids.get("admin")
        if admin_role_id:
            existing = (await conn.execute(text(
                "SELECT id FROM user_roles WHERE user_id = :uid AND role_id = :rid LIMIT 1"
            ), {"uid": "admin", "rid": admin_role_id})).scalar()
            if not existing:
                await conn.execute(text(
                    "INSERT INTO user_roles (id, user_id, role_id) VALUES (:id, :uid, :rid)"
                ), {"id": uuid.uuid4().hex, "uid": "admin", "rid": admin_role_id})
        await conn.execute(text("ANALYZE;"))

    logger.info("[RBAC] Seeded: %d roles, %d permissions, %d mappings, admin user",
                 len(role_ids), len(perm_ids), rp_count)
    return {"roles": len(role_ids), "permissions": len(perm_ids), "role_permissions": rp_count, "admin_user": 1}


async def seed_contractors(db_session: Any) -> int:
    from sqlmodel import text
    fx = _fixtures()
    count = 0
    for c in fx["contractors"]:
        async with db_session.begin():
            if (await db_session.execute(text("SELECT id FROM contractors WHERE nip = :nip"), {"nip": c["nip"]})).scalar():
                logger.info("  Contractor NIP %s already exists, skipping.", c["nip"])
                continue
            now = pendulum.now("UTC").isoformat()
            cid = uuid.uuid4().hex
            await db_session.execute(text(
                "INSERT INTO contractors (id, name, nip, address, bank_account, created_at, updated_at) "
                "VALUES (:id, :name, :nip, :address, :bank_account, :created_at, :updated_at)"
            ), {"id": cid, "name": c["name"], "nip": c["nip"], "address": c["address"],
                "bank_account": c["bank_account"], "created_at": now, "updated_at": now})
            await db_session.commit()
            count += 1
            logger.info("  Contractor '%s' created (NIP=%s)", c["name"], c["nip"])
    return count


async def seed_invoices(db_session: Any, config: Any) -> int:
    from sqlmodel import text
    fx = _fixtures()
    count = 0
    for inv in fx["invoices"]:
        async with db_session.begin():
            if (await db_session.execute(text("SELECT id FROM invoices WHERE number = :number"), {"number": inv["number"]})).scalar():
                logger.info("  Invoice %s already exists, skipping.", inv["number"])
                continue
            inv_id = uuid.uuid4().hex
            contractor_row = await db_session.execute(text("SELECT id FROM contractors WHERE nip = :nip"), {"nip": inv["contractor_nip"]})
            cid = (row[0] if (row := contractor_row.fetchone()) else None)
            now = pendulum.now("UTC").isoformat()
            await db_session.execute(text(
                """INSERT INTO invoices (id, number, amount_net, amount_gross, currency,
                    issue_date, contractor_nip, contractor_id, status, file_path, tenant_id,
                    created_at, updated_at, created_by, updated_by, version_id)
                VALUES (:id, :number, :amount_net, :amount_gross, :currency,
                    :issue_date, :contractor_nip, :contractor_id, :status,
                    :file_path, 'default', :created_at, :updated_at, 'seed_data', 'seed_data', 1)"""
            ), {"id": inv_id, "number": inv["number"], "amount_net": inv["amount_net"],
                "amount_gross": inv["amount_gross"], "currency": inv["currency"],
                "issue_date": inv["issue_date"], "contractor_nip": inv["contractor_nip"],
                "contractor_id": cid, "status": inv["status"], "file_path": inv["file_path"],
                "created_at": now, "updated_at": now})
            outbox_id = uuid.uuid4().hex
            await db_session.execute(text(
                "INSERT INTO outbox_events (id, event_type, aggregate_id, payload, status, processed, created_at) "
                "VALUES (:id, :event_type, :aggregate_id, :payload, :status, 0, :created_at)"
            ), {"id": outbox_id, "event_type": "seed_invoice_created", "aggregate_id": inv_id,
                "payload": msgspec_dumps({"invoice_id": inv_id, "number": inv["number"], "source": "seed_data", "created_at": now}),
                "status": OutboxStatus.PENDING.value, "created_at": now})
            audit_id = uuid.uuid4().hex
            await db_session.execute(text(
                "INSERT INTO audit_logs (id, invoice_id, user_id, action, old_value, new_value, timestamp, created_at) "
                "VALUES (:id, :invoice_id, 'seed_data', 'SEED_CREATED', NULL, :amount, :created_at, :created_at)"
            ), {"id": audit_id, "invoice_id": inv_id,
                "amount": f"Net: {inv['amount_net']}, Gross: {inv['amount_gross']}", "created_at": now})
            await db_session.commit()
            count += 1
            logger.info("  Invoice %s created (%.2f PLN %s)", inv["number"], float(inv["amount_gross"]), inv["currency"])
    return count


async def seed_companies(db_session: Any) -> int:
    from sqlmodel import text
    fx = _fixtures()
    count = 0
    for company in fx["companies"]:
        nip = fx["all_nips"][company["nip_idx"]]
        async with db_session.begin():
            if (await db_session.execute(text("SELECT id FROM company_profiles WHERE nip = :nip"), {"nip": nip})).scalar():
                logger.info("  Company NIP %s already exists, skipping.", nip)
                continue
            now = pendulum.now("UTC").isoformat()
            await db_session.execute(text(
                """INSERT INTO company_profiles (id, name, nip, legal_form, ksef_active, ksef_token,
                    vat_active, vat_proportion, tigerbeetle_ledger_map, company_policy, created_at)
                VALUES (:id, :name, :nip, :legal_form, :ksef_active, '',
                    :vat_active, :vat_proportion, :tigerbeetle_ledger_map, :company_policy, :created_at)"""
            ), {"id": uuid.uuid4().hex, "name": company["name"], "nip": nip,
                "legal_form": company["legal_form"], "ksef_active": company["ksef_active"],
                "vat_active": company["vat_active"], "vat_proportion": company["vat_proportion"],
                "tigerbeetle_ledger_map": msgspec_dumps(company["ledger_map"]),
                "company_policy": msgspec_dumps(company["policy"]), "created_at": now})
            await db_session.commit()
            count += 1
            logger.info("  Company '%s' created (form=%s)", company["name"], company["legal_form"])
    return count


async def seed_tax_policies(db_session: Any) -> int:
    from sqlmodel import text
    fx = _fixtures()
    cids = [row[0] for row in (await db_session.execute(text("SELECT id FROM company_profiles"))).fetchall()]
    count = 0
    for cid in cids:
        for policy in fx["tax_policies"]:
            async with db_session.begin():
                if (await db_session.execute(text(
                    "SELECT id FROM tax_policies WHERE company_id = :company_id AND tax_form = :tax_form"
                ), {"company_id": cid, "tax_form": policy["tax_form"]})).scalar(): continue
                now = pendulum.now("UTC").isoformat()
                await db_session.execute(text(
                    """INSERT INTO tax_policies (id, company_id, tax_form, pit_costs_enabled,
                        requires_full_ledger, vat_settlement_cycle, effective_from)
                    VALUES (:id, :company_id, :tax_form, :pit_costs, :full_ledger, :settlement_cycle, :effective_from)"""
                ), {"id": uuid.uuid4().hex, "company_id": cid, "tax_form": policy["tax_form"],
                    "pit_costs": policy["pit_costs_enabled"], "full_ledger": policy["requires_full_ledger"],
                    "settlement_cycle": policy["vat_settlement_cycle"], "effective_from": now})
                await db_session.commit()
                count += 1
    logger.info("  Created %d tax policies across %d companies", count, len(cids))
    return count


async def seed_financial_periods(db_session: Any) -> int:
    from sqlmodel import text
    fx = _fixtures()
    cids = [row[0] for row in (await db_session.execute(text("SELECT id FROM company_profiles"))).fetchall()]
    count = 0
    for cid in cids:
        for period in fx["financial_periods"]:
            async with db_session.begin():
                if (await db_session.execute(text(
                    "SELECT period_id FROM financial_periods WHERE period_id = :pid AND company_id = :cid"
                ), {"pid": period["period_id"], "cid": cid})).scalar(): continue
                await db_session.execute(text(
                    "INSERT INTO financial_periods (period_id, company_id, status) VALUES (:pid, :cid, :status)"
                ), {"pid": period["period_id"], "cid": cid, "status": period["status"]})
                await db_session.commit()
                count += 1
    logger.info("  Created %d financial periods across %d companies", count, len(cids))
    return count


async def seed_fx_rates(db_session: Any) -> int:
    from sqlmodel import text
    fx = _fixtures()
    count = 0
    effective_at = pendulum.now("UTC").isoformat()
    for rate in fx["fx_rates"]:
        async with db_session.begin():
            await db_session.execute(text(
                "INSERT INTO fx_rates (id, currency, rate_to_pln, effective_at, source, created_at) "
                "VALUES (:id, :currency, :rate, :effective_at, :source, :created_at)"
            ), {"id": uuid.uuid4().hex, "currency": rate["currency"], "rate": rate["rate_to_pln"],
                "effective_at": effective_at, "source": rate["source"], "created_at": effective_at})
            await db_session.commit()
            count += 1
    logger.info("  FX rates seeded: %d currencies", count)
    return count


async def seed_dictionaries(db_session: Any) -> dict[str, int]:
    from sqlmodel import text
    fx = _fixtures()
    async with db_session.begin():
        for tbl in ["dict_vat_rates", "dict_currencies", "dict_invoice_statuses", "dict_tax_forms"]:
            await db_session.execute(text(f"CREATE TABLE IF NOT EXISTS {tbl} (id TEXT PRIMARY KEY, code TEXT UNIQUE NOT NULL, rate REAL, name TEXT, symbol TEXT, description TEXT, created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP)"))
        await db_session.commit()

    counts: dict[str, int] = {}
    for key, tbl, cols in [
        ("vat_rates", "dict_vat_rates", ["id", "code", "rate", "description"]),
        ("currencies", "dict_currencies", ["id", "code", "name", "symbol"]),
        ("invoice_statuses", "dict_invoice_statuses", ["id", "code", "name", "description"]),
        ("tax_forms", "dict_tax_forms", ["id", "code", "name"]),
    ]:
        c = 0
        for item in fx[key]:
            async with db_session.begin():
                if (await db_session.execute(text(f"SELECT id FROM {tbl} WHERE code = :code"), {"code": item["code"]})).scalar(): continue
                vals = {col: (uuid.uuid4().hex if col == "id" else item[col]) for col in cols}
                await db_session.execute(text(
                    f"INSERT INTO {tbl} ({','.join(cols)}) VALUES ({','.join(':' + c for c in cols)})"
                ), vals)
                await db_session.commit()
                c += 1
        counts[key] = c
        logger.info("  %s seeded: %d", key, c)
    return counts


async def seed_task_status(db_session: Any) -> int:
    from sqlmodel import text
    now = pendulum.now("UTC")
    tasks = [
        ("seed-task-001", "OCR Processing", "COMPLETED", 1.0, None, now.subtract(hours=2)),
        ("seed-task-002", "AI Analysis", "COMPLETED", 1.0, None, now.subtract(hours=1)),
        ("seed-task-003", "KSeF Submission", "RUNNING", 0.45, None, now.subtract(minutes=30)),
        ("seed-task-004", "VAT Reconciliation", "QUEUED", 0.0, None, now),
        ("seed-task-005", "Shadow Ledger Sync", "FAILED", 0.0, "TigerBeetle connection timeout", now.subtract(minutes=15)),
    ]
    count = 0
    for task_id, task_name, status, progress, error, created in tasks:
        async with db_session.begin():
            if (await db_session.execute(text("SELECT task_id FROM task_status WHERE task_id = :tid"), {"tid": task_id})).scalar(): continue
            await db_session.execute(text(
                "INSERT INTO task_status (task_id, task_name, user_id, status, progress, error_message, created_at, updated_at) "
                "VALUES (:tid, :tname, 'seed', :status, :progress, :error, :created_at, :created_at)"
            ), {"tid": task_id, "tname": task_name, "status": status, "progress": progress,
                "error": error or "", "created_at": created.isoformat()})
            await db_session.commit()
            count += 1
    logger.info("  Task status entries seeded: %d", count)
    return count


async def seed_all(config: Any | None = None) -> dict[str, int]:
    from nexus_ai.core.config import AppConfig
    from nexus_ai.db.database import create_oltp_engine, create_session_factory

    cfg = config or AppConfig()
    logger.info("=" * 60)
    logger.info("  NEXUSAI -- SEED DATA LOADER")
    logger.info("=" * 60)
    await ensure_directories(cfg)
    engine = create_oltp_engine(cfg)
    session = create_session_factory(engine)()

    results: dict[str, int] = {}
    admin_password: str | None = None
    try:
        results.update(await seed_dictionaries(session))
        user_result = await seed_users(session, cfg)
        results["users"] = user_result.get("count", 0)
        if user_result.get("admin_password"): admin_password = user_result["admin_password"]
        results["contractors"] = await seed_contractors(session)
        results["invoices"] = await seed_invoices(session, cfg)
        results["companies"] = await seed_companies(session)
        results["tax_policies"] = await seed_tax_policies(session)
        results["financial_periods"] = await seed_financial_periods(session)
        results["fx_rates"] = await seed_fx_rates(session)
        results["task_status"] = await seed_task_status(session)
        logger.info("=" * 60)
        logger.info("  SEED DATA SUMMARY")
        for entity, count in results.items():
            logger.info("  %-20s : %d", entity, count)
        total = sum(results.values())
        logger.info("  %-20s : %d", "TOTAL ENTITIES", total)
        if admin_password:
            logger.info("  !!! ADMIN PASSWORD: %s", admin_password)
        logger.info("=" * 60)
    except Exception as exc:
        logger.error("Seed data loading failed: %s", exc, exc_info=True)
        raise
    finally:
        await session.close()
        await engine.dispose()
    return results


def main() -> int:
    import sys
    logging.basicConfig(level=logging.INFO, format="%(asctime)s [%(levelname)s] %(name)s: %(message)s", datefmt="%Y-%m-%d %H:%M:%S")
    try:
        result = anyio.run(seed_all)
        if result:
            sys.stdout.write(f"Seed data loaded: {sum(result.values())} total entities\n")
        return 0
    except Exception as exc:
        logger.critical("Seed data loading failed: %s", exc)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
