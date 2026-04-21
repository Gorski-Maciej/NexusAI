from litestar.middleware import AbstractMiddleware
from litestar.status_codes import HTTP_200_OK, HTTP_201_CREATED

class AuditMiddleware(AbstractMiddleware):
    """Przechwytuje akcje użytkownika i zapisuje je w dzienniku audytu."""

    async def __call__(self, scope, receive, send):
        if scope["type"] != "http" or scope["method"] not in ["POST", "PUT", "DELETE"]:
            await self.app(scope, receive, send)
            return

        async def send_wrapper(message):
            if message["type"] == "http.response.start":
                status = message["status"]
                if status in [HTTP_200_OK, HTTP_201_CREATED]:
                    # Logika zapisu do bazy w tle
                    await self._log_action(scope)
            await send(message)

        await self.app(scope, receive, send_wrapper)
