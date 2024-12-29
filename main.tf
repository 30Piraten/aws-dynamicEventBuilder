module "events" {
  source      = "./modules/events"
  environment = var.environment
  cleanup_lambda_arn  = module.lambda.aws_cleanup_lambda_arn
}

# module "monitordrift" {
#   source = "./modules/monitordrift"
# }

module "lambda" {
  source          = "./modules/lambda"
  environment_tag = var.environment
  table_name      = module.dynamodb.aws_dynamodb_table.name
  terraform_dir   = var.terraform_dir
  source_arn = module.events.environement_cleanup
}

module "api_gateway" {
  source = "./modules/api-gateway"
}

module "dynamodb" {
  source      = "./modules/dynamodb"
  ttl_hours   = var.ttl_hours
  tags        = var.tags
  environment = var.environment
}