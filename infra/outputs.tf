output "bucket_name" {
  description = "Name of the provisioned S3 bucket (Delivery 1)."
  value       = aws_s3_bucket.main.id
}

output "bucket_arn" {
  description = "ARN of the provisioned S3 bucket (Delivery 1)."
  value       = aws_s3_bucket.main.arn
}

output "lambda_function_arn" {
  description = "ARN of the API Lambda function."
  value       = module.compute.function_arn
}

output "lambda_function_name" {
  description = "Name of the API Lambda function."
  value       = module.compute.function_name
}

output "storage_bucket_name" {
  description = "Name of the SportSpace storage bucket."
  value       = module.storage.bucket_name
}

output "storage_bucket_arn" {
  description = "ARN of the SportSpace storage bucket."
  value       = module.storage.bucket_arn
}

output "database_table_name" {
  description = "Name of the DynamoDB reservas table."
  value       = module.database.table_name
}

output "database_table_arn" {
  description = "ARN of the DynamoDB reservas table."
  value       = module.database.table_arn
}

# D3 — nuevos outputs
output "api_gateway_endpoint" {
  description = "Default API Gateway endpoint URL (before custom domain)."
  value       = module.ingress.api_endpoint
}

output "api_gateway_id" {
  description = "ID of the API Gateway HTTP API."
  value       = module.ingress.api_id
}

output "api_custom_endpoint" {
  description = "Public URL via the custom domain (HTTPS)."
  value       = module.network.api_custom_endpoint
}

output "hosted_zone_id" {
  description = "Route 53 hosted zone ID."
  value       = module.network.hosted_zone_id
}

output "base_domain_name" {
  description = "Base Route53 domain name shared across environments."
  value       = module.network.base_domain_name
}

# D4 — Async module outputs
output "async_queue_url" {
  description = "URL of the async SQS queue."
  value       = module.async.queue_url
}

output "async_queue_arn" {
  description = "ARN of the async SQS queue."
  value       = module.async.queue_arn
}

output "async_queue_name" {
  description = "Name of the async SQS queue."
  value       = module.async.queue_name
}

output "async_dlq_url" {
  description = "URL of the async dead-letter queue."
  value       = module.async.dlq_url
}

output "async_dlq_arn" {
  description = "ARN of the async dead-letter queue."
  value       = module.async.dlq_arn
}

output "async_dlq_name" {
  description = "Name of the async dead-letter queue."
  value       = module.async.dlq_name
}

output "async_consumer_function_arn" {
  description = "ARN of the async consumer Lambda function."
  value       = module.compute.async_consumer_function_arn
}

output "async_consumer_function_name" {
  description = "Name of the async consumer Lambda function."
  value       = module.compute.async_consumer_function_name
}
