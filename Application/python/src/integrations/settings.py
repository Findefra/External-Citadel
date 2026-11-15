"""Environment-backed settings for integrations.

Uses pydantic-settings when available; falls back to os.environ.
"""
from __future__ import annotations

import os
from functools import lru_cache
from typing import Optional

try:
    from pydantic_settings import BaseSettings, SettingsConfigDict

    class Settings(BaseSettings):
        model_config = SettingsConfigDict(env_file=".env", extra="ignore")

        http_timeout_seconds: float = 30.0
        aws_region: str = "us-east-1"
        s3_bucket: Optional[str] = None
        openai_api_key: Optional[str] = None
        openai_base_url: Optional[str] = None
        openai_model: str = "gpt-4o-mini"

    @lru_cache
    def get_settings() -> Settings:
        return Settings()

except ImportError:

    class Settings:  # type: ignore[no-redef]
        def __init__(self) -> None:
            self.http_timeout_seconds = float(os.getenv("HTTP_TIMEOUT_SECONDS", "30"))
            self.aws_region = os.getenv("AWS_REGION", "us-east-1")
            self.s3_bucket = os.getenv("S3_BUCKET")
            self.openai_api_key = os.getenv("OPENAI_API_KEY")
            self.openai_base_url = os.getenv("OPENAI_BASE_URL")
            self.openai_model = os.getenv("OPENAI_MODEL", "gpt-4o-mini")

    @lru_cache
    def get_settings() -> Settings:
        return Settings()
