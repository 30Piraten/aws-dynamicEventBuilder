// State locking with DynamoDB to prevent 
// conflicts when Lambda triggers Terraform
terraform {
  backend "s3" {
    bucket = var.bucket
    key = var.key
    region = var.region
    dynamodb_table = var.dynamodb_table
    encrypt = true
  }
}

resource "aws_s3_bucket" "bucket" {
  bucket = var.bucket

  tags = {
    Name = "S3_bucket"
    TTL = var.ttl_expiry_time
    Environment = var.environment
  }
}
