# Backend for Terraform state
terraform {
  backend "s3" {
    bucket         = var.bucket
    key            = "environments/state.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}