variable "aws_vpc_cidr_block" {
  type = string
}

variable "instance_tenancy" {
  type = string
}

variable "aws_subnet_public_cidr_block" {
  type = string
}
variable "aws_subnet_public_availability_zone" {
  type = string
}

variable "map_public_ip_on_launch" {
  type = bool
}

variable "aws_subnet_private_cidr_block" {
  type = string
}

variable "aws_subnet_private_availability_zone" {
  type = string
}

variable "db_subnet_name" {
  type = string
}

variable "db_subnet_tags" {
  type = map(string)
}

variable "ttl_expiry_time" {
  type = number 
  
}

variable "environment" {
  type = string 
  
}