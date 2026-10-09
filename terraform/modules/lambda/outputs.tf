############################################
# LAMBDA - OUTPUTS
############################################

output "lambda_function_name" {
  description = "Name of the deployed Lambda function"
  value       = aws_lambda_function.hello_lambda.function_name
}

output "lambda_function_arn" {
  description = "ARN of the deployed Lambda function"
  value       = aws_lambda_function.hello_lambda.arn
}

output "lambda_function_version" {
  description = "Published version of the Lambda function (SnapStart applies to this version)"
  value       = aws_lambda_function.hello_lambda.version
}

output "lambda_alias_arn" {
  description = "ARN of the Lambda alias used by API Gateway"
  value       = aws_lambda_alias.lambda_dev.arn
}

output "lambda_published_version" {
  description = "Latest published (SnapStart) version."
  value       = aws_lambda_function.hello_lambda.version
}

output "lambda_dev_alias_invoke_arn" {
  description = "Invoke ARN of the Lambda alias (use as the API Gateway integration uri)"
  value       = aws_lambda_alias.lambda_dev.invoke_arn
}
