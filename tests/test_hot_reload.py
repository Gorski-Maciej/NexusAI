"""
Unit tests for HotReloadListener — NATS rule change subscriber.

Tests:
  - SUBJECTS constant contains all 3 topics
  - _on_message handles valid JSON for each subject → clears correct cache prefix
  - _on_message handles malformed JSON gracefully
  - _on_message handles empty/missing fields
  - start() handles NATS unavailable gracefully
  - stop() works when not started (noop)
  - Cache clear failure is handled gracefully
"""

from __future__ import annotations

from nexus_ai.core.msgspec_utils import msgspec_dumps, msgspec_loads, msgspec_dumps_bytes
import sys
from pathlib import Path
from unittest.mock import AsyncMock, MagicMock, patch

import pytest

ROOT = Path(__file__).resolve().parents[1]
if str(ROOT) not in sys.path:
    sys.path.append(str(ROOT))

from conftest import _MockModule

# Ensure api.cache is mockable in sys.modules (needed by from api.cache import clear_cache_async within _on_message)
if "api.cache" not in sys.modules:
    sys.modules["api.cache"] = _MockModule("api.cache")

from nexus_ai.services.hot_reload import HotReloadListener, SUBJECTS


# ---------------------------------------------------------------------------
# Fixtures
# ---------------------------------------------------------------------------


@pytest.fixture
def listener() -> HotReloadListener:
    """Create a HotReloadListener without connecting to NATS."""
    return HotReloadListener(nats_url="nats://localhost:4222")


def _make_msg(subject: str, data: bytes) -> MagicMock:
    """Create a fake NATS message object."""
    msg = MagicMock()
    msg.subject = subject
    msg.data = data
    return msg


# ===========================================================================
# SUBJECTS constant
# ===========================================================================


class TestSubjects:
    """SUBJECTS should include all 4 rule update topics."""

    def test_all_subjects_present(self) -> None:
        assert "billing.rules.updated" in SUBJECTS
        assert "risk.thresholds.updated" in SUBJECTS
        assert "tax.rules.updated" in SUBJECTS
        assert "ledger.rules.updated" in SUBJECTS

    def test_exactly_four_subjects(self) -> None:
        assert len(SUBJECTS) == 4


# ===========================================================================
# Listener lifecycle
# ===========================================================================


class TestLifecycle:
    """start() / stop() lifecycle."""

    @pytest.mark.anyio
    async def test_stop_without_start(self, listener: HotReloadListener) -> None:
        """Calling stop() on a non-started listener should be a noop."""
        await listener.stop()
        assert listener._nc is None
        assert listener._task is None
        assert listener._subs == []

    @pytest.mark.anyio
    async def test_start_nats_unavailable(self, listener: HotReloadListener) -> None:
        """When NATS is unavailable, start() should log a warning and not crash."""
        with patch(
            "nats.connect",
            AsyncMock(side_effect=ConnectionError("NATS not available")),
        ):
            await listener.start()

        # Even though NATS connect failed, start() returns gracefully
        assert listener._nc is None
        assert listener._task is None


# ===========================================================================
# _on_message — valid JSON
# ===========================================================================


class TestOnMessageValidJson:
    """_on_message should clear correct cache prefix for each subject."""

    @pytest.mark.anyio
    async def test_billing_rules_updated(
        self, listener: HotReloadListener
    ) -> None:
        """billing.rules.updated → clear api.routes.billing cache."""
        msg = _make_msg(
            "billing.rules.updated",
            msgspec_dumps_bytes({"rule_id": "abc-123", "action": "created"}),
        )

        with patch(
            "api.cache.clear_cache_async", AsyncMock()
        ) as mock_clear:
            await listener._on_message(msg)

        mock_clear.assert_awaited_once_with(prefix="api.routes.billing")

    @pytest.mark.anyio
    async def test_risk_thresholds_updated(
        self, listener: HotReloadListener
    ) -> None:
        """risk.thresholds.updated → clear api.routes.admin cache."""
        msg = _make_msg(
            "risk.thresholds.updated",
            msgspec_dumps_bytes({"rule_id": "xyz-789", "action": "deprecated"}),
        )

        with patch(
            "api.cache.clear_cache_async", AsyncMock()
        ) as mock_clear:
            await listener._on_message(msg)

        mock_clear.assert_awaited_once_with(prefix="api.routes.admin")

    @pytest.mark.anyio
    async def test_tax_rules_updated(self, listener: HotReloadListener) -> None:
        """tax.rules.updated → clear api.routes.tax cache."""
        msg = _make_msg(
            "tax.rules.updated",
            msgspec_dumps_bytes({"rule_id": "tax-456", "action": "closed"}),
        )

        with patch(
            "api.cache.clear_cache_async", AsyncMock()
        ) as mock_clear:
            await listener._on_message(msg)

        mock_clear.assert_awaited_once_with(prefix="api.routes.tax")

    @pytest.mark.anyio
    async def test_ledger_rules_updated(self, listener: HotReloadListener) -> None:
        """ledger.rules.updated → clear api.routes.ledger cache."""
        msg = _make_msg(
            "ledger.rules.updated",
            msgspec_dumps_bytes({"rule_id": "ledger-789", "action": "created"}),
        )

        with patch(
            "api.cache.clear_cache_async", AsyncMock()
        ) as mock_clear:
            await listener._on_message(msg)

        mock_clear.assert_awaited_once_with(prefix="api.routes.ledger")


# ===========================================================================
# _on_message — edge cases
# ===========================================================================


class TestOnMessageMalformedJson:
    """_on_message should handle malformed JSON without crashing."""

    @pytest.mark.anyio
    async def test_invalid_json(self, listener: HotReloadListener) -> None:
        """Broken JSON → log warning, don't clear cache."""
        msg = _make_msg(
            "billing.rules.updated",
            b"this is not json at all",
        )

        with patch(
            "api.cache.clear_cache_async", AsyncMock()
        ) as mock_clear:
            await listener._on_message(msg)

        mock_clear.assert_not_awaited()

    @pytest.mark.anyio
    async def test_empty_bytes(self, listener: HotReloadListener) -> None:
        """Empty message body → log warning."""
        msg = _make_msg("risk.thresholds.updated", b"")

        with patch(
            "api.cache.clear_cache_async", AsyncMock()
        ) as mock_clear:
            await listener._on_message(msg)

        mock_clear.assert_not_awaited()

    @pytest.mark.anyio
    async def test_partial_json(self, listener: HotReloadListener) -> None:
        """Truncated JSON → log warning."""
        msg = _make_msg(
            "tax.rules.updated",
            b'{"rule_id": "incomplete"',
        )

        with patch(
            "api.cache.clear_cache_async", AsyncMock()
        ) as mock_clear:
            await listener._on_message(msg)

        mock_clear.assert_not_awaited()


class TestOnMessageMissingFields:
    """_on_message should use defaults for missing fields."""

    @pytest.mark.anyio
    async def test_empty_object(self, listener: HotReloadListener) -> None:
        """Empty JSON object {} → use defaults, cache clear still happens."""
        msg = _make_msg(
            "billing.rules.updated",
            msgspec_dumps_bytes({}),
        )

        with patch(
            "api.cache.clear_cache_async", AsyncMock()
        ) as mock_clear:
            await listener._on_message(msg)

        # Cache should still be cleared despite empty payload
        mock_clear.assert_awaited_once()
        assert mock_clear.await_args is not None
        assert mock_clear.await_args.kwargs.get("prefix") == "api.routes.billing"

    @pytest.mark.anyio
    async def test_only_rule_id(self, listener: HotReloadListener) -> None:
        """Only rule_id, no action → default 'unknown' for action, cache cleared."""
        msg = _make_msg(
            "tax.rules.updated",
            msgspec_dumps_bytes({"rule_id": "tax-001"}),
        )

        with patch(
            "api.cache.clear_cache_async", AsyncMock()
        ) as mock_clear:
            # Should not raise any exception
            await listener._on_message(msg)

        mock_clear.assert_awaited_once()


class TestOnMessageCacheFailure:
    """_on_message should handle cache clearing failures gracefully."""

    @pytest.mark.anyio
    async def test_cache_clear_raises(self, listener: HotReloadListener) -> None:
        """If clear_cache_async raises, _on_message should not crash."""
        msg = _make_msg(
            "risk.thresholds.updated",
            msgspec_dumps_bytes({"rule_id": "risk-001", "action": "created"}),
        )

        with patch(
            "api.cache.clear_cache_async",
            AsyncMock(side_effect=RuntimeError("Cache unavailable")),
        ):
            await listener._on_message(msg)

        # Should not raise — the exception is caught inside _on_message

    @pytest.mark.anyio
    async def test_cache_clear_import_error(
        self, listener: HotReloadListener
    ) -> None:
        """If api.cache module can't be imported, _on_message should not crash."""
        msg = _make_msg(
            "tax.rules.updated",
            msgspec_dumps_bytes({"rule_id": "tax-001"}),
        )

        # Remove api.cache from sys.modules to trigger import error
        saved = sys.modules.pop("api.cache", None)
        try:
            await listener._on_message(msg)
        finally:
            if saved is not None:
                sys.modules["api.cache"] = saved

        # Should not raise
