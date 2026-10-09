############################################
# MAIN OUTPUTS
############################################

output "iam_role_terraform_execution_arn" {
  description = "IAM role terraform execution ARN"
  value       = module.iam.iam_role_terraform_execution_arn
}

output "lambda_function_name" {
  description = "Name of the deployed Lambda function"
  value       = module.lambda.lambda_function_name
}

output "lambda_function_arn" {
  description = "ARN of the deployed Lambda function"
  value       = module.lambda.lambda_function_arn
}

output "lambda_function_version" {
  description = "Published version of the Lambda function (SnapStart applies to this version)"
  value       = module.lambda.lambda_function_version
}

output "lambda_alias_arn" {
  description = "ARN of the Lambda alias used by API Gateway"
  value       = module.lambda.lambda_alias_arn
}

output "lambda_cloudwatch_log_group" {
  description = "CloudWatch Log group for the Lambda function"
  value       = module.cloudwatch.log_group_names
}

output "api_gateway_id" {
  description = "ID of the API Gateway REST API"
  value       = module.api-gateway.api_gateway_id
}

output "api_invoke_url" {
  description = "Base invoke URL for the deployed API Gateway dev stage"
  value       = module.api-gateway.api_invoke_url
}

output "table_name" {
  description = "Name of the created DynamoDB table"
  value       = module.dynamodb.dynamodb_table_name
}

output "dynamodb_endpoint_url" {
  description = "Endpoint URL the Spring Boot app should point to. Empty string means use real AWS regional endpoint."
  value       = module.dynamodb.dynamodb_endpoint_url
}

output "dynamodb_kms_key_arn" {
  description = "The ARN of the DynamoDB KMS key."
  value       = module.kms.dynamodb_kms_key_arn
}

output "dynamodb_kms_key_alias_name" {
  description = "The alias name assigned to the DynamoDB KMS key."
  value       = module.kms.dynamodb_kms_key_alias_name
}
