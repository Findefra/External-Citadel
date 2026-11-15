"""Thin OpenAI-compatible chat wrapper."""
from __future__ import annotations

from typing import Any, Dict, List, Optional

from .settings import get_settings


def chat(
    messages: List[Dict[str, str]],
    *,
    model: Optional[str] = None,
    temperature: float = 0.2,
) -> str:
    """Send chat messages; return assistant text content.

    Requires OPENAI_API_KEY (and optional OPENAI_BASE_URL for compatible gateways).
    """
    try:
        from openai import OpenAI
    except ImportError as exc:
        raise ImportError("Install openai: pip install openai") from exc

    settings = get_settings()
    if not settings.openai_api_key:
        raise ValueError("OPENAI_API_KEY is not configured")

    client_kwargs: Dict[str, Any] = {"api_key": settings.openai_api_key}
    if settings.openai_base_url:
        client_kwargs["base_url"] = settings.openai_base_url

    client = OpenAI(**client_kwargs)
    response = client.chat.completions.create(
        model=model or settings.openai_model,
        messages=messages,
        temperature=temperature,
    )
    choice = response.choices[0].message
    return (choice.content or "").strip()
