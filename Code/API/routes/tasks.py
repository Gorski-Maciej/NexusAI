from __future__ import annotations

from litestar import Controller, get


class TaskController(Controller):
    path = "/api/v1/tasks"

    @get("/{task_id:str}")
    async def get_task_status(self, task_id: str) -> dict[str, str]:
        return {"task_id": task_id, "status": "QUEUED"}
