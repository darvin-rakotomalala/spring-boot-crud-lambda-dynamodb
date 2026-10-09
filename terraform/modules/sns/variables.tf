############################################
# SNS - VARIABLES
############################################

variable "naming_prefix" {
  description = "Naming prefix"
  type        = string
}

variable "common_tags" {}

variable "kms_cloudwatch_key_arn" {
  description = "CMK used for CloudWatch Logs and SNS."
  type        = string
}

variable "current_account_id" {
  description = "Current account ID"
  type        = string
}

variable "alert_subscriptions" {
  description = <<-EOT
    SNS alert subscriptions, keyed by a unique static name.
    Example:
      alert_subscriptions = {
        critical-oncall-email = { topic = "critical", protocol = "email", endpoint = "oncall@example.com" }
        critical-pagerduty    = { topic = "critical", protocol = "https", endpoint = "https://events.pagerduty.com/integration/XXXX/enqueue" }
        warning-team-email    = { topic = "warning",  protocol = "email", endpoint = "team@example.com" }
      }
  EOT
  type = map(object({
    topic    = string
    protocol = string
    endpoint = string
  }))
  default = {}

  validation {
    condition     = alltrue([for s in values(var.alert_subscriptions) : contains(["critical", "warning"], s.topic)])
    error_message = "Each subscription's topic must be \"critical\" or \"warning\"."
  }

  validation {
    condition     = alltrue([for s in values(var.alert_subscriptions) : contains(["email", "https"], s.protocol)])
    error_message = "Each subscription's protocol must be \"email\" or \"https\"."
  }
}
