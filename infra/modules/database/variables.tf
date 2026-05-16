variable "environment" {
  description = "Deployment environment name (e.g. dev, staging, prod)."
  type        = string
}

variable "project_name" {
  description = "Name of the project. Used for tagging resources."
  type        = string
}

variable "billing_mode" {
  description = "DynamoDB billing mode. PAY_PER_REQUEST for on-demand or PROVISIONED for fixed capacity."
  type        = string
  default     = "PAY_PER_REQUEST"
}

variable "ttl_attribute" {
  description = "Name of the attribute used for TTL (Time to Live) expiration on items."
  type        = string
  default     = "expires_at"
}
