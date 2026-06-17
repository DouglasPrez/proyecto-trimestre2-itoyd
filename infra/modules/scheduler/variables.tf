variable "schedule_expression" {
  description = "Cron or rate expression for the EventBridge Scheduler (e.g. cron(0 6 * * ? *))."
  type        = string
}

variable "target_lambda_arn" {
  description = "ARN of the Lambda function to invoke on schedule."
  type        = string
}

variable "scheduler_timezone" {
  description = "Timezone for the scheduler expression (e.g. America/Guatemala)."
  type        = string
}

variable "environment" {
  description = "Deployment environment name. Used for naming."
  type        = string
}

variable "project_name" {
  description = "Name of the project. Used for naming and tagging."
  type        = string
}
