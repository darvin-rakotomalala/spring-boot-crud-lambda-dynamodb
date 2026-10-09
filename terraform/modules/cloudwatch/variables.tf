############################################
# CLOUDWATCH - VARIABLES
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

variable "kms_cloudwatch_key_arn" {
  description = "ARN of the KMS key used for CloudWatch Logs / SNS encryption"
  type        = string
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

############################################
# CLOUDWATCH LOGS
############################################

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

variable "log_retention_days" {
  description = "Retention for all log groups."
  type        = number

  validation {
    condition     = contains([1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1096, 1827, 2192, 2557, 2922, 3288, 3653], var.log_retention_days)
    error_message = "log_retention_days must be a value CloudWatch Logs accepts (e.g. 30, 90, 365)."
  }
}

variable "monitored_endpoints" {
  description = "Endpoints to track separately (4xx/5xx metric filters + 5xx alarm). Map of short key => path relative to the stage; trailing * wildcard allowed. Keep this small and low-cardinality."
  type        = map(string)
}

variable "data_lambda_metric_namespace" {
  description = "Name of the Lambda function"
  type        = string
}

variable "data_app_metric_namespace" {
  description = "Name of the Lambda function"
  type        = string
}

variable "data_api_metric_namespace" {
  description = "Name of the Lambda function"
  type        = string
}

variable "api_stage_name" {
  description = "Stage name."
  type        = string
}

variable "lambda_function_name" {
  description = "Name of the deployed Lambda function"
  type        = string
}

variable "java_lambda_api_name" {
  description = "Name of the API Gateway REST API"
  type        = string
}

variable "java_lambda_api_stage_name" {
  description = "Name of the API Gateway stage"
  type        = string
}

variable "lambda_timeout" {
  description = "Lambda timeout in seconds."
  type        = number
}

variable "data_lambda_concurrency_alarm_threshold" {
  description = "Lambda concurrency alarm threshold."
  type        = number
}

variable "dynamodb_table_name" {
  description = "DynamoDB table name."
  type        = string
}

variable "sns_topic_arns" {
  description = "SNS alert topic ARNs keyed by severity."
  type        = map(string)
}
