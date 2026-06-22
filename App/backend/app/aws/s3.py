import logging
from functools import lru_cache
from typing import Optional

import boto3
from botocore.config import Config
from botocore.exceptions import BotoCoreError, ClientError

from ..config import settings

logger = logging.getLogger(__name__)


@lru_cache(maxsize=1)
def _get_client():
    return boto3.client(
        "s3",
        region_name=settings.aws_region,
        config=Config(signature_version="s3v4"),
    )


def _key(reservation_code: str) -> str:
    return f"{settings.s3_voucher_prefix}/{reservation_code}.html"


def upload_voucher(reservation_code: str, html_content: str) -> bool:
    """Upload HTML voucher to S3. Returns True on success, False if S3 not configured or on error."""
    if not settings.s3_bucket:
        logger.debug("S3_BUCKET not configured — skipping voucher upload")
        return False
    try:
        _get_client().put_object(
            Bucket=settings.s3_bucket,
            Key=_key(reservation_code),
            Body=html_content.encode("utf-8"),
            ContentType="text/html; charset=utf-8",
        )
        logger.info("Voucher uploaded: %s", _key(reservation_code))
        return True
    except (BotoCoreError, ClientError) as exc:
        logger.error("S3 upload failed for %s: %s", reservation_code, exc)
        return False


def get_voucher_presigned_url(reservation_code: str, expires_in: int = 3600) -> Optional[str]:
    """Return a presigned URL for the voucher, or None if S3 not configured / object missing."""
    if not settings.s3_bucket:
        return None
    try:
        url: str = _get_client().generate_presigned_url(
            "get_object",
            Params={"Bucket": settings.s3_bucket, "Key": _key(reservation_code)},
            ExpiresIn=expires_in,
        )
        return url
    except (BotoCoreError, ClientError) as exc:
        logger.error("Presigned URL failed for %s: %s", reservation_code, exc)
        return None
