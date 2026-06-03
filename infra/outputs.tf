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

output "hosted_zone_name_servers" {
  description = "Name servers for the Route 53 zone. Configure at your domain registrar."
  value       = module.network.hosted_zone_name_servers
}
