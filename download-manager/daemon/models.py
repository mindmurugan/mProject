from __future__ import annotations

import uuid
from datetime import datetime
from enum import Enum
from typing import Optional

from pydantic import BaseModel, HttpUrl, Field


class JobStatus(str, Enum):
    QUEUED = "queued"
    DOWNLOADING = "downloading"
    COMPLETED = "completed"
    FAILED = "failed"
    CANCELLED = "cancelled"


class Engine(str, Enum):
    AUTO = "auto"
    YTDLP = "ytdlp"
    ARIA2C = "aria2c"


class JobCreate(BaseModel):
    url: str
    engine: Engine = Engine.AUTO
    filename: Optional[str] = None
    extra_args: list[str] = Field(default_factory=list)


class JobProgress(BaseModel):
    downloaded_bytes: int = 0
    total_bytes: Optional[int] = None
    speed_bps: Optional[float] = None
    eta_seconds: Optional[int] = None
    percent: Optional[float] = None


class Job(BaseModel):
    id: str = Field(default_factory=lambda: str(uuid.uuid4()))
    url: str
    engine: Engine
    filename: Optional[str] = None
    status: JobStatus = JobStatus.QUEUED
    progress: JobProgress = Field(default_factory=JobProgress)
    output_path: Optional[str] = None
    error: Optional[str] = None
    created_at: datetime = Field(default_factory=datetime.utcnow)
    started_at: Optional[datetime] = None
    finished_at: Optional[datetime] = None

    def ws_payload(self) -> dict:
        return {
            "event": "progress",
            "job": self.model_dump(mode="json"),
        }


class WSMessage(BaseModel):
    event: str
    job: Optional[dict] = None
    message: Optional[str] = None
