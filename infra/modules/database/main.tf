# ---------------------------------------------------------------------------
# Tabla principal de Reservas — SportSpace
# Clave de partición: reserva_id (identificador único por reserva)
# Clave de ordenamiento: created_at (permite consultas por fecha)
# ---------------------------------------------------------------------------
resource "aws_dynamodb_table" "reservas" {
  name         = "${var.project_name}-${var.environment}-reservas"
  billing_mode = var.billing_mode
  hash_key     = "reserva_id"
  range_key    = "created_at"

  # ---------------------------------------------------------------------------
  # Atributos definidos — solo los usados como keys de tabla o GSI
  # ---------------------------------------------------------------------------
  attribute {
    name = "reserva_id"
    type = "S"
  }

  attribute {
    name = "created_at"
    type = "S"
  }

  attribute {
    name = "espacio_id"
    type = "S"
  }

  attribute {
    name = "usuario_id"
    type = "S"
  }

  # ---------------------------------------------------------------------------
  # GSI 1 — consultas por espacio (UC-01: disponibilidad por cancha)
  # Permite buscar todas las reservas de un espacio específico por fecha
  # ---------------------------------------------------------------------------
  global_secondary_index {
    name            = "espacio-fecha-index"
    hash_key        = "espacio_id"
    range_key       = "created_at"
    projection_type = "ALL"
  }

  # ---------------------------------------------------------------------------
  # GSI 2 — consultas por usuario (UC-03: mis reservas)
  # Permite listar todas las reservas activas de un usuario
  # ---------------------------------------------------------------------------
  global_secondary_index {
    name            = "usuario-fecha-index"
    hash_key        = "usuario_id"
    range_key       = "created_at"
    projection_type = "ALL"
  }

  # ---------------------------------------------------------------------------
  # TTL — expiración automática de bloqueos optimistas (UC-02)
  # El bloqueo de 15 minutos expira automáticamente sin procesos externos
  # ---------------------------------------------------------------------------
  ttl {
    attribute_name = var.ttl_attribute
    enabled        = true
  }

  # ---------------------------------------------------------------------------
  # Encriptación en reposo con clave gestionada por AWS
  # ---------------------------------------------------------------------------
  server_side_encryption {
    enabled = true
  }

  tags = {
    Environment = var.environment
    Project     = var.project_name
    Name        = "${var.project_name}-${var.environment}-reservas"
  }
}
