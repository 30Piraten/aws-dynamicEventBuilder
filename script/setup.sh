#!/bin/bash

# Set project directory
PROJECT_DIR="aws-dynamiceventbuilder"
MODULES_DIR="$PROJECT_DIR/modules"
LAMBDA_DIR="$PROJECT_DIR/lambda-functions"

# Create project directory structure
echo "Creating project directory structure..."
mkdir -p $PROJECT_DIR \
    $MODULES_DIR/vpc \
    $MODULES_DIR/ec2 \
    $MODULES_DIR/rds \
    $MODULES_DIR/lambda \
    $MODULES_DIR/api-gateway \
    $LAMBDA_DIR/provision-env \
    $LAMBDA_DIR/cleanup-env

# Initialize Terraform files
echo "Setting up Terraform files..."

# Root Terraform configuration
cat <<EOF > $PROJECT_DIR/main.tf
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
EOF

# Global variables
cat <<EOF > $PROJECT_DIR/variables.tf
variable "region" {
  description = "AWS region"
  default     = "us-east-1"
}

# Add more variables as needed
EOF

# Global outputs
cat <<EOF > $PROJECT_DIR/outputs.tf
output "vpc_id" {
  value = module.vpc.vpc_id
}

# Add more outputs as needed
EOF

# Provider configuration (AWS)
cat <<EOF > $PROJECT_DIR/provider.tf
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}
EOF

# Terraform variable values
cat <<EOF > $PROJECT_DIR/terraform.tfvars
region = "us-east-1"
EOF

# Initialize Go Lambda Functions
echo "Creating Go Lambda functions..."

# Provision Environment Lambda
cat <<EOF > $LAMBDA_DIR/provision-env/main.go
package main

import (
  "context"
  "fmt"
  "github.com/aws/aws-lambda-go/lambda"
  "github.com/aws/aws-sdk-go/aws"
  "github.com/aws/aws-sdk-go/aws/session"
  "github.com/aws/aws-sdk-go/service/ec2"
)

func HandleRequest(ctx context.Context) (string, error) {
  sess := session.Must(session.NewSession())
  svc := ec2.New(sess)

  input := &ec2.RunInstancesInput{
    ImageId:      aws.String("ami-0c55b159cbfafe1f0"),  # Replace with a valid AMI ID
    InstanceType: aws.String("t2.micro"),
    MinCount:     aws.Int64(1),
    MaxCount:     aws.Int64(1),
  }

  _, err := svc.RunInstances(input)
  if err != nil {
    return "", fmt.Errorf("could not create instance: %v", err)
  }

  return "Instance created successfully", nil
}

func main() {
  lambda.Start(HandleRequest)
}
EOF

# Cleanup Environment Lambda
cat <<EOF > $LAMBDA_DIR/cleanup-env/main.go
package main

import (
  "context"
  "fmt"
  "github.com/aws/aws-lambda-go/lambda"
  "github.com/aws/aws-sdk-go/aws"
  "github.com/aws/aws-sdk-go/aws/session"
  "github.com/aws/aws-sdk-go/service/ec2"
)

func HandleRequest(ctx context.Context) (string, error) {
  // Logic to clean up environments, e.g., terminate EC2 instances based on TTL
  return "Environment cleanup completed", nil
}

func main() {
  lambda.Start(HandleRequest)
}
EOF

# Initialize Go modules for Lambda functions
echo "Initializing Go modules for Lambda functions..."

cd $LAMBDA_DIR/provision-env && go mod init provision-env
cd $LAMBDA_DIR/cleanup-env && go mod init cleanup-env

# Initialize Git
echo "Initializing Git repository..."
cd $PROJECT_DIR
git init

# Add .gitignore file
echo "Adding .gitignore..."
cat <<EOF > .gitignore
# Terraform files
.terraform/
terraform.tfstate
terraform.tfstate.backup
*.tfvars

# Go build artifacts
bin/
EOF

# Done
echo "Project setup complete!"
echo "Now you can run 'terraform init' and start developing the Lambda functions in Go."

