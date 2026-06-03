variable "api_name" {
  description = "Name for the HTTP API Gateway resource."
  type        = string
  default     = "sportspace-api"
}

variable "lambda_invoke_arn" {
  description = "Invoke ARN of the Lambda function to integrate with API Gateway."
  type        = string
}

variable "health_check_path" {
  description = "Path used for health and readiness checks."
  type        = string
  default     = "/"
}

variable "stage_name" {
  description = "API Gateway stage name (e.g. dev)."
  type        = string
  default     = "dev"
}

variable "environment" {
  description = "Deployment environment name. Used for tagging."
  type        = string
  default     = "dev"
}

variable "project_name" {
  description = "Name of the project. Used for naming and tagging resources."
  type        = string
}
