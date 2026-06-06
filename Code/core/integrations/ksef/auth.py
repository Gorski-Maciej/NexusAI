# core/integrations/ksef/auth.py
import logging

import httpx

logger = logging.getLogger("nexus.ksef")

class KsefAuthService:
    def __init__(self, nip: str, is_demo: bool = True):
        self.nip = nip
        self.base_url = "[https://ksef-test.mf.gov.pl/api/online/](https://ksef-test.mf.gov.pl/api/online/)" if is_demo else "[https://ksef.mf.gov.pl/api/online/](https://ksef.mf.gov.pl/api/online/)"

        # Klucz publiczny pobierany zazwyczaj z zasobów aplikacji lub API MF
        self.mf_pub_key = b"---BEGIN PUBLIC KEY---\n..."

    async def login(self, user_token: str) -> str:
        """Główna metoda logowania zwracająca SessionToken."""
        async with httpx.AsyncClient(timeout=30.0) as client:
            # KROK 1: AuthorisationChallenge
            resp = await client.post(
                f"{self.base_url}Session/AuthorisationChallenge",
                json={"contextIdentifier": {"type": "onip", "identifier": self.nip}}
            )
            resp.raise_for_status()
            data = resp.json()
            return data.get("challenge")
