locals {
  name_prefix = "${var.project_name}-${var.environment}"
}

# ---------------------------------------------------------------------------
# CloudWatch Log Groups
# ---------------------------------------------------------------------------
resource "aws_cloudwatch_log_group" "api" {
  name              = "/aws/lambda/${var.api_lambda_function_name}"
  retention_in_days = var.log_retention_days

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_cloudwatch_log_group" "async_consumer" {
  name              = "/aws/lambda/${var.async_consumer_lambda_function_name}"
  retention_in_days = var.log_retention_days

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}

# ---------------------------------------------------------------------------
# SNS Topic for Alarm Notifications
# ---------------------------------------------------------------------------
resource "aws_sns_topic" "alarms" {
  name = "${local.name_prefix}-alarms"

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.alarms.arn
  protocol  = "email"
  endpoint  = var.notification_email
}

# ---------------------------------------------------------------------------
# Metric Alarms
# ---------------------------------------------------------------------------

# Alarm 1 — API 5XX errors
resource "aws_cloudwatch_metric_alarm" "api_5xx" {
  alarm_name          = "${local.name_prefix}-api-5xx"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = var.alarm_evaluation_periods
  metric_name         = "5xxError"
  namespace           = "AWS/ApiGateway"
  period              = var.alarm_period_seconds
  statistic           = "Sum"
  threshold           = var.alarm_error_threshold
  alarm_description   = "API Gateway 5XX error count exceeds ${var.alarm_error_threshold} in ${var.alarm_evaluation_periods} periods of ${var.alarm_period_seconds}s"
  alarm_actions       = [aws_sns_topic.alarms.arn]

  dimensions = {
    ApiName = "${var.project_name}-${var.environment}-sportspace-api"
  }

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}

# Alarm 2 — Async consumer Lambda errors
resource "aws_cloudwatch_metric_alarm" "async_consumer_errors" {
  alarm_name          = "${local.name_prefix}-async-consumer-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = var.alarm_evaluation_periods
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = var.alarm_period_seconds
  statistic           = "Sum"
  threshold           = 0
  alarm_description   = "Async consumer Lambda function has errors"
  alarm_actions       = [aws_sns_topic.alarms.arn]

  dimensions = {
    FunctionName = var.async_consumer_lambda_function_name
  }

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}

# Alarm 3 — Notifications DLQ depth (documento maestro §20.3 — alarm-dlq-notifications)
resource "aws_cloudwatch_metric_alarm" "dlq_notifications" {
  alarm_name          = "${local.name_prefix}-dlq-notifications"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "ApproximateNumberOfMessagesVisible"
  namespace           = "AWS/SQS"
  period              = 300
  statistic           = "Maximum"
  threshold           = 0
  alarm_description   = "Notifications DLQ has messages — indica notificaciones fallidas tras maxReceiveCount"
  alarm_actions       = [aws_sns_topic.alarms.arn]

  dimensions = {
    QueueName = var.notifications_dlq_name
  }

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}

# ---------------------------------------------------------------------------
# CloudWatch Dashboard
# ---------------------------------------------------------------------------
resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "${local.name_prefix}-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/ApiGateway", "Count", { stat = "Sum", label = "Request Count" }]
          ]
          period = 300
          stat   = "Sum"
          region = var.region
          title  = "API Gateway — Request Count"
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 0
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/Lambda", "Errors", { stat = "Sum", label = "API Lambda Errors" }],
            ["AWS/Lambda", "Errors", { stat = "Sum", label = "Async Consumer Errors" }]
          ]
          period = 300
          stat   = "Sum"
          region = var.region
          title  = "Lambda — Error Rate"
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/ApiGateway", "Latency", { stat = "Average", label = "Avg Latency" }]
          ]
          period = 300
          stat   = "Average"
          region = var.region
          title  = "API Gateway — Average Latency"
        }
      }
    ]
  })
}

# ---------------------------------------------------------------------------
# Cost Budget
# ---------------------------------------------------------------------------
resource "aws_budgets_budget" "monthly" {
  name              = "${local.name_prefix}-monthly-budget"
  budget_type       = "COST"
  limit_amount      = var.monthly_budget_usd
  limit_unit        = "USD"
  time_period_start = "2026-01-01_00:00"
  time_unit         = "MONTHLY"

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 80
    threshold_type             = "PERCENTAGE"
    notification_type          = "ACTUAL"
    subscriber_email_addresses = [var.notification_email]
  }

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}
