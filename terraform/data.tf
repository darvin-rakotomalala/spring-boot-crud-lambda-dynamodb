############################################
# DATA SOURCES + SHARED LOCALS
############################################

data "aws_caller_identity" "current" {}
data "aws_partition" "current" {}
data "aws_region" "current" {}

locals {
  account_id = data.aws_caller_identity.current.account_id
  partition  = data.aws_partition.current.partition
  region     = data.aws_region.current.region

  # Custom CloudWatch metric namespaces (populated by the log metric filters in cloudwatch.tf)
  lambda_metric_namespace = "${local.naming_prefix}/Lambda"
  app_metric_namespace    = "${local.naming_prefix}/Application"
  api_metric_namespace    = "${local.naming_prefix}/ApiGateway"

  # Concurrency alarm: 80% (default) of reserved concurrency if set, else the account-level threshold
  lambda_concurrency_alarm_threshold = (
    var.lambda_reserved_concurrency > 0
    ? max(1, floor(var.lambda_reserved_concurrency * var.alarm_thresholds.lambda_concurrency_ratio))
    : var.alarm_thresholds.account_concurrency
  )
}
