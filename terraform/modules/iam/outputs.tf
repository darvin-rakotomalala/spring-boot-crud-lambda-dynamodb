############################################
# IAM - OUTPUTS
############################################

output "iam_role_terraform_execution_arn" {
  description = "IAM role terraform execution ARN (null if create_github_actions_role = false)"
  value       = one(aws_iam_role.terraform_execution[*].arn)
}

output "lambda_exec_role_arn" {
  description = "Lambda execution role ARN."
  value       = aws_iam_role.lambda_exec.arn
}

output "policy_lambda_basic_execution" {
  description = "IAM policy for Lambda basic execution ARN"
  value       = aws_iam_role_policy_attachment.lambda_basic_execution.id
}

output "lambda_app_policy_id" {
  description = "ID of the inline application policy (<role-name>:<policy-name>)"
  value       = aws_iam_role_policy.lambda_app.id
}

output "api_gateway_account_cloudwatch_role_arn" {
  description = "CloudWatch role ARN configured on the API Gateway account (null when not managed)"
  value       = one(aws_api_gateway_account.this[*].cloudwatch_role_arn)
}
