"""Thin boto3 S3 helpers."""
from __future__ import annotations

from typing import Optional

import boto3
from botocore.exceptions import BotoCoreError, ClientError

from .settings import get_settings


def _s3_client(region: Optional[str] = None):
    settings = get_settings()
    return boto3.client("s3", region_name=region or settings.aws_region)


def upload_bytes(
    bucket: str,
    key: str,
    data: bytes,
    *,
    content_type: str = "application/octet-stream",
    region: Optional[str] = None,
) -> str:
    """Upload bytes to s3://bucket/key. Returns the S3 URI."""
    client = _s3_client(region)
    try:
        client.put_object(Bucket=bucket, Key=key, Body=data, ContentType=content_type)
    except (BotoCoreError, ClientError) as exc:
        raise RuntimeError(f"S3 upload failed for s3://{bucket}/{key}: {exc}") from exc
    return f"s3://{bucket}/{key}"


def download_bytes(
    bucket: str,
    key: str,
    *,
    region: Optional[str] = None,
) -> bytes:
    """Download object body as bytes."""
    client = _s3_client(region)
    try:
        obj = client.get_object(Bucket=bucket, Key=key)
        return obj["Body"].read()
    except (BotoCoreError, ClientError) as exc:
        raise RuntimeError(f"S3 download failed for s3://{bucket}/{key}: {exc}") from exc


def upload_to_default_bucket(key: str, data: bytes, *, content_type: str = "application/octet-stream") -> str:
    """Upload using S3_BUCKET from settings."""
    settings = get_settings()
    if not settings.s3_bucket:
        raise ValueError("S3_BUCKET is not configured")
    return upload_bytes(settings.s3_bucket, key, data, content_type=content_type)
