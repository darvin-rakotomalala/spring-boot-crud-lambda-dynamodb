############################################
# API GATEWAY
############################################

resource "aws_api_gateway_rest_api" "java_lambda_api" {
  name = var.api_name

  endpoint_configuration {
    types = ["REGIONAL"]
  }

  tags = merge(var.common_tags, {
    Name = "${var.naming_prefix}-${var.api_name}"
  })
}

# Catch-all proxy resource: /{proxy+}
resource "aws_api_gateway_resource" "proxy" {
  rest_api_id = aws_api_gateway_rest_api.java_lambda_api.id
  parent_id   = aws_api_gateway_rest_api.java_lambda_api.root_resource_id
  path_part   = "{proxy+}"
}

resource "aws_api_gateway_method" "proxy_any" {
  rest_api_id      = aws_api_gateway_rest_api.java_lambda_api.id
  resource_id      = aws_api_gateway_resource.proxy.id
  http_method      = "ANY"
  authorization    = var.api_authorization_type
  api_key_required = var.api_key_required

  request_parameters = {
    "method.request.path.proxy" = true
  }
}

resource "aws_api_gateway_integration" "proxy_lambda" {
  rest_api_id = aws_api_gateway_rest_api.java_lambda_api.id
  resource_id = aws_api_gateway_resource.proxy.id
  http_method = aws_api_gateway_method.proxy_any.http_method

  type                    = "AWS_PROXY"
  integration_http_method = "POST"
  # Must be the Lambda *invoke* ARN (arn:aws:apigateway:...:lambda:path/.../invocations), targeting the alias
  uri = var.lambda_dev_alias_invoke_arn
}

# ANY method on the root resource ("/") so the base path is also routed to the Spring Boot app
resource "aws_api_gateway_method" "root_any" {
  rest_api_id      = aws_api_gateway_rest_api.java_lambda_api.id
  resource_id      = aws_api_gateway_rest_api.java_lambda_api.root_resource_id
  http_method      = "ANY"
  authorization    = var.api_authorization_type
  api_key_required = var.api_key_required
}

resource "aws_api_gateway_integration" "root_lambda" {
  rest_api_id = aws_api_gateway_rest_api.java_lambda_api.id
  resource_id = aws_api_gateway_rest_api.java_lambda_api.root_resource_id
  http_method = aws_api_gateway_method.root_any.http_method

  type                    = "AWS_PROXY"
  integration_http_method = "POST"
  uri                     = var.lambda_dev_alias_invoke_arn
}

resource "aws_api_gateway_deployment" "deployment" {
  rest_api_id = aws_api_gateway_rest_api.java_lambda_api.id

  # Force a new deployment whenever the API configuration changes
  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.proxy.id,
      aws_api_gateway_method.proxy_any,
      aws_api_gateway_integration.proxy_lambda,
      aws_api_gateway_method.root_any,
      aws_api_gateway_integration.root_lambda,
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [
    aws_api_gateway_integration.proxy_lambda,
    aws_api_gateway_integration.root_lambda,
  ]
}

############################################
# STAGE: access logging, tracing, throttling
############################################

locals {
  # Single-line JSON access log. status / responseLatency are always present, so they are left unquoted and
  # CloudWatch JSON metric filters can compare them numerically. integration.* have no value when the request never
  # reaches Lambda (429 throttling, auth rejects) - unquoted they would produce invalid JSON and the line would be
  # skipped by every metric filter, so they are quoted. $context.error.messageString is already JSON-quoted.
  api_access_log_format = trimspace(<<-EOT
    {"requestId":"$context.requestId","ip":"$context.identity.sourceIp","requestTime":"$context.requestTime","httpMethod":"$context.httpMethod","path":"$context.path","resourcePath":"$context.resourcePath","protocol":"$context.protocol","status":$context.status,"responseLength":$context.responseLength,"responseLatency":$context.responseLatency,"integrationLatency":"$context.integration.latency","integrationStatus":"$context.integration.status","errorMessage":$context.error.messageString}
  EOT
  )
}

resource "aws_api_gateway_stage" "dev" {
  rest_api_id   = aws_api_gateway_rest_api.java_lambda_api.id
  deployment_id = aws_api_gateway_deployment.deployment.id
  stage_name    = var.api_stage_name

  access_log_settings {
    destination_arn = var.log_group_api_gateway_arn
    format          = local.api_access_log_format
  }

  tags = merge(var.common_tags, {
    Name = "${var.naming_prefix}-${var.api_stage_name}"
  })
}

resource "aws_api_gateway_method_settings" "all" {
  rest_api_id = aws_api_gateway_rest_api.java_lambda_api.id
  stage_name  = aws_api_gateway_stage.dev.stage_name
  method_path = "*/*"

  settings {
    metrics_enabled        = true
    logging_level          = var.api_execution_logging_level
    data_trace_enabled     = false # never log request/response bodies (PII)
    throttling_rate_limit  = var.api_throttling_rate_limit
    throttling_burst_limit = var.api_throttling_burst_limit
  }
}
