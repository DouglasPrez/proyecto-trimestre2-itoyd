variable "dynamodb_table_name" {
  description = "Name of the DynamoDB reservas table to seed with demo data."
  type        = string
}

resource "aws_dynamodb_table_item" "seed_reserva_01" {
  table_name = var.dynamodb_table_name
  hash_key   = "reserva_id"
  range_key  = "created_at"

  item = jsonencode({
    reserva_id     = { S = "SEED-001" }
    created_at     = { S = "2026-06-01T10:00:00Z" }
    espacio_id     = { S = "CANCHA-TENIS-01" }
    usuario_id     = { S = "USR-DEMO-001" }
    nombre_usuario = { S = "Demo User" }
    complejo       = { S = "Las Américas" }
    deporte        = { S = "tenis" }
    hora_inicio    = { S = "2026-06-10T09:00:00Z" }
    hora_fin       = { S = "2026-06-10T10:00:00Z" }
    estado         = { S = "confirmed" }
    monto_pagado   = { N = "75.00" }
    codigo_reserva = { S = "SPT-2026-000001" }
  })
}
