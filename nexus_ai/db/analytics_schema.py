from collections.abc import Callable
from importlib import import_module
from importlib.util import find_spec

from nexus_ai.db.analytics import DuckDBManager
from nexus_ai.db.zpk_schema import ensure_zpk_schema
from nexus_ai.services.document_fingerprint import ensure_fingerprint_schema
from nexus_ai.services.telemetry import ensure_telemetry_schema

SchemaHook = Callable[[DuckDBManager], None]
OptionalHook = tuple[str, str]


def _run_optional_schema_hook(
    module_name: str, function_name: str, duck_mgr: DuckDBManager
) -> None:
    """Run optional schema initializer only when module is available in runtime."""
    if find_spec(module_name) is None:
        return

    hook = getattr(import_module(module_name), function_name, None)
    if callable(hook):
        hook(duck_mgr)


def _ensure_column(
    duck_mgr: DuckDBManager,
    table_name: str,
    known_columns: set[str],
    column_name: str,
    ddl_suffix: str,
) -> None:
    """Add missing column and update the local column registry."""
    if column_name in known_columns:
        return

    duck_mgr.execute(f"ALTER TABLE {table_name} ADD COLUMN {column_name} {ddl_suffix}")
    known_columns.add(column_name)


class AnalyticsSchemaManager:
    """Zarządza wersjonowaniem schematu DuckDB (odpowiednik migracji)."""
    __slots__ = ()

    @staticmethod
    def ensure_latest_schema(duck_mgr: DuckDBManager):
        """Dodaje brakujące kolumny do repliki, jeśli schemat się zmienił."""

        # Przykład: Dodanie kolumny issue_date, jeśli nie istnieje w starszej wersji bazy
        existing_cols = duck_mgr.execute("PRAGMA table_info('invoices_replica')")
        col_names = [col[1] for col in existing_cols]

        if "issue_date" not in col_names:
            duck_mgr.execute("ALTER TABLE invoices_replica ADD COLUMN issue_date DATE")

        # Tworzenie indeksów dla przyspieszenia raportów OLAP
        duck_mgr.execute(
            "CREATE INDEX IF NOT EXISTS idx_invoices_date ON invoices_replica (issue_date)"
        )
        duck_mgr.execute(
            "CREATE INDEX IF NOT EXISTS idx_invoices_status ON invoices_replica (status)"
        )

        core_schema_hooks: tuple[SchemaHook, ...] = (
            ensure_telemetry_schema,
            ensure_zpk_schema,
            ensure_fingerprint_schema,
            ensure_vendor_intelligence_schema,
            ensure_fixed_assets_schema,
            ensure_rmk_schema,
            ensure_inventory_schema,
        )
        for hook in core_schema_hooks:
            hook(duck_mgr)

        optional_schema_hooks: tuple[OptionalHook, ...] = (
            ("services.shadow_resource_correlation", "ensure_shadow_resource_schema"),
            ("services.compliance_analytics", "ensure_compliance_analytics_schema"),
            ("services.fx_revaluation", "ensure_fx_schema"),
            # ("services.smart_approvals", "ensure_smart_approval_schema") -- USUNIĘTE
            ("services.liquidity_oracle", "ensure_liquidity_schema"),
        )
        for module_name, function_name in optional_schema_hooks:
            _run_optional_schema_hook(module_name, function_name, duck_mgr)


def ensure_vendor_intelligence_schema(duck_mgr: DuckDBManager):
    duck_mgr.execute("""
    CREATE TABLE IF NOT EXISTS vendor_intelligence (
        nip VARCHAR PRIMARY KEY,
        vendor_name VARCHAR,
        avg_payment_delay DOUBLE,
        price_volatility_index DOUBLE,
        total_volume_ytd DOUBLE,
        reliability_score DOUBLE,
        rating_stars INTEGER,
        smart_alerts VARCHAR,
        updated_at TIMESTAMP DEFAULT now()
    )
    """)

    duck_mgr.execute("""
    CREATE TABLE IF NOT EXISTS vendor_price_alerts (
        id UUID DEFAULT uuid(),
        nip VARCHAR,
        item_name VARCHAR,
        current_price DOUBLE,
        six_month_avg DOUBLE,
        increase_ratio DOUBLE,
        alert_type VARCHAR,
        detected_at TIMESTAMP DEFAULT now()
    )
    """)


def ensure_fixed_assets_schema(duck_mgr: DuckDBManager):
    duck_mgr.execute("""
    CREATE TABLE IF NOT EXISTS fixed_assets (
        id UUID PRIMARY KEY,
        invoice_id UUID,
        asset_name VARCHAR NOT NULL,
        initial_value DECIMAL(18, 2) NOT NULL,
        salvage_value DECIMAL(18, 2) NOT NULL DEFAULT 0,
        residual_value DECIMAL(18, 2) NOT NULL DEFAULT 0,
        depreciation_method VARCHAR NOT NULL DEFAULT 'LINEAR',
        annual_rate DOUBLE,
        depreciation_rate DOUBLE NOT NULL,
        start_date DATE,
        purchase_date DATE NOT NULL,
        last_depreciation_date DATE,
        status VARCHAR NOT NULL DEFAULT 'ACTIVE',
        account_id_debit UBIGINT NOT NULL,
        account_id_credit UBIGINT NOT NULL
    )
    """)

    existing_cols = duck_mgr.execute("PRAGMA table_info('fixed_assets')")
    col_names = {col[1] for col in existing_cols}
    _ensure_column(
        duck_mgr, "fixed_assets", col_names, "residual_value", "DECIMAL(18, 2) NOT NULL DEFAULT 0"
    )
    _ensure_column(
        duck_mgr, "fixed_assets", col_names, "salvage_value", "DECIMAL(18, 2) NOT NULL DEFAULT 0"
    )
    _ensure_column(
        duck_mgr,
        "fixed_assets",
        col_names,
        "depreciation_method",
        "VARCHAR NOT NULL DEFAULT 'LINEAR'",
    )
    _ensure_column(duck_mgr, "fixed_assets", col_names, "annual_rate", "DOUBLE")
    _ensure_column(duck_mgr, "fixed_assets", col_names, "start_date", "DATE")
    _ensure_column(duck_mgr, "fixed_assets", col_names, "invoice_id", "UUID")
    _ensure_column(duck_mgr, "fixed_assets", col_names, "last_depreciation_date", "DATE")

    duck_mgr.execute("""
    CREATE TABLE IF NOT EXISTS depreciation_schedule (
        asset_id UUID NOT NULL,
        planned_date DATE NOT NULL,
        amount DECIMAL(18, 2) NOT NULL,
        is_posted BOOLEAN NOT NULL DEFAULT FALSE,
        status VARCHAR NOT NULL DEFAULT 'PENDING',
        ledger_id INTEGER NOT NULL DEFAULT 2,
        transfer_code INTEGER NOT NULL DEFAULT 1001,
        posted_at TIMESTAMP,
        PRIMARY KEY(asset_id, planned_date)
    )
    """)
    schedule_cols = duck_mgr.execute("PRAGMA table_info('depreciation_schedule')")
    schedule_col_names = {col[1] for col in schedule_cols}
    _ensure_column(
        duck_mgr,
        "depreciation_schedule",
        schedule_col_names,
        "status",
        "VARCHAR NOT NULL DEFAULT 'PENDING'",
    )


def ensure_rmk_schema(duck_mgr: DuckDBManager):
    duck_mgr.execute("""
    CREATE TABLE IF NOT EXISTS deferred_expenses (
        id UUID PRIMARY KEY,
        invoice_id UUID NOT NULL,
        description VARCHAR NOT NULL,
        total_net_amount DECIMAL(18, 2) NOT NULL,
        start_date DATE NOT NULL,
        end_date DATE NOT NULL,
        total_days INTEGER NOT NULL,
        daily_rate DECIMAL(18, 4) NOT NULL,
        status VARCHAR NOT NULL DEFAULT 'PENDING',
        cost_account_id VARCHAR NOT NULL
    )
    """)

    duck_mgr.execute("""
    CREATE TABLE IF NOT EXISTS rmk_ledger_entries (
        id UUID PRIMARY KEY,
        deferred_id UUID NOT NULL,
        posting_date DATE NOT NULL,
        amount DECIMAL(18, 2) NOT NULL,
        is_posted BOOLEAN NOT NULL DEFAULT FALSE,
        ledger_id INTEGER NOT NULL DEFAULT 1,
        transfer_code INTEGER NOT NULL DEFAULT 2001,
        rmk_asset_account_id VARCHAR NOT NULL DEFAULT '640',
        user_data_128 UUID NOT NULL
    )
    """)


def ensure_inventory_schema(duck_mgr: DuckDBManager):
    duck_mgr.execute("""
    CREATE TABLE IF NOT EXISTS inventory_batches (
        id UUID PRIMARY KEY,
        batch_id VARCHAR NOT NULL,
        product_id VARCHAR NOT NULL,
        warehouse_id VARCHAR,
        received_date DATE NOT NULL,
        source_document_id UUID,
        initial_qty DECIMAL(18, 4) NOT NULL,
        remaining_qty DECIMAL(18, 4) NOT NULL,
        unit_cost_net DECIMAL(18, 4) NOT NULL,
        currency VARCHAR NOT NULL DEFAULT 'PLN',
        created_at TIMESTAMP NOT NULL DEFAULT now(),
        CHECK (initial_qty >= 0),
        CHECK (remaining_qty >= 0),
        CHECK (remaining_qty <= initial_qty)
    )
    """)

    duck_mgr.execute("""
    CREATE TABLE IF NOT EXISTS inventory_consumption_events (
        id UUID PRIMARY KEY,
        product_id VARCHAR NOT NULL,
        issue_document_id UUID NOT NULL,
        issue_date DATE NOT NULL,
        issued_qty DECIMAL(18, 4) NOT NULL,
        total_cogs_net DECIMAL(18, 2) NOT NULL,
        created_at TIMESTAMP NOT NULL DEFAULT now()
    )
    """)

    duck_mgr.execute("""
    CREATE TABLE IF NOT EXISTS inventory_consumption_lines (
        id UUID PRIMARY KEY,
        consumption_event_id UUID NOT NULL,
        batch_id VARCHAR NOT NULL,
        product_id VARCHAR NOT NULL,
        qty_taken DECIMAL(18, 4) NOT NULL,
        unit_cost_net DECIMAL(18, 4) NOT NULL,
        line_cogs_net DECIMAL(18, 2) NOT NULL,
        created_at TIMESTAMP NOT NULL DEFAULT now()
    )
    """)
