// Lambda IAM Role Definition
resource "aws_iam_role" "lambda_exec" {
  name = "lambda_execution_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
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
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = [
          "logs:PutLogEvents",
          "logs:CreateLogsStream",
          "logs:PutLogEvents"
        ]
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

// Lambda variables for dynamic settings
locals {
  lambda_functions = {
    cleanupenv = {
      name = "cleanup_lambda"
      filepath = "${path.root}/lambda-functions/cleanupenv/lambda_function_payload.zip"
    }
    provisionenv = {
      name = "proenv_lambda"
      filepath = "${path.root}/lambda-functions/provisionenv/lambda_function_payload.zip"
    }
  }
}

// CLEANUP ENVIRONMENT LAMBDA 
// Lambda function resource configurations
resource "aws_lambda_function" "cleanupenv" {
  function_name = local.lambda_functions["cleanupenv"].name 
  role          = aws_iam_role.lambda_exec.arn
  runtime       =  "provided.al2"  //"go1.x"
  handler       = "main"
  filename      = local.lambda_functions["cleanupenv"].filepath
  depends_on    = [null_resource.build_lambdas]

  environment {
    variables = {
      ENVIRONMENT = var.environment_tag
      TABLE_NAME  = var.table_name
    }
  }
}

// IAM Role cleanup Lambda
resource "aws_iam_role" "cleanup_role" {
  name = "cleanup_lambda_role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}

// Role policy attachment for cleanup Lambda
resource "aws_iam_role_policy_attachment" "cleanup_role_policy" {
  role = aws_iam_role.cleanup_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess"
}

// Policy document for Lambda execution
data "aws_iam_policy_document" "lambda_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

// API Gateway integration for manual cleanup
resource "aws_apigatewayv2_api" "cleanup_api" {
  name = "cleanup_api"
  protocol_type = "HTTP"
}

resource "aws_gatewayv2_integration" "cleanup_lambda_integration" {
  api_id = aws_apigatewayv2_api.cleanup_api.id
  integration_type = "AWS_PROXY"
  integration_method = "POST"
  integration_uri = aws_lambda_function.cleanupenv.invoke_arn
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "cleanup_route" {
  api_id = aws_apigatewayv2_api.cleanup_api.id
  route_key = "ANY /cleanup"
  target = "integrations/${aws_gatewayv2_integration.cleanup_lambda_integration.id}"
}


// PROVISION ENVIRONMENT LAMBDA
resource "aws_lambda_function" "provisionenv" {
  function_name = local.lambda_functions["provisionenv"].name
  role          = aws_iam_role.lambda_exec.arn
  runtime       =  "provided.al2" //"go1.x"
  handler       = "main"
  filename      = local.lambda_functions["provisionenv"].filepath
  depends_on    = [null_resource.build_lambdas]
}


// Lambda permission for API Gateway
// this includes permission for both cleanup and proenv
resource "aws_lambda_permission" "api_gateway_cleanupenv" {
  # statement_id  = "AllowPIGatewayInvokeCleanup"
  statement_id = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.cleanupenv.function_name
  principal     = "apigateway.amazonaws.com"
  # source_arn    = "${aws_api_gateway_rest_api.api.execution_arn}/*"
  source_arn = "${aws_apigatewayv2_api.cleanup_api.execution_arn}/*"
}

resource "aws_lambda_permission" "api_gateway_proenv" {
  statement_id  = "AllowPIGatewayInvokeProenv"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.provisionenv.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.api.execution_arn}/*"
}

// API Gateway Configuration
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

resource "aws_api_gateway_integration" "cleanupenv" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.proxy.id
  http_method = aws_api_gateway_method.proxy_method.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.cleanupenv.invoke_arn
}

resource "aws_api_gateway_integration" "provisionenv" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.proxy.id
  http_method = aws_api_gateway_method.proxy_method.http_method

  integration_http_method = "POST"
  type = "AWS_PROXY"
  uri = aws_lambda_function.provisionenv.invoke_arn
}