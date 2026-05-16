variable "project_name" {
  description = "Name of the project. Used for naming the remote state bucket and lock table."
  type        = string
}

variable "region" {
  description = "AWS region where the remote state bucket and lock table will be created."
  type        = string
  default     = "us-east-1"
}
