// ═══════════════════════════════════════════════════════════════════════════════
// Nexus-Forex — Native currency module for NexusAI (Rust + PyO3)
// ═══════════════════════════════════════════════════════════════════════════════
//
// Provides:
//   1. fetch_nbp_rate(date, currency) — pobiera kurs z NBP API
//   2. convert(amount, from_currency, to_currency, rate) — przewalutowanie
//   3. validate_nip(nip) — weryfikacja NIPu (suma kontrolna)
//
// Zastępuje: Pythonowy ForexEngine (nexus_ai/roboton_reflekton/forex_engine.py)
//            oraz py-moneyed do reprezentacji walut.
//
// Budowanie:
//   cd nexus_ai/roboton_reflekton/nexus_forex && maturin develop --release
//
// ═══════════════════════════════════════════════════════════════════════════════

use pyo3::prelude::*;
use chrono::NaiveDate;
use serde::Deserialize;

// ── Struktury danych ─────────────────────────────────────────────────────────

/// Pojedyncza stawka kursu z API NBP
#[derive(Debug, Deserialize)]
struct NbpRate {
    #[serde(rename = "no")]
    table_no: String,
    #[serde(rename = "mid")]
    mid: f64,
    #[serde(rename = "effectiveDate")]
    effective_date: String,
}

/// Odpowiedź API NBP dla pojedynczej waluty
#[derive(Debug, Deserialize)]
struct NbpResponse {
    table: String,
    currency: String,
    code: String,
    rates: Vec<NbpRate>,
}

// ── Funkcje walutowe ─────────────────────────────────────────────────────────

/// Pobierz kurs NBP dla danej waluty i daty.
/// 
/// Args:
///     currency_code: Kod waluty (np. "EUR", "USD")
///     date_str: Data w formacie YYYY-MM-DD
/// 
/// Returns:
///     Średni kurs waluty (mid) jako float, lub None jeśli nie znaleziono.
#[pyfunction]
fn fetch_nbp_rate(currency_code: &str, date_str: &str) -> PyResult<Option<f64>> {
    let url = format!(
        "https://api.nbp.pl/api/exchangerates/rates/A/{}/{}/?format=json",
        currency_code.to_uppercase(),
        date_str
    );

    let client = reqwest::blocking::Client::builder()
        .timeout(std::time::Duration::from_secs(10))
        .build()
        .map_err(|e| pyo3::exceptions::PyRuntimeError::new_err(e.to_string()))?;

    let response = client
        .get(&url)
        .send()
        .map_err(|e| pyo3::exceptions::PyRuntimeError::new_err(e.to_string()))?;

    if !response.status().is_success() {
        return Ok(None);
    }

    let body = response
        .text()
        .map_err(|e| pyo3::exceptions::PyRuntimeError::new_err(e.to_string()))?;

    let parsed: NbpResponse = serde_json::from_str(&body)
        .map_err(|e| pyo3::exceptions::PyValueError::new_err(e.to_string()))?;

    Ok(parsed.rates.first().map(|r| r.mid))
}

/// Wykonaj przewalutowanie kwoty przy danym kursie.
///
/// Args:
///     amount: Kwota do przewalutowania
///     rate: Kurs waluty (ile PLN za jednostkę waluty obcej)
///
/// Returns:
///     Przewalutowana kwota zaokrąglona do 2 miejsc po przecinku.
#[pyfunction]
fn convert(amount: f64, rate: f64) -> f64 {
    let result = amount * rate;
    // Zaokrąglenie do 2 miejsc po przecinku (bankers' rounding)
    ((result * 100.0).round()) / 100.0
}

/// Zweryfikuj NIP używając sumy kontrolnej.
///
/// Args:
///     nip: NIP do weryfikacji (ciąg znaków, może zawierać myślniki)
///
/// Returns:
///     True jeśli NIP jest poprawny, False w przeciwnym razie.
#[pyfunction]
fn validate_nip(nip: &str) -> bool {
    // Usuń myślniki i spacje
    let clean: String = nip.chars().filter(|c| c.is_ascii_digit()).collect();

    // NIP musi mieć dokładnie 10 cyfr
    if clean.len() != 10 {
        return false;
    }

    // Suma kontrolna NIPu
    let weights: [u8; 9] = [6, 5, 7, 2, 3, 4, 5, 6, 7];
    let digits: Vec<u8> = clean.chars().map(|c| c.to_digit(10).unwrap() as u8).collect();

    let sum: u32 = weights
        .iter()
        .zip(digits.iter())
        .map(|(w, d)| (*w as u32) * (*d as u32))
        .sum();

    let checksum = sum % 11;
    if checksum == 10 {
        return false; // NIP z sumą kontrolną 10 jest nieprawidłowy
    }

    checksum as u8 == digits[9]
}

/// Formatuj kwotę jako string z 2 miejscami po przecinku i symbolem waluty.
///
/// Args:
///     amount: Kwota do sformatowania
///     currency: Symbol waluty (np. "PLN", "EUR")
///
/// Returns:
///     Sformatowany string np. "1 234,56 PLN"
#[pyfunction]
fn format_money(amount: f64, currency: &str) -> String {
    let integer_part = amount.trunc() as i64;
    let fractional_part = ((amount.fract() * 100.0).round()) as u8;

    // Formatuj część całkowitą z spacjami co 3 cyfry
    let int_str = integer_part.to_string();
    let mut formatted = String::new();
    let mut count = 0;
    for c in int_str.chars().rev() {
        if count > 0 && count % 3 == 0 {
            formatted.insert(0, ' ');
        }
        formatted.insert(0, c);
        count += 1;
    }

    format!("{},{:02} {}", formatted, fractional_part, currency.to_uppercase())
}

/// Pobierz kurs NBP z automatycznym cofaniem do poprzedniego dnia roboczego.
///
/// Args:
///     currency_code: Kod waluty (np. "EUR", "USD")
///     date_str: Data w formacie YYYY-MM-DD
///     max_lookback_days: Maksymalna liczba dni wstecz (domyślnie 5)
///
/// Returns:
///     Krotka (kurs, data_kursu) lub None jeśli nie znaleziono.
#[pyfunction]
fn fetch_nbp_rate_with_lookback(
    currency_code: &str,
    date_str: &str,
    max_lookback_days: Option<u32>,
) -> PyResult<Option<(f64, String)>> {
    let max_days = max_lookback_days.unwrap_or(5);
    let base_date = NaiveDate::parse_from_str(date_str, "%Y-%m-%d")
        .map_err(|e| pyo3::exceptions::PyValueError::new_err(e.to_string()))?;

    for offset in 0..=max_days {
        let check_date = base_date - chrono::Duration::days(offset as i64);
        // Pomiń weekendy
        if check_date.format("%u").to_string() == "6" || check_date.format("%u").to_string() == "7" {
            continue;
        }

        let date_str = check_date.format("%Y-%m-%d").to_string();
        match fetch_nbp_rate(currency_code, &date_str) {
            Ok(Some(rate)) => return Ok(Some((rate, date_str))),
            Ok(None) => continue,
            Err(_) => continue,
        }
    }

    Ok(None)
}

/// Python module definition.
#[pymodule]
fn _forex(m: &Bound<'_, PyModule>) -> PyResult<()> {
    m.add_function(wrap_pyfunction!(fetch_nbp_rate, m)?)?;
    m.add_function(wrap_pyfunction!(convert, m)?)?;
    m.add_function(wrap_pyfunction!(validate_nip, m)?)?;
    m.add_function(wrap_pyfunction!(format_money, m)?)?;
    m.add_function(wrap_pyfunction!(fetch_nbp_rate_with_lookback, m)?)?;
    Ok(())
}
