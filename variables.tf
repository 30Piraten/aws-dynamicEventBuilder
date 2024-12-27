variable "region" {
  description = "AWS region"
  default     = "us-east-1"
}

variable "ttl_expiry_time" {
  type        = number
  description = "ttl expiry time"
}

variable "environment" {
  description = "Environment name (e.g., dev, test, prod)"
  type        = string
  default     = "dev"
}

# DYANAMODB VARIABLE DECLARATION 
variable "tags" {
  description = "Tags to apply to all resources."
  type        = map(string)
  default = {
    Owner   = "cloud-team"
    Project = "env-manager"
  }
}

variable "ttl_hours" {
  description = "Time-to-live in hours for resources."
  type        = number
  default     = 24 # Default to 24 hours
}

# EC2 VARIABLE DECLARATION
variable "instance_type" {
  type        = string
  default     = "t2.micro"
  description = "Instance type for the EC2 instance"
}

variable "filter_values_one" {
  type    = list(string)
  default = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
}

variable "filter_name_one" {
  type        = string
  default     = "name"
  description = "name"
}

variable "filter_values_two" {
  type        = list(string)
  default     = ["hvm"]
  description = "value"
}

variable "filter_name_two" {
  type        = string
  default     = "virtualization-type"
  description = "Virtualization type"
}

variable "tag_name" {
  type        = string
  default     = "WebServer"
  description = "Tag name for the EC2 instance"
}

// RDS VARIABLE CONFIGURATION
variable "db_name" {
  type        = string
  default     = "mydbsql"
  description = "Name of the database instance"
}

variable "engine" {
  type        = string
  default     = "MySql"
  description = "Engine name of the database instance"
}

variable "engine_version" {
  type        = string
  default     = "8.0.39"
  description = "Engine version for the database instance"
}

variable "allocated_storage" {
  type        = string
  default     = "20"
  description = "Storage size allocated to the database instance"
}

variable "instance_class" {
  type        = string
  default     = "db.t3.micro"
  description = "Instance class of the database instance"
}

variable "parameter_group_name" {
  type        = string
  default     = "default.mysql8.0"
  description = "Parameter group name of the database instance"
}

variable "skip_final_snapshot" {
  type        = bool
  default     = true
  description = "Skip the final snapshot of the database instance"
}

variable "publicly_accessible" {
  type        = bool
  default     = false
  description = "Avoid public access to the database instance"
}

variable "multi_az" {
  type        = bool
  default     = false
  description = "Disallow multi availability zone"
}


// VPC VARIABLE DECLARATION
variable "aws_vpc_cidr_block" {
  type        = string
  default     = "10.0.0.0/16"
  description = "Cidr block for the VPC network"
}

variable "instance_tenancy" {
  type        = string
  default     = "default"
  description = "Instance tenancy"
}

variable "aws_subnet_public_cidr_block" {
  type        = string
  default     = "10.0.1.0/24"
  description = "Public CIDR subnet for the VPC network"
}

variable "aws_subnet_public_availability_zone" {
  type        = string
  default     = "us-east-1a"
  description = "Availability Zone for the public subnet"
}

variable "map_public_ip_on_launch" {
  type        = bool
  default     = true
  description = "Map"
}

variable "aws_subnet_private_cidr_block" {
  type        = string
  default     = "10.0.2.0/24"
  description = "Private CIDR subnet for the VPC network"
}

variable "aws_subnet_private_availability_zone" {
  type        = string
  default     = "us-east-1b"
  description = "Availability zone for the private subnet"
}

variable "db_subnet_name" {
  type        = string
  default     = "dbsubnet"
  description = "Name of the database subnet"
}

variable "db_subnet_tags" {
  type = map(string)
  default = {
    Name = "DBSubnetGroup"
  }
}

// S3 VARIABLE DECLARATION 
variable "bucket" {
  type        = string
  default     = "terraform-state-bucket"
  description = "Name of the S3 bucket created"
}

variable "key" {
  type        = string
  default     = "provisionenv/terraform.tfstate"
  description = "S3 bucket key"
}

variable "dynamodb_table" {
  type        = string
  default     = "terraform-lock"
  description = "Dynamo table for the S3"
}

// LAMBDA VARIABLE DECLARATION 
variable "environment_tag" {
  type        = string
  default     = "dev"
  description = "Environment name (e.g., dev, test, prod)"
}

variable "table_name" {
  type        = string
  description = "Table name for DynamoDB"

}

// API GATEWAY VARIABLE DECLARATION
