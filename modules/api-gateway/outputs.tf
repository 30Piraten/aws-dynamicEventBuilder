// For REST API Gateway
# output "api_gateway_rest_api" {
#   value = aws_api_gateway_rest_api.api.id
# }

# // For source_arn
# output "execution_arn" {
#   value = "${aws_api_gateway_rest_api.api.execution_arn}/*"
# }