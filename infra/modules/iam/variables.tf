variable "environment" {
  description = "Deployment environment name (e.g. dev, staging, prod)."
  type        = string
}

variable "project_name" {
  description = "Name of the project. Used for naming and tagging resources."
  type        = string
}

variable "dynamodb_table_arn" {
  description = "ARN of the DynamoDB reservas table. Scopes compute role database permissions."
  type        = string
}

variable "storage_bucket_arn" {
  description = "ARN of the S3 storage bucket. Scopes compute and async consumer S3 permissions."
  type        = string
}

variable "async_queue_arn" {
  description = "ARN of the async SQS queue (expiry). Scopes compute (SendMessage) and async consumer (ReceiveMessage/DeleteMessage/GetQueueAttributes) permissions."
  type        = string
}

variable "async_notifications_queue_arn" {
  description = "ARN of the notifications SQS queue. Scopes compute (SendMessage) and async consumer (ReceiveMessage/DeleteMessage/GetQueueAttributes) permissions."
  type        = string
}

variable "compute_log_group_arn" {
  description = "ARN pattern for the API Lambda CloudWatch log group. Used to scope logs permissions."
  type        = string
}

variable "async_consumer_log_group_arn" {
  description = "ARN pattern for the async consumer Lambda CloudWatch log group. Used to scope logs permissions."
  type        = string
}

variable "kms_key_arn" {
  description = "ARN of the KMS CMK for encryption. Scopes KMS decrypt permissions for compute role."
  type        = string
  default     = ""
}

variable "secret_arn" {
  description = "ARN of the Secrets Manager secret. Scopes GetSecretValue permission for compute role."
  type        = string
  default     = ""
}

variable "oidc_provider_arn" {
  description = "ARN of the GitHub Actions OIDC provider. Used in the CI runner role trust policy."
  type        = string
  default     = ""
}

variable "github_org" {
  description = "GitHub organization name for OIDC trust policy subject claim."
  type        = string
  default     = ""
}

variable "github_repo" {
  description = "GitHub repository name for OIDC trust policy subject claim."
  type        = string
  default     = ""
}

variable "tfstate_bucket_arn" {
  description = "ARN of the S3 bucket storing Terraform remote state. Scopes CI runner S3 permissions."
  type        = string
  default     = ""
}

variable "tflock_table_arn" {
  description = "ARN of the DynamoDB table used for Terraform state locking. Scopes CI runner DynamoDB permissions."
  type        = string
  default     = ""
}
