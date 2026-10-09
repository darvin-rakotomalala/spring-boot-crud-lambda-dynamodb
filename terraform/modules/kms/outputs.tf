############################################
# KMS - OUTPUTS
############################################

output "dynamodb_kms_key_id" {
  description = "The globally unique identifier (key ID) for the DynamoDB KMS key."
  value       = aws_kms_key.dynamodb.key_id
}

output "dynamodb_kms_key_arn" {
  description = "The ARN of the DynamoDB KMS key."
  value       = aws_kms_key.dynamodb.arn
}

output "dynamodb_kms_key_alias_name" {
  description = "The alias name assigned to the DynamoDB KMS key."
  value       = aws_kms_alias.dynamodb.name
}

output "dynamodb_kms_key_alias_arn" {
  description = "The ARN of the alias for the DynamoDB KMS key."
  value       = aws_kms_alias.dynamodb.arn
}

output "kms_cloudwatch_key_arn" {
  description = "CMK used for CloudWatch Logs and SNS."
  value       = aws_kms_key.cloudwatch.arn
}
