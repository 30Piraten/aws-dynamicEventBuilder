// This is a separate module to monitor drifts in the AWS environment
// It will trigger a Lambda function to monitor drifts in the environment
// The Lambda function will be triggered every 2 hours

resource "null_resource" "build_monitor_drift" {
  triggers = {
    always_run = timestamp()
  }

  provisioner "local-exec" {
    # command = "zip -r monitor_drift.zip monitor_drift"
    command = "${path.root}/script/monitor.sh"
  }
  
}

resource "aws_lambda_function" "monitor_drift_lambda" {
  filename         = "${path.root}/monitordrift/monitor_drift_payload.zip"
  function_name    = "MonitorDrift"
  role             = var.monitor_drift_lambda_role
  handler          = "monitor_drift.lambda_handler"
  source_code_hash = filebase64sha256("monitor_drift.zip")
  runtime          = "provided.al2"
  timeout          = 10
  memory_size      = 128

  depends_on = [ null_resource.build_monitor_drift ]

  environment {
    variables = {
      REGION = var.region
    }
  }
}

resource "aws_cloudwatch_event_rule" "monitor_drift_schedule" {
  name                = "MonitorDriftSchedule"
  schedule_expression = "rate(2 hour)"
}

resource "aws_cloudwatch_event_target" "monitor_drift_target" {
  rule      = aws_cloudwatch_event_rule.monitor_drift_schedule.name
  target_id = "MonitorDriftLambda"
  arn       = aws_lambda_function.monitor_drift_lambda.arn
}