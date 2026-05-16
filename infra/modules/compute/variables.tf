variable "environment" {
  description = "Deployment environment name (e.g. dev, staging, prod)."
  type        = string
}

variable "name" {
  description = "Base name for the Lambda function and related resources."
  type        = string
}

variable "memory_size" {
  description = "Amount of memory in MB allocated to the Lambda function (128–10240)."
  type        = number
  default     = 128
}

variable "timeout" {
  description = "Maximum execution time in seconds for the Lambda function (1–900)."
  type        = number
  default     = 30
}

variable "runtime" {
  description = "Lambda runtime identifier (e.g. python3.12, nodejs20.x, java21)."
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
