############################################
# CLOUDWATCH - OUTPUTS
############################################

output "log_group_names" {
  description = "CloudWatch log groups."
  value = {
    lambda_function = aws_cloudwatch_log_group.lambda_function.name
    application     = aws_cloudwatch_log_group.app.name
    api_gateway     = aws_cloudwatch_log_group.api_gateway.name
  }
}

output "log_group_arns" {
  description = "CloudWatch log group ARNs."
  value = {
    lambda_function = aws_cloudwatch_log_group.lambda_function.arn
    application     = aws_cloudwatch_log_group.app.arn
    api_gateway     = aws_cloudwatch_log_group.api_gateway.arn
  }
}
