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

# D5 — KMS
output "kms_key_arn" {
  description = "ARN of the KMS customer-managed key (CMK)."
  value       = aws_kms_key.main.arn
}

output "kms_key_id" {
  description = "ID of the KMS customer-managed key (CMK)."
  value       = aws_kms_key.main.key_id
}

# D5 — Secrets Manager
output "jwt_secret_arn" {
  description = "ARN of the Secrets Manager JWT signing secret."
  value       = aws_secretsmanager_secret.jwt_secret.arn
}

# D5 — IAM
output "compute_role_arn" {
  description = "ARN of the compute Lambda execution role."
  value       = module.iam.compute_role_arn
}

output "async_consumer_role_arn" {
  description = "ARN of the async consumer Lambda execution role."
  value       = module.iam.async_consumer_role_arn
}

output "ci_runner_role_arn" {
  description = "ARN of the OIDC-assumable CI runner role."
  value       = module.iam.ci_runner_role_arn
}

# D5 — OIDC
output "oidc_provider_arn" {
  description = "ARN of the GitHub Actions OIDC provider."
  value       = aws_iam_openid_connect_provider.github.arn
}

# D5 — TLS
output "cloudfront_domain_name" {
  description = "CloudFront distribution domain name for HTTP→HTTPS redirect."
  value       = try(aws_cloudfront_distribution.main[0].domain_name, null)
}

# D5 — Observability
output "dashboard_name" {
  description = "Name of the CloudWatch dashboard."
  value       = module.observability.dashboard_name
}

output "sns_topic_arn" {
  description = "ARN of the SNS topic for alarm notifications."
  value       = module.observability.sns_topic_arn
}

output "budget_name" {
  description = "Name of the monthly cost budget."
  value       = module.observability.budget_name
}
