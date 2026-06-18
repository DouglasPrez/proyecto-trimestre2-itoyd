variable "environment" {
  description = "Deployment environment name (e.g. dev, staging, prod)."
  type        = string
}

variable "project_name" {
  description = "Name of the project. Used for naming and tagging."
  type        = string
}

variable "api_lambda_function_name" {
  description = "Name of the API Lambda function. Used for log group and alarm dimensions."
  type        = string
}

variable "async_consumer_lambda_function_name" {
  description = "Name of the async consumer Lambda function. Used for log group and alarm dimensions."
  type        = string
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

variable "notification_email" {
  description = "Email address for SNS alarm notifications."
  type        = string
}

variable "monthly_budget_usd" {
  description = "Monthly cost budget limit in USD."
  type        = number
  default     = 50
}

variable "region" {
  description = "AWS region for dashboard metrics."
  type        = string
  default     = "us-east-1"
}

variable "api_endpoint_url" {
  description = "API Gateway endpoint URL for dashboard link."
  type        = string
  default     = ""
}
