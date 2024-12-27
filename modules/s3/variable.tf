variable "bucket" {
  type = string
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

variable "ttl_expiry_time" {
  type = number
  
}

variable "environment" {
  type = string 
  
}