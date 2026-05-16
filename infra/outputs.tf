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
  description = "Name of the SportSpace storage bucket (vouchers and reports)."
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
