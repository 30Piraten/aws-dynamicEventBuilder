output "gateway_api_url" {
  value = aws_apigatewayv2_api.lambda_api.api_endpoint
}