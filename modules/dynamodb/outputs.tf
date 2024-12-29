output "ttl_expiry_time" {
    value = local.ttl_expiry_time
}

output "aws_dynamodb_table" {
    value = aws_dynamodb_table.env_tracker_dynamo_db
}