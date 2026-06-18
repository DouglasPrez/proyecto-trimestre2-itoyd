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

variable "dynamodb_table_name" {
  description = "Name of the DynamoDB table. Injected into Lambda as DYNAMODB_TABLE env var."
  type        = string
}

variable "dynamodb_table_arn" {
  description = "ARN of the DynamoDB table. Used by the IAM module to scope permissions."
  type        = string
}

variable "s3_bucket_name" {
  description = "Name of the S3 storage bucket. Injected into Lambda as S3_BUCKET env var."
  type        = string
}

variable "s3_bucket_arn" {
  description = "ARN of the S3 storage bucket. Used by the IAM module to scope permissions."
  type        = string
}

variable "secret_key" {
  description = "JWT signing secret injected into Lambda as SECRET_KEY env var."
  type        = string
  sensitive   = true
  default     = "sportspace-dev-secret-change-in-production-2026"
}

variable "sqs_queue_url" {
  description = "URL of the SQS queue for async message processing."
  type        = string
  default     = ""
}

variable "sqs_queue_arn" {
  description = "ARN of the SQS queue for IAM policy scoping."
  type        = string
  default     = ""
}

variable "async_consumer_name" {
  description = "Base name for the async consumer Lambda function."
  type        = string
  default     = "async-consumer"
}

variable "async_consumer_memory_size" {
  description = "Memory in MB for the async consumer Lambda."
  type        = number
  default     = 128
}

variable "async_consumer_timeout" {
  description = "Timeout in seconds for the async consumer Lambda."
  type        = number
  default     = 60
}

variable "event_batch_size" {
  description = "Maximum number of records to retrieve per invocation."
  type        = number
  default     = 10
}

variable "event_maximum_batching_window_in_seconds" {
  description = "Maximum batching window in seconds."
  type        = number
  default     = 5
}

variable "event_bisect_batch_on_function_error" {
  description = "If the function returns an error, split the batch in two and retry."
  type        = bool
  default     = false
}

variable "enable_async" {
  description = "Habilita los recursos async (SQS policy, consumer lambda, event source mapping)."
  type        = bool
  default     = false
}

# D5 — IAM module outputs consumed here (role ARNs instead of inline roles)
variable "execution_role_arn" {
  description = "ARN of the IAM execution role for the API Lambda function. Created by the IAM module."
  type        = string
}

variable "async_consumer_execution_role_arn" {
  description = "ARN of the IAM execution role for the async consumer Lambda function. Created by the IAM module."
  type        = string
  default     = ""
}

# D5 — Secrets Manager
variable "secret_arn" {
  description = "ARN of the Secrets Manager secret containing the JWT signing key. Injected as SECRET_ARN env var."
  type        = string
  default     = ""
}
