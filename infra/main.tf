# ---------------------------------------------------------------------------
# Bucket S3 existente del Delivery 1
# ---------------------------------------------------------------------------
resource "aws_s3_bucket" "main" {
  bucket = var.bucket_name

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}

# ---------------------------------------------------------------------------
# Módulo de Cómputo — Lambda (Delivery 2 / Entregable A)
# ---------------------------------------------------------------------------
module "compute" {
  source = "./modules/compute"

  environment  = var.environment
  project_name = var.project_name
  name         = "api"
  memory_size  = var.lambda_memory_size
  timeout      = var.lambda_timeout
  runtime      = "python3.12"
  handler      = "index.handler"
}

# ---------------------------------------------------------------------------
# Módulo de Almacenamiento — S3 (Delivery 2 / Entregable B)
# ---------------------------------------------------------------------------
module "storage" {
  source = "./modules/storage"

  environment                = var.environment
  project_name               = var.project_name
  bucket_name                = var.project_name
  lifecycle_prefix           = "vouchers/"
  transition_days            = 30
  noncurrent_expiration_days = 90
}

# ---------------------------------------------------------------------------
# Módulo de Base de Datos — DynamoDB (Delivery 2 / Entregable C)
# ---------------------------------------------------------------------------
module "database" {
  source = "./modules/database"

  environment   = var.environment
  project_name  = var.project_name
  billing_mode  = "PAY_PER_REQUEST"
  ttl_attribute = "expires_at"
}
