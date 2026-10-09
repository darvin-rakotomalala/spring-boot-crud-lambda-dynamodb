############################################
# IAM - VARIABLES
############################################

variable "aws_region" {
  description = "AWS region to deploy into."
  type        = string
  default     = "us-east-1"
}

variable "naming_prefix" {
  description = "Naming prefix"
  type        = string
}

variable "common_tags" {}

variable "current_account_id" {
  description = "Current account ID"
  type        = string
}

variable "current_partition" {
  description = "Current partition account ID"
  type        = string
  # default = data.aws_partition.current.partition
}

variable "function_name" {
  description = "Name of the Lambda function"
  type        = string
}

############################################
# GITHUB ACTIONS (OIDC) - OPTIONAL
############################################

variable "create_github_actions_role" {
  description = "Create the IAM role assumed by GitHub Actions to run Terraform. Better bootstrapped in a separate stack."
  type        = bool
}

variable "create_github_oidc_provider" {
  description = "Create the GitHub OIDC provider. Set false if the account already has one (it is an account-wide singleton)."
  type        = bool
}

variable "github_org" {
  description = "GitHub organisation / user that owns the repo (exact name, no wildcards)."
  type        = string
}

variable "github_repo" {
  description = "GitHub repository name (exact, no wildcards)."
  type        = string
}

variable "dynamodb_table_arn" {
  type = string
  validation {
    condition     = can(regex("^arn:[^:]+:dynamodb:", var.dynamodb_table_arn))
    error_message = "dynamodb_table_arn must be a full DynamoDB table ARN."
  }
}

variable "dynamodb_kms_key_arn" {
  type = string
  validation {
    condition     = can(regex("^arn:[^:]+:kms:[^:]+:[0-9]{12}:key/", var.dynamodb_kms_key_arn))
    error_message = "dynamodb_kms_key_arn must be a KMS key ARN (not an alias or key ID)."
  }
}

variable "kms_cloudwatch_key_arn" {
  type = string
  validation {
    condition     = can(regex("^arn:[^:]+:kms:[^:]+:[0-9]{12}:key/", var.kms_cloudwatch_key_arn))
    error_message = "kms_cloudwatch_key_arn must be a KMS key ARN (not an alias or key ID)."
  }
}

variable "log_group_app_arn" {
  type = string
  validation {
    condition     = can(regex("^arn:[^:]+:logs:[^:]+:[0-9]{12}:log-group:", var.log_group_app_arn))
    error_message = "log_group_app_arn must be a CloudWatch log group ARN."
  }
}

variable "manage_api_gateway_account" {
  description = "Create the account-level CloudWatch role for API Gateway (aws_api_gateway_account is a per-region singleton). Set false if already configured elsewhere."
  type        = bool
}

variable "table_name" {
  description = "DynamoDB table name (matches @TableName on the entity)."
  type        = string
}

variable "lambda_log_group_name" {
  description = "Log group for the Lambda function (platform + function output)."
  type        = string
}

variable "app_log_group_name" {
  description = "Log group for the Spring Boot application logs."
  type        = string
}

variable "api_log_group_name" {
  description = "Log group for API Gateway access logs."
  type        = string
}
