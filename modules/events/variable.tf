variable "environment" {
  description = "The environment to deploy the resources"
  type        = string
  
}

variable "cleanup_lambda_arn" {
  description = "The ARN of the Lambda function"
  type        = string
}