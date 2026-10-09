############################################
# MAIN VARIABLES
############################################

variable "primary_region" {
  description = "Primary region"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "project_name" {
  description = "Project name"
  type        = string
}

variable "team_name" {
  description = "Team name"
  type        = string
}

variable "cost_center" {
  description = "Cost center"
  type        = string
}

variable "compliance" {
  description = "Compliance"
  type        = string
}

variable "bucket_name" {
  description = "Bucket name"
  type        = string
}

variable "github_org" {
  description = "GitHub organization"
  type        = string
}

variable "github_repo" {
  description = "GitHub repository"
  type        = string
}

variable "function_name" {
  description = "Name of the Lambda function"
  type        = string
}

variable "lambda_zip_path" {
  description = "Path to the built Spring Boot Lambda deployment package (.zip)"
  type        = string
}

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

variable "api_name" {
  description = "Name of the API Gateway REST API"
  type        = string
}

variable "api_stage_name" {
  description = "Name of the API Gateway deployment stage"
  type        = string
}

variable "table_name" {
  description = "DynamoDB table name, must match @TableName on the User entity"
  type        = string
}

variable "enable_point_in_time_recovery" {
  description = "Enable PITR backups on the table"
  type        = bool
}

variable "dynamodb_endpoint" {
  description = "Custom DynamoDB endpoint URL (e.g. http://localhost:8000 for local dev with DynamoDB Local). Leave empty to use real AWS."
  type        = string
}

variable "enable_deletion_protection" {
  type = bool
}

variable "max_read_request_units" {
  type = number
}

variable "max_write_request_units" {
  type = number
}

variable "kms_deletion_window_in_days" {
  type        = number
  description = "Waiting period before the KMS key is deleted after being scheduled for deletion (7-30 days)."
}

variable "lambda_reserved_concurrency" {
  description = "Reserved concurrency for the function. -1 = unreserved (shares the account pool). Set a value to cap blast radius / protect DynamoDB."
  type        = number
}

variable "alarm_thresholds" {
  description = "Alarm thresholds. Override only the ones you want to change."
  type = object({
    lambda_errors                = optional(number, 5)    # Errors per 5 min
    lambda_throttles             = optional(number, 1)    # Throttles per 5 min
    lambda_duration_ratio        = optional(number, 0.8)  # p95 duration as a fraction of the timeout
    lambda_concurrency_ratio     = optional(number, 0.8)  # fraction of reserved concurrency
    account_concurrency          = optional(number, 800)  # ~80% of the default 1000 account limit - adjust to your quota
    lambda_exceptions_logged     = optional(number, 5)    # matching log lines per 5 min
    app_errors_logged            = optional(number, 10)   # ERROR lines per 5 min
    api_5xx_per_minute           = optional(number, 5)    # CRITICAL
    api_4xx_per_minute           = optional(number, 50)   # WARNING
    api_5xx_rate_percent         = optional(number, 5)    # CRITICAL
    api_4xx_rate_percent         = optional(number, 25)   # WARNING
    api_min_requests_for_rate    = optional(number, 20)   # ignore error-rate when traffic is below this per minute
    api_latency_ms               = optional(number, 3000) # p95 overall latency
    api_integration_latency_ms   = optional(number, 2500) # p95 backend latency
    api_severe_backend_delay_ms  = optional(number, 5000) # a request slower than this (responseLatency) counts as "severe"
    api_severe_backend_delay_cnt = optional(number, 3)    # severe requests per 5 min
    api_throttled_per_5min       = optional(number, 5)    # HTTP 429 responses per 5 min
    dynamodb_throttle_events     = optional(number, 5)    # read / write throttle events per 5 min
  })
  default = {}
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

variable "lambda_description" {
  description = "Lambda function description."
  type        = string
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

variable "alert_subscriptions" {
  description = <<-EOT
    SNS alert subscriptions, keyed by a unique static name.
    Example:
      alert_subscriptions = {
        critical-oncall-email = { topic = "critical", protocol = "email", endpoint = "oncall@example.com" }
        critical-pagerduty    = { topic = "critical", protocol = "https", endpoint = "https://events.pagerduty.com/integration/XXXX/enqueue" }
        warning-team-email    = { topic = "warning",  protocol = "email", endpoint = "team@example.com" }
      }
  EOT
  type = map(object({
    topic    = string
    protocol = string
    endpoint = string
  }))
  default = {}

  validation {
    condition     = alltrue([for s in values(var.alert_subscriptions) : contains(["critical", "warning"], s.topic)])
    error_message = "Each subscription's topic must be \"critical\" or \"warning\"."
  }

  validation {
    condition     = alltrue([for s in values(var.alert_subscriptions) : contains(["email", "https"], s.protocol)])
    error_message = "Each subscription's protocol must be \"email\" or \"https\"."
  }
}

variable "create_github_actions_role" {
  description = "Create the IAM role assumed by GitHub Actions to run Terraform. Better bootstrapped in a separate stack."
  type        = bool
}

variable "create_github_oidc_provider" {
  description = "Create the GitHub OIDC provider. Set false if the account already has one (it is an account-wide singleton)."
  type        = bool
}

variable "manage_api_gateway_account" {
  description = "Create the account-level CloudWatch role for API Gateway (aws_api_gateway_account is a per-region singleton). Set false if already configured elsewhere."
  type        = bool
}

variable "monitored_endpoints" {
  description = "Endpoints to track separately (4xx/5xx metric filters + 5xx alarm). Map of short key => path relative to the stage; trailing * wildcard allowed. Keep this small and low-cardinality."
  type        = map(string)
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

