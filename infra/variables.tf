variable "environment" {
  description = "Deployment environment name (e.g. dev, staging, prod)."
  type        = string
  default     = "dev"
}

variable "project_name" {
  description = "Name of the project. Used for naming and tagging resources."
  type        = string
}

variable "region" {
  description = "AWS region where resources will be deployed."
  type        = string
  default     = "us-east-1"
}

variable "bucket_name" {
  description = "Name of the S3 bucket to create. Must be globally unique."
  type        = string
}

variable "lambda_memory_size" {
  description = "Memory in MB for the API Lambda function (128-10240)."
  type        = number
  default     = 128
}

variable "lambda_timeout" {
  description = "Timeout in seconds for the API Lambda function (1-900)."
  type        = number
  default     = 30
}

# D3 — nuevas variables
variable "domain_name" {
  description = "Custom domain name for the SportSpace API (e.g. api.sportspace.example.com)."
  type        = string
}

variable "health_check_path" {
  description = "Path used for API Gateway health/readiness checks."
  type        = string
  default     = "/"
}

variable "api_stage_name" {
  description = "API Gateway stage name (e.g. dev)."
  type        = string
  default     = "dev"
}

# D4 — Async module variables
variable "async_visibility_timeout_seconds" {
  description = "Visibility timeout for the async SQS queue in seconds."
  type        = number
  default     = 30
}

variable "async_message_retention_seconds" {
  description = "Message retention period for the async SQS queue in seconds."
  type        = number
  default     = 345600
}

variable "async_max_receive_count" {
  description = "Max receive count before messages are sent to the DLQ."
  type        = number
  default     = 5
}

variable "async_dlq_message_retention_seconds" {
  description = "Message retention period for the DLQ in seconds."
  type        = number
  default     = 1209600
}

# D4 — Event source mapping variables
variable "event_batch_size" {
  description = "Maximum number of records to retrieve per Lambda invocation."
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

# D4 — Scheduler variables
variable "scheduler_schedule_expression" {
  description = "Cron or rate expression for the EventBridge Scheduler."
  type        = string
  default     = "cron(0 6 * * ? *)"
}

variable "scheduler_timezone" {
  description = "Timezone for the EventBridge Scheduler."
  type        = string
  default     = "America/Guatemala"
}

# D4 — Async consumer variables
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
