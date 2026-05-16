# ---------------------------------------------------------------------------
# Bootstrap workspace — crea los recursos para el remote state de Terraform
# IMPORTANTE: Este workspace NUNCA debe tener un bloque backend{}
#             Su propio estado se guarda localmente (terraform.tfstate)
#             y ese archivo SÍ puede commitearse al repo.
# ---------------------------------------------------------------------------

# Bucket S3 — almacena el estado remoto de Terraform
resource "aws_s3_bucket" "tfstate" {
  bucket = "${var.project_name}-tfstate"

  # Protección contra destroy accidental — el estado es crítico
  lifecycle {
    prevent_destroy = true
  }

  tags = {
    Project   = var.project_name
    ManagedBy = "terraform-bootstrap"
  }
}

# Versionado — permite recuperar versiones anteriores del estado
resource "aws_s3_bucket_versioning" "tfstate" {
  bucket = aws_s3_bucket.tfstate.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Encriptación SSE-S3 con AES256
resource "aws_s3_bucket_server_side_encryption_configuration" "tfstate" {
  bucket = aws_s3_bucket.tfstate.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Bloqueo de acceso público — el estado nunca debe ser público
resource "aws_s3_bucket_public_access_block" "tfstate" {
  bucket = aws_s3_bucket.tfstate.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Tabla DynamoDB — mecanismo de locking para evitar applies concurrentes
resource "aws_dynamodb_table" "tflock" {
  name         = "${var.project_name}-tflock"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  # Protección contra destroy accidental
  lifecycle {
    prevent_destroy = true
  }

  tags = {
    Project   = var.project_name
    ManagedBy = "terraform-bootstrap"
  }
}
