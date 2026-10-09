############################################
# KMS - VARIABLES
############################################

variable "aws_region" {
  description = "Primary region"
  type        = string
}

variable "naming_prefix" {
  description = "Naming prefix"
  type        = string
}

variable "common_tags" {}

variable "current_account_id" {
  description = "Current account ID"
  type        = string
}

variable "current_partition" {
  description = "Current partition account ID"
  type        = string
}

variable "kms_deletion_window_in_days" {
  type        = number
  description = "Waiting period before the KMS key is deleted after being scheduled for deletion (7-30 days)."
}
