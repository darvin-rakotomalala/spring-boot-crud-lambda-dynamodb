############################################
# API GATEWAY - VARIABLES
############################################

variable "naming_prefix" {
  description = "Naming prefix"
  type        = string
}

variable "common_tags" {}

variable "api_name" {
  description = "Name of the API Gateway REST API"
  type        = string
}

variable "api_stage_name" {
  description = "Name of the API Gateway deployment stage"
  type        = string
}

variable "api_authorization_type" {
  description = "Method authorization: NONE (public!), AWS_IAM or COGNITO_USER_POOLS. NONE leaves the CRUD API open to the internet."
  type        = string

  validation {
    condition     = contains(["NONE", "AWS_IAM", "COGNITO_USER_POOLS"], var.api_authorization_type)
    error_message = "api_authorization_type must be NONE, AWS_IAM or COGNITO_USER_POOLS."
  }
}

variable "api_key_required" {
  description = "Require an API key (creates a key + usage plan). Useful for client identification and throttling; not a substitute for authN."
  type        = bool
}

variable "lambda_dev_alias_invoke_arn" {
  description = "Invoke ARN of the Lambda alias (use as the API Gateway integration uri)"
  type        = string
}

variable "log_group_api_gateway_arn" {
  description = "CloudWatch log groups for API Gateway ARN."
  type        = string
}

variable "api_execution_logging_level" {
  description = "API Gateway execution logging: OFF, ERROR or INFO. Execution logs go to an auto-created, unmanaged log group (not KMS encrypted, no retention) - access logs in our managed group are the primary record."
  type        = string

  validation {
    condition     = contains(["OFF", "ERROR", "INFO"], var.api_execution_logging_level)
    error_message = "api_execution_logging_level must be OFF, ERROR or INFO."
  }
}

variable "api_throttling_rate_limit" {
  description = "Steady-state requests/second allowed for all methods in the stage."
  type        = number
}

variable "api_throttling_burst_limit" {
  description = "Burst requests allowed for all methods in the stage."
  type        = number
}
