# pipeline/validators.py
from pyhanko.pdf_utils.reader import PdfFileReader
from pyhanko.sign.validation import validate_pdf_signature
from pyhanko.keys import load_certs_from_pemder

def check_pades_signature(pdf_path: str) -> dict:
    """Weryfikuje, czy plik PDF posiada nienaruszony podpis elektroniczny."""
    try:
        with open(pdf_path, 'rb') as f:
            reader = PdfFileReader(f)

            # Pobieramy ukryte pola podpisów z PDF
            embedded_signatures = reader.embedded_signatures

            if not embedded_signatures:
                return {"is_signed": False, "status": "Brak podpisu"}

            # Walidacja pierwszego znalezionego podpisu
            sig = embedded_signatures[0]
            status = validate_pdf_signature(sig)

            return {
                "is_signed": True,
                "is_intact": status.intact,
                "is_valid": status.valid, # Wymaga sprawdzenia z listą zaufanych certyfikatów
                "signer_name": status.signer_cert.subject.human_friendly if status.signer_cert else "Nieznany"
            }
    except Exception as e:
        return {"is_signed": False, "status": f"Błąd weryfikacji: {str(e)}"}
