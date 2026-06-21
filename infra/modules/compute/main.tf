locals {
  use_app_zip = fileexists("${path.module}/app.zip")
}

data "archive_file" "handler" {
  count       = local.use_app_zip ? 0 : 1
  type        = "zip"
  output_path = "${path.module}/handler.zip"
  source_file = "${path.root}/../src/index.py"
}

# ---------------------------------------------------------------------------
# Lambda Function — API
# ---------------------------------------------------------------------------
resource "aws_lambda_function" "this" {
  function_name = "${var.project_name}-${var.environment}-${var.name}"
  role          = var.execution_role_arn

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
      ENVIRONMENT                  = var.environment
      PROJECT_NAME                 = var.project_name
      DYNAMODB_TABLE               = var.dynamodb_table_name
      S3_BUCKET                    = var.s3_bucket_name
      SECRET_KEY                   = var.secret_key
      SQS_QUEUE_URL                = var.sqs_queue_url
      SQS_NOTIFICATIONS_QUEUE_URL  = var.sqs_queue_url
      SQS_EXPIRY_QUEUE_URL         = var.sqs_queue_url
      SECRET_ARN                   = var.secret_arn
    }
  }

  tags = {
    Environment = var.environment
    Project     = var.project_name
    Name        = "${var.project_name}-${var.environment}-${var.name}"
  }
}

# ---------------------------------------------------------------------------
# Async Consumer Lambda — SQS-triggered worker
# ---------------------------------------------------------------------------
resource "aws_lambda_function" "async_consumer" {
  count = var.enable_async ? 1 : 0

  function_name = "${var.project_name}-${var.environment}-${var.async_consumer_name}"
  role          = var.async_consumer_execution_role_arn

  filename = local.use_app_zip ? "${path.module}/app.zip" : data.archive_file.handler[0].output_path
  source_code_hash = local.use_app_zip ? try(
    filebase64sha256("${path.module}/app.zip"),
    data.archive_file.handler[0].output_base64sha256
  ) : data.archive_file.handler[0].output_base64sha256

  runtime     = var.runtime
  handler     = "index.async_consumer"
  memory_size = var.async_consumer_memory_size
  timeout     = var.async_consumer_timeout

  environment {
    variables = {
      ENVIRONMENT    = var.environment
      PROJECT_NAME   = var.project_name
      DYNAMODB_TABLE = var.dynamodb_table_name
      S3_BUCKET      = var.s3_bucket_name
      SQS_QUEUE_URL  = var.sqs_queue_url
      SECRET_KEY     = var.secret_key
      SECRET_ARN     = var.secret_arn
    }
  }

  tags = {
    Environment = var.environment
    Project     = var.project_name
    Name        = "${var.project_name}-${var.environment}-${var.async_consumer_name}"
  }
}

# ---------------------------------------------------------------------------
# Event Source Mapping — SQS -> Async Consumer Lambda
# ---------------------------------------------------------------------------
resource "aws_lambda_event_source_mapping" "sqs_to_consumer" {
  count = var.enable_async ? 1 : 0

  event_source_arn = var.sqs_queue_arn
  function_name    = aws_lambda_function.async_consumer[0].arn

  batch_size                         = var.event_batch_size
  maximum_batching_window_in_seconds = var.event_maximum_batching_window_in_seconds
  bisect_batch_on_function_error     = var.event_bisect_batch_on_function_error

  enabled = true
}
