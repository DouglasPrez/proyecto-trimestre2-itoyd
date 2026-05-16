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
  description = "Memory in MB for the API Lambda function (128–10240)."
  type        = number
  default     = 128
}

variable "lambda_timeout" {
  description = "Timeout in seconds for the API Lambda function (1–900)."
  type        = number
  default     = 30
}
