############################################
# LAMBDA
############################################

resource "aws_s3_bucket" "lambda_artifacts" {
  bucket_prefix = "${var.naming_prefix}-lambda-artifacts-69127"
  force_destroy = true
  tags = merge(var.common_tags, {
    Name = "${var.naming_prefix}-lambda-artifacts"
  })
}

resource "aws_s3_bucket_public_access_block" "lambda_artifacts" {
  bucket                  = aws_s3_bucket.lambda_artifacts.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

############################################
# DUMMY ZIP FOR INITIAL TERRAFORM PROVISIONING (Java 21)
############################################

data "archive_file" "lambda_dummy" {
  type        = "zip"
  output_path = "${path.module}/dummy_lambda.zip"

  source {
    content  = "dummy"
    filename = "com/ce/StreamLambdaHandler.class"
  }
}

resource "aws_lambda_function" "hello_lambda" {
  function_name = var.function_name
  description   = var.lambda_description

  # Standard code deployment configuration for initial boot
  filename         = data.archive_file.lambda_dummy.output_path
  source_code_hash = data.archive_file.lambda_dummy.output_base64sha256

  handler = var.lambda_handler
  runtime = var.lambda_runtime

  architectures = [var.lambda_architecture] # Spec: x86_64 (SnapStart)[cite: 1]

  memory_size = var.lambda_memory_size
  timeout     = var.lambda_timeout

  role = var.lambda_exec_role_arn

  # Protects downstream DynamoDB and other functions; -1 = unreserved[cite: 1]
  reserved_concurrent_executions = var.lambda_reserved_concurrency

  # A published version is required for SnapStart and for the alias to point to[cite: 1]
  publish = true

  snap_start {
    apply_on = "PublishedVersions"
  }

  tracing_config {
    mode = var.lambda_tracing_mode
  }

  # Keep "Text" so the metric-filter patterns in cloudwatch.tf (e.g. "Task timed out after", REPORT lines) match.[cite: 1]
  logging_config {
    log_format = "Text"
    log_group  = var.log_group_lambda_function_names
  }

  environment {
    variables = merge(
      {
        TABLE_NAME         = var.dynamodb_table_name # rename to whatever your Spring config reads[cite: 1]
        APP_LOG_GROUP_NAME = var.log_group_app_names
        # AWS-recommended JIT setting for faster Java cold starts / SnapStart restores[cite: 1]
        JAVA_TOOL_OPTIONS = "-XX:+TieredCompilation -XX:TieredStopAtLevel=1"
      },
      var.lambda_environment,
    )
  }

  # PREVENT TERRAFORM FROM OVERWRITING CODE DEPLOYED BY GITHUB ACTIONS[cite: 2]
  lifecycle {
    ignore_changes = [
      filename,
      source_code_hash,
      s3_bucket,
      s3_key,
      s3_object_version,
    ]
  }

  depends_on = [
    var.log_group_lambda_function_names,
    var.policy_lambda_basic_execution,
    var.lambda_app_policy_id,
    aws_s3_bucket.lambda_artifacts,
    var.dynamodb_table_arn,
  ]

  tags = merge(var.common_tags, {
    Name = "${var.naming_prefix}-${var.function_name}"
  })
}

# Alias that always tracks the latest published (SnapStart-enabled) version; API Gateway targets it.
resource "aws_lambda_alias" "lambda_dev" {
  name             = var.lambda_alias_name
  description      = "Alias for the ${var.api_stage_name} stage, backed by SnapStart-enabled published versions"
  function_name    = aws_lambda_function.hello_lambda.function_name
  function_version = aws_lambda_function.hello_lambda.version

  lifecycle {
    ignore_changes = [function_version]
  }
}

# Allow API Gateway (this API, this stage only) to invoke the alias
resource "aws_lambda_permission" "apigw_invoke" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.hello_lambda.function_name
  qualifier     = aws_lambda_alias.lambda_dev.name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${var.api_lambda_api_execution_arn}/${var.api_stage_name}/*/*"
}
