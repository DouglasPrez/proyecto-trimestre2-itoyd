variable "queue_name_prefix" {
  description = "Prefix for the main SQS queue name."
  type        = string
}

variable "visibility_timeout_seconds" {
  description = "The visibility timeout for the main queue in seconds."
  type        = number
  default     = 30
}

variable "message_retention_seconds" {
  description = "The number of seconds Amazon SQS retains a message in the main queue."
  type        = number
  default     = 345600
}

variable "max_receive_count" {
  description = "Maximum number of times a message can be received before being sent to the DLQ."
  type        = number
  default     = 5
}

variable "dlq_message_retention_seconds" {
  description = "The number of seconds Amazon SQS retains a message in the dead-letter queue."
  type        = number
  default     = 1209600
}

variable "environment" {
  description = "Deployment environment name. Used for tagging."
  type        = string
}

variable "project_name" {
  description = "Name of the project. Used for tagging."
  type        = string
}
