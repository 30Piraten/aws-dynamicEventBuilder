// AWS Lambda Outputs
output "lambda_gatway_api_url" {
  value = module.lambda.gateway_api_url
}

output "aws_iam_role_lambda_exec_arn" {
  value = module.lambda.aws_iam_role_lambda_exec_arn
}


// Dynamodb Outputs
output "ttl_expiry_time" {
  value = module.dynamodb.ttl_expiry_time
}

output "aws_dynamodb_table" {
  value = module.dynamodb.aws_dynamodb_table
}

output "aws_dynamodb_table_name" {
  value = module.dynamodb.aws_dynamodb_table.name 
}


# // Monitor Drift Outputs
# output "monitor_drift_lambda" {
#   value = module.aws_cloudwatch_event_rule.monitor_drift_schedule.name
# }

# output "monitor_drift_lambda_arn" {
#   value = module.aws_lambda_function.monitor_drift_lambda.arn
# }

# output "monitor_drift_lambda_role" {
#   value = module.aws_lambda_function.monitor_drift_lambda.role
# }

# output "monitor_drift_target" {
#   value = module.aws_cloudwatch_event_target.monitor_drift_target.arn
# }