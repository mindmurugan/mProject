"""Manages the download job queue and dispatches to engines."""
from __future__ import annotations

import asyncio
import logging
import re
from datetime import datetime
from typing import Optional

from models import Engine, Job, JobCreate, JobStatus
from config import settings
from engines import YtdlpEngine, Aria2cEngine

logger = logging.getLogger(__name__)

# Domains/patterns that yt-dlp should handle
_YTDLP_DOMAINS = re.compile(
    r"(youtube\.com|youtu\.be|vimeo\.com|twitch\.tv|twitter\.com|tiktok\.com"
    r"|instagram\.com|dailymotion\.com|soundcloud\.com|bandcamp\.com)",
    re.IGNORECASE,
)


def _pick_engine(url: str, preference: Engine) -> Engine:
    if preference != Engine.AUTO:
        return preference
    if _YTDLP_DOMAINS.search(url):
        return Engine.YTDLP
    return Engine.ARIA2C if settings.prefer_aria2c_for_direct else Engine.YTDLP


class JobManager:
    def __init__(self, broadcast_fn):
        self._jobs: dict[str, Job] = {}
        self._queue: asyncio.Queue[Job] = asyncio.Queue()
        self._semaphore = asyncio.Semaphore(settings.max_concurrent)
        self._broadcast = broadcast_fn
        self._ytdlp = YtdlpEngine(settings.destination, settings.temp_dir)
        self._aria2c = Aria2cEngine(
            settings.destination, settings.temp_dir, settings.aria2c_path
        )

    def all_jobs(self) -> list[Job]:
        return list(self._jobs.values())

    def get_job(self, job_id: str) -> Optional[Job]:
        return self._jobs.get(job_id)

    async def create_job(self, payload: JobCreate) -> Job:
        engine = _pick_engine(payload.url, payload.engine)
        job = Job(
            url=payload.url,
            engine=engine,
            filename=payload.filename,
        )
        # copy extra_args from payload onto job
        job.__dict__["extra_args"] = payload.extra_args
        self._jobs[job.id] = job
        await self._queue.put(job)
        logger.info("Job queued: %s → %s [%s]", job.id, job.url, engine)
        await self._broadcast(job)
        return job

    async def cancel_job(self, job_id: str) -> bool:
        job = self._jobs.get(job_id)
        if not job:
            return False
        if job.status in (JobStatus.COMPLETED, JobStatus.FAILED, JobStatus.CANCELLED):
            return False
        job.status = JobStatus.CANCELLED
        job.finished_at = datetime.utcnow()
        await self._broadcast(job)
        return True

    async def _run_job(self, job: Job) -> None:
        if job.status == JobStatus.CANCELLED:
            return

        job.status = JobStatus.DOWNLOADING
        job.started_at = datetime.utcnow()
        await self._broadcast(job)

        try:
            extra_args = job.__dict__.get("extra_args", [])

            if job.engine == Engine.YTDLP:
                # Pass extra_args via job attributes
                job_copy = job
                job_copy.__dict__["extra_args"] = extra_args
                output = await self._ytdlp.download(
                    job_copy, self._on_progress, loop=asyncio.get_event_loop()
                )
            else:
                output = await self._aria2c.download(job, self._on_progress)

            job.status = JobStatus.COMPLETED
            job.output_path = output
            job.progress.percent = 100.0
        except asyncio.CancelledError:
            job.status = JobStatus.CANCELLED
        except Exception as exc:
            job.status = JobStatus.FAILED
            job.error = str(exc)
            logger.exception("Job %s failed", job.id)
        finally:
            job.finished_at = datetime.utcnow()
            await self._broadcast(job)

    async def _on_progress(self, job: Job) -> None:
        await self._broadcast(job)

    async def worker(self) -> None:
        """Long-running task that drains the queue respecting concurrency limit."""
        while True:
            job = await self._queue.get()
            if job.status == JobStatus.CANCELLED:
                self._queue.task_done()
                continue
            asyncio.create_task(self._bounded_run(job))
            self._queue.task_done()

    async def _bounded_run(self, job: Job) -> None:
        async with self._semaphore:
            await self._run_job(job)
