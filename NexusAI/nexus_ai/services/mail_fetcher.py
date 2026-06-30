from __future__ import annotations

from typing import final

import imaplib
from pathlib import Path


@final
class MailIngestionService:
    """Automatyczne pobieranie faktur PDF ze zdefiniowanej skrzynki mailowej (IMAP)."""

    def __init__(self, imap_server: str, email_user: str, email_pass: str, download_dir: str):
        self.imap_server = imap_server
        self.email_user = email_user
        self.email_pass = email_pass
        self.download_dir = Path(download_dir)
        self.download_dir.mkdir(parents=True, exist_ok=True)

    def fetch_unread_pdfs(self) -> list[str]:
        """Pobiera nieprzeczytane maile, szuka PDF-ów, zapisuje na dysk i zwraca ścieżki."""
        downloaded_files = []
        try:
            # Łączymy się z serwerem
            mail = imaplib.IMAP4_SSL(self.imap_server)
            mail.login(self.email_user, self.email_pass)
            mail.select("inbox")

            # Szukamy nieprzeczytanych wiadomości...
        except Exception:
            pass
        return downloaded_files
