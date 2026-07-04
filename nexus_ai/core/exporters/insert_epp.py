# core/exporters/insert_epp.py
import pendulum


class InsertEppExporter:
    __slots__ = ('invoices',)
    def __init__(self, invoices: list):
        self.invoices = invoices

    def generate(self) -> str:
        header = f'[INFO]\n"1.30",1250,"Nexus OCR","{pendulum.now().format("YYYYMMDDHHmmss")}"\n\n'
        content = "[ZAWARTOSC]\n"

        for inv in self.invoices:
            # Uproszczony wiersz faktury zakupu w formacie EPP
            line = (
                f'"FS",1,0,"{inv.number}",,,,'
                f'"{inv.contractor_name}","{inv.contractor_nip}",,'
                f"{inv.date_sale},{inv.date_issue},{inv.date_due},"
                f'{inv.amount_net},{inv.amount_gross},"PLN",1.0000\n'
            )
            content += line

        return header + content
