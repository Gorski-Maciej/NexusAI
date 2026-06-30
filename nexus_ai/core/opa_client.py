"""
OPA Client -- async Python client for Open Policy Agent REST API.

Zgodnie z aa3fvcx.txt:
- OPA (Open Policy Agent) jako deklaratywny silnik reguł (CNCF)
- Komunikacja przez REST API (httpx, async)
- OPA uruchomiony jako sidecar (natywny binary ~15MB, jak NATS/TigerBeetle)
- Rego policies generowane dynamicznie z DuckDB

Architektura:
  OPA Sidecar (localhost:8181) ← httpx -> OpaClient (Python)
                                         -> RuleEngine.decide()

Usage:
    client = OpaClient(base_url="http://localhost:8181")
    result = await client.evaluate("tax/rules/decide", input_data)
    await client.load_data("tax/rules", rules_data)
"""

from __future__ import annotations

from typing import Any

import httpx
from structlog import get_logger

logger = get_logger("nexus.opa")

# ── Default OPA URL ─────────────────────────────────────────────────────────

OPA_DEFAULT_URL = "http://localhost:8181"
"""Default OPA REST API URL (sidecar process)."""

OPA_POLICY_PACKAGE = "tax.rules"
"""Default Rego package for tax rules."""

OPA_POLICY_RULE = "decide"
"""Default Rego rule for tax decision."""


# ── Exceptions ──────────────────────────────────────────────────────────────


class OpaError(Exception):
    """Base exception for OPA-related errors."""

    def __init__(self, message: str, status_code: int = 0, details: str = "") -> None:
        super().__init__(message)
        self.status_code = status_code
        self.details = details


class OpaConnectionError(OpaError):
    """OPA server is unreachable."""

    pass


class OpaEvaluationError(OpaError):
    """OPA policy evaluation failed."""

    pass


class OpaPolicyNotFound(OpaError):
    """Requested policy/rule not found in OPA."""

    pass


# ── OPA Client ──────────────────────────────────────────────────────────────


class OpaClient:
    """Async HTTP client for Open Policy Agent REST API.

    Manages a connection to a local OPA sidecar process.
    All methods are async and use httpx for HTTP/2 support.

    Args:
        base_url: OPA server URL (default: http://localhost:8181).
        timeout: HTTP request timeout in seconds.
    """

    def __init__(
        self,
        base_url: str = OPA_DEFAULT_URL,
        timeout: float = 10.0,
    ) -> None:
        self._base_url = base_url.rstrip("/")
        self._timeout = timeout
        self._client: httpx.AsyncClient | None = None

    async def _get_client(self) -> httpx.AsyncClient:
        """Lazy-init HTTP client with HTTP/2 and connection pooling."""
        if self._client is None:
            self._client = httpx.AsyncClient(
                base_url=self._base_url,
                timeout=httpx.Timeout(
                    connect=5.0,
                    read=self._timeout,
                    write=self._timeout,
                    pool=30.0,
                ),
                limits=httpx.Limits(
                    max_connections=10,
                    max_keepalive_connections=5,
                    keepalive_expiry=60.0,
                ),
                http2=True,
            )
        return self._client

    async def close(self) -> None:
        """Close the HTTP client and release connections."""
        if self._client is not None:
            await self._client.aclose()
            self._client = None

    # ── Health check ─────────────────────────────────────────────────────

    async def health(self) -> bool:
        """Check if OPA server is healthy.

        Returns:
            True if OPA responds with HTTP 200.
        """
        try:
            client = await self._get_client()
            response = await client.get("/health")
            return response.status_code == 200
        except httpx.ConnectError as exc:
            logger.warning("[OPA] Health check failed: %s", exc)
            return False

    # ── Policy evaluation ────────────────────────────────────────────────

    async def evaluate(
        self,
        path: str = "tax/rules/decide",
        input_data: dict[str, Any] | None = None,
    ) -> dict[str, Any]:
        """Evaluate a Rego policy with given input.

        POST /v1/data/{path} with JSON body {"input": input_data}.

        Args:
            path: Policy path in OPA (e.g. "tax/rules/decide").
            input_data: Input context for policy evaluation.

        Returns:
            Policy decision result dict (OPA's "result" field).

        Raises:
            OpaConnectionError: If OPA is unreachable.
            OpaEvaluationError: If evaluation fails.
            OpaPolicyNotFound: If policy/rule not found.
        """
        client = await self._get_client()
        url = f"/v1/data/{path.lstrip('/')}"
        payload: dict[str, Any] = {}
        if input_data is not None:
            payload["input"] = input_data

        try:
            logger.debug(
                "[OPA] Evaluating path=%s input_keys=%s",
                path,
                list(input_data.keys()) if input_data else [],
            )
            response = await client.post(url, json=payload)
        except httpx.ConnectError as exc:
            raise OpaConnectionError(
                f"OPA server unreachable at {self._base_url}: {exc}",
                details=str(exc),
            ) from exc
        except httpx.TimeoutException as exc:
            raise OpaConnectionError(
                f"OPA request timed out at {self._base_url}: {exc}",
                details=str(exc),
            ) from exc

        if response.status_code == 404:
            raise OpaPolicyNotFound(
                f"Policy not found at path={path}. Ensure the Rego policy is loaded into OPA.",
            )

        if response.status_code != 200:
            error_body = response.text[:500]
            raise OpaEvaluationError(
                f"OPA evaluation failed: HTTP {response.status_code}",
                status_code=response.status_code,
                details=error_body,
            )

        try:
            body = response.json()
        except Exception as exc:
            raise OpaEvaluationError(
                f"OPA returned invalid JSON: {exc}",
                details=response.text[:500],
            ) from exc

        # OPA returns {"result": ...} for successful evaluations
        result = body.get("result")
        if result is None:
            # Undefined result (no rule matched) -- OPA returns null result
            logger.warning("[OPA] Undefined result for path=%s -- no rule matched", path)
            return {"matched": False, "verdict": {}}

        if not isinstance(result, dict):
            # Scalar result -- wrap for consistent API
            return {"matched": True, "verdict": {"result": result}}

        # Dict result -- already structured verdict
        return result

    # ── Data management ──────────────────────────────────────────────────

    async def load_data(
        self,
        path: str,
        data: dict[str, Any],
    ) -> bool:
        """Load/update OPA data document at the given path.

        PUT /v1/data/{path} with JSON body.

        Used to load tax rules from DuckDB into OPA as data documents.
        OPA merges data at different paths, so multiple calls are additive.

        Args:
            path: Data path (e.g. "tax/rules").
            data: JSON-serializable data to load.

        Returns:
            True if successful.

        Raises:
            OpaConnectionError: If OPA is unreachable.
            OpaError: On other failures.
        """
        client = await self._get_client()
        url = f"/v1/data/{path.lstrip('/')}"

        try:
            response = await client.put(url, json=data)
        except httpx.ConnectError as exc:
            raise OpaConnectionError(
                f"OPA server unreachable: {exc}",
            ) from exc

        if response.status_code not in (200, 204):
            raise OpaError(
                f"Failed to load data into OPA at path={path}: HTTP {response.status_code}",
                status_code=response.status_code,
                details=response.text[:500],
            )

        logger.info("[OPA] Loaded data at path=%s (%d keys)", path, len(data))
        return True

    async def delete_data(self, path: str) -> bool:
        """Delete OPA data document at the given path.

        DELETE /v1/data/{path}.

        Args:
            path: Data path to delete.

        Returns:
            True if successful.
        """
        client = await self._get_client()
        url = f"/v1/data/{path.lstrip('/')}"

        try:
            response = await client.delete(url)
        except httpx.ConnectError as exc:
            raise OpaConnectionError(
                f"OPA server unreachable: {exc}",
            ) from exc

        if response.status_code not in (200, 204):
            logger.warning(
                "[OPA] Failed to delete data at path=%s: HTTP %d",
                path,
                response.status_code,
            )
            return False

        logger.info("[OPA] Deleted data at path=%s", path)
        return True

    # ── Policy management ────────────────────────────────────────────────

    async def load_policy(self, policy_name: str, rego_code: str) -> bool:
        """Load a Rego policy into OPA.

        PUT /v1/policies/{policy_name} with Rego source code.

        Args:
            policy_name: Policy identifier (e.g. "tax/rules.rego").
            rego_code: Raw Rego source code.

        Returns:
            True if successful.
        """
        client = await self._get_client()
        url = f"/v1/policies/{policy_name.lstrip('/')}"

        try:
            response = await client.put(
                url,
                content=rego_code,
                headers={"Content-Type": "text/plain"},
            )
        except httpx.ConnectError as exc:
            raise OpaConnectionError(
                f"OPA server unreachable: {exc}",
            ) from exc

        if response.status_code not in (200, 204):
            raise OpaError(
                f"Failed to load policy {policy_name}: HTTP {response.status_code}",
                status_code=response.status_code,
                details=response.text[:500],
            )

        logger.info("[OPA] Loaded policy=%s (%d chars)", policy_name, len(rego_code))
        return True

    async def delete_policy(self, policy_name: str) -> bool:
        """Delete a Rego policy from OPA.

        DELETE /v1/policies/{policy_name}.

        Args:
            policy_name: Policy identifier.

        Returns:
            True if successful.
        """
        client = await self._get_client()
        url = f"/v1/policies/{policy_name.lstrip('/')}"

        try:
            response = await client.delete(url)
        except httpx.ConnectError as exc:
            raise OpaConnectionError(
                f"OPA server unreachable: {exc}",
            ) from exc

        if response.status_code == 404:
            logger.warning("[OPA] Policy not found for deletion: %s", policy_name)
            return False

        logger.info("[OPA] Deleted policy=%s", policy_name)
        return True

    # ── Batch evaluation ─────────────────────────────────────────────────

    async def evaluate_batch(
        self,
        path: str = "tax/rules/decide",
        inputs: list[dict[str, Any]] | None = None,
    ) -> list[dict[str, Any]]:
        """Evaluate multiple inputs against the same policy.

        Uses individual HTTP calls for each input (OPA doesn't support
        native batching). For high-throughput scenarios, consider
        using OPA's Wasm evaluation instead.

        Args:
            path: Policy path.
            inputs: List of input contexts.

        Returns:
            List of results in the same order as inputs.
        """
        if not inputs:
            return []

        results: list[dict[str, Any]] = []
        for i, input_data in enumerate(inputs):
            try:
                result = await self.evaluate(path, input_data)
                results.append(result)
            except OpaError as exc:
                logger.error("[OPA] Batch item %d failed: %s", i, exc)
                results.append({"matched": False, "error": str(exc)})

        return results

    # ── Context manager ──────────────────────────────────────────────────

    async def __aenter__(self) -> OpaClient:
        return self

    async def __aexit__(self, *args: Any) -> None:
        await self.close()
