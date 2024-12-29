resource "aws_cloudwatch_event_rule" "monitor_drift_schedule" {
  name                = "MonitorDriftSchedule"
  schedule_expression = "rate(5 minutes)"
}

resource "aws_lambda_permission" "allow_eventbridge_invoke" {
  statement_id  = "AllowEventBridgeInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.monitor_drift_lambda.arn
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.monitor_drift_schedule.arn
}

resource "aws_cloudwatch_event_target" "monitor_drift_target" {
  rule      = aws_cloudwatch_event_rule.monitor_drift_schedule.name
  target_id = "MonitorDriftLambda"
  arn       = aws_lambda_function.monitor_drift_lambda.arn
}