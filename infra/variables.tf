variable "environment" {
  description = "Deployment environment name (e.g. dev, staging, prod)."
  type        = string
}

variable "project_name" {
  description = "Name of the project. Used for naming and tagging resources."
  type        = string
}

variable "region" {
  description = "AWS region where resources will be deployed."
  type        = string
}

variable "bucket_name" {
  description = "Name of the S3 bucket to create. Must be globally unique."
  type        = string
}
