// Locals for calculating TTL expiry time for DynamoDB table
locals {
  ttl_expiry_time = timeadd(timestamp(), var.ttl_hours * 3600)
  # ttl_expiry_time = var.ttl_expiry_time
}

resource "aws_dynamodb_table" "env_tracker_dynamo_db" {
  name           = "${var.environment}-dynamodb-table"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "EnvironmentName"
  range_key      = "ttl"

  read_capacity  = 5
  write_capacity = 5

  attribute {
    name = "EnvironmentName"
    type = "S"
  }

  ttl {
    attribute_name = "TTL"
    enabled        = true
  }

  tags = merge(var.tags, {
    Name = "${var.environment}-dynamodb-table"
    Environment = var.environment
    TTL  = "${local.ttl_expiry_time}"
  })
}