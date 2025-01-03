output "monitor_drift_lambda" {
  value = aws_cloudwatch_event_rule.monitor_drift_schedule.name
}

output "monitor_drift_lambda_arn" {
  value = aws_lambda_function.monitor_drift_lambda.arn
}

output "monitor_drift_lambda_role" {
  value = aws_lambda_function.monitor_drift_lambda.role
}

output "monitor_drift_target" {
  value = aws_cloudwatch_event_target.monitor_drift_target.arn
}