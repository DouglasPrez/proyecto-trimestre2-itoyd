locals {
  api_lambda_function_name            = "${var.project_name}-${var.environment}-api"
  async_consumer_lambda_function_name = "${var.project_name}-${var.environment}-${var.async_consumer_name}"
}

# ---------------------------------------------------------------------------
# S3 Bucket existente del Delivery 1
# ---------------------------------------------------------------------------
# v2 — one-click deployment proof trigger
resource "aws_s3_bucket" "main" {
  bucket = var.bucket_name

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}

# ---------------------------------------------------------------------------
# KMS Customer-Managed Key (D5 / Deliverable B)
# Policy scoped to: root account (admin), compute execution role, Secrets Manager service
# ---------------------------------------------------------------------------
data "aws_caller_identity" "current" {}

resource "aws_kms_key" "main" {
  description             = "${var.project_name} ${var.environment} CMK for S3, DynamoDB, and Secrets Manager"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "EnableIAMAdminAccess"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "AllowComputeRoleUsage"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.project_name}-${var.environment}-compute-role"
        }
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey"
        ]
        Resource = "*"
      },
      {
        Sid    = "AllowSecretsManagerUsage"
        Effect = "Allow"
        Principal = {
          Service = "secretsmanager.amazonaws.com"
        }
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:GenerateDataKey"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "kms:ViaService" = "secretsmanager.${var.region}.amazonaws.com"
          }
        }
      }
    ]
  })

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_kms_alias" "main" {
  name          = var.kms_key_alias
  target_key_id = aws_kms_key.main.key_id
}

# ---------------------------------------------------------------------------
# Secrets Manager — JWT signing key (D5 / Deliverable B)
# ---------------------------------------------------------------------------
resource "aws_secretsmanager_secret" "jwt_secret" {
  name        = var.db_secret_name
  description = "JWT signing key for SportSpace API"
  kms_key_id  = aws_kms_key.main.arn

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_secretsmanager_secret_version" "jwt_secret" {
  secret_id     = aws_secretsmanager_secret.jwt_secret.id
  secret_string = var.db_password
}

# ---------------------------------------------------------------------------
# OIDC Provider — GitHub Actions (D5 / Deliverable C)
# ---------------------------------------------------------------------------
resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}

# ---------------------------------------------------------------------------
# Módulo IAM (D5 / Deliverable A)
# ---------------------------------------------------------------------------
module "iam" {
  source = "./modules/iam"

  environment  = var.environment
  project_name = var.project_name

  dynamodb_table_arn           = module.database.table_arn
  storage_bucket_arn           = module.storage.bucket_arn
  async_queue_arn              = module.async.queue_arn
  compute_log_group_arn        = "arn:aws:logs:*:*:log-group:/aws/lambda/${local.api_lambda_function_name}:*"
  async_consumer_log_group_arn = "arn:aws:logs:*:*:log-group:/aws/lambda/${local.async_consumer_lambda_function_name}:*"

  kms_key_arn = aws_kms_key.main.arn
  secret_arn  = aws_secretsmanager_secret.jwt_secret.arn

  oidc_provider_arn  = aws_iam_openid_connect_provider.github.arn
  github_org         = var.github_org
  github_repo        = var.github_repo
  tfstate_bucket_arn = "arn:aws:s3:::proyecto-trimestre2-v2-tfstate"
  tflock_table_arn   = "arn:aws:dynamodb:us-east-1:*:table/proyecto-trimestre2-v2-tflock"
}

# ---------------------------------------------------------------------------
# Módulo de Almacenamiento — S3 (D2 / D5: upgraded to KMS encryption)
# ---------------------------------------------------------------------------
module "storage" {
  source = "./modules/storage"

  environment                = var.environment
  project_name               = var.project_name
  bucket_name                = var.project_name
  lifecycle_prefix           = "vouchers/"
  transition_days            = 30
  noncurrent_expiration_days = 90
  kms_key_arn                = aws_kms_key.main.arn
}

# ---------------------------------------------------------------------------
# Módulo de Base de Datos — DynamoDB (D2 / D5: upgraded to KMS encryption)
# ---------------------------------------------------------------------------
module "database" {
  source = "./modules/database"

  environment   = var.environment
  project_name  = var.project_name
  billing_mode  = "PAY_PER_REQUEST"
  ttl_attribute = "expires_at"
  kms_key_arn   = aws_kms_key.main.arn
}

# ---------------------------------------------------------------------------
# Seed Data — D3 / Deliverable D
# ---------------------------------------------------------------------------
module "seed" {
  source = "./seed"

  dynamodb_table_name = module.database.table_name
}

# ---------------------------------------------------------------------------
# Módulo de Cómputo — Lambda (D2 / D5: IAM roles from module)
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

  # D5 — IAM role ARNs from IAM module
  execution_role_arn                = module.iam.compute_role_arn
  async_consumer_execution_role_arn = module.iam.async_consumer_role_arn

  # D5 — Secrets Manager ARN
  secret_arn = aws_secretsmanager_secret.jwt_secret.arn

  # D4 — SQS integration
  sqs_queue_url                            = module.async.queue_url
  sqs_queue_arn                            = module.async.queue_arn
  async_consumer_name                      = var.async_consumer_name
  async_consumer_memory_size               = var.async_consumer_memory_size
  async_consumer_timeout                   = var.async_consumer_timeout
  event_batch_size                         = var.event_batch_size
  event_maximum_batching_window_in_seconds = var.event_maximum_batching_window_in_seconds
  event_bisect_batch_on_function_error     = var.event_bisect_batch_on_function_error
  enable_async                             = true
}

# ---------------------------------------------------------------------------
# Módulo de Ingress — API Gateway HTTP API (D3 / Deliverable C)
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
# Módulo de Red — DNS + Custom Domain + TLS (D3 / D5: CloudFront redirect)
# ---------------------------------------------------------------------------
module "network" {
  source = "./modules/network"

  domain_name               = var.domain_name
  base_domain_name          = var.base_domain_name
  aws_region                = var.region
  project_name              = var.project_name
  environment               = var.environment
  api_gateway_id            = module.ingress.api_id
  api_gateway_stage_name    = module.ingress.stage_name
  api_gateway_execution_arn = module.ingress.execution_arn
  lambda_function_name      = module.compute.function_name
}

# ---------------------------------------------------------------------------
# CloudFront — HTTP to HTTPS redirect (D5 / Deliverable D)
# ---------------------------------------------------------------------------
resource "aws_cloudfront_distribution" "main" {
  count = var.redirect_http_to_https && var.enable_cloudfront ? 1 : 0

  enabled             = true
  is_ipv6_enabled     = true
  comment             = "${var.project_name} ${var.environment} — HTTP→HTTPS redirect"
  default_root_object = ""
  price_class         = "PriceClass_100"

  origin {
    domain_name = "${module.ingress.api_id}.execute-api.${var.region}.amazonaws.com"
    origin_id   = "api-gateway-${var.environment}"

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "https-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "api-gateway-${var.environment}"

    viewer_protocol_policy = "redirect-to-https"

    forwarded_values {
      query_string = true
      headers      = ["*"]
      cookies {
        forward = "all"
      }
    }

    min_ttl     = 0
    default_ttl = 0
    max_ttl     = 0
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}

# ---------------------------------------------------------------------------
# Módulo de Scheduled Jobs (D4 / Deliverable C)
# ---------------------------------------------------------------------------
module "scheduler" {
  source = "./modules/scheduler"

  schedule_expression = var.scheduler_schedule_expression
  target_lambda_arn   = module.compute.function_arn
  scheduler_timezone  = var.scheduler_timezone
  environment         = var.environment
  project_name        = var.project_name
}

# ---------------------------------------------------------------------------
# Módulo Async — SQS + DLQ (D4 / Deliverable A)
# ---------------------------------------------------------------------------
module "async" {
  source = "./modules/async"

  queue_name_prefix             = "${var.project_name}-${var.environment}-reservations"
  visibility_timeout_seconds    = var.async_visibility_timeout_seconds
  message_retention_seconds     = var.async_message_retention_seconds
  max_receive_count             = var.async_max_receive_count
  dlq_message_retention_seconds = var.async_dlq_message_retention_seconds
  environment                   = var.environment
  project_name                  = var.project_name
}

# ---------------------------------------------------------------------------
# Módulo de Observabilidad (D5 / Deliverable E)
# ---------------------------------------------------------------------------
module "observability" {
  source = "./modules/observability"

  environment  = var.environment
  project_name = var.project_name

  api_lambda_function_name            = local.api_lambda_function_name
  async_consumer_lambda_function_name = local.async_consumer_lambda_function_name

  log_retention_days = var.log_retention_days

  alarm_error_threshold    = var.alarm_error_threshold
  alarm_evaluation_periods = var.alarm_evaluation_periods
  alarm_period_seconds     = var.alarm_period_seconds
  notification_email       = var.notification_email

  monthly_budget_usd = var.monthly_budget_usd

  api_endpoint_url = module.ingress.api_endpoint
}
