"""
Testy dla modułów Phase 5 (Druga Warstwa Poprawek).
====================================================
Pokrycie: proxy_router, wasm_gc, nbp_client, aml_compliance,
r0582_migration, ip_box_heuristic_guard, rot_guard, bundle_manager,
immutable_audit (RODO), safe_merge (Rego).
"""

from __future__ import annotations

import pytest


# ═══════════════════════════════════════════════════════════════════════════════
# P0: Proxy Router — Biała Lista anti-shadowban
# ═══════════════════════════════════════════════════════════════════════════════


class TestProxyRouter:
    """Testy dla BialaListaProxyRouter."""

    def test_router_initialization(self):
        """Router tworzy się z domyślnym proxy pool."""
        from nexus_ai.services.infrastructure.proxy_router import (
            BialaListaProxyRouter,
        )
        router = BialaListaProxyRouter()
        assert router is not None
        assert len(router._proxy_pool) >= 1

    def test_cache_lookup(self):
        """Cache zwraca wpis dla znanego NIP."""
        from nexus_ai.services.infrastructure.proxy_router import (
            BialaListaProxyRouter,
            WhitelistEntry,
        )
        router = BialaListaProxyRouter()
        entry = WhitelistEntry(
            nip="1234567890",
            found=True,
            account_numbers=["PL10105000997603123456789123"],
            name="Test JDG",
            status="CZYNNY",
        )
        router._cache["1234567890"] = entry
        cached = router.get_cached("1234567890")
        assert cached is not None
        assert cached.found is True
        assert cached.status == "CZYNNY"

    def test_cache_miss(self):
        """Nieznany NIP zwraca None."""
        from nexus_ai.services.infrastructure.proxy_router import (
            BialaListaProxyRouter,
        )
        router = BialaListaProxyRouter()
        assert router.get_cached("0000000000") is None

    def test_whitelist_entry_account_match(self):
        """Sprawdza dopasowanie numeru rachunku."""
        from nexus_ai.services.infrastructure.proxy_router import (
            WhitelistEntry,
        )
        entry = WhitelistEntry(
            nip="1234567890",
            found=True,
            account_numbers=["PL 10 1050 0099 7603 1234 5678 9123"],
            status="CZYNNY",
        )
        assert entry.account_matches("10 1050 0099 7603 1234 5678 9123") is True
        assert entry.account_matches("PL10105000997603123456789123") is True
        assert entry.account_matches("00 0000 0000 0000 0000 0000 0000") is False

    def test_proxy_pool_status(self):
        """Wszystkie proxy początkowo zdrowe."""
        from nexus_ai.services.infrastructure.proxy_router import (
            BialaListaProxyRouter,
        )
        router = BialaListaProxyRouter()
        status = router.proxy_pool_status
        assert len(status) == len(router._proxy_pool)
        assert all(status.values())

    def test_cache_invalidation(self):
        """Invalidacja czyści cache."""
        from nexus_ai.services.infrastructure.proxy_router import (
            BialaListaProxyRouter,
            WhitelistEntry,
        )
        router = BialaListaProxyRouter()
        router._cache["1234567890"] = WhitelistEntry(
            nip="1234567890", found=True,
        )
        router.invalidate_cache("1234567890")
        assert router.get_cached("1234567890") is None


# ═══════════════════════════════════════════════════════════════════════════════
# P1: WasmMemoryGuard — DuckDB memory limits
# ═══════════════════════════════════════════════════════════════════════════════


class TestWasmMemoryGuard:
    """Testy dla WasmMemoryGuard."""

    def test_guard_initialization(self):
        """Guard tworzy się z domyślnymi limitami."""
        from nexus_ai.tax.wasm_gc import WasmMemoryGuard
        guard = WasmMemoryGuard(tenant_id="test_tenant")
        assert guard._tenant_id == "test_tenant"
        assert guard._memory_limit_mb == 512
        assert guard._thread_limit == 4

    def test_guard_custom_limits(self):
        """Guard akceptuje niestandardowe limity."""
        from nexus_ai.tax.wasm_gc import WasmMemoryGuard
        guard = WasmMemoryGuard(
            tenant_id="premium_tenant",
            memory_limit_mb=1024,
            thread_limit=8,
        )
        assert guard._memory_limit_mb == 1024
        assert guard._thread_limit == 8

    def test_stats_initial_state(self):
        """Statystyki początkowe są zerowe."""
        from nexus_ai.tax.wasm_gc import WasmMemoryGuard
        guard = WasmMemoryGuard(tenant_id="test")
        stats = guard.get_stats()
        assert stats.queries_executed == 0
        assert stats.queries_rejected == 0
        assert stats.usage_ratio == 0.0

    def test_factory_function(self):
        """Funkcja fabryczna tworzy poprawny guard."""
        from nexus_ai.tax.wasm_gc import create_tenant_guard
        guard = create_tenant_guard("jdg_12345")
        assert guard is not None
        assert guard._tenant_id == "jdg_12345"
        assert guard._memory_limit_mb == 512

    def test_memory_limit_update(self):
        """Aktualizacja limitu pamięci."""
        from nexus_ai.tax.wasm_gc import WasmMemoryGuard
        guard = WasmMemoryGuard(tenant_id="test")
        guard.update_memory_limit(1024)
        assert guard._memory_limit_mb == 1024

    def test_memory_limit_too_low_rejected(self):
        """Limit poniżej 64MB jest odrzucany."""
        from nexus_ai.tax.wasm_gc import WasmMemoryGuard
        guard = WasmMemoryGuard(tenant_id="test")
        with pytest.raises(ValueError):
            guard.update_memory_limit(32)


# ═══════════════════════════════════════════════════════════════════════════════
# P1: NBP FX Client — NBP + ECB fallback
# ═══════════════════════════════════════════════════════════════════════════════


class TestNbpFxClient:
    """Testy dla NbpFxClient."""

    def test_client_initialization(self):
        """Klient tworzy się poprawnie."""
        from nexus_ai.tax.nbp_client import NbpFxClient
        client = NbpFxClient()
        assert client is not None
        assert client.is_nbp_available is True

    def test_last_business_day(self):
        """Obliczanie ostatniego dnia roboczego."""
        from nexus_ai.tax.nbp_client import NbpFxClient

        # Poniedziałek → piątek
        assert NbpFxClient._last_business_day("2026-07-13") == "2026-07-10"

        # Niedziela → piątek
        assert NbpFxClient._last_business_day("2026-07-12") == "2026-07-10"

        # Wtorek → poniedziałek
        assert NbpFxClient._last_business_day("2026-07-14") == "2026-07-13"

    def test_cache_hit(self):
        """Cache zwraca zapisany kurs."""
        from nexus_ai.tax.nbp_client import NbpFxClient, FxRate
        import time
        client = NbpFxClient()
        rate = FxRate(
            currency="EUR",
            rate=4.50,
            date="2026-07-10",
            source="NBP_TABLE_A",
            fetched_at=time.time(),
        )
        client._cache["EUR:2026-07-10"] = rate
        cached = client.get_cached_rate("EUR", "2026-07-10")
        assert cached is not None
        assert cached.rate == 4.50

    def test_cache_miss(self):
        """Brak wpisu w cache zwraca None."""
        from nexus_ai.tax.nbp_client import NbpFxClient
        client = NbpFxClient()
        assert client.get_cached_rate("XYZ", "2026-07-10") is None

    def test_pln_no_conversion_needed(self):
        """PLN nie wymaga przeliczania."""
        import asyncio
        from nexus_ai.tax.nbp_client import NbpFxClient

        async def _test():
            client = NbpFxClient()
            result = await client.convert_to_pln(100.0, "PLN", "2026-07-12")
            assert result == 100.0

        asyncio.run(_test())


# ═══════════════════════════════════════════════════════════════════════════════
# P0: AML V Compliance — SAR reporting
# ═══════════════════════════════════════════════════════════════════════════════


class TestAMLCompliance:
    """Testy dla AMLComplianceMonitor."""

    def test_monitor_initialization(self):
        """Monitor tworzy się poprawnie."""
        from nexus_ai.tax.aml_compliance import AMLComplianceMonitor
        monitor = AMLComplianceMonitor()
        assert monitor is not None
        assert monitor._amount_threshold == 50000

    def test_empty_invoice_triggers_sar(self):
        """Pusta faktura (jdg.kks.empty_invoice_issued) wyzwala SAR."""
        import asyncio
        from nexus_ai.tax.aml_compliance import AMLComplianceMonitor

        async def _test():
            monitor = AMLComplianceMonitor()
            verdict = {
                "rule_id": "jdg.kks.empty_invoice_issued",
                "_routing": "BLOCK_AND_ALERT",
                "amount_gross": 100000,
                "transaction_date": "2026-07-12",
            }
            report = await monitor.analyze_verdict(verdict, "jdg_123")
            assert report is not None
            assert report.classification.value == "FRAUDULENT_INVOICES"

        asyncio.run(_test())

    def test_below_threshold_no_sar(self):
        """Transakcja poniżej progu nie wyzwala SAR."""
        import asyncio
        from nexus_ai.tax.aml_compliance import AMLComplianceMonitor

        async def _test():
            monitor = AMLComplianceMonitor()
            verdict = {
                "rule_id": "P305",
                "_routing": "BLOCK_AND_ALERT",
                "amount_gross": 10000,  # Poniżej 50k
                "transaction_date": "2026-07-12",
            }
            report = await monitor.analyze_verdict(verdict, "jdg_123")
            assert report is None

        asyncio.run(_test())

    def test_normal_verdict_no_sar(self):
        """Zwykły werdykt nie wyzwala SAR."""
        import asyncio
        from nexus_ai.tax.aml_compliance import AMLComplianceMonitor

        async def _test():
            monitor = AMLComplianceMonitor()
            verdict = {
                "rule_id": "jdg.vat.a5.r1",
                "_routing": "",
                "amount_gross": 5000,
            }
            report = await monitor.analyze_verdict(verdict, "jdg_123")
            assert report is None

        asyncio.run(_test())

    def test_sar_xml_generation(self):
        """Generowanie XML SAR dla reguły KKS."""
        import asyncio
        from nexus_ai.tax.aml_compliance import AMLComplianceMonitor

        async def _test():
            monitor = AMLComplianceMonitor()
            verdict = {
                "rule_id": "jdg.kks.empty_invoice_issued",
                "_routing": "BLOCK_AND_ALERT",
                "amount_gross": 100000,
                "transaction_date": "2026-07-12",
            }
            report = await monitor.analyze_verdict(verdict, "jdg_123")
            assert report is not None
            assert "SuspiciousActivityReport" in report.xml_payload
            assert "FRAUDULENT_INVOICES" in report.xml_payload
            assert "100000.00" in report.xml_payload

        asyncio.run(_test())


# ═══════════════════════════════════════════════════════════════════════════════
# P0: R0582 Migration — Historical DRA audit
# ═══════════════════════════════════════════════════════════════════════════════


class TestR0582Migration:
    """Testy dla R0582MigrationEngine."""

    def test_engine_initialization(self):
        """Silnik tworzy się poprawnie."""
        from nexus_ai.tax.r0582_migration import R0582MigrationEngine
        engine = R0582MigrationEngine()
        assert engine is not None

    def test_health_minimal_base_by_year(self):
        """Podstawa składki zdrowotnej zmienia się rocznie."""
        from nexus_ai.tax.r0582_migration import R0582MigrationEngine
        engine = R0582MigrationEngine()
        assert engine.HEALTH_MINIMAL_BASE["2024"] == 4666.00
        assert engine.HEALTH_MINIMAL_BASE["2025"] == 5200.00
        assert engine.HEALTH_MINIMAL_BASE["2026"] == 5500.00

    def test_correction_shortfall_positive(self):
        """Korekta: gdy wpłacono 0, shortfall = cała składka."""
        from nexus_ai.tax.r0582_migration import DraCorrection
        corr = DraCorrection(
            period="2026-07",
            entrepreneur_id="jdg_123",
            was_suspended=True,
            health_contribution_due=495.00,
            health_contribution_paid=0.0,
            shortfall=495.00,
            requires_correction=True,
        )
        assert corr.is_critical is False  # Tylko 1 miesiąc
        assert corr.shortfall == 495.00

    def test_correction_critical(self):
        """Korekta krytyczna: >3 miesiące zaległości."""
        from nexus_ai.tax.r0582_migration import DraCorrection
        corr = DraCorrection(
            period="2026-07",
            entrepreneur_id="jdg_123",
            was_suspended=True,
            health_contribution_due=100.00,
            health_contribution_paid=0.0,
            shortfall=400.00,  # 4x miesięczna składka
            requires_correction=True,
        )
        assert corr.is_critical is True

    def test_correction_no_shortfall(self):
        """Brak niedopłaty — korekta niepotrzebna."""
        from nexus_ai.tax.r0582_migration import DraCorrection
        corr = DraCorrection(
            period="2026-07",
            entrepreneur_id="jdg_123",
            was_suspended=True,
            health_contribution_due=495.00,
            health_contribution_paid=495.00,
            shortfall=0.0,
            requires_correction=False,
        )
        assert corr.requires_correction is False

    def test_migration_report_summary(self):
        """Raport migracji generuje poprawne podsumowanie."""
        from nexus_ai.tax.r0582_migration import MigrationReport
        report = MigrationReport(
            entrepreneur_id="jdg_123",
            periods_checked=24,
            total_shortfall=990.00,
            critical_count=1,
        )
        assert "jdg_123" in report.summary
        assert "24" in report.summary
        assert "990.00" in report.summary

    def test_notification_generation(self):
        """Generowanie notyfikacji dla przedsiębiorcy."""
        import asyncio
        from nexus_ai.tax.r0582_migration import (
            R0582MigrationEngine,
            DraCorrection,
            MigrationReport,
        )

        async def _test():
            engine = R0582MigrationEngine()
            report = MigrationReport(
                entrepreneur_id="jdg_123",
                periods_checked=24,
                corrections_needed=[
                    DraCorrection(
                        period="2026-03",
                        entrepreneur_id="jdg_123",
                        was_suspended=True,
                        health_contribution_due=495.00,
                        health_contribution_paid=0.0,
                        shortfall=495.00,
                        requires_correction=True,
                    ),
                ],
                total_shortfall=495.00,
                critical_count=0,
            )
            notification = await engine.notify_entrepreneur(report)
            assert "składka zdrowotna" in notification.lower()
            assert "495.00" in notification

        asyncio.run(_test())


# ═══════════════════════════════════════════════════════════════════════════════
# P0: IP Box Heuristic Guard
# ═══════════════════════════════════════════════════════════════════════════════


class TestIpBoxGuard:
    """Testy dla IpBoxHeuristicGuard."""

    def test_guard_initialization(self):
        """Guard tworzy się z domyślnymi progami."""
        from nexus_ai.tax.ip_box_heuristic_guard import IpBoxHeuristicGuard
        guard = IpBoxHeuristicGuard()
        assert guard._min_confidence == 0.95
        assert guard._min_nexus_ratio == 0.30

    def test_high_confidence_approved(self):
        """Wysoka pewność (>=95%) — automatycznie zatwierdzone."""
        from nexus_ai.tax.ip_box_heuristic_guard import IpBoxHeuristicGuard
        guard = IpBoxHeuristicGuard()
        verdict = {
            "rule_id": "P610",
            "confidence": 0.97,
            "nexus_ratio": 0.80,
        }
        result = guard.evaluate(verdict)
        assert result.blocked is False
        assert result.is_auto_approved is True

    def test_low_confidence_blocked(self):
        """Niska pewność (<95%) — zablokowane."""
        from nexus_ai.tax.ip_box_heuristic_guard import IpBoxHeuristicGuard
        guard = IpBoxHeuristicGuard()
        verdict = {
            "rule_id": "P610",
            "confidence": 0.85,
            "nexus_ratio": 0.80,
        }
        result = guard.evaluate(verdict)
        assert result.blocked is True
        assert result.is_auto_approved is False

    def test_low_nexus_blocked(self):
        """Niski Nexus ratio (<30%) — zablokowane."""
        from nexus_ai.tax.ip_box_heuristic_guard import IpBoxHeuristicGuard
        guard = IpBoxHeuristicGuard()
        verdict = {
            "rule_id": "P610",
            "confidence": 0.98,
            "nexus_ratio": 0.15,
        }
        result = guard.evaluate(verdict)
        assert result.blocked is True

    def test_block_low_confidence_kis_draft(self):
        """Funkcja pomocnicza blokuje draft KIS przy niskiej pewności."""
        from nexus_ai.tax.ip_box_heuristic_guard import (
            IpBoxHeuristicGuard,
        )
        assert IpBoxHeuristicGuard.block_low_confidence_kis_draft(
            {"rule_id": "kis_draft_ip_box", "confidence": 0.80},
        ) is True
        assert IpBoxHeuristicGuard.block_low_confidence_kis_draft(
            {"rule_id": "kis_draft_ip_box", "confidence": 0.98},
        ) is False

    def test_high_concentration_warning(self):
        """>80% przychodów z IP Box — ostrzeżenie (ale nie blokada)."""
        from nexus_ai.tax.ip_box_heuristic_guard import IpBoxHeuristicGuard
        guard = IpBoxHeuristicGuard()
        verdict = {
            "rule_id": "P610",
            "confidence": 0.98,
            "nexus_ratio": 0.80,
        }
        context = {
            "total_annual_revenue": 100000,
            "ip_box_revenue": 90000,  # 90% — powyżej 80%
        }
        result = guard.evaluate(verdict, context)
        assert result.blocked is False  # Nie blokujemy, tylko ostrzegamy
        assert "UWAGA" in result.recommendation


# ═══════════════════════════════════════════════════════════════════════════════
# P0: RODO Art. 17 — TenantSaltKMS + ImmutableAuditWithRODO
# ═══════════════════════════════════════════════════════════════════════════════


class TestRODOArt17:
    """Testy RODO Art. 17 (prawo do bycia zapomnianym)."""

    def test_kms_generate_salt(self):
        """KMS generuje unikalny salt per tenant."""
        from nexus_ai.tax.immutable_audit import TenantSaltKMS
        kms = TenantSaltKMS()
        salt1 = kms.generate_salt("tenant_a")
        salt2 = kms.generate_salt("tenant_b")
        assert salt1 != salt2
        assert len(salt1) == 64  # 32 bajty hex = 64 znaki

    def test_kms_idempotent_salt(self):
        """Drugie wywołanie generate_salt zwraca ten sam salt."""
        from nexus_ai.tax.immutable_audit import TenantSaltKMS
        kms = TenantSaltKMS()
        salt1 = kms.generate_salt("tenant_x")
        salt2 = kms.generate_salt("tenant_x")
        assert salt1 == salt2

    def test_kms_delete_salt(self):
        """Usunięcie salt — tenant zapomniany."""
        from nexus_ai.tax.immutable_audit import TenantSaltKMS
        kms = TenantSaltKMS()
        kms.generate_salt("tenant_x")
        assert kms.is_forgotten("tenant_x") is False
        assert kms.delete_salt("tenant_x") is True
        assert kms.is_forgotten("tenant_x") is True

    def test_kms_double_delete(self):
        """Drugie usunięcie salt zwraca False."""
        from nexus_ai.tax.immutable_audit import TenantSaltKMS
        kms = TenantSaltKMS()
        kms.generate_salt("tenant_x")
        kms.delete_salt("tenant_x")
        assert kms.delete_salt("tenant_x") is False

    def test_kms_deletion_log(self):
        """Log usunięć zawiera dowód dla UODO."""
        from nexus_ai.tax.immutable_audit import TenantSaltKMS
        kms = TenantSaltKMS()
        kms.generate_salt("tenant_x")
        kms.delete_salt("tenant_x")
        log = kms.deletion_log
        assert len(log) == 1
        assert log[0]["tenant_id"] == "tenant_x"
        assert "RODO Art. 17" in log[0]["reason"]

    def test_audit_with_rodo_anonymize_pii(self):
        """Anonimizacja PESEL/NIP przez salted hashing."""
        from nexus_ai.tax.immutable_audit import (
            ImmutableAuditWithRODO,
        )
        auditor = ImmutableAuditWithRODO()
        anonymized = auditor.anonymize_pii("12345678901", "tenant_x")
        assert anonymized != "12345678901"  # Nie cleartext
        assert len(anonymized) == 64  # SHA-256 hex

    def test_audit_with_rodo_same_input_different_tenants(self):
        """Ten sam PESEL, różne tenanty → różne hashe (różne solty)."""
        from nexus_ai.tax.immutable_audit import (
            ImmutableAuditWithRODO,
        )
        auditor = ImmutableAuditWithRODO()
        # Używamy process_audit_record które gwarantuje wygenerowanie soli
        result_a = auditor.process_audit_record(
            {"pesel": "12345678901"}, "tenant_a",
        )
        result_b = auditor.process_audit_record(
            {"pesel": "12345678901"}, "tenant_b",
        )
        hash_a = result_a["anonymized_payload"]["pesel"]
        hash_b = result_b["anonymized_payload"]["pesel"]
        assert hash_a != hash_b  # Różne solty → różne hashe

    def test_audit_with_rodo_forget_tenant(self):
        """Po zapomnieniu tenanta, anonymize_pii zwraca pusty string."""
        from nexus_ai.tax.immutable_audit import (
            ImmutableAuditWithRODO,
        )
        auditor = ImmutableAuditWithRODO()
        # Najpierw wygeneruj salt przez process_audit_record
        auditor.process_audit_record({"pesel": "12345678901"}, "tenant_x")
        # Zapomnij tenanta
        auditor.forget_tenant("tenant_x")
        # Teraz anonymize_pii powinno zwrócić pusty string
        result = auditor.anonymize_pii("12345678901", "tenant_x")
        assert result == ""

    def test_audit_with_rodo_process_record(self):
        """Przetwarzanie rekordu z anonimizacją."""
        from nexus_ai.tax.immutable_audit import (
            ImmutableAuditWithRODO,
        )
        auditor = ImmutableAuditWithRODO()
        payload = {
            "pesel": "12345678901",
            "nip": "1234567890",
            "name": "Jan Kowalski",
        }
        result = auditor.process_audit_record(payload, "tenant_x")
        assert "anonymized_payload" in result
        assert result["anonymized_payload"]["pesel"] != "12345678901"
        assert result["anonymized_payload"]["nip"] != "1234567890"
        assert result["anonymized_payload"]["name"] == "Jan Kowalski"  # Nie PII


# ═══════════════════════════════════════════════════════════════════════════════
# P2: Bundle Manager — Semver
# ═══════════════════════════════════════════════════════════════════════════════


class TestBundleManager:
    """Testy dla BundleManager."""

    def test_manager_initialization(self):
        """Manager tworzy się poprawnie."""
        import tempfile
        from pathlib import Path
        from nexus_ai.services.infrastructure.bundle_manager import BundleManager

        with tempfile.TemporaryDirectory() as tmp:
            manager = BundleManager(bundles_dir=Path(tmp))
            assert manager is not None
            assert manager._manifest is not None

    def test_bundle_version_semver(self):
        """BundleVersion generuje poprawny semver."""
        from nexus_ai.services.infrastructure.bundle_manager import BundleVersion
        v = BundleVersion(
            major=1, minor=2, patch=3,
            hash="abc123def456",
        )
        assert v.semver == "1.2.3"
        assert v.short_hash == "abc123de"

    def test_register_version(self):
        """Rejestracja nowej wersji."""
        import tempfile
        from pathlib import Path
        from nexus_ai.services.infrastructure.bundle_manager import BundleManager

        with tempfile.TemporaryDirectory() as tmp:
            manager = BundleManager(bundles_dir=Path(tmp))
            v = manager.register_version(
                major=1, minor=0, patch=0,
                bundle_content="test bundle",
                description="Initial version",
            )
            assert v.semver == "1.0.0"
            assert len(v.hash) == 64  # SHA-256

    def test_activate_version(self):
        """Aktywacja wersji."""
        import tempfile
        from pathlib import Path
        from nexus_ai.services.infrastructure.bundle_manager import BundleManager

        with tempfile.TemporaryDirectory() as tmp:
            manager = BundleManager(bundles_dir=Path(tmp))
            v1 = manager.register_version(1, 0, 0, "bundle v1")
            v2 = manager.register_version(1, 1, 0, "bundle v2")
            assert manager.activate_version("1.1.0") is True
            current = manager.get_current_version()
            assert current is not None
            assert current.semver == "1.1.0"

    def test_compute_bundle_hash(self):
        """Obliczanie SHA-256 katalogu z plikami .rego."""
        import tempfile
        from pathlib import Path
        from nexus_ai.services.infrastructure.bundle_manager import BundleManager

        with tempfile.TemporaryDirectory() as tmp:
            tmp_path = Path(tmp)
            (tmp_path / "test.rego").write_text("package test\n")
            (tmp_path / "other.rego").write_text("package other\n")
            hash1 = BundleManager.compute_bundle_hash(tmp_path)
            assert len(hash1) == 64
            # Ta sama zawartość → ten sam hash
            hash2 = BundleManager.compute_bundle_hash(tmp_path)
            assert hash1 == hash2

    def test_deprecate_version(self):
        """Deprecjacja wersji."""
        import tempfile
        from pathlib import Path
        from nexus_ai.services.infrastructure.bundle_manager import BundleManager

        with tempfile.TemporaryDirectory() as tmp:
            manager = BundleManager(bundles_dir=Path(tmp))
            manager.register_version(1, 0, 0, "old bundle")
            assert manager.deprecate_version("1.0.0") is True
            v = manager.get_version("1.0.0")
            assert v is not None
            assert v.is_deprecated is True
