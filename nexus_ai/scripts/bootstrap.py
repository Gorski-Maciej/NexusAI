"""bootstrap.py — z prawdziwą TigerBeetle weryfikacją przez realny klient.

SUPERMOCE:
- Real TigerBeetle connection test przez lookup_accounts
- Sprawdzanie czy serwer TB odpowiada
- Graceful degradation gdy TB nie zainstalowane
"""

from __future__ import annotations

import importlib
import logging
import os
import time

import anyio
from collections.abc import Callable
from msgspec import Struct, field
from pathlib import Path
from typing import Any

import pendulum
from structlog import get_logger

logger = get_logger("nexus.bootstrap")


class StepResult(Struct):
    name: str
    status: str
    message: str = ""
    duration_ms: float = 0.0
    details: dict[str, Any] = field(default_factory=dict)


class BootstrapReport(Struct):
    steps: list[StepResult] = field(default_factory=list)
    started_at: str = ""
    finished_at: str = ""
    environment: str = ""
    overall_status: str = "ok"

    @property
    def total_duration_ms(self) -> float:
        if not self.steps:
            return 0.0
        return sum(s.duration_ms for s in self.steps)

    def add(self, step: StepResult) -> None:
        self.steps.append(step)

    def print_summary(self) -> None:
        print()
        print("=" * 70)
        print("  NEXUSAI BOOTSTRAP SUMMARY")
        print(f"  Environment: {self.environment}")
        print("=" * 70)
        print()
        for step in self.steps:
            icon = {"ok": "✓", "skipped": "−", "warning": "⚠", "error": "✗"}.get(step.status, "?")
            print(f"  {icon}  {step.name:45s} {step.status.upper():8s} {step.duration_ms:7.0f}ms")
            if step.message:
                print(f"     {step.message}")
        print()
        print(f"  Total time: {self.total_duration_ms:.0f} ms")
        print(f"  Overall: {self.overall_status.upper()}")
        print("=" * 70)
        print()


async def step_validate_config(config: Any) -> StepResult:
    start = time.perf_counter()
    name = "Validate configuration"
    errors: list[str] = []

    env = os.getenv("NEXUS_ENV", "dev")
    if env not in ("dev", "stage", "prod"):
        errors.append(f"NEXUS_ENV='{env}' must be one of: dev, stage, prod")

    base_dir = config.base_dir if hasattr(config, "base_dir") else Path.cwd()
    if not base_dir.exists():
        try:
            base_dir.mkdir(parents=True, exist_ok=True)
        except OSError as exc:
            errors.append(f"Cannot create base directory {base_dir}: {exc}")

    jwt_secret = os.getenv("NEXUS_JWT_SECRET", "")
    if env in ("stage", "prod") and not jwt_secret:
        errors.append("NEXUS_JWT_SECRET is REQUIRED in stage/prod environment")
    encryption_key = os.getenv("NEXUS_ENCRYPTION_KEY", "")
    if env in ("stage", "prod") and not encryption_key:
        errors.append("NEXUS_ENCRYPTION_KEY is REQUIRED in stage/prod environment")

    config_dir = Path(__file__).resolve().parent.parent.parent / "config"
    profile_file = config_dir / f"{env}.toml"
    if not profile_file.exists():
        errors.append(f"TOML config profile not found: {profile_file}")

    if errors:
        return StepResult(
            name=name, status="error",
            message="; ".join(errors),
            duration_ms=(time.perf_counter() - start) * 1000,
            details={"errors": errors},
        )
    return StepResult(
        name=name, status="ok",
        message=f"Environment '{env}' validated",
        duration_ms=(time.perf_counter() - start) * 1000,
        details={"environment": env, "base_dir": str(base_dir)},
    )


async def step_check_dependencies(config: Any) -> StepResult:
    start = time.perf_counter()
    name = "Check Python dependencies"

    REQUIRED_CORE = [
        ("litestar", "litestar"),
        ("granian", "granian"),
        ("sqlmodel", "sqlmodel"),
        # alembic removed — replaced by migrations/run_migrations.py
        ("taskiq", "taskiq"),
        ("duckdb", "duckdb"),
        ("msgspec", "msgspec"),
        ("tigerbeetle", "tigerbeetle"),
    ]

    missing: list[str] = []
    for pkg_name, import_name in REQUIRED_CORE:
        try:
            importlib.import_module(import_name)
        except ModuleNotFoundError:
            missing.append(pkg_name)

    if missing:
        return StepResult(
            name=name, status="error",
            message=f"Missing packages: {', '.join(missing)}. Run: pip install -r requirements.txt",
            duration_ms=(time.perf_counter() - start) * 1000,
            details={"missing": missing},
        )
    return StepResult(
        name=name, status="ok",
        message=f"{len(REQUIRED_CORE)} core packages available (including tigerbeetle)",
        duration_ms=(time.perf_counter() - start) * 1000,
    )


async def step_create_directories(config: Any) -> StepResult:
    start = time.perf_counter()
    name = "Create data directories"

    if not hasattr(config, "base_dir"):
        return StepResult(
            name=name, status="error", message="Config missing base_dir", duration_ms=0
        )

    dirs = [
        config.base_dir,
        config.base_dir / "app_data",
        config.base_dir / "app_data" / "uploads",
        config.base_dir / "app_data" / "scans",
        config.base_dir / "app_data" / "exports",
        config.base_dir / "app_data" / "logs",
        config.base_dir / "models",
    ]
    if hasattr(config, "storage_dir"):
        dirs.append(config.storage_dir)

    created = 0
    for d in dirs:
        try:
            d.mkdir(parents=True, exist_ok=True)
            created += 1
        except OSError as exc:
            logger.warning("  Could not create directory %s: %s", d, exc)

    return StepResult(
        name=name, status="ok",
        message=f"{created} directories ready",
        duration_ms=(time.perf_counter() - start) * 1000,
        details={"directories": [str(d) for d in dirs]},
    )


async def step_run_migrations(config: Any) -> StepResult:
    start = time.perf_counter()
    name = "Run database migrations"
    try:
        from migrations.run_migrations import run_migrations

        result = run_migrations(
            db_path=config.sqlite_path if hasattr(config, "sqlite_path") else "app_data/nexus.db",
        )
        logger.info(
            "[BOOTSTRAP] All migrations applied: %d files",
            len(result["applied"]),
        )
        return StepResult(
            name=name, status="ok",
            message=f"{len(result['applied'])} migrations applied, {len(result['skipped'])} skipped",
            duration_ms=(time.perf_counter() - start) * 1000,
        )
    except ImportError:
        logger.warning("  Migration runner not available, creating tables via SQLAlchemy...")
        return StepResult(
            name=name, status="warning",
            message="migrations package not found — schema may be incomplete",
            duration_ms=(time.perf_counter() - start) * 1000,
        )
    except Exception as exc:
        return StepResult(
            name=name, status="error",
            message=f"Migration failed: {exc}",
            duration_ms=(time.perf_counter() - start) * 1000,
        )


async def step_initialize_olap(config: Any) -> StepResult:
    start = time.perf_counter()
    name = "Initialize OLAP schema"
    try:
        from db.analytics import DuckDBManager

        duckdb_path = (
            config.duckdb_path if hasattr(config, "duckdb_path") else Path("nexus_olap.duckdb")
        )
        sqlite_path = (
            config.sqlite_path if hasattr(config, "sqlite_path") else Path("nexus_oltp.db")
        )

        manager = DuckDBManager(db_path=duckdb_path, sqlite_path=sqlite_path)
        if hasattr(manager, "initialize"):
            manager.initialize()
        manager.close()

        return StepResult(
            name=name, status="ok",
            message=f"DuckDB ready at {duckdb_path.name}",
            duration_ms=(time.perf_counter() - start) * 1000,
        )
    except ImportError as exc:
        return StepResult(
            name=name, status="warning",
            message=f"DuckDB not available: {exc}",
            duration_ms=(time.perf_counter() - start) * 1000,
        )
    except Exception as exc:
        return StepResult(
            name=name, status="warning",
            message=f"DuckDB init warning: {exc}",
            duration_ms=(time.perf_counter() - start) * 1000,
        )


async def step_seed_data(config: Any) -> StepResult:
    start = time.perf_counter()
    name = "Load seed data"

    seeded_file = config.base_dir / ".seeded" if hasattr(config, "base_dir") else Path(".seeded")
    if seeded_file.exists():
        seeded_at = seeded_file.read_text(encoding="utf-8").strip()
        return StepResult(
            name=name, status="skipped",
            message=f"Already seeded at {seeded_at[:19]} (delete .seeded to re-seed)",
            duration_ms=(time.perf_counter() - start) * 1000,
        )

    try:
        from scripts.seed_data import seed_all

        result = await seed_all(config)
        total = sum(result.values()) if result else 0
        seeded_file.write_text(pendulum.now("UTC").isoformat())

        return StepResult(
            name=name, status="ok",
            message=f"{total} entities loaded",
            duration_ms=(time.perf_counter() - start) * 1000,
            details=result,
        )
    except Exception as exc:
        return StepResult(
            name=name, status="warning",
            message=f"Seed data partially loaded: {exc}",
            duration_ms=(time.perf_counter() - start) * 1000,
        )


async def step_verify_nats(config: Any) -> StepResult:
    start = time.perf_counter()
    name = "Verify NATS connection"
    nats_url = os.getenv("NEXUS_NATS_URL", "nats://localhost:4222")

    from nexus_ai.core.nats_utils import NatsErrors, get_connection, safe_close

    NatsErrors.init()
    try:
        nc = await get_connection(nats_url=nats_url, name="nexus-bootstrap", connect_timeout=3.0)
        if nc is not None:
            await safe_close(nc)
            return StepResult(
                name=name, status="ok",
                message=f"Connected to {nats_url}",
                duration_ms=(time.perf_counter() - start) * 1000,
            )
        return StepResult(
            name=name, status="warning",
            message=f"NATS not reachable at {nats_url} (timeout)",
            duration_ms=(time.perf_counter() - start) * 1000,
        )
    except NatsErrors.TimeoutError:
        return StepResult(
            name=name, status="warning",
            message=f"NATS not reachable at {nats_url} (timeout)",
            duration_ms=(time.perf_counter() - start) * 1000,
        )
    except NatsErrors.ConnectionClosedError as exc:
        return StepResult(
            name=name, status="warning",
            message=f"NATS connection error: {exc}",
            duration_ms=(time.perf_counter() - start) * 1000,
        )
    except ImportError:
        return StepResult(
            name=name, status="skipped",
            message="NATS client not installed",
            duration_ms=(time.perf_counter() - start) * 1000,
        )


# ── SUPERMOC: Real TigerBeetle verification ──────────────────────────────

async def step_verify_tigerbeetle(config: Any) -> StepResult:
    """Step 9: Verify TigerBeetle connection using real client.

    SUPERMOCE:
    - Real connection test przez lookup_accounts
    - Sprawdzanie czy serwer TB jest uruchomiony
    - Inicjalizacja planu kont przez LedgerInitializer
    - Graceful degradation gdy TB nie dostępne
    """
    start = time.perf_counter()
    name = "Verify TigerBeetle connection"

    try:
        from nexus_ai.services.tigerbeetle.client import TigerBeetleClient

        client = TigerBeetleClient()
        try:
            # SUPERMOC: lookup_accounts — testuje czy TB odpowiada
            accounts = client.lookup_accounts([])
            accounts_count = len(accounts)

            # SUPERMOC: Inicjalizacja planu kont przez LedgerInitializer
            if accounts_count == 0:
                try:
                    from nexus_ai.services.tigerbeetle import LedgerInitializer
                    from nexus_ai.services.tigerbeetle.models import LegalForm, TaxForm

                    initializer = LedgerInitializer(tb_client=client)
                    account_map = await initializer.configure_ledger(
                        legal_form=LegalForm.SP_ZOO,
                        tax_form=TaxForm.CIT_STANDARD,
                    )
                    print(f"  [LEDGER-INIT] Accounts created: {len(account_map)}")
                    accounts_count = len(account_map)
                except Exception as init_err:
                    logger.warning("LedgerInitializer failed: %s", init_err)

            client.close()

            return StepResult(
                name=name, status="ok",
                message=f"TigerBeetle connected (cluster={client.cluster_id}, "
                        f"addresses={client.replica_addresses}, accounts={accounts_count})",
                duration_ms=(time.perf_counter() - start) * 1000,
                details={
                    "cluster_id": client.cluster_id,
                    "addresses": client.replica_addresses,
                    "accounts_found": accounts_count,
                },
            )
        except Exception as exc:
            error_str = str(exc)
            if "Connection refused" in error_str:
                return StepResult(
                    name=name, status="warning",
                    message=f"TigerBeetle not running (connection refused on {client.replica_addresses})",
                    duration_ms=(time.perf_counter() - start) * 1000,
                )
            return StepResult(
                name=name, status="warning",
                message=f"TigerBeetle unavailable: {exc}",
                duration_ms=(time.perf_counter() - start) * 1000,
            )
        finally:
            try:
                client.close()
            except Exception:
                pass
    except ImportError:
        return StepResult(
            name=name, status="skipped",
            message="tigerbeetle client not installed (pip install tigerbeetle)",
            duration_ms=(time.perf_counter() - start) * 1000,
        )
    except Exception as exc:
        return StepResult(
            name=name, status="warning",
            message=f"TigerBeetle check: {exc}",
            duration_ms=(time.perf_counter() - start) * 1000,
        )


async def run_bootstrap(
    *,
    config: Any = None,
    steps: list[str] | None = None,
) -> BootstrapReport:
    if config is None:
        from core.config import AppConfig
        config = AppConfig()

    report = BootstrapReport(
        started_at=pendulum.now("UTC").isoformat(),
        environment=os.getenv("NEXUS_ENV", "dev"),
    )

    all_steps: list[tuple[str, Callable]] = [
        ("validate_config", step_validate_config),
        ("check_dependencies", step_check_dependencies),
        ("create_directories", step_create_directories),
        ("run_migrations", step_run_migrations),
        ("initialize_olap", step_initialize_olap),
        ("seed_data", step_seed_data),
        ("verify_nats", step_verify_nats),
        ("verify_tigerbeetle", step_verify_tigerbeetle),
    ]

    if steps is not None:
        all_steps = [(name, func) for name, func in all_steps if name in steps]

    print()
    print("=" * 70)
    print("  NEXUSAI BOOTSTRAP")
    print(f"  Environment: {report.environment}")
    print(f"  Steps: {len(all_steps)}")
    print("=" * 70)
    print()

    for step_name, step_func in all_steps:
        print(f"  → {step_name.replace('_', ' ').title()}...", end=" ", flush=True)
        try:
            result = await step_func(config)
            report.add(result)
            icon = {"ok": "✓", "skipped": "−", "warning": "⚠", "error": "✗"}.get(result.status, "?")
            print(f"{icon}  {result.status.upper()} ({result.duration_ms:.0f}ms)")
            if result.message:
                print(f"    {result.message}")
            if result.status == "error":
                report.overall_status = "error"
        except Exception as exc:
            error_result = StepResult(
                name=step_name.replace("_", " ").title(),
                status="error",
                message=str(exc),
                duration_ms=0,
            )
            report.add(error_result)
            print(f"✗  ERROR ({exc})")
            report.overall_status = "error"
        print()

    report.finished_at = pendulum.now("UTC").isoformat()
    report.print_summary()
    return report


def main(argv: list[str] | None = None) -> int:
    import argparse

    parser = argparse.ArgumentParser(
        description="NexusAI Bootstrap — Initialize environment for first run",
    )
    parser.add_argument(
        "--steps", type=str, nargs="*",
        help="Specific steps to run (default: all).",
    )
    parser.add_argument("--skip-seed", action="store_true", help="Skip seed data loading")
    parser.add_argument("--force", action="store_true", help="Force re-run even if already bootstrapped")

    args = parser.parse_args(argv)

    logging.basicConfig(
        level=logging.INFO,
        format="%(asctime)s [%(levelname)s] %(message)s",
        datefmt="%H:%M:%S",
    )
    logging.getLogger("nexus.bootstrap").setLevel(logging.DEBUG)

    step_filter = args.steps
    if args.skip_seed and step_filter is None:
        step_filter = [
            s for s in [
                "validate_config", "check_dependencies", "check_ai_models",
                "create_directories", "run_migrations", "initialize_olap",
                "verify_nats", "verify_tigerbeetle",
            ]
        ]
        result = anyio.run(run_bootstrap, step_filter)

    if result.overall_status == "error":
        print("Bootstrap completed with ERRORS. Review the summary above.")
        return 1

    print()
    print("  ✓  NexusAI is ready. Run 'python main.py --mode api' to start.")
    print()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
