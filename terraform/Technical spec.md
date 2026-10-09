## Project: Create API Gateway + Amazon DynamoDB + AWS Lambda Function with Java 21 runtime (Terraform)

***

**Objective**: Create a serverless REST API with API Gateway, Amazon DynamoDB and AWS Lambda Serverless Functions in
Java & Spring with Java 21 runtime using Terraform. Uploading the `.zip` file to AWS Lambda Function with Terraform.

### Create Lambda function

- Create a new function
- Function a name `crudLambdaApiGateway`
- description = `AWS Serverless Spring Boot 4 API`
- Choose the Java 21 runtime
- Architectures: `x86`
- Start with `1024` MB for Most Functions
- MemorySize: `1024`
- Policies: `AWSLambdaBasicExecutionRole`
- Timeout: 30
- AutoPublishAlias: `lambda-dev`
- Enable SnapStart and ApplyOn: PublishedVersions
- Enabling SnapStart to improve cold-start time
- Configure versions and aliases alongside SnapStart
- For the purposes of this project, I'll keep the architecture at `X86` - this is because if you want to use something
  like SnapStart, you’ll need to use `X86` as it currently does not support ARM64.
- Configure the handler for the Lambda function `com.ce.StreamLambdaHandler::handleRequest`. The Lambda runtime must
  know which handler method to invoke
- Upload the built `spring-boot-crud-lambda-dynamodb.zip` file by choosing "Upload a
  `.zip` file" to the function
- Create CloudWatch Log group for monitoring
- Generate an Outputs

### Create API Gateway

- Create an API Gateway
- Globals Api EndpointConfiguration: `REGIONAL`
- Create API and choose the "REST API" option
- API Name: `crudLambdaRestApi`
- Create a new resource for each endpoint of our REST API
- Resource Path: `/{proxy+}`
- Resource named: `/{proxy+}`
- Method: ANY
- To configure the integration between the API Gateway and Lambda function above, select a resource and method, and
  set on "Integration Request". Choose the Lambda function as the integration type and select the Lambda
  function above.
- Deploy API with a new stage name `dev`
- Generate an Outputs for Invoke URL

### Create Amazon DynamoDB

```
############################################
# DynamoDB Table
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
    kms_key_arn = var.dynamodb_kms_key_arn
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

  lifecycle {
    prevent_destroy = false
  }
}

```

### Create Amazon KMS

- Create Amazon KMS key to encrypt DynamoDB and CloudWatch Log group
- Update IAM role of Lambda function to add permission decrypt and encrypt

### Create Amazon CloudWatch Log group

- Create Log Group for Lambda Function
    - Name `SpringBoot_Lambda_Function_Logs`
    - Metric Filters and Alarm for alert
    - Alerts when functions hit account/reserved concurrency limits.
    - Detects code exceptions, unhandled rejections, and runtime crashes.
    - High latency signals performance bottlenecks or imminent timeouts.
    - Prevents unexpected throttling across all regional services.
    - Function Timeouts `"Task timed out after"`
    - Out of Memory (OOM) Errors `{ $.status = "OOM" || $.message = "*Out of memory*" }`
    - Unhandled Code Exceptions / Panic `?"ERROR" ?"Error" ?"Exception" ?"Unhandled" ?"panic"`
    - Cold Start Tracking (From REPORT Logs) `[type="REPORT", ..., init_duration="Init Duration:"]`
- Create Log Group for Java Spring Boot application
    - Name `SpringBoot_Lambda_APIGateway_DynamoDB_Logs`
    - Metric Filters: Extract metrics from log patterns (ERROR, WARN)
        - Metric Filter for ERROR patterns
        - Metric Filter for WARNING patterns
- Create Log Group for API Gateway
    - Name `SpringBoot_APIGateway_Logs`
    - Extract 4xx/5xx Errors by Specific Path or Endpoint
    - Severe Backend Delays (Latencies > Threshold)
    - High 5xx Server Errors `Critical: Triggers PagerDuty / OpsGenie`
    - Spike in 4xx Client Errors `Warning: Alert Slack or email team`
    - High Overall Latency `Warning: Indicates API bottleneck`
    - High Integration Latency `Warning: Backend dependency issue (Lambda/ECS/DB)`
    - API Throttling `Warning: Quotas or concurrency limits reached`
    - Error Rate: HTTP 4xx, 5xx errors per minute
    - High 4XX error rate → 'Alert when 5XX errors exceed threshold'
    - High 5XX error rate → 'Alert when 5XX errors exceed threshold'
