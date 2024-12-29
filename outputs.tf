output "lambda_gatway_api_url" {
  value = module.lambda.gateway_api_url
}

output "ttl_expiry_time" {
  value = module.dynamodb.ttl_expiry_time
}

output "aws_dynamodb_table" {
  value = module.dynamodb.aws_dynamodb_table
}
