import os
import yaml
from pathlib import Path
from pydantic_settings import BaseSettings
from pydantic import Field


def _expand(value: str) -> str:
    return os.path.expandvars(value)


def _load_yaml() -> dict:
    candidates = [
        Path(os.getenv("DM_CONFIG", "")),
        Path(os.getenv("LOCALAPPDATA", ""), "download-manager", "config.yaml"),
        Path(__file__).parent / "config.yaml",
    ]
    for path in candidates:
        if path.is_file():
            with open(path) as f:
                return yaml.safe_load(f) or {}
    return {}


_yaml = _load_yaml()


class Settings(BaseSettings):
    host: str = Field(default=_yaml.get("server", {}).get("host", "127.0.0.1"))
    port: int = Field(default=_yaml.get("server", {}).get("port", 8765))
    api_key: str = Field(default=_yaml.get("server", {}).get("api_key", "change-me"))

    destination: str = Field(
        default=_expand(_yaml.get("downloads", {}).get(
            "destination",
            r"C:\Users\%USERNAME%\OneDrive\Downloads",
        ))
    )
    max_concurrent: int = Field(
        default=_yaml.get("downloads", {}).get("max_concurrent", 3)
    )
    temp_dir: str = Field(
        default=_expand(
            _yaml.get("downloads", {}).get("temp_dir", r"%TEMP%\download-manager")
        )
    )

    aria2c_path: str | None = Field(
        default=_yaml.get("engines", {}).get("aria2c_path", None)
    )
    prefer_aria2c_for_direct: bool = Field(
        default=_yaml.get("engines", {}).get("prefer_aria2c_for_direct", True)
    )

    log_level: str = Field(
        default=_yaml.get("logging", {}).get("level", "INFO")
    )
    log_file: str = Field(
        default=_expand(
            _yaml.get("logging", {}).get(
                "file", r"%LOCALAPPDATA%\download-manager\daemon.log"
            )
        )
    )

    class Config:
        env_prefix = "DM_"


settings = Settings()
