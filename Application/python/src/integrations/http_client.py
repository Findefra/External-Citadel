"""Thin httpx wrapper for JSON HTTP calls."""
from __future__ import annotations

from typing import Any, Mapping, Optional

import httpx

from .settings import get_settings


def _client(timeout: Optional[float] = None) -> httpx.Client:
    settings = get_settings()
    return httpx.Client(timeout=timeout if timeout is not None else settings.http_timeout_seconds)


def get_json(
    url: str,
    *,
    headers: Optional[Mapping[str, str]] = None,
    params: Optional[Mapping[str, Any]] = None,
    timeout: Optional[float] = None,
) -> Any:
    """GET URL and return parsed JSON. Raises httpx.HTTPStatusError on 4xx/5xx."""
    with _client(timeout) as client:
        response = client.get(url, headers=headers, params=params)
        response.raise_for_status()
        return response.json()


def post_json(
    url: str,
    *,
    json_body: Any = None,
    headers: Optional[Mapping[str, str]] = None,
    timeout: Optional[float] = None,
) -> Any:
    """POST JSON and return parsed JSON body when present."""
    with _client(timeout) as client:
        response = client.post(url, headers=headers, json=json_body)
        response.raise_for_status()
        if response.content:
            return response.json()
        return None
