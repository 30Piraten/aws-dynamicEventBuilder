variable "bucket" {
  type = string
}

variable "bucket_tags" {
  type = map(string)
}

variable "region" {
  type = string
}

variable "key" {
  type = string 
}

variable "dynamodb_table" {
  type = string 
}