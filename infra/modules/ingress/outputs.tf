output "api_id" {
  description = "ID of the API Gateway HTTP API."
  value       = aws_apigatewayv2_api.sportspace.id
}

output "api_endpoint" {
  description = "Default public endpoint URL of the API Gateway stage."
  value       = aws_apigatewayv2_stage.default.invoke_url
}

output "execution_arn" {
  description = "Execution ARN of the API Gateway. Used in aws_lambda_permission source_arn."
  value       = aws_apigatewayv2_api.sportspace.execution_arn
}

output "stage_name" {
  description = "Name of the deployed API Gateway stage."
  value       = aws_apigatewayv2_stage.default.name
}
