variable "environment" {
  description = "Deployment environment name (e.g. dev, staging, prod)."
  type        = string
}

variable "name" {
  description = "Base name for the Lambda function and related resources."
  type        = string
}

variable "memory_size" {
  description = "Amount of memory in MB allocated to the Lambda function (128-10240)."
  type        = number
  default     = 128
}

variable "timeout" {
  description = "Maximum execution time in seconds for the Lambda function (1-900)."
  type        = number
  default     = 30
}

variable "runtime" {
  description = "Lambda runtime identifier (e.g. python3.12, nodejs20.x)."
  type        = string
  default     = "python3.12"
}

variable "handler" {
  description = "Function entrypoint in the format file.method (e.g. index.handler)."
  type        = string
  default     = "index.handler"
}

variable "project_name" {
  description = "Name of the project. Used for tagging resources."
  type        = string
}

# D3 — variables para conectar Lambda a DynamoDB y S3
variable "dynamodb_table_name" {
  description = "Name of the DynamoDB table. Injected into Lambda as DYNAMODB_TABLE env var."
  type        = string
}

variable "dynamodb_table_arn" {
  description = "ARN of the DynamoDB table. Scopes the IAM policy — no wildcard Resource."
  type        = string
}

variable "s3_bucket_name" {
  description = "Name of the S3 storage bucket. Injected into Lambda as S3_BUCKET env var."
  type        = string
}

variable "s3_bucket_arn" {
  description = "ARN of the S3 storage bucket. Scopes the IAM policy — no wildcard Resource."
  type        = string
}

variable "secret_key" {
  description = "JWT signing secret injected into Lambda as SECRET_KEY env var."
  type        = string
  sensitive   = true
  default     = "sportspace-dev-secret-change-in-production-2026"
}