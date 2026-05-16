output "bucket_arn" {
  description = "ARN of the provisioned S3 storage bucket."
  value       = aws_s3_bucket.storage.arn
}

output "bucket_name" {
  description = "Name of the provisioned S3 storage bucket."
  value       = aws_s3_bucket.storage.id
}

output "bucket_domain_name" {
  description = "Regional domain name of the S3 storage bucket."
  value       = aws_s3_bucket.storage.bucket_regional_domain_name
}
