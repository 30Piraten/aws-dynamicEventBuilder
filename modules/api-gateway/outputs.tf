output "api_gateway_rest_api" {
  value = aws_api_gateway_rest_api.api.id
}

output "api_gateway_execution_arn" {
  value = "${aws_api_gateway_rest_api.api.execution_arn}/*"
}