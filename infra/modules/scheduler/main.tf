resource "aws_iam_role" "scheduler" {
  name = "${var.project_name}-${var.environment}-scheduler-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { Service = "scheduler.amazonaws.com" }
        Action    = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_iam_role_policy" "scheduler_invoke" {
  name = "${var.project_name}-${var.environment}-scheduler-invoke-policy"
  role = aws_iam_role.scheduler.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "InvokeLambda"
        Effect   = "Allow"
        Action   = ["lambda:InvokeFunction"]
        Resource = var.target_lambda_arn
      }
    ]
  })
}

resource "aws_lambda_permission" "scheduler" {
  action        = "lambda:InvokeFunction"
  function_name = var.target_lambda_arn
  principal     = "scheduler.amazonaws.com"
}

resource "aws_scheduler_schedule" "main" {
  name = "${var.project_name}-${var.environment}-health-ping"

  flexible_time_window {
    mode = "OFF"
  }

  schedule_expression          = var.schedule_expression
  schedule_expression_timezone = var.scheduler_timezone

  target {
    arn      = var.target_lambda_arn
    role_arn = aws_iam_role.scheduler.arn

    input = jsonencode({
      scheduler = true
      action    = "health-ping"
      timestamp = "$${aws:CurrentTimestamp}"
    })
  }
}
