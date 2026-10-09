############################################
# CLOUDWATCH ALARMS
#   severity "critical" -> SNS critical topic (PagerDuty / OpsGenie)
#   severity "warning"  -> SNS warning topic  (Slack / email)
############################################

locals {
  lambda_dimensions = {
    FunctionName = var.lambda_function_name
  }

  api_dimensions = {
    ApiName = var.java_lambda_api_name
    Stage   = var.java_lambda_api_stage_name
  }

  base_alarms = {
    ############ Lambda (AWS/Lambda metrics) ############
    lambda_errors = {
      description        = "Lambda invocation errors (code exceptions, crashes, timeouts) at or above threshold."
      namespace          = "AWS/Lambda"
      metric_name        = "Errors"
      dimensions         = local.lambda_dimensions
      statistic          = "Sum"
      period             = 300
      evaluation_periods = 1
      threshold          = var.alarm_thresholds.lambda_errors
      severity           = "critical"
    }
    lambda_throttles = {
      description        = "Lambda throttling - function or account concurrency limit reached."
      namespace          = "AWS/Lambda"
      metric_name        = "Throttles"
      dimensions         = local.lambda_dimensions
      statistic          = "Sum"
      period             = 300
      evaluation_periods = 1
      threshold          = var.alarm_thresholds.lambda_throttles
      severity           = "warning"
    }
    lambda_duration_p95 = {
      description         = "Lambda p95 duration is approaching the configured timeout (performance bottleneck / imminent timeouts)."
      namespace           = "AWS/Lambda"
      metric_name         = "Duration"
      dimensions          = local.lambda_dimensions
      extended_statistic  = "p95"
      period              = 300
      evaluation_periods  = 3
      datapoints_to_alarm = 2
      threshold           = floor(var.lambda_timeout * 1000 * var.alarm_thresholds.lambda_duration_ratio)
      severity            = "warning"
    }
    lambda_concurrency = {
      description         = "Lambda concurrent executions approaching the reserved (or account) concurrency limit."
      namespace           = "AWS/Lambda"
      metric_name         = "ConcurrentExecutions"
      dimensions          = local.lambda_dimensions
      statistic           = "Maximum"
      period              = 60
      evaluation_periods  = 3
      datapoints_to_alarm = 2
      threshold           = var.data_lambda_concurrency_alarm_threshold
      severity            = "warning"
    }
    lambda_account_concurrency = {
      description         = "Account-wide Lambda concurrency approaching the regional limit - risk of throttling for every function."
      namespace           = "AWS/Lambda"
      metric_name         = "ClaimedAccountConcurrency"
      dimensions          = {}
      statistic           = "Maximum"
      period              = 60
      evaluation_periods  = 3
      datapoints_to_alarm = 2
      threshold           = var.alarm_thresholds.account_concurrency
      severity            = "warning"
    }

    ############ Lambda (log metric filters) ############
    lambda_timeouts = {
      description        = "Function timeouts: 'Task timed out after' found in logs."
      namespace          = var.data_lambda_metric_namespace
      metric_name        = "LambdaTimeouts"
      dimensions         = {}
      statistic          = "Sum"
      period             = 300
      evaluation_periods = 1
      threshold          = 1
      severity           = "critical"
    }
    lambda_out_of_memory = {
      description        = "Out-of-memory errors detected in function logs."
      namespace          = var.data_lambda_metric_namespace
      metric_name        = "LambdaOutOfMemory"
      dimensions         = {}
      statistic          = "Sum"
      period             = 300
      evaluation_periods = 1
      threshold          = 1
      severity           = "critical"
    }
    lambda_code_exceptions = {
      description        = "Unhandled exceptions / errors / panics found in function logs."
      namespace          = var.data_lambda_metric_namespace
      metric_name        = "LambdaCodeExceptions"
      dimensions         = {}
      statistic          = "Sum"
      period             = 300
      evaluation_periods = 1
      threshold          = var.alarm_thresholds.lambda_exceptions_logged
      severity           = "warning"
    }

    ############ Spring Boot application log group ############
    app_errors = {
      description        = "Spring Boot application is logging ERROR lines above threshold."
      namespace          = var.data_app_metric_namespace
      metric_name        = "AppErrors"
      dimensions         = {}
      statistic          = "Sum"
      period             = 300
      evaluation_periods = 1
      threshold          = var.alarm_thresholds.app_errors_logged
      severity           = "warning"
    }

    ############ API Gateway (AWS/ApiGateway metrics) ############
    api_5xx_errors = {
      description         = "CRITICAL: API Gateway 5XX errors per minute above threshold (page on-call)."
      namespace           = "AWS/ApiGateway"
      metric_name         = "5XXError"
      dimensions          = local.api_dimensions
      statistic           = "Sum"
      period              = 60
      evaluation_periods  = 3
      datapoints_to_alarm = 2
      threshold           = var.alarm_thresholds.api_5xx_per_minute
      severity            = "critical"
    }
    api_4xx_errors = {
      description         = "WARNING: spike in API Gateway 4XX client errors per minute."
      namespace           = "AWS/ApiGateway"
      metric_name         = "4XXError"
      dimensions          = local.api_dimensions
      statistic           = "Sum"
      period              = 60
      evaluation_periods  = 5
      datapoints_to_alarm = 3
      threshold           = var.alarm_thresholds.api_4xx_per_minute
      severity            = "warning"
    }
    api_latency_p95 = {
      description         = "WARNING: high overall API latency (p95) - API bottleneck."
      namespace           = "AWS/ApiGateway"
      metric_name         = "Latency"
      dimensions          = local.api_dimensions
      extended_statistic  = "p95"
      period              = 300
      evaluation_periods  = 2
      datapoints_to_alarm = 2
      threshold           = var.alarm_thresholds.api_latency_ms
      severity            = "warning"
    }
    api_integration_latency_p95 = {
      description         = "WARNING: high integration latency (p95) - backend dependency issue (Lambda / DynamoDB)."
      namespace           = "AWS/ApiGateway"
      metric_name         = "IntegrationLatency"
      dimensions          = local.api_dimensions
      extended_statistic  = "p95"
      period              = 300
      evaluation_periods  = 2
      datapoints_to_alarm = 2
      threshold           = var.alarm_thresholds.api_integration_latency_ms
      severity            = "warning"
    }

    ############ DynamoDB (on-demand max throughput can throttle) ############
    dynamodb_read_throttles = {
      description        = "DynamoDB read throttling - the on-demand max read request units (or a hot partition) is being hit."
      namespace          = "AWS/DynamoDB"
      metric_name        = "ReadThrottleEvents"
      dimensions         = { TableName = var.dynamodb_table_name }
      statistic          = "Sum"
      period             = 300
      evaluation_periods = 1
      threshold          = var.alarm_thresholds.dynamodb_throttle_events
      severity           = "warning"
    }
    dynamodb_write_throttles = {
      description        = "DynamoDB write throttling - the on-demand max write request units (or a hot partition) is being hit."
      namespace          = "AWS/DynamoDB"
      metric_name        = "WriteThrottleEvents"
      dimensions         = { TableName = var.dynamodb_table_name }
      statistic          = "Sum"
      period             = 300
      evaluation_periods = 1
      threshold          = var.alarm_thresholds.dynamodb_throttle_events
      severity           = "warning"
    }

    ############ API Gateway (access-log metric filters) ############
    api_throttling = {
      description        = "WARNING: API Gateway is returning HTTP 429 - quotas or concurrency limits reached."
      namespace          = var.data_api_metric_namespace
      metric_name        = "ApiThrottled"
      dimensions         = {}
      statistic          = "Sum"
      period             = 300
      evaluation_periods = 1
      threshold          = var.alarm_thresholds.api_throttled_per_5min
      severity           = "warning"
    }
    api_severe_backend_delay = {
      description        = "WARNING: requests with severe latency (backend delay, response latency above ${var.alarm_thresholds.api_severe_backend_delay_ms} ms)."
      namespace          = var.data_api_metric_namespace
      metric_name        = "ApiSevereBackendDelay"
      dimensions         = {}
      statistic          = "Sum"
      period             = 300
      evaluation_periods = 1
      threshold          = var.alarm_thresholds.api_severe_backend_delay_cnt
      severity           = "warning"
    }
  }

  # One 5xx alarm per monitored endpoint
  endpoint_alarms = {
    for key, path in var.monitored_endpoints : "api_endpoint_5xx_${key}" => {
      description         = "WARNING: 5XX responses on endpoint ${path} (stage ${var.api_stage_name})."
      namespace           = var.data_api_metric_namespace
      metric_name         = "Api5xx_${key}"
      dimensions          = {}
      statistic           = "Sum"
      period              = 60
      evaluation_periods  = 3
      datapoints_to_alarm = 2
      threshold           = var.alarm_thresholds.api_5xx_per_minute
      severity            = "warning"
    }
  }

  simple_alarms = {
    for key, alarm in merge(local.base_alarms, local.endpoint_alarms) : key => {
      description         = alarm.description
      namespace           = alarm.namespace
      metric_name         = alarm.metric_name
      dimensions          = alarm.dimensions
      statistic           = lookup(alarm, "statistic", null)
      extended_statistic  = lookup(alarm, "extended_statistic", null)
      period              = alarm.period
      evaluation_periods  = alarm.evaluation_periods
      datapoints_to_alarm = lookup(alarm, "datapoints_to_alarm", null)
      threshold           = alarm.threshold
      severity            = alarm.severity
    }
  }
}

resource "aws_cloudwatch_metric_alarm" "simple" {
  for_each = local.simple_alarms

  alarm_name        = "${var.naming_prefix}-${replace(each.key, "_", "-")}"
  alarm_description = each.value.description

  namespace   = each.value.namespace
  metric_name = each.value.metric_name
  dimensions  = each.value.dimensions

  statistic          = each.value.statistic
  extended_statistic = each.value.extended_statistic

  period              = each.value.period
  evaluation_periods  = each.value.evaluation_periods
  datapoints_to_alarm = each.value.datapoints_to_alarm

  comparison_operator = "GreaterThanOrEqualToThreshold"
  threshold           = each.value.threshold
  treat_missing_data  = "notBreaching"

  alarm_actions = [var.sns_topic_arns[each.value.severity]]

  tags = merge(var.common_tags, {
    Name     = "${var.naming_prefix}-${replace(each.key, "_", "-")}"
    Severity = each.value.severity
  })

  lifecycle {
    precondition {
      condition     = (each.value.statistic == null) != (each.value.extended_statistic == null)
      error_message = "Alarm '${each.key}' must define exactly one of 'statistic' or 'extended_statistic'."
    }
  }
}

# Error *rate* (% of requests) per minute - metric math, ignored below a minimum traffic level
resource "aws_cloudwatch_metric_alarm" "api_error_rate" {
  for_each = {
    "5xx" = {
      api_metric  = "5XXError"
      threshold   = var.alarm_thresholds.api_5xx_rate_percent
      severity    = "critical"
      description = "CRITICAL: more than ${var.alarm_thresholds.api_5xx_rate_percent}% of API requests are failing with 5XX."
    }
    "4xx" = {
      api_metric  = "4XXError"
      threshold   = var.alarm_thresholds.api_4xx_rate_percent
      severity    = "warning"
      description = "WARNING: more than ${var.alarm_thresholds.api_4xx_rate_percent}% of API requests are failing with 4XX."
    }
  }

  alarm_name        = "${var.naming_prefix}-api-${each.key}-error-rate"
  alarm_description = each.value.description

  comparison_operator = "GreaterThanOrEqualToThreshold"
  threshold           = each.value.threshold
  evaluation_periods  = 3
  datapoints_to_alarm = 2
  treat_missing_data  = "notBreaching"

  metric_query {
    id          = "rate"
    label       = "${each.key} error rate (%)"
    expression  = "IF(requests >= ${var.alarm_thresholds.api_min_requests_for_rate}, 100 * errors / requests, 0)"
    return_data = true
  }

  metric_query {
    id = "errors"
    metric {
      namespace   = "AWS/ApiGateway"
      metric_name = each.value.api_metric
      period      = 60
      stat        = "Sum"
      dimensions  = local.api_dimensions
    }
  }

  metric_query {
    id = "requests"
    metric {
      namespace   = "AWS/ApiGateway"
      metric_name = "Count"
      period      = 60
      stat        = "Sum"
      dimensions  = local.api_dimensions
    }
  }

  alarm_actions = [var.sns_topic_arns[each.value.severity]]

  tags = merge(var.common_tags, {
    Name     = "${var.naming_prefix}-api-${each.key}-error-rate"
    Severity = each.value.severity
  })
}
