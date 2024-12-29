// Locals for calculating TTL expiry time for DynamoDB table
locals {
  ttl_expiry_time = var.ttl_hours * 3600
}

resource "aws_dynamodb_table" "env_tracker_dynamo_db" {
  name           = "${var.environment}-dynamodb-table"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "LockID"
  range_key      = "Dev"

  attribute {
    name = "LockID"
    type = "S"
  }

  attribute {
    name = "Dev"
    type = "S"
  }
 
  ttl {
    attribute_name = "TTL"
    enabled        = true
  }

   global_secondary_index {
    name               = "TTLIndex"
    hash_key           = "status"
    range_key          = "TTL"
    projection_type    = "ALL"
  }

  tags = merge(var.tags, {
    Name = "${var.environment}-dynamodb-table"
    Environment = var.environment
    TTL = local.ttl_expiry_time
  })
}
