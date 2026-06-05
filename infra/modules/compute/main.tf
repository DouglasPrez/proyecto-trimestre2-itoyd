# ---------------------------------------------------------------------------
# Empaquetado — dos modos:
#   1. app.zip existe (generado por App/backend/build_lambda.sh):
#      → se despliega el backend FastAPI completo (E4+)
#   2. app.zip no existe (fallback):
#      → se empaqueta src/index.py solo (handler POC de E3)
# ---------------------------------------------------------------------------
locals {
  use_app_zip = fileexists("${path.module}/app.zip")
}

data "archive_file" "handler" {
  # Solo se empaqueta cuando no hay app.zip precompilado
  count       = local.use_app_zip ? 0 : 1
  type        = "zip"
  output_path = "${path.module}/handler.zip"
  source_file = "${path.root}/../src/index.py"
}

# ---------------------------------------------------------------------------
# IAM Role
# ---------------------------------------------------------------------------
resource "aws_iam_role" "lambda_exec" {
  name = "${var.project_name}-${var.environment}-${var.name}-exec-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { Service = "lambda.amazonaws.com" }
        Action    = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}

# CloudWatch Logs — scoped al log group de esta función
resource "aws_iam_role_policy" "lambda_logs" {
  name = "${var.project_name}-${var.environment}-${var.name}-logs-policy"
  role = aws_iam_role.lambda_exec.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:log-group:/aws/lambda/${var.project_name}-${var.environment}-${var.name}:*"
      }
    ]
  })
}

# D3 — DynamoDB: scoped al ARN de la tabla específica (sin wildcard)
resource "aws_iam_role_policy" "lambda_dynamodb" {
  name = "${var.project_name}-${var.environment}-${var.name}-dynamodb-policy"
  role = aws_iam_role.lambda_exec.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "DynamoDBTableAccess"
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:UpdateItem",
          "dynamodb:DeleteItem",
          "dynamodb:Scan",
          "dynamodb:Query"
        ]
        Resource = [
          var.dynamodb_table_arn,
          "${var.dynamodb_table_arn}/index/*"
        ]
      }
    ]
  })
}

# D3 — S3: scoped al ARN del bucket específico (sin wildcard)
resource "aws_iam_role_policy" "lambda_s3" {
  name = "${var.project_name}-${var.environment}-${var.name}-s3-policy"
  role = aws_iam_role.lambda_exec.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "S3BucketAccess"
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:DeleteObject"
        ]
        Resource = "${var.s3_bucket_arn}/*"
      }
    ]
  })
}

# ---------------------------------------------------------------------------
# Lambda Function
# ---------------------------------------------------------------------------
resource "aws_lambda_function" "this" {
  function_name = "${var.project_name}-${var.environment}-${var.name}"
  role          = aws_iam_role.lambda_exec.arn

  filename = local.use_app_zip ? "${path.module}/app.zip" : data.archive_file.handler[0].output_path
  source_code_hash = local.use_app_zip ? try(
    filebase64sha256("${path.module}/app.zip"),
    data.archive_file.handler[0].output_base64sha256
  ) : data.archive_file.handler[0].output_base64sha256

  runtime     = var.runtime
  handler     = var.handler
  memory_size = var.memory_size
  timeout     = var.timeout

  environment {
    variables = {
      ENVIRONMENT    = var.environment
      PROJECT_NAME   = var.project_name
      DYNAMODB_TABLE = var.dynamodb_table_name
      S3_BUCKET      = var.s3_bucket_name
      SECRET_KEY     = var.secret_key
      # AWS_REGION es reservada — el runtime Lambda la inyecta automáticamente
    }
  }

  tags = {
    Environment = var.environment
    Project     = var.project_name
    Name        = "${var.project_name}-${var.environment}-${var.name}"
  }
}
