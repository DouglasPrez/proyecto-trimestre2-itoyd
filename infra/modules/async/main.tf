resource "aws_sqs_queue" "main" {
  name_prefix                = var.queue_name_prefix
  visibility_timeout_seconds = var.visibility_timeout_seconds
  message_retention_seconds  = var.message_retention_seconds

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.dlq.arn
    maxReceiveCount     = var.max_receive_count
  })

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_sqs_queue" "dlq" {
  name_prefix               = "${var.queue_name_prefix}-dlq"
  message_retention_seconds = var.dlq_message_retention_seconds

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}
