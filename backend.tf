# # Backend for Terraform state
# terraform {
#   backend "s3" {
#     bucket         = "dynamiceventbuilder-bucket-v01"
#     key            = "environments/state.tfstate"
#     region         = "us-east-1"
#     dynamodb_table = "dev-dynamodb-table"
#     encrypt        = true
#   }
# }