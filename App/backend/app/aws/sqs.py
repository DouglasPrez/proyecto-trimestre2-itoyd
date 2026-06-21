import json
import logging
from functools import lru_cache
from typing import Optional

import boto3
from botocore.exceptions import BotoCoreError, ClientError

from ..config import settings

logger = logging.getLogger(__name__)


@lru_cache(maxsize=1)
def _get_client():
    return boto3.client("sqs", region_name=settings.aws_region)


def _send(queue_url: str, body: dict, delay_seconds: int = 0) -> bool:
    """Send a message to SQS. Returns True on success, False if not configured or on error."""
    if not queue_url:
        logger.debug("SQS queue URL not configured — skipping publish")
        return False
    try:
        _get_client().send_message(
            QueueUrl=queue_url,
            MessageBody=json.dumps(body, default=str),
            DelaySeconds=delay_seconds,
        )
        logger.info("SQS message sent to %s | type=%s id=%s",
                    queue_url,
                    body.get("event_type", "expiry"),
                    body.get("reserva_id", ""))
        return True
    except (BotoCoreError, ClientError) as exc:
        logger.error("SQS send failed for queue %s: %s", queue_url, exc)
        return False


def publish_expiry(reserva_id: int, space_id: int) -> bool:
    """Enqueue a delayed expiry message (900 s = 15 min) for a PENDING reservation.

    The expiry-worker will fire a conditional UpdateItem that only transitions
    the reservation to EXPIRED if its status is still PENDING — idempotent by design.
    """
    return _send(
        queue_url=settings.sqs_expiry_queue_url,
        body={"reserva_id": reserva_id, "space_id": space_id},
        delay_seconds=900,
    )


def publish_notification(
    event_type: str,
    reserva_id: int,
    usuario_email: str,
    fecha: Optional[str] = None,
    hora_inicio: Optional[str] = None,
    codigo: Optional[str] = None,
) -> bool:
    """Enqueue a notification command to the notifications-worker.

    Supported event_type values (from documento maestro §13):
      reserva_confirmada | reserva_cancelada | recordatorio_24h | bloqueo_notificado
    """
    return _send(
        queue_url=settings.sqs_notifications_queue_url,
        body={
            "event_type": event_type,
            "reserva_id": str(reserva_id),
            "usuario_email": usuario_email,
            "fecha": fecha,
            "hora_inicio": hora_inicio,
            "codigo": codigo,
        },
    )
