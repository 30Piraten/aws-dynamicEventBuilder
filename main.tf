provider "aws" {
  region = "us-east-1"  # Change this to your preferred AWS region
}

module "vpc" {
  source = "./modules/vpc"
}

module "ec2" {
  source = "./modules/ec2"
}

module "rds" {
  source = "./modules/rds"
}

module "lambda" {
  source = "./modules/lambda"
}

module "api_gateway" {
  source = "./modules/api-gateway"
}
