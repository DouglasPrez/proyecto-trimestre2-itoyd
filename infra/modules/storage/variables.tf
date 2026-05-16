variable "environment" {
  description = "Deployment environment name (e.g. dev, staging, prod)."
  type        = string
}

variable "bucket_name" {
  description = "Base name for the S3 storage bucket. A suffix with environment will be appended."
  type        = string
}

variable "project_name" {
  description = "Name of the project. Used for tagging resources."
  type        = string
}

variable "lifecycle_prefix" {
  description = "Object key prefix to which the lifecycle rule applies (e.g. 'vouchers/' for reservation PDFs)."
  type        = string
  default     = "vouchers/"
}

variable "transition_days" {
  description = "Number of days after which objects under lifecycle_prefix transition to STANDARD_IA storage."
  type        = number
  default     = 30
}

variable "noncurrent_expiration_days" {
  description = "Number of days after which non-current object versions are permanently deleted."
  type        = number
  default     = 90
}
