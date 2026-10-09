############################################
# SNS ALERT TOPICS
#   critical -> PagerDuty / OpsGenie (+ email)
#   warning  -> Slack bridge / email
############################################

resource "aws_sns_topic" "alerts" {
  for_each          = toset(["critical", "warning"])
  name              = "${var.naming_prefix}-alerts-${each.key}"
  kms_master_key_id = var.kms_cloudwatch_key_arn

  tags = merge(var.common_tags, {
    Name = "${var.naming_prefix}-alerts-${each.key}"
  })
}

data "aws_iam_policy_document" "sns_alerts" {
  for_each = aws_sns_topic.alerts

  statement {
    sid    = "AccountOwnerAdmin"
    effect = "Allow"
    actions = [
      "SNS:GetTopicAttributes", "SNS:SetTopicAttributes", "SNS:AddPermission", "SNS:RemovePermission",
      "SNS:DeleteTopic", "SNS:Subscribe", "SNS:ListSubscriptionsByTopic", "SNS:Publish",
    ]
    resources = [each.value.arn]
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
    condition {
      test     = "StringEquals"
      variable = "AWS:SourceOwner"
      values   = [var.current_account_id]
    }
  }

  statement {
    sid       = "AllowCloudWatchAlarmsPublish"
    effect    = "Allow"
    actions   = ["SNS:Publish"]
    resources = [each.value.arn]
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

  statement {
    sid       = "DenyInsecureTransport"
    effect    = "Deny"
    actions   = ["SNS:Publish", "SNS:Subscribe"]
    resources = [each.value.arn]
    principals {
      type        = "*"
      identifiers = ["*"]
    }
    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }
}

resource "aws_sns_topic_policy" "alerts" {
  for_each = aws_sns_topic.alerts
  arn      = each.value.arn
  policy   = data.aws_iam_policy_document.sns_alerts[each.key].json
}

resource "aws_sns_topic_subscription" "alerts" {
  for_each  = var.alert_subscriptions
  topic_arn = aws_sns_topic.alerts[each.value.topic].arn
  protocol  = each.value.protocol
  endpoint  = each.value.endpoint

  # PagerDuty / OpsGenie CloudWatch endpoints confirm the subscription themselves
  endpoint_auto_confirms = each.value.protocol == "https"
}
