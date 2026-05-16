# ---------------------------------------------------------------------------
# Archivo ZIP de placeholder para que Terraform pueda crear la función.
# En un proyecto real este archivo sería reemplazado por el código real
# de la API de SportSpace empaquetado por el pipeline de CI/CD.
# ---------------------------------------------------------------------------
data "archive_file" "placeholder" {
  type        = "zip"
  output_path = "${path.module}/placeholder.zip"

  source {
    content  = "def handler(event, context):\n    return {'statusCode': 200, 'body': 'SportSpace API'}\n"
    filename = "index.py"
  }
}

# ---------------------------------------------------------------------------
# IAM Role — execution role de la Lambda
# Permisos mínimos: solo lo necesario para que Lambda pueda ejecutarse
# y escribir logs en CloudWatch. Sin wildcards en Action ni Resource.
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

# Política inline con permisos mínimos para CloudWatch Logs
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

# ---------------------------------------------------------------------------
# Lambda Function
# ---------------------------------------------------------------------------
resource "aws_lambda_function" "this" {
  function_name = "${var.project_name}-${var.environment}-${var.name}"
  role          = aws_iam_role.lambda_exec.arn

  filename         = data.archive_file.placeholder.output_path
  source_code_hash = data.archive_file.placeholder.output_base64sha256

  runtime     = var.runtime
  handler     = var.handler
  memory_size = var.memory_size
  timeout     = var.timeout

  environment {
    variables = {
      ENVIRONMENT  = var.environment
      PROJECT_NAME = var.project_name
    }
  }

  tags = {
    Environment = var.environment
    Project     = var.project_name
    Name        = "${var.project_name}-${var.environment}-${var.name}"
  }
}


