# core/integrations/mail.py
import email
import imaplib
from pathlib import Path

from nexus_ai.core.logger import logger

# from core.tasks import process_invoice_task # Importowane z zadań


class MailIngestionService:
    def __init__(self, config):
        self.config = config
        self.download_path = Path(config.base_dir) / "app_data" / "mailbox_ingest"
        self.download_path.mkdir(parents=True, exist_ok=True)

    async def check_and_process(self):
        """Pobiera nowe maile i wysyła zadania do Workera przez NATS."""
        try:
            # Połączenie IMAP (uproszczone)
            mail = imaplib.IMAP4_SSL(self.config.mail_host)
            mail.login(self.config.mail_user, self.config.mail_pass)
            mail.select("inbox")

            # Szukamy nieprzeczytanych wiadomości
            _, messages = mail.search(None, "UNSEEN")

            for num in messages[0].split():
                _, data = mail.fetch(num, "(RFC822)")
                email.message_from_bytes(data[0][1])
                # Tu logika zapisywania załączników PDF

            mail.logout()
        except Exception as e:
            logger.error(f"Błąd MailIngestion: {e}")
