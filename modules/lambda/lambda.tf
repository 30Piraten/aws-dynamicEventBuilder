// Lambda IAM Role Definition

resource "aws_iam_role" "lambda_exec" {
  name = "lambda_execution_role"

  assume_role_policy = jsonencode({
    Version = "2024-12-14",
    Statement = [
      {
        Effect    = "Allow",
        Principal = { Service = "lambda.amazonaws.com" },
        Action    = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy" "lambda_logging" {
  name = "lambda_logging_policy"
  role = aws_iam_role.lambda_exec.id

  policy = jsonencode({
    Version = "2024-12-14",
    Statement = [
      {
        Effect   = "Allow",
        Action   = "logs:PutLogEvents",
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}

// Automate build process for lambda function
resource "null_resource" "build_lambdas" {
  provisioner "local-exec" {
    command = "${path.root}/script/zip.sh"
  }
}

// TODO: USE DYNAMIC SETTINGS
// Lambda function resource configuration
// for cleanupenv and provisionenv
resource "aws_lambda_function" "cleanupenv" {
  function_name = "cleanup_lambda"
  role          = aws_iam_role.lambda_exec.arn
  runtime       = "go1.x" // python instead
  handler       = "main"
  filename      = "lambda_function_payload.zip"
  depends_on    = [null_resource.build_lambdas]
}

resource "aws_lambda_function" "provisionenv" {
  function_name = "proenv_lambda"
  role          = aws_iam_role.lambda_exec
  runtime       = "go1.x"
  handler       = "main"
  filename      = "${path.root}/lambda_functions/provisionenv/proenv.go"
  depends_on    = [null_resource.build_lambdas]
}

// TODO: USE DYNAMIC SETTINGS 
// Lambda permission for API Gateway
// this includes permission for both cleanup and proenv
resource "aws_lambda_permission" "api_gateway_cleanupenv" {
  statement_id  = "AllowPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.cleanupenv.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = aws_api_gateway_rest_api.api.execution_arn
}

resource "aws_lambda_permission" "api_gateway_proenv" {
  statement_id  = "AllowPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.provisionenv.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = aws_api_gateway_rest_api.api.execution_arn
}

// Connecting API Gateway to Lambda
resource "aws_api_gateway_rest_api" "api" {
  name        = "gateway_api"
  description = "API Gateway for Lambda"

  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

resource "aws_api_gateway_resource" "proxy" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_rest_api.api.root_resource_id
  path_part   = "{proxy+}"
}

resource "aws_api_gateway_method" "proxy_method" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.proxy.id
  http_method   = "ANY"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "lambda" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.proxy.id
  http_method = aws_api_gateway_method.proxy_method.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.lambda_func.invoke_arn
}