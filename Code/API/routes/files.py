from litestar import get
from litestar.response import Stream
from pathlib import Path

def file_chunk_generator(file_path: Path, chunk_size: int = 65536):
    """Generator wysyłający plik w małych paczkach (64KB)."""
    with open(file_path, "rb") as f:
        while chunk := f.read(chunk_size):
            yield chunk

@get("/api/invoices/{invoice_id}/pdf")
async def stream_pdf(invoice_id: str) -> Stream:
    pdf_path = Path(f"app_data/documents/{invoice_id}.pdf")
    return Stream(
        file_chunk_generator(pdf_path),
        media_type="application/pdf",
        headers={"Content-Disposition": f"inline; filename={invoice_id}.pdf"}
    )
