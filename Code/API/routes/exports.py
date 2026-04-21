import io
import csv
from litestar import Controller, get
from litestar.response import Stream
from db.analytics import DuckDBManager

class ExportController(Controller):
    path = "/api/v1/exports"

    @get("/csv")
    async def export_invoices_csv(self, duckdb: DuckDBManager) -> Stream:
        """Strumieniuje dane z DuckDB bezpośrednio do pliku CSV."""
        def iter_csv():
            # Pobieramy dane partiami (chunks) dla wydajności
            buffer = io.StringIO()
            writer = csv.writer(buffer)

            # Nagłówki
            writer.writerow(["ID", "Numer", "NIP", "Netto", "Brutto", "Waluta", "Data"])
            yield buffer.getvalue()
            buffer.seek(0)
            buffer.truncate(0)

            # Pobranie danych z DuckDB
            data = duckdb.execute("SELECT * FROM invoices_replica")

            for row in data:
                writer.writerow(row.values())
                yield buffer.getvalue()
                buffer.seek(0)
                buffer.truncate(0)

        return Stream(iter_csv(), media_type="text/csv")
