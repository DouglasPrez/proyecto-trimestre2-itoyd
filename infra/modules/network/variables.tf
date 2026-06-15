variable "domain_name" {
  description = "Custom domain name for the SportSpace API (e.g. api.sportspace.example.com)."
  type        = string
}

variable "base_domain_name" {
  description = "Base Route53 domain zone (shared across environments)."
  type        = string
  default     = "grupo2.oyd.solid.com.gt"
}

variable "aws_region" {
  description = "AWS region where API Gateway is deployed. ACM certificate must be in the same region."
  type        = string
}

variable "api_gateway_id" {
  description = "ID of the HTTP API Gateway (from ingress module output)."
  type        = string
}

variable "api_gateway_stage_name" {
  description = "Name of the API Gateway stage to bind to the custom domain (e.g. dev)."
  type        = string
  default     = "dev"
}

variable "lambda_function_name" {
  description = "Name of the Lambda function for the aws_lambda_permission resource."
  type        = string
}

variable "api_gateway_execution_arn" {
  description = "Execution ARN of the API Gateway. Scopes the lambda:InvokeFunction permission to this API only."
  type        = string
}

variable "environment" {
  description = "Deployment environment name (e.g. dev, prod). Used for tagging."
  type        = string
  default     = "dev"
}

variable "project_name" {
  description = "Name of the project. Used for naming and tagging resources."
  type        = string
}
