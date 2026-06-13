// ═══════════════════════════════════════════════════════════════════════════════
// JWT — HS256 / RS256 / ES256 verification + claims validation (jsonwebtoken + PyO3)
// ═══════════════════════════════════════════════════════════════════════════════
//
// Structured logging: log::info!, log::debug!, log::warn!
// All logs are forwarded to Python structlog via pyo3-log (init in lib.rs)
// ═══════════════════════════════════════════════════════════════════════════════
//
// Zastępuje: nexus_ai/api/middleware.py → _tenant_from_bearer_auth()
// Nowy:     Rust + jsonwebtoken crate — 10-50× szybsza weryfikacja JWT
//
// Funkcje eksportowane do Pythona:
//   verify_jwt(token, key, required_issuer, required_audience) → dict | None
//   decode_jwt_header(token) → dict | None
//
// Obsługiwane algorytmy:
//   - HS256 (HMAC-SHA256)        — symetryczny, klucz jako secret string
//   - RS256 (RSA PKCS1v1.5)      — asymetryczny, klucz jako PEM public key
//   - ES256 (ECDSA P-256)         — asymetryczny, klucz jako PEM public key
//
// Auto-detection: algorytm jest odczytywany z nagłówka JWT.
// Jeśli klucz wygląda jak PEM (zawiera "-----BEGIN"), traktujemy go jako
// klucz publiczny dla RS256/ES256. W przeciwnym razie jako HMAC secret.
//
// Wspólne dla wszystkich algorytmów:
//   - Weryfikacja exp, nbf, iss, aud
//   - Ekstrakcja tenant_id z claims
//   - Akceptacja typ "JWT" i "AT+JWT"
// ═══════════════════════════════════════════════════════════════════════════════

use base64::Engine as _;
use pyo3::exceptions::PyValueError;
use pyo3::prelude::*;
use pyo3::types::PyDict;
use serde::{Deserialize, Serialize};
use std::collections::HashSet;

// ── Supported algorithms ───────────────────────────────────────────────────

/// Supported JWT algorithms.
#[derive(Debug, Clone, PartialEq)]
enum JwtAlgorithm {
    Hs256,
    Rs256,
    Es256,
}

impl JwtAlgorithm {
    /// Parse algorithm from a JWT header `alg` field.
    fn from_str(s: &str) -> Option<Self> {
        match s.to_uppercase().as_str() {
            "HS256" => Some(JwtAlgorithm::Hs256),
            "RS256" => Some(JwtAlgorithm::Rs256),
            "ES256" => Some(JwtAlgorithm::Es256),
            _ => None,
        }
    }

    /// Convert to jsonwebtoken Algorithm for validation.
    fn to_jwt_alg(&self) -> jsonwebtoken::Algorithm {
        match self {
            JwtAlgorithm::Hs256 => jsonwebtoken::Algorithm::HS256,
            JwtAlgorithm::Rs256 => jsonwebtoken::Algorithm::RS256,
            JwtAlgorithm::Es256 => jsonwebtoken::Algorithm::ES256,
        }
    }

    /// Human-readable name.
    fn as_str(&self) -> &'static str {
        match self {
            JwtAlgorithm::Hs256 => "HS256",
            JwtAlgorithm::Rs256 => "RS256",
            JwtAlgorithm::Es256 => "ES256",
        }
    }
}

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

// ── JWT header parsing ─────────────────────────────────────────────────────

/// Decode and parse JWT header to extract algorithm and type.
///
/// Returns (header_json, algorithm) or an error.
fn parse_jwt_header(token: &str) -> PyResult<(serde_json::Value, JwtAlgorithm)> {
    let parts: Vec<&str> = token.split('.').collect();
    if parts.len() != 3 {
        return Err(PyValueError::new_err(format!(
            "Invalid JWT format: expected 3 parts (header.payload.signature), got {}",
            parts.len()
        )));
    }

    let header_b64 = parts[0];
    let padded = format!("{}{}", header_b64, "=".repeat((4 - header_b64.len() % 4) % 4));
    let header_decoded = base64::engine::general_purpose::URL_SAFE
        .decode(padded.as_bytes())
        .map_err(|_| PyValueError::new_err("Invalid JWT header: base64 decode failed"))?;

    let header: serde_json::Value = serde_json::from_slice(&header_decoded)
        .map_err(|_| PyValueError::new_err("Invalid JWT header: JSON parse failed"))?;

    // Extract algorithm
    let alg_str = header
        .get("alg")
        .and_then(|v| v.as_str())
        .unwrap_or("");
    let alg = JwtAlgorithm::from_str(alg_str).ok_or_else(|| {
        PyValueError::new_err(format!(
            "Unsupported or missing JWT algorithm: {alg_str:?}. \
             Supported algorithms: HS256, RS256, ES256"
        ))
    })?;

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

    Ok((header, alg))
}

// ── DecodingKey builder ────────────────────────────────────────────────────

/// Build a DecodingKey from the key string based on the algorithm.
///
/// For HS256: key is a plain secret string.
/// For RS256/ES256: key is a PEM-encoded public key string.
fn build_decoding_key(alg: &JwtAlgorithm, key: &str) -> PyResult<jsonwebtoken::DecodingKey> {
    match alg {
        JwtAlgorithm::Hs256 => {
            Ok(jsonwebtoken::DecodingKey::from_secret(key.as_bytes()))
        }
        JwtAlgorithm::Rs256 => {
            jsonwebtoken::DecodingKey::from_rsa_pem(key.as_bytes())
                .map_err(|e| PyValueError::new_err(format!(
                    "Invalid RSA public key PEM for RS256: {e}. \
                     Expected PEM format starting with '-----BEGIN PUBLIC KEY-----' \
                     or '-----BEGIN RSA PUBLIC KEY-----'."
                )))
        }
        JwtAlgorithm::Es256 => {
            jsonwebtoken::DecodingKey::from_ec_pem(key.as_bytes())
                .map_err(|e| PyValueError::new_err(format!(
                    "Invalid EC public key PEM for ES256: {e}. \
                     Expected PEM format starting with '-----BEGIN PUBLIC KEY-----' \
                     with an EC key (P-256 curve)."
                )))
        }
    }
}

// ── Validation builder ─────────────────────────────────────────────────────

/// Build a Validation struct with common settings for all algorithms.
fn build_validation(
    alg: &JwtAlgorithm,
    required_issuer: Option<String>,
    required_audience: Option<String>,
) -> jsonwebtoken::Validation {
    let mut validation = jsonwebtoken::Validation::new(alg.to_jwt_alg());

    // Configure issuer validation
    if let Some(issuer) = required_issuer.filter(|s| !s.is_empty()) {
        let mut issuers = HashSet::new();
        issuers.insert(issuer);
        validation.iss = Some(issuers);
    }

    // Configure audience validation
    if let Some(audience) = required_audience.filter(|s| !s.is_empty()) {
        validation.set_audience(&[&audience]);
    }

    // Validate exp (leeway of 30 seconds for clock skew)
    validation.leeway = 30;

    // Set accepted algorithms (only the detected one for security)
    validation.algorithms = vec![alg.to_jwt_alg()];

    validation
}

// ═══════════════════════════════════════════════════════════════════════════════
// decode_jwt_header
// ═══════════════════════════════════════════════════════════════════════════════

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
    match parse_jwt_header(token) {
        Ok((header, _alg)) => Ok(json_to_py(py, &header)),
        Err(_) => Ok(py.None()),
    }
}

// ═══════════════════════════════════════════════════════════════════════════════
// verify_jwt
// ═══════════════════════════════════════════════════════════════════════════════

/// Verify a JWT token and return its claims as a Python dict.
///
/// Automatically detects the algorithm from the JWT header and uses the
/// appropriate verification method:
///   - HS256: symmetric HMAC-SHA256, key is a plain secret string
///   - RS256: RSA PKCS1v1.5 SHA256, key is a PEM-encoded RSA public key
///   - ES256: ECDSA P-256 SHA256, key is a PEM-encoded EC public key
///
/// Args:
///     token: JWT token string (base64url-encoded, 3 parts).
///     key: Verification key:
///         - For HS256: HMAC secret string (e.g. from NEXUS_JWT_SECRET).
///         - For RS256/ES256: PEM-encoded public key string (e.g. from
///           NEXUS_JWT_PUBLIC_KEY). Must start with "-----BEGIN".
///     required_issuer: Optional expected issuer (from NEXUS_JWT_ISSUER).
///     required_audience: Optional expected audience (from NEXUS_JWT_AUDIENCE).
///
/// Returns:
///     Dict with decoded claims (sub, iss, aud, exp, nbf, tenant_id, etc.)
///     or None if the token is invalid, expired, or tampered.
///
/// Raises:
///     ValueError: If the token format is invalid, signature verification fails,
///         or the algorithm is unsupported.
#[pyfunction]
#[pyo3(signature = (token, key, required_issuer = None, required_audience = None))]
pub fn verify_jwt(
    py: Python<'_>,
    token: &str,
    key: &str,
    required_issuer: Option<String>,
    required_audience: Option<String>,
) -> PyResult<PyObject> {
    log::info!("verify_jwt: verifying token ({} chars)", token.len());

    // Basic validation
    if token.is_empty() {
        return Err(PyValueError::new_err("Empty JWT token"));
    }

    // Parse header and detect algorithm
    let (_header, alg) = parse_jwt_header(token)?;
    log::debug!("verify_jwt: detected algorithm = {}", alg.as_str());

    // Build the appropriate DecodingKey based on algorithm
    let decoding_key = build_decoding_key(&alg, key)?;

    // Build validation rules
    let validation = build_validation(&alg, required_issuer, required_audience);

    // Decode and verify
    let token_data = match jsonwebtoken::decode::<JwtClaims>(
        token,
        &decoding_key,
        &validation,
    ) {
        Ok(data) => data,
        Err(e) => {
            log::warn!("verify_jwt: {} verification failed: {}", alg.as_str(), e);
            return Err(PyValueError::new_err(format!(
                "JWT {} verification failed: {e}",
                alg.as_str()
            )));
        }
    };

    log::debug!(
        "verify_jwt: {} token verified successfully for sub={:?}",
        alg.as_str(),
        token_data.claims.sub
    );
    Ok(claims_to_pydict(py, &token_data.claims))
}

// ═══════════════════════════════════════════════════════════════════════════════
// Module registration
// ═══════════════════════════════════════════════════════════════════════════════

pub fn register(module: &Bound<'_, PyModule>) -> PyResult<()> {
    module.add_function(wrap_pyfunction!(verify_jwt, module)?)?;
    module.add_function(wrap_pyfunction!(decode_jwt_header, module)?)?;
    log::info!(
        "jwt: registered verify_jwt (HS256/RS256/ES256) and decode_jwt_header functions"
    );
    Ok(())
}
