locals {
  ttl_expiry = 3
}


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

  # tags = var.bucket_tags
  tags = {
    Name = "S3_bucket"
    TTL = timeadd(timestamp(), "${ttl_expiry}m")
  }
}
