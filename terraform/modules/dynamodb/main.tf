############################################
# DYNAMODB TABLE
############################################

# ---------------------------------------------------------------------------
# DynamoDB table generated from the User @DynamoDbBean:
#   - Partition key   : userId       (@DynamoDbPartitionKey)
#   - GSI email-index : email        (@DynamoDbSecondaryPartitionKey)
#   - GSI status-index: status       (@DynamoDbSecondaryPartitionKey)
# Table name matches @TableName(name = "users") on the entity.
# ---------------------------------------------------------------------------

resource "aws_dynamodb_table" "users" {
  name         = var.table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "userId"

  # --- Security hardening ---
  deletion_protection_enabled = var.enable_deletion_protection

  server_side_encryption {
    enabled     = true
    kms_key_arn = var.kms_dynamodb_key_arn
  }

  point_in_time_recovery {
    enabled = var.enable_point_in_time_recovery
  }

  # --- Dynamic scaling / cost control ---
  on_demand_throughput {
    max_read_request_units  = var.max_read_request_units
    max_write_request_units = var.max_write_request_units
  }

  attribute {
    name = "userId"
    type = "S"
  }

  attribute {
    name = "email"
    type = "S"
  }

  attribute {
    name = "status"
    type = "S"
  }

  global_secondary_index {
    name            = "email-index"
    projection_type = "ALL"

    key_schema {
      attribute_name = "email"
      key_type       = "HASH"
    }

    on_demand_throughput {
      max_read_request_units  = var.max_read_request_units
      max_write_request_units = var.max_write_request_units
    }
  }

  global_secondary_index {
    name            = "status-index"
    projection_type = "ALL"

    key_schema {
      attribute_name = "status"
      key_type       = "HASH"
    }

    on_demand_throughput {
      max_read_request_units  = var.max_read_request_units
      max_write_request_units = var.max_write_request_units
    }
  }

  tags = merge(var.common_tags, {
    Name = "${var.naming_prefix}-dynamodb-crud"
  })
}
