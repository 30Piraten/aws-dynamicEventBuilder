module "vpc" {
  source                               = "./modules/vpc"
  instance_tenancy                     = var.instance_tenancy
  aws_vpc_cidr_block                   = var.aws_vpc_cidr_block
  map_public_ip_on_launch              = var.map_public_ip_on_launch
  aws_subnet_public_cidr_block         = var.aws_subnet_public_cidr_block
  aws_subnet_private_cidr_block        = var.aws_subnet_private_cidr_block
  aws_subnet_public_availability_zone  = var.aws_subnet_public_availability_zone
  aws_subnet_private_availability_zone = var.aws_subnet_private_availability_zone
  db_subnet_name                       = var.db_subnet_name
  db_subnet_tags                       = var.db_subnet_tags
  ttl_expiry_time                      = module.dynamodb.ttl_expiry_time
  environment                          = var.environment

}

module "ec2" {
  source               = "./modules/ec2"
  tag_name             = var.tag_name
  instance_type        = var.instance_type
  environment          = var.environment
  ttl_expiry_time      = module.dynamodb.ttl_expiry_time
  network_interface_id = module.vpc.network_interface_id
}

module "eventsBridge" {
  source      = "./modules/events"
  environment = var.environment
  cleanup_lambda_arn  = module.lambda.aws_cleanup_lambda_arn
}

module "lambda" {
  source          = "./modules/lambda"
  environment_tag = var.environment
  table_name      = module.dynamodb.aws_dynamodb_table.name
  terraform_dir   = var.terraform_dir
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