"""FastAPI download manager daemon."""
from __future__ import annotations

import asyncio
import logging
import logging.handlers
import os
from contextlib import asynccontextmanager
from pathlib import Path
from typing import List

from fastapi import (
    Depends,
    FastAPI,
    HTTPException,
    WebSocket,
    WebSocketDisconnect,
    status,
)
from fastapi.middleware.cors import CORSMiddleware

from auth import require_api_key
from config import settings
from job_manager import JobManager
from models import Job, JobCreate, JobStatus
from websocket_manager import WebSocketManager

# ── Logging setup ────────────────────────────────────────────────────────────

log_path = Path(settings.log_file)
log_path.parent.mkdir(parents=True, exist_ok=True)

logging.basicConfig(
    level=settings.log_level,
    format="%(asctime)s [%(levelname)s] %(name)s: %(message)s",
    handlers=[
        logging.StreamHandler(),
        logging.handlers.RotatingFileHandler(
            log_path, maxBytes=5 * 1024 * 1024, backupCount=3
        ),
    ],
)
logger = logging.getLogger(__name__)

# ── App factory ───────────────────────────────────────────────────────────────

ws_manager = WebSocketManager()


async def _broadcast_job(job: Job) -> None:
    await ws_manager.broadcast(job.ws_payload())


@asynccontextmanager
async def lifespan(app: FastAPI):
    job_mgr: JobManager = app.state.job_manager
    worker_task = asyncio.create_task(job_mgr.worker())
    logger.info(
        "Download manager started on %s:%d", settings.host, settings.port
    )
    yield
    worker_task.cancel()
    try:
        await worker_task
    except asyncio.CancelledError:
        pass


def create_app() -> FastAPI:
    app = FastAPI(
        title="Download Manager Daemon",
        version="1.0.0",
        lifespan=lifespan,
    )
    app.add_middleware(
        CORSMiddleware,
        allow_origins=["chrome-extension://*"],
        allow_methods=["*"],
        allow_headers=["*"],
    )

    job_manager = JobManager(broadcast_fn=_broadcast_job)
    app.state.job_manager = job_manager

    # ── REST endpoints ────────────────────────────────────────────────────────

    @app.post(
        "/jobs",
        response_model=Job,
        status_code=status.HTTP_202_ACCEPTED,
        dependencies=[Depends(require_api_key)],
    )
    async def create_job(payload: JobCreate) -> Job:
        return await job_manager.create_job(payload)

    @app.get(
        "/jobs",
        response_model=List[Job],
        dependencies=[Depends(require_api_key)],
    )
    async def list_jobs() -> list[Job]:
        return job_manager.all_jobs()

    @app.get(
        "/jobs/{job_id}",
        response_model=Job,
        dependencies=[Depends(require_api_key)],
    )
    async def get_job(job_id: str) -> Job:
        job = job_manager.get_job(job_id)
        if not job:
            raise HTTPException(status_code=404, detail="Job not found")
        return job

    @app.delete(
        "/jobs/{job_id}",
        status_code=status.HTTP_204_NO_CONTENT,
        dependencies=[Depends(require_api_key)],
    )
    async def cancel_job(job_id: str) -> None:
        ok = await job_manager.cancel_job(job_id)
        if not ok:
            raise HTTPException(
                status_code=404,
                detail="Job not found or already finished",
            )

    @app.get("/health")
    async def health() -> dict:
        return {"status": "ok"}

    # ── WebSocket ─────────────────────────────────────────────────────────────

    @app.websocket("/ws")
    async def websocket_endpoint(websocket: WebSocket) -> None:
        # Validate API key from query param for WS (headers not reliable cross-browser)
        api_key = websocket.query_params.get("api_key")
        if not api_key or api_key != settings.api_key:
            await websocket.close(code=4001)
            return

        await ws_manager.connect(websocket)
        # Send current job state to newly connected client
        for job in job_manager.all_jobs():
            await websocket.send_text(
                __import__("json").dumps(job.ws_payload())
            )

        try:
            while True:
                # Keep alive; client can send pings
                await websocket.receive_text()
        except WebSocketDisconnect:
            pass
        finally:
            await ws_manager.disconnect(websocket)

    return app


app = create_app()

if __name__ == "__main__":
    import uvicorn

    uvicorn.run(
        "main:app",
        host=settings.host,
        port=settings.port,
        log_level=settings.log_level.lower(),
    )
