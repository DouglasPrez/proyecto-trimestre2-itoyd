output "table_name" {
  description = "Name of the DynamoDB reservas table."
  value       = aws_dynamodb_table.reservas.name
}

output "table_arn" {
  description = "ARN of the DynamoDB reservas table."
  value       = aws_dynamodb_table.reservas.arn
}

output "table_id" {
  description = "ID of the DynamoDB reservas table."
  value       = aws_dynamodb_table.reservas.id
}
