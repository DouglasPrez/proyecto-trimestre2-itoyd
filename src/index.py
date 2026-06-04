"""
SportSpace API — Lambda handler para Delivery 3 (E2E proof)
Runtime: Python 3.12

GET  /reservations  — lee de DynamoDB y retorna ítems como JSON
POST /vouchers      — escribe un objeto a S3 y retorna HTTP 201 con el key

Variables de entorno (inyectadas por Terraform):
  DYNAMODB_TABLE  — nombre de la tabla de reservas
  S3_BUCKET       — nombre del bucket de vouchers
"""

import json
import os
import boto3
from datetime import datetime, timezone

dynamodb = boto3.resource("dynamodb", region_name=os.environ.get("AWS_REGION", "us-east-1"))
s3_client = boto3.client("s3", region_name=os.environ.get("AWS_REGION", "us-east-1"))

TABLE_NAME  = os.environ["DYNAMODB_TABLE"]
BUCKET_NAME = os.environ["S3_BUCKET"]


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

    # GET / — health check
    if route_key == "GET /":
        return _response(200, {"status": "ok", "service": "sportspace-api"})

    return _response(404, {"error": f"Route not found: {route_key}"})
    