"""yt-dlp download engine with async progress callbacks."""
from __future__ import annotations

import asyncio
import logging
from pathlib import Path
from typing import Callable, Awaitable

import yt_dlp

from models import Job, JobProgress, JobStatus

logger = logging.getLogger(__name__)

ProgressCallback = Callable[[Job], Awaitable[None]]


class YtdlpEngine:
    def __init__(self, destination: str, temp_dir: str):
        self.destination = Path(destination)
        self.temp_dir = Path(temp_dir)
        self.destination.mkdir(parents=True, exist_ok=True)
        self.temp_dir.mkdir(parents=True, exist_ok=True)

    async def download(
        self,
        job: Job,
        on_progress: ProgressCallback,
        loop: asyncio.AbstractEventLoop | None = None,
    ) -> str:
        loop = loop or asyncio.get_event_loop()

        def _progress_hook(d: dict) -> None:
            if d["status"] == "downloading":
                downloaded = d.get("downloaded_bytes", 0)
                total = d.get("total_bytes") or d.get("total_bytes_estimate")
                speed = d.get("speed")
                eta = d.get("eta")
                percent = (downloaded / total * 100) if total else None
                job.progress = JobProgress(
                    downloaded_bytes=downloaded,
                    total_bytes=total,
                    speed_bps=speed,
                    eta_seconds=eta,
                    percent=percent,
                )
                asyncio.run_coroutine_threadsafe(on_progress(job), loop)
            elif d["status"] == "finished":
                job.progress.percent = 100.0

        outtmpl = str(
            self.destination / (job.filename or "%(title)s.%(ext)s")
        )

        ydl_opts: dict = {
            "outtmpl": outtmpl,
            "progress_hooks": [_progress_hook],
            "noplaylist": True,
            "quiet": True,
            "no_warnings": True,
        }

        if job.extra_args:
            # extra_args accepted as list of "key=value" or flags
            for arg in job.extra_args:
                if "=" in arg:
                    k, v = arg.split("=", 1)
                    ydl_opts[k.lstrip("-").replace("-", "_")] = v

        def _run() -> str:
            with yt_dlp.YoutubeDL(ydl_opts) as ydl:
                info = ydl.extract_info(job.url, download=True)
                return ydl.prepare_filename(info)

        output_path = await loop.run_in_executor(None, _run)
        return output_path
