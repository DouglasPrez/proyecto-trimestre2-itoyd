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

# D3 — Custom domain
variable "domain_name" {
  description = "Custom domain name for the SportSpace API (e.g. api.sportspace.example.com)."
  type        = string
}

variable "base_domain_name" {
  description = "Base Route53 domain zone (shared across environments)."
  type        = string
  default     = "proyecto.grupo2.oyd.solid.com.gt"
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

# D5 — KMS
variable "kms_key_alias" {
  description = "Alias for the KMS customer-managed key (CMK)."
  type        = string
  default     = "alias/sportspace-cmk"
}

# D5 — Secrets Manager
variable "db_secret_name" {
  description = "Name of the Secrets Manager secret for the JWT signing key."
  type        = string
  default     = "sportspace-jwt-secret"
}

variable "db_password" {
  description = "JWT signing secret value stored in Secrets Manager. Sensitive — do NOT commit in .tfvars."
  type        = string
  sensitive   = true
  default     = "sportspace-dev-secret-change-in-production-2026"
}

# D5 — OIDC
variable "github_org" {
  description = "GitHub organization name for OIDC trust policy."
  type        = string
  default     = "DouglasPrez"
}

variable "github_repo" {
  description = "GitHub repository name for OIDC trust policy."
  type        = string
  default     = "proyecto-trimestre2-itoyd"
}

# D5 — Observability
variable "notification_email" {
  description = "Email address for SNS alarm notifications."
  type        = string
  default     = "admin@sportspace.com"
}

variable "monthly_budget_usd" {
  description = "Monthly cost budget limit in USD."
  type        = number
  default     = 50
}

variable "log_retention_days" {
  description = "Number of days to retain CloudWatch log group data."
  type        = number
  default     = 14
}

variable "alarm_error_threshold" {
  description = "Threshold for API 5XX error count alarm."
  type        = number
  default     = 5
}

variable "alarm_evaluation_periods" {
  description = "Number of evaluation periods for metric alarms."
  type        = number
  default     = 2
}

variable "alarm_period_seconds" {
  description = "Period in seconds for metric alarm evaluation."
  type        = number
  default     = 300
}

# D5 — TLS
variable "ssl_policy" {
  description = "SSL security policy for CloudFront and API Gateway."
  type        = string
  default     = "TLSv1.2_2021"
}

variable "enable_cloudfront" {
  description = "Enable CloudFront distribution for HTTP→HTTPS redirect. Requires AWS account verification."
  type        = bool
  default     = false
}

variable "redirect_http_to_https" {
  description = "Enable HTTP to HTTPS redirect for public endpoints."
  type        = bool
  default     = true
}
