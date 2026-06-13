// ═══════════════════════════════════════════════════════════════════════════════
// KSeF — Generator XML FA_VAT (Rust + quick-xml)
// ═══════════════════════════════════════════════════════════════════════════════
//
// Structured logging: log::info!, log::debug!, log::warn!
// All logs are forwarded to Python structlog via pyo3-log (init in lib.rs)
// ═══════════════════════════════════════════════════════════════════════════════
//
// Zastępuje xml.etree.ElementTree w services/ksef_generator.py
// używając quick-xlm dla wydajności i bezpieczeństwa typów.
//
// Obsługuje:
//   - Generowanie pełnego XML FA_VAT zgodnego ze schematem KSeF
//   - ksef_fields z werdyktu (gtu_code, procedure_code, transaction_mark, split_payment)
//   - category_gtu_map — mapowanie kategorii na domyślne kody GTU
//   - Konwersja groszy na złotówki (string z 2 miejscami po przecinku)
// ═══════════════════════════════════════════════════════════════════════════════

use pyo3::exceptions::PyValueError;
use pyo3::prelude::*;
use pyo3::types::*;
use quick_xml::events::{BytesDecl, BytesEnd, BytesStart, BytesText, Event};
use quick_xml::Writer;
use std::io::Write;

// ── Category → GTU map ───────────────────────────────────────────────────────

const CATEGORY_GTU: &[(&str, &str)] = &[
    ("FUEL", "GTU_12"),
    ("IT_OFFICE", "GTU_01"),
    ("FOOD", "GTU_07"),
    ("BOOKS", "GTU_01"),
    ("TRANSPORT", "GTU_02"),
    ("ADVERTISING", "GTU_06"),
    ("RENT", "GTU_09"),
    ("CONSTRUCTION", "GTU_08"),
    ("ELECTRONICS", "GTU_10"),
    ("PHARMA", "GTU_03"),
    ("WASTE", "GTU_04"),
    ("METAL", "GTU_05"),
    ("GAMBLING", "GTU_13"),
];

// ── Helpers ──────────────────────────────────────────────────────────────────

/// Get string value from dict, returning empty string if missing.
fn dict_str(d: &Bound<'_, PyDict>, key: &str) -> String {
    d.get_item(key)
        .ok()  // PyResult<Option<...>> -> Option<Option<...>>
        .and_then(|v| v)  // flatten: Option<Bound<...>>
        .and_then(|v| v.extract::<String>().ok())
        .unwrap_or_default()
}

/// Get i64 from dict, returning 0 if missing.
fn dict_int(d: &Bound<'_, PyDict>, key: &str) -> i64 {
    d.get_item(key)
        .ok()  // PyResult<Option<...>> -> Option<Option<...>>
        .and_then(|v| v)  // flatten: Option<Bound<...>>
        .and_then(|v| v.extract::<i64>().ok())
        .unwrap_or(0)
}

/// Get bool from dict (accepts "1", "true", True).
///
/// PyO3 0.22: Bound::get_item() returns PyResult<Option<Bound<'_, PyAny>>>.
fn dict_bool(d: &Bound<'_, PyDict>, key: &str) -> bool {
    match d.get_item(key) {
        Ok(Some(v)) => {
            if let Ok(b) = v.extract::<bool>() {
                b
            } else if let Ok(s) = v.extract::<String>() {
                s == "1" || s.to_lowercase() == "true"
            } else {
                false
            }
        }
        _ => false,
    }
}

/// Get nested dict from a key.
fn dict_subdict<'a>(d: &'a Bound<'_, PyDict>, key: &str) -> Option<Bound<'a, PyDict>> {
    d.get_item(key)
        .ok()  // PyResult<Option<...>> -> Option<Option<...>>
        .and_then(|v| v)  // flatten: Option<Bound<...>>
        .and_then(|v| v.downcast::<PyDict>().ok().map(|d| d.to_owned()))
}

/// Convert grosze to złotówki string (e.g. 12345 → "123.45").
fn grosze_to_pln(grosze: i64) -> String {
    let sign = if grosze < 0 { "-" } else { "" };
    let abs = grosze.unsigned_abs();
    let zl = abs / 100;
    let gr = abs % 100;
    format!("{}{}.{:02}", sign, zl, gr)
}

/// Format current UTC time as YYYY-MM-DDTHH:mm:ss.
fn utc_now_iso() -> String {
    // Utc::now() requires chrono "clock" feature
    // (Cargo.toml: default-features=false, features=["std", "clock"])
    chrono::Utc::now().format("%Y-%m-%dT%H:%M:%S").to_string()
}

// ── Low-level XML helpers (avoid fluent builder lifetime issues) ─────────────

/// Write <tag>text</tag> using low-level Event API.
fn write_simple_element<W: Write>(writer: &mut Writer<W>, tag: &str, text: &str) -> Result<(), quick_xml::Error> {
    writer.write_event(Event::Start(BytesStart::new(tag)))?;
    writer.write_event(Event::Text(BytesText::new(text.as_ref())))?;
    writer.write_event(Event::End(BytesEnd::new(tag)))?;
    Ok(())
}

/// Write <parent>...nested...</parent> via closure.
fn write_nested_element<W: Write>(
    writer: &mut Writer<W>,
    tag: &str,
    inner: impl Fn(&mut Writer<W>) -> Result<(), quick_xml::Error>,
) -> Result<(), quick_xml::Error> {
    writer.write_event(Event::Start(BytesStart::new(tag)))?;
    inner(writer)?;
    writer.write_event(Event::End(BytesEnd::new(tag)))?;
    Ok(())
}

// ── KSeF field resolution ────────────────────────────────────────────────────

struct KsefFields {
    gtu_code: String,
    procedure_code: String,
    transaction_mark: String,
    split_payment: bool,
}

/// Resolve KSeF fields from verdict dict.
///
/// Priority:
///   1. verdict["ksef_fields"] — explicit dict
///   2. verdict["gtu_code"] + verdict["procedure"] — legacy
///   3. CATEGORY_GTU lookup by category_code
fn resolve_ksef_fields(verdict: &Bound<'_, PyDict>) -> KsefFields {
    let mut gtu_code = String::new();
    let mut procedure_code = String::new();
    let mut transaction_mark = String::new();
    let mut split_payment = false;

    if let Some(ksef) = dict_subdict(verdict, "ksef_fields") {
        let gtu = dict_str(&ksef, "gtu_code");
        if !gtu.is_empty() {
            gtu_code = gtu;
        }
        let proc = dict_str(&ksef, "procedure_code");
        if !proc.is_empty() {
            procedure_code = proc;
        }
        let tm = dict_str(&ksef, "transaction_mark");
        if !tm.is_empty() {
            transaction_mark = tm;
        }
        split_payment = dict_bool(&ksef, "split_payment");
    }

    if gtu_code.is_empty() {
        gtu_code = dict_str(verdict, "gtu_code");
    }
    if procedure_code.is_empty() {
        procedure_code = dict_str(verdict, "procedure");
    }
    if transaction_mark.is_empty() {
        transaction_mark = dict_str(verdict, "transaction_mark");
    }
    if !split_payment {
        split_payment = dict_bool(verdict, "split_payment");
    }

    if !gtu_code.starts_with("GTU_") && !gtu_code.is_empty() {
        if let Some(found) = CATEGORY_GTU.iter().find(|(cat, _)| *cat == gtu_code) {
            gtu_code = found.1.to_string();
        }
    } else if gtu_code.is_empty() {
        let category = dict_str(verdict, "category_code");
        let cat = if category.is_empty() {
            dict_str(verdict, "_category_code")
        } else {
            category
        };
        if let Some(found) = CATEGORY_GTU.iter().find(|(c, _)| *c == cat) {
            gtu_code = found.1.to_string();
        }
    }

    KsefFields {
        gtu_code,
        procedure_code,
        transaction_mark,
        split_payment,
    }
}

// ── XML building ─────────────────────────────────────────────────────────────

/// Write entity data (vendor/buyer) inside <Osoba>.
fn write_entity<W: Write>(writer: &mut Writer<W>, entity_data: &Option<Bound<'_, PyDict>>) -> Result<(), quick_xml::Error> {
    write_nested_element(writer, "Osoba", |w| {
        let entity = match entity_data {
            Some(ref e) => e,
            None => return Ok(()),
        };
        let nip = dict_str(entity, "nip");
        if !nip.is_empty() {
            write_simple_element(w, "NIP", &nip)?;
        }
        let name = dict_str(entity, "name");
        if !name.is_empty() {
            write_simple_element(w, "Nazwa", &name)?;
        }
        let street = dict_str(entity, "street");
        if !street.is_empty() {
            write_simple_element(w, "Ulica", &street)?;
        }
        let city = dict_str(entity, "city");
        if !city.is_empty() {
            write_simple_element(w, "Miejscowosc", &city)?;
        }
        let zip = dict_str(entity, "zip");
        if !zip.is_empty() {
            write_simple_element(w, "KodPocztowy", &zip)?;
        }
        Ok(())
    })?;
    Ok(())
}

/// Write a single invoice position inside <Pozycja>.
fn write_position<W: Write>(writer: &mut Writer<W>, idx: usize, pos: &Bound<'_, PyDict>) -> Result<(), quick_xml::Error> {
    write_nested_element(writer, "Pozycja", |w| {
        let nr = (idx + 1).to_string();
        write_simple_element(w, "NrWiersza", &nr)?;

        let desc = dict_str(pos, "description");
        if !desc.is_empty() {
            write_simple_element(w, "Nazwa", &desc)?;
        }

        let pos_net = dict_int(pos, "net_amount_grosze");
        let net_val = if pos_net > 0 {
            pos_net
        } else {
            dict_int(pos, "net_amount")
        };
        let cena = grosze_to_pln(net_val);
        write_simple_element(w, "CenaNetto", &cena)?;

        let pos_vat = dict_int(pos, "vat_amount_grosze");
        let vat_val = if pos_vat > 0 {
            pos_vat
        } else {
            dict_int(pos, "vat_amount")
        };
        if vat_val > 0 {
            let kwota = grosze_to_pln(vat_val);
            write_simple_element(w, "KwotaVat", &kwota)?;
        }
        Ok(())
    })?;
    Ok(())
}

// ── Main function ────────────────────────────────────────────────────────────

/// Generate KSeF FA_VAT XML for an invoice.
///
/// Args:
///     invoice_data: dict with invoice_id, number, transaction_date,
///                   amount_net_grosze, amount_vat_grosze, vendor, buyer,
///                   positions, currency, sale_date.
///     verdict: dict with vat_rate, gtu_code, ksef_fields, category_code,
///              procedure, transaction_mark, split_payment.
///
/// Returns:
///     XML string (UTF-8, with declaration).
///
/// Raises:
///     ValueError: If input data is invalid.
#[pyfunction]
#[pyo3(signature = (invoice_data, verdict))]
fn generate_ksef_xml(
    invoice_data: &Bound<'_, PyDict>,
    verdict: &Bound<'_, PyDict>,
) -> PyResult<String> {
    let invoice_id = dict_str(invoice_data, "invoice_id");
    let invoice_number = {
        let n = dict_str(invoice_data, "number");
        if n.is_empty() { invoice_id.clone() } else { n }
    };
    let issue_date = {
        let d = dict_str(invoice_data, "transaction_date");
        if d.is_empty() { "2025-01-01".to_string() } else { d }
    };
    let sale_date = {
        let d = dict_str(invoice_data, "sale_date");
        if d.is_empty() { issue_date.clone() } else { d }
    };
    let currency = {
        let c = dict_str(invoice_data, "currency");
        if c.is_empty() { "PLN".to_string() } else { c }
    };

    let net_grosze = dict_int(invoice_data, "amount_net_grosze");
    let vat_grosze = dict_int(invoice_data, "amount_vat_grosze");
    let brutto_grosze = net_grosze + vat_grosze;

    let net_pln = grosze_to_pln(net_grosze);
    let vat_pln = grosze_to_pln(vat_grosze);
    let brutto_pln = grosze_to_pln(brutto_grosze);

    let vendor = dict_subdict(invoice_data, "vendor");
    let buyer = dict_subdict(invoice_data, "buyer");
    let ksef = resolve_ksef_fields(verdict);

    // Get positions list
    let positions: Vec<Bound<'_, PyDict>> = invoice_data
        .get_item("positions")
        .ok()
        .flatten()
        .and_then(|v| v.downcast::<PyList>().ok().map(|list| {
            list.iter()
                .filter_map(|item| item.downcast::<PyDict>().ok().map(|d| d.to_owned()))
                .collect()
        }))
        .unwrap_or_default();

    // Build XML using low-level Event API
    let mut buffer = Vec::new();
    let mut writer = Writer::new_with_indent(&mut buffer, b' ', 2);

    // XML declaration
    writer
        .write_event(Event::Decl(BytesDecl::new("1.0", Some("UTF-8"), None)))
        .map_err(|e| PyValueError::new_err(format!("XML write error: {e}")))?;

    // Root: Faktura with xmlns
    let mut faktura_start = BytesStart::new("Faktura");
    faktura_start.push_attribute(("xmlns", "http://ksef.mf.gov.pl/schema/gtw/faktura/2023/03/31"));
    writer
        .write_event(Event::Start(faktura_start))
        .map_err(|e| PyValueError::new_err(format!("XML write error: {e}")))?;

    // Naglowek
    write_nested_element(&mut writer, "Naglowek", |w| {
        write_simple_element(w, "KodFormularza", "FA_VAT")?;
        write_simple_element(w, "WariantFormularza", "4")?;
        write_simple_element(w, "SystemInfo", "NexusAI v1.0")?;
        write_simple_element(w, "CelZlozenia", "1")?;
        let now_str = utc_now_iso();
        write_simple_element(w, "DataWytworzenia", &now_str)?;
        Ok(())
    })
    .map_err(|e| PyValueError::new_err(format!("XML write error: {e}")))?;

    // Podmiot1 (Sprzedawca)
    write_nested_element(&mut writer, "Podmiot1", |w| {
        write_entity(w, &vendor)
    })
    .map_err(|e| PyValueError::new_err(format!("XML write error: {e}")))?;

    // Podmiot2 (Nabywca)
    write_nested_element(&mut writer, "Podmiot2", |w| {
        write_entity(w, &buyer)
    })
    .map_err(|e| PyValueError::new_err(format!("XML write error: {e}")))?;

    // Fa (Szczegóły faktury)
    write_nested_element(&mut writer, "Fa", |w| {
        write_simple_element(w, "P_1", &invoice_number)?;
        write_simple_element(w, "P_2", &issue_date)?;
        write_simple_element(w, "P_3", &sale_date)?;
        write_simple_element(w, "P_4", &currency)?;
        write_simple_element(w, "P_13_1", &net_pln)?;
        write_simple_element(w, "P_14_1", &vat_pln)?;
        write_simple_element(w, "P_15", &brutto_pln)?;

        // GTU
        if !ksef.gtu_code.is_empty() {
            write_nested_element(w, "Gtu", |w| {
                write_simple_element(w, &ksef.gtu_code, "1")?;
                Ok(())
            })?;
        }

        // Transaction mark (TP, SW)
        if ksef.transaction_mark == "TP" || ksef.transaction_mark == "SW" {
            write_nested_element(w, "Oznaczenia", |w| {
                write_simple_element(w, &ksef.transaction_mark, "1")?;
                Ok(())
            })?;
        }

        // Procedure
        if !ksef.procedure_code.is_empty() {
            write_nested_element(w, "Procedura", |w| {
                write_simple_element(w, "RodzajProcedury", &ksef.procedure_code)?;
                Ok(())
            })?;
        }

        // Split payment
        if ksef.split_payment {
            write_simple_element(w, "SplitPayment", "1")?;
        }

        // Positions
        if !positions.is_empty() {
            let liczba = positions.len().to_string();
            write_simple_element(w, "LiczbaPozycji", &liczba)?;
            for (i, pos) in positions.iter().enumerate() {
                write_position(w, i, pos)?;
            }
        }

        Ok(())
    })
    .map_err(|e| PyValueError::new_err(format!("XML generation error: {e}")))?;

    // Close Faktura root
    writer
        .write_event(Event::End(BytesEnd::new("Faktura")))
        .map_err(|e| PyValueError::new_err(format!("XML write error: {e}")))?;

    let xml_str = String::from_utf8(buffer)
        .map_err(|e| PyValueError::new_err(format!("UTF-8 encoding error: {e}")))?;

    log::info!("generate_ksef_xml: generated {} bytes for invoice {}", xml_str.len(), invoice_number);
    Ok(xml_str)
}

// ── PyO3 registration ────────────────────────────────────────────────────────

pub fn register(m: &Bound<'_, PyModule>) -> PyResult<()> {
    m.add_function(wrap_pyfunction!(generate_ksef_xml, m)?)?;
    log::info!("nexus_crypto: registered KSeF XML generator");
    Ok(())
}
