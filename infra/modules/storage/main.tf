# ---------------------------------------------------------------------------
# S3 Bucket principal de SportSpace
# Almacena vouchers PDF de reservas y reportes de utilización (UC-02, UC-07)
# ---------------------------------------------------------------------------
resource "aws_s3_bucket" "storage" {
  bucket = "${var.bucket_name}-${var.environment}-storage"

  tags = {
    Environment = var.environment
    Project     = var.project_name
    Name        = "${var.bucket_name}-${var.environment}-storage"
  }
}

# ---------------------------------------------------------------------------
# Versionado — permite recuperar versiones anteriores de vouchers y reportes
# ---------------------------------------------------------------------------
resource "aws_s3_bucket_versioning" "storage" {
  bucket = aws_s3_bucket.storage.id

  versioning_configuration {
    status = "Enabled"
  }
}

# ---------------------------------------------------------------------------
# Encriptación SSE-S3 — datos en reposo protegidos con AES-256
# ---------------------------------------------------------------------------
resource "aws_s3_bucket_server_side_encryption_configuration" "storage" {
  bucket = aws_s3_bucket.storage.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# ---------------------------------------------------------------------------
# Lifecycle rule — scoped al prefijo de vouchers (no aplica a todo el bucket)
# Fase 1: transición a STANDARD_IA después de N días (más barato para archivos)
# Fase 2: expiración de versiones no-actuales después de N días
# ---------------------------------------------------------------------------
resource "aws_s3_bucket_lifecycle_configuration" "storage" {
  bucket = aws_s3_bucket.storage.id

  rule {
    id     = "vouchers-lifecycle"
    status = "Enabled"

    filter {
      prefix = var.lifecycle_prefix
    }

    transition {
      days          = var.transition_days
      storage_class = "STANDARD_IA"
    }

    noncurrent_version_expiration {
      noncurrent_days = var.noncurrent_expiration_days
    }
  }
}

# ---------------------------------------------------------------------------
# Bloqueo de acceso público — ningún objeto puede ser público accidentalmente
# ---------------------------------------------------------------------------
resource "aws_s3_bucket_public_access_block" "storage" {
  bucket = aws_s3_bucket.storage.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# ---------------------------------------------------------------------------
# Bucket policy — fuerza acceso exclusivamente por SSL (aws:SecureTransport)
# Cualquier request HTTP sin TLS es rechazado con Deny explícito
# ---------------------------------------------------------------------------
resource "aws_s3_bucket_policy" "storage" {
  bucket = aws_s3_bucket.storage.id

  # Depende del bloqueo de acceso público para evitar conflictos
  depends_on = [aws_s3_bucket_public_access_block.storage]

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "DenyNonSSL"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:*"
        Resource = [
          aws_s3_bucket.storage.arn,
          "${aws_s3_bucket.storage.arn}/*"
        ]
        Condition = {
          Bool = {
            "aws:SecureTransport" = "false"
          }
        }
      }
    ]
  })
}
