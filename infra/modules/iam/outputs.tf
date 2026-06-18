output "compute_role_arn" {
  description = "ARN of the IAM role for the API Lambda function (compute)."
  value       = aws_iam_role.compute.arn
}

output "compute_role_name" {
  description = "Name of the IAM role for the API Lambda function (compute)."
  value       = aws_iam_role.compute.name
}

output "async_consumer_role_arn" {
  description = "ARN of the IAM role for the async consumer Lambda function."
  value       = aws_iam_role.async_consumer.arn
}

output "async_consumer_role_name" {
  description = "Name of the IAM role for the async consumer Lambda function."
  value       = aws_iam_role.async_consumer.name
}

output "ci_runner_role_arn" {
  description = "ARN of the IAM role for GitHub Actions CI runner (OIDC-assumable)."
  value       = aws_iam_role.ci_runner.arn
}

output "ci_runner_role_name" {
  description = "Name of the IAM role for GitHub Actions CI runner."
  value       = aws_iam_role.ci_runner.name
}
