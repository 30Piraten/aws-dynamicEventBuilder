# Terraform Backend Configuration (Using Terraform Cloud/Enterprise)
terraform {
  backend "remote" {
    hostname     = "app.terraform.io"
    organization = "datenbank"
    workspaces {
      name = "aws-dynamicEventBuilder"
    }
  }
  cloud {

    organization = "datenbank"

    workspaces {
      name = "aws-dynamicEventBuilder"
    }
  }
}