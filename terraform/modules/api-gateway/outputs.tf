############################################
# API GATEWAY - OUTPUTS
############################################

output "api_gateway_id" {
  description = "ID of the API Gateway REST API"
  value       = aws_api_gateway_rest_api.java_lambda_api.id
}

output "api_invoke_url" {
  description = "Base invoke URL for the deployed API Gateway dev stage"
  value       = aws_api_gateway_stage.dev.invoke_url
}

output "api_lambda_api_execution_arn" {
  description = "REST API Gateway for Lambda execution ARN"
  value       = aws_api_gateway_rest_api.java_lambda_api.execution_arn
}

output "api_id" {
  description = "REST API ID."
  value       = aws_api_gateway_rest_api.java_lambda_api.id
}

output "java_lambda_api_name" {
  description = "Name of the API Gateway REST API"
  value       = aws_api_gateway_rest_api.java_lambda_api.name
}

output "java_lambda_api_stage_name" {
  description = "Name of the API Gateway stage"
  value       = aws_api_gateway_stage.dev.stage_name
}
