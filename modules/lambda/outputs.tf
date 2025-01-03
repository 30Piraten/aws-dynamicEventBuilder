output "gateway_api_url" {
  value = aws_apigatewayv2_api.lambda_api.api_endpoint
}

output "aws_cleanup_lambda_arn" {
  value = aws_lambda_function.cleanupenv.arn
}

output "aws_iam_role_lambda_exec_arn" {
  value = aws_iam_role.lambda_exec.arn
}