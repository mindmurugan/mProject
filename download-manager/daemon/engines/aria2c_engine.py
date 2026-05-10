"""aria2c subprocess download engine with real-time progress parsing."""
from __future__ import annotations

import asyncio
import logging
import re
import shutil
from pathlib import Path
from typing import Callable, Awaitable

from models import Job, JobProgress

logger = logging.getLogger(__name__)

ProgressCallback = Callable[[Job], Awaitable[None]]

# Matches aria2c progress lines:
# [#abc123 1.2MiB/5.0MiB(24%) CN:1 DL:512KiB ETA:7s]
_PROGRESS_RE = re.compile(
    r"\[#\w+\s+([\d.]+\w+)/([\d.]+\w+)\((\d+)%\).*?DL:([\d.]+\w+).*?ETA:(\d+)s\]",
    re.IGNORECASE,
)

_UNIT_MAP = {
    "b": 1,
    "kib": 1024,
    "mib": 1024**2,
    "gib": 1024**3,
    "kb": 1000,
    "mb": 1000**2,
    "gb": 1000**3,
}


def _to_bytes(value: str) -> int:
    m = re.match(r"([\d.]+)(\w+)", value.strip(), re.IGNORECASE)
    if not m:
        return 0
    num, unit = float(m.group(1)), m.group(2).lower()
    return int(num * _UNIT_MAP.get(unit, 1))


class Aria2cEngine:
    def __init__(self, destination: str, temp_dir: str, aria2c_path: str | None = None):
        self.destination = Path(destination)
        self.temp_dir = Path(temp_dir)
        self.destination.mkdir(parents=True, exist_ok=True)
        self.temp_dir.mkdir(parents=True, exist_ok=True)
        self.aria2c_bin = aria2c_path or shutil.which("aria2c") or "aria2c"

    async def download(
        self,
        job: Job,
        on_progress: ProgressCallback,
    ) -> str:
        filename = job.filename or ""
        cmd = [
            self.aria2c_bin,
            "--dir", str(self.destination),
            "--console-log-level=notice",
            "--summary-interval=1",
            "--auto-file-renaming=false",
        ]
        if filename:
            cmd += ["--out", filename]
        cmd.append(job.url)

        proc = await asyncio.create_subprocess_exec(
            *cmd,
            stdout=asyncio.subprocess.PIPE,
            stderr=asyncio.subprocess.STDOUT,
        )

        output_path = str(self.destination / filename) if filename else ""

        async for raw in proc.stdout:  # type: ignore[union-attr]
            line = raw.decode(errors="replace").rstrip()
            m = _PROGRESS_RE.search(line)
            if m:
                downloaded = _to_bytes(m.group(1))
                total = _to_bytes(m.group(2))
                percent = float(m.group(3))
                speed = _to_bytes(m.group(4))
                eta = int(m.group(5))
                job.progress = JobProgress(
                    downloaded_bytes=downloaded,
                    total_bytes=total,
                    speed_bps=float(speed),
                    eta_seconds=eta,
                    percent=percent,
                )
                await on_progress(job)
            # capture final output path from aria2c's "Download complete" line
            if "Download complete:" in line:
                output_path = line.split("Download complete:")[-1].strip()

        await proc.wait()
        if proc.returncode != 0:
            raise RuntimeError(f"aria2c exited with code {proc.returncode}")

        return output_path
