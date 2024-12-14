variable "region" {
  description = "AWS region"
  default     = "us-east-1"
}

# Add more variables as needed

# EC2 VARIABLE DECLARATION
variable "instance_type" {
  type = string 
  default = "t2.micro"
  description = "Instance type for the EC2 instance"
}

variable "filter_values_one" {
  type = list(string) 
  default = [ "ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*" ]
}

variable "filter_name_one" {
  type = string 
  default = "name"
  description = "name"
}

variable "filter_values_two" {
  type = string
  default =["hvm"]
  description = "value" 
}

variable "filter_name_two" {
  type = string 
  default = "virtualization-type"
  description = "Virtualization type"
}

variable "tag_name" {
  type = string 
  default = "WebServer"
  description = "Tag name for the EC2 instance"
}

// RDS VARIABLE CONFIGURATION
variable "db_name" {
  type = string 
  default = "mydbsql"
  description = "Name of the database instance"
}

variable "engine" {
  type = string 
  default = "MySql"
  description = "Engine name of the database instance"
}

variable "engine_version" {
  type = string 
  default = "8.0.0"
  description = "Engine version for the database instance"
}

variable "allocated_storage" {
  type = string 
  default = "20"
  description = "Storage size allocated to the database instance"
}

variable "instance_class" {
  type = string 
  default = "db.t3.micro"
  description = "Instance class of the database instance"
}

variable "parameter_group_name" {
  type = string 
  default = "default.mysql8.0"
  description = "Parameter group name of the database instance"
}

variable "skip_final_snapshot" {
  type = bool
  default = true 
  description = "Skip the final snapshot of the database instance"
}

variable "publicly_accessible" {
  type = bool
  default = false
  description = "Avoid public access to the database instance"
}

variable "multi_az" {
  type = bool 
  default = false
  description = "Disallow multi availability zone"
}


// VPC VARIABLE DECLARATION
variable "aws_vpc_cidr_block" {
  type = string 
  default = "10.0.0.1/16"
  description = "Cidr block for the VPC network"
}

variable "instance_tenancy" {
  type = string 
  default = "default"
  description = "Instance tenancy"
}

variable "tags" {
  type = map(string)
  default = {
    "name" = "main"
  }
  description = "Tags for the VPC network"
}

variable "aws_subnet_public_cidr_block" {
  type = string 
  default = "10.0.1.0/24"
  description = "Public CIDR subnet for the VPC network"
}

variable "aws_subnet_public_availability_zone" {
  type = string 
  default = "us-east-1a"
  description = "Availability Zone for the public subnet"
}

variable "map_public_ip_on_launch" {
  type = bool 
  default = true 
  description = "Map"
}

variable "aws_subnet_private_cidr_block" {
  type = string 
  default = "10.0.2.0/24"
  description = "Private CIDR subnet for the VPC network"
}

variable "aws_subnet_private_availability_zone" {
  type = string 
  default = "us-east-1b"
  description = "Availability zone for the private subnet"
}