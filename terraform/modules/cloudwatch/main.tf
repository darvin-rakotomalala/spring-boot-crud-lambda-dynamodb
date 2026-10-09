############################################
# CLOUDWATCH LOG GROUPS (all KMS-encrypted)
############################################

# 1) Lambda function logs (platform + function output; wired in via logging_config)
resource "aws_cloudwatch_log_group" "lambda_function" {
  name              = var.lambda_log_group_name
  retention_in_days = var.log_retention_days
  kms_key_id        = var.kms_cloudwatch_key_arn

  tags = merge(var.common_tags, {
    Name = "${var.naming_prefix}-lambda-function-logs"
  })
}

# 2) Spring Boot application logs.
# The function's stdout goes to the group above; to land application logs here the app must write to it
# (APP_LOG_GROUP_NAME env var + a CloudWatch appender), or add a subscription filter from group 1.
resource "aws_cloudwatch_log_group" "app" {
  name              = var.app_log_group_name
  retention_in_days = var.log_retention_days
  kms_key_id        = var.kms_cloudwatch_key_arn

  tags = merge(var.common_tags, {
    Name = "${var.naming_prefix}-springboot-app-logs"
  })
}

# 3) API Gateway access logs
resource "aws_cloudwatch_log_group" "api_gateway" {
  name              = var.api_log_group_name
  retention_in_days = var.log_retention_days
  kms_key_id        = var.kms_cloudwatch_key_arn

  tags = merge(var.common_tags, {
    Name = "${var.naming_prefix}-apigateway-logs"
  })
}

############################################
# METRIC FILTERS
############################################

locals {
  lambda_log_filters = {
    timeout = {
      pattern = "\"Task timed out after\""
      metric  = "LambdaTimeouts"
    }
    oom_structured = {
      pattern = "{ $.status = \"OOM\" || $.message = \"*Out of memory*\" }"
      metric  = "LambdaOutOfMemory"
    }
    # Java managed runtime prints the exception rather than structured JSON
    oom_java = {
      pattern = "?\"OutOfMemoryError\" ?\"signal: killed\""
      metric  = "LambdaOutOfMemory"
    }
    code_exceptions = {
      pattern = "?\"ERROR\" ?\"Error\" ?\"Exception\" ?\"Unhandled\" ?\"panic\""
      metric  = "LambdaCodeExceptions"
    }
    # REPORT lines carry "Init Duration" on a cold start...
    cold_start = {
      pattern = "\"REPORT\" \"Init Duration\""
      metric  = "LambdaColdStarts"
    }
    # ...but SnapStart-enabled published versions report "Restore Duration" instead
    snapstart_restore = {
      pattern = "\"REPORT\" \"Restore Duration\""
      metric  = "LambdaSnapStartRestores"
    }
  }

  app_log_filters = {
    errors = {
      pattern = "\"ERROR\""
      metric  = "AppErrors"
    }
    warnings = {
      pattern = "?\"WARN\" ?\"WARNING\""
      metric  = "AppWarnings"
    }
  }

  api_log_filters = {
    http_5xx = {
      pattern = "{ $.status >= 500 }"
      metric  = "Api5xxResponses"
    }
    http_4xx = {
      pattern = "{ $.status >= 400 && $.status < 500 }"
      metric  = "Api4xxResponses"
    }
    throttled = {
      pattern = "{ $.status = 429 }"
      metric  = "ApiThrottled"
    }
    severe_backend_delay = {
      pattern = "{ $.responseLatency > ${var.alarm_thresholds.api_severe_backend_delay_ms} }"
      metric  = "ApiSevereBackendDelay"
    }
  }
}

resource "aws_cloudwatch_log_metric_filter" "lambda" {
  for_each       = local.lambda_log_filters
  name           = "${var.naming_prefix}-lambda-${replace(each.key, "_", "-")}"
  log_group_name = aws_cloudwatch_log_group.lambda_function.name
  pattern        = each.value.pattern

  metric_transformation {
    name          = each.value.metric
    namespace     = var.data_lambda_metric_namespace
    value         = "1"
    default_value = "0"
    unit          = "Count"
  }
}

resource "aws_cloudwatch_log_metric_filter" "app" {
  for_each       = local.app_log_filters
  name           = "${var.naming_prefix}-app-${each.key}"
  log_group_name = aws_cloudwatch_log_group.app.name
  pattern        = each.value.pattern

  metric_transformation {
    name          = each.value.metric
    namespace     = var.data_app_metric_namespace
    value         = "1"
    default_value = "0"
    unit          = "Count"
  }
}

resource "aws_cloudwatch_log_metric_filter" "api" {
  for_each       = local.api_log_filters
  name           = "${var.naming_prefix}-api-${replace(each.key, "_", "-")}"
  log_group_name = aws_cloudwatch_log_group.api_gateway.name
  pattern        = each.value.pattern

  metric_transformation {
    name          = each.value.metric
    namespace     = var.data_api_metric_namespace
    value         = "1"
    default_value = "0"
    unit          = "Count"
  }
}

# Per-endpoint 4xx / 5xx (the API is a {proxy+} catch-all, so the real path comes from the access log)
resource "aws_cloudwatch_log_metric_filter" "api_endpoint_5xx" {
  for_each       = var.monitored_endpoints
  name           = "${var.naming_prefix}-api-5xx-${each.key}"
  log_group_name = aws_cloudwatch_log_group.api_gateway.name
  pattern        = "{ $.status >= 500 && $.path = \"/${var.api_stage_name}${each.value}\" }"

  metric_transformation {
    name          = "Api5xx_${each.key}"
    namespace     = var.data_api_metric_namespace
    value         = "1"
    default_value = "0"
    unit          = "Count"
  }
}

resource "aws_cloudwatch_log_metric_filter" "api_endpoint_4xx" {
  for_each       = var.monitored_endpoints
  name           = "${var.naming_prefix}-api-4xx-${each.key}"
  log_group_name = aws_cloudwatch_log_group.api_gateway.name
  pattern        = "{ $.status >= 400 && $.status < 500 && $.path = \"/${var.api_stage_name}${each.value}\" }"

  metric_transformation {
    name          = "Api4xx_${each.key}"
    namespace     = var.data_api_metric_namespace
    value         = "1"
    default_value = "0"
    unit          = "Count"
  }
}

############################################
# LOGS INSIGHTS QUERIES (ad-hoc drill-down by path)
############################################

resource "aws_cloudwatch_query_definition" "api_errors_by_path" {
  name            = "${var.naming_prefix}/api-errors-by-path"
  log_group_names = [aws_cloudwatch_log_group.api_gateway.name]

  query_string = <<-EOQ
    fields @timestamp, httpMethod, path, status
    | filter status >= 400
    | stats count(*) as errors by path, status
    | sort errors desc
    | limit 50
  EOQ
}

resource "aws_cloudwatch_query_definition" "api_slow_backend" {
  name            = "${var.naming_prefix}/api-slow-backend-requests"
  log_group_names = [aws_cloudwatch_log_group.api_gateway.name]

  query_string = <<-EOQ
    fields @timestamp, httpMethod, path, status, integrationLatency, responseLatency
    | filter responseLatency > ${var.alarm_thresholds.api_severe_backend_delay_ms}
    | sort responseLatency desc
    | limit 50
  EOQ
}
