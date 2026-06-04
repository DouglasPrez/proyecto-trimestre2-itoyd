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
# Actualizado en D3: se agregan env vars de DynamoDB, S3 y permisos IAM
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

  dynamodb_table_name = module.database.table_name
  s3_bucket_name      = module.storage.bucket_name
  dynamodb_table_arn  = module.database.table_arn
  s3_bucket_arn       = module.storage.bucket_arn
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

# ---------------------------------------------------------------------------
# Seed Data — Delivery 3 / Deliverable D
# ---------------------------------------------------------------------------
module "seed" {
  source = "./seed"

  dynamodb_table_name = module.database.table_name
}

# ---------------------------------------------------------------------------
# Módulo de Ingress — API Gateway HTTP API (Delivery 3 / Deliverable C)
# ---------------------------------------------------------------------------
module "ingress" {
  source = "./modules/ingress"

  environment       = var.environment
  project_name      = var.project_name
  lambda_invoke_arn = module.compute.invoke_arn
  health_check_path = var.health_check_path
  stage_name        = var.api_stage_name
}

# ---------------------------------------------------------------------------
# Módulo de Red — DNS + Custom Domain (Delivery 3 / Deliverable A + B)
# ---------------------------------------------------------------------------
module "network" {
  source = "./modules/network"

  domain_name               = var.domain_name
  aws_region                = var.region
  project_name              = var.project_name
  environment               = var.environment
  api_gateway_id            = module.ingress.api_id
  api_gateway_stage_name    = module.ingress.stage_name
  api_gateway_execution_arn = module.ingress.execution_arn
  lambda_function_name      = module.compute.function_name
}
