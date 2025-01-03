variable "region" {
  description = "AWS region"
  default     = "us-east-1"
}

// TODO: environment needs to be dynamic
variable "environment" {
  description = "Environment name (e.g., dev, test, prod)"
  type        = string
  default     = "dev"
}

variable "client_id" {
  description = "Client ID"
  type        = string
  default     = "dev"
  
}

# DYANAMODB VARIABLE DECLARATION 
variable "tags" {
  description = "Tags to apply to all resources."
  type        = map(string)
  default = {
    # Owner   = "prod" ? "prod-team" : "dev-team"
    Owner   = "dev-team"
    Project = "dynamic-env-manager"
  }
}

variable "ttl_hours" {
  description = "Time-to-live in hours for resources."
  type        = number
  default     = 1 # Default to 24 hours
}

# EC2 VARIABLE DECLARATION
variable "instance_type" {
  type        = string
  default     = "t2.micro"
  description = "Instance type for the EC2 instance"
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
  default     = "us-east-1b"
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
  default     = "us-east-1c"
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
  default     = "dynamiceventbuilder-bucket-v01"
  description = "Name of the S3 bucket created"
}

variable "key" {
  type        = string
  default     = "provisionenv/terraform.tfstate"
  description = "S3 bucket key"
}

// LAMBDA VARIABLE DECLARATION 
variable "environment_tag" {
  type        = string
  default     = "dev"
  description = "Environment name (e.g., dev, test, prod)"
}

# variable "source_arn" {
#   type = string 
#   description = "Source ARN for the allow_eventbridge_invoke"
# }

variable "terraform_dir" {
  type        = string
  description = "Terraform directory"
  default     = "/modules/*"

}

// API GATEWAY VARIABLE DECLARATION


// CLOUDWATCH VARIABLE DECLARATION
# variable "cleanup_lambda_arn" {
#   type = string 
# }