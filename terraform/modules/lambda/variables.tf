############################################
# LAMBDA - VARIABLES
############################################

variable "naming_prefix" {
  description = "Naming prefix"
  type        = string
}

variable "common_tags" {}

variable "function_name" {
  description = "Name of the Lambda function"
  type        = string
}

# variable "lambda_zip_path" {
#   description = "Path to the built Spring Boot Lambda deployment package (.zip)"
#   type        = string
# }

variable "lambda_handler" {
  description = "Fully qualified Lambda handler method"
  type        = string
}

variable "lambda_runtime" {
  description = "Lambda runtime identifier"
  type        = string
}

variable "lambda_architecture" {
  description = "Lambda instruction set architecture. Must be x86_64 - SnapStart does not support arm64."
  type        = string
}

variable "lambda_memory_size" {
  description = "Amount of memory (MB) allocated to the Lambda function"
  type        = number
}

variable "lambda_timeout" {
  description = "Lambda function timeout in seconds"
  type        = number
}

variable "lambda_alias_name" {
  description = "Name of the Lambda alias used for the published version"
  type        = string
}

variable "log_retention_days" {
  description = "CloudWatch Logs retention period in days"
  type        = number
}

variable "api_stage_name" {
  description = "Name of the API Gateway deployment stage"
  type        = string
}

variable "lambda_exec_role_arn" {
  description = "Lambda execution role ARN."
  type        = string
}

variable "policy_lambda_basic_execution" {
  description = "IAM policy for Lambda basic execution ARN"
  type        = string
}

variable "api_lambda_api_execution_arn" {
  description = "REST API Gateway for Lambda execution ARN"
  type        = string
}

variable "lambda_description" {
  description = "Lambda function description."
  type        = string
}

variable "lambda_reserved_concurrency" {
  description = "Reserved concurrency for the function. -1 = unreserved (shares the account pool). Set a value to cap blast radius / protect DynamoDB."
  type        = number
}

variable "lambda_tracing_mode" {
  description = "X-Ray tracing mode for Lambda: Active or PassThrough."
  type        = string

  validation {
    condition     = contains(["Active", "PassThrough"], var.lambda_tracing_mode)
    error_message = "lambda_tracing_mode must be Active or PassThrough."
  }
}

variable "lambda_environment" {
  description = "Extra environment variables for the function (merged over the defaults in lambda.tf)."
  type        = map(string)
}

variable "log_group_lambda_function_names" {
  description = "CloudWatch log groups for Lambda function."
  type        = string
}

variable "dynamodb_table_name" {
  description = "DynamoDB table name."
  type        = string
}

variable "log_group_app_names" {
  description = "CloudWatch log groups for App."
  type        = string
}

variable "lambda_app_policy_id" {
  description = "ID of the inline application policy (<role-name>:<policy-name>)"
  type        = string
}

variable "dynamodb_table_arn" {
  description = "DynamoDB table ARN."
  type        = string
}
