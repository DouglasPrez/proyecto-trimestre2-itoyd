# Propuestas para Live Change — Presentación Final

## Equipo SportSpace · 25 Junio 2026

---

## Propuesta 1 — Filtrar reservas por estado

| Campo | Detalle |
|---|---|
| **Endpoint** | `GET /reservations` |
| **Handler** | `src/index.py` → función `handler()` → bloque `route_key == "GET /reservations"` |
| **Comportamiento actual** | Retorna todas las reservas sin filtro (scan con límite 20) |
| **Cambio propuesto** | Agregar query param `?status=confirmed` para filtrar por estado |
| **Líneas de código** | ~5 |
| **Verificación** | `curl "https://<endpoint>/reservations?status=confirmed"` → solo reservas con `"estado": "confirmed"` |

---

## Propuesta 2 — Enriquecer objeto del async consumer

| Campo | Detalle |
|---|---|
| **Endpoint** | `POST /reservations/enqueue` (producer) + SQS → Lambda consumer |
| **Handler** | `src/index.py` → función `async_consumer()` |
| **Comportamiento actual** | Escribe el mensaje JSON tal cual en S3 sin metadata |
| **Cambio propuesto** | Agregar campo `"processed_at"` con timestamp ISO al objeto en S3 |
| **Líneas de código** | ~1 |
| **Verificación** | `curl -X POST "https://<endpoint>/reservations/enqueue"` → esperar → ver objeto en S3 con `"processed_at"` |

---

## Propuesta 3 — Health check combinado

| Campo | Detalle |
|---|---|
| **Endpoint** | `GET /` |
| **Handler** | `src/index.py` → función `handler()` → bloque `route_key == "GET /"` |
| **Comportamiento actual** | Retorna `{"status": "ok"}` sin verificar dependencias |
| **Cambio propuesto** | Verificar DynamoDB (`table_status`) y S3 (`head_bucket`), retornar HTTP 200 si ambos alcanzables, HTTP 503 si alguno falla |
| **Líneas de código** | ~10 |
| **Verificación** | `curl "https://<endpoint>/"` → `{"status":"ok","dynamodb":"reachable","s3":"reachable"}` |

---

## Notas para la presentación

- Las 3 propuestas son cambios quirúrgicos (< 10 líneas cada uno)
- Todos se implementan en < 3 minutos con AI assistance
- Ninguno requiere cambios en Terraform ni nueva infraestructura
- Todos son verificables via curl contra el endpoint de staging
