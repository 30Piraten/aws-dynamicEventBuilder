variable "instance_type" {
  type = string
}

variable "filter_values_one" {
  type = list(string)
}

variable "filter_name_one" {
  type = string
}

variable "filter_values_two" {
  type = list(string)
}

variable "filter_name_two" {
  type = string
}

variable "tag_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "ttl_expiry_time" {
  type = number
}