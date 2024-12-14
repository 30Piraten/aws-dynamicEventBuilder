resource "aws_vpc" "vpc" {
 cidr_block = var.aws_vpc_cidr_block  

 instance_tenancy = var.instance_tenancy

 tags = var.tags 
}

resource "aws_subnet" "public" {
  vpc_id = aws_vpc.vpc.id
  cidr_block = var.aws_subnet_public_cidr_block
  availability_zone = var.aws_subnet_public_availability_zone 
  map_public_ip_on_launch = var.map_public_ip_on_launch
}

resource "aws_subnet" "private" {
  vpc_id = aws_vpc.vpc.id
  cidr_block = var.aws_subnet_private_cidr_block
  availability_zone = var.aws_subnet_private_availability_zone
}