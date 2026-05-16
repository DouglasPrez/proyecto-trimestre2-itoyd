output "state_bucket_name" {
  description = "Name of the S3 bucket that stores Terraform remote state."
  value       = aws_s3_bucket.tfstate.id
}

output "lock_table_name" {
  description = "Name of the DynamoDB table used for Terraform state locking."
  value       = aws_dynamodb_table.tflock.name
}

output "region" {
  description = "AWS region where the remote state resources were created."
  value       = var.region
}
