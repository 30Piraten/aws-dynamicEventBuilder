resource "aws_cloudwatch_event_rule" "monitor_drift_schedule" {
  name                = "MonitorDriftSchedule"
  schedule_expression = "rate(2 hour)"
}



resource "aws_cloudwatch_event_target" "monitor_drift_target" {
  rule      = aws_cloudwatch_event_rule.monitor_drift_schedule.name
  target_id = "MonitorDriftLambda"
  arn       = aws_lambda_function.monitor_drift_lambda.arn
}