# EventBridge rule to trigger cleanup Lambda
resource "aws_cloudwatch_event_rule" "environment_cleanup" {
  name                = "environment-cleanup-trigger"
  description         = "Trigger cleanup for expired environments"
  schedule_expression = "rate(1 hour)"

  tags = {
    Environment = var.environment
    Managed_By  = "terraform"
  }
}

# EventBridge target configuration
resource "aws_cloudwatch_event_target" "cleanup_lambda" {
  rule      = aws_cloudwatch_event_rule.environment_cleanup.name
  target_id = "EnvironmentCleanupLambda"
  arn       = aws_lambda_function.cleanup.arn
}

# Lambda permission to allow EventBridge invocation
resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "AllowEventBridgeInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.cleanup.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.environment_cleanup.arn
}

# CloudWatch Log Group for Lambda logs
resource "aws_cloudwatch_log_group" "cleanup_lambda" {
  name              = "/aws/lambda/${aws_lambda_function.cleanup.function_name}"
  retention_in_days = 14

  tags = {
    Environment = var.environment
    Managed_By  = "terraform"
  }
}