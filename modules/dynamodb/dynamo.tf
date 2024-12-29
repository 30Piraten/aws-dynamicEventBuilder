// Locals for calculating TTL expiry time for DynamoDB table
locals {
  # ttl_expiry_time = timeadd(timestamp(), "${var.ttl_hours * 3600}s")
  #  ttl_expiry_time = "${var.ttl_hours * 3600}s"

  ttl_expiry_time = var.ttl_hours * 3600
}

resource "aws_dynamodb_table" "env_tracker_dynamo_db" {
  name           = "${var.environment}-dynamodb-table"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "EnvironmentName"
  range_key      = "Team"

  attribute {
    name = "Team"
    type = "S"
  }
 
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
    # TTL  = "${local.ttl_expiry_time}"
    TTL = local.ttl_expiry_time
  })
}