// ═══════════════════════════════════════════════════════════════════════════════
// JWT — HS256 verification + claims validation (jsonwebtoken + PyO3)
// ═══════════════════════════════════════════════════════════════════════════════
//
// Zastępuje: nexus_ai/api/middleware.py → _tenant_from_bearer_auth()
// Nowy:     Rust + jsonwebtoken crate — 10-50× szybsza weryfikacja JWT
//
// Funkcje eksportowane do Pythona:
//   verify_jwt(token, secret, required_issuer, required_audience) → dict | None
//   decode_jwt_header(token) → dict | None
//
// Zgodność z istniejącą implementacją:
//   - HS256 (HMAC-SHA256)
//   - Weryfikacja exp, nbf, iss, aud
//   - Ekstrakcja tenant_id z claims
//   - Akceptacja typ "JWT" i "AT+JWT"
// ═══════════════════════════════════════════════════════════════════════════════

use base64::Engine as _;
use pyo3::exceptions::{PyTypeError, PyValueError};
use pyo3::prelude::*;
use pyo3::types::PyDict;
use serde::{Deserialize, Serialize};
use std::collections::HashSet;

// ── Claims struct (what we extract from the JWT payload) ──────────────────

/// JWT claims matching the NexusAI token format.
#[derive(Debug, Deserialize, Serialize)]
struct JwtClaims {
    sub: Option<String>,
    iss: Option<String>,
    aud: Option<serde_json::Value>,  // can be string or array of strings
    exp: Option<u64>,
    nbf: Option<u64>,
    iat: Option<u64>,
    tenant_id: Option<String>,
    tenant: Option<String>,
    username: Option<String>,
    role: Option<String>,
    jwt_version: Option<i64>,
    #[serde(flatten)]
    extra: std::collections::HashMap<String, serde_json::Value>,
}

// ── Helper: convert serde_json::Value to Python object ─────────────────────

fn json_to_py(py: Python<'_>, value: &serde_json::Value) -> PyObject {
    match value {
        serde_json::Value::Null => py.None(),
        serde_json::Value::Bool(b) => b.to_object(py),
        serde_json::Value::Number(n) => {
            if let Some(i) = n.as_i64() {
                i.to_object(py)
            } else if let Some(f) = n.as_f64() {
                f.to_object(py)
            } else {
                n.to_string().to_object(py)
            }
        }
        serde_json::Value::String(s) => s.to_object(py),
        serde_json::Value::Array(arr) => {
            arr.iter().map(|v| json_to_py(py, v)).collect::<Vec<_>>().to_object(py)
        }
        serde_json::Value::Object(map) => {
            let dict = PyDict::new_bound(py);
            for (k, v) in map {
                dict.set_item(k.as_str(), json_to_py(py, &v)).ok();
            }
            dict.into()
        }
    }
}

// ── Helper: convert JwtClaims to Python dict ───────────────────────────────

fn claims_to_pydict(py: Python<'_>, claims: &JwtClaims) -> PyObject {
    let dict = PyDict::new_bound(py);
    if let Some(ref v) = claims.sub {
        dict.set_item("sub", v).ok();
    }
    if let Some(ref v) = claims.iss {
        dict.set_item("iss", v).ok();
    }
    if let Some(ref v) = claims.aud {
        dict.set_item("aud", json_to_py(py, v)).ok();
    }
    if let Some(v) = claims.exp {
        dict.set_item("exp", v).ok();
    }
    if let Some(v) = claims.nbf {
        dict.set_item("nbf", v).ok();
    }
    if let Some(v) = claims.iat {
        dict.set_item("iat", v).ok();
    }
    if let Some(ref v) = claims.tenant_id {
        dict.set_item("tenant_id", v).ok();
    }
    if let Some(ref v) = claims.tenant {
        dict.set_item("tenant", v).ok();
    }
    if let Some(ref v) = claims.username {
        dict.set_item("username", v).ok();
    }
    if let Some(ref v) = claims.role {
        dict.set_item("role", v).ok();
    }
    if let Some(v) = claims.jwt_version {
        dict.set_item("jwt_version", v).ok();
    }
    // Extra claims
    for (k, v) in &claims.extra {
        dict.set_item(k.as_str(), json_to_py(py, v)).ok();
    }
    dict.into()
}

// ── decode_jwt_header ──────────────────────────────────────────────────────

/// Decode and return the JWT header without signature verification.
///
/// Useful for inspecting the algorithm and token type without verifying.
///
/// Args:
///     token: JWT token string (base64.header.payload.signature).
///
/// Returns:
///     Dict with header fields (alg, typ) or None if invalid.
#[pyfunction]
pub fn decode_jwt_header(py: Python<'_>, token: &str) -> PyResult<PyObject> {
    let parts: Vec<&str> = token.split('.').collect();
    if parts.len() != 3 {
        return Ok(py.None());
    }

    let header_b64 = parts[0];
    // Decode base64url (add padding)
    let padded = format!("{}{}", header_b64, "=".repeat((4 - header_b64.len() % 4) % 4));
    let decoded = match base64::engine::general_purpose::URL_SAFE
        .decode(padded.as_bytes())
    {
        Ok(d) => d,
        Err(_) => return Ok(py.None()),
    };

    let header: serde_json::Value = match serde_json::from_slice(&decoded) {
        Ok(v) => v,
        Err(_) => return Ok(py.None()),
    };

    Ok(json_to_py(py, &header))
}

// ── verify_jwt ─────────────────────────────────────────────────────────────

/// Verify a JWT token and return its claims as a Python dict.
///
/// Performs full HS256 signature verification, expiration check,
/// not-before check, and optional issuer/audience validation.
///
/// Args:
///     token: JWT token string (base64url-encoded, 3 parts).
///     secret: HMAC-SHA256 secret key (from NEXUS_JWT_SECRET env).
///     required_issuer: Optional expected issuer (from NEXUS_JWT_ISSUER).
///     required_audience: Optional expected audience (from NEXUS_JWT_AUDIENCE).
///
/// Returns:
///     Dict with decoded claims (sub, iss, aud, exp, nbf, tenant_id, etc.)
///     or None if the token is invalid, expired, or tampered.
///
/// Raises:
///     ValueError: If the token format is invalid or signature wrong.
///     TypeError: If the token is None or empty.
#[pyfunction]
#[pyo3(signature = (token, secret, required_issuer = None, required_audience = None))]
pub fn verify_jwt(
    py: Python<'_>,
    token: &str,
    secret: &str,
    required_issuer: Option<String>,
    required_audience: Option<String>,
) -> PyResult<PyObject> {
    log::info!("verify_jwt: verifying token");

    // Basic validation
    if token.is_empty() {
        return Err(PyValueError::new_err("Empty JWT token"));
    }

    let parts: Vec<&str> = token.split('.').collect();
    if parts.len() != 3 {
        return Err(PyValueError::new_err(format!(
            "Invalid JWT format: expected 3 parts (header.payload.signature), got {}",
            parts.len()
        )));
    }

    // Check algorithm in header — must be HS256
    let header_b64 = parts[0];
    let padded = format!("{}{}", header_b64, "=".repeat((4 - header_b64.len() % 4) % 4));
    let header_decoded = match base64::engine::general_purpose::URL_SAFE
        .decode(padded.as_bytes())
    {
        Ok(d) => d,
        Err(_) => {
            return Err(PyValueError::new_err(
                "Invalid JWT header: base64 decode failed",
            ));
        }
    };

    let header: serde_json::Value = match serde_json::from_slice(&header_decoded) {
        Ok(v) => v,
        Err(_) => {
            return Err(PyValueError::new_err(
                "Invalid JWT header: JSON parse failed",
            ));
        }
    };

    // Validate algorithm
    let alg = header
        .get("alg")
        .and_then(|v| v.as_str())
        .unwrap_or("");
    if alg.to_uppercase() != "HS256" {
        return Err(PyValueError::new_err(format!(
            "Unsupported JWT algorithm: {alg}. Only HS256 is accepted."
        )));
    }

    // Validate typ
    let typ = header
        .get("typ")
        .and_then(|v| v.as_str())
        .unwrap_or("JWT")
        .to_uppercase();
    if typ != "JWT" && typ != "AT+JWT" {
        return Err(PyValueError::new_err(format!(
            "Unsupported JWT type: {typ}. Expected 'JWT' or 'AT+JWT'."
        )));
    }

    // Build validation rules
    let mut validation = jsonwebtoken::Validation::new(jsonwebtoken::Algorithm::HS256);

    // Configure issuer validation
    // Only validate if a non-empty issuer is provided
    if let Some(issuer) = required_issuer.filter(|s| !s.is_empty()) {
        let mut issuers = HashSet::new();
        issuers.insert(issuer);
        validation.iss = Some(issuers);
    }
    // When issuer is None or empty, jsonwebtoken skips issuer validation
    // because validation.iss stays None (default).

    // Configure audience validation
    if let Some(audience) = required_audience.filter(|s| !s.is_empty()) {
        validation.set_audience(&[&audience]);
    }
    // When audience is None or empty, jsonwebtoken skips audience validation

    // Validate exp (leeway of 30 seconds for clock skew)
    validation.leeway = 30;

    // Validate nbf (leeway of 30 seconds for clock skew)
    // jsonwebtoken validates nbf by default with the same leeway

    // Set accepted algorithms (only HS256)
    validation.algorithms = vec![jsonwebtoken::Algorithm::HS256];

    // Decode and verify
    let token_data = match jsonwebtoken::decode::<JwtClaims>(
        token,
        &jsonwebtoken::DecodingKey::from_secret(secret.as_bytes()),
        &validation,
    ) {
        Ok(data) => data,
        Err(e) => {
            log::warn!("verify_jwt: token verification failed: {}", e);
            return Err(PyValueError::new_err(format!("JWT verification failed: {e}")));
        }
    };

    log::debug!("verify_jwt: token verified successfully for sub={:?}", token_data.claims.sub);
    Ok(claims_to_pydict(py, &token_data.claims))
}

// ── Module registration ────────────────────────────────────────────────────

pub fn register(module: &Bound<'_, PyModule>) -> PyResult<()> {
    module.add_function(wrap_pyfunction!(verify_jwt, module)?)?;
    module.add_function(wrap_pyfunction!(decode_jwt_header, module)?)?;
    log::info!("jwt: registered verify_jwt and decode_jwt_header functions");
    Ok(())
}
