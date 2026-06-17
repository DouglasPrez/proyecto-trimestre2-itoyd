output "api_log_group_name" {
  description = "Name of the API Lambda CloudWatch log group."
  value       = aws_cloudwatch_log_group.api.name
}

output "api_log_group_arn" {
  description = "ARN of the API Lambda CloudWatch log group."
  value       = aws_cloudwatch_log_group.api.arn
}

output "async_consumer_log_group_name" {
  description = "Name of the async consumer Lambda CloudWatch log group."
  value       = aws_cloudwatch_log_group.async_consumer.name
}

output "async_consumer_log_group_arn" {
  description = "ARN of the async consumer Lambda CloudWatch log group."
  value       = aws_cloudwatch_log_group.async_consumer.arn
}

output "alarm_api_5xx_arn" {
  description = "ARN of the API 5XX error alarm."
  value       = aws_cloudwatch_metric_alarm.api_5xx.arn
}

output "alarm_async_consumer_errors_arn" {
  description = "ARN of the async consumer error alarm."
  value       = aws_cloudwatch_metric_alarm.async_consumer_errors.arn
}

output "sns_topic_arn" {
  description = "ARN of the SNS topic for alarm notifications."
  value       = aws_sns_topic.alarms.arn
}

output "dashboard_name" {
  description = "Name of the CloudWatch dashboard."
  value       = aws_cloudwatch_dashboard.main.dashboard_name
}

output "budget_name" {
  description = "Name of the monthly cost budget."
  value       = aws_budgets_budget.monthly.name
}
