// Lambda IAM Role Definition with combined permissions
resource "aws_iam_role" "lambda_exec" {
  name = "lamba-exec-role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy" "lambda_permissions" {
  name = "lambda-permissions"
  role = aws_iam_role.lambda_exec.id
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Effect = "Allow"
        Action = [
          "dynamodb:PutItem",
          "dynamodb:UpdateItem",
          "dynamodb:GetItem",
          "dynamodb:DeleteItem",

          "ec2:DescribeInstances",
          "ec2:RunInstances",
          "ec2:TerminateInstances",
        ]
        Resource = "*"
      }
    ]
  })
}

// Lambda build automation
resource "null_resource" "build_lambdas" {
  provisioner "local-exec"  {
    command = "${path.root}/script/zip.sh"
  }
}

// Lambda configurations
locals {
  lambda_functions = {
    cleanupenv = {
      name = "cleanup_lambda"
      filepath = "${path.root}/lambda-functions/cleanupenv/lambda_function_payload.zip"
    }
    provisionenv = {
      name = "provision_lambda"
      filepath = "${path.root}/lambda-functions/provisionenv/lambda_function_payload.zip"
    }
  }
}

// Lambda function definition
resource "aws_lambda_function" "cleanupenv" {
  function_name = local.lambda_functions["cleanupenv"].name
  role = aws_iam_role.lambda_exec.arn
  runtime = "provided.al2"
  handler = "main"
  filename = local.lambda_functions["cleanupenv"].filepath
  depends_on = [ null_resource.build_lambdas ]

  environment {
    variables = {
      ENVIRONMENT = var.environment_tag
      TABLE_NAME = var.table_name
    }
  }
}

resource "aws_lambda_function" "provisionenv" {
  function_name = local.lambda_functions["provisionenv"].name
  role = aws_iam_role.lambda_exec.arn
  runtime = "provided.al2"
  handler = "main"
  filename = local.lambda_functions["provisionenv"].filepath
  depends_on = [ null_resource.build_lambdas ]
}

// Single HTTP API Gateway for both functions
resource "aws_apigatewayv2_api" "lambda_api" {
  name          = "lambda-api"
  protocol_type = "HTTP"
}

// Integration for cleanupenv & provisionenv
resource "aws_apigatewayv2_integration" "cleanup_integration" {
  api_id             = aws_apigatewayv2_api.lambda_api.id
  integration_type   = "AWS_PROXY"
  integration_uri    = aws_lambda_function.cleanupenv.invoke_arn
  integration_method = "POST"
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_integration" "provision_integration" {
  api_id = aws_apigatewayv2_api.lambda_api.id
  integration_type = "AWS_PROXY"
  integration_method = "POST"
  integration_uri = aws_lambda_function.provisionenv.invoke_arn
  payload_format_version = "2.0"
}

// Routes for cleanupenv & provisionenv
resource "aws_apigatewayv2_route" "cleanup_route" {
  api_id = aws_apigatewayv2_api.lambda_api.id
  route_key = "ANY /cleanupenv"
  target = "integrations/${aws_apigatewayv2_integration.cleanup_integration.id}"
}

resource "aws_apigatewayv2_route" "provision_route" {
  api_id = aws_apigatewayv2_api.lambda_api.id
  route_key = "ANY /provision"
  target = "integrations/${aws_apigatewayv2_integration.provision_integration.id}"
}

// Lambda permissions for API Gateway
resource "aws_lambda_permission" "cleanupenv" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.cleanupenv.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.lambda_api.execution_arn}/*"
}

resource "aws_lambda_permission" "provisionenv" {
  statement_id = "AllowAPIGatewayInvoke"
  action = "lambda:InvokeFunction"
  function_name = aws_lambda_function.provisionenv.function_name
  principal = "apigateway.amazonaws.com"
  source_arn = "${aws_apigatewayv2_api.lambda_api.execution_arn}/*"
}

# Lambda permission
resource "aws_lambda_permission" "allow_eventbridge_invoke" {
  statement_id  = "AllowEventBridgeInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.cleanupenv.function_name
  principal     = "events.amazonaws.com"
  # source_arn    = aws_cloudwatch_event_rule.environement_cleanup.arn
  source_arn = var.source_arn
}
