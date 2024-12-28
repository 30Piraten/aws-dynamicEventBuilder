terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0.0"
    }
  }
}

provider "aws" {
  region  = var.region
  profile = "tf-user"
  # access_key = "AKIAWPPO6UVN2SM2DK7M"
  # secret_key = "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"
}