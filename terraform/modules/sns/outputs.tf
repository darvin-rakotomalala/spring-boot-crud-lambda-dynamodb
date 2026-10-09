############################################
# SNS - OUTPUTS
############################################

# Alarm severity -> SNS topic ARN
output "sns_topic_arns" {
  description = "SNS alert topics by severity."
  value       = { for severity, topic in aws_sns_topic.alerts : severity => topic.arn }
}
