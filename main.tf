module "vpc" {
  source                               = "./modules/vpc"
  tags                                 = var.tags
  instance_tenancy                     = var.instance_tenancy
  aws_vpc_cidr_block                   = var.aws_vpc_cidr_block
  map_public_ip_on_launch              = var.map_public_ip_on_launch
  aws_subnet_public_cidr_block         = var.aws_subnet_public_cidr_block
  aws_subnet_private_cidr_block        = var.aws_subnet_private_cidr_block
  aws_subnet_public_availability_zone  = var.aws_subnet_public_availability_zone
  aws_subnet_private_availability_zone = var.aws_subnet_private_availability_zone
  db_subnet_name                       = var.db_subnet_name
  db_subnet_tags                       = var.db_subnet_tags

}

module "ec2" {
  source            = "./modules/ec2"
  tag_name          = var.tag_name
  filter_name_one   = var.filter_name_one
  filter_name_two   = var.filter_name_two
  filter_values_one = var.filter_values_one
  filter_values_two = var.filter_values_two
  instance_type     = var.instance_type
}

module "rds" {
  source               = "./modules/rds"
  engine               = var.engine
  db_name              = var.db_name
  multi_az             = var.multi_az
  instance_class       = var.instance_class
  engine_version       = var.engine_version
  allocated_storage    = var.allocated_storage
  skip_final_snapshot  = var.skip_final_snapshot
  publicly_accessible  = var.publicly_accessible
  parameter_group_name = var.parameter_group_name
}

module "lambda" {
  source     = "./modules/lambda"
  source_arn = module.api_gateway.api_gateway_execution_arn
}

module "api_gateway" {
  source = "./modules/api-gateway"
  uri    = module.lambda.aws_lambda_function.invoke_arn
}
