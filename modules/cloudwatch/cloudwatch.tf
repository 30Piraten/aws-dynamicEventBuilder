resource "random_string" "id" {
  length  = 8
  special = false
  keepers = {
    client_id = var.environment
  }
}

# CloudWatch Log Group for Lambda logs
resource "aws_cloudwatch_log_group" "cleanup_lambda" {
  name              = "watch-lambda-${var.client_id}-${random_string.id.hex}"
  retention_in_days = 2

  tags = {
    Environment = var.environment
    Managed_By  = "terraform"
  }
}

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
  arn       = var.cleanup_lambda_arn # This is the ARN of the Lambda function
}