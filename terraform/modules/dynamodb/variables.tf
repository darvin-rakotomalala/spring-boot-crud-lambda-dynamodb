#########################################################
# DYNAMODB - VARIABLES
#########################################################

variable "aws_region" {
  description = "Primary region"
  type        = string
}

variable "naming_prefix" {
  description = "Naming prefix"
  type        = string
}

variable "common_tags" {}

variable "table_name" {
  description = "DynamoDB table name, must match @TableName on the User entity"
  type        = string
}

variable "enable_point_in_time_recovery" {
  description = "Enable PITR backups on the table"
  type        = bool
}

variable "dynamodb_endpoint" {
  description = "Custom DynamoDB endpoint URL (e.g. http://localhost:8000 for local dev with DynamoDB Local). Leave empty to use real AWS."
  type        = string
}

variable "enable_deletion_protection" {
  type = bool
}

variable "kms_dynamodb_key_arn" {
  description = "The ARN of the DynamoDB KMS key."
  type        = string
}

variable "max_read_request_units" {
  type        = number
  description = "The maximum number of read request units (RU/s) allocated for the resource."
}

variable "max_write_request_units" {
  type        = number
  description = "The maximum number of write request units (RU/s) allocated for the resource."
}
