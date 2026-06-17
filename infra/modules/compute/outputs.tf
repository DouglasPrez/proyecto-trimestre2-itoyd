output "function_arn" {
  description = "ARN of the provisioned Lambda function."
  value       = aws_lambda_function.this.arn
}

output "function_name" {
  description = "Name of the Lambda function."
  value       = aws_lambda_function.this.function_name
}

output "invoke_arn" {
  description = "Invoke ARN of the Lambda function. Used by API Gateway integration."
  value       = aws_lambda_function.this.invoke_arn
}

output "execution_role_arn" {
  description = "ARN of the IAM execution role attached to the Lambda function (from IAM module)."
  value       = var.execution_role_arn
}

# D4 — Async consumer outputs
output "async_consumer_function_arn" {
  description = "ARN of the async consumer Lambda function."
  value       = try(aws_lambda_function.async_consumer[0].arn, null)
}

output "async_consumer_function_name" {
  description = "Name of the async consumer Lambda function."
  value       = try(aws_lambda_function.async_consumer[0].function_name, null)
}

output "async_consumer_invoke_arn" {
  description = "Invoke ARN of the async consumer Lambda function."
  value       = try(aws_lambda_function.async_consumer[0].invoke_arn, null)
}

output "event_source_mapping_id" {
  description = "UUID of the SQS-to-Lambda event source mapping."
  value       = try(aws_lambda_event_source_mapping.sqs_to_consumer[0].id, null)
}
