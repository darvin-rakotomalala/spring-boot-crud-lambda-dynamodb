#########################################################
# IAM
#########################################################

module "iam" {
  source        = "./modules/iam"
  naming_prefix = local.naming_prefix
  common_tags   = local.common_tags

  api_log_group_name           = var.api_log_group_name
  app_log_group_name           = var.app_log_group_name
  create_github_actions_role   = var.create_github_actions_role
  create_github_oidc_provider  = var.create_github_oidc_provider
  current_account_id           = data.aws_caller_identity.current.account_id
  current_partition            = data.aws_partition.current.partition
  dynamodb_kms_key_arn         = module.kms.dynamodb_kms_key_arn
  dynamodb_table_arn           = module.dynamodb.dynamodb_table_arn
  function_name                = var.function_name
  github_org                   = var.github_org
  github_repo                  = var.github_repo
  kms_cloudwatch_key_arn       = module.kms.kms_cloudwatch_key_arn
  lambda_log_group_name        = var.lambda_log_group_name
  log_group_app_arn            = module.cloudwatch.log_group_arns.application
  manage_api_gateway_account   = var.manage_api_gateway_account
  table_name                   = var.table_name
  lambda_artifacts_bucket_name = module.lambda.lambda_artifacts_bucket_name
}

#########################################################
# LAMBDA
#########################################################

module "lambda" {
  source        = "./modules/lambda"
  naming_prefix = local.naming_prefix
  common_tags   = local.common_tags

  api_lambda_api_execution_arn    = module.api-gateway.api_lambda_api_execution_arn
  api_stage_name                  = var.api_stage_name
  dynamodb_table_name             = module.dynamodb.dynamodb_table_name
  function_name                   = var.function_name
  lambda_alias_name               = var.lambda_alias_name
  lambda_app_policy_id            = module.iam.lambda_app_policy_id
  lambda_architecture             = var.lambda_architecture
  lambda_description              = var.lambda_description
  lambda_environment              = var.lambda_environment
  lambda_exec_role_arn            = module.iam.lambda_exec_role_arn
  lambda_handler                  = var.lambda_handler
  lambda_memory_size              = var.lambda_memory_size
  lambda_reserved_concurrency     = var.lambda_reserved_concurrency
  lambda_runtime                  = var.lambda_runtime
  lambda_timeout                  = var.lambda_timeout
  lambda_tracing_mode             = var.lambda_tracing_mode
  # lambda_zip_path                 = var.lambda_zip_path
  log_group_app_names             = module.cloudwatch.log_group_names.lambda_function
  log_group_lambda_function_names = module.cloudwatch.log_group_names.lambda_function
  log_retention_days              = var.log_retention_days
  policy_lambda_basic_execution   = module.iam.policy_lambda_basic_execution
  dynamodb_table_arn              = module.dynamodb.dynamodb_table_arn
}

#########################################################
# API GATEWAY
#########################################################

module "api-gateway" {
  source        = "./modules/api-gateway"
  naming_prefix = local.naming_prefix
  common_tags   = local.common_tags

  api_authorization_type      = var.api_authorization_type
  api_execution_logging_level = var.api_execution_logging_level
  api_key_required            = var.api_key_required
  api_name                    = var.api_name
  api_stage_name              = var.api_stage_name
  api_throttling_burst_limit  = var.api_throttling_burst_limit
  api_throttling_rate_limit   = var.api_throttling_rate_limit
  lambda_dev_alias_invoke_arn = module.lambda.lambda_dev_alias_invoke_arn
  log_group_api_gateway_arn   = module.cloudwatch.log_group_arns.api_gateway
}

#########################################################
## KMS
#########################################################

module "kms" {
  source        = "./modules/kms"
  naming_prefix = local.naming_prefix
  common_tags   = local.common_tags

  aws_region                  = var.primary_region
  current_account_id          = data.aws_caller_identity.current.account_id
  current_partition           = data.aws_partition.current.partition
  kms_deletion_window_in_days = var.kms_deletion_window_in_days
}

#########################################################
## DYNAMODB
#########################################################

module "dynamodb" {
  source        = "./modules/dynamodb"
  naming_prefix = local.naming_prefix
  common_tags   = local.common_tags

  aws_region                    = var.primary_region
  dynamodb_endpoint             = var.dynamodb_endpoint
  enable_deletion_protection    = var.enable_deletion_protection
  enable_point_in_time_recovery = var.enable_point_in_time_recovery
  kms_dynamodb_key_arn          = module.kms.dynamodb_kms_key_arn
  max_read_request_units        = var.max_read_request_units
  max_write_request_units       = var.max_write_request_units
  table_name                    = var.table_name
}

#########################################################
## CLOUDWATCH
#########################################################

module "cloudwatch" {
  source        = "./modules/cloudwatch"
  naming_prefix = local.naming_prefix
  common_tags   = local.common_tags

  api_log_group_name                      = var.api_log_group_name
  api_stage_name                          = var.api_stage_name
  app_log_group_name                      = var.app_log_group_name
  data_api_metric_namespace               = local.api_metric_namespace
  data_app_metric_namespace               = local.app_metric_namespace
  data_lambda_concurrency_alarm_threshold = local.lambda_concurrency_alarm_threshold
  data_lambda_metric_namespace            = local.lambda_metric_namespace
  dynamodb_table_name                     = module.dynamodb.dynamodb_table_name
  function_name                           = var.function_name
  kms_cloudwatch_key_arn                  = module.kms.kms_cloudwatch_key_arn
  lambda_function_name                    = module.lambda.lambda_function_name
  lambda_log_group_name                   = var.lambda_log_group_name
  lambda_timeout                          = var.lambda_timeout
  log_retention_days                      = var.log_retention_days
  monitored_endpoints                     = var.monitored_endpoints
  sns_topic_arns                          = module.sns.sns_topic_arns
  java_lambda_api_name                    = var.api_name
  java_lambda_api_stage_name              = var.api_stage_name
}

#########################################################
## SNS
#########################################################

module "sns" {
  source                 = "./modules/sns"
  naming_prefix          = local.naming_prefix
  common_tags            = local.common_tags
  current_account_id     = data.aws_caller_identity.current.account_id
  kms_cloudwatch_key_arn = module.kms.kms_cloudwatch_key_arn
}
