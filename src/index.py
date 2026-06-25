"""
SportSpace API — Lambda handler for Delivery 5 (Security, Observability & One-Click)
Runtime: Python 3.12

Reads JWT signing key from AWS Secrets Manager at cold start (SECRET_ARN env var).
Falls back to SECRET_KEY env var if SECRET_ARN is not set.

Rutas HTTP (API Gateway -> handler):
  GET  /reservations           — lee de DynamoDB y retorna ítems como JSON
  POST /vouchers               — escribe un objeto a S3 y retorna HTTP 201 con el key
  POST /reservations/enqueue   — envía mensaje a SQS, retorna HTTP 202 con message_id
  GET  /                       — health check

Entry point async_consumer (SQS -> Lambda):
  Se activa por el event source mapping de SQS.
  Lee el mensaje, escribe un objeto a S3.

Variables de entorno:
  DYNAMODB_TABLE  — nombre de la tabla de reservas
  S3_BUCKET       — nombre del bucket de vouchers
  SQS_QUEUE_URL   — URL de la cola SQS (solo consumer)
  SECRET_KEY      — JWT signing key (fallback, reemplazado por Secrets Manager)
  SECRET_ARN      — ARN del secreto en Secrets Manager (D5)
"""

import json
import os
import boto3
import uuid
import logging
from datetime import datetime, timezone

logger = logging.getLogger()
logger.setLevel(logging.INFO)

dynamodb = boto3.resource("dynamodb", region_name=os.environ.get("AWS_REGION", "us-east-1"))
s3_client = boto3.client("s3", region_name=os.environ.get("AWS_REGION", "us-east-1"))
sqs_client = boto3.client("sqs", region_name=os.environ.get("AWS_REGION", "us-east-1"))
secretsmanager = boto3.client("secretsmanager", region_name=os.environ.get("AWS_REGION", "us-east-1"))

TABLE_NAME    = os.environ["DYNAMODB_TABLE"]
BUCKET_NAME   = os.environ["S3_BUCKET"]
SQS_QUEUE_URL = os.environ.get("SQS_QUEUE_URL", "")
SECRET_ARN    = os.environ.get("SECRET_ARN", "")

# D5 — Read JWT secret from Secrets Manager at cold start
SECRET_KEY = os.environ.get("SECRET_KEY", "sportspace-dev-secret-change-in-production-2026")
if SECRET_ARN:
    try:
        response = secretsmanager.get_secret_value(SecretId=SECRET_ARN)
        SECRET_KEY = response["SecretString"]
        logger.info("JWT secret loaded from Secrets Manager: %s", SECRET_ARN)
    except Exception as e:
        logger.warning("Failed to read secret from Secrets Manager, using env var fallback: %s", e)


def _response(status_code: int, body: dict) -> dict:
    return {
        "statusCode": status_code,
        "headers": {"Content-Type": "application/json"},
        "body": json.dumps(body, default=str),
    }


def handler(event: dict, context) -> dict:
    route_key = event.get("routeKey", "")

    # GET /reservations — lee de DynamoDB
    if route_key == "GET /reservations":
        table  = dynamodb.Table(TABLE_NAME)
        result = table.scan(Limit=20)
        items  = result.get("Items", [])
        return _response(200, {"reservations": items, "count": len(items)})

    # POST /vouchers — escribe en S3
    if route_key == "POST /vouchers":
        raw_body = event.get("body") or "{}"
        try:
            payload = json.loads(raw_body)
        except json.JSONDecodeError:
            return _response(400, {"error": "Invalid JSON body"})

        timestamp  = datetime.now(tz=timezone.utc).strftime("%Y%m%dT%H%M%SZ")
        object_key = f"vouchers/{timestamp}.json"

        s3_client.put_object(
            Bucket      = BUCKET_NAME,
            Key         = object_key,
            Body        = json.dumps(payload, default=str),
            ContentType = "application/json",
        )
        return _response(201, {"object_key": object_key, "bucket": BUCKET_NAME})

    # POST /reservations/enqueue — envía mensaje a SQS (Delivery 4)
    if route_key == "POST /reservations/enqueue":
        raw_body = event.get("body") or "{}"
        try:
            payload = json.loads(raw_body)
        except json.JSONDecodeError:
            return _response(400, {"error": "Invalid JSON body"})

        if not SQS_QUEUE_URL:
            return _response(500, {"error": "SQS_QUEUE_URL not configured"})

        message_id = str(uuid.uuid4())
        message_body = json.dumps({
            "message_id": message_id,
            "payload": payload,
            "timestamp": datetime.now(tz=timezone.utc).isoformat(),
        })

        response = sqs_client.send_message(
            QueueUrl    = SQS_QUEUE_URL,
            MessageBody = message_body,
        )

        return _response(202, {
            "message_id": message_id,
            "sqs_message_id": response["MessageId"],
        })

    # GET / — health check
    if route_key == "GET /":
        return _response(200, {"status": "ok", "service": "sportspace-api"})

    return _response(404, {"error": f"Route not found: {route_key}"})


def async_consumer(event: dict, context) -> None:
    """
    D4 — Async consumer (SQS-triggered).
    Lee mensajes de SQS, escribe cada uno como objeto en S3.
    """
    for record in event.get("Records", []):
        try:
            message_body = json.loads(record["body"])
            message_id = message_body.get("message_id", record.get("messageId", str(uuid.uuid4())))
            message_body["processed_at"] = datetime.now(tz=timezone.utc).isoformat()
            timestamp  = datetime.now(tz=timezone.utc).strftime("%Y%m%dT%H%M%SZ")
            object_key = f"async/{timestamp}-{message_id}.json"

            s3_client.put_object(
                Bucket      = BUCKET_NAME,
                Key         = object_key,
                Body        = json.dumps(message_body, default=str),
                ContentType = "application/json",
            )

            print(f"Processed message {message_id} -> s3://{BUCKET_NAME}/{object_key}")

        except Exception as e:
            print(f"Error processing record: {e}")
            raise
