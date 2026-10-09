############################################
# KMS ENCRYPTION
############################################

# ---------- Key 1: DynamoDB ----------
data "aws_iam_policy_document" "kms_dynamodb" {
  statement {
    sid       = "EnableIAMUserPermissions"
    effect    = "Allow"
    actions   = ["kms:*"]
    resources = ["*"]
    principals {
      type        = "AWS"
      identifiers = ["arn:${var.current_partition}:iam::${var.current_account_id}:root"]
    }
  }

  # Standard pattern for DynamoDB CMKs: only usable *through* DynamoDB, only by principals in this account.
  statement {
    sid    = "AllowDynamoDBUseViaService"
    effect = "Allow"
    actions = [
      "kms:Encrypt", "kms:Decrypt", "kms:ReEncrypt*", "kms:GenerateDataKey*",
      "kms:CreateGrant", "kms:ListGrants", "kms:RevokeGrant", "kms:DescribeKey",
    ]
    resources = ["*"]
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
    condition {
      test     = "StringEquals"
      variable = "kms:CallerAccount"
      values   = [var.current_account_id]
    }
    condition {
      test     = "StringEquals"
      variable = "kms:ViaService"
      values   = ["dynamodb.${var.aws_region}.amazonaws.com"]
    }
  }
}

resource "aws_kms_key" "dynamodb" {
  description             = "CMK for encrypting ${var.naming_prefix} DynamoDB tables"
  deletion_window_in_days = var.kms_deletion_window_in_days
  enable_key_rotation     = true
  policy                  = data.aws_iam_policy_document.kms_dynamodb.json

  tags = merge(var.common_tags, {
    Name = "${var.naming_prefix}-dynamodb-cmk"
  })
}

resource "aws_kms_alias" "dynamodb" {
  name          = "alias/${var.naming_prefix}-dynamodb"
  target_key_id = aws_kms_key.dynamodb.key_id
}

# ---------- Key 2: CloudWatch Logs + SNS ----------
data "aws_iam_policy_document" "kms_cloudwatch" {
  statement {
    sid       = "EnableIAMUserPermissions"
    effect    = "Allow"
    actions   = ["kms:*"]
    resources = ["*"]
    principals {
      type        = "AWS"
      identifiers = ["arn:${var.current_partition}:iam::${var.current_account_id}:root"]
    }
  }

  statement {
    sid    = "AllowCloudWatchLogsServiceUse"
    effect = "Allow"
    actions = [
      "kms:Encrypt*", "kms:Decrypt*", "kms:ReEncrypt*",
      "kms:GenerateDataKey*", "kms:Describe*",
    ]
    resources = ["*"]
    principals {
      type        = "Service"
      identifiers = ["logs.${var.aws_region}.amazonaws.com"]
    }
    condition {
      test     = "ArnLike"
      variable = "kms:EncryptionContext:aws:logs:arn"
      values   = ["arn:${var.current_partition}:logs:${var.aws_region}:${var.current_account_id}:log-group:*"]
    }
  }

  # SNS topics (alert topics) encrypted with this key
  statement {
    sid       = "AllowSNSServiceUse"
    effect    = "Allow"
    actions   = ["kms:Encrypt", "kms:Decrypt", "kms:ReEncrypt*", "kms:GenerateDataKey*", "kms:DescribeKey"]
    resources = ["*"]
    principals {
      type        = "Service"
      identifiers = ["sns.amazonaws.com"]
    }
    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [var.current_account_id]
    }
  }

  # CloudWatch alarms must be able to publish to the encrypted SNS topics
  statement {
    sid       = "AllowCloudWatchAlarmsToUseKMS"
    effect    = "Allow"
    actions   = ["kms:Decrypt", "kms:GenerateDataKey*"]
    resources = ["*"]
    principals {
      type        = "Service"
      identifiers = ["cloudwatch.amazonaws.com"]
    }
    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [var.current_account_id]
    }
  }
}

resource "aws_kms_key" "cloudwatch" {
  description             = "CMK for ${var.naming_prefix} CloudWatch Log groups and SNS alert topics"
  deletion_window_in_days = var.kms_deletion_window_in_days
  enable_key_rotation     = true
  policy                  = data.aws_iam_policy_document.kms_cloudwatch.json

  tags = merge(var.common_tags, {
    Name = "${var.naming_prefix}-cloudwatch-cmk"
  })
}

resource "aws_kms_alias" "cloudwatch" {
  name          = "alias/${var.naming_prefix}-lambda-cloudwatch"
  target_key_id = aws_kms_key.cloudwatch.key_id
}
