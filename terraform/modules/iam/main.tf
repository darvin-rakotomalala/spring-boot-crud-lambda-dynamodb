############################################
# IAM - LAMBDA EXECUTION ROLE
############################################

data "aws_iam_policy_document" "lambda_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "lambda_exec" {
  name               = "${var.function_name}-exec-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}

# Spec: AWSLambdaBasicExecutionRole (write logs to CloudWatch)
resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:${var.current_partition}:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Least-privilege access to the table, the KMS keys and the application log group
data "aws_iam_policy_document" "lambda_app" {
  statement {
    sid = "DynamoDBCrud"
    actions = [
      "dynamodb:GetItem", "dynamodb:BatchGetItem",
      "dynamodb:PutItem", "dynamodb:UpdateItem", "dynamodb:DeleteItem", "dynamodb:BatchWriteItem",
      "dynamodb:ConditionCheckItem",
      "dynamodb:Query", "dynamodb:Scan", # drop Scan if the app never uses findAll()
      "dynamodb:DescribeTable",
    ]
    resources = [
      var.dynamodb_table_arn,
      "${var.dynamodb_table_arn}/index/*",
    ]
  }

  # Spec: Lambda role gets KMS encrypt/decrypt - scoped to the specific keys and to the calling service
  statement {
    sid       = "KmsDynamoDB"
    actions   = ["kms:Decrypt", "kms:Encrypt", "kms:GenerateDataKey", "kms:ReEncrypt*", "kms:DescribeKey"]
    resources = [var.dynamodb_kms_key_arn]
    condition {
      test     = "StringEquals"
      variable = "kms:ViaService"
      values   = ["dynamodb.${var.aws_region}.amazonaws.com"]
    }
  }

  statement {
    sid       = "KmsCloudWatchLogs"
    actions   = ["kms:Decrypt", "kms:Encrypt", "kms:GenerateDataKey", "kms:DescribeKey"]
    resources = [var.kms_cloudwatch_key_arn]
    condition {
      test     = "StringEquals"
      variable = "kms:ViaService"
      values   = ["logs.${var.aws_region}.amazonaws.com"]
    }
  }

  # Lets the app write to its dedicated application log group (e.g. via a Logback CloudWatch appender)
  statement {
    sid       = "AppLogGroup"
    actions   = ["logs:CreateLogStream", "logs:PutLogEvents", "logs:DescribeLogStreams"]
    resources = [var.log_group_app_arn, "${var.log_group_app_arn}:*"]
  }
}

resource "aws_iam_role_policy" "lambda_app" {
  name   = "${var.function_name}-app-access"
  role   = aws_iam_role.lambda_exec.id
  policy = data.aws_iam_policy_document.lambda_app.json
}

############################################
# IAM - API GATEWAY -> CLOUDWATCH (account-level singleton)
############################################

data "aws_iam_policy_document" "apigw_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["apigateway.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "apigw_cloudwatch" {
  count              = var.manage_api_gateway_account ? 1 : 0
  name               = "${var.naming_prefix}-apigw-cloudwatch-role"
  assume_role_policy = data.aws_iam_policy_document.apigw_assume_role.json
}

resource "aws_iam_role_policy_attachment" "apigw_cloudwatch" {
  count      = var.manage_api_gateway_account ? 1 : 0
  role       = aws_iam_role.apigw_cloudwatch[0].name
  policy_arn = "arn:${var.current_partition}:iam::aws:policy/service-role/AmazonAPIGatewayPushToCloudWatchLogs"
}

resource "aws_api_gateway_account" "this" {
  count               = var.manage_api_gateway_account ? 1 : 0
  cloudwatch_role_arn = aws_iam_role.apigw_cloudwatch[0].arn

  depends_on = [aws_iam_role_policy_attachment.apigw_cloudwatch]
}

############################################
# IAM - GITHUB ACTIONS OIDC ROLE (OPTIONAL)
############################################

locals {
  github_subjects = concat(
    ["repo:${var.github_org}*/${var.github_repo}*:*"],
  )

  github_oidc_provider_arn = coalesce(
    one(aws_iam_openid_connect_provider.github_actions[*].arn),
    "arn:${var.current_partition}:iam::${var.current_account_id}:oidc-provider/token.actions.githubusercontent.com",
  )
  github_role_name = "${var.naming_prefix}-github-actions-role"
}

# Preserve existing state addresses (resources gained a `count`)
moved {
  from = aws_iam_openid_connect_provider.github_actions
  to   = aws_iam_openid_connect_provider.github_actions[0]
}

moved {
  from = aws_iam_role.terraform_execution
  to   = aws_iam_role.terraform_execution[0]
}

resource "aws_iam_openid_connect_provider" "github_actions" {
  count          = var.create_github_actions_role && var.create_github_oidc_provider ? 1 : 0
  url            = "https://token.actions.githubusercontent.com"
  client_id_list = ["sts.amazonaws.com"]
  # thumbprint_list is no longer required - AWS validates GitHub's certificate chain itself.
}

data "aws_iam_policy_document" "github_assume_role" {
  count = var.create_github_actions_role ? 1 : 0

  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [local.github_oidc_provider_arn]
    }
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }
    # Exact repo + branch (no org/repo wildcards, which would match look-alike orgs/repos)
    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = local.github_subjects
    }
  }
}

resource "aws_iam_role" "terraform_execution" {
  count                = var.create_github_actions_role ? 1 : 0
  name                 = local.github_role_name
  assume_role_policy   = data.aws_iam_policy_document.github_assume_role[0].json
  max_session_duration = 3600

  tags = merge(var.common_tags, {
    Name = "${var.naming_prefix}-ga-oidc"
  })

  lifecycle {
    precondition {
      condition     = var.github_org != "" && var.github_repo != ""
      error_message = "github_org and github_repo must be set (exact names) when create_github_actions_role = true."
    }
  }
}

# Scoped replacement for AdministratorAccess. Starting point only - tune with IAM Access Analyzer
# policy generation. It deliberately cannot modify its own role or the OIDC provider (no privilege escalation);
# add permissions for your Terraform state backend (S3/DynamoDB) separately.
data "aws_iam_policy_document" "github_deploy" {
  statement {
    sid     = "Lambda"
    actions = ["lambda:*"]
    resources = [
      "arn:${var.current_partition}:lambda:${var.aws_region}:${var.current_account_id}:function:${var.function_name}",
      "arn:${var.current_partition}:lambda:${var.aws_region}:${var.current_account_id}:function:${var.function_name}:*",
    ]
  }

  statement {
    sid     = "ApiGateway"
    actions = ["apigateway:*"]
    resources = [
      "arn:${var.current_partition}:apigateway:${var.aws_region}::/restapis",
      "arn:${var.current_partition}:apigateway:${var.aws_region}::/restapis/*",
      "arn:${var.current_partition}:apigateway:${var.aws_region}::/account",
      "arn:${var.current_partition}:apigateway:${var.aws_region}::/usageplans",
      "arn:${var.current_partition}:apigateway:${var.aws_region}::/usageplans/*",
      "arn:${var.current_partition}:apigateway:${var.aws_region}::/apikeys",
      "arn:${var.current_partition}:apigateway:${var.aws_region}::/apikeys/*",
      "arn:${var.current_partition}:apigateway:${var.aws_region}::/tags/*",
    ]
  }

  statement {
    sid     = "DynamoDB"
    actions = ["dynamodb:*"]
    resources = [
      "arn:${var.current_partition}:dynamodb:${var.aws_region}:${var.current_account_id}:table/${var.table_name}",
      "arn:${var.current_partition}:dynamodb:${var.aws_region}:${var.current_account_id}:table/${var.table_name}/*",
    ]
  }

  statement {
    sid       = "KmsCreate"
    actions   = ["kms:CreateKey", "kms:TagResource", "kms:ListAliases", "kms:ListKeys"]
    resources = ["*"]
  }

  statement {
    sid     = "KmsManageProjectKeys"
    actions = ["kms:*"]
    resources = [
      var.dynamodb_kms_key_arn,
      var.kms_cloudwatch_key_arn,
      "arn:${var.current_partition}:kms:${var.aws_region}:${var.current_account_id}:alias/${var.naming_prefix}-*",
    ]
  }

  statement {
    sid     = "LogGroups"
    actions = ["logs:*"]
    resources = flatten([
      for name in [var.lambda_log_group_name, var.app_log_group_name, var.api_log_group_name] : [
        "arn:${var.current_partition}:logs:${var.aws_region}:${var.current_account_id}:log-group:${name}",
        "arn:${var.current_partition}:logs:${var.aws_region}:${var.current_account_id}:log-group:${name}:*",
      ]
    ])
  }

  statement {
    sid = "LogsUnscoped"
    actions = [
      "logs:DescribeLogGroups", "logs:ListTagsForResource",
      "logs:PutQueryDefinition", "logs:DeleteQueryDefinition", "logs:DescribeQueryDefinitions",
    ]
    resources = ["*"]
  }

  statement {
    sid       = "Sns"
    actions   = ["sns:*"]
    resources = ["arn:${var.current_partition}:sns:${var.aws_region}:${var.current_account_id}:${var.naming_prefix}-alerts-*"]
  }

  statement {
    sid = "CloudWatchAlarms"
    actions = [
      "cloudwatch:PutMetricAlarm", "cloudwatch:DeleteAlarms",
      "cloudwatch:TagResource", "cloudwatch:UntagResource", "cloudwatch:ListTagsForResource",
    ]
    resources = ["arn:${var.current_partition}:cloudwatch:${var.aws_region}:${var.current_account_id}:alarm:${var.naming_prefix}-*"]
  }

  statement {
    sid       = "CloudWatchRead"
    actions   = ["cloudwatch:DescribeAlarms"]
    resources = ["*"]
  }

  # NOTE: iam:* on the two project roles means this pipeline can still widen what the Lambda role may do
  # (e.g. attach a broader policy). Add a permissions boundary on those roles if you need to cap that.
  statement {
    sid     = "IamProjectRoles"
    actions = ["iam:*"]
    resources = [
      "arn:${var.current_partition}:iam::${var.current_account_id}:role/${var.function_name}-exec-role",
      "arn:${var.current_partition}:iam::${var.current_account_id}:role/${var.naming_prefix}-apigw-cloudwatch-role",
    ]
  }

  statement {
    sid = "IamReadSelf"
    actions = [
      "iam:GetRole", "iam:ListRolePolicies", "iam:ListAttachedRolePolicies",
      "iam:GetRolePolicy", "iam:ListInstanceProfilesForRole", "iam:ListRoleTags",
    ]
    resources = ["arn:${var.current_partition}:iam::${var.current_account_id}:role/${local.github_role_name}"]
  }

  statement {
    sid       = "IamReadOidcProvider"
    actions   = ["iam:GetOpenIDConnectProvider", "iam:ListOpenIDConnectProviderTags"]
    resources = ["arn:${var.current_partition}:iam::${var.current_account_id}:oidc-provider/token.actions.githubusercontent.com"]
  }

  # Workflow uploads the Lambda zip, and Lambda reads it back using the caller's credentials
  statement {
    sid = "ArtifactBucketObjects"
    actions = [
      "s3:PutObject",
      "s3:GetObject",
      "s3:AbortMultipartUpload",
    ]
    resources = ["arn:${var.current_partition}:s3:::${var.lambda_artifacts_bucket_name}/${var.function_name}/*"]
  }

  statement {
    sid       = "ArtifactBucketList"
    actions   = ["s3:ListBucket", "s3:GetBucketLocation"]
    resources = ["arn:${var.current_partition}:s3:::${var.lambda_artifacts_bucket_name}"]
  }

}

resource "aws_iam_role_policy" "github_deploy" {
  count  = var.create_github_actions_role ? 1 : 0
  name   = "${var.naming_prefix}-github-deploy"
  role   = aws_iam_role.terraform_execution[0].id
  policy = data.aws_iam_policy_document.github_deploy.json
}
