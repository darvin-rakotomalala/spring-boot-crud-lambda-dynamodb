# ─── Adjust for your environment ────────────────────────────────────
primary_region                = "us-east-1"
environment                   = "dev"
project_name                  = "ce"
team_name                     = "training"
cost_center                   = "engineering"
compliance                    = "internal"
create_github_actions_role    = true
create_github_oidc_provider   = true
github_org                    = "darvin-rakotomalala"
github_repo                   = "spring-boot-crud-lambda-dynamodb"
bucket_name                   = "ce-dev-terraform-state-69127"
function_name                 = "crudLambdaApiGateway"
lambda_zip_path               = "./spring-boot-crud-lambda-dynamodb.zip"
lambda_handler                = "com.ce.StreamLambdaHandler::handleRequest"
lambda_runtime                = "java21"
lambda_architecture           = "x86_64"
lambda_memory_size            = 1024
lambda_timeout                = 30
lambda_alias_name             = "lambda-dev"
lambda_reserved_concurrency   = -1
log_retention_days            = 14
api_name                      = "crudLambdaRestApi"
api_stage_name                = "dev"
table_name                    = "users"
enable_point_in_time_recovery = false
dynamodb_endpoint             = ""
enable_deletion_protection    = false
max_read_request_units        = 4000
max_write_request_units       = 4000
kms_deletion_window_in_days   = 7
api_authorization_type        = "NONE"
api_key_required              = false
api_execution_logging_level   = "OFF"
api_throttling_rate_limit     = 100
api_throttling_burst_limit    = 200
manage_api_gateway_account    = true
lambda_environment = {
  # LOG_LEVEL = "debug"
}
lambda_tracing_mode   = "Active"
lambda_description    = "AWS Serverless Spring Boot 4 API"
lambda_log_group_name = "SpringBoot_Lambda_Function_Logs"
app_log_group_name    = "SpringBoot_Lambda_APIGateway_DynamoDB_Logs"
api_log_group_name    = "SpringBoot_APIGateway_Logs"
monitored_endpoints = {
  users = "/users*"
}

# --- Scaling / protection ---
# lambda_reserved_concurrency = 50
# api_throttling_rate_limit   = 100
# api_throttling_burst_limit  = 200

# --- Dev only: allow terraform destroy ---
# enable_deletion_protection = false

# --- Alerting ---
alert_subscriptions = {
  critical-oncall-email = { topic = "critical", protocol = "email", endpoint = "darvintojo@gmail.com" }
  # critical-pagerduty    = { topic = "critical", protocol = "https", endpoint = "https://events.pagerduty.com/integration/XXXX/enqueue" }
  warning-team-email = { topic = "warning", protocol = "email", endpoint = "darvintojo@gmail.com" }
}
