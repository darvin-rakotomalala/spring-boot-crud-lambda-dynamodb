############################################
# DYNAMODB OUTPUTS
############################################

output "dynamodb_endpoint_url" {
  description = "Endpoint URL the Spring Boot app should point to. Empty string means use real AWS regional endpoint."
  value       = var.dynamodb_endpoint != "" ? var.dynamodb_endpoint : "https://dynamodb.${var.aws_region}.amazonaws.com"
}

output "dynamodb_table_name" {
  description = "DynamoDB table name."
  value       = aws_dynamodb_table.users.name
}

output "dynamodb_table_arn" {
  description = "DynamoDB table ARN."
  value       = aws_dynamodb_table.users.arn
}
